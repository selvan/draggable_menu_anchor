import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:draggable_menu_anchor/draggable_menu_anchor.dart';

void main() {
  const screen = Size(400, 800);
  const menuKey = ValueKey<String>('menu');

  /// A button at [buttonAt] that opens a 200×[menuHeight] menu at the tap.
  Future<MenuController> pump(
    WidgetTester tester, {
    Offset buttonAt = const Offset(50, 100),
    double menuHeight = 300,
    List<Widget> extra = const <Widget>[],
    VoidCallback? onUnderneathTap,
    AlignmentGeometry alignment = AlignmentDirectional.bottomStart,
    Offset alignmentOffset = const Offset(0, 6),
    MenuDragFrom dragFrom = MenuDragFrom.anywhere,
    ValueChanged<Offset>? onMoved,
    VoidCallback? onDragStart,
    VoidCallback? onDragEnd,
    Offset? initialPosition,
    bool rememberPosition = false,
    TextDirection textDirection = TextDirection.ltr,
  }) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = MenuController();
    Offset? down;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            Directionality(textDirection: textDirection, child: child!),
        home: Scaffold(
          body: Stack(
            children: <Widget>[
              Positioned.fill(
                child: GestureDetector(
                  key: const ValueKey<String>('underneath'),
                  behavior: HitTestBehavior.opaque,
                  onTap: onUnderneathTap,
                ),
              ),
              Positioned(
                left: buttonAt.dx,
                top: buttonAt.dy,
                child: DraggableMenuAnchor(
                  controller: controller,
                  alignment: alignment,
                  alignmentOffset: alignmentOffset,
                  dragFrom: dragFrom,
                  onMoved: onMoved,
                  onDragStart: onDragStart,
                  onDragEnd: onDragEnd,
                  initialPosition: initialPosition,
                  rememberPosition: rememberPosition,
                  menuChildren: <Widget>[
                    Container(
                      key: menuKey,
                      width: 200,
                      height: menuHeight,
                      color: Colors.blue,
                    ),
                    ...extra,
                  ],
                  builder: (context, c, _) => Listener(
                    onPointerDown: (e) => down = e.localPosition,
                    child: SizedBox(
                      width: 120,
                      height: 40,
                      child: TextButton(
                        key: const ValueKey<String>('button'),
                        onPressed: () => c.open(position: down),
                        child: const Text('open'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return controller;
  }

  Rect menuRect(WidgetTester tester) => tester.getRect(find.byKey(menuKey));

  testWidgets('opens at the tap point', (tester) async {
    await pump(tester);
    await tester.tapAt(const Offset(60, 110)); // (10, 10) into the button
    await tester.pumpAndSettle();
    expect(menuRect(tester).topLeft, const Offset(60, 110));
  });

  testWidgets('near the bottom: directly above the button', (tester) async {
    await pump(tester, buttonAt: const Offset(50, 700));
    await tester.tapAt(const Offset(60, 710));
    await tester.pumpAndSettle();
    expect(menuRect(tester).bottom, 700 - 6);
    expect(menuRect(tester).left, 60);
  });

  testWidgets('drag moves it and keeps it on screen', (tester) async {
    final controller = await pump(tester);
    await tester.tapAt(const Offset(60, 110));
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(menuKey), const Offset(40, 100));
    await tester.pumpAndSettle();
    expect(menuRect(tester).topLeft, const Offset(100, 210));
    // Far past the bottom-right: stops 8px inside.
    await tester.drag(find.byKey(menuKey), const Offset(2000, 2000));
    await tester.pumpAndSettle();
    expect(
      menuRect(tester).bottomRight,
      Offset(screen.width - 8, screen.height - 8),
    );
    expect(controller.isOpen, isTrue, reason: 'dragging keeps it open');
    // Still interactive where it was dragged to.
    await tester.tapAt(menuRect(tester).center);
    await tester.pumpAndSettle();
    expect(controller.isOpen, isTrue, reason: 'a tap inside keeps it open');
  });

  testWidgets('outside tap closes it without reaching what is underneath', (
    tester,
  ) async {
    var underneath = 0;
    final controller = await pump(tester, onUnderneathTap: () => underneath++);
    await tester.tapAt(const Offset(60, 110));
    await tester.pumpAndSettle();
    expect(controller.isOpen, isTrue);
    await tester.tapAt(const Offset(390, 790));
    await tester.pumpAndSettle();
    expect(controller.isOpen, isFalse);
    expect(find.byKey(menuKey), findsNothing);
    expect(underneath, 0);
  });

  testWidgets('a MenuAnchor opened inside counts as inside', (tester) async {
    final controller = await pump(
      tester,
      menuHeight: 100,
      extra: <Widget>[
        MenuAnchor(
          menuChildren: <Widget>[
            MenuItemButton(onPressed: () {}, child: const Text('inner item')),
          ],
          builder: (context, c, _) =>
              TextButton(onPressed: c.open, child: const Text('inner')),
        ),
      ],
    );
    await tester.tapAt(const Offset(60, 110));
    await tester.pumpAndSettle();
    await tester.tap(find.text('inner'));
    await tester.pumpAndSettle();
    expect(find.text('inner item'), findsOneWidget);
    await tester.tap(find.text('inner item'));
    await tester.pumpAndSettle();
    expect(find.text('inner item'), findsNothing);
    expect(controller.isOpen, isTrue);
  });

  testWidgets('taller than the screen: fits, and scrolls', (tester) async {
    await pump(tester, menuHeight: 2000);
    await tester.tapAt(const Offset(60, 110));
    await tester.pumpAndSettle();
    final scroll = find.ancestor(
      of: find.byKey(menuKey),
      matching: find.byType(Scrollable),
    );
    final viewport = tester.getRect(scroll);
    expect(viewport.top, 8);
    expect(viewport.height, screen.height - 16);
    expect(
      tester.state<ScrollableState>(scroll).position.maxScrollExtent,
      greaterThan(0),
    );
  });

  testWidgets('alignment + offset: opened from code, right of the button', (
    tester,
  ) async {
    final controller = await pump(
      tester,
      alignment: AlignmentDirectional.topEnd,
      alignmentOffset: const Offset(8, 0),
    );
    controller.open(); // no position: placed by alignment
    await tester.pumpAndSettle();
    // Button: (50, 100) 120×40 → its top-right is (170, 100).
    expect(menuRect(tester).topLeft, const Offset(178, 100));
  });

  testWidgets('alignment follows right-to-left text', (tester) async {
    final controller = await pump(
      tester,
      buttonAt: const Offset(250, 100),
      alignmentOffset: Offset.zero,
      textDirection: TextDirection.rtl,
    );
    controller.open();
    await tester.pumpAndSettle();
    // bottomStart in RTL is the button's bottom-right: (370, 140).
    expect(menuRect(tester).topLeft.dy, 140);
    expect(
      menuRect(tester).left,
      392 - 200,
      reason: 'starts at x=370, pushed in from the right edge',
    );
  });

  testWidgets('dragFrom.handle: only DraggableMenuHandle moves it', (
    tester,
  ) async {
    final controller = await pump(
      tester,
      dragFrom: MenuDragFrom.handle,
      menuHeight: 100,
      extra: const <Widget>[
        DraggableMenuHandle(
          child: SizedBox(
            key: ValueKey<String>('grip'),
            width: 200,
            height: 30,
          ),
        ),
      ],
    );
    controller.open();
    await tester.pumpAndSettle();
    final start = menuRect(tester).topLeft;
    await tester.drag(find.byKey(menuKey), const Offset(40, 60));
    await tester.pumpAndSettle();
    expect(menuRect(tester).topLeft, start, reason: 'body drags do nothing');
    await tester.drag(
      find.byKey(const ValueKey<String>('grip')),
      const Offset(40, 60),
    );
    await tester.pumpAndSettle();
    expect(menuRect(tester).topLeft, start + const Offset(40, 60));
  });

  testWidgets('a handle outside a menu just shows its child', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: DraggableMenuHandle(child: Text('grip')),
      ),
    );
    expect(find.text('grip'), findsOneWidget);
  });

  testWidgets('onMoved: reports the placement, then each drag', (tester) async {
    final moves = <Offset>[];
    await pump(tester, onMoved: moves.add);
    await tester.tapAt(const Offset(60, 110));
    await tester.pumpAndSettle();
    expect(moves, <Offset>[const Offset(60, 110)]);
    await tester.drag(find.byKey(menuKey), const Offset(30, 40));
    await tester.pumpAndSettle();
    expect(moves.last, const Offset(90, 150));
    expect(moves.length, greaterThan(1));
  });

  testWidgets('rememberPosition: reopens where it was left', (tester) async {
    final controller = await pump(tester, rememberPosition: true);
    await tester.tapAt(const Offset(60, 110));
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(menuKey), const Offset(100, 200));
    await tester.pumpAndSettle();
    final left = menuRect(tester).topLeft;
    expect(left, const Offset(160, 310));
    controller.close();
    await tester.pumpAndSettle();
    // Reopen from a different tap point: still where it was left.
    await tester.tapAt(const Offset(150, 130));
    await tester.pumpAndSettle();
    expect(menuRect(tester).topLeft, left);
  });

  testWidgets('without rememberPosition: placed afresh', (tester) async {
    final controller = await pump(tester);
    await tester.tapAt(const Offset(60, 110));
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(menuKey), const Offset(100, 200));
    await tester.pumpAndSettle();
    controller.close();
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(60, 110));
    await tester.pumpAndSettle();
    expect(menuRect(tester).topLeft, const Offset(60, 110));
  });

  testWidgets('initialPosition: opens there, kept inside the screen', (
    tester,
  ) async {
    final controller = await pump(
      tester,
      initialPosition: const Offset(120, 400),
    );
    controller.open(position: const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(menuRect(tester).topLeft, const Offset(120, 400));
    controller.close();
    await tester.pumpAndSettle();

    final outside = await pump(tester, initialPosition: const Offset(350, 700));
    outside.open();
    await tester.pumpAndSettle();
    // 200×300 menu, screen 400×800 less 8px: pulled in to (192, 492).
    expect(menuRect(tester).topLeft, const Offset(192, 492));
  });

  testWidgets('a handle in a drag-anywhere menu: one start, one end', (
    tester,
  ) async {
    var starts = 0;
    var ends = 0;
    final controller = await pump(
      tester,
      menuHeight: 100,
      onDragStart: () => starts++,
      onDragEnd: () => ends++,
      extra: const <Widget>[
        DraggableMenuHandle(
          child: SizedBox(
            key: ValueKey<String>('grip'),
            width: 200,
            height: 30,
          ),
        ),
      ],
    );
    controller.open();
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey<String>('grip')),
      const Offset(20, 30),
    );
    await tester.pumpAndSettle();
    expect(starts, 1);
    expect(ends, 1);
  });
}
