// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import 'application_package.dart';
import 'artifacts.dart';
import 'asset.dart';
import 'base/common.dart';
import 'base/file_system.dart';
import 'base/io.dart';
import 'base/logger.dart';
import 'base/terminal.dart';
import 'base/utils.dart';
import 'build_info.dart';
import 'codegen.dart';
import 'compile.dart';
import 'dart/package_map.dart';
import 'devfs.dart';
import 'device.dart';
import 'globals.dart';
import 'project.dart';
import 'run_cold.dart';
import 'run_hot.dart';
import 'vmservice.dart';

class FlutterDevice {
  FlutterDevice(
    this.device, {
    @required this.trackWidgetCreation,
    this.dillOutputPath,
    this.fileSystemRoots,
    this.fileSystemScheme,
    this.viewFilter,
    TargetModel targetModel = TargetModel.flutter,
    List<String> experimentalFlags,
    ResidentCompiler generator,
    @required BuildMode buildMode,
  }) : assert(trackWidgetCreation != null),
       generator = generator ?? ResidentCompiler(
         artifacts.getArtifactPath(Artifact.flutterPatchedSdkPath, mode: buildMode),
         trackWidgetCreation: trackWidgetCreation,
         fileSystemRoots: fileSystemRoots,
         fileSystemScheme: fileSystemScheme,
         targetModel: targetModel,
         experimentalFlags: experimentalFlags,
       );

  /// Create a [FlutterDevice] with optional code generation enabled.
  static Future<FlutterDevice> create(
    Device device, {
    @required bool trackWidgetCreation,
    String dillOutputPath,
    List<String> fileSystemRoots,
    String fileSystemScheme,
    String viewFilter,
    @required String target,
    TargetModel targetModel = TargetModel.flutter,
    List<String> experimentalFlags,
    ResidentCompiler generator,
    @required BuildMode buildMode,
  }) async {
    ResidentCompiler generator;
    final FlutterProject flutterProject = await FlutterProject.current();
    if (flutterProject.hasBuilders) {
      generator = await CodeGeneratingResidentCompiler.create(
        flutterProject: flutterProject,
      );
    } else {
      generator = ResidentCompiler(
        artifacts.getArtifactPath(Artifact.flutterPatchedSdkPath, mode: buildMode),
        trackWidgetCreation: trackWidgetCreation,
        fileSystemRoots: fileSystemRoots,
        fileSystemScheme: fileSystemScheme,
        targetModel: targetModel,
        experimentalFlags: experimentalFlags,
      );
    }
    return FlutterDevice(
      device,
      trackWidgetCreation: trackWidgetCreation,
      dillOutputPath: dillOutputPath,
      fileSystemRoots: fileSystemRoots,
      fileSystemScheme:fileSystemScheme,
      viewFilter: viewFilter,
      experimentalFlags: experimentalFlags,
      targetModel: targetModel,
      generator: generator,
      buildMode: buildMode,
    );
  }

  final Device device;
  final ResidentCompiler generator;
  List<Uri> observatoryUris;
  List<VMService> vmServices;
  DevFS devFS;
  ApplicationPackage package;
  String dillOutputPath;
  List<String> fileSystemRoots;
  String fileSystemScheme;
  StreamSubscription<String> _loggingSubscription;
  final String viewFilter;
  final bool trackWidgetCreation;

  /// If the [reloadSources] parameter is not null the 'reloadSources' service
  /// will be registered.
  /// The 'reloadSources' service can be used by other Service Protocol clients
  /// connected to the VM (e.g. Observatory) to request a reload of the source
  /// code of the running application (a.k.a. HotReload).
  /// The 'compileExpression' service can be used to compile user-provided
  /// expressions requested during debugging of the application.
  /// This ensures that the reload process follows the normal orchestration of
  /// the Flutter Tools and not just the VM internal service.
  Future<void> _connect({
    ReloadSources reloadSources,
    Restart restart,
    CompileExpression compileExpression,
  }) async {
    if (vmServices != null)
      return;
    final List<VMService> localVmServices = List<VMService>(observatoryUris.length);
    for (int i = 0; i < observatoryUris.length; i += 1) {
      printTrace('Connecting to service protocol: ${observatoryUris[i]}');
      localVmServices[i] = await VMService.connect(
        observatoryUris[i],
        reloadSources: reloadSources,
        restart: restart,
        compileExpression: compileExpression,
      );
      printTrace('Successfully connected to service protocol: ${observatoryUris[i]}');
    }
    vmServices = localVmServices;
  }

