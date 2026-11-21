# draggable_menu_anchor example

A small app showing [`DraggableMenuAnchor`](../README.md):

- **Open panel** (centre) and the four **corner** buttons open a draggable
  panel at the point you tap. Near the bottom or a side it's placed the way
  a `MenuAnchor` would be: above the button, pushed in from the edge.
- Drag the panel anywhere; it stays on screen. The chip row inside scrolls
  sideways; dragging it up/down moves the panel instead.
- **More ▾** inside the panel opens a nested `MenuAnchor`, which counts as
  part of the panel.
- **Tall menu** opens content taller than the screen: it's limited to the
  screen and scrolls.
- The event log at the bottom shows `onOpen`, `onClose`, `onDragStart` and
  `onDragEnd`.

```bash
cd example
flutter run
```
