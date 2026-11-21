import 'package:draggable_menu_anchor_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('opens at the tap, drags, closes on an outside tap', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ExampleApp());

    final button = find.widgetWithText(FilledButton, 'Open panel');
    final tap = tester.getTopLeft(button) + const Offset(20, 10);
    await tester.tapAt(tap);
    await tester.pumpAndSettle();
    final panel = find.byKey(const ValueKey<String>('demo-panel'));
    expect(panel, findsOneWidget);
    expect(tester.getTopLeft(panel), tap);
    expect(find.text('Open panel: opened'), findsOneWidget);

    await tester.drag(
      find.byIcon(Icons.drag_indicator),
      const Offset(-100, 80),
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(panel), tap + const Offset(-100, 80));
    expect(find.text('Open panel: drag ended'), findsOneWidget);

    await tester.tapAt(const Offset(780, 880));
    await tester.pumpAndSettle();
    expect(panel, findsNothing);
    expect(find.text('Open panel: closed'), findsOneWidget);
  });

  testWidgets('tall content fits the screen and scrolls', (tester) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ExampleApp());

    await tester.tap(find.widgetWithText(FilledButton, 'Tall menu'));
    await tester.pumpAndSettle();
    final tall = find.byKey(const ValueKey<String>('tall-panel'));
    final scroll = find
        .ancestor(of: tall, matching: find.byType(Scrollable))
        .first;
    expect(tester.getSize(scroll).height, lessThanOrEqualTo(900 - 16));
    expect(
      tester.state<ScrollableState>(scroll).position.maxScrollExtent,
      greaterThan(0),
    );
  });

  testWidgets('Right of button: opens beside the button', (tester) async {
    // Wide enough for the 300px panel to fit right of the centred button.
    tester.view.physicalSize = const Size(1100, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ExampleApp());

    final button = find.widgetWithText(FilledButton, 'Right of button');
    final buttonRect = tester.getRect(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    final panel = find.byKey(const ValueKey<String>('demo-panel'));
    expect(
      tester.getTopLeft(panel),
      Offset(buttonRect.right + 8, buttonRect.top),
    );
  });

  testWidgets('Grip only: body drags do nothing; reopens where left', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ExampleApp());

    final button = find.widgetWithText(
      FilledButton,
      'Grip only (remembers spot)',
    );
    await tester.tap(button);
    await tester.pumpAndSettle();
    final panel = find.byKey(const ValueKey<String>('demo-panel'));
    final start = tester.getTopLeft(panel);

    // The hint text inside the panel isn't a handle.
    await tester.drag(
      find.descendant(
        of: panel,
        matching: find.textContaining('Drag anywhere'),
      ),
      const Offset(0, 80),
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(panel), start);

    await tester.drag(find.byIcon(Icons.drag_indicator), const Offset(-60, 90));
    await tester.pumpAndSettle();
    final left = tester.getTopLeft(panel);
    expect(left, start + const Offset(-60, 90));
    expect(find.textContaining('onMoved: Grip only'), findsOneWidget);

    await tester.tapAt(const Offset(790, 990)); // outside: close
    await tester.pumpAndSettle();
    expect(panel, findsNothing);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(panel), left);
  });
}