  Future<void> refreshViews() async {
    if (vmServices == null || vmServices.isEmpty)
      return Future<void>.value(null);
    final List<Future<void>> futures = <Future<void>>[];
    for (VMService service in vmServices)
      futures.add(service.vm.refreshViews(waitForViews: true));
    await Future.wait(futures);
  }

  List<FlutterView> get views {
    if (vmServices == null)
      return <FlutterView>[];

    return vmServices
      .where((VMService service) => !service.isClosed)
      .expand<FlutterView>(
        (VMService service) {
          return viewFilter != null
               ? service.vm.allViewsWithName(viewFilter)
               : service.vm.views;
        },
      )
      .toList();
  }

  Future<void> getVMs() async {
    for (VMService service in vmServices)
      await service.getVM();
  }

  Future<void> stopApps() async {
    if (!device.supportsStopApp) {
      return;
    }
    final List<FlutterView> flutterViews = views;
    if (flutterViews == null || flutterViews.isEmpty)
      return;
    final List<Future<void>> futures = <Future<void>>[];
    for (FlutterView view in flutterViews) {
      if (view != null && view.uiIsolate != null) {
        futures.add(view.uiIsolate.flutterExit());
      }
    }
    // The flutterExit message only returns if it fails, so just wait a few
    // seconds then assume it worked.
    // TODO(ianh): We should make this return once the VM service disconnects.
    await Future.wait(futures).timeout(const Duration(seconds: 2), onTimeout: () { });
  }

  Future<Uri> setupDevFS(
    String fsName,
    Directory rootDirectory, {
    String packagesFilePath,
  }) {
    // One devFS per device. Shared by all running instances.
    devFS = DevFS(
      vmServices[0],
      fsName,
      rootDirectory,
      packagesFilePath: packagesFilePath,
    );
    return devFS.create();
  }

  List<Future<Map<String, dynamic>>> reloadSources(
    String entryPath, {
    bool pause = false,
  }) {
    final Uri deviceEntryUri = devFS.baseUri.resolveUri(fs.path.toUri(entryPath));
    final Uri devicePackagesUri = devFS.baseUri.resolve('.packages');
    final List<Future<Map<String, dynamic>>> reports = <Future<Map<String, dynamic>>>[];
    for (FlutterView view in views) {
      final Future<Map<String, dynamic>> report = view.uiIsolate.reloadSources(
        pause: pause,
        rootLibUri: deviceEntryUri,
        packagesUri: devicePackagesUri,
      );
      reports.add(report);
    }
    return reports;
  }

  Future<void> resetAssetDirectory() async {
    final Uri deviceAssetsDirectoryUri = devFS.baseUri.resolveUri(
        fs.path.toUri(getAssetBuildDirectory()));
    assert(deviceAssetsDirectoryUri != null);
    await Future.wait<void>(views.map<Future<void>>(
      (FlutterView view) => view.setAssetDirectory(deviceAssetsDirectoryUri)
    ));
  }

  // Lists program elements changed in the most recent reload that have not
  // since executed.
  Future<List<ProgramElement>> unusedChangesInLastReload() async {
    final List<Future<List<ProgramElement>>> reports =
      <Future<List<ProgramElement>>>[];
    for (FlutterView view in views)
      reports.add(view.uiIsolate.getUnusedChangesInLastReload());
    final List<ProgramElement> elements = <ProgramElement>[];
    for (Future<List<ProgramElement>> report in reports) {
      for (ProgramElement element in await report)
        elements.add(ProgramElement(element.qualifiedName,
                                        devFS.deviceUriToHostUri(element.uri),
                                        element.line,
                                        element.column));
    }
    return elements;
  }

  Future<void> debugDumpApp() async {
    for (FlutterView view in views)
      await view.uiIsolate.flutterDebugDumpApp();
  }

  Future<void> debugDumpRenderTree() async {
    for (FlutterView view in views)
      await view.uiIsolate.flutterDebugDumpRenderTree();
  }

  Future<void> debugDumpLayerTree() async {
    for (FlutterView view in views)
      await view.uiIsolate.flutterDebugDumpLayerTree();
  }

