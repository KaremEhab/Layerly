import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:layerly/core/utils/uuid_generator.dart';
import 'package:layerly/features/editor/domain/entities/image_layer.dart';
import 'package:layerly/features/editor/domain/entities/vector_layer.dart';

class SvgVectorParser {
  /// Converts an SVG [ImageLayer] (or raw SVG XML) into an editable multi-layer [VectorLayer].
  static VectorLayer convertImageLayerToVector(ImageLayer layer) {
    List<VectorPathElement> elements = [];

    if (layer.svgContent != null && layer.svgContent!.isNotEmpty) {
      elements = parseSvgElements(layer.svgContent!);
    } else if (layer.imagePath != null) {
      try {
        final file = File(layer.imagePath!);
        if (file.existsSync()) {
          final content = file.readAsStringSync();
          elements = parseSvgElements(content);
        }
      } catch (_) {}
    }

    if (elements.isEmpty) {
      // Fallback preset
      elements = [
        VectorPathElement(
          id: 'elem-${UuidGenerator.generate().substring(0, 6)}',
          name: 'Vector Shape',
          points: generateBlobPreset(),
          fill: layer.tintColor ?? const Color(0xFF6C5CE7),
          strokeColor: const Color(0xFFA29BFE),
          strokeWidth: 2.0,
        ),
      ];
    }

    return VectorLayer(
      id: 'vector-${UuidGenerator.generate().substring(0, 8)}',
      name: '${layer.name} (Vector)',
      x: layer.x,
      y: layer.y,
      width: layer.width,
      height: layer.height,
      elements: elements,
    );
  }

