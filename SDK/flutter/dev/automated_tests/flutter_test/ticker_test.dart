// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Does flutter_test catch leaking tickers?', (WidgetTester tester) async {
    Ticker((Duration duration) { })..start();

    final ByteData message = const StringCodec().encodeMessage('AppLifecycleState.paused');
    await BinaryMessages.handlePlatformMessage('flutter/lifecycle', message, (_) {});
  });
}
