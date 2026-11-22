import 'package:flutter/widgets.dart';

import 'draggable_menu_anchor.dart';

/// A ready-made grip for a [DraggableMenuAnchor]'s menu: a band of tiny
/// staggered dots across the menu's width that drags the menu.
///
/// Each dot is a light square with a darker one just below-right of it, and
/// every other row is shifted by half a step, so the band reads as a
/// textured, raised strip. It's a [DraggableMenuHandle], so it drags the
/// menu it's in (and is required to, with `dragFrom: MenuDragFrom.handle`).
///
/// Put it at the top of the menu, flush with its edges:
///
/// ```dart
/// DraggableMenuAnchor(
///   menuChildren: [
///     MySurface(
///       child: IntrinsicWidth(
///         child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
///           const DraggableMenuGrip(),
///           // … rows
///         ]),
///       ),
///     ),
///   ],
/// )
/// ```
///
/// It fills the width it's given and is [rows] × 2 × [dotSize] tall, plus
/// [padding]. For a grip of your own (an icon, a title bar, …), wrap it in a
/// [DraggableMenuHandle] instead.
class DraggableMenuGrip extends StatelessWidget {
  const DraggableMenuGrip({
    super.key,
    this.color,
    this.shadowColor = const Color(0xB3000000),
    this.dotSize = 1.5,
    this.rows = 4,
    this.padding = const EdgeInsets.only(bottom: 4),
  }) : assert(dotSize > 0),
       assert(rows > 0);

  /// The light dots. Defaults to the ambient [IconTheme]'s colour at 55%
  /// opacity.
  final Color? color;

  /// The darker dot beside each light one.
  final Color shadowColor;

  /// The side of one dot, in logical pixels. Dots repeat every 4 × [dotSize]
  /// across, and rows every 2 × [dotSize] down.
  final double dotSize;

  /// How many rows of dots.
  final int rows;

  /// Space around the band (by default only below it).
  final EdgeInsets padding;

  /// The band's height, without [padding].
  double get bandHeight => rows * 2 * dotSize;

  @override
  Widget build(BuildContext context) {
    final light =
        color ??
        (IconTheme.of(context).color ?? const Color(0xFF9E9E9E)).withValues(
          alpha: 0.55,
        );
    return DraggableMenuHandle(
      child: Padding(
        padding: padding,
        child: CustomPaint(
          size: Size.fromHeight(bandHeight),
          painter: _GripPainter(
            light: light,
            dark: shadowColor,
            dotSize: dotSize,
            rows: rows,
          ),
        ),
      ),
    );
  }
}

class _GripPainter extends CustomPainter {
  const _GripPainter({
    required this.light,
    required this.dark,
    required this.dotSize,
    required this.rows,
  });

  final Color light;
  final Color dark;
  final double dotSize;
  final int rows;

  @override
  void paint(Canvas canvas, Size size) {
    final lightPaint = Paint()..color = light;
    final darkPaint = Paint()..color = dark;
    final step = 4 * dotSize;
    // Edge to edge: the pattern runs past both sides and is cut off there.
    canvas.clipRect(Offset.zero & size);
    for (var row = 0; row < rows; row++) {
      final y = row * 2 * dotSize;
      // Every other row is shifted half a step: the dots stagger.
      for (var x = row.isOdd ? -step / 2 : 0.0; x < size.width; x += step) {
        canvas
          ..drawRect(Rect.fromLTWH(x, y, dotSize, dotSize), lightPaint)
          ..drawRect(
            Rect.fromLTWH(x + dotSize, y + dotSize, dotSize, dotSize),
            darkPaint,
          );
      }
    }
  }

  @override
  bool shouldRepaint(_GripPainter old) =>
      old.light != light ||
      old.dark != dark ||
      old.dotSize != dotSize ||
      old.rows != rows;
}
