// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'bottom_app_bar_theme.dart';
import 'material.dart';
import 'scaffold.dart';
import 'theme.dart';

// Examples can assume:
// Widget bottomAppBarContents;

/// A container that is typically used with [Scaffold.bottomNavigationBar], and
/// can have a notch along the top that makes room for an overlapping
/// [FloatingActionButton].
///
/// Typically used with a [Scaffold] and a [FloatingActionButton].
///
/// {@tool sample}
/// ```dart
/// Scaffold(
///   bottomNavigationBar: BottomAppBar(
///     color: Colors.white,
///     child: bottomAppBarContents,
///   ),
///   floatingActionButton: FloatingActionButton(onPressed: null),
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [ComputeNotch] a function used for creating a notch in a shape.
///  * [ScaffoldGeometry.floatingActionBarComputeNotch] the [ComputeNotch] used to
///    make a notch for the [FloatingActionButton].
///  * [FloatingActionButton] which the [BottomAppBar] makes a notch for.
///  * [AppBar] for a toolbar that is shown at the top of the screen.
class BottomAppBar extends StatefulWidget {
  /// Creates a bottom application bar.
  ///
  /// The [clipBehavior] argument must not be null.
  /// Additionally, [elevation] must be non-negative.
  ///
  /// If [color], [elevation], or [shape] are null, their [BottomAppBarTheme] values will be used.
  /// If the corresponding [BottomAppBarTheme] property is null, then the default
  /// specified in the property's documentation will be used.
  const BottomAppBar({
    Key key,
    this.color,
    this.elevation,
    this.shape,
    this.clipBehavior = Clip.none,
    this.notchMargin = 4.0,
    this.child,
  }) : assert(clipBehavior != null),
       assert(elevation == null || elevation >= 0.0),
       assert(notchMargin != null),
       super(key: key);

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  ///
  /// Typically this the child will be a [Row], with the first child
  /// being an [IconButton] with the [Icons.menu] icon.
  final Widget child;

  /// The bottom app bar's background color.
  ///
  /// If this property is null then [ThemeData.bottomAppBarTheme.color] is used,
  /// if that's null then [ThemeData.bottomAppBarColor] is used.
  final Color color;

  /// The z-coordinate at which to place this bottom app bar relative to its
  /// parent.
  ///
  /// This controls the size of the shadow below the bottom app bar. The
  /// value is non-negative.
  ///
  /// If this property is null then [ThemeData.bottomAppBarTheme.elevation] is used,
  /// if that's null, the default value is 8.
  final double elevation;

  /// The notch that is made for the floating action button.
  ///
  /// If this property is null then [ThemeData.bottomAppBarTheme.shape] is used,
  /// if that's null then the shape will be rectangular with no notch.
  final NotchedShape shape;

  /// {@macro flutter.widgets.Clip}
  final Clip clipBehavior;

  /// The margin between the [FloatingActionButton] and the [BottomAppBar]'s
  /// notch.
  ///
  /// Not used if [shape] is null.
  final double notchMargin;

  @override
  State createState() => _BottomAppBarState();
}

class _BottomAppBarState extends State<BottomAppBar> {
  ValueListenable<ScaffoldGeometry> geometryListenable;
  static const double _defaultElevation = 8.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    geometryListenable = Scaffold.geometryOf(context);
  }

  @override
  Widget build(BuildContext context) {
    final BottomAppBarTheme babTheme = BottomAppBarTheme.of(context);
    final NotchedShape notchedShape = widget.shape ?? babTheme.shape;
    final CustomClipper<Path> clipper = notchedShape != null
      ? _BottomAppBarClipper(
        geometry: geometryListenable,
        shape: notchedShape,
        notchMargin: widget.notchMargin,
      )
      : const ShapeBorderClipper(shape: RoundedRectangleBorder());
    return PhysicalShape(
      clipper: clipper,
      elevation: widget.elevation ?? babTheme.elevation ?? _defaultElevation,
      color: widget.color ?? babTheme.color ?? Theme.of(context).bottomAppBarColor,
      clipBehavior: widget.clipBehavior,
      child: Material(
        type: MaterialType.transparency,
        child: widget.child == null
          ? null
          : SafeArea(child: widget.child),
      ),
    );
  }
}

class _BottomAppBarClipper extends CustomClipper<Path> {
  const _BottomAppBarClipper({
    @required this.geometry,
    @required this.shape,
    @required this.notchMargin,
  }) : assert(geometry != null),
       assert(shape != null),
       assert(notchMargin != null),
       super(reclip: geometry);

  final ValueListenable<ScaffoldGeometry> geometry;
  final NotchedShape shape;
  final double notchMargin;

  @override
  Path getClip(Size size) {
    // button is the floating action button's bounding rectangle in the
    // coordinate system whose origin is at the appBar's top left corner,
    // or null if there is no floating action button.
    final Rect button = geometry.value.floatingActionButtonArea?.translate(
      0.0,
      geometry.value.bottomNavigationBarTop * -1.0,
    );
    return shape.getOuterPath(Offset.zero & size, button?.inflate(notchMargin));
  }

  @override
  bool shouldReclip(_BottomAppBarClipper oldClipper) {
    return oldClipper.geometry != geometry
        || oldClipper.shape != shape
        || oldClipper.notchMargin != notchMargin;
  }
}
