// Copyright (c) 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_devicelab/tasks/plugin_tests.dart';
import 'package:flutter_devicelab/framework/framework.dart';

Future<void> main() async {
  await task(combine(<TaskFunction>[
    PluginTest('ios', <String>['-i', 'objc']),
    PluginTest('ios', <String>['-i', 'swift']),
  ]));
}
