# draggable_menu_anchor example

A small app showing [`DraggableMenuAnchor`](../README.md):

- **Tap anywhere** on the screen: a vertical menu opens at that point. Near
  an edge it's placed the way a `MenuAnchor` would be, kept on screen.
- The menu and its submenus are `DraggableMenuSurface`s: styled by the
  app's `MenuTheme`, like Flutter's own menus.
- The ☀/☾ button (top right) switches between light and dark themes. It
  leaves an open menu open, so you can watch the menu, its grip and its
  submenus restyle with the theme.
- **Drag** the menu to move it anywhere (the dotted band along its top is a
  `DraggableMenuGrip`); it stays on screen.
- **Insert** and **Arrange** open submenus beside it, flipping to the left
  near the right edge (`DraggableSubmenu`s with material rows, part of the
  same menu).
- Choosing an item closes the menu and shows the choice; a tap outside the
  menu just closes it.

```bash
cd example
flutter run
```
