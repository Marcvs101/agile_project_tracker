// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

Future<void> main() async {
  test('MotionEvents recomposition', () async {
    final FlutterDriver driver = await FlutterDriver.connect();
    final String errorMessage = await driver.requestData('run test');

    expect(errorMessage, '');
    driver?.close();
  });
}

