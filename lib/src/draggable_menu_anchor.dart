import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'menu_placement.dart';

/// Where a [DraggableMenuAnchor]'s menu can be dragged from.
enum MenuDragFrom {
  /// Anywhere on the menu (scrollables inside still win drags along their
  /// own axis).
  anywhere,

  /// Only from [DraggableMenuHandle]s placed inside the menu.
  handle,
}

/// A `MenuAnchor` whose menu can be dragged around the screen.
///
/// Built on Flutter's [RawMenuAnchor], so opening and closing work exactly
/// like a `MenuAnchor`:
///  * [MenuController.open] (optionally with a `position`, e.g. the tap
///    point, relative to the anchor) and [MenuController.close];
///  * a tap outside closes it (absorbed when [consumeOutsideTap]);
///  * menus opened from inside it (e.g. a `MenuAnchor` in [menuChildren])
///    count as inside;
///  * a [DismissIntent] (Esc) from inside closes it.
///
/// What it adds:
///  * **Placement** like `MenuAnchor`'s: at the open point, or at the
///    [alignment] point of the anchor plus [alignmentOffset]; flipped above
///    the anchor when there's no room below; pushed in from the sides (see
///    [menuAnchorPosition]); within the screen's safe area less
///    [screenPadding]. [initialPosition] and [rememberPosition] can override
///    it.
///  * **Size**: the menu is never bigger than that area; when [scrollable]
///    its content scrolls vertically if taller, as a `MenuAnchor`'s does.
///  * **Dragging** ([draggable]): from anywhere on the menu, or only from
///    [DraggableMenuHandle]s ([dragFrom]); it stays inside the screen.
///    Scrollable content inside still wins drags along its own axis. Once
///    placed, the menu keeps its position when its size changes (pulled back
///    inside if needed). [onMoved] reports the position.
///
/// Unlike `MenuAnchor`, it draws no surface: [menuChildren] bring their own.
///
/// Positions ([initialPosition], [onMoved]) are the menu's top-left in the
/// overlay's coordinates: the screen's, for the usual full-screen overlay.
class DraggableMenuAnchor extends StatefulWidget {
  const DraggableMenuAnchor({
    super.key,
    required this.menuChildren,
    this.controller,
    this.builder,
    this.child,
    this.onOpen,
    this.onClose,
    this.onDragStart,
    this.onDragEnd,
    this.onMoved,
    this.draggable = true,
    this.dragFrom = MenuDragFrom.anywhere,
    this.consumeOutsideTap = true,
    this.scrollable = true,
    this.screenPadding = const EdgeInsets.all(8),
    this.alignment = AlignmentDirectional.bottomStart,
    this.alignmentOffset = const Offset(0, 6),
    this.initialPosition,
    this.rememberPosition = false,
    this.useRootOverlay = false,
  });

  /// The menu's contents, laid out in a column.
  final List<Widget> menuChildren;

  /// Opens/closes the menu. One is created if null.
  final MenuController? controller;

  /// Builds the anchor (e.g. a button that calls `controller.open`).
  final RawMenuAnchorChildBuilder? builder;

  /// The anchor, or the [builder]'s child.
  final Widget? child;

  final VoidCallback? onOpen;
  final VoidCallback? onClose;

  /// Called when a drag of the menu starts / ends.
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;

  /// Called with the menu's top-left whenever it changes: when it's placed
  /// after opening (reported after that frame), on each drag update, and
  /// when it's pulled back inside after a size change.
  final ValueChanged<Offset>? onMoved;

  /// Whether the menu can be dragged at all.
  final bool draggable;

  /// Where it can be dragged from: anywhere, or only [DraggableMenuHandle]s.
  final MenuDragFrom dragFrom;

  /// Whether a tap outside, which closes the menu, is kept from reaching
  /// whatever is underneath.
  final bool consumeOutsideTap;

  /// Whether content taller than the screen scrolls vertically.
  final bool scrollable;

  /// Kept clear between the menu and the screen's safe area.
  final EdgeInsets screenPadding;

  /// When opened without a `position`: the point on the anchor where the
  /// menu's top-left starts (e.g. `AlignmentDirectional.topEnd`: to the
  /// anchor's right). Start/end follow the ambient [Directionality].
  final AlignmentGeometry alignment;

  /// Added to the [alignment] point. Its `dy` is also the gap kept when the
  /// menu flips above the anchor.
  final Offset alignmentOffset;

