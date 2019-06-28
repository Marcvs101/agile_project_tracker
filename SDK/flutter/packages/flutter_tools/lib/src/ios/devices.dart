// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../application_package.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/process_manager.dart';
import '../build_info.dart';
import '../convert.dart';
import '../device.dart';
import '../globals.dart';
import '../protocol_discovery.dart';
import 'code_signing.dart';
import 'ios_workflow.dart';
import 'mac.dart';

const String _kIdeviceinstallerInstructions =
    'To work with iOS devices, please install ideviceinstaller. To install, run:\n'
    'brew install ideviceinstaller.';

class IOSDeploy {
  const IOSDeploy();

  /// Installs and runs the specified app bundle using ios-deploy, then returns
  /// the exit code.
  Future<int> runApp({
    @required String deviceId,
    @required String bundlePath,
    @required List<String> launchArguments,
  }) async {
    final List<String> launchCommand = <String>[
      '/usr/bin/env',
      'ios-deploy',
      '--id',
      deviceId,
      '--bundle',
      bundlePath,
      '--no-wifi',
      '--justlaunch',
    ];
    if (launchArguments.isNotEmpty) {
      launchCommand.add('--args');
      launchCommand.add('${launchArguments.join(" ")}');
    }

    // Push /usr/bin to the front of PATH to pick up default system python, package 'six'.
    //
    // ios-deploy transitively depends on LLDB.framework, which invokes a
    // Python script that uses package 'six'. LLDB.framework relies on the
    // python at the front of the path, which may not include package 'six'.
    // Ensure that we pick up the system install of python, which does include
    // it.
    final Map<String, String> iosDeployEnv = Map<String, String>.from(platform.environment);
    iosDeployEnv['PATH'] = '/usr/bin:${iosDeployEnv['PATH']}';

    return await runCommandAndStreamOutput(
      launchCommand,
      mapFunction: _monitorInstallationFailure,
      trace: true,
      environment: iosDeployEnv,
    );
  }

  // Maps stdout line stream. Must return original line.
  String _monitorInstallationFailure(String stdout) {
    // Installation issues.
    if (stdout.contains('Error 0xe8008015') || stdout.contains('Error 0xe8000067')) {
      printError(noProvisioningProfileInstruction, emphasis: true);

    // Launch issues.
    } else if (stdout.contains('e80000e2')) {
      printError('''
═══════════════════════════════════════════════════════════════════════════════════
Your device is locked. Unlock your device first before running.
═══════════════════════════════════════════════════════════════════════════════════''',
      emphasis: true);
    } else if (stdout.contains('Error 0xe8000022')) {
      printError('''
═══════════════════════════════════════════════════════════════════════════════════
Error launching app. Try launching from within Xcode via:
    open ios/Runner.xcworkspace

Your Xcode version may be too old for your iOS version.
═══════════════════════════════════════════════════════════════════════════════════''',
      emphasis: true);
    }

    return stdout;
  }
}

class IOSDevices extends PollingDeviceDiscovery {
  IOSDevices() : super('iOS devices');

  @override
  bool get supportsPlatform => platform.isMacOS;

  @override
  bool get canListAnything => iosWorkflow.canListDevices;

  @override
  Future<List<Device>> pollingGetDevices() => IOSDevice.getAttachedDevices();
}

class IOSDevice extends Device {
  IOSDevice(String id, { this.name, String sdkVersion })
      : _sdkVersion = sdkVersion,
        super(id) {
    _installerPath = _checkForCommand('ideviceinstaller');
    _iproxyPath = _checkForCommand('iproxy');
  }

  String _installerPath;
  String _iproxyPath;

  final String _sdkVersion;

  @override
  bool get supportsHotReload => true;

  @override
  bool get supportsHotRestart => true;

  @override
  final String name;

  Map<ApplicationPackage, _IOSDeviceLogReader> _logReaders;

  _IOSDevicePortForwarder _portForwarder;

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  bool get supportsStartPaused => false;

