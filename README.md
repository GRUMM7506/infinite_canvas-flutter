# Infinite Canvas

A production-ready Flutter infinite-canvas drawing app (Miro / Figma–style whiteboard).

## Features

| Feature | Details |
|---------|---------|
| Infinite canvas | Virtual world coordinates, double-precision |
| Smooth freehand drawing | Quadratic bezier through midpoints |
| Pinch-to-zoom + pan | Zoom centred on focal point |
| Mouse wheel zoom | Centred on cursor |
| Pan mode | Toggle button in toolbar |
| Viewport culling | Only visible strokes are rendered — fast at any stroke count |
| Undo / Redo | 60-step history, memory-efficient snapshots |
| Dot grid | Adaptive spacing at any zoom level |
| Colour picker | Full HSV wheel |
| Stroke width | 1 – 40 px |
| Save / Load | JSON format |
| SVG export | Vector-perfect, same bezier algorithm as the renderer |
| Dark mode | One-tap toggle |

## Setup

```bash
# 1. Create a new Flutter project
flutter create infinite_canvas
cd infinite_canvas

# 2. Replace pubspec.yaml and lib/ with the files from this package
# 3. Install dependencies
flutter pub get

# 4. Run
flutter run
```

## Gestures

| Gesture | Action |
|---------|--------|
| Single-finger / mouse drag | Draw stroke |
| Two-finger drag | Pan |
| Two-finger pinch | Zoom |
| Scroll wheel | Zoom at cursor |
| Tap **Pan** button | Toggle pan / draw mode |
| Tap zoom % label | Reset camera to origin |

## Architecture

```
lib/
  main.dart                        # Entry point + theme management
  models/
    stroke.dart                    # Stroke model (points, color, width, bounds)
    camera.dart                    # Viewport: worldToScreen / screenToWorld
    canvas_state.dart              # ChangeNotifier: strokes, camera, undo/redo
  services/
    serialization_service.dart     # JSON save/load · SVG export
  painters/
    canvas_painter.dart            # CustomPainter: grid + stroke rendering
  ui/
    canvas_widget.dart             # Gesture handling → CanvasState mutations
    toolbar.dart                   # Color, width, undo, save, zoom UI
```
