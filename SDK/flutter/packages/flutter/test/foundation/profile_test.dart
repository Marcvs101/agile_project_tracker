// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import '../flutter_test_alternative.dart';

void main() {
  // TODO(devoncarew): This test - while very nice - isn't testing what we really want to know:
  // that the code in the `profile` closure is omitted in release mode.
  test('profile invokes its closure in debug or profile mode', () {
    int count = 0;
    profile(() { // ignore: deprecated_member_use_from_same_package
      count++;
    });
    // We run our tests in debug mode, so kReleaseMode will always evaluate to
    // false...
    expect(count, kReleaseMode ? 0 : 1);
  });
}
