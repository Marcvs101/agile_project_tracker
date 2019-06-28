// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:meta/meta.dart';
import 'package:quiver/strings.dart';

import '../application_package.dart';
import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/terminal.dart';
import '../base/time.dart';
import '../base/user_messages.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../bundle.dart' as bundle;
import '../cache.dart';
import '../dart/package_map.dart';
import '../dart/pub.dart';
import '../device.dart';
import '../doctor.dart';
import '../globals.dart';
import '../project.dart';
import '../usage.dart';
import '../version.dart';
import 'flutter_command_runner.dart';

export '../cache.dart' show DevelopmentArtifact;

enum ExitStatus {
  success,
  warning,
  fail,
}

/// [FlutterCommand]s' subclasses' [FlutterCommand.runCommand] can optionally
/// provide a [FlutterCommandResult] to furnish additional information for
/// analytics.
class FlutterCommandResult {
  const FlutterCommandResult(
    this.exitStatus, {
    this.timingLabelParts,
    this.endTimeOverride,
  });

  final ExitStatus exitStatus;

  /// Optional data that can be appended to the timing event.
  /// https://developers.google.com/analytics/devguides/collection/analyticsjs/field-reference#timingLabel
  /// Do not add PII.
  final List<String> timingLabelParts;

  /// Optional epoch time when the command's non-interactive wait time is
  /// complete during the command's execution. Use to measure user perceivable
  /// latency without measuring user interaction time.
  ///
  /// [FlutterCommand] will automatically measure and report the command's
  /// complete time if not overridden.
  final DateTime endTimeOverride;
}

/// Common flutter command line options.
class FlutterOptions {
  static const String kExtraFrontEndOptions = 'extra-front-end-options';
  static const String kExtraGenSnapshotOptions = 'extra-gen-snapshot-options';
  static const String kEnableExperiment = 'enable-experiment';
  static const String kFileSystemRoot = 'filesystem-root';
  static const String kFileSystemScheme = 'filesystem-scheme';
}

abstract class FlutterCommand extends Command<void> {
  /// The currently executing command (or sub-command).
  ///
  /// Will be `null` until the top-most command has begun execution.
  static FlutterCommand get current => context[FlutterCommand];

  /// The option name for a custom observatory port.
  static const String observatoryPortOption = 'observatory-port';

  /// The flag name for whether or not to use ipv6.
  static const String ipv6Flag = 'ipv6';

  @override
  ArgParser get argParser => _argParser;
  final ArgParser _argParser = ArgParser(
    allowTrailingOptions: false,
    usageLineLength: outputPreferences.wrapText ? outputPreferences.wrapColumn : null,
  );

  @override
  FlutterCommandRunner get runner => super.runner;

  bool _requiresPubspecYaml = false;

  /// Whether this command uses the 'target' option.
  bool _usesTargetOption = false;

  bool _usesPubOption = false;

  bool _usesPortOption = false;

  bool _usesIpv6Flag = false;

  bool get shouldRunPub => _usesPubOption && argResults['pub'];

  bool get shouldUpdateCache => true;

  BuildMode _defaultBuildMode;

  void requiresPubspecYaml() {
    _requiresPubspecYaml = true;
  }

  void usesTargetOption() {
    argParser.addOption('target',
      abbr: 't',
      defaultsTo: bundle.defaultMainPath,
      help: 'The main entry-point file of the application, as run on the device.\n'
            'If the --target option is omitted, but a file name is provided on '
            'the command line, then that is used instead.',
      valueHelp: 'path');
    _usesTargetOption = true;
  }

  String get targetFile {
    if (argResults.wasParsed('target'))
      return argResults['target'];
    else if (argResults.rest.isNotEmpty)
      return argResults.rest.first;
    else
      return bundle.defaultMainPath;
  }

  void usesPubOption() {
    argParser.addFlag('pub',
      defaultsTo: true,
      help: 'Whether to run "flutter packages get" before executing this command.');
    _usesPubOption = true;
  }

