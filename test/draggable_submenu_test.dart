// Only package:flutter/widgets.dart: the submenu needs neither material nor
// Cupertino.
import 'package:draggable_menu_anchor/draggable_menu_anchor.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('submenuPosition', () {
    const bounds = Rect.fromLTWH(0, 0, 400, 800);
    const row = Rect.fromLTWH(100, 200, 120, 40);
    const size = Size(150, 100);

    test('beside the row, tops level', () {
      expect(
        submenuPosition(anchor: row, child: size, bounds: bounds),
        const Offset(220, 200),
      );
    });

    test('offset: gap from the side, shift down', () {
      expect(
        submenuPosition(
          anchor: row,
          child: size,
          bounds: bounds,
          offset: const Offset(4, -8),
        ),
        const Offset(224, 192),
      );
    });

    test('no room on the right: flips to the left', () {
      const nearRight = Rect.fromLTWH(200, 200, 120, 40);
      expect(
        submenuPosition(
          anchor: nearRight,
          child: size,
          bounds: bounds,
          offset: const Offset(4, 0),
        ),
        const Offset(200 - 4 - 150, 200),
      );
    });

    test('no room on either side: pushed in from the right edge', () {
      const wide = Rect.fromLTWH(60, 200, 280, 40);
      expect(
        submenuPosition(anchor: wide, child: size, bounds: bounds).dx,
        400 - 150,
      );
    });

    test('wider than the screen: at its left edge', () {
      expect(
        submenuPosition(
          anchor: row,
          child: const Size(500, 100),
          bounds: bounds,
        ).dx,
        0,
      );
    });

    test('right-to-left: left first, flips to the right', () {
      expect(
        submenuPosition(
          anchor: row,
          child: const Size(90, 100),
          bounds: bounds,
          textDirection: TextDirection.rtl,
        ).dx,
        100 - 90,
      );
      expect(
        submenuPosition(
          anchor: row,
          child: size,
          bounds: bounds,
          textDirection: TextDirection.rtl,
        ).dx,
        220,
      );
    });

    test('off the bottom: grows upwards from the row, else at the bottom', () {
      const low = Rect.fromLTWH(100, 740, 120, 40);
      expect(
        submenuPosition(anchor: low, child: size, bounds: bounds).dy,
        780 - 100,
      );
      expect(
        submenuPosition(
          anchor: const Rect.fromLTWH(100, 760, 120, 40),
          child: const Size(150, 790),
          bounds: bounds,
        ).dy,
        800 - 790,
      );
    });

    test('taller than the screen: at its top edge', () {
      expect(
        submenuPosition(
          anchor: row,
          child: const Size(150, 900),
          bounds: bounds,
        ).dy,
        0,
      );
    });
  });

  group('DraggableSubmenu', () {
    const screen = Size(600, 600);
    final menu = find.byKey(const ValueKey<String>('menu'));
    final insertMenu = find.byKey(const ValueKey<String>('insert-menu'));
    final arrangeMenu = find.byKey(const ValueKey<String>('arrange-menu'));
    final shapesMenu = find.byKey(const ValueKey<String>('shapes-menu'));

    Widget row(String label, {VoidCallback? onTap}) => GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(height: 40, child: Text(label)),
    );

    Widget surface(String key, List<Widget> rows) => Container(
      key: ValueKey<String>(key),
      width: 150,
      color: const Color(0xFF333333),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: rows,
      ),
    );

    /// A plain-widgets app (no material) with a draggable menu holding two
    /// submenus, "Insert" (with a nested "Shapes") and "Arrange".
    Future<MenuController> pump(
      WidgetTester tester, {
      required Offset at,
      List<String>? chosen,
    }) async {
      tester.view.physicalSize = screen;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = MenuController();
      void choose(String item) {
        chosen?.add(item);
        controller.close();
      }

      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFF000000),
          builder: (context, _) => Overlay(
            initialEntries: <OverlayEntry>[
              OverlayEntry(
                // A background, as apps have: taps on it count as outside
                // the menu (Flutter only sees taps on hit-testable widgets).
                builder: (context) => ColoredBox(
                  color: const Color(0xFF101010),
                  child: DraggableMenuAnchor(
                    controller: controller,
                    screenPadding: EdgeInsets.zero,
                    menuChildren: <Widget>[
                      surface('menu', <Widget>[
                        row('Copy', onTap: () => choose('Copy')),
                        DraggableSubmenu(
                          menuChildren: <Widget>[
                            surface('insert-menu', <Widget>[
                              row('Text', onTap: () => choose('Text')),
                              DraggableSubmenu(
                                menuChildren: <Widget>[
                                  surface('shapes-menu', <Widget>[
                                    row(
                                      'Circle',
                                      onTap: () => choose('Circle'),
                                    ),
                                  ]),
                                ],
                                child: row('Shapes'),
                              ),
                            ]),
                          ],
                          child: row('Insert'),
                        ),
                        DraggableSubmenu(
                          menuChildren: <Widget>[
                            surface('arrange-menu', <Widget>[
                              row('Send to back'),
                            ]),
                          ],
                          child: row('Arrange'),
                        ),
                      ]),
                    ],
                    // A small anchor in the corner: a tap on the anchor isn't
                    // "outside", so it mustn't cover the screen.
                    child: const Align(
                      alignment: Alignment.topLeft,
                      child: SizedBox(width: 10, height: 10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      controller.open(position: at);
      await tester.pumpAndSettle();
      return controller;
    }

    Future<void> tapText(WidgetTester tester, String text) async {
      await tester.tap(find.text(text));
      await tester.pumpAndSettle();
    }

    testWidgets('a tap on the row opens it beside the menu, again closes it', (
      tester,
    ) async {
      await pump(tester, at: const Offset(50, 50));
      expect(insertMenu, findsNothing);
      await tapText(tester, 'Insert');
      expect(insertMenu, findsOneWidget);
      final insertRow = tester.getRect(find.text('Insert'));
      expect(tester.getTopLeft(insertMenu), Offset(200, insertRow.top));
      expect(menu, findsOneWidget);

      await tapText(tester, 'Insert');
      expect(insertMenu, findsNothing);
      expect(menu, findsOneWidget);
    });

    testWidgets('near the right edge it flips to the left', (tester) async {
      await pump(tester, at: const Offset(440, 50));
      final menuRect = tester.getRect(menu);
      await tapText(tester, 'Insert');
      expect(tester.getTopRight(insertMenu).dx, menuRect.left);
    });

    testWidgets('opening one submenu closes the other', (tester) async {
      await pump(tester, at: const Offset(50, 50));
      await tapText(tester, 'Insert');
      await tapText(tester, 'Arrange');
      expect(arrangeMenu, findsOneWidget);
      expect(insertMenu, findsNothing);
    });

    testWidgets('nested submenus open beside their own row', (tester) async {
      final chosen = <String>[];
      final controller = await pump(
        tester,
        at: const Offset(20, 50),
        chosen: chosen,
      );
      await tapText(tester, 'Insert');
      await tapText(tester, 'Shapes');
      expect(shapesMenu, findsOneWidget);
      expect(
        tester.getTopLeft(shapesMenu).dx,
        tester.getTopRight(insertMenu).dx,
      );

      // A tap inside a submenu isn't outside: choosing works, and the app
      // closes everything.
      await tapText(tester, 'Circle');
      expect(chosen, <String>['Circle']);
      expect(controller.isOpen, isFalse);
      expect(menu, findsNothing);
      expect(shapesMenu, findsNothing);
    });

    testWidgets('a tap outside everything closes them all', (tester) async {
      final controller = await pump(tester, at: const Offset(50, 50));
      await tapText(tester, 'Insert');
      await tapText(tester, 'Shapes');
      await tester.tapAt(const Offset(590, 590));
      await tester.pumpAndSettle();
      expect(controller.isOpen, isFalse);
      expect(menu, findsNothing);
      expect(insertMenu, findsNothing);
      expect(shapesMenu, findsNothing);
    });

    testWidgets('dragging the menu closes its submenus', (tester) async {
      await pump(tester, at: const Offset(50, 50));
      await tapText(tester, 'Insert');
      final before = tester.getTopLeft(menu);
      await tester.drag(find.text('Copy'), const Offset(60, 80));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(menu), before + const Offset(60, 80));
      expect(insertMenu, findsNothing);
    });

    testWidgets('builder: opened from code through its controller', (
      tester,
    ) async {
      tester.view.physicalSize = screen;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final root = MenuController();
      final sub = MenuController();
      var opened = 0;
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFF000000),
          builder: (context, _) => Overlay(
            initialEntries: <OverlayEntry>[
              OverlayEntry(
                // A background, as apps have: taps on it count as outside
                // the menu (Flutter only sees taps on hit-testable widgets).
                builder: (context) => ColoredBox(
                  color: const Color(0xFF101010),
                  child: DraggableMenuAnchor(
                    controller: root,
                    menuChildren: <Widget>[
                      surface('menu', <Widget>[
                        DraggableSubmenu(
                          controller: sub,
                          onOpen: () => opened++,
                          menuChildren: <Widget>[
                            surface('insert-menu', <Widget>[row('Text')]),
                          ],
                          builder: (context, controller, child) =>
                              row('Insert'),
                        ),
                      ]),
                    ],
                    // A small anchor in the corner: a tap on the anchor isn't
                    // "outside", so it mustn't cover the screen.
                    child: const Align(
                      alignment: Alignment.topLeft,
                      child: SizedBox(width: 10, height: 10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      root.open(position: const Offset(50, 50));
      await tester.pumpAndSettle();
      // With a builder, a tap on the row is the app's to handle.
      await tapText(tester, 'Insert');
      expect(insertMenu, findsNothing);
      sub.open();
      await tester.pumpAndSettle();
      expect(insertMenu, findsOneWidget);
      expect(opened, 1);
      root.close();
      await tester.pumpAndSettle();
      expect(sub.isOpen, isFalse);
    });
  });
}
