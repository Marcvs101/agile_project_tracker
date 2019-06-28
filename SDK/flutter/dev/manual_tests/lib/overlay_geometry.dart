// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class CardModel {
  CardModel(this.value, this.height, this.color);

  int value;
  double height;
  Color color;

  String get label => 'Card $value';
  Key get key => ObjectKey(this);
  GlobalKey get targetKey => GlobalObjectKey(this);
}

enum MarkerType { topLeft, bottomRight, touch }

class _MarkerPainter extends CustomPainter {
  const _MarkerPainter({
    this.size,
    this.type,
  });

  final double size;
  final MarkerType type;

  @override
  void paint(Canvas canvas, _) {
    final Paint paint = Paint()..color = const Color(0x8000FF00);
    final double r = size / 2.0;
    canvas.drawCircle(Offset(r, r), r, paint);

    paint
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    if (type == MarkerType.topLeft) {
      canvas.drawLine(Offset(r, r), Offset(r + r - 1.0, r), paint);
      canvas.drawLine(Offset(r, r), Offset(r, r + r - 1.0), paint);
    }
    if (type == MarkerType.bottomRight) {
      canvas.drawLine(Offset(r, r), Offset(1.0, r), paint);
      canvas.drawLine(Offset(r, r), Offset(r, 1.0), paint);
    }
  }

  @override
  bool shouldRepaint(_MarkerPainter oldPainter) {
    return oldPainter.size != size
        || oldPainter.type != type;
  }
}

class Marker extends StatelessWidget {
  const Marker({
    Key key,
    this.type = MarkerType.touch,
    this.position,
    this.size = 40.0,
  }) : super(key: key);

  final Offset position;
  final double size;
  final MarkerType type;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx - size / 2.0,
      top: position.dy - size / 2.0,
      width: size,
      height: size,
      child: IgnorePointer(
        child: CustomPaint(
          painter: _MarkerPainter(
            size: size,
            type: type,
          ),
        ),
      ),
    );
  }
}

class OverlayGeometryApp extends StatefulWidget {
  @override
  OverlayGeometryAppState createState() => OverlayGeometryAppState();
}

typedef CardTapCallback = void Function(GlobalKey targetKey, Offset globalPosition);

class CardBuilder extends SliverChildDelegate {
  CardBuilder({ this.cardModels, this.onTapUp });

  final List<CardModel> cardModels;
  final CardTapCallback onTapUp;

  static const TextStyle cardLabelStyle =
    TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.bold);

  @override
  Widget build(BuildContext context, int index) {
    if (index >= cardModels.length)
      return null;
    final CardModel cardModel = cardModels[index];
    return GestureDetector(
      key: cardModel.key,
      onTapUp: (TapUpDetails details) { onTapUp(cardModel.targetKey, details.globalPosition); },
      child: Card(
        key: cardModel.targetKey,
        color: cardModel.color,
        child: Container(
          height: cardModel.height,
          padding: const EdgeInsets.all(8.0),
          child: Center(child: Text(cardModel.label, style: cardLabelStyle)),
        ),
      ),
    );
  }

  @override
  int get estimatedChildCount => cardModels.length;

  @override
  bool shouldRebuild(CardBuilder oldDelegate) {
    return oldDelegate.cardModels != cardModels;
  }
}

class OverlayGeometryAppState extends State<OverlayGeometryApp> {
  List<CardModel> cardModels;
  Map<MarkerType, Offset> markers = <MarkerType, Offset>{};
  double markersScrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    final List<double> cardHeights = <double>[
      48.0, 63.0, 82.0, 146.0, 60.0, 55.0, 84.0, 96.0, 50.0,
      48.0, 63.0, 82.0, 146.0, 60.0, 55.0, 84.0, 96.0, 50.0,
      48.0, 63.0, 82.0, 146.0, 60.0, 55.0, 84.0, 96.0, 50.0,
    ];
    cardModels = List<CardModel>.generate(cardHeights.length, (int i) {
      final Color color = Color.lerp(Colors.red.shade300, Colors.blue.shade900, i / cardHeights.length);
      return CardModel(i, cardHeights[i], color);
    });
  }

  bool handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification && notification.depth == 0) {
      setState(() {
        final double dy = markersScrollOffset - notification.metrics.extentBefore;
        markersScrollOffset = notification.metrics.extentBefore;
        for (MarkerType type in markers.keys) {
          final Offset oldPosition = markers[type];
          markers[type] = oldPosition.translate(0.0, dy);
        }
      });
    }
    return false;
  }

  void handleTapUp(GlobalKey target, Offset globalPosition) {
    setState(() {
      markers[MarkerType.touch] = globalPosition;
      final RenderBox box = target.currentContext.findRenderObject();
      markers[MarkerType.topLeft] = box.localToGlobal(const Offset(0.0, 0.0));
      final Size size = box.size;
      markers[MarkerType.bottomRight] = box.localToGlobal(Offset(size.width, size.height));
      final ScrollableState scrollable = Scrollable.of(target.currentContext);
      markersScrollOffset = scrollable.position.pixels;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> layers = <Widget>[
      Scaffold(
        appBar: AppBar(title: const Text('Tap a Card')),
        body: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          child: NotificationListener<ScrollNotification>(
            onNotification: handleScrollNotification,
            child: ListView.custom(
              childrenDelegate: CardBuilder(
                cardModels: cardModels,
                onTapUp: handleTapUp,
              ),
            ),
          ),
        ),
      ),
    ];
    for (MarkerType type in markers.keys)
      layers.add(Marker(type: type, position: markers[type]));
    return Stack(children: layers);
  }
}

void main() {
  runApp(MaterialApp(
    theme: ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      accentColor: Colors.redAccent,
    ),
    title: 'Cards',
    home: OverlayGeometryApp(),
  ));
}
