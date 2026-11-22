import 'package:draggable_menu_anchor/material.dart';
import 'package:material_ui/material_ui.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  ThemeMode _mode = ThemeMode.dark;

  void _toggleTheme() => setState(
    () => _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'draggable_menu_anchor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      themeMode: _mode,
      home: TapAnywherePage(onToggleTheme: _toggleTheme),
    );
  }
}

/// A full-screen pane: tap anywhere to open a draggable menu at that point.
class TapAnywherePage extends StatefulWidget {
  const TapAnywherePage({super.key, this.onToggleTheme});

  /// Switches between the light and dark theme.
  final VoidCallback? onToggleTheme;

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

  /// A row that opens a submenu beside the menu ([DraggableSubmenu]; it
  /// flips to the other side near the screen edge).
  Widget _submenu(String label, IconData icon, List<Widget> items) =>
      DraggableSubmenu(
        // Styled by the app's MenuTheme, like Flutter's own menus.
        menuChildren: <Widget>[DraggableMenuSurface(children: items)],
        builder: (context, submenu, _) => MenuItemButton(
          leadingIcon: Icon(icon),
          trailingIcon: const Icon(Icons.arrow_right),
          // A row that opens a submenu mustn't close menus when pressed
          // (MenuItemButton's default), or a tap on an open submenu's row
          // would close it and then open it again.
          closeOnActivate: false,
          onPressed: () => submenu.isOpen ? submenu.close() : submenu.open(),
          child: Text(label),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: DraggableMenuAnchor(
        controller: _menu,
        menuChildren: <Widget>[
          // The menu's panel, styled by the app's MenuTheme like Flutter's
          // own menus.
          DraggableMenuSurface(
            key: const ValueKey<String>('example-menu'),
            // A grip at the top. The whole menu drags (the default
            // `dragFrom: MenuDragFrom.anywhere`); the grip shows that it
            // can. With `dragFrom: MenuDragFrom.handle` only it would.
            header: const DraggableMenuGrip(
              key: ValueKey<String>('example-grip'),
            ),
            children: <Widget>[
              _item('Cut', Icons.content_cut),
              _item('Copy', Icons.content_copy),
              _item('Paste', Icons.content_paste),
              const Divider(height: 8),
              _submenu('Insert', Icons.add_box_outlined, <Widget>[
                _item('Text', Icons.title),
                _item('Image', Icons.image_outlined),
                _item('Shape', Icons.category_outlined),
              ]),
              _submenu('Arrange', Icons.layers_outlined, <Widget>[
                _item('Bring to front', Icons.flip_to_front),
                _item('Send to back', Icons.flip_to_back),
              ]),
            ],
          ),
        ],
        // The anchor is the whole pane: the menu opens where it's tapped.
        child: Stack(
          children: <Widget>[
            GestureDetector(
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
                      const Text(
                        'Drag the menu to move it · tap outside to close',
                      ),
                      const SizedBox(height: 24),
                      Text(_chosen, key: const ValueKey<String>('chosen')),
                    ],
                  ),
                ),
              ),
            ),
            // Light/dark switch. It's on the pane (the anchor), so tapping it
            // leaves an open menu open: watch the menu, its grip and its
            // submenus restyle with the theme.
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: IconButton.filledTonal(
                    key: const ValueKey<String>('theme-toggle'),
                    tooltip: isDark ? 'Light mode' : 'Dark mode',
                    icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                    onPressed: widget.onToggleTheme,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
