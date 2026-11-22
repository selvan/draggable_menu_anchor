import 'package:draggable_menu_anchor/material.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const screen = Size(600, 600);
  const menuKey = ValueKey<String>('menu');
  final menu = find.byKey(menuKey);

  /// A draggable menu (200 wide) with an "Insert" submenu, opened at [at].
  Future<MenuController> pump(
    WidgetTester tester, {
    required Offset at,
    bool scoped = true,
    List<String>? chosen,
  }) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = MenuController();
    final Widget items = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        MenuItemButton(onPressed: () {}, child: const Text('Copy')),
        SubmenuButton(
          menuChildren: <Widget>[
            MenuItemButton(
              onPressed: () => chosen?.add('Image'),
              child: const Text('Image'),
            ),
          ],
          child: const Text('Insert'),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DraggableMenuAnchor(
            controller: controller,
            screenPadding: EdgeInsets.zero,
            menuChildren: <Widget>[
              Material(
                key: menuKey,
                child: SizedBox(
                  width: 200,
                  child: scoped ? VerticalMenuScope(child: items) : items,
                ),
              ),
            ],
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
    controller.open(position: at);
    await tester.pumpAndSettle();
    return controller;
  }

  Rect submenuItem(WidgetTester tester) =>
      tester.getRect(find.widgetWithText(MenuItemButton, 'Image'));

  Future<void> openInsert(WidgetTester tester) async {
    await tester.tap(find.text('Insert'));
    await tester.pumpAndSettle();
  }

  testWidgets('without it, a submenu opens below its button', (tester) async {
    await pump(tester, at: const Offset(50, 50), scoped: false);
    await openInsert(tester);
    final insert = tester.getRect(find.widgetWithText(SubmenuButton, 'Insert'));
    expect(submenuItem(tester).top, greaterThanOrEqualTo(insert.bottom));
    expect(submenuItem(tester).left, lessThan(insert.right));
  });

  testWidgets('with it, a submenu opens beside the menu', (tester) async {
    await pump(tester, at: const Offset(50, 50));
    await openInsert(tester);
    final insert = tester.getRect(find.widgetWithText(SubmenuButton, 'Insert'));
    expect(submenuItem(tester).left, greaterThanOrEqualTo(insert.right - 1));
    expect(submenuItem(tester).top, lessThan(insert.bottom));
  });

  testWidgets('near the right edge, it flips to the left of the menu', (
    tester,
  ) async {
    await pump(tester, at: const Offset(380, 50));
    final menuRect = tester.getRect(menu);
    expect(menuRect.right, lessThanOrEqualTo(screen.width));
    await openInsert(tester);
    expect(submenuItem(tester).right, lessThanOrEqualTo(menuRect.left + 1));
  });

  testWidgets('the submenu is part of the menu: taps in it work, an outside '
      'tap closes both', (tester) async {
    final chosen = <String>[];
    final controller = await pump(
      tester,
      at: const Offset(50, 50),
      chosen: chosen,
    );
    await openInsert(tester);
    await tester.tap(find.text('Image'));
    await tester.pumpAndSettle();
    expect(chosen, <String>['Image']);

    await openInsert(tester);
    expect(find.text('Image'), findsOneWidget);
    await tester.tapAt(const Offset(590, 590));
    await tester.pumpAndSettle();
    expect(controller.isOpen, isFalse);
    expect(menu, findsNothing);
    expect(find.text('Image'), findsNothing);
  });

  testWidgets('dragging the menu still works inside it', (tester) async {
    await pump(tester, at: const Offset(50, 50));
    final before = tester.getTopLeft(menu);
    await tester.drag(find.text('Copy'), const Offset(100, 80));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(menu), before + const Offset(100, 80));
  });
}
