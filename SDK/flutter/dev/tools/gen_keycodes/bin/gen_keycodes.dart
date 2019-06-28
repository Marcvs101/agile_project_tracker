// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' hide Platform;

import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import 'package:gen_keycodes/code_gen.dart';
import 'package:gen_keycodes/key_data.dart';
import 'package:gen_keycodes/utils.dart';

/// Get contents of the file that contains the key code mapping in Chromium
/// source.
Future<String> getChromiumConversions() async {
  final Uri keyCodeMapUri = Uri.parse('https://cs.chromium.org/codesearch/f/chromium/src/ui/events/keycodes/dom/keycode_converter_data.inc');
  return await http.read(keyCodeMapUri);
}

/// Get contents of the file that contains the key codes in Android source.
Future<String> getAndroidKeyCodes() async {
  final Uri keyCodesUri = Uri.parse('https://android.googlesource.com/platform/frameworks/native/+/master/include/android/keycodes.h?format=TEXT');
  return utf8.decode(base64.decode(await http.read(keyCodesUri)));
}

/// Get contents of the file that contains the scan codes in Android source.
/// Yes, this is just the generic keyboard layout file for base Android distro
/// This is because there isn't any facility in Android to get the keyboard
/// layout, so we're using this to match scan codes with symbol names for most
/// common keyboards. Other than some special keyboards and game pads, this
/// should be OK.
Future<String> getAndroidScanCodes() async {
  final Uri scanCodesUri = Uri.parse('https://android.googlesource.com/platform/frameworks/base/+/master/data/keyboards/Generic.kl?format=TEXT');
  return utf8.decode(base64.decode(await http.read(scanCodesUri)));
}

Future<String> getGlfwKeyCodes() async {
  final Uri keyCodesUri = Uri.parse('https://raw.githubusercontent.com/glfw/glfw/master/include/GLFW/glfw3.h');
  return await http.read(keyCodesUri);
}

Future<void> main(List<String> rawArguments) async {
  final ArgParser argParser = ArgParser();
  argParser.addOption(
    'chromium-hid-codes',
    defaultsTo: null,
    help: 'The path to where the Chromium HID code mapping file should be '
        'read. If --chromium-hid-codes is not specified, the input will be read '
        'from the correct file in the Chromium repository.',
  );
  argParser.addOption(
    'android-keycodes',
    defaultsTo: null,
    help: 'The path to where the Android keycodes header file should be read. '
        'If --android-keycodes is not specified, the input will be read from the '
        'correct file in the Android repository.',
  );
  argParser.addOption(
    'android-scancodes',
    defaultsTo: null,
    help: 'The path to where the Android scancodes header file should be read. '
      'If --android-scancodes is not specified, the input will be read from the '
      'correct file in the Android repository.',
  );
  argParser.addOption(
    'android-domkey',
    defaultsTo: path.join(flutterRoot.path, 'dev', 'tools', 'gen_keycodes', 'data', 'key_name_to_android_name.json'),
    help: 'The path to where the Android keycode to DomKey mapping is.',
  );
  argParser.addOption(
    'glfw-keycodes',
    defaultsTo: null,
    help: 'The path to where the GLFW keycodes header file should be read. '
        'If --glfw-keycodes is not specified, the input will be read from the '
        'correct file in the GLFW github repository.',
  );
    argParser.addOption(
    'glfw-domkey',
    defaultsTo: path.join(flutterRoot.path, 'dev', 'tools', 'gen_keycodes', 'data', 'key_name_to_glfw_name.json'),
    help: 'The path to where the GLFW keycode to DomKey mapping is.',
  );

  argParser.addOption(
    'data',
    defaultsTo: path.join(flutterRoot.path, 'dev', 'tools', 'gen_keycodes', 'data', 'key_data.json'),
    help: 'The path to where the key code data file should be written when '
        'collected, and read from when generating output code. If --data is '
        'not specified, the output will be written to/read from the current '
        "directory. If the output directory doesn't exist, it, and the path to "
        'it, will be created.',
  );
  argParser.addOption(
    'code',
    defaultsTo: path.join(flutterRoot.path, 'packages', 'flutter', 'lib', 'src', 'services', 'keyboard_key.dart'),
    help: 'The path to where the output "keyboard_keys.dart" file should be'
        'written. If --code is not specified, the output will be written to the '
        'correct directory in the flutter tree. If the output directory does not '
        'exist, it, and the path to it, will be created.',
  );
  argParser.addOption(
    'maps',
    defaultsTo: path.join(flutterRoot.path, 'packages', 'flutter', 'lib', 'src', 'services', 'keyboard_maps.dart'),
    help: 'The path to where the output "keyboard_maps.dart" file should be'
      'written. If --maps is not specified, the output will be written to the '
      'correct directory in the flutter tree. If the output directory does not '
      'exist, it, and the path to it, will be created.',
  );
  argParser.addFlag(
    'collect',
    defaultsTo: false,
    negatable: false,
    help: 'If this flag is set, then collect and parse header files from '
        'Chromium and Android instead of reading pre-parsed data from '
        '"key_data.json", and then update "key_data.json" with the fresh data.',
  );
  argParser.addFlag(
    'help',
    defaultsTo: false,
    negatable: false,
    help: 'Print help for this command.',
  );

  final ArgResults parsedArguments = argParser.parse(rawArguments);

  if (parsedArguments['help']) {
    print(argParser.usage);
    exit(0);
  }

  KeyData data;
  if (parsedArguments['collect']) {
    String hidCodes;
    if (parsedArguments['chromium-hid-codes'] == null) {
      hidCodes = await getChromiumConversions();
    } else {
      hidCodes = File(parsedArguments['chromium-hid-codes']).readAsStringSync();
    }

    String androidKeyCodes;
    if (parsedArguments['android-keycodes'] == null) {
      androidKeyCodes = await getAndroidKeyCodes();
    } else {
      androidKeyCodes = File(parsedArguments['android-keycodes']).readAsStringSync();
    }

    String androidScanCodes;
    if (parsedArguments['android-scancodes'] == null) {
      androidScanCodes = await getAndroidScanCodes();
    } else {
      androidScanCodes = File(parsedArguments['android-scancodes']).readAsStringSync();
    }

    String glfwKeyCodes;
    if (parsedArguments['glfw-keycodes'] == null) {
      glfwKeyCodes = await getGlfwKeyCodes();
    } else {
      glfwKeyCodes = File(parsedArguments['glfw-keycodes']).readAsStringSync();
    }

    final String glfwToDomKey = File(parsedArguments['glfw-domkey']).readAsStringSync();
    final String androidToDomKey = File(parsedArguments['android-domkey']).readAsStringSync();

    data = KeyData(hidCodes, androidScanCodes, androidKeyCodes, androidToDomKey, glfwKeyCodes, glfwToDomKey);

    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    File(parsedArguments['data']).writeAsStringSync(encoder.convert(data.toJson()));
  } else {
    data = KeyData.fromJson(json.decode(await File(parsedArguments['data']).readAsString()));
  }

  final File codeFile = File(parsedArguments['code']);
  if (!codeFile.existsSync()) {
    codeFile.createSync(recursive: true);
  }

  final File mapsFile = File(parsedArguments['maps']);
  if (!mapsFile.existsSync()) {
    mapsFile.createSync(recursive: true);
  }

  final CodeGenerator generator = CodeGenerator(data);
  await codeFile.writeAsString(generator.generateKeyboardKeys());
  await mapsFile.writeAsString(generator.generateKeyboardMaps());
}