  /// Adds flags for using a specific filesystem root and scheme.
  ///
  /// [hide] indicates whether or not to hide these options when the user asks
  /// for help.
  void usesFilesystemOptions({ @required bool hide }) {
    argParser
      ..addOption('output-dill',
        hide: hide,
        help: 'Specify the path to frontend server output kernel file.',
      )
      ..addMultiOption(FlutterOptions.kFileSystemRoot,
        hide: hide,
        help: 'Specify the path, that is used as root in a virtual file system\n'
            'for compilation. Input file name should be specified as Uri in\n'
            'filesystem-scheme scheme. Use only in Dart 2 mode.\n'
            'Requires --output-dill option to be explicitly specified.\n',
      )
      ..addOption(FlutterOptions.kFileSystemScheme,
        defaultsTo: 'org-dartlang-root',
        hide: hide,
        help: 'Specify the scheme that is used for virtual file system used in\n'
            'compilation. See more details on filesystem-root option.\n',
      );
  }

  /// Adds options for connecting to the Dart VM observatory port.
  void usesPortOptions() {
    argParser.addOption(observatoryPortOption,
        help: 'Listen to the given port for an observatory debugger connection.\n'
              'Specifying port 0 (the default) will find a random free port.',
    );
    _usesPortOption = true;
  }

  /// Gets the observatory port provided to in the 'observatory-port' option.
  ///
  /// If no port is set, returns null.
  int get observatoryPort {
    if (!_usesPortOption || argResults['observatory-port'] == null) {
      return null;
    }
    try {
      return int.parse(argResults['observatory-port']);
    } catch (error) {
      throwToolExit('Invalid port for `--observatory-port`: $error');
    }
    return null;
  }

  void usesIpv6Flag() {
    argParser.addFlag(ipv6Flag,
      hide: true,
      negatable: false,
      help: 'Binds to IPv6 localhost instead of IPv4 when the flutter tool '
            'forwards the host port to a device port. Not used when the '
            '--debug-port flag is not set.',
    );
    _usesIpv6Flag = true;
  }

  bool get ipv6 => _usesIpv6Flag ? argResults['ipv6'] : null;

  void usesBuildNumberOption() {
    argParser.addOption('build-number',
        help: 'An identifier used as an internal version number.\n'
              'Each build must have a unique identifier to differentiate it from previous builds.\n'
              'It is used to determine whether one build is more recent than another, with higher numbers indicating more recent build.\n'
              'On Android it is used as \'versionCode\'.\n'
              'On Xcode builds it is used as \'CFBundleVersion\'',
    );
  }

  void usesBuildNameOption() {
    argParser.addOption('build-name',
        help: 'A "x.y.z" string used as the version number shown to users.\n'
              'For each new version of your app, you will provide a version number to differentiate it from previous versions.\n'
              'On Android it is used as \'versionName\'.\n'
              'On Xcode builds it is used as \'CFBundleShortVersionString\'',
        valueHelp: 'x.y.z');
  }

  void usesIsolateFilterOption({ @required bool hide }) {
    argParser.addOption('isolate-filter',
      defaultsTo: null,
      hide: hide,
      help: 'Restricts commands to a subset of the available isolates (running instances of Flutter).\n'
            'Normally there\'s only one, but when adding Flutter to a pre-existing app it\'s possible to create multiple.');
  }

  void addBuildModeFlags({ bool defaultToRelease = true, bool verboseHelp = false }) {
    defaultBuildMode = defaultToRelease ? BuildMode.release : BuildMode.debug;

    argParser.addFlag('debug',
      negatable: false,
      help: 'Build a debug version of your app${defaultToRelease ? '' : ' (default mode)'}.');
    argParser.addFlag('profile',
      negatable: false,
      help: 'Build a version of your app specialized for performance profiling.');
    argParser.addFlag('release',
      negatable: false,
      help: 'Build a release version of your app${defaultToRelease ? ' (default mode)' : ''}.');
    argParser.addFlag('dynamic',
      hide: !verboseHelp,
      negatable: false,
      help: 'Enable dynamic code. Only allowed with --release or --profile.');
  }