  /// Parses all SVG elements (<path>, <circle>, <rect>, <polygon>, <polyline>, <ellipse>)
  /// into discrete [VectorPathElement] sub-layers preserving fills, strokes, and coordinates.
  static List<VectorPathElement> parseSvgElements(String svgXml) {
    final List<_RawSvgElement> rawElements = [];

    // 1. Extract ViewBox dimensions if available
    double vbWidth = 100.0;
    double vbHeight = 100.0;
    final vbMatch = RegExp(r'viewBox="([^"]+)"', caseSensitive: false).firstMatch(svgXml);
    if (vbMatch != null) {
      final parts = vbMatch.group(1)!.trim().split(RegExp(r'[\s,]+'));
      if (parts.length == 4) {
        vbWidth = double.tryParse(parts[2]) ?? 100.0;
        vbHeight = double.tryParse(parts[3]) ?? 100.0;
      }
    } else {
      final wMatch = RegExp(r'width="([^"ptpx]+)"', caseSensitive: false).firstMatch(svgXml);
      final hMatch = RegExp(r'height="([^"ptpx]+)"', caseSensitive: false).firstMatch(svgXml);
      if (wMatch != null && hMatch != null) {
        vbWidth = double.tryParse(wMatch.group(1)!) ?? 100.0;
        vbHeight = double.tryParse(hMatch.group(1)!) ?? 100.0;
      }
    }

    // 2. Parse all <path> tags
    final pathRegex = RegExp(r'<path\b([^>]*)/?>', caseSensitive: false);
    for (final m in pathRegex.allMatches(svgXml)) {
      final attrs = m.group(1)!;
      final dMatch = RegExp(r'd="([^"]+)"', caseSensitive: false).firstMatch(attrs);
      if (dMatch != null) {
        final pathData = dMatch.group(1)!;
        final pts = parseSvgPathData(pathData);
        if (pts.isNotEmpty) {
          final fill = _extractColor(attrs, 'fill', defaultColor: const Color(0xFFFFA726));
          final stroke = _extractColor(attrs, 'stroke');
          final strokeW = _extractDouble(attrs, 'stroke-width', defaultVal: 0.0);
          final opacity = _extractDouble(attrs, 'opacity', defaultVal: 1.0);
          final id = _extractString(attrs, 'id') ?? 'Path ${rawElements.length + 1}';

          rawElements.add(_RawSvgElement(
            name: id,
            points: pts,
            fill: fill,
            strokeColor: stroke,
            strokeWidth: strokeW,
            opacity: opacity,
          ));
        }
      }
    }

    // 3. Parse <circle> and <ellipse> tags
    final circleRegex = RegExp(r'<(circle|ellipse)\b([^>]*)/?>', caseSensitive: false);
    for (final m in circleRegex.allMatches(svgXml)) {
      final tag = m.group(1)!;
      final attrs = m.group(2)!;
      final cx = _extractDouble(attrs, 'cx', defaultVal: vbWidth / 2);
      final cy = _extractDouble(attrs, 'cy', defaultVal: vbHeight / 2);
      final rx = (tag == 'circle')
          ? _extractDouble(attrs, 'r', defaultVal: 20.0)
          : _extractDouble(attrs, 'rx', defaultVal: 20.0);
      final ry = (tag == 'circle') ? rx : _extractDouble(attrs, 'ry', defaultVal: 20.0);

      final pts = _generateEllipsePoints(cx, cy, rx, ry);
      final fill = _extractColor(attrs, 'fill', defaultColor: const Color(0xFFFFD54F));
      final stroke = _extractColor(attrs, 'stroke');
      final strokeW = _extractDouble(attrs, 'stroke-width', defaultVal: 0.0);
      final opacity = _extractDouble(attrs, 'opacity', defaultVal: 1.0);

      rawElements.add(_RawSvgElement(
        name: tag == 'circle' ? 'Circle' : 'Ellipse',
        points: pts,
        fill: fill,
        strokeColor: stroke,
        strokeWidth: strokeW,
        opacity: opacity,
      ));
    }

    // 4. Parse <rect> tags
    final rectRegex = RegExp(r'<rect\b([^>]*)/?>', caseSensitive: false);
    for (final m in rectRegex.allMatches(svgXml)) {
      final attrs = m.group(1)!;
      final x = _extractDouble(attrs, 'x', defaultVal: 0.0);
      final y = _extractDouble(attrs, 'y', defaultVal: 0.0);
      final w = _extractDouble(attrs, 'width', defaultVal: vbWidth);
      final h = _extractDouble(attrs, 'height', defaultVal: vbHeight);

      final pts = [
        VectorPoint(x: x, y: y),
        VectorPoint(x: x + w, y: y),
        VectorPoint(x: x + w, y: y + h),
        VectorPoint(x: x, y: y + h),
      ];

      final fill = _extractColor(attrs, 'fill', defaultColor: const Color(0xFFFFF3E0));
      final stroke = _extractColor(attrs, 'stroke');
      final strokeW = _extractDouble(attrs, 'stroke-width', defaultVal: 0.0);
      final opacity = _extractDouble(attrs, 'opacity', defaultVal: 1.0);

      rawElements.add(_RawSvgElement(
        name: 'Rectangle',
        points: pts,
        fill: fill,
        strokeColor: stroke,
        strokeWidth: strokeW,
        opacity: opacity,
      ));
    }

    // 5. Parse <polygon> and <polyline> tags
    final polyRegex = RegExp(r'<(polygon|polyline)\b([^>]*)/?>', caseSensitive: false);
    for (final m in polyRegex.allMatches(svgXml)) {
      final attrs = m.group(2)!;
      final ptsMatch = RegExp(r'points="([^"]+)"', caseSensitive: false).firstMatch(attrs);
      if (ptsMatch != null) {
        final rawCoords = ptsMatch.group(1)!.trim().split(RegExp(r'[\s,]+'));
        final List<VectorPoint> pts = [];
        for (int i = 0; i < rawCoords.length - 1; i += 2) {
          final x = double.tryParse(rawCoords[i]);
          final y = double.tryParse(rawCoords[i + 1]);
          if (x != null && y != null) {
            pts.add(VectorPoint(x: x, y: y));
          }
        }
        if (pts.isNotEmpty) {
          final fill = _extractColor(attrs, 'fill', defaultColor: const Color(0xFFFFB74D));
          final stroke = _extractColor(attrs, 'stroke');
          final strokeW = _extractDouble(attrs, 'stroke-width', defaultVal: 0.0);
          final opacity = _extractDouble(attrs, 'opacity', defaultVal: 1.0);

          rawElements.add(_RawSvgElement(
            name: 'Polygon',
            points: pts,
            fill: fill,
            strokeColor: stroke,
            strokeWidth: strokeW,
            opacity: opacity,
          ));
        }
      }
    }

    if (rawElements.isEmpty) {
      return [];
    }

    // 6. Global bounding box normalization across ALL elements
    double globalMinX = double.infinity;
    double globalMaxX = -double.infinity;
    double globalMinY = double.infinity;
    double globalMaxY = -double.infinity;

    for (final elem in rawElements) {
      for (final p in elem.points) {
        if (p.x < globalMinX) globalMinX = p.x;
        if (p.x > globalMaxX) globalMaxX = p.x;
        if (p.y < globalMinY) globalMinY = p.y;
        if (p.y > globalMaxY) globalMaxY = p.y;
      }
    }

    final totalWidth = (globalMaxX - globalMinX == 0) ? vbWidth : (globalMaxX - globalMinX);
    final totalHeight = (globalMaxY - globalMinY == 0) ? vbHeight : (globalMaxY - globalMinY);

    final List<VectorPathElement> elements = [];

    for (int i = 0; i < rawElements.length; i++) {
      final raw = rawElements[i];
      final normPoints = raw.points.map((p) {
        final nx = ((p.x - globalMinX) / totalWidth).clamp(0.0, 1.0);
        final ny = ((p.y - globalMinY) / totalHeight).clamp(0.0, 1.0);

        double? nhInX;
        double? nhInY;
        double? nhOutX;
        double? nhOutY;

        if (p.handleInX != null && p.handleInY != null) {
          nhInX = ((p.handleInX! - globalMinX) / totalWidth).clamp(0.0, 1.0);
          nhInY = ((p.handleInY! - globalMinY) / totalHeight).clamp(0.0, 1.0);
        }
        if (p.handleOutX != null && p.handleOutY != null) {
          nhOutX = ((p.handleOutX! - globalMinX) / totalWidth).clamp(0.0, 1.0);
          nhOutY = ((p.handleOutY! - globalMinY) / totalHeight).clamp(0.0, 1.0);
        }

        return VectorPoint(
          x: nx,
          y: ny,
          handleInX: nhInX,
          handleInY: nhInY,
          handleOutX: nhOutX,
          handleOutY: nhOutY,
          isSmooth: p.isSmooth,
        );
      }).toList();

      elements.add(VectorPathElement(
        id: 'elem-${i + 1}',
        name: '${raw.name} #${i + 1}',
        points: normPoints,
        fill: raw.fill,
        strokeColor: raw.strokeColor,
        strokeWidth: raw.strokeWidth,
        opacity: raw.opacity,
      ));
    }

    return elements;
  }

