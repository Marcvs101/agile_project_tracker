// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../painting/mocks_for_image_cache.dart';

List<int> selectedTabs;

void main() {
  setUp(() {
    selectedTabs = <int>[];
  });

  testWidgets('Last tab gets focus', (WidgetTester tester) async {
    // 2 nodes for 2 tabs
    final List<FocusNode> focusNodes = <FocusNode>[FocusNode(), FocusNode()];

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: CupertinoTabScaffold(
            tabBar: _buildTabBar(),
            tabBuilder: (BuildContext context, int index) {
              return TextField(
                focusNode: focusNodes[index],
                autofocus: true,
              );
            },
          ),
        ),
      ),
    );

    expect(focusNodes[0].hasFocus, isTrue);

    await tester.tap(find.text('Tab 2'));
    await tester.pump();

    expect(focusNodes[0].hasFocus, isFalse);
    expect(focusNodes[1].hasFocus, isTrue);

    await tester.tap(find.text('Tab 1'));
    await tester.pump();

    expect(focusNodes[0].hasFocus, isTrue);
    expect(focusNodes[1].hasFocus, isFalse);
  });

  testWidgets('Do not affect focus order in the route', (WidgetTester tester) async {
    final List<FocusNode> focusNodes = <FocusNode>[
      FocusNode(), FocusNode(), FocusNode(), FocusNode(),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: CupertinoTabScaffold(
            tabBar: _buildTabBar(),
            tabBuilder: (BuildContext context, int index) {
              return Column(
                children: <Widget>[
                  TextField(
                    focusNode: focusNodes[index * 2],
                    decoration: const InputDecoration(
                      hintText: 'TextField 1',
                    ),
                  ),
                  TextField(
                    focusNode: focusNodes[index * 2 + 1],
                    decoration: const InputDecoration(
                      hintText: 'TextField 2',
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    expect(
      focusNodes.any((FocusNode node) => node.hasFocus),
      isFalse,
    );

    await tester.tap(find.widgetWithText(TextField, 'TextField 2'));

    expect(
      focusNodes.indexOf(focusNodes.singleWhere((FocusNode node) => node.hasFocus)),
      1,
    );

    await tester.tap(find.text('Tab 2'));
    await tester.pump();

    await tester.tap(find.widgetWithText(TextField, 'TextField 1'));

    expect(
      focusNodes.indexOf(focusNodes.singleWhere((FocusNode node) => node.hasFocus)),
      2,
    );

    await tester.tap(find.text('Tab 1'));
    await tester.pump();

    // Upon going back to tab 1, the item it tab 1 that previously had the focus
    // (TextField 2) gets it back.
    expect(
      focusNodes.indexOf(focusNodes.singleWhere((FocusNode node) => node.hasFocus)),
      1,
    );
  });

  testWidgets('Tab bar respects themes', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoTabScaffold(
          tabBar: _buildTabBar(),
          tabBuilder: (BuildContext context, int index) {
            return const Placeholder();
          },
        ),
      ),
    );

    BoxDecoration tabDecoration = tester.widget<DecoratedBox>(find.descendant(
      of: find.byType(CupertinoTabBar),
      matching: find.byType(DecoratedBox),
    )).decoration;

    expect(tabDecoration.color, const Color(0xCCF8F8F8));

    await tester.tap(find.text('Tab 2'));
    await tester.pump();

    // Pump again but with dark theme.
    await tester.pumpWidget(
      CupertinoApp(
        theme: const CupertinoThemeData(
          brightness: Brightness.dark,
          primaryColor: CupertinoColors.destructiveRed,
        ),
        home: CupertinoTabScaffold(
          tabBar: _buildTabBar(),
          tabBuilder: (BuildContext context, int index) {
            return const Placeholder();
          },
        ),
      ),
    );

    tabDecoration = tester.widget<DecoratedBox>(find.descendant(
      of: find.byType(CupertinoTabBar),
      matching: find.byType(DecoratedBox),
    )).decoration;

    expect(tabDecoration.color, const Color(0xB7212121));

    final RichText tab1 = tester.widget(find.descendant(
      of: find.text('Tab 1'),
      matching: find.byType(RichText),
    ));
    // Tab 2 should still be selected after changing theme.
    expect(tab1.text.style.color, CupertinoColors.inactiveGray);
    final RichText tab2 = tester.widget(find.descendant(
      of: find.text('Tab 2'),
      matching: find.byType(RichText),
    ));
    expect(tab2.text.style.color, CupertinoColors.destructiveRed);
  });

  testWidgets('Does not lose state when focusing on text input', (WidgetTester tester) async {
    // Regression testing for https://github.com/flutter/flutter/issues/28457.

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          viewInsets:  EdgeInsets.only(bottom: 0),
        ),
        child: MaterialApp(
          home: Material(
            child: CupertinoTabScaffold(
              tabBar: _buildTabBar(),
              tabBuilder: (BuildContext context, int index) {
                return const TextField();
              },
            ),
          ),
        ),
      ),
    );

    final EditableTextState editableState = tester.state<EditableTextState>(find.byType(EditableText));

    await tester.enterText(find.byType(TextField), "don't lose me");

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          viewInsets:  EdgeInsets.only(bottom: 100),
        ),
        child: MaterialApp(
          home: Material(
            child: CupertinoTabScaffold(
              tabBar: _buildTabBar(),
              tabBuilder: (BuildContext context, int index) {
                return const TextField();
              },
            ),
          ),
        ),
      ),
    );

    // The exact same state instance is still there.
    expect(tester.state<EditableTextState>(find.byType(EditableText)), editableState);
    expect(find.text("don't lose me"), findsOneWidget);
  });
}

CupertinoTabBar _buildTabBar({ int selectedTab = 0 }) {
  return CupertinoTabBar(
    items: const <BottomNavigationBarItem>[
      BottomNavigationBarItem(
        icon: ImageIcon(TestImageProvider(24, 24)),
        title: Text('Tab 1'),
      ),
      BottomNavigationBarItem(
        icon: ImageIcon(TestImageProvider(24, 24)),
        title: Text('Tab 2'),
      ),
    ],
    currentIndex: selectedTab,
    onTap: (int newTab) => selectedTabs.add(newTab),
  );
}
