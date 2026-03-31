// lib/services/serialization_service.dart
// JSON save/load and SVG export.
//
// JSON format:
//   { "version": 1, "strokes": [ { "points": [[x,y],...], "color": int, "width": double } ] }
//
// SVG export mirrors the quadratic-bezier algorithm in canvas_painter.dart
// so exported files look identical to the in-app rendering.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/stroke.dart';

class SerializationService {
  // ── JSON ──────────────────────────────────────────────────────────────────

  static Map<String, dynamic> _toMap(List<Stroke> strokes) => {
    'version': 1,
    'strokes': strokes.map((s) => s.toJson()).toList(),
  };

  static List<Stroke> _fromMap(Map<String, dynamic> map) =>
      (map['strokes'] as List)
          .map((s) => Stroke.fromJson(s as Map<String, dynamic>))
          .toList();

  /// Save strokes as JSON. Returns saved path or null on failure.
  static Future<String?> saveJson(List<Stroke> strokes) async {
    try {
      final json = const JsonEncoder.withIndent('  ').convert(_toMap(strokes));
      final dir = await getApplicationDocumentsDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/canvas_$ts.json');
      await file.writeAsString(json);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  /// Open file picker and load JSON. Returns null if cancelled or invalid.
  static Future<List<Stroke>?> loadJson() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return null;
      final bytes = result.files.first.bytes;
      final String content;
      if (bytes != null) {
        content = utf8.decode(bytes);
      } else {
        final path = result.files.first.path;
        if (path == null) return null;
        content = await File(path).readAsString();
      }
      return _fromMap(jsonDecode(content) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ── SVG export ────────────────────────────────────────────────────────────

  static String exportSvg(List<Stroke> strokes) {
    if (strokes.isEmpty) {
      return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 600"></svg>';
    }

    // Tight bounding box
    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (final s in strokes) {
      for (final p in s.points) {
        minX = min(minX, p.dx - s.width);
        minY = min(minY, p.dy - s.width);
        maxX = max(maxX, p.dx + s.width);
        maxY = max(maxY, p.dy + s.width);
      }
    }
    const pad = 20.0;
    minX -= pad; minY -= pad; maxX += pad; maxY += pad;
    final vw = maxX - minX, vh = maxY - minY;

    final buf = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln('<svg xmlns="http://www.w3.org/2000/svg"')
      ..writeln('  viewBox="${_f(minX)} ${_f(minY)} ${_f(vw)} ${_f(vh)}"')
      ..writeln('  width="${_f(vw)}" height="${_f(vh)}">');

    for (final s in strokes) {
      if (s.points.isEmpty) continue;
      final hex = '#${s.color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
      final opacity = (s.color.alpha / 255.0).toStringAsFixed(3);
      buf
        ..write('  <path d="${_strokePath(s)}"')
        ..write(' stroke="$hex" stroke-opacity="$opacity"')
        ..write(' stroke-width="${_f(s.width)}"')
        ..writeln(' stroke-linecap="round" stroke-linejoin="round" fill="none"/>');
    }
    buf.writeln('</svg>');
    return buf.toString();
  }

  static String _strokePath(Stroke stroke) {
    final pts = stroke.points;
    if (pts.isEmpty) return '';
    if (pts.length == 1) return 'M${_f(pts[0].dx)},${_f(pts[0].dy)} l0,0';
    final buf = StringBuffer('M${_f(pts[0].dx)},${_f(pts[0].dy)}');
    if (pts.length == 2) {
      buf.write(' L${_f(pts[1].dx)},${_f(pts[1].dy)}');
      return buf.toString();
    }
    // Quadratic bezier through midpoints — mirrors canvas_painter.dart
    for (int i = 0; i < pts.length - 1; i++) {
      final mx = (pts[i].dx + pts[i + 1].dx) / 2;
      final my = (pts[i].dy + pts[i + 1].dy) / 2;
      buf.write(' Q${_f(pts[i].dx)},${_f(pts[i].dy)} ${_f(mx)},${_f(my)}');
    }
    buf.write(' L${_f(pts.last.dx)},${_f(pts.last.dy)}');
    return buf.toString();
  }

  static Future<String?> saveSvg(List<Stroke> strokes) async {
    try {
      final svg = exportSvg(strokes);
      final dir = await getApplicationDocumentsDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/canvas_$ts.svg');
      await file.writeAsString(svg);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  static String _f(double v) => v.toStringAsFixed(2);
}
