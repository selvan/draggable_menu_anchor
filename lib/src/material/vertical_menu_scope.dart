import 'package:flutter/material.dart';

/// Makes the [SubmenuButton]s inside [child] behave as items of a vertical
/// menu, as they do in a [MenuAnchor]'s menu: their submenus open beside the
/// menu (to the right, or left in right-to-left text) and flip to the other
/// side when there's no room, before being pushed in from the screen edge.
///
/// Wrap a [DraggableMenuAnchor]'s menu contents in it:
///
/// ```dart
/// DraggableMenuAnchor(
///   menuChildren: [
///     Material(
///       child: VerticalMenuScope(
///         child: Column(children: [
///           MenuItemButton(child: Text('Copy'), onPressed: copy),
///           SubmenuButton(menuChildren: [/* … */], child: Text('Insert')),
///         ]),
///       ),
///     ),
///   ],
/// )
/// ```
///
/// Without it a [SubmenuButton] there has no material menu around it, so it
/// acts like an item of a menu bar: its submenu opens below it and is only
/// pushed in at the screen edge.
///
/// It works by placing [child] inside an empty [MenuAnchor] (which is never
/// opened): Flutter's submenus look for the nearest [MenuAnchor] to learn
/// their parent menu's orientation, and a [MenuAnchor]'s is vertical.
class VerticalMenuScope extends StatelessWidget {
  const VerticalMenuScope({super.key, required this.child});

  /// The menu's contents, e.g. a [Column] of [MenuItemButton]s and
  /// [SubmenuButton]s.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      menuChildren: const <Widget>[],
      builder: (context, controller, child) => child!,
      child: child,
    );
  }
}
