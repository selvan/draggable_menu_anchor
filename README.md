# draggable_menu_anchor

A `MenuAnchor`-style pop-up that the user can **drag around the screen**.

`DraggableMenuAnchor` opens where Flutter's `MenuAnchor` would open (at the tap
point, flipped above the button when there's no room below, pushed in from the
screen edges), then lets the user drag it anywhere while keeping it on screen.
It closes like a menu: tap outside, Esc from inside it, or `controller.close()`.

It's built on Flutter's own [`RawMenuAnchor`][raw], the base that
`MenuAnchor` itself is built on. Opening, closing, outside taps and nested
menus are Flutter's; this package adds placement, size limits and dragging.

- No dependencies beyond Flutter (only `package:flutter/widgets.dart`).
- No state-management assumptions: drive it with a `MenuController` and
  callbacks, from `setState`, MobX, Provider, Bloc or anything else.

[raw]: https://api.flutter.dev/flutter/widgets/RawMenuAnchor-class.html

## Contents

- [Install](#install)
- [Quick start](#quick-start)
- [How it behaves](#how-it-behaves)
- [API](#api)
- [Recipes](#recipes)
- [Compared with `MenuAnchor`](#compared-with-menuanchor)
- [Limitations](#limitations)
- [Example app](#example-app)

## Install

```bash
flutter pub add draggable_menu_anchor
```

or in `pubspec.yaml`:

```yaml
dependencies:
  draggable_menu_anchor: ^1.0.1
```

```dart
import 'package:draggable_menu_anchor/draggable_menu_anchor.dart';
```

Requires Flutter 3.32 or later (`RawMenuAnchor`).

## Quick start

Open a panel at the point where the button was tapped:

```dart
class PanelButton extends StatefulWidget {
  const PanelButton({super.key});

  @override
  State<PanelButton> createState() => _PanelButtonState();
}

class _PanelButtonState extends State<PanelButton> {
  final MenuController _controller = MenuController();
  Offset? _tap; // where the finger went down, relative to the button

  @override
  Widget build(BuildContext context) {
    return DraggableMenuAnchor(
      controller: _controller,
      menuChildren: const [
        Card(
          child: SizedBox(
            width: 280,
            height: 160,
            child: Center(child: Text('Drag me')),
          ),
        ),
      ],
      builder: (context, controller, child) => Listener(
        onPointerDown: (e) => _tap = e.localPosition,
        child: FilledButton(
          onPressed: () => controller.isOpen
              ? controller.close()
              : controller.open(position: _tap),
          child: const Text('Open'),
        ),
      ),
    );
  }
}
```

The menu draws **no surface of its own**: give `menuChildren` a background,
for example a `Card` or a `Material` with a shape and elevation.

## How it behaves

### Placement (like `MenuAnchor`)
The first time it opens, the menu's top-left is placed by
`menuAnchorPosition`, which follows `_MenuLayout` in Flutter's
`material/menu_anchor.dart` for a top-level menu:

1. **Start** at the open point: `anchor.topLeft + position`. When `open()`
   gets no position, start at the `alignment` point of the anchor (default:
   its bottom-start corner) plus `alignmentOffset` (default `Offset(0, 6)`,
   a 6px gap below). Start/end alignments follow the text direction.
2. **Horizontally:** wider than the screen → at its left edge. Otherwise,
   past the left or right edge → pushed back in.
3. **Vertically:** taller than the screen → at its top edge.
   - Past the top → just below the anchor (or at the top edge).
   - Past the bottom → **directly above the anchor**, `alignmentOffset.dy`
     clear (or against the bottom edge).

`initialPosition` and `rememberPosition` can override this (see
[Position](#position)).

"The screen" is the overlay minus the system insets (`MediaQuery.padding`,
`viewInsets`, for example the keyboard) minus `screenPadding`.

### Size (like `MenuAnchor`)
The menu is never larger than that area. With `scrollable: true` (the
default) taller content scrolls vertically, as a `MenuAnchor`'s does. Wider
content is constrained, and has to fit itself into the width.

### Dragging
- Drag **anywhere** on the menu to move it, or, with
  `dragFrom: MenuDragFrom.handle`, only from `DraggableMenuHandle`s you
  place inside it (e.g. around a grip icon or title bar). It always stays
  inside the screen.
- Drags follow the finger from where it went down, with no jump by the touch
  slop.
- **Scrollables inside win drags along their own axis.** A horizontal list
  scrolls on sideways drags and the menu moves on vertical ones. This happens
  naturally: their drag slop is half the menu's.
- **Trackpad** two-finger gestures are left to scrolling and never move the
  menu.
- Once placed, the menu **keeps its position when its size changes** (for
  example content expanding), pulled back inside the screen if needed.
- `onDragStart` / `onDragEnd` report drags (one of each per drag), for
  example to show a "lifted" look.

### Position
Positions are the menu's top-left in the overlay's coordinates (the
screen's, for the usual full-screen overlay).
- `onMoved` reports it whenever it changes: when placed after opening
  (reported after that frame), on every drag update, and when pulled back
  inside after a size change.
- Reopening normally places it afresh from the new open point. With
  `rememberPosition: true` it reopens where it was last (for the widget's
  lifetime).
- `initialPosition` opens it at a given spot, e.g. one saved from `onMoved`
  in your own state, so it survives restarts.
- When opening: `initialPosition` comes first, then the remembered
  position, then the placement rules. Every one is kept inside the screen.

### Closing
- **Tap outside:** closes it. The tap is absorbed by default
  (`consumeOutsideTap`), so it doesn't also press what's underneath.
- **Esc** (a `DismissIntent` from a focused widget inside the menu): closes it.
- **`controller.close()`** from code.
- **`onClose`** fires in every case, so you can sync your own state.

### Nested menus
A `MenuAnchor` (or another `DraggableMenuAnchor`) opened from inside
`menuChildren` is part of the same menu system:
- tapping in it doesn't count as outside;
- closing the outer menu closes it;
- a tap outside everything closes them all, as Flutter's nested menus do.

## API

### `DraggableMenuAnchor`

| Parameter | Default | |
|---|---|---|
| `menuChildren` | required | The menu's contents, in a column. |
| `controller` | created internally | A `MenuController` used to `open({position})` and `close()`. |
| `builder` | — | Builds the anchor: `(context, controller, child)`. |
| `child` | — | The anchor, or the `builder`'s child. |
| `onOpen` / `onClose` | — | Called when the menu opens / closes (for any reason). |
| `onDragStart` / `onDragEnd` | — | Called when a drag of the menu starts / ends. |
| `draggable` | `true` | Whether the menu can be dragged at all. |
| `dragFrom` | `MenuDragFrom.anywhere` | `anywhere` on the menu, or only `handle`s (`DraggableMenuHandle`). |
| `onMoved` | — | Called with the menu's top-left whenever it changes. |
| `initialPosition` | — | Open at this top-left (kept inside the screen) instead of placing it. |
| `rememberPosition` | `false` | Reopen where it was last. |
| `consumeOutsideTap` | `true` | Whether the tap that closes the menu is kept from what's underneath. |
| `scrollable` | `true` | Whether content taller than the screen scrolls. |
| `screenPadding` | `EdgeInsets.all(8)` | Space kept between the menu and the screen's safe area. |
| `alignment` | `AlignmentDirectional.bottomStart` | Without an open position: the point on the anchor where the menu's top-left starts. |
| `alignmentOffset` | `Offset(0, 6)` | Added to that point; its `dy` is also the gap when flipped above the anchor. |
| `useRootOverlay` | `false` | Show the menu in the root `Overlay` (see `RawMenuAnchor.useRootOverlay`). |

### `DraggableMenuHandle`
`DraggableMenuHandle(child: …)`: a part of the menu that drags it. It's
required with `dragFrom: MenuDragFrom.handle` and harmless otherwise. It
shows a "grab" cursor; outside a draggable menu it just shows its child.

### `MenuDragFrom`
`anywhere` or `handle`.

### `menuAnchorPosition(...)`
The placement rules on their own, as a pure function, for laying out your own
pop-ups:

```dart
final topLeft = menuAnchorPosition(
  anchor: buttonRect,   // in the same coordinates as bounds
  child: popupSize,
  bounds: safeAreaRect, // where the popup must stay
  position: tapPoint,   // relative to anchor.topLeft; null = use alignment
  alignment: Alignment.bottomLeft,   // MenuAnchor's default
  alignmentOffset: Offset.zero,      // MenuAnchor's default
);
```

### `keepInside(topLeft, size, bounds)`
`topLeft` moved the least needed for a `size` box to fit in `bounds`. A box
bigger than `bounds` sits at its top/left edge.

## Recipes

**Open from code, below the anchor.**
```dart
controller.open(); // no position: alignment + alignmentOffset
```

**Open beside the anchor** (to its right, 8px clear, tops lined up).
```dart
DraggableMenuAnchor(
  alignment: AlignmentDirectional.topEnd,
  alignmentOffset: const Offset(8, 0),
  // … then controller.open() with no position
);
```

**Drag only by a grip.**
```dart
DraggableMenuAnchor(
  dragFrom: MenuDragFrom.handle,
  menuChildren: [
    Card(child: Column(children: [
      const DraggableMenuHandle(child: Icon(Icons.drag_indicator)),
      // … content that doesn't move the menu
    ])),
  ],
);
```

**Remember where the user left it.**
```dart
// For the widget's lifetime:
DraggableMenuAnchor(rememberPosition: true, /* … */);

// Across restarts: keep it in your own state.
DraggableMenuAnchor(
  initialPosition: settings.panelPosition,
  onMoved: (topLeft) => settings.panelPosition = topLeft,
  // …
);
```

**Keep open/closed in your own state** (MobX, Provider, …).
```dart
DraggableMenuAnchor(
  controller: controller,
  onClose: () => myState.menuOpen = false, // the user closed it
  // …
);
// When your state changes (after the frame, e.g. from a post-frame callback):
myState.menuOpen ? controller.open(position: at) : controller.close();
```

**Share an anchor with another menu.** Stack the two anchors over the same
widget. Make the second one's anchor transparent to touches:
```dart
Stack(children: [
  MenuAnchor(/* list menu */ builder: (_, c, __) => myButton),
  Positioned.fill(
    child: DraggableMenuAnchor(
      controller: panelController,
      menuChildren: [panel],
      child: const IgnorePointer(child: SizedBox.expand()),
    ),
  ),
]);
```

**Not draggable, just `MenuAnchor` placement for any widget.** Set
`draggable: false`.

## Compared with `MenuAnchor`

| | `MenuAnchor` | `DraggableMenuAnchor` |
|---|---|---|
| Open/close, outside tap, nested menus | ✓ | ✓ (same `RawMenuAnchor` base) |
| Placement at tap / flip above / push in | ✓ | ✓ (same rules) |
| Size limited to screen, scroll when taller | ✓ | ✓ |
| Draggable after opening | — | ✓ |
| Keeps position when content resizes | — (re-placed) | ✓ |
| `alignment` / `alignmentOffset` | ✓ | ✓ |
| Drag from a grip only | — | ✓ (`DraggableMenuHandle`) |
| Report / restore / remember position | — | ✓ |
| Menu surface (background, elevation, padding) | `MenuStyle` | your `menuChildren` |
| Keyboard arrow-key traversal of items | ✓ | — |
| Open/close animation | ✓ | — |

## Limitations

- **Right-to-left:** `alignment` follows the text direction, but the
  push-in rules and the open `position` work the same in both directions.
- **No open/close animation**, and no `MenuStyle`; style the contents
  yourself.
- **Display features** (hinge/fold areas) aren't avoided, unlike
  `MenuAnchor`.

## Example app

[`example/`](example/) has:
- buttons in the centre and the four corners, each opening a draggable panel
  at the tap point;
- "Grip only (remembers spot)": `dragFrom: handle` + `rememberPosition`;
- "Right of button": opened from code with `alignment: topEnd`;
- "Tall menu": content taller than the screen, scrolling;
- a nested `MenuAnchor` inside the panel;
- a log of the callbacks and the latest `onMoved` position.

```bash
cd example
flutter run
```

## Tests

```bash
flutter test            # placement rules + widget behaviour
cd example && flutter test
```
