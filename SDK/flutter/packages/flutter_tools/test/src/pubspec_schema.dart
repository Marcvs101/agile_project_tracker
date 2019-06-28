// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/flutter_manifest.dart';

/// Writes a schemaData used for validating pubspec.yaml files when parsing
/// asset information.
void writeSchemaFile(FileSystem filesystem, String schemaData) {
  final String schemaPath = buildSchemaPath(filesystem);
  final File schemaFile = filesystem.file(schemaPath);

  final String schemaDir = buildSchemaDir(filesystem);

  filesystem.directory(schemaDir).createSync(recursive: true);
  schemaFile.writeAsStringSync(schemaData);
}

/// Writes an empty schemaData that will validate any pubspec.yaml file.
void writeEmptySchemaFile(FileSystem filesystem) {
  writeSchemaFile(filesystem, '{}');
}
