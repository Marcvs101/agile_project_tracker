// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

class PaintingBindingSpy extends BindingBase with ServicesBinding, PaintingBinding {
  int counter = 0;
  int get instantiateImageCodecCalledCount => counter;

  @override
  Future<ui.Codec> instantiateImageCodec(Uint8List list) {
    counter++;
    return ui.instantiateImageCodec(list, decodedCacheRatioCap: decodedCacheRatioCap); // ignore: deprecated_member_use_from_same_package
  }

  @override
  // ignore: MUST_CALL_SUPER
  void initLicenses() {
    // Do not include any licenses, because we're a test, and the LICENSE file
    // doesn't get generated for tests.
  }
}
