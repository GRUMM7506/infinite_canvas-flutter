// lib/main.dart
// Entry point. Sets up Provider + MaterialApp with light/dark theme.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/canvas_state.dart';
import 'ui/canvas_widget.dart';
import 'ui/toolbar.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => CanvasState(),
      child: const InfiniteCanvasApp(),
    ),
  );
}

class InfiniteCanvasApp extends StatefulWidget {
  const InfiniteCanvasApp({super.key});
  @override
  State<InfiniteCanvasApp> createState() => _InfiniteCanvasAppState();
}

class _InfiniteCanvasAppState extends State<InfiniteCanvasApp> {
  ThemeMode _theme = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Infinite Canvas',
      debugShowCheckedModeBanner: false,
      themeMode: _theme,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: CanvasScreen(
        isDark: _theme == ThemeMode.dark,
        onToggleTheme: () => setState(() => _theme =
            _theme == ThemeMode.light ? ThemeMode.dark : ThemeMode.light),
      ),
    );
  }
}

class CanvasScreen extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;
  const CanvasScreen({super.key, required this.isDark, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        SafeArea(
          bottom: false,
          child: Row(children: [
            const Expanded(child: Toolbar()),
            IconButton(
              icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
              tooltip: 'Toggle theme',
              onPressed: onToggleTheme,
            ),
            const SizedBox(width: 4),
          ]),
        ),
        const Expanded(child: CanvasWidget()),
      ]),
    );
  }
}
