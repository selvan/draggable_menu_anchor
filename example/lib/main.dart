import 'package:draggable_menu_anchor/draggable_menu_anchor.dart';
import 'package:flutter/material.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'draggable_menu_anchor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: const DemoPage(),
    );
  }
}

/// Buttons in the centre and the four corners, each opening a draggable
/// panel at the tap point, plus a log of the anchors' callbacks.
class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  final List<String> _log = <String>[];

  /// Latest `onMoved` report.
  String _position = '—';

  void _moved(String label, Offset topLeft) => setState(
    () =>
        _position = '$label at (${topLeft.dx.round()}, ${topLeft.dy.round()})',
  );

  void _record(String event) {
    setState(() {
      _log.insert(0, event);
      if (_log.length > 4) _log.removeLast();
    });
  }

  Widget _corner(Alignment alignment, String label) => Align(
    alignment: alignment,
    child: PanelButton(label: label, onEvent: _record, onMoved: _moved),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('draggable_menu_anchor')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: <Widget>[
            _corner(Alignment.topLeft, 'Top-left'),
            _corner(Alignment.topRight, 'Top-right'),
            _corner(Alignment.bottomLeft, 'Bottom-left'),
            _corner(Alignment.bottomRight, 'Bottom-right'),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  PanelButton(
                    label: 'Open panel',
                    onEvent: _record,
                    onMoved: _moved,
                  ),
                  const SizedBox(height: 12),
                  // Drags only by the ⋮⋮ grip, and reopens where it was left.
                  PanelButton(
                    label: 'Grip only (remembers spot)',
                    onEvent: _record,
                    onMoved: _moved,
                    dragFrom: MenuDragFrom.handle,
                    rememberPosition: true,
                  ),
                  const SizedBox(height: 12),
                  // Opened from code (no tap point): to the button's right.
                  PanelButton(
                    label: 'Right of button',
                    onEvent: _record,
                    onMoved: _moved,
                    openAtTap: false,
                    alignment: AlignmentDirectional.topEnd,
                    alignmentOffset: const Offset(8, 0),
                  ),
                  const SizedBox(height: 12),
                  PanelButton(
                    label: 'Tall menu',
                    onEvent: _record,
                    panelBuilder: (controller) =>
                        TallPanel(controller: controller),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Tap a button: the panel opens where you tapped.\n'
                    'Drag it anywhere · tap outside to close.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'onMoved: $_position',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  // Fixed height, so new log lines don't move the buttons
                  // (and an open panel) around.
                  SizedBox(
                    height: 80,
                    child: Column(
                      children: <Widget>[
                        for (final event in _log)
                          Text(
                            event,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A button that opens a [DraggableMenuAnchor] at the point it was tapped.
class PanelButton extends StatefulWidget {
  const PanelButton({
    super.key,
    required this.label,
    required this.onEvent,
    this.onMoved,
    this.panelBuilder,
    this.openAtTap = true,
    this.dragFrom = MenuDragFrom.anywhere,
    this.rememberPosition = false,
    this.alignment = AlignmentDirectional.bottomStart,
    this.alignmentOffset = const Offset(0, 6),
  });

  final String label;
  final ValueChanged<String> onEvent;
  final void Function(String label, Offset topLeft)? onMoved;

  /// Open at the tap point (`open(position:)`), or by [alignment] (`open()`).
  final bool openAtTap;
  final MenuDragFrom dragFrom;
  final bool rememberPosition;
  final AlignmentGeometry alignment;
  final Offset alignmentOffset;

  /// The panel's contents (defaults to [DemoPanel]).
  final Widget Function(MenuController controller)? panelBuilder;

  @override
  State<PanelButton> createState() => _PanelButtonState();
}

class _PanelButtonState extends State<PanelButton> {
  final MenuController _controller = MenuController();

  /// Where the finger went down on the button, so the panel opens there.
  Offset? _tap;

  @override
  Widget build(BuildContext context) {
    final label = widget.label;
    return DraggableMenuAnchor(
      controller: _controller,
      onOpen: () => widget.onEvent('$label: opened'),
      onClose: () => widget.onEvent('$label: closed'),
      onDragStart: () => widget.onEvent('$label: drag started'),
      onDragEnd: () => widget.onEvent('$label: drag ended'),
      onMoved: (topLeft) => widget.onMoved?.call(label, topLeft),
      dragFrom: widget.dragFrom,
      rememberPosition: widget.rememberPosition,
      alignment: widget.alignment,
      alignmentOffset: widget.alignmentOffset,
      menuChildren: <Widget>[
        widget.panelBuilder?.call(_controller) ??
            DemoPanel(title: label, controller: _controller),
      ],
      builder: (context, controller, child) => Listener(
        onPointerDown: (event) => _tap = event.localPosition,
        child: FilledButton.tonal(
          onPressed: () => controller.isOpen
              ? controller.close()
              : controller.open(position: widget.openAtTap ? _tap : null),
          child: Text(label),
        ),
      ),
    );
  }
}

/// A small card: drag grip, title, close button, a sideways-scrolling chip
/// row and a nested `MenuAnchor`.
class DemoPanel extends StatelessWidget {
  const DemoPanel({super.key, required this.title, required this.controller});

  final String title;
  final MenuController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: const ValueKey<String>('demo-panel'),
      elevation: 8,
      margin: EdgeInsets.zero,
      child: SizedBox(
        width: 300,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 4, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  // The grip: the only drag spot when `dragFrom: handle`.
                  const DraggableMenuHandle(
                    child: Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.drag_indicator, size: 18),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(title, style: theme.textTheme.titleSmall),
                  ),
                  MenuAnchor(
                    menuChildren: <Widget>[
                      for (final action in <String>[
                        'Duplicate',
                        'Rename',
                        'Delete',
                      ])
                        MenuItemButton(
                          onPressed: () => ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(action))),
                          child: Text(action),
                        ),
                    ],
                    builder: (context, menu, _) => TextButton(
                      onPressed: () => menu.isOpen ? menu.close() : menu.open(),
                      child: const Text('More ▾'),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close),
                    onPressed: controller.close,
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  'Drag anywhere to move me. Swipe the chips sideways to '
                  'scroll them; drag up or down on them to move me.',
                ),
              ),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  itemCount: 12,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (_, i) => Chip(label: Text('Item ${i + 1}')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Content taller than any screen: the anchor limits it to the screen and
/// lets it scroll, as a `MenuAnchor` does.
class TallPanel extends StatelessWidget {
  const TallPanel({super.key, required this.controller});

  final MenuController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const ValueKey<String>('tall-panel'),
      elevation: 8,
      margin: EdgeInsets.zero,
      child: SizedBox(
        width: 240,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (var i = 1; i <= 40; i++)
              ListTile(
                dense: true,
                title: Text('Row $i'),
                onTap: controller.close,
              ),
          ],
        ),
      ),
    );
  }
}
