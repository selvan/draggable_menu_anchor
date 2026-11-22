## 2.0.0

- **Requires Flutter 3.47 / Dart 3.13.** The `material.dart` helpers
  (`DraggableMenuSurface`, `VerticalMenuScope`) are built on
  [`material_ui`](https://pub.dev/packages/material_ui), Flutter's Material
  library package, so they follow a `material_ui` app's theme. The package
  now depends on `material_ui`; the main library still uses only
  `package:flutter/widgets.dart`. The example uses `material_ui`.
- `DraggableMenuSurface` (`material.dart`): a menu panel styled exactly like
  a `MenuAnchor`'s, from its `style`, the app's `MenuTheme` and Material 3's
  defaults. Optional flush `header` (e.g. a `DraggableMenuGrip`); material
  `SubmenuButton`s in it open beside the menu (`verticalSubmenus`, on by
  default).
- `DraggableMenuGrip`: a ready-made grip (a band of tiny staggered dots
  across the menu's width) that drags the menu. Colours, dot size, rows and
  padding are adjustable; any widget in a `DraggableMenuHandle` still works
  as a custom grip.
- `DraggableSubmenu`: a submenu for the menu that needs neither material nor
  Cupertino. Opens beside its row and flips to the other side near the
  screen edge; part of the menu (outside taps, closing, siblings, nesting).
- `submenuPosition`: its placement rules as a pure function.
- Dragging the menu now closes its open submenus (they'd otherwise stay
  where they opened).
- `VerticalMenuScope` (new library `package:draggable_menu_anchor/material.dart`):
  material `SubmenuButton`s in a draggable menu open beside it and flip to
  the other side near the screen edge, as in a `MenuAnchor`'s menu.
- Example: one screen, tap anywhere to open a menu (a
  `DraggableMenuSurface` with a grip) with two submenus (`DraggableSubmenu`s),
  and a light/dark switch showing it follow the theme.

## 1.0.1

- First stable release; the API is unchanged from 0.2.0.
- pub.dev metadata: MIT license, repository, issue tracker and topics.
- README: install from pub.dev.

## 0.2.0

- **Breaking:** `gap` is replaced by `alignment` (default
  `AlignmentDirectional.bottomStart`) and `alignmentOffset` (default
  `Offset(0, 6)`, the old 6px gap), as on `MenuAnchor`. Replace `gap: g` with
  `alignmentOffset: Offset(0, g)`. `menuAnchorPosition` takes
  `alignment` / `alignmentOffset` instead of `gap` (defaults: `MenuAnchor`'s).
- `dragFrom` (`MenuDragFrom.anywhere` / `handle`) and `DraggableMenuHandle`:
  drag only from a grip.
- `onMoved`, `initialPosition`, `rememberPosition`: report, set and remember
  the menu's position.
- Fix: a `DraggableMenuHandle` in a drag-anywhere menu reported
  `onDragEnd` twice.

## 0.1.0

- `DraggableMenuAnchor`: a draggable `MenuAnchor`-style pop-up on
  `RawMenuAnchor`.
- `menuAnchorPosition` (MenuAnchor's placement rules) and `keepInside`.
- Example app (`example/`) and full README.