  void addDynamicModeFlags({ bool verboseHelp = false }) {
    argParser.addOption('compilation-trace-file',
        defaultsTo: 'compilation.txt',
        hide: !verboseHelp,
        help: 'Filename of Dart compilation trace file. This file will be produced\n'
              'by \'flutter run --dynamic --profile --train\' and consumed by subsequent\n'
              '--dynamic builds such as \'flutter build apk --dynamic\' to precompile\n'
              'some code by the offline compiler.',
    );
    argParser.addFlag('patch',
        hide: !verboseHelp,
        negatable: false,
        help: 'Generate dynamic patch for current changes from baseline.\n'
              'Dynamic patch is generated relative to baseline package.\n'
              'This flag is only allowed when using --dynamic.\n',
    );
  }

  void addDynamicPatchingFlags({ bool verboseHelp = false }) {
    argParser.addOption('patch-number',
        hide: !verboseHelp,
        help: 'An integer used as an internal version number for dynamic patch.\n'
              'Each update may have a unique number to differentiate from previous\n'
              'patches for same \'versionCode\' on Android or \'CFBundleVersion\' on iOS.\n'
              'This optional setting allows several dynamic patches to coexist\n'
              'for same baseline build, and is useful for canary and A-B testing\n'
              'of dynamic patches.\n'
              'This flag is only used when --dynamic --patch is specified.\n',
    );
    argParser.addOption('patch-dir',
        defaultsTo: 'public',
        hide: !verboseHelp,
        help: 'The directory where to store generated dynamic patches.\n'
              'This directory can be deployed to a CDN such as Firebase Hosting.\n'
              'It is recommended to store this directory in version control.\n'
              'This flag is only used when --dynamic --patch is specified.\n',
    );
    argParser.addFlag('baseline',
        hide: !verboseHelp,
        negatable: false,
        help: 'Save built package as baseline for future dynamic patching.\n'
            'Built package, such as APK file on Android, is saved and '
            'can be used to generate dynamic patches in later builds.\n'
            'This flag is only allowed when using --dynamic.\n',
    );

    addDynamicBaselineFlags(verboseHelp: verboseHelp);
  }

  void addDynamicBaselineFlags({ bool verboseHelp = false }) {
    argParser.addOption('baseline-dir',
        defaultsTo: '.baseline',
        hide: !verboseHelp,
        help: 'The directory where to store and find generated baseline packages.\n'
              'It is recommended to store this directory in version control.\n'
              'This flag is only used when --dynamic --baseline is specified.\n',
    );
  }

  void usesFuchsiaOptions({ bool hide = false }) {
    argParser.addOption(
      'target-model',
      help: 'Target model that determines what core libraries are available',
      defaultsTo: 'flutter',
      hide: hide,
      allowed: const <String>['flutter', 'flutter_runner'],
    );
    argParser.addOption(
      'module',
      abbr: 'm',
      hide: hide,
      help: 'The name of the module (required if attaching to a fuchsia device)',
      valueHelp: 'module-name',
    );
  }

  set defaultBuildMode(BuildMode value) {
    _defaultBuildMode = value;
  }

  BuildMode getBuildMode() {
    final List<bool> modeFlags = <bool>[argResults['debug'], argResults['profile'], argResults['release']];
    if (modeFlags.where((bool flag) => flag).length > 1)
      throw UsageException('Only one of --debug, --profile, or --release can be specified.', null);
    final bool dynamicFlag = argParser.options.containsKey('dynamic')
        ? argResults['dynamic']
        : false;

    if (argResults['debug']) {
      if (dynamicFlag)
        throw ToolExit('Error: --dynamic requires --release or --profile.');
      return BuildMode.debug;
    }
    if (argResults['profile'])
      return dynamicFlag ? BuildMode.dynamicProfile : BuildMode.profile;
    if (argResults['release'])
      return dynamicFlag ? BuildMode.dynamicRelease : BuildMode.release;

    if (_defaultBuildMode == BuildMode.debug && dynamicFlag)
      throw ToolExit('Error: --dynamic requires --release or --profile.');
    if (_defaultBuildMode == BuildMode.release && dynamicFlag)
      return BuildMode.dynamicRelease;
    if (_defaultBuildMode == BuildMode.profile && dynamicFlag)
      return BuildMode.dynamicProfile;

    return _defaultBuildMode;
  }

