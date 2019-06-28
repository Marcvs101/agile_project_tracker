// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/windows/application_package.dart';
import 'package:flutter_tools/src/windows/windows_device.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group(WindowsDevice, () {
    final WindowsDevice device = WindowsDevice();
    final MockPlatform notWindows = MockPlatform();
    final MockProcessManager mockProcessManager = MockProcessManager();

    when(notWindows.isWindows).thenReturn(false);
    when(notWindows.environment).thenReturn(const <String, String>{});
    when(mockProcessManager.runSync(<String>[
      'powershell', '-script="Get-CimInstance Win32_Process"'
    ])).thenAnswer((Invocation invocation) {
      final MockProcessResult result = MockProcessResult();
      when(result.exitCode).thenReturn(0);
      when<String>(result.stdout).thenReturn('');
      return result;
    });

    testUsingContext('defaults', () async {
      final PrebuiltWindowsApp windowsApp = PrebuiltWindowsApp(executable: 'foo');
      expect(await device.targetPlatform, TargetPlatform.windows_x64);
      expect(device.name, 'Windows');
      expect(await device.installApp(windowsApp), true);
      expect(await device.uninstallApp(windowsApp), true);
      expect(await device.isLatestBuildInstalled(windowsApp), true);
      expect(await device.isAppInstalled(windowsApp), true);
      expect(await device.stopApp(windowsApp), false);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    test('noop port forwarding', () async {
      final WindowsDevice device = WindowsDevice();
      final DevicePortForwarder portForwarder = device.portForwarder;
      final int result = await portForwarder.forward(2);
      expect(result, 2);
      expect(portForwarder.forwardedPorts.isEmpty, true);
    });

    testUsingContext('No devices listed if platform unsupported', () async {
      expect(await WindowsDevices().devices, <Device>[]);
    }, overrides: <Type, Generator>{
      Platform: () => notWindows,
    });
  });
}

class MockPlatform extends Mock implements Platform {}

class MockFileSystem extends Mock implements FileSystem {}

class MockFile extends Mock implements File {}

class MockProcessManager extends Mock implements ProcessManager {}

class MockProcess extends Mock implements Process {}

class MockProcessResult extends Mock implements ProcessResult {}