// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui show Image;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

class TestImageInfo implements ImageInfo {
  const TestImageInfo(this.value, { this.image, this.scale = 1.0 });

  @override
  final ui.Image image;

  @override
  final double scale;

  final int value;

  @override
  String toString() => '$runtimeType($value)';
}

class TestImageProvider extends ImageProvider<int> {
  const TestImageProvider(this.key, this.imageValue, { this.image });
  final int key;
  final int imageValue;
  final ui.Image image;

  @override
  Future<int> obtainKey(ImageConfiguration configuration) {
    return Future<int>.value(key);
  }

  @override
  ImageStreamCompleter load(int key) {
    return OneFrameImageStreamCompleter(
      SynchronousFuture<ImageInfo>(TestImageInfo(imageValue, image: image))
    );
  }

  @override
  String toString() => '$runtimeType($key, $imageValue)';
}

class FailingTestImageProvider extends TestImageProvider {
  const FailingTestImageProvider(int key, int imageValue, { ui.Image image }) : super(key, imageValue, image: image);

  @override
  ImageStreamCompleter load(int key) {
    return OneFrameImageStreamCompleter(Future<ImageInfo>.sync(() => Future<ImageInfo>.error('loading failed!')));
  }
}

Future<ImageInfo> extractOneFrame(ImageStream stream) {
  final Completer<ImageInfo> completer = Completer<ImageInfo>();
  void listener(ImageInfo image, bool synchronousCall) {
    completer.complete(image);
    stream.removeListener(listener);
  }
  stream.addListener(listener);
  return completer.future;
}

class TestImage implements ui.Image {
  const TestImage({this.height = 0, this.width = 0});
  @override
  final int height;
  @override
  final int width;

  @override
  void dispose() { }

  @override
  Future<ByteData> toByteData({ ImageByteFormat format = ImageByteFormat.rawRgba }) {
    throw UnimplementedError();
  }
}

class ErrorImageProvider extends ImageProvider<ErrorImageProvider> {
  @override
  ImageStreamCompleter load(ErrorImageProvider key) {
    throw Error();
  }

  @override
  Future<ErrorImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<ErrorImageProvider>(this);
  }
}

class ObtainKeyErrorImageProvider extends ImageProvider<ObtainKeyErrorImageProvider> {
  @override
  ImageStreamCompleter load(ObtainKeyErrorImageProvider key) {
    throw Error();
  }

  @override
  Future<ObtainKeyErrorImageProvider> obtainKey(ImageConfiguration configuration) {
    throw Error();
  }
}

class LoadErrorImageProvider extends ImageProvider<LoadErrorImageProvider> {
  @override
  ImageStreamCompleter load(LoadErrorImageProvider key) {
    throw Error();
  }

   @override
  Future<LoadErrorImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<LoadErrorImageProvider>(this);
  }
}

class LoadErrorCompleterImageProvider extends ImageProvider<LoadErrorCompleterImageProvider> {
  @override
  ImageStreamCompleter load(LoadErrorCompleterImageProvider key) {
    final Completer<void> completer = Completer<void>.sync();
    completer.completeError(Error());
    return OneFrameImageStreamCompleter(completer.future);
  }

   @override
  Future<LoadErrorCompleterImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<LoadErrorCompleterImageProvider>(this);
  }
}

class TestImageStreamCompleter extends ImageStreamCompleter {}
