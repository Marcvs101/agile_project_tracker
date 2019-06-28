// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class TestBinding extends LiveTestWidgetsFlutterBinding {
  TestBinding();

  int framesBegun = 0;
  int framesDrawn = 0;

  bool handleBeginFrameMicrotaskRun;

  @override
  void handleBeginFrame(Duration rawTimeStamp) {
    handleBeginFrameMicrotaskRun = false;
    framesBegun += 1;
    Future<void>.microtask(() { handleBeginFrameMicrotaskRun = true; });
    super.handleBeginFrame(rawTimeStamp);
  }

  @override
  void handleDrawFrame() {
    if (!handleBeginFrameMicrotaskRun) {
      throw "Microtasks scheduled by 'handledBeginFrame' must be run before 'handleDrawFrame'.";
    }
    framesDrawn += 1;
    super.handleDrawFrame();
  }
}

Future<void> main() async {
  final TestBinding binding = TestBinding();

  test('test pumpBenchmark() only runs one frame', () async {
    await benchmarkWidgets((WidgetTester tester) async {
      const Key root = Key('root');
      binding.attachRootWidget(Container(key: root));
      await tester.pump();

      expect(binding.framesBegun, greaterThan(0));
      expect(binding.framesDrawn, greaterThan(0));

      final Element appState = tester.element(find.byKey(root));
      binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.benchmark;

      final int startFramesBegun = binding.framesBegun;
      final int startFramesDrawn = binding.framesDrawn;
      expect(startFramesBegun, equals(startFramesDrawn));

      appState.markNeedsBuild();

      await tester.pumpBenchmark(const Duration(milliseconds: 16));

      final int endFramesBegun = binding.framesBegun;
      final int endFramesDrawn = binding.framesDrawn;
      expect(endFramesBegun, equals(endFramesDrawn));

      expect(endFramesBegun, equals(startFramesBegun + 1));
      expect(endFramesDrawn, equals(startFramesDrawn + 1));
    });
  });
}
