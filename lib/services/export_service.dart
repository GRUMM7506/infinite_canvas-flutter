// lib/services/export_service.dart
// Exports canvas strokes to SVG or PDF.
// SVG: manually constructed — uses the same bezier smoothing as the renderer.
// PDF: uses the `pdf` package with PdfGraphics drawing API.

import 'dart:io';
import 'dart:ui' show Offset, Rect;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/stroke.dart';

class ExportService {
  // ── SVG ────────────────────────────────────────────────────────────────────

  Future<String?> exportSvg(List<Stroke> strokes) async {
    if (kIsWeb || strokes.isEmpty) return null;
    final bounds = _bounds(strokes);
    if (bounds == null) return null;

    final w = bounds.width.toStringAsFixed(2);
    final h = bounds.height.toStringAsFixed(2);
    final vb =
        '${bounds.left.toStringAsFixed(2)} ${bounds.top.toStringAsFixed(2)} $w $h';

    final buf = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln(
          '<svg xmlns="http://www.w3.org/2000/svg" width="$w" height="$h" viewBox="$vb">');

    for (final s in strokes) {
      if (s.points.isEmpty) continue;
      final hex =
          '#${s.color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
      final opacity = s.color.opacity.toStringAsFixed(3);
      buf.writeln('<path d="${_svgPath(s.points)}" stroke="$hex" '
          'stroke-opacity="$opacity" stroke-width="${s.width.toStringAsFixed(2)}" '
          'stroke-linecap="round" stroke-linejoin="round" fill="none"/>');
    }

    buf.write('</svg>');
    return _writeFile(buf.toString().codeUnits.map((c) => c & 0xFF).toList(),
        'canvas', 'svg');
  }

  String _svgPath(List<Offset> pts) {
    String f(double v) => v.toStringAsFixed(2);
    if (pts.length == 1) return 'M ${f(pts[0].dx)} ${f(pts[0].dy)} l 0.01 0';
    if (pts.length == 2)
      return 'M ${f(pts[0].dx)} ${f(pts[0].dy)} L ${f(pts[1].dx)} ${f(pts[1].dy)}';

    final buf = StringBuffer('M ${f(pts[0].dx)} ${f(pts[0].dy)} ');
    final fm = _mid(pts[0], pts[1]);
    buf.write('L ${f(fm.dx)} ${f(fm.dy)} ');
    for (int i = 1; i < pts.length - 1; i++) {
      final e = _mid(pts[i], pts[i + 1]);
      buf.write('Q ${f(pts[i].dx)} ${f(pts[i].dy)} ${f(e.dx)} ${f(e.dy)} ');
    }
    buf.write('L ${f(pts.last.dx)} ${f(pts.last.dy)}');
    return buf.toString();
  }

  // ── PDF ────────────────────────────────────────────────────────────────────

  Future<String?> exportPdf(List<Stroke> strokes) async {
    if (kIsWeb || strokes.isEmpty) return null;
    final bounds = _bounds(strokes);
    if (bounds == null) return null;

    const pageW = 595.28;
    const pageH = 841.89;
    const margin = 0.9;

    final sx = (pageW * margin) / bounds.width;
    final sy = (pageH * margin) / bounds.height;
    final scale = sx < sy ? sx : sy;
    final offX = (pageW - bounds.width * scale) / 2;
    final offY = (pageH - bounds.height * scale) / 2;

    Offset toPage(Offset p) => Offset(
          (p.dx - bounds.left) * scale + offX,
          pageH - ((p.dy - bounds.top) * scale + offY),
        );

    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => pw.CustomPaint(
        size: const PdfPoint(pageW, pageH),
        painter: (PdfGraphics g, PdfPoint _) {
          for (final s in strokes) {
            if (s.points.isEmpty) continue;
            g
              ..setStrokeColor(PdfColor(
                s.color.red / 255.0,
                s.color.green / 255.0,
                s.color.blue / 255.0,
                s.color.opacity,
              ))
              ..setLineWidth(s.width * scale);

            final pts = s.points.map(toPage).toList();
            g.moveTo(pts[0].dx, pts[0].dy);
            for (int i = 1; i < pts.length; i++) {
              g.lineTo(pts[i].dx, pts[i].dy);
            }
            g.strokePath();
          }
        },
      ),
    ));

    final bytes = await pdf.save();
    return _writeFile(bytes, 'canvas', 'pdf');
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Rect? _bounds(List<Stroke> strokes) {
    if (strokes.isEmpty) return null;
    var b = strokes.first.bounds;
    for (final s in strokes.skip(1)) {
      b = b.expandToInclude(s.bounds);
    }
    return b;
  }

  Offset _mid(Offset a, Offset b) =>
      Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);

  Future<String?> _writeFile(List<int> bytes, String base, String ext) async {
    final name = '${base}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    try {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Export ${ext.toUpperCase()}',
        fileName: name,
        type: FileType.custom,
        allowedExtensions: [ext],
        lockParentWindow: true,
      );
      if (path != null) {
        await File(path).writeAsBytes(bytes);
        return path;
      }
    } catch (_) {}
    try {
      final dir = await getDownloadsDirectory();
      if (dir != null) {
        final path = '${dir.path}/$name';
        await File(path).writeAsBytes(bytes);
        return path;
      }
    } catch (_) {}
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/$name';
      await File(path).writeAsBytes(bytes);
      return path;
    } catch (_) {
      return null;
    }
  }
}
