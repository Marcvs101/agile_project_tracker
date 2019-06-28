// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matcher/matcher.dart';

import '../widgets/semantics_tester.dart';

MaterialApp _appWithAlertDialog(WidgetTester tester, AlertDialog dialog, { ThemeData theme }) {
  return MaterialApp(
      theme: theme,
      home: Material(
        child: Builder(
          builder: (BuildContext context) {
            return Center(
              child: RaisedButton(
                child: const Text('X'),
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return dialog;
                    },
                  );
                },
              ),
            );
          }
        ),
      ),
  );
}

Material _getMaterialFromDialog(WidgetTester tester) {
  return tester.widget<Material>(find.descendant(of: find.byType(AlertDialog), matching: find.byType(Material)));
}

RenderParagraph _getTextRenderObjectFromDialog(WidgetTester tester, String text) {
  return tester.element<StatelessElement>(find.descendant(of: find.byType(AlertDialog), matching: find.text(text))).renderObject;
}

const ShapeBorder _defaultDialogShape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(2.0)));

void main() {
  testWidgets('Dialog is scrollable', (WidgetTester tester) async {
    bool didPressOk = false;
    final AlertDialog dialog = AlertDialog(
      content: Container(
        height: 5000.0,
        width: 300.0,
        color: Colors.green[500],
      ),
      actions: <Widget>[
        FlatButton(
            onPressed: () {
              didPressOk = true;
            },
            child: const Text('OK'),
        ),
      ],
    );
    await tester.pumpWidget(_appWithAlertDialog(tester, dialog));

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    expect(didPressOk, false);
    await tester.tap(find.text('OK'));
    expect(didPressOk, true);
  });

  testWidgets('Dialog background color from AlertDialog', (WidgetTester tester) async {
    const Color customColor = Colors.pink;
    const AlertDialog dialog = AlertDialog(
      backgroundColor: customColor,
      actions: <Widget>[ ],
    );
    await tester.pumpWidget(_appWithAlertDialog(tester, dialog, theme: ThemeData(brightness: Brightness.dark)));

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final Material materialWidget = _getMaterialFromDialog(tester);
    expect(materialWidget.color, customColor);
  });

  testWidgets('Dialog Defaults', (WidgetTester tester) async {
    const AlertDialog dialog = AlertDialog(
      title: Text('Title'),
      content: Text('Y'),
      actions: <Widget>[ ],
    );
    await tester.pumpWidget(_appWithAlertDialog(tester, dialog, theme: ThemeData(brightness: Brightness.dark)));

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final Material materialWidget = _getMaterialFromDialog(tester);
    expect(materialWidget.color, Colors.grey[800]);
    expect(materialWidget.shape, _defaultDialogShape);
    expect(materialWidget.elevation, 24.0);
  });

  testWidgets('Custom dialog elevation', (WidgetTester tester) async {
    const double customElevation = 12.0;
    const AlertDialog dialog = AlertDialog(
      actions: <Widget>[ ],
      elevation: customElevation,
    );
    await tester.pumpWidget(_appWithAlertDialog(tester, dialog));

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final Material materialWidget = _getMaterialFromDialog(tester);
    expect(materialWidget.elevation, customElevation);
  });

  testWidgets('Custom Title Text Style', (WidgetTester tester) async {
    const String titleText = 'Title';
    const TextStyle titleTextStyle = TextStyle(color: Colors.pink);
    const AlertDialog dialog = AlertDialog(
      title: Text(titleText),
      titleTextStyle: titleTextStyle,
      actions: <Widget>[ ],
    );
    await tester.pumpWidget(_appWithAlertDialog(tester, dialog));

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final RenderParagraph title = _getTextRenderObjectFromDialog(tester, titleText);
    expect(title.text.style, titleTextStyle);
  });

  testWidgets('Custom Content Text Style', (WidgetTester tester) async {
    const String contentText = 'Content';
    const TextStyle contentTextStyle = TextStyle(color: Colors.pink);
    const AlertDialog dialog = AlertDialog(
      content: Text(contentText),
      contentTextStyle: contentTextStyle,
      actions: <Widget>[ ],
    );
    await tester.pumpWidget(_appWithAlertDialog(tester, dialog));

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final RenderParagraph content = _getTextRenderObjectFromDialog(tester, contentText);
    expect(content.text.style, contentTextStyle);
  });

  testWidgets('Custom dialog shape', (WidgetTester tester) async {
    const RoundedRectangleBorder customBorder =
      RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16.0)));
    const AlertDialog dialog = AlertDialog(
      actions: <Widget>[ ],
      shape: customBorder,
    );
    await tester.pumpWidget(_appWithAlertDialog(tester, dialog));

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final Material materialWidget = _getMaterialFromDialog(tester);
    expect(materialWidget.shape, customBorder);
  });

  testWidgets('Null dialog shape', (WidgetTester tester) async {
    const AlertDialog dialog = AlertDialog(
      actions: <Widget>[ ],
      shape: null,
    );
    await tester.pumpWidget(_appWithAlertDialog(tester, dialog));

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final Material materialWidget = _getMaterialFromDialog(tester);
    expect(materialWidget.shape, _defaultDialogShape);
  });

  testWidgets('Rectangular dialog shape', (WidgetTester tester) async {
    const ShapeBorder customBorder = Border();
    const AlertDialog dialog = AlertDialog(
      actions: <Widget>[ ],
      shape: customBorder,
    );
    await tester.pumpWidget(_appWithAlertDialog(tester, dialog));

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final Material materialWidget = _getMaterialFromDialog(tester);
    expect(materialWidget.shape, customBorder);
  });

  testWidgets('Simple dialog control test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: Center(
            child: RaisedButton(
              onPressed: null,
              child: Text('Go'),
            ),
          ),
        ),
      ),
    );

    final BuildContext context = tester.element(find.text('Go'));

    final Future<int> result = showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Title'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, 42);
              },
              child: const Text('First option'),
            ),
            const SimpleDialogOption(
              child: Text('Second option'),
            ),
          ],
        );
      },
    );

    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Title'), findsOneWidget);
    await tester.tap(find.text('First option'));

    expect(await result, equals(42));
  });

  testWidgets('Barrier dismissible', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: Center(
            child: RaisedButton(
              onPressed: null,
              child: Text('Go'),
            ),
          ),
        ),
      ),
    );

    final BuildContext context = tester.element(find.text('Go'));

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          width: 100.0,
          height: 100.0,
          alignment: Alignment.center,
          child: const Text('Dialog1'),
        );
      },
    );

    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Dialog1'), findsOneWidget);

    // Tap on the barrier.
    await tester.tapAt(const Offset(10.0, 10.0));

    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Dialog1'), findsNothing);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Container(
          width: 100.0,
          height: 100.0,
          alignment: Alignment.center,
          child: const Text('Dialog2'),
        );
      },
    );

    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Dialog2'), findsOneWidget);

    // Tap on the barrier, which shouldn't do anything this time.
    await tester.tapAt(const Offset(10.0, 10.0));

    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Dialog2'), findsOneWidget);

  });

  testWidgets('Dialog hides underlying semantics tree', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    const String buttonText = 'A button covered by dialog overlay';
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: Center(
            child: RaisedButton(
              onPressed: null,
              child: Text(buttonText),
            ),
          ),
        ),
      ),
    );

    expect(semantics, includesNodeWith(label: buttonText));

    final BuildContext context = tester.element(find.text(buttonText));

    const String alertText = 'A button in an overlay alert';
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return const AlertDialog(title: Text(alertText));
      },
    );

    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(semantics, includesNodeWith(label: alertText));
    expect(semantics, isNot(includesNodeWith(label: buttonText)));

    semantics.dispose();
  });

  testWidgets('Dialogs removes MediaQuery padding and view insets', (WidgetTester tester) async {
    BuildContext outerContext;
    BuildContext routeContext;
    BuildContext dialogContext;

    await tester.pumpWidget(Localizations(
      locale: const Locale('en', 'US'),
      delegates: const <LocalizationsDelegate<dynamic>>[
        DefaultWidgetsLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
      ],
      child: MediaQuery(
        data: const MediaQueryData(
          padding: EdgeInsets.all(50.0),
          viewInsets: EdgeInsets.only(left: 25.0, bottom: 75.0),
        ),
        child: Navigator(
          onGenerateRoute: (_) {
            return PageRouteBuilder<void>(
              pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
                outerContext = context;
                return Container();
              },
            );
          },
        ),
      ),
    ));

    showDialog<void>(
      context: outerContext,
      barrierDismissible: false,
      builder: (BuildContext context) {
        routeContext = context;
        return Dialog(
          child: Builder(
            builder: (BuildContext context) {
              dialogContext = context;
              return const Placeholder();
            },
          ),
        );
      },
    );

    await tester.pump();

    expect(MediaQuery.of(outerContext).padding, const EdgeInsets.all(50.0));
    expect(MediaQuery.of(routeContext).padding, EdgeInsets.zero);
    expect(MediaQuery.of(dialogContext).padding, EdgeInsets.zero);
    expect(MediaQuery.of(outerContext).viewInsets, const EdgeInsets.only(left: 25.0, bottom: 75.0));
    expect(MediaQuery.of(routeContext).viewInsets, const EdgeInsets.only(left: 25.0, bottom: 75.0));
    expect(MediaQuery.of(dialogContext).viewInsets, EdgeInsets.zero);
  });

  testWidgets('Dialog widget insets by viewInsets', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(
          viewInsets: EdgeInsets.fromLTRB(10.0, 20.0, 30.0, 40.0),
        ),
        child: Dialog(
          child: Placeholder(),
        ),
      ),
    );
    expect(
      tester.getRect(find.byType(Placeholder)),
      Rect.fromLTRB(10.0 + 40.0, 20.0 + 24.0, 800.0 - (40.0 + 30.0), 600.0 - (24.0 + 40.0)),
    );
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(
          viewInsets: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
        ),
        child: Dialog(
          child: Placeholder(),
        ),
      ),
    );
    expect( // no change because this is an animation
      tester.getRect(find.byType(Placeholder)),
      Rect.fromLTRB(10.0 + 40.0, 20.0 + 24.0, 800.0 - (40.0 + 30.0), 600.0 - (24.0 + 40.0)),
    );
    await tester.pump(const Duration(seconds: 1));
    expect( // animation finished
      tester.getRect(find.byType(Placeholder)),
      Rect.fromLTRB(40.0, 24.0, 800.0 - 40.0, 600.0 - 24.0),
    );
  });

  testWidgets('Dialog widget contains route semantics from title', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Builder(
            builder: (BuildContext context) {
              return Center(
                child: RaisedButton(
                  child: const Text('X'),
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (BuildContext context) {
                        return const AlertDialog(
                          title: Text('Title'),
                          content: Text('Y'),
                          actions: <Widget>[],
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(semantics, isNot(includesNodeWith(
        label: 'Title',
        flags: <SemanticsFlag>[SemanticsFlag.namesRoute],
    )));

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    expect(semantics, includesNodeWith(
      label: 'Title',
      flags: <SemanticsFlag>[SemanticsFlag.namesRoute],
    ));

    semantics.dispose();
  });

  testWidgets('Dismissable.confirmDismiss defers to an AlertDialog', (WidgetTester tester) async {
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
    final List<int> dismissedItems = <int>[];

    // Dismiss is confirmed IFF confirmDismiss() returns true.
    Future<bool> confirmDismiss (DismissDirection dismissDirection) {
      return showDialog<bool>(
        context: _scaffoldKey.currentContext,
        barrierDismissible: true, // showDialog() returns null if tapped outside the dialog
        builder: (BuildContext context) {
          return AlertDialog(
            actions: <Widget>[
              FlatButton(
                child: const Text('TRUE'),
                onPressed: () {
                  Navigator.pop(context, true); // showDialog() returns true
                },
              ),
              FlatButton(
                child: const Text('FALSE'),
                onPressed: () {
                  Navigator.pop(context, false); // showDialog() returns false
                },
              ),
            ],
          );
        },
      );
    }

    Widget buildDismissibleItem(int item, StateSetter setState) {
      return Dismissible(
        key: ValueKey<int>(item),
        confirmDismiss: confirmDismiss,
        onDismissed: (DismissDirection direction) {
          setState(() {
            expect(dismissedItems.contains(item), isFalse);
            dismissedItems.add(item);
          });
        },
        child: SizedBox(
          height: 100.0,
          child: Text(item.toString()),
        ),
      );
    }

    Widget buildFrame() {
      return MaterialApp(
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Scaffold(
              key: _scaffoldKey,
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  itemExtent: 100.0,
                  children: <int>[0, 1, 2, 3, 4]
                    .where((int i) => !dismissedItems.contains(i))
                    .map<Widget>((int item) => buildDismissibleItem(item, setState)).toList(),
                ),
              ),
            );
          },
        ),
      );
    }

    Future<void> dismissItem(WidgetTester tester, int item) async {
      await tester.fling(find.text(item.toString()), const Offset(300.0, 0.0), 1000.0); // fling to the right
      await tester.pump(); // start the slide
      await tester.pump(const Duration(seconds: 1)); // finish the slide and start shrinking...
      await tester.pump(); // first frame of shrinking animation
      await tester.pump(const Duration(seconds: 1)); // finish the shrinking and call the callback...
      await tester.pump(); // rebuild after the callback removes the entry
    }

    // Dismiss item 0 is confirmed via the AlertDialog
    await tester.pumpWidget(buildFrame());
    expect(dismissedItems, isEmpty);
    await dismissItem(tester, 0); // Causes the AlertDialog to appear per confirmDismiss
    await tester.pumpAndSettle();
    await tester.tap(find.text('TRUE')); // AlertDialog action
    await tester.pumpAndSettle();
    expect(find.text('TRUE'), findsNothing); // Dialog was dismissed
    expect(find.text('FALSE'), findsNothing);
    expect(dismissedItems, <int>[0]);
    expect(find.text('0'), findsNothing);

    // Dismiss item 1 is not confirmed via the AlertDialog
    await tester.pumpWidget(buildFrame());
    expect(dismissedItems, <int>[0]);
    await dismissItem(tester, 1); // Causes the AlertDialog to appear per confirmDismiss
    await tester.pumpAndSettle();
    await tester.tap(find.text('FALSE')); // AlertDialog action
    await tester.pumpAndSettle();
    expect(find.text('TRUE'), findsNothing); // Dialog was dismissed
    expect(find.text('FALSE'), findsNothing);
    expect(dismissedItems, <int>[0]);
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);

    // Dismiss item 1 is not confirmed via the AlertDialog
    await tester.pumpWidget(buildFrame());
    expect(dismissedItems, <int>[0]);
    await dismissItem(tester, 1); // Causes the AlertDialog to appear per confirmDismiss
    await tester.pumpAndSettle();
    expect(find.text('FALSE'), findsOneWidget);
    expect(find.text('TRUE'), findsOneWidget);
    await tester.tapAt(Offset.zero); // Tap outside of the AlertDialog
    await tester.pumpAndSettle();
    expect(dismissedItems, <int>[0]);
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('TRUE'), findsNothing); // Dialog was dismissed
    expect(find.text('FALSE'), findsNothing);

    // Dismiss item 1 is confirmed via the AlertDialog
    await tester.pumpWidget(buildFrame());
    expect(dismissedItems, <int>[0]);
    await dismissItem(tester, 1); // Causes the AlertDialog to appear per confirmDismiss
    await tester.pumpAndSettle();
    await tester.tap(find.text('TRUE')); // AlertDialog action
    await tester.pumpAndSettle();
    expect(find.text('TRUE'), findsNothing); // Dialog was dismissed
    expect(find.text('FALSE'), findsNothing);
    expect(dismissedItems, <int>[0, 1]);
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsNothing);
  });

  // Regression test for https://github.com/flutter/flutter/issues/28505.
  testWidgets('showDialog only gets Theme from context on the first call', (WidgetTester tester) async {
    Widget buildFrame(Key builderKey) {
      return MaterialApp(
        home: Center(
          child: Builder(
            key: builderKey,
            builder: (BuildContext outerContext) {
              return RaisedButton(
                onPressed: () {
                  showDialog<void>(
                    context: outerContext,
                    builder: (BuildContext innerContext) {
                      return const AlertDialog(title: Text('Title'));
                    },
                  );
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      );
    }

    await tester.pumpWidget(buildFrame(UniqueKey()));

    // Open the dialog.
    await tester.tap(find.byType(RaisedButton));
    await tester.pumpAndSettle();

    // Force the Builder to be recreated (new key) which causes outerContext to
    // be deactivated. If showDialog()'s implementation were to refer to
    // outerContext again, it would crash.
    await tester.pumpWidget(buildFrame(UniqueKey()));
    await tester.pump();
  });
}
