// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/usage.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:mockito/mockito.dart';

typedef CommandFunction = Future<FlutterCommandResult> Function();

class DummyFlutterCommand extends FlutterCommand {

  DummyFlutterCommand({
    this.shouldUpdateCache = false,
    this.noUsagePath  = false,
    this.commandFunction,
  });

  final bool noUsagePath;
  final CommandFunction commandFunction;

  @override
  final bool shouldUpdateCache;

  @override
  String get description => 'does nothing';

  @override
  Future<String> get usagePath => noUsagePath ? null : super.usagePath;

  @override
  String get name => 'dummy';

  @override
  Future<FlutterCommandResult> runCommand() async {
    return commandFunction == null ? null : await commandFunction();
  }
}

class MockitoCache extends Mock implements Cache {}

class MockitoUsage extends Mock implements Usage {}