  Future<void> debugDumpSemanticsTreeInTraversalOrder() async {
    for (FlutterView view in views)
      await view.uiIsolate.flutterDebugDumpSemanticsTreeInTraversalOrder();
  }

  Future<void> debugDumpSemanticsTreeInInverseHitTestOrder() async {
    for (FlutterView view in views)
      await view.uiIsolate.flutterDebugDumpSemanticsTreeInInverseHitTestOrder();
  }

  Future<void> toggleDebugPaintSizeEnabled() async {
    for (FlutterView view in views)
      await view.uiIsolate.flutterToggleDebugPaintSizeEnabled();
  }

  Future<void> toggleDebugCheckElevationsEnabled() async {
    for (FlutterView view in views)
      await view.uiIsolate.flutterToggleDebugCheckElevationsEnabled();
  }

  Future<void> debugTogglePerformanceOverlayOverride() async {
    for (FlutterView view in views)
      await view.uiIsolate.flutterTogglePerformanceOverlayOverride();
  }

  Future<void> toggleWidgetInspector() async {
    for (FlutterView view in views)
      await view.uiIsolate.flutterToggleWidgetInspector();
  }

  Future<void> toggleProfileWidgetBuilds() async {
    for (FlutterView view in views) {
      await view.uiIsolate.flutterToggleProfileWidgetBuilds();
    }
  }

  Future<String> togglePlatform({ String from }) async {
    String to;
    switch (from) {
      case 'iOS':
        to = 'android';
        break;
      case 'android':
      default:
        to = 'iOS';
        break;
    }
    for (FlutterView view in views)
      await view.uiIsolate.flutterPlatformOverride(to);
    return to;
  }

  void startEchoingDeviceLog() {
    if (_loggingSubscription != null)
      return;
    _loggingSubscription = device.getLogReader(app: package).logLines.listen((String line) {
      if (!line.contains('Observatory listening on http'))
        printStatus(line, wrap: false);
    });
  }

  Future<void> stopEchoingDeviceLog() async {
    if (_loggingSubscription == null)
      return;
    await _loggingSubscription.cancel();
    _loggingSubscription = null;
  }

  void initLogReader() {
    device.getLogReader(app: package).appPid = vmServices.first.vm.pid;
  }

  Future<int> runHot({
    HotRunner hotRunner,
    String route,
    bool shouldBuild,
  }) async {
    final bool prebuiltMode = hotRunner.applicationBinary != null;
    final String modeName = hotRunner.debuggingOptions.buildInfo.friendlyModeName;
    printStatus('Launching ${getDisplayPath(hotRunner.mainPath)} on ${device.name} in $modeName mode...');

    final TargetPlatform targetPlatform = await device.targetPlatform;
    package = await ApplicationPackageFactory.instance.getPackageForPlatform(
      targetPlatform,
      applicationBinary: hotRunner.applicationBinary,
    );

    if (package == null) {
      String message = 'No application found for $targetPlatform.';
      final String hint = await getMissingPackageHintForPlatform(targetPlatform);
      if (hint != null)
        message += '\n$hint';
      printError(message);
      return 1;
    }

    final Map<String, dynamic> platformArgs = <String, dynamic>{};

    startEchoingDeviceLog();

    // Start the application.
    final Future<LaunchResult> futureResult = device.startApp(
      package,
      mainPath: hotRunner.mainPath,
      debuggingOptions: hotRunner.debuggingOptions,
      platformArgs: platformArgs,
      route: route,
      prebuiltApplication: prebuiltMode,
      usesTerminalUi: hotRunner.usesTerminalUI,
      ipv6: hotRunner.ipv6,
    );

    final LaunchResult result = await futureResult;

    if (!result.started) {
      printError('Error launching application on ${device.name}.');
      await stopEchoingDeviceLog();
      return 2;
    }
    if (result.hasObservatory) {
      observatoryUris = <Uri>[result.observatoryUri];
    } else {
      observatoryUris = <Uri>[];
    }
    return 0;
  }


