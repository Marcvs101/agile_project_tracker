// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Platform;

/// Returns [Platform.pathSeparator], suitably escaped so as to be usable in a
/// regular expression.
String get pathSeparatorForRegExp {
  switch (Platform.pathSeparator) {
    case r'/':
      return r'/';
    case r'\':
      return r'\\'; // because dividerRegExp gets inserted into regexps
    default:
      throw 'Unsupported platform.';
  }
}
