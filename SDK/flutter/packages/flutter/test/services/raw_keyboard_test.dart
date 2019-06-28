// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _ModifierCheck {
  const _ModifierCheck(this.key, this.side);
  final ModifierKey key;
  final KeyboardSide side;
}

void main() {
  group('RawKeyEventDataAndroid', () {
    const Map<int, _ModifierCheck> modifierTests = <int, _ModifierCheck>{
      RawKeyEventDataAndroid.modifierAlt | RawKeyEventDataAndroid.modifierLeftAlt: _ModifierCheck(ModifierKey.altModifier, KeyboardSide.left),
      RawKeyEventDataAndroid.modifierAlt | RawKeyEventDataAndroid.modifierRightAlt: _ModifierCheck(ModifierKey.altModifier, KeyboardSide.right),
      RawKeyEventDataAndroid.modifierShift | RawKeyEventDataAndroid.modifierLeftShift: _ModifierCheck(ModifierKey.shiftModifier, KeyboardSide.left),
      RawKeyEventDataAndroid.modifierShift | RawKeyEventDataAndroid.modifierRightShift: _ModifierCheck(ModifierKey.shiftModifier, KeyboardSide.right),
      RawKeyEventDataAndroid.modifierSym: _ModifierCheck(ModifierKey.symbolModifier, KeyboardSide.all),
      RawKeyEventDataAndroid.modifierFunction: _ModifierCheck(ModifierKey.functionModifier, KeyboardSide.all),
      RawKeyEventDataAndroid.modifierControl | RawKeyEventDataAndroid.modifierLeftControl: _ModifierCheck(ModifierKey.controlModifier, KeyboardSide.left),
      RawKeyEventDataAndroid.modifierControl | RawKeyEventDataAndroid.modifierRightControl: _ModifierCheck(ModifierKey.controlModifier, KeyboardSide.right),
      RawKeyEventDataAndroid.modifierMeta | RawKeyEventDataAndroid.modifierLeftMeta: _ModifierCheck(ModifierKey.metaModifier, KeyboardSide.left),
      RawKeyEventDataAndroid.modifierMeta | RawKeyEventDataAndroid.modifierRightMeta: _ModifierCheck(ModifierKey.metaModifier, KeyboardSide.right),
      RawKeyEventDataAndroid.modifierCapsLock: _ModifierCheck(ModifierKey.capsLockModifier, KeyboardSide.all),
      RawKeyEventDataAndroid.modifierNumLock: _ModifierCheck(ModifierKey.numLockModifier, KeyboardSide.all),
      RawKeyEventDataAndroid.modifierScrollLock: _ModifierCheck(ModifierKey.scrollLockModifier, KeyboardSide.all),
    };

    test('modifier keys are recognized individually', () {
      for (int modifier in modifierTests.keys) {
        final RawKeyEvent event = RawKeyEvent.fromMessage(<String, dynamic>{
          'type': 'keydown',
          'keymap': 'android',
          'keyCode': 0x04,
          'plainCodePoint': 0x64,
          'codePoint': 0x44,
          'scanCode': 0x20,
          'metaState': modifier,
        });
        final RawKeyEventDataAndroid data = event.data;
        for (ModifierKey key in ModifierKey.values) {
          if (modifierTests[modifier].key == key) {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier].side),
              isTrue,
              reason: "$key should be pressed with metaState $modifier, but isn't.",
            );
            expect(data.getModifierSide(key), equals(modifierTests[modifier].side));
          } else {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier].side),
              isFalse,
              reason: '$key should not be pressed with metaState $modifier.',
            );
          }
        }
      }
    });
    test('modifier keys are recognized when combined', () {
      for (int modifier in modifierTests.keys) {
        if (modifier == RawKeyEventDataAndroid.modifierFunction) {
          // No need to combine function key with itself.
          continue;
        }
        final RawKeyEvent event = RawKeyEvent.fromMessage(<String, dynamic>{
          'type': 'keydown',
          'keymap': 'android',
          'keyCode': 0x04,
          'plainCodePoint': 0x64,
          'codePoint': 0x44,
          'scanCode': 0x20,
          'metaState': modifier | RawKeyEventDataAndroid.modifierFunction,
        });
        final RawKeyEventDataAndroid data = event.data;
        for (ModifierKey key in ModifierKey.values) {
          if (modifierTests[modifier].key == key || key == ModifierKey.functionModifier) {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier].side),
              isTrue,
              reason: '$key should be pressed with metaState $modifier '
                  "and additional key ${RawKeyEventDataAndroid.modifierFunction}, but isn't.",
            );
            if (key != ModifierKey.functionModifier) {
              expect(data.getModifierSide(key), equals(modifierTests[modifier].side));
            } else {
              expect(data.getModifierSide(key), equals(KeyboardSide.all));
            }
          } else {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier].side),
              isFalse,
              reason: '$key should not be pressed with metaState $modifier '
                  'and additional key ${RawKeyEventDataAndroid.modifierFunction}.',
            );
          }
        }
      }
    });
    test('Printable keyboard keys are correctly translated', () {
      final RawKeyEvent keyAEvent = RawKeyEvent.fromMessage(<String, dynamic>{
        'type': 'keydown',
        'keymap': 'android',
        'keyCode': 29,
        'plainCodePoint': 'a'.codeUnitAt(0),
        'codePoint': 'A'.codeUnitAt(0),
        'character': 'A',
        'scanCode': 30,
        'metaState': 0x0,
      });
      final RawKeyEventDataAndroid data = keyAEvent.data;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.keyA));
      expect(data.logicalKey, equals(LogicalKeyboardKey.keyA));
      expect(data.keyLabel, equals('a'));
    });
    test('Control keyboard keys are correctly translated', () {
      final RawKeyEvent escapeKeyEvent = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'android',
        'keyCode': 111,
        'codePoint': 0,
        'character': null,
        'scanCode': 1,
        'metaState': 0x0,
      });
      final RawKeyEventDataAndroid data = escapeKeyEvent.data;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.escape));
      expect(data.logicalKey, equals(LogicalKeyboardKey.escape));
      expect(data.keyLabel, isNull);
    });
    test('Modifier keyboard keys are correctly translated', () {
      final RawKeyEvent shiftLeftKeyEvent = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'android',
        'keyCode': 59,
        'plainCodePoint': 0,
        'codePoint': 0,
        'character': null,
        'scanCode': 42,
        'metaState': RawKeyEventDataAndroid.modifierLeftShift,
      });
      final RawKeyEventDataAndroid data = shiftLeftKeyEvent.data;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.shiftLeft));
      expect(data.logicalKey, equals(LogicalKeyboardKey.shiftLeft));
      expect(data.keyLabel, isNull);
    });
  });
  group('RawKeyEventDataFuchsia', () {
    const Map<int, _ModifierCheck> modifierTests = <int, _ModifierCheck>{
      RawKeyEventDataFuchsia.modifierAlt: _ModifierCheck(ModifierKey.altModifier, KeyboardSide.any),
      RawKeyEventDataFuchsia.modifierLeftAlt: _ModifierCheck(ModifierKey.altModifier, KeyboardSide.left),
      RawKeyEventDataFuchsia.modifierRightAlt: _ModifierCheck(ModifierKey.altModifier, KeyboardSide.right),
      RawKeyEventDataFuchsia.modifierShift: _ModifierCheck(ModifierKey.shiftModifier, KeyboardSide.any),
      RawKeyEventDataFuchsia.modifierLeftShift: _ModifierCheck(ModifierKey.shiftModifier, KeyboardSide.left),
      RawKeyEventDataFuchsia.modifierRightShift: _ModifierCheck(ModifierKey.shiftModifier, KeyboardSide.right),
      RawKeyEventDataFuchsia.modifierControl: _ModifierCheck(ModifierKey.controlModifier, KeyboardSide.any),
      RawKeyEventDataFuchsia.modifierLeftControl: _ModifierCheck(ModifierKey.controlModifier, KeyboardSide.left),
      RawKeyEventDataFuchsia.modifierRightControl: _ModifierCheck(ModifierKey.controlModifier, KeyboardSide.right),
      RawKeyEventDataFuchsia.modifierMeta: _ModifierCheck(ModifierKey.metaModifier, KeyboardSide.any),
      RawKeyEventDataFuchsia.modifierLeftMeta: _ModifierCheck(ModifierKey.metaModifier, KeyboardSide.left),
      RawKeyEventDataFuchsia.modifierRightMeta: _ModifierCheck(ModifierKey.metaModifier, KeyboardSide.right),
      RawKeyEventDataFuchsia.modifierCapsLock: _ModifierCheck(ModifierKey.capsLockModifier, KeyboardSide.any),
    };

    test('modifier keys are recognized individually', () {
      for (int modifier in modifierTests.keys) {
        final RawKeyEvent event = RawKeyEvent.fromMessage(<String, dynamic>{
          'type': 'keydown',
          'keymap': 'fuchsia',
          'hidUsage': 0x04,
          'codePoint': 0x64,
          'modifiers': modifier,
        });
        final RawKeyEventDataFuchsia data = event.data;
        for (ModifierKey key in ModifierKey.values) {
          if (modifierTests[modifier].key == key) {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier].side),
              isTrue,
              reason: "$key should be pressed with metaState $modifier, but isn't.",
            );
          } else {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier].side),
              isFalse,
              reason: '$key should not be pressed with metaState $modifier.',
            );
          }
        }
      }
    });
    test('modifier keys are recognized when combined', () {
      for (int modifier in modifierTests.keys) {
        if (modifier == RawKeyEventDataFuchsia.modifierCapsLock) {
          // No need to combine caps lock key with itself.
          continue;
        }
        final RawKeyEvent event = RawKeyEvent.fromMessage(<String, dynamic>{
          'type': 'keydown',
          'keymap': 'fuchsia',
          'hidUsage': 0x04,
          'codePoint': 0x64,
          'modifiers': modifier | RawKeyEventDataFuchsia.modifierCapsLock,
        });
        final RawKeyEventDataFuchsia data = event.data;
        for (ModifierKey key in ModifierKey.values) {
          if (modifierTests[modifier].key == key || key == ModifierKey.capsLockModifier) {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier].side),
              isTrue,
              reason: '$key should be pressed with metaState $modifier '
                  "and additional key ${RawKeyEventDataFuchsia.modifierCapsLock}, but isn't.",
            );
          } else {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier].side),
              isFalse,
              reason: '$key should not be pressed with metaState $modifier '
                  'and additional key ${RawKeyEventDataFuchsia.modifierCapsLock}.',
            );
          }
        }
      }
    });
    test('Printable keyboard keys are correctly translated', () {
      final RawKeyEvent keyAEvent = RawKeyEvent.fromMessage(<String, dynamic>{
        'type': 'keydown',
        'keymap': 'fuchsia',
        'hidUsage': 0x00070004,
        'codePoint': 'a'.codeUnitAt(0),
        'character': 'a',
      });
      final RawKeyEventDataFuchsia data = keyAEvent.data;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.keyA));
      expect(data.logicalKey, equals(LogicalKeyboardKey.keyA));
      expect(data.keyLabel, equals('a'));
    });
    test('Control keyboard keys are correctly translated', () {
      final RawKeyEvent escapeKeyEvent = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'fuchsia',
        'hidUsage': 0x00070029,
        'codePoint': null,
        'character': null,
      });
      final RawKeyEventDataFuchsia data = escapeKeyEvent.data;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.escape));
      expect(data.logicalKey, equals(LogicalKeyboardKey.escape));
      expect(data.keyLabel, isNull);
    });
    test('Modifier keyboard keys are correctly translated', () {
      final RawKeyEvent shiftLeftKeyEvent = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'fuchsia',
        'hidUsage': 0x000700e1,
        'codePoint': null,
        'character': null,
      });
      final RawKeyEventDataFuchsia data = shiftLeftKeyEvent.data;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.shiftLeft));
      expect(data.logicalKey, equals(LogicalKeyboardKey.shiftLeft));
      expect(data.keyLabel, isNull);
    });
  });
  group('RawKeyEventDataMacOs', () {
    const Map<int, _ModifierCheck> modifierTests = <int, _ModifierCheck>{
      RawKeyEventDataMacOs.modifierOption | RawKeyEventDataMacOs.modifierLeftOption: _ModifierCheck(ModifierKey.altModifier, KeyboardSide.left),
      RawKeyEventDataMacOs.modifierOption | RawKeyEventDataMacOs.modifierRightOption: _ModifierCheck(ModifierKey.altModifier, KeyboardSide.right),
      RawKeyEventDataMacOs.modifierShift | RawKeyEventDataMacOs.modifierLeftShift: _ModifierCheck(ModifierKey.shiftModifier, KeyboardSide.left),
      RawKeyEventDataMacOs.modifierShift | RawKeyEventDataMacOs.modifierRightShift: _ModifierCheck(ModifierKey.shiftModifier, KeyboardSide.right),
      RawKeyEventDataMacOs.modifierFunction: _ModifierCheck(ModifierKey.functionModifier, KeyboardSide.all),
      RawKeyEventDataMacOs.modifierControl | RawKeyEventDataMacOs.modifierLeftControl: _ModifierCheck(ModifierKey.controlModifier, KeyboardSide.left),
      RawKeyEventDataMacOs.modifierControl | RawKeyEventDataMacOs.modifierRightControl: _ModifierCheck(ModifierKey.controlModifier, KeyboardSide.right),
      RawKeyEventDataMacOs.modifierCommand | RawKeyEventDataMacOs.modifierLeftCommand: _ModifierCheck(ModifierKey.metaModifier, KeyboardSide.left),
      RawKeyEventDataMacOs.modifierCommand | RawKeyEventDataMacOs.modifierRightCommand: _ModifierCheck(ModifierKey.metaModifier, KeyboardSide.right),
      RawKeyEventDataMacOs.modifierCapsLock: _ModifierCheck(ModifierKey.capsLockModifier, KeyboardSide.all),
    };

    test('modifier keys are recognized individually', () {
      for (int modifier in modifierTests.keys) {
        final RawKeyEvent event = RawKeyEvent.fromMessage(<String, dynamic>{
          'type': 'keydown',
          'keymap': 'macos',
          'keyCode': 0x04,
          'characters': 'a',
          'charactersIgnoringModifiers': 'a',
          'modifiers': modifier,
        });
        final RawKeyEventDataMacOs data = event.data;
        for (ModifierKey key in ModifierKey.values) {
          if (modifierTests[modifier].key == key) {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier].side),
              isTrue,
              reason: "$key should be pressed with metaState $modifier, but isn't.",
            );
            expect(data.getModifierSide(key), equals(modifierTests[modifier].side));
          } else {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier].side),
              isFalse,
              reason: '$key should not be pressed with metaState $modifier.',
            );
          }
        }
      }
    });
    test('modifier keys are recognized when combined', () {
      for (int modifier in modifierTests.keys) {
        if (modifier == RawKeyEventDataMacOs.modifierFunction) {
          // No need to combine function key with itself.
          continue;
        }
        final RawKeyEvent event = RawKeyEvent.fromMessage(<String, dynamic>{
          'type': 'keydown',
          'keymap': 'macos',
          'keyCode': 0x04,
          'plainCodePoint': 0x64,
          'characters': 'a',
          'charactersIgnoringModifiers': 'a',
          'modifiers': modifier | RawKeyEventDataMacOs.modifierFunction,
        });
        final RawKeyEventDataMacOs data = event.data;
        for (ModifierKey key in ModifierKey.values) {
          if (modifierTests[modifier].key == key || key == ModifierKey.functionModifier) {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier].side),
              isTrue,
              reason: '$key should be pressed with metaState $modifier '
                  "and additional key ${RawKeyEventDataMacOs.modifierFunction}, but isn't.",
            );
            if (key != ModifierKey.functionModifier) {
              expect(data.getModifierSide(key), equals(modifierTests[modifier].side));
            } else {
              expect(data.getModifierSide(key), equals(KeyboardSide.all));
            }
          } else {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier].side),
              isFalse,
              reason: '$key should not be pressed with metaState $modifier '
                  'and additional key ${RawKeyEventDataMacOs.modifierFunction}.',
            );
          }
        }
      }
    });
    test('Printable keyboard keys are correctly translated', () {
      const String unmodifiedCharacter = 'a';
      final RawKeyEvent keyAEvent = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'macos',
        'keyCode': 0x00000000,
        'characters': 'a',
        'charactersIgnoringModifiers': unmodifiedCharacter,
        'modifiers': 0x0,
      });
      final RawKeyEventDataMacOs data = keyAEvent.data;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.keyA));
      expect(data.logicalKey, equals(LogicalKeyboardKey.keyA));
      expect(data.keyLabel, equals('a'));
    });
    test('Control keyboard keys are correctly translated', () {
      final RawKeyEvent escapeKeyEvent = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'macos',
        'keyCode': 0x00000035,
        'characters': '',
        'charactersIgnoringModifiers': '',
        'character': null,
        'modifiers': 0x0,
      });
      final RawKeyEventDataMacOs data = escapeKeyEvent.data;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.escape));
      expect(data.logicalKey, equals(LogicalKeyboardKey.escape));
      expect(data.keyLabel, isNull);
    });
    test('Modifier keyboard keys are correctly translated', () {
      final RawKeyEvent shiftLeftKeyEvent = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'macos',
        'keyCode': 0x00000038,
        'characters': '',
        'charactersIgnoringModifiers': '',
        'character': null,
        'modifiers': RawKeyEventDataMacOs.modifierLeftShift,
      });
      final RawKeyEventDataMacOs data = shiftLeftKeyEvent.data;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.shiftLeft));
      expect(data.logicalKey, equals(LogicalKeyboardKey.shiftLeft));
      expect(data.keyLabel, isNull);
    });
  });
  group('RawKeyEventDataLinux-GFLW', () {
    const Map<int, _ModifierCheck> modifierTests = <int, _ModifierCheck>{
      GLFWKeyHelper.modifierAlt: _ModifierCheck(ModifierKey.altModifier, KeyboardSide.any),
      GLFWKeyHelper.modifierShift: _ModifierCheck(ModifierKey.shiftModifier, KeyboardSide.any),
      GLFWKeyHelper.modifierControl: _ModifierCheck(ModifierKey.controlModifier, KeyboardSide.any),
      GLFWKeyHelper.modifierMeta: _ModifierCheck(ModifierKey.metaModifier, KeyboardSide.any),
      GLFWKeyHelper.modifierNumericPad: _ModifierCheck(ModifierKey.numLockModifier, KeyboardSide.all),
      GLFWKeyHelper.modifierCapsLock: _ModifierCheck(ModifierKey.capsLockModifier, KeyboardSide.all),
    };

    test('modifier keys are recognized individually', () {
      for (int modifier in modifierTests.keys) {
        final RawKeyEvent event = RawKeyEvent.fromMessage(<String, dynamic>{
          'type': 'keydown',
          'keymap': 'linux',
          'toolkit': 'glfw',
          'keyCode': 0x04,
          'scanCode': 0x01,
          'codePoint': 0x10,
          'modifiers': modifier,
        });
        final RawKeyEventDataLinux data = event.data;
        for (ModifierKey key in ModifierKey.values) {
          if (modifierTests[modifier].key == key) {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier].side),
              isTrue,
              reason: "$key should be pressed with metaState $modifier, but isn't.",
            );
            expect(data.getModifierSide(key), equals(modifierTests[modifier].side));
          } else {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier].side),
              isFalse,
              reason: '$key should not be pressed with metaState $modifier.',
            );
          }
        }
      }
    });
    test('modifier keys are recognized when combined', () {
      for (int modifier in modifierTests.keys) {
        if (modifier == GLFWKeyHelper.modifierControl) {
          // No need to combine CTRL key with itself.
          continue;
        }
        final RawKeyEvent event = RawKeyEvent.fromMessage(<String, dynamic>{
          'type': 'keydown',
          'keymap': 'linux',
          'toolkit': 'glfw',
          'keyCode': 0x04,
          'scanCode': 0x64,
          'codePoint': 0x1,
          'modifiers': modifier | GLFWKeyHelper.modifierControl,
        });
        final RawKeyEventDataLinux data = event.data;
        for (ModifierKey key in ModifierKey.values) {
          if (modifierTests[modifier].key == key || key == ModifierKey.controlModifier) {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier].side),
              isTrue,
              reason: '$key should be pressed with metaState $modifier '
                  "and additional key ${GLFWKeyHelper.modifierControl}, but isn't.",
            );
            if (key != ModifierKey.controlModifier) {
              expect(data.getModifierSide(key), equals(modifierTests[modifier].side));
            } else {
              expect(data.getModifierSide(key), equals(KeyboardSide.any));
            }
          } else {
            expect(
              data.isModifierPressed(key, side: modifierTests[modifier].side),
              isFalse,
              reason: '$key should not be pressed with metaState $modifier '
                  'and additional key ${GLFWKeyHelper.modifierControl}.',
            );
          }
        }
      }
    });
    test('Printable keyboard keys are correctly translated', () {
      final RawKeyEvent keyAEvent = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'linux',
        'toolkit': 'glfw',
        'keyCode': 65,
        'scanCode': 0x00000026,
        'codePoint': 97,
        'modifiers': 0x0,
      });
      final RawKeyEventDataLinux data = keyAEvent.data;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.keyA));
      expect(data.logicalKey, equals(LogicalKeyboardKey.keyA));
      expect(data.keyLabel, equals('a'));
    });
    test('Control keyboard keys are correctly translated', () {
      final RawKeyEvent escapeKeyEvent = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'linux',
        'toolkit': 'glfw',
        'keyCode': 256,
        'scanCode': 0x00000009,
        'codePoint': 0,
        'modifiers': 0x0,
      });
      final RawKeyEventDataLinux data = escapeKeyEvent.data;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.escape));
      expect(data.logicalKey, equals(LogicalKeyboardKey.escape));
      expect(data.keyLabel, isNull);
    });
    test('Modifier keyboard keys are correctly translated', () {
      final RawKeyEvent shiftLeftKeyEvent = RawKeyEvent.fromMessage(const <String, dynamic>{
        'type': 'keydown',
        'keymap': 'linux',
        'toolkit': 'glfw',
        'keyCode': 340,
        'scanCode': 0x00000032,
        'codePoint': 0,
      });
      final RawKeyEventDataLinux data = shiftLeftKeyEvent.data;
      expect(data.physicalKey, equals(PhysicalKeyboardKey.shiftLeft));
      expect(data.logicalKey, equals(LogicalKeyboardKey.shiftLeft));
      expect(data.keyLabel, isNull);
    });
  });
}
