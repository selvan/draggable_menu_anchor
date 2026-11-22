import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'vertical_menu_scope.dart';

/// A menu panel styled like a [MenuAnchor]'s: background, elevation, shadow,
/// shape, padding and size limits come from [style], then the ambient
/// [MenuTheme], then Material 3's menu defaults, exactly as a [MenuAnchor]
/// resolves them.
///
/// Use it as the contents of a `DraggableMenuAnchor` (or a
/// `DraggableSubmenu`) so the menu matches the app's other menus:
///
/// ```dart
/// DraggableMenuAnchor(
///   menuChildren: [
///     DraggableMenuSurface(
///       header: const DraggableMenuGrip(),
///       children: [
///         MenuItemButton(onPressed: copy, child: const Text('Copy')),
///         SubmenuButton(menuChildren: [/* … */], child: const Text('Insert')),
///       ],
///     ),
///   ],
/// )
/// ```
///
/// [children] are laid out in a column as wide as the widest one (each
/// stretched to that width), inside the style's padding. [header] (e.g. a
/// `DraggableMenuGrip`) sits above them, flush with the panel's top and
/// sides. `SubmenuButton`s in it open beside the menu and flip near the
/// screen edge: a [VerticalMenuScope] is built in.
///
/// Unlike a [MenuAnchor]'s panel it doesn't scroll by itself: the
/// `DraggableMenuAnchor` (with `scrollable: true`, the default) scrolls it
/// when it's taller than the screen.
class DraggableMenuSurface extends StatelessWidget {
  const DraggableMenuSurface({
    super.key,
    required this.children,
    this.header,
    this.style,
    this.clipBehavior = Clip.hardEdge,
  });

  /// The menu's rows, e.g. [MenuItemButton]s and [SubmenuButton]s.
  final List<Widget> children;

  /// Shown above [children], flush with the panel's top and sides (outside
  /// its padding), e.g. a `DraggableMenuGrip`. With a header there's no
  /// top padding between it and [children].
  final Widget? header;

  /// Overrides the [MenuTheme]'s style, as [MenuAnchor.style] does. Only
  /// the properties that shape the panel are used: background, shadow and
  /// surface-tint colours, elevation, shape, side, padding, minimum, fixed
  /// and maximum size, and visual density.
  final MenuStyle? style;

  /// How the panel clips its contents (as [MenuAnchor.clipBehavior]).
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final MenuStyle? themeStyle = MenuTheme.of(context).style;
    final MenuStyle defaults = _MenuDefaults(context);

    T? effective<T>(T? Function(MenuStyle? style) get) =>
        get(style) ?? get(themeStyle) ?? get(defaults);
    T? resolve<T>(WidgetStateProperty<T>? Function(MenuStyle? style) get) =>
        effective((s) => get(s)?.resolve(<WidgetState>{}));

    final backgroundColor = resolve<Color?>((s) => s?.backgroundColor);
    final shadowColor = resolve<Color?>((s) => s?.shadowColor);
    final surfaceTintColor = resolve<Color?>((s) => s?.surfaceTintColor);
    final elevation = resolve<double?>((s) => s?.elevation) ?? 0;
    final minimumSize = resolve<Size?>((s) => s?.minimumSize);
    final fixedSize = resolve<Size?>((s) => s?.fixedSize);
    final maximumSize = resolve<Size?>((s) => s?.maximumSize);
    final side = resolve<BorderSide?>((s) => s?.side);
    final shape = resolve<OutlinedBorder?>(
      (s) => s?.shape,
    )!.copyWith(side: side);
    final visualDensity =
        effective((s) => s?.visualDensity) ?? VisualDensity.standard;
    final padding =
        resolve<EdgeInsetsGeometry?>((s) => s?.padding) ?? EdgeInsets.zero;

    // As a MenuAnchor does: density never narrows the side padding.
    final dx = math.max(0.0, visualDensity.baseSizeAdjustment.dx);
    var resolvedPadding = padding
        .add(EdgeInsets.symmetric(horizontal: dx))
        .clamp(EdgeInsets.zero, EdgeInsetsGeometry.infinity)
        .resolve(Directionality.of(context));
    if (header != null) resolvedPadding = resolvedPadding.copyWith(top: 0);

    var constraints = visualDensity.effectiveConstraints(
      BoxConstraints(
        minWidth: minimumSize?.width ?? 0,
        minHeight: minimumSize?.height ?? 0,
        maxWidth: maximumSize?.width ?? double.infinity,
        maxHeight: maximumSize?.height ?? double.infinity,
      ),
    );
    if (fixedSize != null) {
      final size = constraints.constrain(fixedSize);
      if (size.width.isFinite) {
        constraints = constraints.copyWith(
          minWidth: size.width,
          maxWidth: size.width,
        );
      }
      if (size.height.isFinite) {
        constraints = constraints.copyWith(
          minHeight: size.height,
          maxHeight: size.height,
        );
      }
    }

    return ConstrainedBox(
      constraints: constraints,
      child: IntrinsicWidth(
        child: Material(
          elevation: elevation,
          shape: shape,
          color: backgroundColor,
          shadowColor: shadowColor,
          surfaceTintColor: surfaceTintColor,
          type: backgroundColor == null
              ? MaterialType.transparency
              : MaterialType.canvas,
          clipBehavior: clipBehavior,
          child: VerticalMenuScope(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ?header,
                Padding(
                  padding: resolvedPadding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Material 3's defaults for a vertical menu panel, as `MenuAnchor` uses
/// them (Flutter keeps its own copy private).
class _MenuDefaults extends MenuStyle {
  _MenuDefaults(this.context)
    : super(
        elevation: const WidgetStatePropertyAll<double?>(3.0),
        shape: const WidgetStatePropertyAll<OutlinedBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ),
        padding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
          EdgeInsetsDirectional.symmetric(vertical: 8),
        ),
        surfaceTintColor: const WidgetStatePropertyAll<Color?>(
          Colors.transparent,
        ),
      );

  final BuildContext context;

  late final ColorScheme _colors = Theme.of(context).colorScheme;

  @override
  WidgetStateProperty<Color?> get backgroundColor =>
      WidgetStatePropertyAll<Color?>(_colors.surfaceContainer);

  @override
  WidgetStateProperty<Color?> get shadowColor =>
      WidgetStatePropertyAll<Color?>(_colors.shadow);

  @override
  VisualDensity get visualDensity => Theme.of(context).visualDensity;
}
