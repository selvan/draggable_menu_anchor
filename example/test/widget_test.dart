import 'package:draggable_menu_anchor/material.dart';
import 'package:draggable_menu_anchor_example/main.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final menu = find.byKey(const ValueKey<String>('example-menu'));
  final chosen = find.byKey(const ValueKey<String>('chosen'));

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ExampleApp());
  }

  testWidgets('opens at the tap point, drags, closes on an outside tap', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text('Tap anywhere'), findsOneWidget);
    expect(menu, findsNothing);

    const tap = Offset(120, 90);
    await tester.tapAt(tap);
    await tester.pumpAndSettle();
    expect(menu, findsOneWidget);
    expect(tester.getTopLeft(menu), tap);

    await tester.drag(find.text('Copy'), const Offset(150, 100));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(menu),
      offsetMoreOrLessEquals(tap + const Offset(150, 100)),
    );
    expect(menu, findsOneWidget);

    // The grip drags it too.
    final grip = find.byKey(const ValueKey<String>('example-grip'));
    expect(grip, findsOneWidget);
    final before = tester.getTopLeft(menu);
    await tester.drag(grip, const Offset(-60, 40));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(menu),
      offsetMoreOrLessEquals(before + const Offset(-60, 40)),
    );

    // A tap outside it closes it; the next one opens it again, there.
    await tester.tapAt(const Offset(780, 580));
    await tester.pumpAndSettle();
    expect(menu, findsNothing);
    await tester.tapAt(const Offset(300, 200));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(menu), const Offset(300, 200));
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(menu, findsNothing);
    expect(chosen, findsOneWidget);
    expect(tester.widget<Text>(chosen).data, 'Nothing chosen yet');
  });

  testWidgets('submenus open beside it; choosing closes everything', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tapAt(const Offset(100, 100));
    await tester.pumpAndSettle();

    expect(find.text('Image'), findsNothing);
    await tester.tap(find.text('Insert'));
    await tester.pumpAndSettle();
    expect(find.text('Image'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Image')).dx,
      greaterThan(tester.getTopRight(menu).dx - 1),
    );

    await tester.tap(find.text('Image'));
    await tester.pumpAndSettle();
    expect(menu, findsNothing);
    expect(find.text('Image'), findsNothing);
    expect(tester.widget<Text>(chosen).data, 'Chosen: Image');

    // The other submenu, from a tap near the bottom-right corner: the menu
    // is pushed back inside the screen.
    await tester.tapAt(const Offset(790, 590));
    await tester.pumpAndSettle();
    final rect = tester.getRect(menu);
    expect(rect.right, lessThanOrEqualTo(800));
    expect(rect.bottom, lessThanOrEqualTo(600));
    await tester.tap(find.text('Arrange'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send to back'));
    await tester.pumpAndSettle();
    expect(menu, findsNothing);
    expect(tester.widget<Text>(chosen).data, 'Chosen: Send to back');
  });

  testWidgets('near the right edge a submenu flips to the left', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tapAt(const Offset(760, 100));
    await tester.pumpAndSettle();
    final menuRect = tester.getRect(menu);
    expect(menuRect.right, lessThanOrEqualTo(800));

    await tester.tap(find.text('Insert'));
    await tester.pumpAndSettle();
    final image = tester.getRect(find.widgetWithText(MenuItemButton, 'Image'));
    // On the menu's left, not pushed over it.
    expect(image.right, lessThanOrEqualTo(menuRect.left + 1));
  });

  testWidgets('the theme switch restyles the open menu and its submenu', (
    tester,
  ) async {
    await pumpApp(tester);
    final toggle = find.byKey(const ValueKey<String>('theme-toggle'));

    Color? panelColor(Finder panel) => tester
        .widget<Material>(
          find.descendant(of: panel, matching: find.byType(Material)).first,
        )
        .color;
    Color surfaceContainer(Brightness brightness) => ThemeData(
      colorSchemeSeed: Colors.indigo,
      brightness: brightness,
    ).colorScheme.surfaceContainer;

    await tester.tapAt(const Offset(100, 100));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Insert'));
    await tester.pumpAndSettle();
    final submenu = find.ancestor(
      of: find.text('Image'),
      matching: find.byType(DraggableMenuSurface),
    );
    expect(panelColor(menu), surfaceContainer(Brightness.dark));
    expect(panelColor(submenu), surfaceContainer(Brightness.dark));

    // The switch is on the anchor: tapping it leaves the menu open.
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(menu, findsOneWidget);
    expect(find.text('Image'), findsOneWidget);
    expect(panelColor(menu), surfaceContainer(Brightness.light));
    expect(panelColor(submenu), surfaceContainer(Brightness.light));

    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(panelColor(menu), surfaceContainer(Brightness.dark));
  });

  testWidgets('tapping an open submenu\'s row closes it', (tester) async {
    await pumpApp(tester);
    await tester.tapAt(const Offset(100, 100));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Insert'));
    await tester.pumpAndSettle();
    expect(find.text('Image'), findsOneWidget);

    await tester.tap(find.text('Insert'));
    await tester.pumpAndSettle();
    expect(find.text('Image'), findsNothing);
    expect(menu, findsOneWidget);

    // And again opens it.
    await tester.tap(find.text('Insert'));
    await tester.pumpAndSettle();
    expect(find.text('Image'), findsOneWidget);
  });
}