  static Future<List<IOSDevice>> getAttachedDevices() async {
    if (!iMobileDevice.isInstalled)
      return <IOSDevice>[];

    final List<IOSDevice> devices = <IOSDevice>[];
    for (String id in (await iMobileDevice.getAvailableDeviceIDs()).split('\n')) {
      id = id.trim();
      if (id.isEmpty)
        continue;

      try {
        final String deviceName = await iMobileDevice.getInfoForDevice(id, 'DeviceName');
        final String sdkVersion = await iMobileDevice.getInfoForDevice(id, 'ProductVersion');
        devices.add(IOSDevice(id, name: deviceName, sdkVersion: sdkVersion));
      } on IOSDeviceNotFoundError catch (error) {
        // Unable to find device with given udid. Possibly a network device.
        printTrace('Error getting attached iOS device: $error');
      }
    }
    return devices;
  }

  static String _checkForCommand(
    String command, [
    String macInstructions = _kIdeviceinstallerInstructions,
  ]) {
    try {
      command = runCheckedSync(<String>['which', command]).trim();
    } catch (e) {
      if (platform.isMacOS) {
        printError('$command not found. $macInstructions');
      } else {
        printError('Cannot control iOS devices or simulators. $command is not available on your platform.');
      }
      return null;
    }
    return command;
  }

