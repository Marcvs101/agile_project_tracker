import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/services.dart';

class _MarqueeText extends AnimatedWidget {
  const _MarqueeText({Key key, Animation<double> animation})
      : super(key: key, listenable: animation);

  @override
  Widget build(BuildContext context) {
    final Animation<double> animation = listenable;
    return Container(
      margin: EdgeInsets.only(left: animation.value),
      child: const Text(
        'This is Marquee',
        softWrap: false,
      ),
    );
  }
}

class Marquee extends StatefulWidget {
  const Marquee({this.color});

  final Color color;

  @override
  State<StatefulWidget> createState() => MarqueeState();
}

class MarqueeState extends State<Marquee> with SingleTickerProviderStateMixin {
  AnimationController controller;
  Animation<double> animation;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    animation = Tween<double>(begin: 0.0, end: 400.0).animate(controller);
    controller.repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: widget.color,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: <Widget>[
            Align(
              child: _MarqueeText(animation: animation),
              alignment: Alignment.centerLeft,
            ),
            const FlatButton(child: Text('POP'), onPressed: SystemNavigator.pop),
          ],
        ),
      ),
    );
  }
}
