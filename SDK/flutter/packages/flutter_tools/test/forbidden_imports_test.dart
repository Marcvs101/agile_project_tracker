// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';

import 'src/common.dart';

void main() {
  final String flutterTools = fs.path.join(getFlutterRoot(), 'packages', 'flutter_tools');

  test('no unauthorized imports of dart:io', () {
    final List<String> whitelistedPaths = <String>[
      fs.path.join(flutterTools, 'lib', 'src', 'base', 'io.dart'),
      fs.path.join(flutterTools, 'lib', 'src', 'build_runner', 'kernel_builder.dart'),
    ];
    bool _isNotWhitelisted(FileSystemEntity entity) => whitelistedPaths.every((String path) => path != entity.path);

    for (String dirName in <String>['lib', 'bin']) {
      final Iterable<File> files = fs.directory(fs.path.join(flutterTools, dirName))
        .listSync(recursive: true)
        .where(_isDartFile)
        .where(_isNotWhitelisted)
        .map(_asFile);
      for (File file in files) {
        for (String line in file.readAsLinesSync()) {
          if (line.startsWith(RegExp(r'import.*dart:io')) &&
              !line.contains('ignore: dart_io_import')) {
            final String relativePath = fs.path.relative(file.path, from:flutterTools);
            fail("$relativePath imports 'dart:io'; import 'lib/src/base/io.dart' instead");
          }
        }
      }
    }
  });

  test('no unauthorized imports of package:path', () {
    final String whitelistedPath = fs.path.join(flutterTools, 'lib', 'src', 'build_runner', 'kernel_builder.dart');
    for (String dirName in <String>['lib', 'bin', 'test']) {
      final Iterable<File> files = fs.directory(fs.path.join(flutterTools, dirName))
        .listSync(recursive: true)
        .where(_isDartFile)
        .where((FileSystemEntity entity) => entity.path != whitelistedPath)
        .map(_asFile);
      for (File file in files) {
        for (String line in file.readAsLinesSync()) {
          if (line.startsWith(RegExp(r'import.*package:path/path.dart')) &&
              !line.contains('ignore: package_path_import')) {
            final String relativePath = fs.path.relative(file.path, from:flutterTools);
            fail("$relativePath imports 'package:path/path.dart'; use 'fs.path' instead");
          }
        }
      }
    }
  });

  test('no unauthorized imports of dart:convert', () {
    final List<String> whitelistedPaths = <String>[
      fs.path.join(flutterTools, 'lib', 'src', 'convert.dart'),
      fs.path.join(flutterTools, 'lib', 'src', 'build_runner', 'kernel_builder.dart'),
    ];
    bool _isNotWhitelisted(FileSystemEntity entity) => whitelistedPaths.every((String path) => path != entity.path);

    for (String dirName in <String>['lib']) {
      final Iterable<File> files = fs.directory(fs.path.join(flutterTools, dirName))
        .listSync(recursive: true)
        .where(_isDartFile)
        .where(_isNotWhitelisted)
        .map(_asFile);
      for (File file in files) {
        for (String line in file.readAsLinesSync()) {
          if (line.startsWith(RegExp(r'import.*dart:convert')) &&
              !line.contains('ignore: dart_convert_import')) {
            final String relativePath = fs.path.relative(file.path, from:flutterTools);
            fail("$relativePath imports 'dart:convert'; import 'lib/src/convert.dart' instead");
          }
        }
      }
    }
  });

  test('no unauthorized imports of build_runner', () {
    final List<String> whitelistedPaths = <String>[
      fs.path.join(flutterTools, 'test', 'src', 'build_runner'),
      fs.path.join(flutterTools, 'lib', 'src', 'build_runner'),
      fs.path.join(flutterTools, 'lib', 'executable.dart'),
    ];
    bool _isNotWhitelisted(FileSystemEntity entity) => whitelistedPaths.every((String path) => !entity.path.contains(path));

    for (String dirName in <String>['lib']) {
      final Iterable<File> files = fs.directory(fs.path.join(flutterTools, dirName))
        .listSync(recursive: true)
        .where(_isDartFile)
        .where(_isNotWhitelisted)
        .map(_asFile);
      for (File file in files) {
        for (String line in file.readAsLinesSync()) {
          if (line.startsWith(RegExp(r'import.*package:build_runner_core/build_runner_core.dart')) ||
              line.startsWith(RegExp(r'import.*package:build_runner/build_runner.dart')) ||
              line.startsWith(RegExp(r'import.*package:build_config/build_config.dart')) ||
              line.startsWith(RegExp(r'import.*build_runner/.*.dart'))) {
            final String relativePath = fs.path.relative(file.path, from:flutterTools);
            fail('$relativePath imports a build_runner package');
          }
        }
      }
    }
  });
}

bool _isDartFile(FileSystemEntity entity) => entity is File && entity.path.endsWith('.dart');

File _asFile(FileSystemEntity entity) => entity;
