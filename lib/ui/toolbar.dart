// lib/ui/toolbar.dart
// Top toolbar: color • width • draw/pan • undo/redo • clear • save/load/SVG • zoom

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';

import '../models/canvas_state.dart';
import '../services/serialization_service.dart';

class Toolbar extends StatelessWidget {
  const Toolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CanvasState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final divColor = isDark ? Colors.white12 : Colors.black12;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(bottom: BorderSide(color: divColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.07),
            blurRadius: 6, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          const SizedBox(width: 8),

          // Color swatch
          Tooltip(
            message: 'Pick color',
            child: GestureDetector(
              onTap: () => _showColorPicker(context, state),
              child: Container(
                width: 28, height: 28,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: state.selectedColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? Colors.white38 : Colors.black26, width: 2),
                ),
              ),
            ),
          ),

          // Recent colors
          ...state.recentColors.map((c) => Tooltip(
            message: 'Recent color',
            child: GestureDetector(
              onTap: () => state.setColor(c),
              child: Container(
                width: 20, height: 20,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: state.selectedColor == c 
                        ? (isDark ? Colors.white : Colors.black) 
                        : (isDark ? Colors.white24 : Colors.black12), 
                    width: state.selectedColor == c ? 2 : 1,
                  ),
                ),
              ),
            ),
          )),
          const SizedBox(width: 8),

          // Width slider
          const Icon(Icons.brush_outlined, size: 18),
          SizedBox(
            width: 100,
            child: Slider(
              value: state.selectedWidth, min: 1, max: 40,
              onChanged: state.setWidth,
            ),
          ),
          SizedBox(
            width: 34,
            child: Text('${state.selectedWidth.round()}px',
                style: const TextStyle(fontSize: 11)),
          ),

          _div(divColor),

          // Draw / Pan toggle
          _Btn(
            icon: state.isPanMode ? Icons.pan_tool_outlined : Icons.edit_outlined,
            label: state.isPanMode ? 'Pan mode' : 'Draw mode',
            active: state.isPanMode,
            onPressed: state.togglePanMode,
          ),

          _div(divColor),

          // Undo / Redo
          _Btn(icon: Icons.undo, label: 'Undo',
              onPressed: state.canUndo ? state.undo : null),
          _Btn(icon: Icons.redo, label: 'Redo',
              onPressed: state.canRedo ? state.redo : null),

          _div(divColor),

          // Clear
          _Btn(
            icon: Icons.delete_sweep_outlined, label: 'Clear canvas',
            onPressed: () => _confirmClear(context, state),
          ),

          _div(divColor),

          // Save / Load / Export
          _Btn(icon: Icons.save_outlined,        label: 'Save JSON',
              onPressed: () => _saveJson(context, state)),
          _Btn(icon: Icons.folder_open_outlined,  label: 'Load JSON',
              onPressed: () => _loadJson(context, state)),
          _Btn(icon: Icons.image_outlined,        label: 'Export SVG',
              onPressed: () => _exportSvg(context, state)),

          _div(divColor),

          // Zoom % (tap to reset)
          GestureDetector(
            onTap: state.resetCamera,
            child: Tooltip(
              message: 'Reset view (${(state.camera.zoom * 100).round()}%)',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '${(state.camera.zoom * 100).round()}%',
                  style: const TextStyle(fontSize: 12,
                      fontFeatures: [FontFeature.tabularFigures()]),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),
        ]),
      ),
    );
  }

  Widget _div(Color c) => Container(
      width: 1, height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: c);

  void _showColorPicker(BuildContext ctx, CanvasState state) {
    Color tmp = state.selectedColor;
    showDialog(
      context: ctx,
      builder: (dctx) => AlertDialog(
        title: const Text('Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: tmp,
            onColorChanged: (c) => tmp = c,
            labelTypes: const [],
            pickerAreaHeightPercent: 0.7,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () { state.setColor(tmp); Navigator.pop(dctx); },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext ctx, CanvasState state) {
    showDialog(
      context: ctx,
      builder: (dctx) => AlertDialog(
        title: const Text('Clear canvas?'),
        content: const Text('All strokes will be removed. Undoable.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('Cancel')),
          FilledButton.tonal(
            onPressed: () { state.clear(); Navigator.pop(dctx); },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveJson(BuildContext ctx, CanvasState state) async {
    _snack(ctx, 'Saving…');
    final path = await SerializationService.saveJson(state.strokes);
    if (ctx.mounted) _snack(ctx, path != null ? 'Saved → $path' : 'Save failed');
  }

  Future<void> _loadJson(BuildContext ctx, CanvasState state) async {
    final loaded = await SerializationService.loadJson();
    if (loaded != null) {
      state.loadStrokes(loaded);
      if (ctx.mounted) _snack(ctx, 'Loaded ${loaded.length} strokes');
    }
  }

  Future<void> _exportSvg(BuildContext ctx, CanvasState state) async {
    if (state.strokes.isEmpty) { _snack(ctx, 'Nothing to export'); return; }
    _snack(ctx, 'Exporting…');
    final path = await SerializationService.saveSvg(state.strokes);
    if (ctx.mounted) _snack(ctx, path != null ? 'SVG saved → $path' : 'Export failed');
  }

  void _snack(BuildContext ctx, String msg) {
    if (!ctx.mounted) return;
    ScaffoldMessenger.of(ctx)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 3)));
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool active;

  const _Btn({required this.icon, required this.label,
      this.onPressed, this.active = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final col = active
        ? theme.colorScheme.primary
        : onPressed == null ? theme.disabledColor : theme.iconTheme.color;
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Icon(icon, size: 22, color: col),
        ),
      ),
    );
  }
}