  /// Parses basic SVG path commands (M, L, C, Q, S, Z, H, V).
  static List<VectorPoint> parseSvgPathData(String pathData) {
    final List<VectorPoint> points = [];
    final commands = RegExp(r'([a-df-z])([^a-df-z]*)', caseSensitive: false).allMatches(pathData);

    double currentX = 0;
    double currentY = 0;

    for (final match in commands) {
      final cmd = match.group(1)!;
      final argsString = match.group(2)!.trim();
      final args = RegExp(r'[-+]?[0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?')
          .allMatches(argsString)
          .map((m) => double.tryParse(m.group(0)!) ?? 0.0)
          .toList();

      switch (cmd) {
        case 'M':
          if (args.length >= 2) {
            currentX = args[0];
            currentY = args[1];
            points.add(VectorPoint(x: currentX, y: currentY));
          }
          break;
        case 'm':
          if (args.length >= 2) {
            currentX += args[0];
            currentY += args[1];
            points.add(VectorPoint(x: currentX, y: currentY));
          }
          break;
        case 'L':
          for (int i = 0; i < args.length - 1; i += 2) {
            currentX = args[i];
            currentY = args[i + 1];
            points.add(VectorPoint(x: currentX, y: currentY));
          }
          break;
        case 'l':
          for (int i = 0; i < args.length - 1; i += 2) {
            currentX += args[i];
            currentY += args[i + 1];
            points.add(VectorPoint(x: currentX, y: currentY));
          }
          break;
        case 'C':
          for (int i = 0; i < args.length - 5; i += 6) {
            final h1x = args[i];
            final h1y = args[i + 1];
            final h2x = args[i + 2];
            final h2y = args[i + 3];
            currentX = args[i + 4];
            currentY = args[i + 5];
            points.add(VectorPoint(
              x: currentX,
              y: currentY,
              handleInX: h2x,
              handleInY: h2y,
              handleOutX: h1x,
              handleOutY: h1y,
              isSmooth: true,
            ));
          }
          break;
        case 'c':
          for (int i = 0; i < args.length - 5; i += 6) {
            final h1x = currentX + args[i];
            final h1y = currentY + args[i + 1];
            final h2x = currentX + args[i + 2];
            final h2y = currentY + args[i + 3];
            currentX += args[i + 4];
            currentY += args[i + 5];
            points.add(VectorPoint(
              x: currentX,
              y: currentY,
              handleInX: h2x,
              handleInY: h2y,
              handleOutX: h1x,
              handleOutY: h1y,
              isSmooth: true,
            ));
          }
          break;
        case 'H':
          if (args.isNotEmpty) {
            currentX = args[0];
            points.add(VectorPoint(x: currentX, y: currentY));
          }
          break;
        case 'h':
          if (args.isNotEmpty) {
            currentX += args[0];
            points.add(VectorPoint(x: currentX, y: currentY));
          }
          break;
        case 'V':
          if (args.isNotEmpty) {
            currentY = args[0];
            points.add(VectorPoint(x: currentX, y: currentY));
          }
          break;
        case 'v':
          if (args.isNotEmpty) {
            currentY += args[0];
            points.add(VectorPoint(x: currentX, y: currentY));
          }
          break;
      }
    }

    return points;
  }

