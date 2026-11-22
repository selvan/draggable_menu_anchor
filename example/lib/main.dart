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
      home: const TapAnywherePage(),
    );
  }
}

/// A full-screen pane: tap anywhere to open a draggable menu at that point.
class TapAnywherePage extends StatefulWidget {
  const TapAnywherePage({super.key});

  @override
  State<TapAnywherePage> createState() => _TapAnywherePageState();
}

class _TapAnywherePageState extends State<TapAnywherePage> {
  final MenuController _menu = MenuController();
  String _chosen = 'Nothing chosen yet';

  void _choose(String item) {
    setState(() => _chosen = 'Chosen: $item');
    _menu.close();
  }

  /// A tap on the pane closes an open menu, else opens it at the tap. (The
  /// pane is the anchor, so a tap on it isn't an "outside" tap.)
  void _onTap(TapUpDetails details) => _menu.isOpen
      ? _menu.close()
      : _menu.open(position: details.localPosition);

  Widget _item(String label, IconData icon) => MenuItemButton(
    leadingIcon: Icon(icon),
    onPressed: () => _choose(label),
    child: Text(label),
  );

  /// A menu panel: the menus draw no surface of their own, so give them one.
  Widget _surface(BuildContext context, List<Widget> rows, {Key? key}) =>
      Material(
        key: key,
        color: Theme.of(context).colorScheme.surfaceContainer,
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: rows,
            ),
          ),
        ),
      );

  /// A row that opens a submenu beside the menu ([DraggableSubmenu]; it
  /// flips to the other side near the screen edge).
  Widget _submenu(
    BuildContext context,
    String label,
    IconData icon,
    List<Widget> items,
  ) => DraggableSubmenu(
    menuChildren: <Widget>[_surface(context, items)],
    builder: (context, submenu, _) => MenuItemButton(
      leadingIcon: Icon(icon),
      trailingIcon: const Icon(Icons.arrow_right),
      onPressed: () => submenu.isOpen ? submenu.close() : submenu.open(),
      child: Text(label),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DraggableMenuAnchor(
        controller: _menu,
        menuChildren: <Widget>[
          _surface(
            context,
            key: const ValueKey<String>('example-menu'),
            <Widget>[
              _item('Cut', Icons.content_cut),
              _item('Copy', Icons.content_copy),
              _item('Paste', Icons.content_paste),
              const Divider(height: 8),
              _submenu(context, 'Insert', Icons.add_box_outlined, <Widget>[
                _item('Text', Icons.title),
                _item('Image', Icons.image_outlined),
                _item('Shape', Icons.category_outlined),
              ]),
              _submenu(context, 'Arrange', Icons.layers_outlined, <Widget>[
                _item('Bring to front', Icons.flip_to_front),
                _item('Send to back', Icons.flip_to_back),
              ]),
            ],
          ),
        ],
        // The anchor is the whole pane: the menu opens where it's tapped.
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: _onTap,
          child: SizedBox.expand(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Tap anywhere',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text('Drag the menu to move it · tap outside to close'),
                  const SizedBox(height: 24),
                  Text(_chosen, key: const ValueKey<String>('chosen')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