  /// Where to open the menu (its top-left, kept inside the screen) instead
  /// of placing it relative to the anchor. E.g. a position saved from
  /// [onMoved].
  final Offset? initialPosition;

  /// Reopen where the menu was last (kept inside the screen) rather than
  /// placing it afresh. Remembered for the lifetime of this widget.
  final bool rememberPosition;

  /// See [RawMenuAnchor.useRootOverlay].
  final bool useRootOverlay;

  @override
  State<DraggableMenuAnchor> createState() => _DraggableMenuAnchorState();
}

class _DraggableMenuAnchorState extends State<DraggableMenuAnchor> {
  MenuController? _ownController;
  MenuController get _controller =>
      widget.controller ?? (_ownController ??= MenuController());

  /// The menu's top-left in overlay coordinates, once placed (or dragged).
  /// Null until the first layout after opening, unless [_handleOpen] seeds
  /// it from `initialPosition` or the remembered position.
  Offset? _placed;

  /// Where the menu last was, for `rememberPosition`.
  Offset? _remembered;

  /// The last position given to `onMoved`, so each change is reported once.
  Offset? _reported;

  /// Bumped on each drag, to lay the menu out again at its new spot.
  final ValueNotifier<int> _moves = ValueNotifier<int>(0);

  /// Latest layout facts, for keeping drags inside the screen.
  Size _menuSize = Size.zero;
  Rect _bounds = Rect.zero;

  @override
  void dispose() {
    _moves.dispose();
    super.dispose();
  }

  void _handleOpen() {
    // Seeded positions are still pulled inside the screen at layout.
    _placed =
        widget.initialPosition ??
        (widget.rememberPosition ? _remembered : null);
    _reported = null;
    widget.onOpen?.call();
  }

  void _report(Offset topLeft) {
    if (topLeft == _reported) return;
    _reported = topLeft;
    widget.onMoved?.call(topLeft);
  }

  void _dragBy(Offset delta) {
    final from = _placed;
    if (from == null) return;
    final to = keepInside(from + delta, _menuSize, _bounds);
    _placed = to;
    _remembered = to;
    _moves.value++;
    _report(to);
  }

  /// Layout-time bookkeeping: plain fields only, and `onMoved` is deferred
  /// to after the frame (no callbacks into app code during layout).
  void _placedAt(Offset topLeft, Size size, Rect bounds) {
    _placed = topLeft;
    _remembered = topLeft;
    _menuSize = size;
    _bounds = bounds;
    if (widget.onMoved != null && topLeft != _reported) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.isOpen && _placed == topLeft) {
          _report(topLeft);
        }
      });
    }
  }

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
    final textDirection = Directionality.maybeOf(context) ?? TextDirection.ltr;
    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.menuChildren,
    );
    if (widget.scrollable) {
      content = SingleChildScrollView(primary: false, child: content);
    }
    if (widget.draggable) {
      if (widget.dragFrom == MenuDragFrom.anywhere) {
        content = _MenuDragArea(
          onStart: widget.onDragStart,
          onUpdate: _dragBy,
          onEnd: widget.onDragEnd,
          child: content,
        );
      }
      // Handles work in both modes (in `anywhere` they're redundant).
      content = _DraggableMenuScope(
        onStart: widget.onDragStart,
        onUpdate: _dragBy,
        onEnd: widget.onDragEnd,
        child: content,
      );
    }
    final panel = TapRegion(
      groupId: info.tapRegionGroupId,
      consumeOutsideTaps: _controller.isOpen && widget.consumeOutsideTap,
      onTapOutside: (_) => _controller.close(),
      child: Actions(
        actions: <Type, Action<Intent>>{
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) => _controller.close(),
          ),
        },
        child: content,
      ),
    );
    return ConstrainedBox(
      constraints: BoxConstraints.loose(info.overlaySize),
      child: CustomSingleChildLayout(
        delegate: _DraggableMenuLayout(
          anchor: info.anchorRect,
          position: info.position,
          bounds: bounds,
          alignment: widget.alignment.resolve(textDirection),
          alignmentOffset: widget.alignmentOffset,
          placed: () => _placed,
          relayout: _moves,
          onPlaced: (topLeft, size) => _placedAt(topLeft, size, bounds),
        ),
        child: panel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RawMenuAnchor(
      controller: _controller,
      consumeOutsideTaps: widget.consumeOutsideTap,
      useRootOverlay: widget.useRootOverlay,
      onOpen: _handleOpen,
      onClose: widget.onClose,
      builder: widget.builder,
      overlayBuilder: _buildOverlay,
      child: widget.child,
    );
  }
}