  static List<VectorPoint> _generateEllipsePoints(double cx, double cy, double rx, double ry) {
    const int segments = 12;
    final List<VectorPoint> pts = [];
    for (int i = 0; i < segments; i++) {
      final theta = (i / segments) * 2 * math.pi;
      final x = cx + rx * math.cos(theta);
      final y = cy + ry * math.sin(theta);
      pts.add(VectorPoint(x: x, y: y, isSmooth: true));
    }
    return pts;
  }

  // -------------------------------------------------------------
  // FLUTTER CUSTOM PAINTER CODE GENERATOR
  // -------------------------------------------------------------

  /// Generates clean, production-ready Flutter `CustomPainter` Dart code.
  static String generateFlutterPainterCode(VectorLayer layer, {String className = 'VectorIllustrationPainter'}) {
    final buffer = StringBuffer();
    buffer.writeln('import \'package:flutter/material.dart\';');
    buffer.writeln();
    buffer.writeln('/// Generated Flutter CustomPainter for ${layer.name}');
    buffer.writeln('class $className extends CustomPainter {');
    buffer.writeln('  const $className();');
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  void paint(Canvas canvas, Size size) {');

    for (int i = 0; i < layer.elements.length; i++) {
      final elem = layer.elements[i];
      if (!elem.visible || elem.points.isEmpty) continue;

      buffer.writeln('    // --- Layer ${i + 1}: ${elem.name} ---');
      buffer.writeln('    {');
      buffer.writeln('      final path = Path();');
      final pts = elem.points;
      buffer.writeln('      path.moveTo(size.width * ${pts.first.x.toStringAsFixed(4)}, size.height * ${pts.first.y.toStringAsFixed(4)});');

      for (int p = 1; p < pts.length; p++) {
        final pt = pts[p];
        final prev = pts[p - 1];
        if (pt.isSmooth && (pt.handleInX != null || prev.handleOutX != null)) {
          final cp1x = (prev.handleOutX ?? prev.x).toStringAsFixed(4);
          final cp1y = (prev.handleOutY ?? prev.y).toStringAsFixed(4);
          final cp2x = (pt.handleInX ?? pt.x).toStringAsFixed(4);
          final cp2y = (pt.handleInY ?? pt.y).toStringAsFixed(4);
          final px = pt.x.toStringAsFixed(4);
          final py = pt.y.toStringAsFixed(4);
          buffer.writeln('      path.cubicTo(size.width * $cp1x, size.height * $cp1y, size.width * $cp2x, size.height * $cp2y, size.width * $px, size.height * $py);');
        } else {
          buffer.writeln('      path.lineTo(size.width * ${pt.x.toStringAsFixed(4)}, size.height * ${pt.y.toStringAsFixed(4)});');
        }
      }

      if (elem.isClosed) {
        buffer.writeln('      path.close();');
      }

      if (elem.fill != null) {
        final hex = '0x${elem.fill!.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
        buffer.writeln('      final fillPaint = Paint()..color = const Color($hex)..style = PaintingStyle.fill;');
        buffer.writeln('      canvas.drawPath(path, fillPaint);');
      }

      if (elem.strokeColor != null && elem.strokeWidth > 0) {
        final hex = '0x${elem.strokeColor!.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
        buffer.writeln('      final strokePaint = Paint()');
        buffer.writeln('        ..color = const Color($hex)');
        buffer.writeln('        ..strokeWidth = ${elem.strokeWidth}');
        buffer.writeln('        ..style = PaintingStyle.stroke;');
        buffer.writeln('      canvas.drawPath(path, strokePaint);');
      }
      buffer.writeln('    }');
      buffer.writeln();
    }

    buffer.writeln('  }');
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;');
    buffer.writeln('}');

    return buffer.toString();
  }

  // -------------------------------------------------------------
  // HELPER PARSERS
  // -------------------------------------------------------------

  static Color? _extractColor(String attrs, String key, {Color? defaultColor}) {
    // Check direct attribute key="value" or style="key:value"
    final directMatch = RegExp('$key="([^"]+)"', caseSensitive: false).firstMatch(attrs);
    String? raw = directMatch?.group(1);

    if (raw == null) {
      final styleMatch = RegExp(r'style="([^"]+)"', caseSensitive: false).firstMatch(attrs);
      if (styleMatch != null) {
        final styleContent = styleMatch.group(1)!;
        final kvMatch = RegExp('$key:([^;]+)', caseSensitive: false).firstMatch(styleContent);
        raw = kvMatch?.group(1)?.trim();
      }
    }

    if (raw == null || raw == 'none') return (raw == 'none') ? null : defaultColor;

    if (raw.startsWith('#')) {
      String hex = raw.substring(1);
      if (hex.length == 3) {
        hex = hex.split('').map((c) => '$c$c').join('');
      }
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      final val = int.tryParse(hex, radix: 16);
      if (val != null) return Color(val);
    } else if (raw.startsWith('rgb')) {
      final nums = RegExp(r'\d+').allMatches(raw).map((m) => int.tryParse(m.group(0)!) ?? 0).toList();
      if (nums.length >= 3) {
        return Color.fromARGB(255, nums[0], nums[1], nums[2]);
      }
    }

    return defaultColor;
  }

  static double _extractDouble(String attrs, String key, {double defaultVal = 0.0}) {
    final m = RegExp('$key="([^"ptpx%]+)"', caseSensitive: false).firstMatch(attrs);
    if (m != null) {
      return double.tryParse(m.group(1)!) ?? defaultVal;
    }
    return defaultVal;
  }

  static String? _extractString(String attrs, String key) {
    final m = RegExp('$key="([^"]+)"', caseSensitive: false).firstMatch(attrs);
    return m?.group(1);
  }

  static List<VectorPoint> generateBlobPreset() {
    return const [
      VectorPoint(x: 0.50, y: 0.05, isSmooth: true, handleInX: 0.25, handleInY: 0.05, handleOutX: 0.75, handleOutY: 0.05),
      VectorPoint(x: 0.95, y: 0.40, isSmooth: true, handleInX: 0.95, handleInY: 0.20, handleOutX: 0.95, handleOutY: 0.70),
      VectorPoint(x: 0.70, y: 0.95, isSmooth: true, handleInX: 0.90, handleInY: 0.95, handleOutX: 0.40, handleOutY: 0.95),
      VectorPoint(x: 0.05, y: 0.65, isSmooth: true, handleInX: 0.05, handleInY: 0.85, handleOutX: 0.05, handleOutY: 0.35),
    ];
  }
}

class _RawSvgElement {
  final String name;
  final List<VectorPoint> points;
  final Color? fill;
  final Color? strokeColor;
  final double strokeWidth;
  final double opacity;

  _RawSvgElement({
    required this.name,
    required this.points,
    this.fill,
    this.strokeColor,
    this.strokeWidth = 0.0,
    this.opacity = 1.0,
  });
}
