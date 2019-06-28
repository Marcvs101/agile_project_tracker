// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../application_package.dart';
import '../base/io.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/process_manager.dart';
import '../build_info.dart';
import '../convert.dart';
import '../desktop.dart';
import '../device.dart';
import '../globals.dart';
import '../project.dart';
import '../protocol_discovery.dart';
import 'application_package.dart';
import 'build_linux.dart';
import 'linux_workflow.dart';

/// A device that represents a desktop Linux target.
class LinuxDevice extends Device {
  LinuxDevice() : super('Linux');

  @override
  void clearLogs() { }

  @override
  DeviceLogReader getLogReader({ ApplicationPackage app }) => NoOpDeviceLogReader('linux');

  // Since the host and target devices are the same, no work needs to be done
  // to install the application.
  @override
  Future<bool> installApp(ApplicationPackage app) async => true;

  // Since the host and target devices are the same, no work needs to be done
  // to install the application.
  @override
  Future<bool> isAppInstalled(ApplicationPackage app) async => true;

  // Since the host and target devices are the same, no work needs to be done
  // to install the application.
  @override
  Future<bool> isLatestBuildInstalled(ApplicationPackage app) async => true;

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  bool isSupported() => true;

  @override
  String get name => 'Linux';

  @override
  DevicePortForwarder get portForwarder => const NoOpDevicePortForwarder();

  @override
  Future<String> get sdkNameAndVersion async => os.name;

  @override
  Future<LaunchResult> startApp(
    covariant LinuxApp package, {
    String mainPath,
    String route,
    DebuggingOptions debuggingOptions,
    Map<String, dynamic> platformArgs,
    bool prebuiltApplication = false,
    bool usesTerminalUi = true,
    bool ipv6 = false,
  }) async {
    if (!prebuiltApplication) {
      await buildLinux((await FlutterProject.current()).linux, debuggingOptions.buildInfo);
    }
    await stopApp(package);
    final Process process = await processManager.start(<String>[
      package.executable(debuggingOptions?.buildInfo?.mode)
    ]);
    if (debuggingOptions?.buildInfo?.isRelease == true) {
      return LaunchResult.succeeded();
    }
    final LinuxLogReader logReader = LinuxLogReader(package, process);
    final ProtocolDiscovery observatoryDiscovery = ProtocolDiscovery.observatory(logReader);
    try {
      final Uri observatoryUri = await observatoryDiscovery.uri;
      return LaunchResult.succeeded(observatoryUri: observatoryUri);
    } catch (error) {
      printError('Error waiting for a debug connection: $error');
      return LaunchResult.failed();
    } finally {
      await observatoryDiscovery.cancel();
    }
  }

  @override
  Future<bool> stopApp(covariant LinuxApp app) async {
    // Assume debug for now.
    return killProcess(app.executable(BuildMode.debug));
  }

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.linux_x64;

  // Since the host and target devices are the same, no work needs to be done
  // to uninstall the application.
  @override
  Future<bool> uninstallApp(ApplicationPackage app) async => true;
}

class LinuxDevices extends PollingDeviceDiscovery {
  LinuxDevices() : super('linux devices');

  @override
  bool get supportsPlatform => platform.isLinux;

  @override
  bool get canListAnything => linuxWorkflow.canListDevices;

  @override
  Future<List<Device>> pollingGetDevices() async {
    if (!canListAnything) {
      return const <Device>[];
    }
    return <Device>[
      LinuxDevice(),
    ];
  }

  @override
  Future<List<String>> getDiagnostics() async => const <String>[];
}

class LinuxLogReader extends DeviceLogReader {
  LinuxLogReader(this.linuxApp, this.process);

  final LinuxApp linuxApp;
  final Process process;

  @override
  Stream<String> get logLines {
    return process.stdout.transform(utf8.decoder);
  }

  @override
  String get name => linuxApp.displayName;
}