  Future<int> runCold({
    ColdRunner coldRunner,
    String route,
    bool shouldBuild = true,
  }) async {
    final TargetPlatform targetPlatform = await device.targetPlatform;
    package = await ApplicationPackageFactory.instance.getPackageForPlatform(
      targetPlatform,
      applicationBinary: coldRunner.applicationBinary,
    );

    final String modeName = coldRunner.debuggingOptions.buildInfo.friendlyModeName;
    final bool prebuiltMode = coldRunner.applicationBinary != null;
    if (coldRunner.mainPath == null) {
      assert(prebuiltMode);
      printStatus('Launching ${package.displayName} on ${device.name} in $modeName mode...');
    } else {
      printStatus('Launching ${getDisplayPath(coldRunner.mainPath)} on ${device.name} in $modeName mode...');
    }

    if (package == null) {
      String message = 'No application found for $targetPlatform.';
      final String hint = await getMissingPackageHintForPlatform(targetPlatform);
      if (hint != null)
        message += '\n$hint';
      printError(message);
      return 1;
    }

    final Map<String, dynamic> platformArgs = <String, dynamic>{};
    if (coldRunner.traceStartup != null)
      platformArgs['trace-startup'] = coldRunner.traceStartup;

    startEchoingDeviceLog();

    final LaunchResult result = await device.startApp(
      package,
      mainPath: coldRunner.mainPath,
      debuggingOptions: coldRunner.debuggingOptions,
      platformArgs: platformArgs,
      route: route,
      prebuiltApplication: prebuiltMode,
      usesTerminalUi: coldRunner.usesTerminalUI,
      ipv6: coldRunner.ipv6,
    );

    if (!result.started) {
      printError('Error running application on ${device.name}.');
      await stopEchoingDeviceLog();
      return 2;
    }
    if (result.hasObservatory) {
      observatoryUris = <Uri>[result.observatoryUri];
    } else {
      observatoryUris = <Uri>[];
    }
    return 0;
  }

  Future<UpdateFSReport> updateDevFS({
    String mainPath,
    String target,
    AssetBundle bundle,
    DateTime firstBuildTime,
    bool bundleFirstUpload = false,
    bool bundleDirty = false,
    bool fullRestart = false,
    String projectRootPath,
    String pathToReload,
    @required List<Uri> invalidatedFiles,
  }) async {
    final Status devFSStatus = logger.startProgress(
      'Syncing files to device ${device.name}...',
      timeout: timeoutConfiguration.fastOperation,
    );
    UpdateFSReport report;
    try {
      report = await devFS.update(
        mainPath: mainPath,
        target: target,
        bundle: bundle,
        firstBuildTime: firstBuildTime,
        bundleFirstUpload: bundleFirstUpload,
        generator: generator,
        fullRestart: fullRestart,
        dillOutputPath: dillOutputPath,
        trackWidgetCreation: trackWidgetCreation,
        projectRootPath: projectRootPath,
        pathToReload: pathToReload,
        invalidatedFiles: invalidatedFiles,
      );
    } on DevFSException {
      devFSStatus.cancel();
      return UpdateFSReport(success: false);
    }
    devFSStatus.stop();
    printTrace('Synced ${getSizeAsMB(report.syncedBytes)}.');
    return report;
  }

  Future<void> updateReloadStatus(bool wasReloadSuccessful) async {
    if (wasReloadSuccessful)
      generator?.accept();
    else
      await generator?.reject();
  }
}

// Shared code between different resident application runners.
abstract class ResidentRunner {
  ResidentRunner(
    this.flutterDevices, {
    this.target,
    this.debuggingOptions,
    this.usesTerminalUI = true,
    String projectRootPath,
    String packagesFilePath,
    this.saveCompilationTrace,
    this.stayResident,
    this.ipv6,
  }) {
    _mainPath = findMainDartFile(target);
    _projectRootPath = projectRootPath ?? fs.currentDirectory.path;
    _packagesFilePath =
        packagesFilePath ?? fs.path.absolute(PackageMap.globalPackagesPath);
    _assetBundle = AssetBundleFactory.instance.createBundle();
  }

  final List<FlutterDevice> flutterDevices;
  final String target;
  final DebuggingOptions debuggingOptions;
  final bool usesTerminalUI;
  final bool saveCompilationTrace;
  final bool stayResident;
  final bool ipv6;
  final Completer<int> _finished = Completer<int>();
  bool _stopped = false;
  String _packagesFilePath;
  String get packagesFilePath => _packagesFilePath;
  String _projectRootPath;
  String get projectRootPath => _projectRootPath;
  String _mainPath;
  String get mainPath => _mainPath;
  String getReloadPath({ bool fullRestart }) => mainPath + (fullRestart ? '' : '.incremental') + '.dill';

