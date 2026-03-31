// lib/models/canvas_state.dart
// Central app state: strokes, camera, tool settings, undo/redo.

import 'package:flutter/material.dart';
import 'stroke.dart';
import 'camera.dart';

class CanvasState extends ChangeNotifier {
  // ── Stroke storage ──────────────────────────────────────────────────────
  final List<Stroke> strokes = [];
  Stroke? _currentStroke;

  // Undo/redo stacks hold shallow list snapshots.
  // Committed Stroke objects are immutable, so sharing them is memory-safe.
  final List<List<Stroke>> _undoStack = [];
  final List<List<Stroke>> _redoStack = [];

  // ── Camera ──────────────────────────────────────────────────────────────
  Camera camera = Camera();

  // ── Tool settings ───────────────────────────────────────────────────────
  Color selectedColor = Colors.black;
  List<Color> recentColors = [Colors.black, Colors.red, Colors.blue, Colors.green];
  double selectedWidth = 3.0;
  bool isPanMode = false;

  Stroke? get currentStroke => _currentStroke;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  // ── Drawing ─────────────────────────────────────────────────────────────
  void beginStroke(Offset worldPoint) {
    _currentStroke = Stroke(
      points: [worldPoint],
      color: selectedColor,
      width: selectedWidth / camera.zoom,
    );
    notifyListeners();
  }

  void addPoint(Offset worldPoint) {
    _currentStroke?.points.add(worldPoint);
    notifyListeners();
  }

  void endStroke() {
    final s = _currentStroke;
    _currentStroke = null;
    if (s != null && s.points.length > 1) {
      _saveSnapshot();
      strokes.add(s);
    }
    notifyListeners();
  }

  void cancelStroke() {
    _currentStroke = null;
    notifyListeners();
  }

  // ── Undo / Redo ──────────────────────────────────────────────────────────
  void undo() {
    if (!canUndo) return;
    _redoStack.add(List.from(strokes));
    strokes..clear()..addAll(_undoStack.removeLast());
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    _undoStack.add(List.from(strokes));
    strokes..clear()..addAll(_redoStack.removeLast());
    notifyListeners();
  }

  void clear() {
    if (strokes.isEmpty && _currentStroke == null) return;
    _saveSnapshot();
    strokes.clear();
    _currentStroke = null;
    notifyListeners();
  }

  void loadStrokes(List<Stroke> newStrokes) {
    _saveSnapshot();
    strokes..clear()..addAll(newStrokes);
    _currentStroke = null;
    notifyListeners();
  }

  // ── Tool settings ────────────────────────────────────────────────────────
  void setColor(Color color) {
    selectedColor = color;
    recentColors.remove(color);
    recentColors.insert(0, color);
    if (recentColors.length > 5) recentColors.removeLast();
    notifyListeners();
  }
  void setWidth(double w) { selectedWidth = w; notifyListeners(); }
  void togglePanMode() {
    isPanMode = !isPanMode;
    if (isPanMode) cancelStroke();
    notifyListeners();
  }

  // ── Camera (called from gesture handler) ─────────────────────────────────
  void panCamera(Offset screenDelta) {
    camera.position -= screenDelta / camera.zoom;
    notifyListeners();
  }

  void zoomCamera(Offset focalScreen, double scaleFactor) {
    camera.zoomAtFocalPoint(focalScreen, scaleFactor);
    notifyListeners();
  }

  void resetCamera() { camera = Camera(); notifyListeners(); }

  // ── Private ──────────────────────────────────────────────────────────────
  void _saveSnapshot() {
    _undoStack.add(List.from(strokes));
    _redoStack.clear();
    if (_undoStack.length > 60) _undoStack.removeAt(0);
  }
}
