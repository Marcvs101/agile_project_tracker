import 'localizations_utils.dart';

HeaderGenerator generateMaterialHeader = (String regenerateInstructions) {
  return '''
// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file has been automatically generated. Please do not edit it manually.
// To regenerate the file, use:
// $regenerateInstructions

import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../material_localizations.dart';

// The classes defined here encode all of the translations found in the
// `flutter_localizations/lib/src/l10n/*.arb` files.
//
// These classes are constructed by the [getMaterialTranslation] method at the
// bottom of this file, and used by the [_MaterialLocalizationsDelegate.load]
// method defined in `flutter_localizations/lib/src/material_localizations.dart`.''';
};

/// Returns the source of the constructor for a GlobalMaterialLocalizations
/// subclass.
ConstructorGenerator generateMaterialConstructor = (LocaleInfo locale) {
  final String localeName = locale.originalString;
  return '''
  /// Create an instance of the translation bundle for ${describeLocale(localeName)}.
  ///
  /// For details on the meaning of the arguments, see [GlobalMaterialLocalizations].
  const MaterialLocalization${camelCase(locale)}({
    String localeName = '$localeName',
    @required intl.DateFormat fullYearFormat,
    @required intl.DateFormat mediumDateFormat,
    @required intl.DateFormat longDateFormat,
    @required intl.DateFormat yearMonthFormat,
    @required intl.NumberFormat decimalFormat,
    @required intl.NumberFormat twoDigitZeroPaddedFormat,
  }) : super(
    localeName: localeName,
    fullYearFormat: fullYearFormat,
    mediumDateFormat: mediumDateFormat,
    longDateFormat: longDateFormat,
    yearMonthFormat: yearMonthFormat,
    decimalFormat: decimalFormat,
    twoDigitZeroPaddedFormat: twoDigitZeroPaddedFormat,
  );''';
};

const String materialFactoryDeclaration = '''
GlobalMaterialLocalizations getMaterialTranslation(
  Locale locale,
  intl.DateFormat fullYearFormat,
  intl.DateFormat mediumDateFormat,
  intl.DateFormat longDateFormat,
  intl.DateFormat yearMonthFormat,
  intl.NumberFormat decimalFormat,
  intl.NumberFormat twoDigitZeroPaddedFormat,
) {''';

const String materialFactoryArguments =
    'fullYearFormat: fullYearFormat, mediumDateFormat: mediumDateFormat, longDateFormat: longDateFormat, yearMonthFormat: yearMonthFormat, decimalFormat: decimalFormat, twoDigitZeroPaddedFormat: twoDigitZeroPaddedFormat';