  AssetBundle _assetBundle;
  AssetBundle get assetBundle => _assetBundle;

  bool get isRunningDebug => debuggingOptions.buildInfo.isDebug;
  bool get isRunningProfile => debuggingOptions.buildInfo.isProfile;
  bool get isRunningRelease => debuggingOptions.buildInfo.isRelease;
  bool get supportsServiceProtocol => isRunningDebug || isRunningProfile;

  /// Whether this runner can hot restart.
  ///
  /// To prevent scenarios where only a subset of devices are hot restarted,
  /// the runner requires that all attached devices can support hot restart
  /// before enabling it.
  bool get canHotRestart {
    return flutterDevices.every((FlutterDevice device) {
      return device.device.supportsHotRestart;
    });
  }

  /// Start the app and keep the process running during its lifetime.
  ///
  /// Returns the exit code that we should use for the flutter tool process; 0
  /// for success, 1 for user error (e.g. bad arguments), 2 for other failures.
  Future<int> run({
    Completer<DebugConnectionInfo> connectionInfoCompleter,
    Completer<void> appStartedCompleter,
    String route,
    bool shouldBuild = true,
  });

  Future<int> attach({
    Completer<DebugConnectionInfo> connectionInfoCompleter,
    Completer<void> appStartedCompleter,
  });

  bool get supportsRestart => false;

  Future<OperationResult> restart({ bool fullRestart = false, bool pauseAfterRestart = false, String reason }) {
    final String mode = isRunningProfile ? 'profile' :
        isRunningRelease ? 'release' : 'this';
    throw '${fullRestart ? 'Restart' : 'Reload'} is not supported in $mode mode';
  }

  Future<void> stop() async {
    _stopped = true;
    if (saveCompilationTrace)
      await _debugSaveCompilationTrace();
    await stopEchoingDeviceLog();
    await preStop();
    await stopApp();
  }

  Future<void> detach() async {
    await stopEchoingDeviceLog();
    await preStop();
    appFinished();
  }

  Future<void> refreshViews() async {
    final List<Future<void>> futures = <Future<void>>[];
    for (FlutterDevice device in flutterDevices)
      futures.add(device.refreshViews());
    await Future.wait(futures);
  }

  Future<void> _debugDumpApp() async {
    await refreshViews();
    for (FlutterDevice device in flutterDevices)
      await device.debugDumpApp();
  }

  Future<void> _debugDumpRenderTree() async {
    await refreshViews();
    for (FlutterDevice device in flutterDevices)
      await device.debugDumpRenderTree();
  }

  Future<void> _debugDumpLayerTree() async {
    await refreshViews();
    for (FlutterDevice device in flutterDevices)
      await device.debugDumpLayerTree();
  }

  Future<void> _debugDumpSemanticsTreeInTraversalOrder() async {
    await refreshViews();
    for (FlutterDevice device in flutterDevices)
      await device.debugDumpSemanticsTreeInTraversalOrder();
  }

  Future<void> _debugDumpSemanticsTreeInInverseHitTestOrder() async {
    await refreshViews();
    for (FlutterDevice device in flutterDevices)
      await device.debugDumpSemanticsTreeInInverseHitTestOrder();
  }

  Future<void> _debugToggleDebugPaintSizeEnabled() async {
    await refreshViews();
    for (FlutterDevice device in flutterDevices)
      await device.toggleDebugPaintSizeEnabled();
  }

  Future<void> _debugToggleDebugCheckElevationsEnabled() async {
    await refreshViews();
    for (FlutterDevice device in flutterDevices)
      await device.toggleDebugCheckElevationsEnabled();
  }

  Future<void> _debugTogglePerformanceOverlayOverride() async {
    await refreshViews();
    for (FlutterDevice device in flutterDevices)
      await device.debugTogglePerformanceOverlayOverride();
  }

  Future<void> _debugToggleWidgetInspector() async {
    await refreshViews();
    for (FlutterDevice device in flutterDevices)
      await device.toggleWidgetInspector();
  }

  Future<void> _debugToggleProfileWidgetBuilds() async {
    await refreshViews();
    for (FlutterDevice device in flutterDevices) {
      await device.toggleProfileWidgetBuilds();
    }
  }

