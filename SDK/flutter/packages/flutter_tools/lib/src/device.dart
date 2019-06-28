// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'android/android_device.dart';
import 'application_package.dart';
import 'base/context.dart';
import 'base/file_system.dart';
import 'base/utils.dart';
import 'build_info.dart';
import 'desktop.dart';
import 'fuchsia/fuchsia_device.dart';

import 'globals.dart';
import 'ios/devices.dart';
import 'ios/simulators.dart';
import 'linux/linux_device.dart';
import 'macos/macos_device.dart';
import 'tester/flutter_tester.dart';
import 'web/web_device.dart';
import 'windows/windows_device.dart';

DeviceManager get deviceManager => context[DeviceManager];

/// A class to get all available devices.
class DeviceManager {

  /// Constructing DeviceManagers is cheap; they only do expensive work if some
  /// of their methods are called.
  List<DeviceDiscovery> get deviceDiscoverers => _deviceDiscoverers;
  final List<DeviceDiscovery> _deviceDiscoverers = List<DeviceDiscovery>.unmodifiable(<DeviceDiscovery>[
    AndroidDevices(),
    IOSDevices(),
    IOSSimulators(),
    FuchsiaDevices(),
    FlutterTesterDevices(),
  ] + _conditionalDesktopDevices + _conditionalWebDevices);

  /// Only add desktop devices if the flag is enabled.
  static List<DeviceDiscovery> get _conditionalDesktopDevices {
    return flutterDesktopEnabled ? <DeviceDiscovery>[
      MacOSDevices(),
      LinuxDevices(),
      WindowsDevices(),
    ] : <DeviceDiscovery>[];
  }

  /// Only add web devices if the flag is enabled.
  static List<DeviceDiscovery> get _conditionalWebDevices {
    return flutterWebEnabled ? <DeviceDiscovery>[
      WebDevices(),
    ] : <DeviceDiscovery>[];
  }

  String _specifiedDeviceId;

  /// A user-specified device ID.
  String get specifiedDeviceId {
    if (_specifiedDeviceId == null || _specifiedDeviceId == 'all')
      return null;
    return _specifiedDeviceId;
  }

  set specifiedDeviceId(String id) {
    _specifiedDeviceId = id;
  }

  /// True when the user has specified a single specific device.
  bool get hasSpecifiedDeviceId => specifiedDeviceId != null;

  /// True when the user has specified all devices by setting
  /// specifiedDeviceId = 'all'.
  bool get hasSpecifiedAllDevices => _specifiedDeviceId == 'all';

  Stream<Device> getDevicesById(String deviceId) async* {
    final List<Device> devices = await getAllConnectedDevices().toList();
    deviceId = deviceId.toLowerCase();
    bool exactlyMatchesDeviceId(Device device) =>
        device.id.toLowerCase() == deviceId ||
        device.name.toLowerCase() == deviceId;
    bool startsWithDeviceId(Device device) =>
        device.id.toLowerCase().startsWith(deviceId) ||
        device.name.toLowerCase().startsWith(deviceId);

    final Device exactMatch = devices.firstWhere(
        exactlyMatchesDeviceId, orElse: () => null);
    if (exactMatch != null) {
      yield exactMatch;
      return;
    }

    // Match on a id or name starting with [deviceId].
    for (Device device in devices.where(startsWithDeviceId))
      yield device;
  }

  /// Return the list of connected devices, filtered by any user-specified device id.
  Stream<Device> getDevices() {
    return hasSpecifiedDeviceId
        ? getDevicesById(specifiedDeviceId)
        : getAllConnectedDevices();
  }

  Iterable<DeviceDiscovery> get _platformDiscoverers {
    return deviceDiscoverers.where((DeviceDiscovery discoverer) => discoverer.supportsPlatform);
  }

  /// Return the list of all connected devices.
  Stream<Device> getAllConnectedDevices() async* {
    for (DeviceDiscovery discoverer in _platformDiscoverers) {
      for (Device device in await discoverer.devices) {
        yield device;
      }
    }
  }

  /// Whether we're capable of listing any devices given the current environment configuration.
  bool get canListAnything {
    return _platformDiscoverers.any((DeviceDiscovery discoverer) => discoverer.canListAnything);
  }

  /// Get diagnostics about issues with any connected devices.
  Future<List<String>> getDeviceDiagnostics() async {
    final List<String> diagnostics = <String>[];
    for (DeviceDiscovery discoverer in _platformDiscoverers) {
      diagnostics.addAll(await discoverer.getDiagnostics());
    }
    return diagnostics;
  }
}

/// An abstract class to discover and enumerate a specific type of devices.
abstract class DeviceDiscovery {
  bool get supportsPlatform;

  /// Whether this device discovery is capable of listing any devices given the
  /// current environment configuration.
  bool get canListAnything;

  Future<List<Device>> get devices;

  /// Gets a list of diagnostic messages pertaining to issues with any connected
  /// devices (will be an empty list if there are no issues).
  Future<List<String>> getDiagnostics() => Future<List<String>>.value(<String>[]);
}

