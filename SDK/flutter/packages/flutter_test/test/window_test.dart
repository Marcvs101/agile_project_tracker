// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show window;
import 'dart:ui' show Size, Locale, WindowPadding, AccessibilityFeatures, Brightness;

import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';

void main() {
  testWidgets('TestWindow can fake device pixel ratio', (WidgetTester tester) async {
    verifyThatTestWindowCanFakeProperty<double>(
      tester: tester,
      realValue: ui.window.devicePixelRatio,
      fakeValue: 2.5,
      propertyRetriever: () {
        return WidgetsBinding.instance.window.devicePixelRatio;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, double fakeValue) {
        binding.window.devicePixelRatioTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestWindow can fake physical size', (WidgetTester tester) async {
    verifyThatTestWindowCanFakeProperty<Size>(
      tester: tester,
      realValue: ui.window.physicalSize,
      fakeValue: const Size(50, 50),
      propertyRetriever: () {
        return WidgetsBinding.instance.window.physicalSize;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, Size fakeValue) {
        binding.window.physicalSizeTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestWindow can fake view insets', (WidgetTester tester) async {
    verifyThatTestWindowCanFakeProperty<WindowPadding>(
      tester: tester,
      realValue: ui.window.viewInsets,
      fakeValue: const FakeWindowPadding(),
      propertyRetriever: () {
        return WidgetsBinding.instance.window.viewInsets;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, WindowPadding fakeValue) {
        binding.window.viewInsetsTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestWindow can fake padding', (WidgetTester tester) async {
    verifyThatTestWindowCanFakeProperty<WindowPadding>(
      tester: tester,
      realValue: ui.window.padding,
      fakeValue: const FakeWindowPadding(),
      propertyRetriever: () {
        return WidgetsBinding.instance.window.padding;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, WindowPadding fakeValue) {
        binding.window.paddingTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestWindow can fake locale', (WidgetTester tester) async {
    verifyThatTestWindowCanFakeProperty<Locale>(
      tester: tester,
      realValue: ui.window.locale,
      fakeValue: const Locale('fake_language_code'),
      propertyRetriever: () {
        return WidgetsBinding.instance.window.locale;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, Locale fakeValue) {
        binding.window.localeTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestWindow can fake locales', (WidgetTester tester) async {
    verifyThatTestWindowCanFakeProperty<List<Locale>>(
      tester: tester,
      realValue: ui.window.locales,
      fakeValue: <Locale>[const Locale('fake_language_code')],
      propertyRetriever: () {
        return WidgetsBinding.instance.window.locales;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, List<Locale> fakeValue) {
        binding.window.localesTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestWindow can fake text scale factor', (WidgetTester tester) async {
    verifyThatTestWindowCanFakeProperty<double>(
      tester: tester,
      realValue: ui.window.textScaleFactor,
      fakeValue: 2.5,
      propertyRetriever: () {
        return WidgetsBinding.instance.window.textScaleFactor;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, double fakeValue) {
        binding.window.textScaleFactorTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestWindow can fake clock format', (WidgetTester tester) async {
    verifyThatTestWindowCanFakeProperty<bool>(
      tester: tester,
      realValue: ui.window.alwaysUse24HourFormat,
      fakeValue: !ui.window.alwaysUse24HourFormat,
      propertyRetriever: () {
        return WidgetsBinding.instance.window.alwaysUse24HourFormat;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, bool fakeValue) {
        binding.window.alwaysUse24HourFormatTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestWindow can fake default route name', (WidgetTester tester) async {
    verifyThatTestWindowCanFakeProperty<String>(
      tester: tester,
      realValue: ui.window.defaultRouteName,
      fakeValue: 'fake_route',
      propertyRetriever: () {
        return WidgetsBinding.instance.window.defaultRouteName;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, String fakeValue) {
        binding.window.defaultRouteNameTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestWindow can fake accessibility features', (WidgetTester tester) async {
    verifyThatTestWindowCanFakeProperty<AccessibilityFeatures>(
      tester: tester,
      realValue: ui.window.accessibilityFeatures,
      fakeValue: const FakeAccessibilityFeatures(),
      propertyRetriever: () {
        return WidgetsBinding.instance.window.accessibilityFeatures;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, AccessibilityFeatures fakeValue) {
        binding.window.accessibilityFeaturesTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestWindow can fake platform brightness', (WidgetTester tester) async {
    verifyThatTestWindowCanFakeProperty<Brightness>(
      tester: tester,
      realValue: Brightness.light,
      fakeValue: Brightness.dark,
      propertyRetriever: () {
        return WidgetsBinding.instance.window.platformBrightness;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, Brightness fakeValue) {
        binding.window.platformBrightnessTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestWindow can clear out fake properties all at once', (WidgetTester tester) {
    final double originalDevicePixelRatio = ui.window.devicePixelRatio;
    final double originalTextScaleFactor = ui.window.textScaleFactor;
    final TestWindow testWindow = retrieveTestBinding(tester).window;

    // Set fake values for window properties.
    testWindow.devicePixelRatioTestValue = 2.5;
    testWindow.textScaleFactorTestValue = 3.0;

    // Erase fake window property values.
    testWindow.clearAllTestValues();

    // Verify that the window once again reports real property values.
    expect(WidgetsBinding.instance.window.devicePixelRatio, originalDevicePixelRatio);
    expect(WidgetsBinding.instance.window.textScaleFactor, originalTextScaleFactor);
  });
}

void verifyThatTestWindowCanFakeProperty<WindowPropertyType>({
  @required WidgetTester tester,
  @required WindowPropertyType realValue,
  @required WindowPropertyType fakeValue,
  @required WindowPropertyType Function() propertyRetriever,
  @required Function(TestWidgetsFlutterBinding, WindowPropertyType fakeValue) propertyFaker,
}) {
  WindowPropertyType propertyBeforeFaking;
  WindowPropertyType propertyAfterFaking;

  propertyBeforeFaking = propertyRetriever();

  propertyFaker(retrieveTestBinding(tester), fakeValue);

  propertyAfterFaking = propertyRetriever();

  expect(propertyBeforeFaking, realValue);
  expect(propertyAfterFaking, fakeValue);
}

TestWidgetsFlutterBinding retrieveTestBinding(WidgetTester tester) {
  final WidgetsBinding binding = tester.binding;
  assert(binding is TestWidgetsFlutterBinding);
  final TestWidgetsFlutterBinding testBinding = binding;
  return testBinding;
}

class FakeWindowPadding implements WindowPadding {
  const FakeWindowPadding({
    this.left = 0.0,
    this.top = 0.0,
    this.right = 0.0,
    this.bottom = 0.0,
  });

  @override
  final double left;

  @override
  final double top;

  @override
  final double right;

  @override
  final double bottom;
}

class FakeAccessibilityFeatures implements AccessibilityFeatures {
  const FakeAccessibilityFeatures({
    this.accessibleNavigation = false,
    this.invertColors = false,
    this.disableAnimations = false,
    this.boldText = false,
    this.reduceMotion = false,
  });

  @override
  final bool accessibleNavigation;

  @override
  final bool invertColors;

  @override
  final bool disableAnimations;

  @override
  final bool boldText;

  @override
  final bool reduceMotion;
}
