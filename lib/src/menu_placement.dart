import 'package:flutter/painting.dart' show Alignment, Offset, Rect, Size;

/// Where Flutter's `MenuAnchor` puts the top-left corner of a menu of size
/// [child] opened from [anchor], kept inside [bounds].
///
/// All rects share one coordinate space (e.g. the overlay's). [position] is
/// the `MenuController.open(position:)` point, relative to [anchor]'s
/// top-left. Without it, the menu's top-left starts at the [alignment] point
/// of [anchor] (e.g. `Alignment.bottomLeft`: its bottom-left corner) plus
/// [alignmentOffset], as `MenuAnchor.alignmentOffset` / `MenuStyle.alignment`
/// do. The defaults are `MenuAnchor`'s.
///
/// The rules follow `_MenuLayout` in Flutter's `material/menu_anchor.dart`
/// for a top-level menu (left-to-right):
///  * start at the open point;
///  * wider than [bounds] → at its left edge; off the left or right → pushed
///    back in;
///  * taller than [bounds] → at its top edge; off the top → just below the
///    anchor (or at the top edge); off the bottom → directly above the
///    anchor, `alignmentOffset.dy` clear (or against the bottom edge).
Offset menuAnchorPosition({
  required Rect anchor,
  required Size child,
  required Rect bounds,
  Offset? position,
  Alignment alignment = Alignment.bottomLeft,
  Offset alignmentOffset = Offset.zero,
}) {
  final start = position != null
      ? anchor.topLeft + position
      : alignment.withinRect(anchor) + alignmentOffset;
  var x = start.dx;
  var y = start.dy;

  if (child.width >= bounds.width) {
    x = bounds.left;
  } else if (x < bounds.left) {
    x = bounds.left;
  } else if (x + child.width > bounds.right) {
    x = bounds.right - child.width;
  }

  bool offTop(double y) => y < bounds.top;
  bool offBottom(double y) => y + child.height > bounds.bottom;
  if (child.height >= bounds.height) {
    y = bounds.top;
  } else if (offTop(y)) {
    y = offBottom(anchor.bottom) ? bounds.top : anchor.bottom;
  } else if (offBottom(y)) {
    final above = anchor.top - child.height;
    y = offTop(above)
        ? bounds.bottom - child.height
        : above - alignmentOffset.dy;
  }
  return Offset(x, y);
}

/// [topLeft] moved the least needed to keep a [child]-sized box inside
/// [bounds]. A box bigger than [bounds] sits at its top/left edge.
Offset keepInside(Offset topLeft, Size child, Rect bounds) {
  double clamp(double v, double min, double max) =>
      max < min ? min : (v < min ? min : (v > max ? max : v));
  return Offset(
    clamp(topLeft.dx, bounds.left, bounds.right - child.width),
    clamp(topLeft.dy, bounds.top, bounds.bottom - child.height),
  );
}
