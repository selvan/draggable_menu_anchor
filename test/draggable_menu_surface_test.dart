import 'package:draggable_menu_anchor/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const surfaceKey = ValueKey<String>('surface');
  final surface = find.byKey(surfaceKey);

  /// The [Material] that draws [panel] (its nearest one).
  Material materialOf(WidgetTester tester, Finder panel) => tester
      .widgetList<Material>(
        find.descendant(of: panel, matching: find.byType(Material)),
      )
      .first;

  /// A [MenuAnchor] and a [DraggableMenuAnchor] side by side, both open,
  /// with one item each, under [theme].
  Future<void> pumpBoth(
    WidgetTester tester, {
    required ThemeData theme,
    MenuStyle? style,
    Widget? header,
  }) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final real = MenuController();
    final ours = MenuController();
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              MenuAnchor(
                controller: real,
                style: style,
                menuChildren: <Widget>[
                  MenuItemButton(onPressed: () {}, child: const Text('Real')),
                ],
                child: const SizedBox(width: 10, height: 10),
              ),
              const SizedBox(width: 390),
              DraggableMenuAnchor(
                controller: ours,
                menuChildren: <Widget>[
                  DraggableMenuSurface(
                    key: surfaceKey,
                    style: style,
                    header: header,
                    children: <Widget>[
                      MenuItemButton(
                        onPressed: () {},
                        child: const Text('Ours'),
                      ),
                    ],
                  ),
                ],
                child: const SizedBox(width: 10, height: 10),
              ),
            ],
          ),
        ),
      ),
    );
    real.open();
    ours.open();
    await tester.pumpAndSettle();
  }

  /// The real menu's panel [Material]: the nearest one above its item.
  Material realPanel(WidgetTester tester) => tester
      .widgetList<Material>(
        find.ancestor(of: find.text('Real'), matching: find.byType(Material)),
      )
      .firstWhere((m) => m.type == MaterialType.canvas);

  void expectSameLook(WidgetTester tester) {
    final real = realPanel(tester);
    final ours = materialOf(tester, surface);
    expect(ours.color, real.color);
    expect(ours.elevation, real.elevation);
    expect(ours.shadowColor, real.shadowColor);
    expect(ours.surfaceTintColor, real.surfaceTintColor);
    expect(ours.shape, real.shape);
    expect(ours.clipBehavior, real.clipBehavior);
    // Same padding: the item sits as far inside the panel.
    final realItem = tester.getRect(
      find.widgetWithText(MenuItemButton, 'Real'),
    );
    final oursItem = tester.getRect(
      find.widgetWithText(MenuItemButton, 'Ours'),
    );
    final realPanelRect = tester.getRect(
      find
          .ancestor(of: find.text('Real'), matching: find.byType(Material))
          .at(1),
    );
    final oursRect = tester.getRect(surface);
    expect(oursItem.top - oursRect.top, realItem.top - realPanelRect.top);
    expect(
      oursRect.bottom - oursItem.bottom,
      realPanelRect.bottom - realItem.bottom,
    );
  }

  testWidgets('looks like a MenuAnchor by default (light)', (tester) async {
    await pumpBoth(tester, theme: ThemeData.light());
    expectSameLook(tester);
    final ours = materialOf(tester, surface);
    expect(ours.color, ThemeData.light().colorScheme.surfaceContainer);
    expect(ours.elevation, 3);
  });

  testWidgets('follows the theme (dark)', (tester) async {
    await pumpBoth(tester, theme: ThemeData.dark());
    expectSameLook(tester);
    expect(
      materialOf(tester, surface).color,
      ThemeData.dark().colorScheme.surfaceContainer,
    );
  });

  testWidgets('follows the MenuTheme', (tester) async {
    await pumpBoth(
      tester,
      theme: ThemeData(
        menuTheme: const MenuThemeData(
          style: MenuStyle(
            backgroundColor: WidgetStatePropertyAll<Color>(Color(0xFF123456)),
            elevation: WidgetStatePropertyAll<double>(12),
            shape: WidgetStatePropertyAll<OutlinedBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
            padding: WidgetStatePropertyAll<EdgeInsets>(
              EdgeInsets.symmetric(vertical: 20),
            ),
          ),
        ),
      ),
    );
    expectSameLook(tester);
    final ours = materialOf(tester, surface);
    expect(ours.color, const Color(0xFF123456));
    expect(ours.elevation, 12);
  });

  testWidgets('style overrides the theme, as MenuAnchor.style does', (
    tester,
  ) async {
    await pumpBoth(
      tester,
      theme: ThemeData(
        menuTheme: const MenuThemeData(
          style: MenuStyle(
            backgroundColor: WidgetStatePropertyAll<Color>(Color(0xFF123456)),
          ),
        ),
      ),
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll<Color>(Color(0xFF654321)),
        side: WidgetStatePropertyAll<BorderSide>(
          BorderSide(color: Color(0xFFFF0000), width: 2),
        ),
      ),
    );
    expectSameLook(tester);
    expect(materialOf(tester, surface).color, const Color(0xFF654321));
  });

  testWidgets('header: flush with the top and sides, no top padding', (
    tester,
  ) async {
    const headerKey = ValueKey<String>('header');
    await pumpBoth(
      tester,
      theme: ThemeData.light(),
      header: const SizedBox(key: headerKey, height: 12),
    );
    final panel = tester.getRect(surface);
    final header = tester.getRect(find.byKey(headerKey));
    expect(header.top, panel.top);
    expect(header.left, panel.left);
    expect(header.right, panel.right);
    expect(
      tester.getRect(find.widgetWithText(MenuItemButton, 'Ours')).top,
      header.bottom,
    );
  });

  testWidgets('SubmenuButtons in it open beside the menu', (tester) async {
    tester.view.physicalSize = const Size(600, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = MenuController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DraggableMenuAnchor(
            controller: controller,
            menuChildren: <Widget>[
              DraggableMenuSurface(
                key: surfaceKey,
                children: <Widget>[
                  SubmenuButton(
                    menuChildren: <Widget>[
                      MenuItemButton(
                        onPressed: () {},
                        child: const Text('Image'),
                      ),
                    ],
                    child: const Text('Insert'),
                  ),
                ],
              ),
            ],
            child: const SizedBox(width: 10, height: 10),
          ),
        ),
      ),
    );
    controller.open(position: const Offset(50, 50));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Insert'));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.widgetWithText(MenuItemButton, 'Image')).left,
      greaterThanOrEqualTo(tester.getRect(surface).right - 1),
    );
  });
}