/// A [DeviceDiscovery] implementation that uses polling to discover device adds
/// and removals.
abstract class PollingDeviceDiscovery extends DeviceDiscovery {
  PollingDeviceDiscovery(this.name);

  static const Duration _pollingInterval = Duration(seconds: 4);
  static const Duration _pollingTimeout = Duration(seconds: 30);

  final String name;
  ItemListNotifier<Device> _items;
  Poller _poller;

  Future<List<Device>> pollingGetDevices();

  void startPolling() {
    if (_poller == null) {
      _items ??= ItemListNotifier<Device>();

      _poller = Poller(() async {
        try {
          final List<Device> devices = await pollingGetDevices().timeout(_pollingTimeout);
          _items.updateWithNewList(devices);
        } on TimeoutException {
          printTrace('Device poll timed out. Will retry.');
        }
      }, _pollingInterval);
    }
  }

  void stopPolling() {
    _poller?.cancel();
    _poller = null;
  }

  @override
  Future<List<Device>> get devices async {
    _items ??= ItemListNotifier<Device>.from(await pollingGetDevices());
    return _items.items;
  }

  Stream<Device> get onAdded {
    _items ??= ItemListNotifier<Device>();
    return _items.onAdded;
  }

  Stream<Device> get onRemoved {
    _items ??= ItemListNotifier<Device>();
    return _items.onRemoved;
  }

  void dispose() => stopPolling();

  @override
  String toString() => '$name device discovery';
}

abstract class Device {

  Device(this.id);

  final String id;

  String get name;

  bool get supportsStartPaused => true;

  /// Whether it is an emulated device running on localhost.
  Future<bool> get isLocalEmulator;

  /// Whether the device is a simulator on a platform which supports hardware rendering.
  Future<bool> get supportsHardwareRendering async {
    assert(await isLocalEmulator);
    switch (await targetPlatform) {
      case TargetPlatform.android_arm:
      case TargetPlatform.android_arm64:
      case TargetPlatform.android_x64:
      case TargetPlatform.android_x86:
        return true;
      case TargetPlatform.ios:
      case TargetPlatform.darwin_x64:
      case TargetPlatform.linux_x64:
      case TargetPlatform.windows_x64:
      case TargetPlatform.fuchsia:
      default:
        return false;
    }
  }

  /// Check if a version of the given app is already installed
  Future<bool> isAppInstalled(ApplicationPackage app);

  /// Check if the latest build of the [app] is already installed.
  Future<bool> isLatestBuildInstalled(ApplicationPackage app);

  /// Install an app package on the current device
  Future<bool> installApp(ApplicationPackage app);

  /// Uninstall an app package from the current device
  Future<bool> uninstallApp(ApplicationPackage app);

  /// Check if the device is supported by Flutter
  bool isSupported();

  // String meant to be displayed to the user indicating if the device is
  // supported by Flutter, and, if not, why.
  String supportMessage() => isSupported() ? 'Supported' : 'Unsupported';

  /// The device's platform.
  Future<TargetPlatform> get targetPlatform;

  Future<String> get sdkNameAndVersion;

  /// Get a log reader for this device.
  /// If [app] is specified, this will return a log reader specific to that
  /// application. Otherwise, a global log reader will be returned.
  DeviceLogReader getLogReader({ ApplicationPackage app });

  /// Get the port forwarder for this device.
  DevicePortForwarder get portForwarder;

  /// Clear the device's logs.
  void clearLogs();

  /// Start an app package on the current device.
  ///
  /// [platformArgs] allows callers to pass platform-specific arguments to the
  /// start call. The build mode is not used by all platforms.
  ///
  /// If [usesTerminalUi] is true, Flutter Tools may attempt to prompt the
  /// user to resolve fixable issues such as selecting a signing certificate
  /// for iOS device deployment. Set to false if stdin cannot be read from while
  /// attempting to start the app.
  Future<LaunchResult> startApp(
    ApplicationPackage package, {
    String mainPath,
    String route,
    DebuggingOptions debuggingOptions,
    Map<String, dynamic> platformArgs,
    bool prebuiltApplication = false,
    bool usesTerminalUi = true,
    bool ipv6 = false,
  });

  /// Whether this device implements support for hot reload.
  bool get supportsHotReload => true;

  /// Whether this device implements support for hot restart.
  bool get supportsHotRestart => true;

  /// Whether flutter applications running on this device can be terminated
  /// from the vmservice.
  bool get supportsStopApp => true;

  /// Whether the device supports taking screenshots of a running flutter
  /// application.
  bool get supportsScreenshot => false;

  /// Stop an app package on the current device.
  Future<bool> stopApp(ApplicationPackage app);

