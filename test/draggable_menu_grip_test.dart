// Only package:flutter/widgets.dart: the grip needs neither material nor
// Cupertino.
import 'package:draggable_menu_anchor/draggable_menu_anchor.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final menu = find.byKey(const ValueKey<String>('menu'));
  final grip = find.byType(DraggableMenuGrip);

  /// A 200-wide menu with [gripWidget] on top and a 100-tall body, opened at
  /// (50, 50).
  Future<MenuController> pump(
    WidgetTester tester, {
    Widget gripWidget = const DraggableMenuGrip(),
    MenuDragFrom dragFrom = MenuDragFrom.anywhere,
  }) async {
    tester.view.physicalSize = const Size(600, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = MenuController();
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFF000000),
        builder: (context, _) => Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (context) => DraggableMenuAnchor(
                controller: controller,
                dragFrom: dragFrom,
                menuChildren: <Widget>[
                  SizedBox(
                    key: const ValueKey<String>('menu'),
                    width: 200,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        gripWidget,
                        const SizedBox(
                          key: ValueKey<String>('body'),
                          height: 100,
                        ),
                      ],
                    ),
                  ),
                ],
                child: const Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(width: 10, height: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    controller.open(position: const Offset(50, 50));
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets('fills the width; 4 rows of 1.5px dots + 4px below by default', (
    tester,
  ) async {
    await pump(tester);
    expect(tester.getSize(grip), const Size(200, 4 * 2 * 1.5 + 4));
  });

  testWidgets('rows, dotSize and padding set its size', (tester) async {
    await pump(
      tester,
      gripWidget: const DraggableMenuGrip(
        rows: 2,
        dotSize: 3,
        padding: EdgeInsets.symmetric(vertical: 5),
      ),
    );
    expect(tester.getSize(grip), const Size(200, 2 * 2 * 3 + 10));
    expect(const DraggableMenuGrip(rows: 3, dotSize: 2).bandHeight, 12);
  });

  testWidgets('drags the menu, even when only handles may', (tester) async {
    await pump(tester, dragFrom: MenuDragFrom.handle);
    final before = tester.getTopLeft(menu);

    // The body doesn't drag in handle mode…
    await tester.drag(
      find.byKey(const ValueKey<String>('body')),
      const Offset(80, 60),
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(menu), before);

    // …the grip does.
    await tester.drag(grip, const Offset(80, 60));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(menu), before + const Offset(80, 60));
  });

  testWidgets('paints its dots', (tester) async {
    await pump(
      tester,
      gripWidget: const DraggableMenuGrip(
        color: Color(0xFFFFFFFF),
        shadowColor: Color(0xFF000000),
      ),
    );
    final paint = find.descendant(of: grip, matching: find.byType(CustomPaint));
    expect(
      paint,
      paints
        ..rect(color: const Color(0xFFFFFFFF))
        ..rect(color: const Color(0xFF000000)),
    );
  });

  testWidgets('outside a menu it just paints', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: SizedBox(width: 100, child: DraggableMenuGrip())),
      ),
    );
    expect(tester.getSize(grip), const Size(100, 16));
    await tester.drag(grip, const Offset(30, 30));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