/// Places the menu: like a `MenuAnchor` the first time (unless seeded),
/// then wherever it was (or was dragged to), kept inside the screen.
class _DraggableMenuLayout extends SingleChildLayoutDelegate {
  _DraggableMenuLayout({
    required this.anchor,
    required this.position,
    required this.bounds,
    required this.alignment,
    required this.alignmentOffset,
    required this.placed,
    required this.onPlaced,
    required Listenable relayout,
  }) : super(relayout: relayout);

  final Rect anchor;
  final Offset? position;
  final Rect bounds;
  final Alignment alignment;
  final Offset alignmentOffset;

  /// Where the menu already is (null: not placed yet).
  final Offset? Function() placed;
  final void Function(Offset topLeft, Size size) onPlaced;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(bounds.size);

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final current = placed();
    final result = current == null
        ? menuAnchorPosition(
            anchor: anchor,
            child: childSize,
            bounds: bounds,
            position: position,
            alignment: alignment,
            alignmentOffset: alignmentOffset,
          )
        : keepInside(current, childSize, bounds);
    onPlaced(result, childSize);
    return result;
  }

  @override
  bool shouldRelayout(_DraggableMenuLayout old) =>
      anchor != old.anchor ||
      position != old.position ||
      bounds != old.bounds ||
      alignment != old.alignment ||
      alignmentOffset != old.alignmentOffset;
}

/// Gives [DraggableMenuHandle]s inside the menu its drag callbacks.
class _DraggableMenuScope extends InheritedWidget {
  const _DraggableMenuScope({
    required this.onUpdate,
    required super.child,
    this.onStart,
    this.onEnd,
  });

  final ValueChanged<Offset> onUpdate;
  final VoidCallback? onStart;
  final VoidCallback? onEnd;

  @override
  bool updateShouldNotify(_DraggableMenuScope old) =>
      onUpdate != old.onUpdate || onStart != old.onStart || onEnd != old.onEnd;
}

/// A part of a [DraggableMenuAnchor]'s menu that drags it, e.g. a grip icon
/// or a title bar. Needed when the anchor's `dragFrom` is
/// [MenuDragFrom.handle]; harmless otherwise. Outside a draggable menu it
/// just shows [child].
class DraggableMenuHandle extends StatelessWidget {
  const DraggableMenuHandle({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_DraggableMenuScope>();
    if (scope == null) return child;
    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: _MenuDragArea(
        onStart: scope.onStart,
        onUpdate: scope.onUpdate,
        onEnd: scope.onEnd,
        child: child,
      ),
    );
  }
}

/// Drags the menu. Scrollables inside win drags along their own axis
/// (their slop is half the pan's); trackpad gestures are left to scrolling.
///
/// [onEnd] fires only for a drag that started here: a nested drag area (a
/// [DraggableMenuHandle] inside a drag-anywhere menu) competes with this
/// one, and the one that loses mustn't report an end.
class _MenuDragArea extends StatefulWidget {
  const _MenuDragArea({
    required this.onUpdate,
    required this.child,
    this.onStart,
    this.onEnd,
  });

  final ValueChanged<Offset> onUpdate;
  final VoidCallback? onStart;
  final VoidCallback? onEnd;
  final Widget child;

  @override
  State<_MenuDragArea> createState() => _MenuDragAreaState();
}

class _MenuDragAreaState extends State<_MenuDragArea> {
  bool _dragging = false;

  void _end() {
    if (!_dragging) return;
    _dragging = false;
    widget.onEnd?.call();
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: <Type, GestureRecognizerFactory>{
        PanGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
              () => PanGestureRecognizer(
                supportedDevices: <PointerDeviceKind>{
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.stylus,
                  PointerDeviceKind.invertedStylus,
                  PointerDeviceKind.unknown,
                },
              ),
              (recognizer) {
                // Follow the finger from where it went down.
                recognizer.dragStartBehavior = DragStartBehavior.down;
                recognizer.onStart = (_) {
                  _dragging = true;
                  widget.onStart?.call();
                };
                recognizer.onUpdate = (d) => widget.onUpdate(d.delta);
                recognizer.onEnd = (_) => _end();
                recognizer.onCancel = _end;
              },
            ),
      },
      child: widget.child,
    );
  }
}
