// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MaterialApp(
    title: 'Hardware Key Demo',
    home: Scaffold(
      appBar: AppBar(
        title: const Text('Hardware Key Demo'),
      ),
      body: const Center(
        child: RawKeyboardDemo(),
      ),
    ),
  ));
}

class RawKeyboardDemo extends StatefulWidget {
  const RawKeyboardDemo({Key key}) : super(key: key);

  @override
  _HardwareKeyDemoState createState() => _HardwareKeyDemoState();
}

class _HardwareKeyDemoState extends State<RawKeyboardDemo> {
  final FocusNode _focusNode = FocusNode();
  RawKeyEvent _event;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(RawKeyEvent event) {
    setState(() {
      _event = event;
    });
  }

  String _asHex(int value) => value != null ? '0x${value.toRadixString(16)}' : 'null';

  String _getEnumName(dynamic enumItem) {
    final String name = '$enumItem';
    final int index = name.indexOf('.');
    return index == -1 ? name : name.substring(index + 1);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: _handleKeyEvent,
      child: AnimatedBuilder(
        animation: _focusNode,
        builder: (BuildContext context, Widget child) {
          if (!_focusNode.hasFocus) {
            return GestureDetector(
              onTap: () {
                FocusScope.of(context).requestFocus(_focusNode);
              },
              child: Text('Tap to focus', style: textTheme.display1),
            );
          }

          if (_event == null) {
            return Text('Press a key', style: textTheme.display1);
          }

          final RawKeyEventData data = _event.data;
          final String modifierList = data.modifiersPressed.keys.map<String>(_getEnumName).join(', ').replaceAll('Modifier', '');
          final List<Widget> dataText = <Widget>[
            Text('${_event.runtimeType}'),
            Text('modifiers set: $modifierList'),
          ];
          if (data is RawKeyEventDataAndroid) {
            const int combiningCharacterMask = 0x7fffffff;
            final String codePointChar = String.fromCharCode(combiningCharacterMask & data.codePoint);
            dataText.add(Text('codePoint: ${data.codePoint} (${_asHex(data.codePoint)}: $codePointChar)'));
            final String plainCodePointChar = String.fromCharCode(combiningCharacterMask & data.plainCodePoint);
            dataText.add(Text('plainCodePoint: ${data.plainCodePoint} (${_asHex(data.plainCodePoint)}: $plainCodePointChar)'));
            dataText.add(Text('keyCode: ${data.keyCode} (${_asHex(data.keyCode)})'));
            dataText.add(Text('scanCode: ${data.scanCode} (${_asHex(data.scanCode)})'));
            dataText.add(Text('metaState: ${data.metaState} (${_asHex(data.metaState)})'));
            dataText.add(Text('flags: ${data.flags} (${_asHex(data.flags)})'));
          } else if (data is RawKeyEventDataFuchsia) {
            dataText.add(Text('codePoint: ${data.codePoint} (${_asHex(data.codePoint)})'));
            dataText.add(Text('hidUsage: ${data.hidUsage} (${_asHex(data.hidUsage)})'));
            dataText.add(Text('modifiers: ${data.modifiers} (${_asHex(data.modifiers)})'));
          } else if (data is RawKeyEventDataMacOs) {
            dataText.add(Text('keyCode: ${data.keyCode} (${_asHex(data.keyCode)})'));
            dataText.add(Text('characters: ${data.characters}'));
            dataText.add(Text('charactersIgnoringModifiers: ${data.charactersIgnoringModifiers}'));
            dataText.add(Text('modifiers: ${data.modifiers} (${_asHex(data.modifiers)})'));
          } else if (data is RawKeyEventDataLinux) {
            dataText.add(Text('keyCode: ${data.keyCode} (${_asHex(data.keyCode)})'));
            dataText.add(Text('scanCode: ${data.scanCode}'));
            dataText.add(Text('codePoint: ${data.codePoint}'));
            dataText.add(Text('modifiers: ${data.modifiers} (${_asHex(data.modifiers)})'));
          }
          dataText.add(Text('logical: ${_event.logicalKey}'));
          dataText.add(Text('physical: ${_event.physicalKey}'));
          if (_event.character != null) {
            dataText.add(Text('character: ${_event.character}'));
          }
          for (ModifierKey modifier in data.modifiersPressed.keys) {
            for (KeyboardSide side in KeyboardSide.values) {
              if (data.isModifierPressed(modifier, side: side)) {
                dataText.add(
                  Text('${_getEnumName(side)} ${_getEnumName(modifier).replaceAll('Modifier', '')} pressed'),
                );
              }
            }
          }
          return DefaultTextStyle(
            style: textTheme.headline,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: dataText,
            ),
          );
        },
      ),
    );
  }
}
