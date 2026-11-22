# draggable_menu_anchor example

A small app showing [`DraggableMenuAnchor`](../README.md):

- **Tap anywhere** on the screen: a vertical menu opens at that point. Near
  an edge it's placed the way a `MenuAnchor` would be, kept on screen.
- **Drag** the menu to move it anywhere; it stays on screen.
- **Insert** and **Arrange** open submenus beside it, flipping to the left
  near the right edge (`DraggableSubmenu`s with material rows, part of the
  same menu).
- Choosing an item closes the menu and shows the choice; a tap outside the
  menu just closes it.

```bash
cd example
flutter run
```
