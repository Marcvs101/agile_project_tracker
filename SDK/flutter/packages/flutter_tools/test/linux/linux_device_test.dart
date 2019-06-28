// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/linux/application_package.dart';
import 'package:flutter_tools/src/linux/linux_device.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group(LinuxDevice, () {
    final LinuxDevice device = LinuxDevice();
    final MockPlatform notLinux = MockPlatform();
    final MockProcessManager mockProcessManager = MockProcessManager();

    when(notLinux.isLinux).thenReturn(false);
    when(notLinux.environment).thenReturn(const <String, String>{});
    when(mockProcessManager.run(<String>[
      'ps', 'aux',
    ])).thenAnswer((Invocation invocation) async {
      final MockProcessResult result = MockProcessResult();
      when(result.exitCode).thenReturn(0);
      when<String>(result.stdout).thenReturn('');
      return result;
    });

    testUsingContext('defaults', () async {
      final PrebuiltLinuxApp linuxApp = PrebuiltLinuxApp(executable: 'foo');
      expect(await device.targetPlatform, TargetPlatform.linux_x64);
      expect(device.name, 'Linux');
      expect(await device.installApp(linuxApp), true);
      expect(await device.uninstallApp(linuxApp), true);
      expect(await device.isLatestBuildInstalled(linuxApp), true);
      expect(await device.isAppInstalled(linuxApp), true);
      expect(await device.stopApp(linuxApp), true);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    test('noop port forwarding', () async {
      final LinuxDevice device = LinuxDevice();
      final DevicePortForwarder portForwarder = device.portForwarder;
      final int result = await portForwarder.forward(2);
      expect(result, 2);
      expect(portForwarder.forwardedPorts.isEmpty, true);
    });

    testUsingContext('No devices listed if platform unsupported', () async {
      expect(await LinuxDevices().devices, <Device>[]);
    }, overrides: <Type, Generator>{
      Platform: () => notLinux,
    });
  });
}

class MockPlatform extends Mock implements Platform {}

class MockFileSystem extends Mock implements FileSystem {}

class MockFile extends Mock implements File {}

class MockProcessManager extends Mock implements ProcessManager {}

class MockProcess extends Mock implements Process {}

class MockProcessResult extends Mock implements ProcessResult {}