  void usesFlavorOption() {
    argParser.addOption(
      'flavor',
      help: 'Build a custom app flavor as defined by platform-specific build setup.\n'
        'Supports the use of product flavors in Android Gradle scripts.\n'
        'Supports the use of custom Xcode schemes.',
    );
  }

  BuildInfo getBuildInfo() {
    TargetPlatform targetPlatform;
    if (argParser.options.containsKey('target-platform') &&
        argResults['target-platform'] != 'default') {
      targetPlatform = getTargetPlatformForName(argResults['target-platform']);
    }

    final bool trackWidgetCreation = argParser.options.containsKey('track-widget-creation')
        ? argResults['track-widget-creation']
        : false;

    final String buildNumber = argParser.options.containsKey('build-number') && argResults['build-number'] != null
        ? argResults['build-number']
        : null;

    int patchNumber;
    try {
      patchNumber = argParser.options.containsKey('patch-number') && argResults['patch-number'] != null
          ? int.parse(argResults['patch-number'])
          : null;
    } catch (e) {
      throw UsageException(
          '--patch-number (${argResults['patch-number']}) must be an int.', null);
    }

    String extraFrontEndOptions =
        argParser.options.containsKey(FlutterOptions.kExtraFrontEndOptions)
            ? argResults[FlutterOptions.kExtraFrontEndOptions]
            : null;
    if (argParser.options.containsKey(FlutterOptions.kEnableExperiment) &&
        argResults[FlutterOptions.kEnableExperiment] != null) {
      for (String expFlag in argResults[FlutterOptions.kEnableExperiment]) {
        final String flag = '--enable-experiment=' + expFlag;
        if (extraFrontEndOptions != null) {
          extraFrontEndOptions += ',' + flag;
        } else {
          extraFrontEndOptions = flag;
        }
      }
    }

    return BuildInfo(getBuildMode(),
      argParser.options.containsKey('flavor')
        ? argResults['flavor']
        : null,
      trackWidgetCreation: trackWidgetCreation,
      compilationTraceFilePath: argParser.options.containsKey('compilation-trace-file')
          ? argResults['compilation-trace-file']
          : null,
      createBaseline: argParser.options.containsKey('baseline')
          ? argResults['baseline']
          : false,
      createPatch: argParser.options.containsKey('patch')
          ? argResults['patch']
          : false,
      patchNumber: patchNumber,
      patchDir: argParser.options.containsKey('patch-dir')
          ? argResults['patch-dir']
          : null,
      baselineDir: argParser.options.containsKey('baseline-dir')
          ? argResults['baseline-dir']
          : null,
      extraFrontEndOptions: extraFrontEndOptions,
      extraGenSnapshotOptions: argParser.options.containsKey(FlutterOptions.kExtraGenSnapshotOptions)
          ? argResults[FlutterOptions.kExtraGenSnapshotOptions]
          : null,
      buildSharedLibrary: argParser.options.containsKey('build-shared-library')
        ? argResults['build-shared-library']
        : false,
      targetPlatform: targetPlatform,
      fileSystemRoots: argParser.options.containsKey(FlutterOptions.kFileSystemRoot)
          ? argResults[FlutterOptions.kFileSystemRoot] : null,
      fileSystemScheme: argParser.options.containsKey(FlutterOptions.kFileSystemScheme)
          ? argResults[FlutterOptions.kFileSystemScheme] : null,
      buildNumber: buildNumber,
      buildName: argParser.options.containsKey('build-name')
          ? argResults['build-name']
          : null,
    );
  }

