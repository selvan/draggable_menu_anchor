import 'package:flutter/widgets.dart';

import 'menu_placement.dart';

/// A submenu for a [DraggableMenuAnchor] (or any menu built on
/// [RawMenuAnchor]) that doesn't depend on material or Cupertino.
///
/// Put it in the menu as one of its rows. Its [menuChildren] open **beside**
/// the menu, level with the row, and **flip to the other side** when there's
/// no room (see [submenuPosition]), like a `SubmenuButton` in a `MenuAnchor`.
/// It draws nothing itself: style the row and the submenu's surface yourself.
///
/// ```dart
/// DraggableSubmenu(
///   menuChildren: [
///     MyMenuSurface(child: Column(children: [ /* rows */ ])),
///   ],
///   child: const MyMenuRow(label: 'Insert', trailing: Icon(Icons.chevron_right)),
/// )
/// ```
///
/// With [child] alone, a tap on it opens the submenu (and closes it again).
/// For other triggers (hover, a button inside the row, …) use [builder],
/// which gets the submenu's [MenuController].
///
/// It's part of the menu it sits in:
///  * opening it closes any other open submenu of that menu;
///  * taps in it don't count as outside the menu;
///  * closing the menu (or dragging it) closes it;
///  * a tap outside everything closes them all;
///  * Esc from inside it closes just the submenu.
///
/// Choosing an item doesn't close anything by itself: close the menu (its
/// controller) when an item is chosen.
///
/// Submenus can be nested: a [DraggableSubmenu] inside [menuChildren] opens
/// beside this one.
class DraggableSubmenu extends StatefulWidget {
  const DraggableSubmenu({
    super.key,
    required this.menuChildren,
    this.controller,
    this.builder,
    this.child,
    this.onOpen,
    this.onClose,
    this.offset = Offset.zero,
    this.screenPadding = const EdgeInsets.all(8),
    this.scrollable = true,
  }) : assert(
         builder != null || child != null,
         'Give a child (the row) or a builder.',
       );

  /// The submenu's contents, in a column. Give them a surface (background,
  /// shape, shadow): the submenu draws none.
  final List<Widget> menuChildren;

  /// Opens and closes the submenu. Created internally if not given.
  final MenuController? controller;

  /// Builds the row the submenu belongs to, given its controller. Without
  /// it, [child] is the row and a tap on it toggles the submenu.
  final RawMenuAnchorChildBuilder? builder;

  /// The row (or the [builder]'s child).
  final Widget? child;

  /// Called when the submenu opens / closes (for any reason).
  final VoidCallback? onOpen;
  final VoidCallback? onClose;

  /// Moves the submenu from its usual spot: `dx` is the gap from the row's
  /// side (both sides, when it flips), `dy` shifts it down from the row's
  /// top.
  final Offset offset;

  /// Space kept between the submenu and the screen's safe area.
  final EdgeInsets screenPadding;

  /// Whether contents taller than the screen scroll.
  final bool scrollable;

  @override
  State<DraggableSubmenu> createState() => _DraggableSubmenuState();
}

class _DraggableSubmenuState extends State<DraggableSubmenu> {
  MenuController? _ownController;
  MenuController get _controller =>
      widget.controller ?? (_ownController ??= MenuController());

  void _toggle() =>
      _controller.isOpen ? _controller.close() : _controller.open();

  Rect _boundsFor(BuildContext context, Size overlaySize) {
    final media = MediaQuery.maybeOf(context);
    var rect = Offset.zero & overlaySize;
    if (media != null) {
      rect = media.viewInsets.deflateRect(media.padding.deflateRect(rect));
    }
    return widget.screenPadding.deflateRect(rect);
  }

  Widget _buildOverlay(BuildContext context, RawMenuOverlayInfo info) {
    final bounds = _boundsFor(context, info.overlaySize);
    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.menuChildren,
    );
    if (widget.scrollable) {
      content = SingleChildScrollView(primary: false, child: content);
    }
    return ConstrainedBox(
      constraints: BoxConstraints.loose(info.overlaySize),
      child: CustomSingleChildLayout(
        delegate: _SubmenuLayout(
          anchor: info.anchorRect,
          bounds: bounds,
          textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
          offset: widget.offset,
        ),
        // Same tap-region group as the menu: a tap here isn't "outside".
        child: TapRegion(
          groupId: info.tapRegionGroupId,
          child: Actions(
            actions: <Type, Action<Intent>>{
              DismissIntent: CallbackAction<DismissIntent>(
                onInvoke: (_) => _controller.close(),
              ),
            },
            child: content,
          ),
        ),
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    MenuController controller,
    Widget? child,
  ) {
    final builder = widget.builder;
    if (builder != null) return builder(context, controller, child);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggle,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RawMenuAnchor(
      controller: _controller,
      onOpen: widget.onOpen,
      onClose: widget.onClose,
      overlayBuilder: _buildOverlay,
      builder: _buildRow,
      child: widget.child,
    );
  }
}

class _SubmenuLayout extends SingleChildLayoutDelegate {
  _SubmenuLayout({
    required this.anchor,
    required this.bounds,
    required this.textDirection,
    required this.offset,
  });

  final Rect anchor;
  final Rect bounds;
  final TextDirection textDirection;
  final Offset offset;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(bounds.size);

  @override
  Offset getPositionForChild(Size size, Size childSize) => submenuPosition(
    anchor: anchor,
    child: childSize,
    bounds: bounds,
    textDirection: textDirection,
    offset: offset,
  );

  @override
  bool shouldRelayout(_SubmenuLayout old) =>
      anchor != old.anchor ||
      bounds != old.bounds ||
      textDirection != old.textDirection ||
      offset != old.offset;
}
