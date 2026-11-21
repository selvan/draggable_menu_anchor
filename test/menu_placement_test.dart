import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:draggable_menu_anchor/draggable_menu_anchor.dart';

void main() {
  const bounds = Rect.fromLTRB(8, 8, 392, 792); // 400×800, 8px padding
  const menu = Size(200, 300);

  // A 6px gap, like DraggableMenuAnchor's default alignmentOffset.
  Offset place(
    Rect anchor, {
    Offset? at,
    Size child = menu,
    Alignment alignment = Alignment.bottomLeft,
    Offset offset = const Offset(0, 6),
  }) => menuAnchorPosition(
    anchor: anchor,
    child: child,
    bounds: bounds,
    position: at,
    alignment: alignment,
    alignmentOffset: offset,
  );

  test('fits: at the open point', () {
    const anchor = Rect.fromLTWH(50, 100, 120, 40);
    expect(place(anchor, at: const Offset(10, 20)), const Offset(60, 120));
  });

  test('no position: gap below the anchor', () {
    const anchor = Rect.fromLTWH(50, 100, 120, 40);
    expect(place(anchor), const Offset(50, 146));
  });

  test('too low: directly above the anchor, gap clear', () {
    const anchor = Rect.fromLTWH(50, 700, 120, 40);
    expect(place(anchor, at: const Offset(10, 20)), const Offset(60, 394));
  });

  test('too low, no room above either: against the bottom edge', () {
    const anchor = Rect.fromLTWH(50, 200, 120, 40);
    final p = place(
      anchor,
      at: const Offset(0, 40),
      child: const Size(200, 600),
    );
    expect(p, const Offset(50, 192)); // 792 - 600
  });

  test('too high: just below the anchor', () {
    // Open point above the screen (e.g. a negative position).
    const anchor = Rect.fromLTWH(50, 20, 120, 40);
    expect(place(anchor, at: const Offset(0, -30)), const Offset(50, 60));
  });

  test('off the right: pushed in; off the left: pushed in', () {
    const anchor = Rect.fromLTWH(300, 100, 80, 40);
    expect(place(anchor, at: const Offset(40, 0)).dx, 392 - 200);
    const left = Rect.fromLTWH(0, 100, 80, 40);
    expect(place(left, at: const Offset(-20, 0)).dx, 8);
  });

  test('bigger than the bounds: at the top-left edges', () {
    const anchor = Rect.fromLTWH(50, 100, 120, 40);
    final p = place(anchor, at: Offset.zero, child: const Size(500, 900));
    expect(p, const Offset(8, 8));
  });

  test('keepInside', () {
    expect(
      keepInside(const Offset(-50, 900), menu, bounds),
      const Offset(8, 792 - 300),
    );
    expect(
      keepInside(const Offset(100, 100), menu, bounds),
      const Offset(100, 100),
    );
    expect(
      keepInside(const Offset(100, 100), const Size(999, 999), bounds),
      const Offset(8, 8),
    );
  });

  group('alignment + alignmentOffset (no position)', () {
    const anchor = Rect.fromLTWH(50, 100, 120, 40);

    test("defaults are MenuAnchor's: anchor's bottom-left, no offset", () {
      expect(
        menuAnchorPosition(anchor: anchor, child: menu, bounds: bounds),
        const Offset(50, 140),
      );
    });

    test('bottomRight / topRight / centerLeft', () {
      expect(
        place(anchor, alignment: Alignment.bottomRight, offset: Offset.zero),
        const Offset(170, 140),
      );
      // To the right of the anchor, 8px clear.
      expect(
        place(
          anchor,
          alignment: Alignment.topRight,
          offset: const Offset(8, 0),
        ),
        const Offset(178, 100),
      );
      // Too wide to fit there (178 + 300 > 392): pushed in from the right.
      expect(
        place(
          anchor,
          alignment: Alignment.topRight,
          offset: const Offset(8, 0),
          child: const Size(300, 300),
        ),
        const Offset(392 - 300, 100),
      );
      expect(
        place(anchor, alignment: Alignment.centerLeft, offset: Offset.zero),
        const Offset(50, 120),
      );
    });

    test('offset is added to the alignment point', () {
      expect(
        place(anchor, offset: const Offset(10, 20)),
        const Offset(60, 160),
      );
    });

    test('a position ignores alignment and offset', () {
      expect(
        place(
          anchor,
          at: const Offset(10, 20),
          alignment: Alignment.topRight,
          offset: const Offset(99, 99),
        ),
        const Offset(60, 120),
      );
    });

    test('flipping above keeps alignmentOffset.dy clear', () {
      const low = Rect.fromLTWH(50, 700, 120, 40);
      expect(place(low, offset: const Offset(0, 12)).dy, 700 - 300 - 12);
    });
  });
}