  @override
  Future<bool> isAppInstalled(ApplicationPackage app) async {
    try {
      final RunResult apps = await runCheckedAsync(<String>[_installerPath, '--list-apps']);
      if (RegExp(app.id, multiLine: true).hasMatch(apps.stdout)) {
        return true;
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  @override
  Future<bool> isLatestBuildInstalled(ApplicationPackage app) async => false;

  @override
  Future<bool> installApp(ApplicationPackage app) async {
    final IOSApp iosApp = app;
    final Directory bundle = fs.directory(iosApp.deviceBundlePath);
    if (!bundle.existsSync()) {
      printError('Could not find application bundle at ${bundle.path}; have you run "flutter build ios"?');
      return false;
    }

    try {
      await runCheckedAsync(<String>[_installerPath, '-i', iosApp.deviceBundlePath]);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> uninstallApp(ApplicationPackage app) async {
    try {
      await runCheckedAsync(<String>[_installerPath, '-U', app.id]);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  bool isSupported() => true;

  @override
  Future<LaunchResult> startApp(
    ApplicationPackage package, {
    String mainPath,
    String route,
    DebuggingOptions debuggingOptions,
    Map<String, dynamic> platformArgs,
    bool prebuiltApplication = false,
    bool usesTerminalUi = true,
    bool ipv6 = false,
  }) async {
    if (!prebuiltApplication) {
      // TODO(chinmaygarde): Use mainPath, route.
      printTrace('Building ${package.name} for $id');

      final String cpuArchitecture = await iMobileDevice.getInfoForDevice(id, 'CPUArchitecture');
      final IOSArch iosArch = getIOSArchForName(cpuArchitecture);

      // Step 1: Build the precompiled/DBC application if necessary.
      final XcodeBuildResult buildResult = await buildXcodeProject(
          app: package,
          buildInfo: debuggingOptions.buildInfo,
          targetOverride: mainPath,
          buildForDevice: true,
          usesTerminalUi: usesTerminalUi,
          activeArch: iosArch,
      );
      if (!buildResult.success) {
        printError('Could not build the precompiled application for the device.');
        await diagnoseXcodeBuildFailure(buildResult);
        printError('');
        return LaunchResult.failed();
      }
    } else {
      if (!await installApp(package))
        return LaunchResult.failed();
    }

    // Step 2: Check that the application exists at the specified path.
    final IOSApp iosApp = package;
    final Directory bundle = fs.directory(iosApp.deviceBundlePath);
    if (!bundle.existsSync()) {
      printError('Could not find the built application bundle at ${bundle.path}.');
      return LaunchResult.failed();
    }

    // Step 3: Attempt to install the application on the device.
    final List<String> launchArguments = <String>['--enable-dart-profiling'];

    if (debuggingOptions.startPaused)
      launchArguments.add('--start-paused');

    if (debuggingOptions.disableServiceAuthCodes)
      launchArguments.add('--disable-service-auth-codes');

    if (debuggingOptions.useTestFonts)
      launchArguments.add('--use-test-fonts');

    if (debuggingOptions.debuggingEnabled) {
      launchArguments.add('--enable-checked-mode');
      launchArguments.add('--verify-entry-points');
    }

    if (debuggingOptions.enableSoftwareRendering)
      launchArguments.add('--enable-software-rendering');

    if (debuggingOptions.skiaDeterministicRendering)
      launchArguments.add('--skia-deterministic-rendering');

    if (debuggingOptions.traceSkia)
      launchArguments.add('--trace-skia');

    if (debuggingOptions.dumpSkpOnShaderCompilation)
      launchArguments.add('--dump-skp-on-shader-compilation');

    if (debuggingOptions.verboseSystemLogs) {
      launchArguments.add('--verbose-logging');
    }

    if (platformArgs['trace-startup'] ?? false)
      launchArguments.add('--trace-startup');

    int installationResult = -1;
    Uri localObservatoryUri;

    final Status installStatus = logger.startProgress('Installing and launching...', timeout: timeoutConfiguration.slowOperation);

    if (!debuggingOptions.debuggingEnabled) {
      // If debugging is not enabled, just launch the application and continue.
      printTrace('Debugging is not enabled');
      installationResult = await const IOSDeploy().runApp(
        deviceId: id,
        bundlePath: bundle.path,
        launchArguments: launchArguments,
      );
    } else {
      // Debugging is enabled, look for the observatory server port post launch.
      printTrace('Debugging is enabled, connecting to observatory');

      // TODO(danrubel): The Android device class does something similar to this code below.
      // The various Device subclasses should be refactored and common code moved into the superclass.
      final ProtocolDiscovery observatoryDiscovery = ProtocolDiscovery.observatory(
        getLogReader(app: package),
        portForwarder: portForwarder,
        hostPort: debuggingOptions.observatoryPort,
        ipv6: ipv6,
      );

      final Future<Uri> forwardObservatoryUri = observatoryDiscovery.uri;

      final Future<int> launch = const IOSDeploy().runApp(
        deviceId: id,
        bundlePath: bundle.path,
        launchArguments: launchArguments,
      );

      localObservatoryUri = await launch.then<Uri>((int result) async {
        installationResult = result;

        if (result != 0) {
          printTrace('Failed to launch the application on device.');
          return null;
        }

        printTrace('Application launched on the device. Waiting for observatory port.');
        return await forwardObservatoryUri;
      }).whenComplete(() {
        observatoryDiscovery.cancel();
      });
    }
    installStatus.stop();

    if (installationResult != 0) {
      printError('Could not install ${bundle.path} on $id.');
      printError('Try launching Xcode and selecting "Product > Run" to fix the problem:');
      printError('  open ios/Runner.xcworkspace');
      printError('');
      return LaunchResult.failed();
    }

    return LaunchResult.succeeded(observatoryUri: localObservatoryUri);
  }

  @override
  Future<bool> stopApp(ApplicationPackage app) async {
    // Currently we don't have a way to stop an app running on iOS.
    return false;
  }

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.ios;

  @override
  Future<String> get sdkNameAndVersion async => 'iOS $_sdkVersion';

  @override
  DeviceLogReader getLogReader({ ApplicationPackage app }) {
    _logReaders ??= <ApplicationPackage, _IOSDeviceLogReader>{};
    return _logReaders.putIfAbsent(app, () => _IOSDeviceLogReader(this, app));
  }

  @override
  DevicePortForwarder get portForwarder => _portForwarder ??= _IOSDevicePortForwarder(this);

  @override
  void clearLogs() { }

  @override
  bool get supportsScreenshot => iMobileDevice.isInstalled;

  @override
  Future<void> takeScreenshot(File outputFile) async {
    await iMobileDevice.takeScreenshot(outputFile);
  }
}

/// Decodes a vis-encoded syslog string to a UTF-8 representation.
///
/// Apple's syslog logs are encoded in 7-bit form. Input bytes are encoded as follows:
/// 1. 0x00 to 0x19: non-printing range. Some ignored, some encoded as <...>.
/// 2. 0x20 to 0x7f: as-is, with the exception of 0x5c (backslash).
/// 3. 0x5c (backslash): octal representation \134.
/// 4. 0x80 to 0x9f: \M^x (using control-character notation for range 0x00 to 0x40).
/// 5. 0xa0: octal representation \240.
/// 6. 0xa1 to 0xf7: \M-x (where x is the input byte stripped of its high-order bit).
/// 7. 0xf8 to 0xff: unused in 4-byte UTF-8.
///
/// See: [vis(3) manpage](https://www.freebsd.org/cgi/man.cgi?query=vis&sektion=3)
String decodeSyslog(String line) {
  // UTF-8 values for \, M, -, ^.
  const int kBackslash = 0x5c;
  const int kM = 0x4d;
  const int kDash = 0x2d;
  const int kCaret = 0x5e;

  // Mask for the UTF-8 digit range.
  const int kNum = 0x30;

  // Returns true when `byte` is within the UTF-8 7-bit digit range (0x30 to 0x39).
  bool isDigit(int byte) => (byte & 0xf0) == kNum;

  // Converts a three-digit ASCII (UTF-8) representation of an octal number `xyz` to an integer.
  int decodeOctal(int x, int y, int z) => (x & 0x3) << 6 | (y & 0x7) << 3 | z & 0x7;

  try {
    final List<int> bytes = utf8.encode(line);
    final List<int> out = <int>[];
    for (int i = 0; i < bytes.length;) {
      if (bytes[i] != kBackslash || i > bytes.length - 4) {
        // Unmapped byte: copy as-is.
        out.add(bytes[i++]);
      } else {
        // Mapped byte: decode next 4 bytes.
        if (bytes[i + 1] == kM && bytes[i + 2] == kCaret) {
          // \M^x form: bytes in range 0x80 to 0x9f.
          out.add((bytes[i + 3] & 0x7f) + 0x40);
        } else if (bytes[i + 1] == kM && bytes[i + 2] == kDash) {
          // \M-x form: bytes in range 0xa0 to 0xf7.
          out.add(bytes[i + 3] | 0x80);
        } else if (bytes.getRange(i + 1, i + 3).every(isDigit)) {
          // \ddd form: octal representation (only used for \134 and \240).
          out.add(decodeOctal(bytes[i + 1], bytes[i + 2], bytes[i + 3]));
        } else {
          // Unknown form: copy as-is.
          out.addAll(bytes.getRange(0, 4));
        }
        i += 4;
      }
    }
    return utf8.decode(out);
  } catch (_) {
    // Unable to decode line: return as-is.
    return line;
  }
}

class _IOSDeviceLogReader extends DeviceLogReader {
  _IOSDeviceLogReader(this.device, ApplicationPackage app) {
    _linesController = StreamController<String>.broadcast(
      onListen: _start,
      onCancel: _stop,
    );

    // Match for lines for the runner in syslog.
    //
    // iOS 9 format:  Runner[297] <Notice>:
    // iOS 10 format: Runner(Flutter)[297] <Notice>:
    final String appName = app == null ? '' : app.name.replaceAll('.app', '');
    _runnerLineRegex = RegExp(appName + r'(\(Flutter\))?\[[\d]+\] <[A-Za-z]+>: ');
    // Similar to above, but allows ~arbitrary components instead of "Runner"
    // and "Flutter". The regex tries to strike a balance between not producing
    // false positives and not producing false negatives.
    _anyLineRegex = RegExp(r'\w+(\([^)]*\))?\[\d+\] <[A-Za-z]+>: ');
  }

  final IOSDevice device;

  // Matches a syslog line from the runner.
  RegExp _runnerLineRegex;
  // Matches a syslog line from any app.
  RegExp _anyLineRegex;

  StreamController<String> _linesController;
  Process _process;

  @override
  Stream<String> get logLines => _linesController.stream;

  @override
  String get name => device.name;

  void _start() {
    iMobileDevice.startLogger(device.id).then<void>((Process process) {
      _process = process;
      _process.stdout.transform<String>(utf8.decoder).transform<String>(const LineSplitter()).listen(_newLineHandler());
      _process.stderr.transform<String>(utf8.decoder).transform<String>(const LineSplitter()).listen(_newLineHandler());
      _process.exitCode.whenComplete(() {
        if (_linesController.hasListener)
          _linesController.close();
      });
    });
  }

  // Returns a stateful line handler to properly capture multi-line output.
  //
  // For multi-line log messages, any line after the first is logged without
  // any specific prefix. To properly capture those, we enter "printing" mode
  // after matching a log line from the runner. When in printing mode, we print
  // all lines until we find the start of another log message (from any app).
  Function _newLineHandler() {
    bool printing = false;

    return (String line) {
      if (printing) {
        if (!_anyLineRegex.hasMatch(line)) {
          _linesController.add(decodeSyslog(line));
          return;
        }

        printing = false;
      }

      final Match match = _runnerLineRegex.firstMatch(line);

      if (match != null) {
        final String logLine = line.substring(match.end);
        // Only display the log line after the initial device and executable information.
        _linesController.add(decodeSyslog(logLine));

        printing = true;
      }
    };
  }

  void _stop() {
    _process?.kill();
  }
}

class _IOSDevicePortForwarder extends DevicePortForwarder {
  _IOSDevicePortForwarder(this.device) : _forwardedPorts = <ForwardedPort>[];

  final IOSDevice device;

  final List<ForwardedPort> _forwardedPorts;

  @override
  List<ForwardedPort> get forwardedPorts => _forwardedPorts;

  static const Duration _kiProxyPortForwardTimeout = Duration(seconds: 1);

  @override
  Future<int> forward(int devicePort, { int hostPort }) async {
    final bool autoselect = hostPort == null || hostPort == 0;
    if (autoselect)
      hostPort = 1024;

    Process process;

    bool connected = false;
    while (!connected) {
      printTrace('attempting to forward device port $devicePort to host port $hostPort');
      // Usage: iproxy LOCAL_TCP_PORT DEVICE_TCP_PORT UDID
      process = await runCommand(<String>[
        device._iproxyPath,
        hostPort.toString(),
        devicePort.toString(),
        device.id,
      ]);
      // TODO(ianh): This is a flakey race condition, https://github.com/libimobiledevice/libimobiledevice/issues/674
      connected = !await process.stdout.isEmpty.timeout(_kiProxyPortForwardTimeout, onTimeout: () => false);
      if (!connected) {
        if (autoselect) {
          hostPort += 1;
          if (hostPort > 65535)
            throw Exception('Could not find open port on host.');
        } else {
          throw Exception('Port $hostPort is not available.');
        }
      }
    }
    assert(connected);
    assert(process != null);

    final ForwardedPort forwardedPort = ForwardedPort.withContext(
      hostPort, devicePort, process,
    );
    printTrace('Forwarded port $forwardedPort');
    _forwardedPorts.add(forwardedPort);
    return hostPort;
  }

  @override
  Future<void> unforward(ForwardedPort forwardedPort) async {
    if (!_forwardedPorts.remove(forwardedPort)) {
      // Not in list. Nothing to remove.
      return;
    }

    printTrace('Unforwarding port $forwardedPort');

    final Process process = forwardedPort.context;

    if (process != null) {
      processManager.killPid(process.pid);
    } else {
      printError('Forwarded port did not have a valid process');
    }
  }
}
