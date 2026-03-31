// lib/models/camera.dart
// Camera represents the viewport into the infinite world coordinate system.
//
// Transform:
//   screen = (world - position) * zoom
//   world  = screen / zoom + position

import 'dart:ui';

class Camera {
  Offset position; // world point at screen top-left
  double zoom;     // pixels per world unit

  static const double minZoom = 0.05;
  static const double maxZoom = 100.0;

  Camera({this.position = Offset.zero, this.zoom = 1.0});

  Offset worldToScreen(Offset world) => (world - position) * zoom;
  Offset screenToWorld(Offset screen) => screen / zoom + position;

  /// Zoom centred on a screen-space focal point.
  /// Keeps the world point under focalScreen fixed after zoom.
  void zoomAtFocalPoint(Offset focalScreen, double scaleFactor) {
    final worldFocal = screenToWorld(focalScreen);
    zoom = (zoom * scaleFactor).clamp(minZoom, maxZoom);
    position = worldFocal - focalScreen / zoom;
  }

  /// World-space rect currently visible on screen.
  Rect visibleWorldRect(Size screenSize) {
    final tl = screenToWorld(Offset.zero);
    final br = screenToWorld(Offset(screenSize.width, screenSize.height));
    return Rect.fromPoints(tl, br);
  }
}