  void setupApplicationPackages() {
    applicationPackages ??= ApplicationPackageStore();
  }

  /// The path to send to Google Analytics. Return null here to disable
  /// tracking of the command.
  Future<String> get usagePath async {
    if (parent is FlutterCommand) {
      final FlutterCommand commandParent = parent;
      final String path = await commandParent.usagePath;
      // Don't report for parents that return null for usagePath.
      return path == null ? null : '$path/$name';
    } else {
      return name;
    }
  }

  /// Whether this feature should not be usable on stable branches.
  ///
  /// Defaults to false, meaning it is usable.
  bool get isExperimental => false;

  /// Additional usage values to be sent with the usage ping.
  Future<Map<String, String>> get usageValues async => const <String, String>{};

  /// Runs this command.
  ///
  /// Rather than overriding this method, subclasses should override
  /// [verifyThenRunCommand] to perform any verification
  /// and [runCommand] to execute the command
  /// so that this method can record and report the overall time to analytics.
  @override
  Future<void> run() {
    final DateTime startTime = systemClock.now();

    return context.run<void>(
      name: 'command',
      overrides: <Type, Generator>{FlutterCommand: () => this},
      body: () async {
        if (flutterUsage.isFirstRun)
          flutterUsage.printWelcome();
        final String commandPath = await usagePath;
        FlutterCommandResult commandResult;
        try {
          commandResult = await verifyThenRunCommand(commandPath);
        } on ToolExit {
          commandResult = const FlutterCommandResult(ExitStatus.fail);
          rethrow;
        } finally {
          final DateTime endTime = systemClock.now();
          printTrace(userMessages.flutterElapsedTime(name, getElapsedAsMilliseconds(endTime.difference(startTime))));
          printTrace('"flutter $name" took ${getElapsedAsMilliseconds(endTime.difference(startTime))}.');
          if (commandPath != null) {
            final List<String> labels = <String>[];
            if (commandResult?.exitStatus != null)
              labels.add(getEnumName(commandResult.exitStatus));
            if (commandResult?.timingLabelParts?.isNotEmpty ?? false)
              labels.addAll(commandResult.timingLabelParts);

            final String label = labels
                .where((String label) => !isBlank(label))
                .join('-');
            flutterUsage.sendTiming(
              'flutter',
              name,
              // If the command provides its own end time, use it. Otherwise report
              // the duration of the entire execution.
              (commandResult?.endTimeOverride ?? endTime).difference(startTime),
              // Report in the form of `success-[parameter1-parameter2]`, all of which
              // can be null if the command doesn't provide a FlutterCommandResult.
              label: label == '' ? null : label,
            );
          }
        }
      },
    );
  }

  /// Perform validation then call [runCommand] to execute the command.
  /// Return a [Future] that completes with an exit code
  /// indicating whether execution was successful.
  ///
  /// Subclasses should override this method to perform verification
  /// then call this method to execute the command
  /// rather than calling [runCommand] directly.
  @mustCallSuper
  Future<FlutterCommandResult> verifyThenRunCommand(String commandPath) async {
    await validateCommand();

    // Populate the cache. We call this before pub get below so that the sky_engine
    // package is available in the flutter cache for pub to find.
    if (shouldUpdateCache) {
      await cache.updateAll(await requiredArtifacts);
    }

    if (shouldRunPub) {
      await pubGet(context: PubContext.getVerifyContext(name));
      final FlutterProject project = await FlutterProject.current();
      await project.ensureReadyForPlatformSpecificTooling();
    }

    setupApplicationPackages();

    if (commandPath != null) {
      final Map<String, String> additionalUsageValues = await usageValues;
      flutterUsage.sendCommand(commandPath, parameters: additionalUsageValues);
    }

    return await runCommand();
  }