  Future<void> _screenshot(FlutterDevice device) async {
    final Status status = logger.startProgress('Taking screenshot for ${device.device.name}...', timeout: timeoutConfiguration.fastOperation);
    final File outputFile = getUniqueFile(fs.currentDirectory, 'flutter', 'png');
    try {
      if (supportsServiceProtocol && isRunningDebug) {
        await device.refreshViews();
        try {
          for (FlutterView view in device.views)
            await view.uiIsolate.flutterDebugAllowBanner(false);
        } catch (error) {
          status.cancel();
          printError('Error communicating with Flutter on the device: $error');
          return;
        }
      }
      try {
        await device.device.takeScreenshot(outputFile);
      } finally {
        if (supportsServiceProtocol && isRunningDebug) {
          try {
            for (FlutterView view in device.views)
              await view.uiIsolate.flutterDebugAllowBanner(true);
          } catch (error) {
            status.cancel();
            printError('Error communicating with Flutter on the device: $error');
            return;
          }
        }
      }
      final int sizeKB = (await outputFile.length()) ~/ 1024;
      status.stop();
      printStatus('Screenshot written to ${fs.path.relative(outputFile.path)} (${sizeKB}kB).');
    } catch (error) {
      status.cancel();
      printError('Error taking screenshot: $error');
    }
  }

  Future<void> _debugSaveCompilationTrace() async {
    if (!supportsServiceProtocol)
      return;

    for (FlutterDevice device in flutterDevices) {
      for (FlutterView view in device.views) {
        final int index = device.views.indexOf(view);
        final File outputFile = fs.currentDirectory
            .childFile('compilation${index == 0 ? '' : index}.txt');

        printStatus('Saving compilation training data '
            'for ${device.device.name}${index == 0 ? '' :'/Isolate$index'} '
            'to ${fs.path.relative(outputFile.path)}...');

        List<int> buffer;
        try {
          buffer = await view.uiIsolate.flutterDebugSaveCompilationTrace();
          assert(buffer != null);
        } catch (error) {
          printError('Error communicating with Flutter on the device: $error');
          continue;
        }

        outputFile.parent.createSync(recursive: true);
        outputFile.writeAsBytesSync(buffer);
      }
    }
  }

  Future<void> _debugTogglePlatform() async {
    await refreshViews();
    final String from = await flutterDevices[0].views[0].uiIsolate.flutterPlatformOverride();
    String to;
    for (FlutterDevice device in flutterDevices)
      to = await device.togglePlatform(from: from);
    printStatus('Switched operating system to $to');
  }

  void registerSignalHandlers() {
    assert(stayResident);
    ProcessSignal.SIGINT.watch().listen(_cleanUpAndExit);
    ProcessSignal.SIGTERM.watch().listen(_cleanUpAndExit);
    if (!supportsServiceProtocol || !supportsRestart)
      return;
    ProcessSignal.SIGUSR1.watch().listen(_handleSignal);
    ProcessSignal.SIGUSR2.watch().listen(_handleSignal);
  }

  Future<void> _cleanUpAndExit(ProcessSignal signal) async {
    _resetTerminal();
    await cleanupAfterSignal();
    exit(0);
  }

  bool _processingUserRequest = false;
  Future<void> _handleSignal(ProcessSignal signal) async {
    if (_processingUserRequest) {
      printTrace('Ignoring signal: "$signal" because we are busy.');
      return;
    }
    _processingUserRequest = true;

    final bool fullRestart = signal == ProcessSignal.SIGUSR2;

    try {
      await restart(fullRestart: fullRestart);
    } finally {
      _processingUserRequest = false;
    }
  }

  Future<void> stopEchoingDeviceLog() async {
    await Future.wait<void>(
      flutterDevices.map<Future<void>>((FlutterDevice device) => device.stopEchoingDeviceLog())
    );
  }

