// lib/painters/canvas_painter.dart
// CustomPainter that renders the infinite canvas.
//
// Pipeline:
//   1. Adaptive dot-grid in screen space
//   2. Apply camera transform (world coordinates below this line)
//   3. Committed strokes — viewport-culled
//   4. Current in-progress stroke (always rendered)

import 'package:flutter/material.dart';
import '../models/stroke.dart';
import '../models/camera.dart';

class CanvasPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke? currentStroke;
  final Camera camera;
  final bool isDark;

  const CanvasPainter({
    required this.strokes,
    required this.currentStroke,
    required this.camera,
    this.isDark = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    _paintGrid(canvas, size);

    // Apply camera transform — everything below is in world coordinates.
    canvas.save();
    canvas.translate(
        -camera.position.dx * camera.zoom, -camera.position.dy * camera.zoom);
    canvas.scale(camera.zoom);

    final visible = camera.visibleWorldRect(size);

    for (final stroke in strokes) {
      if (stroke.bounds.overlaps(visible)) {
        _paintStroke(canvas, stroke);
      }
    }
    if (currentStroke != null) _paintStroke(canvas, currentStroke!);

    canvas.restore();
  }

  // ── Grid ─────────────────────────────────────────────────────────────────
  void _paintGrid(Canvas canvas, Size size) {
    // Keep dot spacing between 24 px and 120 px on screen.
    double spacing = 50.0;
    while (spacing * camera.zoom < 24) {
      spacing *= 5;
    }
    while (spacing * camera.zoom > 120) {
      spacing /= 5;
    }

    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.14);

    final worldLeft = camera.screenToWorld(Offset.zero).dx;
    final worldTop = camera.screenToWorld(Offset.zero).dy;
    final worldRight = camera.screenToWorld(Offset(size.width, 0)).dx;
    final worldBot = camera.screenToWorld(Offset(0, size.height)).dy;

    final startX = (worldLeft / spacing).ceil() * spacing;
    final startY = (worldTop / spacing).ceil() * spacing;

    for (double wx = startX; wx <= worldRight; wx += spacing) {
      for (double wy = startY; wy <= worldBot; wy += spacing) {
        canvas.drawCircle(camera.worldToScreen(Offset(wx, wy)), 1.3, paint);
      }
    }

    // World-origin axis lines
    final axis = Paint()
      ..color = Colors.blueAccent.withOpacity(0.22)
      ..strokeWidth = 1.0;
    final ox = camera.worldToScreen(Offset.zero);
    if (ox.dx >= 0 && ox.dx <= size.width) {
      canvas.drawLine(Offset(ox.dx, 0), Offset(ox.dx, size.height), axis);
    }
    if (ox.dy >= 0 && ox.dy <= size.height) {
      canvas.drawLine(Offset(0, ox.dy), Offset(size.width, ox.dy), axis);
    }
  }

  // ── Stroke ───────────────────────────────────────────────────────────────
  void _paintStroke(Canvas canvas, Stroke stroke) {
    final pts = stroke.points;
    if (pts.isEmpty) return;

    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    if (pts.length == 1) {
      canvas.drawCircle(
          pts[0], stroke.width / 2, paint..style = PaintingStyle.fill);
      return;
    }

    // Smooth quadratic bezier: control point = current sample,
    // target = midpoint to next sample. Produces C1-continuous curve.
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    if (pts.length == 2) {
      path.lineTo(pts[1].dx, pts[1].dy);
    } else {
      for (int i = 0; i < pts.length - 1; i++) {
        final mx = (pts[i].dx + pts[i + 1].dx) / 2;
        final my = (pts[i].dy + pts[i + 1].dy) / 2;
        path.quadraticBezierTo(pts[i].dx, pts[i].dy, mx, my);
      }
      path.lineTo(pts.last.dx, pts.last.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CanvasPainter old) => true;
}
