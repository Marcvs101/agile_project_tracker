// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import '../painting/mocks_for_image_cache.dart';

/// Integration tests testing both [CupertinoPageScaffold] and [CupertinoTabScaffold].
void main() {
  testWidgets('Contents are behind translucent bar', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: CupertinoPageScaffold(
          // Default nav bar is translucent.
          navigationBar: CupertinoNavigationBar(
            middle: Text('Title'),
          ),
          child: Center(),
        ),
      ),
    );

    expect(tester.getTopLeft(find.byType(Center)), const Offset(0.0, 0.0));
  });

testWidgets('Opaque bar pushes contents down', (WidgetTester tester) async {
    BuildContext childContext;
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(viewInsets: EdgeInsets.only(top: 20)),
        child: CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(
            middle: Text('Opaque'),
            backgroundColor: Color(0xFFF8F8F8),
          ),
          child: Builder(
            builder: (BuildContext context) {
              childContext = context;
              return Container();
            },
          ),
        ),
      ),
    ));

    expect(MediaQuery.of(childContext).padding.top, 0);
    // The top of the [Container] is 44 px from the top of the screen because
    // it's pushed down by the opaque navigation bar whose height is 44 px,
    // and the 20 px [MediaQuery] top padding is fully absorbed by the navigation bar.
    expect(tester.getRect(find.byType(Container)), Rect.fromLTRB(0, 44, 800, 600));
  });

  testWidgets('Contents padding from viewInsets', (WidgetTester tester) async {
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(viewInsets: EdgeInsets.only(bottom: 100.0)),
        child: CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(
            middle: Text('Opaque'),
            backgroundColor: Color(0xFFF8F8F8),
          ),
          child: Container(),
        ),
      ),
    ));

    expect(tester.getSize(find.byType(Container)).height, 600.0 - 44.0 - 100.0);

    BuildContext childContext;
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(viewInsets: EdgeInsets.only(bottom: 100.0)),
        child: CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(
            middle: Text('Transparent'),
          ),
          child: Builder(
            builder: (BuildContext context) {
              childContext = context;
              return Container();
            },
          ),
        ),
      ),
    ));

    expect(tester.getSize(find.byType(Container)).height, 600.0 - 100.0);
    // The shouldn't see a media query view inset because it was consumed by
    // the scaffold.
    expect(MediaQuery.of(childContext).viewInsets.bottom, 0);

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(viewInsets: EdgeInsets.only(bottom: 100.0)),
        child: CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(
            middle: Text('Title'),
          ),
          resizeToAvoidBottomInset: false,
          child: Container(),
        ),
      ),
    ));

    expect(tester.getSize(find.byType(Container)).height, 600.0);
  });

  testWidgets('Contents are between opaque bars', (WidgetTester tester) async {
    const Center page1Center = Center();

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoTabScaffold(
          tabBar: CupertinoTabBar(
            backgroundColor: CupertinoColors.white,
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
          ),
          tabBuilder: (BuildContext context, int index) {
            return index == 0
                ? const CupertinoPageScaffold(
                  navigationBar: CupertinoNavigationBar(
                    backgroundColor: CupertinoColors.white,
                    middle: Text('Title'),
                  ),
                  child: page1Center,
                )
                : Stack();
          },
        ),
      ),
    );

    expect(tester.getSize(find.byWidget(page1Center)).height, 600.0 - 44.0 - 50.0);
  });

  testWidgets('Contents have automatic sliver padding between translucent bars', (WidgetTester tester) async {
    final Container content = Container(height: 600.0, width: 600.0);

    await tester.pumpWidget(
      CupertinoApp(
        home: MediaQuery(
          data: const MediaQueryData(
            padding: EdgeInsets.symmetric(vertical: 20.0),
          ),
          child: CupertinoTabScaffold(
            tabBar: CupertinoTabBar(
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
            ),
            tabBuilder: (BuildContext context, int index) {
              return index == 0
                  ? CupertinoPageScaffold(
                    navigationBar: const CupertinoNavigationBar(
                      middle: Text('Title'),
                    ),
                    child: ListView(
                      children: <Widget>[
                        content,
                      ],
                    ),
                  )
                  : Stack();
            },
          ),
        ),
      ),
    );

    // List content automatically padded by nav bar and top media query padding.
    expect(tester.getTopLeft(find.byWidget(content)).dy, 20.0 + 44.0);

    // Overscroll to the bottom.
    await tester.drag(find.byWidget(content), const Offset(0.0, -400.0));
    // Let it bounce back.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // List content automatically padded by tab bar and bottom media query padding.
    expect(tester.getBottomLeft(find.byWidget(content)).dy, 600 - 20.0 - 50.0);
  });

  testWidgets('iOS independent tab navigation', (WidgetTester tester) async {
    // A full on iOS information architecture app with 2 tabs, and 2 pages
    // in each with independent navigation states.
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoTabScaffold(
          tabBar: CupertinoTabBar(
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
          ),
          tabBuilder: (BuildContext context, int index) {
            // For 1-indexed readability.
            ++index;
            return CupertinoTabView(
              builder: (BuildContext context) {
                return CupertinoPageScaffold(
                  navigationBar: CupertinoNavigationBar(
                    middle: Text('Page 1 of tab $index'),
                  ),
                  child: Center(
                    child: CupertinoButton(
                      child: const Text('Next'),
                      onPressed: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute<void>(
                            builder: (BuildContext context) {
                              return CupertinoPageScaffold(
                                navigationBar: CupertinoNavigationBar(
                                  middle: Text('Page 2 of tab $index'),
                                ),
                                child: Center(
                                  child: CupertinoButton(
                                    child: const Text('Back'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );

    expect(find.text('Page 1 of tab 1'), findsOneWidget);
    expect(find.text('Page 1 of tab 2'), findsNothing); // Lazy building so not built yet.

    await tester.tap(find.text('Tab 2'));
    await tester.pump();

    expect(find.text('Page 1 of tab 1'), findsNothing); // It's offstage now.
    expect(find.text('Page 1 of tab 1', skipOffstage: false), findsOneWidget);
    expect(find.text('Page 1 of tab 2'), findsOneWidget);

    // Navigate in tab 2.
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Page 2 of tab 2'), isOnstage);
    expect(find.text('Page 1 of tab 1', skipOffstage: false), isOffstage);

    await tester.tap(find.text('Tab 1'));
    await tester.pump();

    // Independent navigation stacks.
    expect(find.text('Page 1 of tab 1'), isOnstage);
    expect(find.text('Page 2 of tab 2', skipOffstage: false), isOffstage);

    // Navigate in tab 1.
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Page 2 of tab 1'), isOnstage);
    expect(find.text('Page 2 of tab 2', skipOffstage: false), isOffstage);

    await tester.tap(find.text('Tab 2'));
    await tester.pump();

    expect(find.text('Page 2 of tab 2'), isOnstage);
    expect(find.text('Page 2 of tab 1', skipOffstage: false), isOffstage);

    // Pop in tab 2
    await tester.tap(find.text('Back'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Page 1 of tab 2'), isOnstage);
    expect(find.text('Page 2 of tab 1', skipOffstage: false), isOffstage);
  });

  testWidgets('Decorated with white background by default', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: CupertinoPageScaffold(
          child: Center(),
        ),
      ),
    );

    final DecoratedBox decoratedBox = tester.widgetList(find.byType(DecoratedBox)).elementAt(1);
    expect(decoratedBox.decoration.runtimeType, BoxDecoration);

    final BoxDecoration decoration = decoratedBox.decoration;
    expect(decoration.color, CupertinoColors.white);
  });

  testWidgets('Overrides background color', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: CupertinoPageScaffold(
          child: Center(),
          backgroundColor: Color(0xFF010203),
        ),
      ),
    );

    final DecoratedBox decoratedBox = tester.widgetList(find.byType(DecoratedBox)).elementAt(1);
    expect(decoratedBox.decoration.runtimeType, BoxDecoration);

    final BoxDecoration decoration = decoratedBox.decoration;
    expect(decoration.color, const Color(0xFF010203));
  });

  testWidgets('Lists in CupertinoPageScaffold scroll to the top when status bar tapped', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        builder: (BuildContext context, Widget child) {
          // Acts as a 20px status bar at the root of the app.
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(padding: const EdgeInsets.only(top: 20)),
            child: child,
          );
        },
        home: CupertinoPageScaffold(
          // Default nav bar is translucent.
          navigationBar: const CupertinoNavigationBar(
            middle: Text('Title'),
          ),
          child: ListView.builder(
            itemExtent: 50,
            itemBuilder: (BuildContext context, int index) => Text(index.toString()),
          ),
        ),
      ),
    );
    // Top media query padding 20 + translucent nav bar 44.
    expect(tester.getTopLeft(find.text('0')).dy, 64);
    expect(tester.getTopLeft(find.text('6')).dy, 364);

    await tester.fling(
      find.text('5'), // Find some random text on the screen.
      const Offset(0, -200),
      20,
    );

    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.text('6')).dy, moreOrLessEquals(166.833, epsilon: 0.1));
    expect(tester.getTopLeft(find.text('12')).dy, moreOrLessEquals(466.8333333333334, epsilon: 0.1));

    // The media query top padding is 20. Tapping at 20 should do nothing.
    await tester.tapAt(const Offset(400, 20));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('6')).dy, moreOrLessEquals(166.833, epsilon: 0.1));
    expect(tester.getTopLeft(find.text('12')).dy, moreOrLessEquals(466.8333333333334, epsilon: 0.1));

    // Tap 1 pixel higher.
    await tester.tapAt(const Offset(400, 19));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.getTopLeft(find.text('0')).dy, 64);
    expect(tester.getTopLeft(find.text('6')).dy, 364);
    expect(find.text('12'), findsNothing);
  });
}