  /// If the [reloadSources] parameter is not null the 'reloadSources' service
  /// will be registered.
  //
  // Failures should be indicated by completing the future with an error, using
  // a string as the error object, which will be used by the caller (attach())
  // to display an error message.
  Future<void> connectToServiceProtocol({
    ReloadSources reloadSources,
    Restart restart,
    CompileExpression compileExpression,
  }) async {
    if (!debuggingOptions.debuggingEnabled)
      throw 'The service protocol is not enabled.';

    bool viewFound = false;
    for (FlutterDevice device in flutterDevices) {
      await device._connect(
        reloadSources: reloadSources,
        restart: restart,
        compileExpression: compileExpression,
      );
      await device.getVMs();
      await device.refreshViews();
      if (device.views.isNotEmpty)
        viewFound = true;
    }
    if (!viewFound) {
      if (flutterDevices.length == 1)
        throw 'No Flutter view is available on ${flutterDevices.first.device.name}.';
      throw 'No Flutter view is available on any device '
            '(${flutterDevices.map<String>((FlutterDevice device) => device.device.name).join(', ')}).';
    }

    // Listen for service protocol connection to close.
    for (FlutterDevice device in flutterDevices) {
      for (VMService service in device.vmServices) {
        // This hooks up callbacks for when the connection stops in the future.
        // We don't want to wait for them. We don't handle errors in those callbacks'
        // futures either because they just print to logger and is not critical.
        unawaited(service.done.then<void>(
          _serviceProtocolDone,
          onError: _serviceProtocolError,
        ).whenComplete(_serviceDisconnected));
      }
    }
  }

  Future<void> _serviceProtocolDone(dynamic object) {
    printTrace('Service protocol connection closed.');
    return Future<void>.value(object);
  }

  Future<void> _serviceProtocolError(dynamic error, StackTrace stack) {
    printTrace('Service protocol connection closed with an error: $error\n$stack');
    return Future<void>.error(error, stack);
  }

  /// Returns [true] if the input has been handled by this function.
  Future<bool> _commonTerminalInputHandler(String character) async {
    final String lower = character.toLowerCase();

    printStatus(''); // the key the user tapped might be on this line

    if (lower == 'h' || lower == '?') {
      // help
      printHelp(details: true);
      return true;
    } else if (lower == 'w') {
      if (supportsServiceProtocol) {
        await _debugDumpApp();
        return true;
      }
    } else if (lower == 't') {
      if (supportsServiceProtocol) {
        await _debugDumpRenderTree();
        return true;
      }
    } else if (character == 'L') {
      if (supportsServiceProtocol) {
        await _debugDumpLayerTree();
        return true;
      }
    } else if (character == 'S') {
      if (supportsServiceProtocol) {
        await _debugDumpSemanticsTreeInTraversalOrder();
        return true;
      }
    } else if (character == 'U') {
      if (supportsServiceProtocol) {
        await _debugDumpSemanticsTreeInInverseHitTestOrder();
        return true;
      }
    } else if (character == 'p') {
      if (supportsServiceProtocol && isRunningDebug) {
        await _debugToggleDebugPaintSizeEnabled();
        return true;
      }
    } else if (character == 'P') {
      if (supportsServiceProtocol) {
        await _debugTogglePerformanceOverlayOverride();
      }
    } else if (lower == 'i') {
      if (supportsServiceProtocol) {
        await _debugToggleWidgetInspector();
        return true;
      }
    } else if (character == 's') {
      for (FlutterDevice device in flutterDevices) {
        if (device.device.supportsScreenshot)
          await _screenshot(device);
      }
      return true;
    } else if (character == 'a') {
      if (supportsServiceProtocol) {
        await _debugToggleProfileWidgetBuilds();
      }
    } else if (lower == 'o') {
      if (supportsServiceProtocol && isRunningDebug) {
        await _debugTogglePlatform();
        return true;
      }
    } else if (lower == 'q') {
      // exit
      await stop();
      return true;
    } else if (lower == 'd') {
      await detach();
      return true;
    } else if (lower == 'z') {
      await _debugToggleDebugCheckElevationsEnabled();
      return true;
    }

    return false;
  }

  Future<void> processTerminalInput(String command) async {
    // When terminal doesn't support line mode, '\n' can sneak into the input.
    command = command.trim();
    if (_processingUserRequest) {
      printTrace('Ignoring terminal input: "$command" because we are busy.');
      return;
    }
    _processingUserRequest = true;
    try {
      final bool handled = await _commonTerminalInputHandler(command);
      if (!handled)
        await handleTerminalCommand(command);
    } catch (error, st) {
      printError('$error\n$st');
      await _cleanUpAndExit(null);
    } finally {
      _processingUserRequest = false;
    }
  }

  void _serviceDisconnected() {
    if (_stopped) {
      // User requested the application exit.
      return;
    }
    if (_finished.isCompleted)
      return;
    printStatus('Lost connection to device.');
    _resetTerminal();
    _finished.complete(0);
  }

