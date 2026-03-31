// lib/models/stroke.dart
// Represents a single freehand stroke on the infinite canvas.
// After endStroke(), points are treated as immutable.

import 'dart:ui';

class Stroke {
  final List<Offset> points;
  final Color color;
  final double width;

  Rect? _bounds;

  Stroke({required this.points, required this.color, required this.width});

  /// Bounding rect in world space, inflated by half stroke-width.
  /// Used for viewport culling.
  Rect get bounds {
    if (_bounds != null) return _bounds!;
    if (points.isEmpty) return _bounds = Rect.zero;
    double minX = points.first.dx, maxX = points.first.dx;
    double minY = points.first.dy, maxY = points.first.dy;
    for (final p in points) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }
    final half = width / 2.0;
    return _bounds = Rect.fromLTRB(minX - half, minY - half, maxX + half, maxY + half);
  }

  Map<String, dynamic> toJson() => {
    'points': points.map((p) => [p.dx, p.dy]).toList(),
    'color': color.value,
    'width': width,
  };

  factory Stroke.fromJson(Map<String, dynamic> json) => Stroke(
    points: (json['points'] as List)
        .map((p) => Offset((p[0] as num).toDouble(), (p[1] as num).toDouble()))
        .toList(),
    color: Color(json['color'] as int),
    width: (json['width'] as num).toDouble(),
  );
}
