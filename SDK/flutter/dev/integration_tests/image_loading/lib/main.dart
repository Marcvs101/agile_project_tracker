// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';

void main() {
  final ThrowingHttpClient httpClient = ThrowingHttpClient();
  final HttpOverrides overrides = ProvidedHttpOverrides(httpClient);
  HttpOverrides.global = overrides;
  final ZoneSpecification specification = ZoneSpecification(
    handleUncaughtError:(Zone zone, ZoneDelegate delegate, Zone parent, Object error, StackTrace stackTrace) {
    FlutterError.reportError(FlutterErrorDetails(
      exception: error,
      context: 'In the Zone handleUncaughtError handler',
      silent: false,
    ));
  });
  when(httpClient.getUrl(any)).thenAnswer((Invocation invocation) {
    final Completer<HttpClientRequest> completer = Completer<HttpClientRequest>.sync();
    completer.completeError(Error());
    return completer.future;
  });
  Zone.current.fork(specification: specification).run<void>(() {
    runApp(ImageLoader());
  });
}

class ImageLoader extends StatefulWidget {
  @override
  _ImageLoaderState createState() => _ImageLoaderState();
}

class _ImageLoaderState extends State<ImageLoader> {
  bool caughtError = false;

  @override
  void initState() {
    // This is not an image, but we don't care since we're using a faked
    // http client.
    final NetworkImage image = NetworkImage('https://github.com/flutter/flutter');
    final ImageStream stream = image.resolve(ImageConfiguration.empty);
    stream.addListener((ImageInfo info, bool syncCall) {}, onError: (dynamic error, StackTrace stackTrace) {
      print('ERROR caught by framework');
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const Text('hello', textDirection: TextDirection.ltr);
  }
}

class ThrowingHttpClient extends Mock implements HttpClient {}

class ProvidedHttpOverrides extends HttpOverrides {
  ProvidedHttpOverrides(this.httpClient);

  final ThrowingHttpClient httpClient;
  @override
  HttpClient createHttpClient(SecurityContext context) {
    return httpClient;
  }
}