  void appFinished() {
    if (_finished.isCompleted)
      return;
    printStatus('Application finished.');
    _resetTerminal();
    _finished.complete(0);
  }

  void _resetTerminal() {
    if (usesTerminalUI)
      terminal.singleCharMode = false;
  }

  void setupTerminal() {
    assert(stayResident);
    if (usesTerminalUI) {
      if (!logger.quiet) {
        printStatus('');
        printHelp(details: false);
      }
      terminal.singleCharMode = true;
      terminal.keystrokes.listen(processTerminalInput);
    }
  }

  Future<int> waitForAppToFinish() async {
    final int exitCode = await _finished.future;
    assert(exitCode != null);
    await cleanupAtFinish();
    return exitCode;
  }

  Future<void> preStop() async { }

  Future<void> stopApp() async {
    final List<Future<void>> futures = <Future<void>>[];
    for (FlutterDevice device in flutterDevices)
      futures.add(device.stopApps());
    await Future.wait(futures);
    appFinished();
  }

  /// Called to print help to the terminal.
  void printHelp({ @required bool details });

  void printHelpDetails() {
    if (supportsServiceProtocol) {
      printStatus('You can dump the widget hierarchy of the app (debugDumpApp) by pressing "w".');
      printStatus('To dump the rendering tree of the app (debugDumpRenderTree), press "t".');
      if (isRunningDebug) {
        printStatus('For layers (debugDumpLayerTree), use "L"; for accessibility (debugDumpSemantics), use "S" (for traversal order) or "U" (for inverse hit test order).');
        printStatus('To toggle the widget inspector (WidgetsApp.showWidgetInspectorOverride), press "i".');
        printStatus('To toggle the display of construction lines (debugPaintSizeEnabled), press "p".');
        printStatus('To simulate different operating systems, (defaultTargetPlatform), press "o".');
        printStatus('To toggle the elevation checker, press "z".');
      } else {
        printStatus('To dump the accessibility tree (debugDumpSemantics), press "S" (for traversal order) or "U" (for inverse hit test order).');
      }
      printStatus('To display the performance overlay (WidgetsApp.showPerformanceOverlay), press "P".');
      printStatus('To enable timeline events for all widget build methods, (debugProfileWidgetBuilds), press "a"');
    }
    if (flutterDevices.any((FlutterDevice d) => d.device.supportsScreenshot)) {
      printStatus('To save a screenshot to flutter.png, press "s".');
    }
  }

  /// Called when a signal has requested we exit.
  Future<void> cleanupAfterSignal();
  /// Called right before we exit.
  Future<void> cleanupAtFinish();
  /// Called when the runner should handle a terminal command.
  Future<void> handleTerminalCommand(String code);
}

class OperationResult {
  OperationResult(this.code, this.message);

  /// The result of the operation; a non-zero code indicates a failure.
  final int code;

  /// A user facing message about the results of the operation.
  final String message;

  bool get isOk => code == 0;

  static final OperationResult ok = OperationResult(0, '');
}

/// Given the value of the --target option, return the path of the Dart file
/// where the app's main function should be.
String findMainDartFile([ String target ]) {
  target ??= '';
  final String targetPath = fs.path.absolute(target);
  if (fs.isDirectorySync(targetPath))
    return fs.path.join(targetPath, 'lib', 'main.dart');
  else
    return targetPath;
}

Future<String> getMissingPackageHintForPlatform(TargetPlatform platform) async {
  switch (platform) {
    case TargetPlatform.android_arm:
    case TargetPlatform.android_arm64:
    case TargetPlatform.android_x64:
    case TargetPlatform.android_x86:
      final FlutterProject project = await FlutterProject.current();
      final String manifestPath = fs.path.relative(project.android.appManifestFile.path);
      return 'Is your project missing an $manifestPath?\nConsider running "flutter create ." to create one.';
    case TargetPlatform.ios:
      return 'Is your project missing an ios/Runner/Info.plist?\nConsider running "flutter create ." to create one.';
    default:
      return null;
  }
}

class DebugConnectionInfo {
  DebugConnectionInfo({ this.httpUri, this.wsUri, this.baseUri });

  // TODO(danrubel): the httpUri field should be removed as part of
  // https://github.com/flutter/flutter/issues/7050
  final Uri httpUri;
  final Uri wsUri;
  final String baseUri;
}
