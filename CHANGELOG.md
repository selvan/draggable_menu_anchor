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
