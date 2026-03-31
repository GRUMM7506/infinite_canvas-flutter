// lib/ui/canvas_widget.dart
// Interactive drawing surface.
//
// Gesture strategy:
//   • Single pointer + draw mode  → freehand stroke
//   • Single pointer + pan mode   → pan
//   • Two+ pointers               → pan + pinch-zoom (cancels active stroke)
//   • Mouse scroll wheel          → zoom at cursor

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/canvas_state.dart';
import '../painters/canvas_painter.dart';

class CanvasWidget extends StatefulWidget {
  const CanvasWidget({super.key});
  @override
  State<CanvasWidget> createState() => _CanvasWidgetState();
}

class _CanvasWidgetState extends State<CanvasWidget> {
  Offset? _lastFocal;
  double _lastScale = 1.0;
  bool _isDrawing = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CanvasState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerSignal: (ev) {
        if (ev is PointerScrollEvent) {
          state.zoomCamera(ev.localPosition,
              ev.scrollDelta.dy > 0 ? 0.9 : 1.1);
        }
      },
      onPointerMove: (ev) {
        if (ev.buttons == kMiddleMouseButton || ev.buttons == kSecondaryMouseButton) {
          state.panCamera(ev.delta);
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onScaleStart: (d) {
          _lastFocal = d.localFocalPoint;
          _lastScale = 1.0;
          if (d.pointerCount >= 2) {
            if (_isDrawing) { state.cancelStroke(); _isDrawing = false; }
          } else if (!state.isPanMode) {
            _isDrawing = true;
            state.beginStroke(state.camera.screenToWorld(d.localFocalPoint));
          }
        },
        onScaleUpdate: (d) {
          final focal = d.localFocalPoint;
          final panDelta = focal - (_lastFocal ?? focal);
          final scaleDelta = d.scale / _lastScale;
          _lastScale = d.scale;

          if (d.pointerCount >= 2) {
            if (panDelta != Offset.zero) state.panCamera(panDelta);
            if ((scaleDelta - 1.0).abs() > 0.001) {
              state.zoomCamera(focal, scaleDelta);
            }
          } else if (state.isPanMode) {
            if (panDelta != Offset.zero) state.panCamera(panDelta);
          } else if (_isDrawing) {
            state.addPoint(state.camera.screenToWorld(focal));
          }
          _lastFocal = focal;
        },
        onScaleEnd: (_) {
          if (_isDrawing) { state.endStroke(); _isDrawing = false; }
          _lastFocal = null;
          _lastScale = 1.0;
        },
        child: RepaintBoundary(
          child: SizedBox.expand(
            child: CustomPaint(
              painter: CanvasPainter(
                strokes: state.strokes,
                currentStroke: state.currentStroke,
                camera: state.camera,
                isDark: isDark,
              ),
              isComplex: true,
              willChange: true,
            ),
          ),
        ),
      ),
    );
  }
}
