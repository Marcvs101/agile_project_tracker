// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';

import '../test_utils.dart';

abstract class Project {
  Directory dir;

  String get pubspec;
  String get main;

  Uri get mainDart => Uri.parse('package:test/main.dart');

  Future<void> setUpIn(Directory dir) async {
    this.dir = dir;
    writeFile(fs.path.join(dir.path, 'pubspec.yaml'), pubspec);
    if (main != null) {
      writeFile(fs.path.join(dir.path, 'lib', 'main.dart'), main);
    }
    await getPackages(dir.path);
  }

  int lineContaining(String contents, String search) {
    final int index = contents.split('\n').indexWhere((String l) => l.contains(search));
    if (index == -1)
      throw Exception("Did not find '$search' inside the file");
    return index + 1; // first line is line 1, not line 0
  }
}