  Future<void> takeScreenshot(File outputFile) => Future<void>.error('unimplemented');

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! Device)
      return false;
    return id == other.id;
  }

  @override
  String toString() => name;

  static Stream<String> descriptions(List<Device> devices) async* {
    if (devices.isEmpty)
      return;

    // Extract device information
    final List<List<String>> table = <List<String>>[];
    for (Device device in devices) {
      String supportIndicator = device.isSupported() ? '' : ' (unsupported)';
      final TargetPlatform targetPlatform = await device.targetPlatform;
      if (await device.isLocalEmulator) {
        final String type = targetPlatform == TargetPlatform.ios ? 'simulator' : 'emulator';
        supportIndicator += ' ($type)';
      }
      table.add(<String>[
        device.name,
        device.id,
        '${getNameForTargetPlatform(targetPlatform)}',
        '${await device.sdkNameAndVersion}$supportIndicator',
      ]);
    }

    // Calculate column widths
    final List<int> indices = List<int>.generate(table[0].length - 1, (int i) => i);
    List<int> widths = indices.map<int>((int i) => 0).toList();
    for (List<String> row in table) {
      widths = indices.map<int>((int i) => math.max(widths[i], row[i].length)).toList();
    }

    // Join columns into lines of text
    for (List<String> row in table) {
      yield indices.map<String>((int i) => row[i].padRight(widths[i])).join(' • ') + ' • ${row.last}';
    }
  }

  static Future<void> printDevices(List<Device> devices) async {
    await descriptions(devices).forEach(printStatus);
  }
}

class DebuggingOptions {
  DebuggingOptions.enabled(
    this.buildInfo, {
    this.startPaused = false,
    this.disableServiceAuthCodes = false,
    this.enableSoftwareRendering = false,
    this.skiaDeterministicRendering = false,
    this.traceSkia = false,
    this.traceSystrace = false,
    this.dumpSkpOnShaderCompilation = false,
    this.useTestFonts = false,
    this.verboseSystemLogs = false,
    this.observatoryPort,
   }) : debuggingEnabled = true;

  DebuggingOptions.disabled(this.buildInfo)
    : debuggingEnabled = false,
      useTestFonts = false,
      startPaused = false,
      disableServiceAuthCodes = false,
      enableSoftwareRendering = false,
      skiaDeterministicRendering = false,
      traceSkia = false,
      traceSystrace = false,
      dumpSkpOnShaderCompilation = false,
      verboseSystemLogs = false,
      observatoryPort = null;

  final bool debuggingEnabled;

  final BuildInfo buildInfo;
  final bool startPaused;
  final bool disableServiceAuthCodes;
  final bool enableSoftwareRendering;
  final bool skiaDeterministicRendering;
  final bool traceSkia;
  final bool traceSystrace;
  final bool dumpSkpOnShaderCompilation;
  final bool useTestFonts;
  final bool verboseSystemLogs;
  final int observatoryPort;

  bool get hasObservatoryPort => observatoryPort != null;
}

class LaunchResult {
  LaunchResult.succeeded({ this.observatoryUri }) : started = true;
  LaunchResult.failed()
    : started = false,
      observatoryUri = null;

  bool get hasObservatory => observatoryUri != null;

  final bool started;
  final Uri observatoryUri;

  @override
  String toString() {
    final StringBuffer buf = StringBuffer('started=$started');
    if (observatoryUri != null)
      buf.write(', observatory=$observatoryUri');
    return buf.toString();
  }
}

class ForwardedPort {
  ForwardedPort(this.hostPort, this.devicePort) : context = null;
  ForwardedPort.withContext(this.hostPort, this.devicePort, this.context);

  final int hostPort;
  final int devicePort;
  final dynamic context;

  @override
  String toString() => 'ForwardedPort HOST:$hostPort to DEVICE:$devicePort';
}

/// Forward ports from the host machine to the device.
abstract class DevicePortForwarder {
  /// Returns a Future that completes with the current list of forwarded
  /// ports for this device.
  List<ForwardedPort> get forwardedPorts;

  /// Forward [hostPort] on the host to [devicePort] on the device.
  /// If [hostPort] is null or zero, will auto select a host port.
  /// Returns a Future that completes with the host port.
  Future<int> forward(int devicePort, { int hostPort });

  /// Stops forwarding [forwardedPort].
  Future<void> unforward(ForwardedPort forwardedPort);
}

/// Read the log for a particular device.
abstract class DeviceLogReader {
  String get name;

  /// A broadcast stream where each element in the string is a line of log output.
  Stream<String> get logLines;

  @override
  String toString() => name;

  /// Process ID of the app on the device.
  int appPid;
}

/// Describes an app running on the device.
class DiscoveredApp {
  DiscoveredApp(this.id, this.observatoryPort);
  final String id;
  final int observatoryPort;
}

// An empty device log reader
class NoOpDeviceLogReader implements DeviceLogReader {
  NoOpDeviceLogReader(this.name);

  @override
  final String name;

  @override
  int appPid;

  @override
  Stream<String> get logLines => const Stream<String>.empty();
}

// A portforwarder which does not support forwarding ports.
class NoOpDevicePortForwarder implements DevicePortForwarder {
  const NoOpDevicePortForwarder();

  @override
  Future<int> forward(int devicePort, { int hostPort }) async => devicePort;

  @override
  List<ForwardedPort> get forwardedPorts => <ForwardedPort>[];

  @override
  Future<void> unforward(ForwardedPort forwardedPort) async { }
}