  /// The set of development artifacts required for this command.
  ///
  /// Defaults to [DevelopmentArtifact.universal],
  /// [DevelopmentArtifact.android], and [DevelopmentArtifact.iOS].
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{
    DevelopmentArtifact.universal,
    DevelopmentArtifact.iOS,
    DevelopmentArtifact.android,
  };

  /// Subclasses must implement this to execute the command.
  /// Optionally provide a [FlutterCommandResult] to send more details about the
  /// execution for analytics.
  Future<FlutterCommandResult> runCommand();

  /// Find and return all target [Device]s based upon currently connected
  /// devices and criteria entered by the user on the command line.
  /// If no device can be found that meets specified criteria,
  /// then print an error message and return null.
  Future<List<Device>> findAllTargetDevices() async {
    if (!doctor.canLaunchAnything) {
      printError(userMessages.flutterNoDevelopmentDevice);
      return null;
    }

    List<Device> devices = await deviceManager.getDevices().toList();

    if (devices.isEmpty && deviceManager.hasSpecifiedDeviceId) {
      printStatus(userMessages.flutterNoMatchingDevice(deviceManager.specifiedDeviceId));
      return null;
    } else if (devices.isEmpty && deviceManager.hasSpecifiedAllDevices) {
      printStatus(userMessages.flutterNoDevicesFound);
      return null;
    } else if (devices.isEmpty) {
      printNoConnectedDevices();
      return null;
    }

    devices = devices.where((Device device) => device.isSupported()).toList();

    if (devices.isEmpty) {
      printStatus(userMessages.flutterNoSupportedDevices);
      return null;
    } else if (devices.length > 1 && !deviceManager.hasSpecifiedAllDevices) {
      if (deviceManager.hasSpecifiedDeviceId) {
        printStatus(userMessages.flutterFoundSpecifiedDevices(devices.length, deviceManager.specifiedDeviceId));
      } else {
        printStatus(userMessages.flutterSpecifyDeviceWithAllOption);
        devices = await deviceManager.getAllConnectedDevices().toList();
      }
      printStatus('');
      await Device.printDevices(devices);
      return null;
    }
    return devices;
  }

  /// Find and return the target [Device] based upon currently connected
  /// devices and criteria entered by the user on the command line.
  /// If a device cannot be found that meets specified criteria,
  /// then print an error message and return null.
  Future<Device> findTargetDevice() async {
    List<Device> deviceList = await findAllTargetDevices();
    if (deviceList == null)
      return null;
    if (deviceList.length > 1) {
      printStatus(userMessages.flutterSpecifyDevice);
      deviceList = await deviceManager.getAllConnectedDevices().toList();
      printStatus('');
      await Device.printDevices(deviceList);
      return null;
    }
    return deviceList.single;
  }

  void printNoConnectedDevices() {
    printStatus(userMessages.flutterNoConnectedDevices);
  }

  @protected
  @mustCallSuper
  Future<void> validateCommand() async {
    // If we're on a stable branch, then don't allow the usage of
    // "experimental" features.
    if (isExperimental && FlutterVersion.instance.isStable) {
      throwToolExit('Experimental feature $name is not supported on stable branches');
    }

    if (_requiresPubspecYaml && !PackageMap.isUsingCustomPackagesPath) {
      // Don't expect a pubspec.yaml file if the user passed in an explicit .packages file path.
      if (!fs.isFileSync('pubspec.yaml')) {
        throw ToolExit(userMessages.flutterNoPubspec);
      }

      if (fs.isFileSync('flutter.yaml')) {
        throw ToolExit(userMessages.flutterMergeYamlFiles);
      }

      // Validate the current package map only if we will not be running "pub get" later.
      if (parent?.name != 'packages' && !(_usesPubOption && argResults['pub'])) {
        final String error = PackageMap(PackageMap.globalPackagesPath).checkValid();
        if (error != null)
          throw ToolExit(error);
      }
    }

    if (_usesTargetOption) {
      final String targetPath = targetFile;
      if (!fs.isFileSync(targetPath))
        throw ToolExit(userMessages.flutterTargetFileMissing(targetPath));
    }

    final String compilationTraceFilePath = argParser.options.containsKey('compilation-trace-file')
        ? argResults['compilation-trace-file'] : null;
    final bool createBaseline = argParser.options.containsKey('baseline')
        ? argResults['baseline'] : false;
    final bool createPatch = argParser.options.containsKey('patch')
        ? argResults['patch'] : false;

    if (createBaseline && createPatch)
      throw ToolExit(userMessages.flutterBasePatchFlagsExclusive);
    if (createBaseline && compilationTraceFilePath == null)
      throw ToolExit(userMessages.flutterBaselineRequiresTraceFile);
    if (createPatch && compilationTraceFilePath == null)
      throw ToolExit(userMessages.flutterPatchRequiresTraceFile);
  }

