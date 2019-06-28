// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';
import '../widgets/test_border.dart' show TestBorder;

class NotifyMaterial extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    LayoutChangedNotification().dispatch(context);
    return Container();
  }
}

Widget buildMaterial({
  double elevation = 0.0,
  Color shadowColor = const Color(0xFF00FF00),
}) {
  return Center(
    child: SizedBox(
      height: 100.0,
      width: 100.0,
      child: Material(
        shadowColor: shadowColor,
        elevation: elevation,
        shape: const CircleBorder(),
      ),
    ),
  );
}

RenderPhysicalShape getShadow(WidgetTester tester) {
  return tester.renderObject(find.byType(PhysicalShape));
}

class PaintRecorder extends CustomPainter {
  PaintRecorder(this.log);

  final List<Size> log;

  @override
  void paint(Canvas canvas, Size size) {
    log.add(size);
    final Paint paint = Paint()..color = const Color(0xFF0000FF);
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(PaintRecorder oldDelegate) => false;
}

void main() {
  testWidgets('default Material debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const Material().debugFillProperties(builder);

    final List<String> description = builder.properties
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.toString())
      .toList();

    expect(description, <String>['type: canvas']);
  });

  testWidgets('Material implements debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const Material(
      type: MaterialType.canvas,
      color: Color(0xFFFFFFFF),
      textStyle: TextStyle(color: Color(0xff00ff00)),
      borderRadius: BorderRadiusDirectional.all(Radius.circular(10)),
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.toString())
      .toList();

    expect(description, <String>[
      'type: canvas',
      'color: Color(0xffffffff)',
      'textStyle.inherit: true',
      'textStyle.color: Color(0xff00ff00)',
      'borderRadius: BorderRadiusDirectional.circular(10.0)',
    ]);
  });

  testWidgets('LayoutChangedNotification test', (WidgetTester tester) async {
    await tester.pumpWidget(
      Material(
        child: NotifyMaterial(),
      ),
    );
  });

  testWidgets('ListView scroll does not repaint', (WidgetTester tester) async {
    final List<Size> log = <Size>[];

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: <Widget>[
            SizedBox(
              width: 150.0,
              height: 150.0,
              child: CustomPaint(
                painter: PaintRecorder(log),
              ),
            ),
            Expanded(
              child: Material(
                child: Column(
                  children: <Widget>[
                    Expanded(
                      child: ListView(
                        children: <Widget>[
                          Container(
                            height: 2000.0,
                            color: const Color(0xFF00FF00),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 100.0,
                      height: 100.0,
                      child: CustomPaint(
                        painter: PaintRecorder(log),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // We paint twice because we have two CustomPaint widgets in the tree above
    // to test repainting both inside and outside the Material widget.
    expect(log, equals(<Size>[
      const Size(150.0, 150.0),
      const Size(100.0, 100.0),
    ]));
    log.clear();

    await tester.drag(find.byType(ListView), const Offset(0.0, -300.0));
    await tester.pump();

    expect(log, isEmpty);
  });

  testWidgets('Shadows animate smoothly', (WidgetTester tester) async {
    // This code verifies that the PhysicalModel's elevation animates over
    // a kThemeChangeDuration time interval.

    await tester.pumpWidget(buildMaterial(elevation: 0.0));
    final RenderPhysicalShape modelA = getShadow(tester);
    expect(modelA.elevation, equals(0.0));

    await tester.pumpWidget(buildMaterial(elevation: 9.0));
    final RenderPhysicalShape modelB = getShadow(tester);
    expect(modelB.elevation, equals(0.0));

    await tester.pump(const Duration(milliseconds: 1));
    final RenderPhysicalShape modelC = getShadow(tester);
    expect(modelC.elevation, closeTo(0.0, 0.001));

    await tester.pump(kThemeChangeDuration ~/ 2);
    final RenderPhysicalShape modelD = getShadow(tester);
    expect(modelD.elevation, isNot(closeTo(0.0, 0.001)));

    await tester.pump(kThemeChangeDuration);
    final RenderPhysicalShape modelE = getShadow(tester);
    expect(modelE.elevation, equals(9.0));
  });

  testWidgets('Shadow colors animate smoothly', (WidgetTester tester) async {
    // This code verifies that the PhysicalModel's shadowColor animates over
    // a kThemeChangeDuration time interval.

    await tester.pumpWidget(buildMaterial(shadowColor: const Color(0xFF00FF00)));
    final RenderPhysicalShape modelA = getShadow(tester);
    expect(modelA.shadowColor, equals(const Color(0xFF00FF00)));

    await tester.pumpWidget(buildMaterial(shadowColor: const Color(0xFFFF0000)));
    final RenderPhysicalShape modelB = getShadow(tester);
    expect(modelB.shadowColor, equals(const Color(0xFF00FF00)));

    await tester.pump(const Duration(milliseconds: 1));
    final RenderPhysicalShape modelC = getShadow(tester);
    expect(modelC.shadowColor, within<Color>(distance: 1, from: const Color(0xFF00FF00)));

    await tester.pump(kThemeChangeDuration ~/ 2);
    final RenderPhysicalShape modelD = getShadow(tester);
    expect(modelD.shadowColor, isNot(within<Color>(distance: 1, from: const Color(0xFF00FF00))));

    await tester.pump(kThemeChangeDuration);
    final RenderPhysicalShape modelE = getShadow(tester);
    expect(modelE.shadowColor, equals(const Color(0xFFFF0000)));
  });

  group('Transparency clipping', () {
    testWidgets('No clip by default', (WidgetTester tester) async {
      final GlobalKey materialKey = GlobalKey();
      await tester.pumpWidget(
          Material(
            key: materialKey,
            type: MaterialType.transparency,
            child: const SizedBox(width: 100.0, height: 100.0),
          )
      );

      expect(find.byKey(materialKey), hasNoImmediateClip);
    });

    testWidgets('clips to bounding rect by default given Clip.antiAlias', (WidgetTester tester) async {
      final GlobalKey materialKey = GlobalKey();
      await tester.pumpWidget(
        Material(
          key: materialKey,
          type: MaterialType.transparency,
          child: const SizedBox(width: 100.0, height: 100.0),
          clipBehavior: Clip.antiAlias,
        )
      );

      expect(find.byKey(materialKey), clipsWithBoundingRect);
    });

    testWidgets('clips to rounded rect when borderRadius provided given Clip.antiAlias', (WidgetTester tester) async {
      final GlobalKey materialKey = GlobalKey();
      await tester.pumpWidget(
        Material(
          key: materialKey,
          type: MaterialType.transparency,
          borderRadius: const BorderRadius.all(Radius.circular(10.0)),
          child: const SizedBox(width: 100.0, height: 100.0),
          clipBehavior: Clip.antiAlias,
        )
      );

      expect(
        find.byKey(materialKey),
        clipsWithBoundingRRect(
          borderRadius: const BorderRadius.all(Radius.circular(10.0))
        ),
      );
    });

    testWidgets('clips to shape when provided given Clip.antiAlias', (WidgetTester tester) async {
      final GlobalKey materialKey = GlobalKey();
      await tester.pumpWidget(
        Material(
          key: materialKey,
          type: MaterialType.transparency,
          shape: const StadiumBorder(),
          child: const SizedBox(width: 100.0, height: 100.0),
          clipBehavior: Clip.antiAlias,
        )
      );

      expect(
        find.byKey(materialKey),
        clipsWithShapeBorder(
          shape: const StadiumBorder(),
        ),
      );
    });

    testWidgets('supports directional clips', (WidgetTester tester) async {
      final List<String> logs = <String>[];
      final ShapeBorder shape = TestBorder((String message) { logs.add(message); });
      Widget buildMaterial() {
        return Material(
          type: MaterialType.transparency,
          shape: shape,
          child: const SizedBox(width: 100.0, height: 100.0),
          clipBehavior: Clip.antiAlias,
        );
      }
      final Widget material = buildMaterial();
      // verify that a regular clip works as one would expect
      logs.add('--0');
      await tester.pumpWidget(material);
      // verify that pumping again doesn't recompute the clip
      // even though the widget itself is new (the shape doesn't change identity)
      logs.add('--1');
      await tester.pumpWidget(buildMaterial());
      // verify that Material passes the TextDirection on to its shape when it's transparent
      logs.add('--2');
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: material,
      ));
      // verify that changing the text direction from LTR to RTL has an effect
      // even though the widget itself is identical
      logs.add('--3');
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.rtl,
        child: material,
      ));
      // verify that pumping again with a text direction has no effect
      logs.add('--4');
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.rtl,
        child: buildMaterial(),
      ));
      logs.add('--5');
      // verify that changing the text direction and the widget at the same time
      // works as expected
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: material,
      ));
      expect(logs, <String>[
        '--0',
        'getOuterPath Rect.fromLTRB(0.0, 0.0, 800.0, 600.0) null',
        'paint Rect.fromLTRB(0.0, 0.0, 800.0, 600.0) null',
        '--1',
        '--2',
        'getOuterPath Rect.fromLTRB(0.0, 0.0, 800.0, 600.0) TextDirection.ltr',
        'paint Rect.fromLTRB(0.0, 0.0, 800.0, 600.0) TextDirection.ltr',
        '--3',
        'getOuterPath Rect.fromLTRB(0.0, 0.0, 800.0, 600.0) TextDirection.rtl',
        'paint Rect.fromLTRB(0.0, 0.0, 800.0, 600.0) TextDirection.rtl',
        '--4',
        '--5',
        'getOuterPath Rect.fromLTRB(0.0, 0.0, 800.0, 600.0) TextDirection.ltr',
        'paint Rect.fromLTRB(0.0, 0.0, 800.0, 600.0) TextDirection.ltr',
      ]);
    });
  });

  group('PhysicalModels', () {
    testWidgets('canvas', (WidgetTester tester) async {
      final GlobalKey materialKey = GlobalKey();
      await tester.pumpWidget(
        Material(
          key: materialKey,
          type: MaterialType.canvas,
          child: const SizedBox(width: 100.0, height: 100.0),
        )
      );

      expect(find.byKey(materialKey), rendersOnPhysicalModel(
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.zero,
          elevation: 0.0,
      ));
    });

    testWidgets('canvas with borderRadius and elevation', (WidgetTester tester) async {
      final GlobalKey materialKey = GlobalKey();
      await tester.pumpWidget(
        Material(
          key: materialKey,
          type: MaterialType.canvas,
          borderRadius: const BorderRadius.all(Radius.circular(5.0)),
          child: const SizedBox(width: 100.0, height: 100.0),
          elevation: 1.0,
        )
      );

      expect(find.byKey(materialKey), rendersOnPhysicalModel(
          shape: BoxShape.rectangle,
          borderRadius: const BorderRadius.all(Radius.circular(5.0)),
          elevation: 1.0,
      ));
    });

    testWidgets('canvas with shape and elevation', (WidgetTester tester) async {
      final GlobalKey materialKey = GlobalKey();
      await tester.pumpWidget(
        Material(
          key: materialKey,
          type: MaterialType.canvas,
          shape: const StadiumBorder(),
          child: const SizedBox(width: 100.0, height: 100.0),
          elevation: 1.0,
        )
      );

      expect(find.byKey(materialKey), rendersOnPhysicalShape(
          shape: const StadiumBorder(),
          elevation: 1.0,
      ));
    });

    testWidgets('card', (WidgetTester tester) async {
      final GlobalKey materialKey = GlobalKey();
      await tester.pumpWidget(
        Material(
          key: materialKey,
          type: MaterialType.card,
          child: const SizedBox(width: 100.0, height: 100.0),
        )
      );

      expect(find.byKey(materialKey), rendersOnPhysicalModel(
          shape: BoxShape.rectangle,
          borderRadius: const BorderRadius.all(Radius.circular(2.0)),
          elevation: 0.0,
      ));
    });

    testWidgets('card with borderRadius and elevation', (WidgetTester tester) async {
      final GlobalKey materialKey = GlobalKey();
      await tester.pumpWidget(
        Material(
          key: materialKey,
          type: MaterialType.card,
          borderRadius: const BorderRadius.all(Radius.circular(5.0)),
          elevation: 5.0,
          child: const SizedBox(width: 100.0, height: 100.0),
        )
      );

      expect(find.byKey(materialKey), rendersOnPhysicalModel(
          shape: BoxShape.rectangle,
          borderRadius: const BorderRadius.all(Radius.circular(5.0)),
          elevation: 5.0,
      ));
    });

    testWidgets('card with shape and elevation', (WidgetTester tester) async {
      final GlobalKey materialKey = GlobalKey();
      await tester.pumpWidget(
        Material(
          key: materialKey,
          type: MaterialType.card,
          shape: const StadiumBorder(),
          elevation: 5.0,
          child: const SizedBox(width: 100.0, height: 100.0),
        )
      );

      expect(find.byKey(materialKey), rendersOnPhysicalShape(
          shape: const StadiumBorder(),
          elevation: 5.0,
      ));
    });

    testWidgets('circle', (WidgetTester tester) async {
      final GlobalKey materialKey = GlobalKey();
      await tester.pumpWidget(
        Material(
          key: materialKey,
          type: MaterialType.circle,
          child: const SizedBox(width: 100.0, height: 100.0),
          color: const Color(0xFF0000FF),
        )
      );

      expect(find.byKey(materialKey), rendersOnPhysicalModel(
          shape: BoxShape.circle,
          elevation: 0.0,
      ));
    });

    testWidgets('button', (WidgetTester tester) async {
      final GlobalKey materialKey = GlobalKey();
      await tester.pumpWidget(
        Material(
          key: materialKey,
          type: MaterialType.button,
          child: const SizedBox(width: 100.0, height: 100.0),
          color: const Color(0xFF0000FF),
        )
      );

      expect(find.byKey(materialKey), rendersOnPhysicalModel(
          shape: BoxShape.rectangle,
          borderRadius: const BorderRadius.all(Radius.circular(2.0)),
          elevation: 0.0,
      ));
    });

    testWidgets('button with elevation and borderRadius', (WidgetTester tester) async {
      final GlobalKey materialKey = GlobalKey();
      await tester.pumpWidget(
        Material(
          key: materialKey,
          type: MaterialType.button,
          child: const SizedBox(width: 100.0, height: 100.0),
          color: const Color(0xFF0000FF),
          borderRadius: const BorderRadius.all(Radius.circular(6.0)),
          elevation: 4.0,
        )
      );

      expect(find.byKey(materialKey), rendersOnPhysicalModel(
          shape: BoxShape.rectangle,
          borderRadius: const BorderRadius.all(Radius.circular(6.0)),
          elevation: 4.0,
      ));
    });

    testWidgets('button with elevation and shape', (WidgetTester tester) async {
      final GlobalKey materialKey = GlobalKey();
      await tester.pumpWidget(
        Material(
          key: materialKey,
          type: MaterialType.button,
          child: const SizedBox(width: 100.0, height: 100.0),
          color: const Color(0xFF0000FF),
          shape: const StadiumBorder(),
          elevation: 4.0,
        )
      );

      expect(find.byKey(materialKey), rendersOnPhysicalShape(
          shape: const StadiumBorder(),
          elevation: 4.0,
      ));
    });
  });

  group('Border painting', () {
    testWidgets('border is painted on physical layers', (WidgetTester tester) async {
      final GlobalKey materialKey = GlobalKey();
      await tester.pumpWidget(
        Material(
          key: materialKey,
          type: MaterialType.button,
          child: const SizedBox(width: 100.0, height: 100.0),
          color: const Color(0xFF0000FF),
          shape: const CircleBorder(
            side: BorderSide(
              width: 2.0,
              color: Color(0xFF0000FF),
            ),
          ),
        )
      );

      final RenderBox box = tester.renderObject(find.byKey(materialKey));
      expect(box, paints..circle());
    });

    testWidgets('border is painted for transparent material', (WidgetTester tester) async {
      final GlobalKey materialKey = GlobalKey();
      await tester.pumpWidget(
        Material(
          key: materialKey,
          type: MaterialType.transparency,
          child: const SizedBox(width: 100.0, height: 100.0),
          shape: const CircleBorder(
            side: BorderSide(
              width: 2.0,
              color: Color(0xFF0000FF),
            ),
          ),
        )
      );

      final RenderBox box = tester.renderObject(find.byKey(materialKey));
      expect(box, paints..circle());
    });

    testWidgets('border is not painted for when border side is none', (WidgetTester tester) async {
      final GlobalKey materialKey = GlobalKey();
      await tester.pumpWidget(
        Material(
          key: materialKey,
          type: MaterialType.transparency,
          child: const SizedBox(width: 100.0, height: 100.0),
          shape: const CircleBorder(),
        )
      );

      final RenderBox box = tester.renderObject(find.byKey(materialKey));
      expect(box, isNot(paints..circle()));
    });

    testWidgets('border is painted above child by default', (WidgetTester tester) async {
      final Key painterKey = UniqueKey();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RepaintBoundary(
            key: painterKey,
            child: Card(
              child: SizedBox(
                width: 200,
                height: 300,
                child: Material(
                  clipBehavior: Clip.hardEdge,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.grey, width: 6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: <Widget>[
                      Container(
                        color: Colors.green,
                        height: 150,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ));

      await expectLater(
        find.byKey(painterKey),
        matchesGoldenFile('material.border_paint_above.png'),
        skip: !Platform.isLinux,
      );
    });

    testWidgets('border is painted below child when specified', (WidgetTester tester) async {
      final Key painterKey = UniqueKey();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RepaintBoundary(
            key: painterKey,
            child: Card(
              child: SizedBox(
                width: 200,
                height: 300,
                child: Material(
                  clipBehavior: Clip.hardEdge,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.grey, width: 6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  borderOnForeground: false,
                  child: Column(
                    children: <Widget>[
                      Container(
                        color: Colors.green,
                        height: 150,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ));

      await expectLater(
        find.byKey(painterKey),
        matchesGoldenFile('material.border_paint_below.png'),
        skip: !Platform.isLinux,
      );
    });
  });
}