  ApplicationPackageStore applicationPackages;
}

/// A mixin which applies an implementation of [requiredArtifacts] that only
/// downloads artifacts corresponding to an attached device.
mixin DeviceBasedDevelopmentArtifacts on FlutterCommand {
  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async {
    // If there are no attached devices, use the default configuration.
    // Otherwise, only add development artifacts which correspond to a
    // connected device.
    final List<Device> devices = await deviceManager.getDevices().toList();
    if (devices.isEmpty) {
      return super.requiredArtifacts;
    }
    final Set<DevelopmentArtifact> artifacts = <DevelopmentArtifact>{
      DevelopmentArtifact.universal,
    };
    for (Device device in devices) {
      final TargetPlatform targetPlatform = await device.targetPlatform;
      switch (targetPlatform) {
        case TargetPlatform.android_arm:
        case TargetPlatform.android_arm64:
        case TargetPlatform.android_x64:
        case TargetPlatform.android_x86:
          artifacts.add(DevelopmentArtifact.android);
          break;
        case TargetPlatform.web:
          artifacts.add(DevelopmentArtifact.web);
          break;
        case TargetPlatform.ios:
          artifacts.add(DevelopmentArtifact.iOS);
          break;
        case TargetPlatform.darwin_x64:
        case TargetPlatform.fuchsia:
        case TargetPlatform.tester:
        case TargetPlatform.windows_x64:
        case TargetPlatform.linux_x64:
          // No artifacts currently supported.
          break;
      }
    }
    return artifacts;
  }
}

/// A mixin which applies an implementation of [requiredArtifacts] that only
/// downloads artifacts corresponding to a target device.
mixin TargetPlatformBasedDevelopmentArtifacts on FlutterCommand {
  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async {
    // If there is no specified target device, fallback to the default
    // confiugration.
    final String rawTargetPlatform = argResults['target-platform'];
    final TargetPlatform targetPlatform = getTargetPlatformForName(rawTargetPlatform);
    if (targetPlatform == null) {
      return super.requiredArtifacts;
    }

    final Set<DevelopmentArtifact> artifacts = <DevelopmentArtifact>{
      DevelopmentArtifact.universal,
    };
    switch (targetPlatform) {
      case TargetPlatform.android_arm:
      case TargetPlatform.android_arm64:
      case TargetPlatform.android_x64:
      case TargetPlatform.android_x86:
        artifacts.add(DevelopmentArtifact.android);
        break;
      case TargetPlatform.web:
        artifacts.add(DevelopmentArtifact.web);
        break;
      case TargetPlatform.ios:
        artifacts.add(DevelopmentArtifact.iOS);
        break;
      case TargetPlatform.darwin_x64:
      case TargetPlatform.fuchsia:
      case TargetPlatform.tester:
      case TargetPlatform.windows_x64:
      case TargetPlatform.linux_x64:
        // No artifacts currently supported.
        break;
    }
    return artifacts;
  }
}

/// A command which runs less analytics and checks to speed up startup time.
abstract class FastFlutterCommand extends FlutterCommand {
  @override
  Future<void> run() {
    return context.run<void>(
      name: 'command',
      overrides: <Type, Generator>{FlutterCommand: () => this},
      body: runCommand,
    );
  }
}
