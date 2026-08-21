import 'package:flutter/material.dart';
import 'package:layerly/features/editor/domain/services/snapping_service.dart';

class SmartGuidesOverlay extends StatelessWidget {
  final List<SnapGuideLine> guides;
  final List<SpacingMeasurement> measurements;
  final double pageWidth;
  final double pageHeight;
  final double scale;

  const SmartGuidesOverlay({
    super.key,
    required this.guides,
    this.measurements = const [],
    required this.pageWidth,
    required this.pageHeight,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    if (guides.isEmpty && measurements.isEmpty) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: CustomPaint(
        size: Size(pageWidth, pageHeight),
        painter: _SmartGuidesPainter(
          guides: guides,
          measurements: measurements,
          scale: scale > 0 ? scale : 1.0,
        ),
      ),
    );
  }
}

class _SmartGuidesPainter extends CustomPainter {
  final List<SnapGuideLine> guides;
  final List<SpacingMeasurement> measurements;
  final double scale;

  _SmartGuidesPainter({
    required this.guides,
    required this.measurements,
    this.scale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const coralColor = Color(0xFFF24E1E); // Figma signature smart guide coral color

    // Scale-aware stroke and sizing so numbers and lines are crisp and easily readable on mobile
    final effectiveScale = scale.clamp(0.2, 2.5);
    final strokeW = (1.2 / effectiveScale).clamp(1.2, 3.2);
    final tickLen = (3.5 / effectiveScale).clamp(3.0, 8.0);

    final guidePaint = Paint()
      ..color = coralColor
      ..strokeWidth = strokeW
      ..style = PaintingStyle.stroke;

    final railPaint = Paint()
      ..color = coralColor.withValues(alpha: 0.85)
      ..strokeWidth = strokeW
      ..style = PaintingStyle.stroke;

    final pillFillPaint = Paint()
      ..color = coralColor
      ..style = PaintingStyle.fill;

    // 1. Draw Full Axis Snap Guides
    for (final guide in guides) {
      if (guide.isVertical) {
        canvas.drawLine(
          Offset(guide.position, 0),
          Offset(guide.position, size.height),
          guidePaint,
        );
      } else {
        canvas.drawLine(
          Offset(0, guide.position),
          Offset(size.width, guide.position),
          guidePaint,
        );
      }
    }

    // 2. Draw Figma-Style Spacing Measurements & Boundary Rails
    final drawnRails = <String>{};

    for (final m in measurements) {
      // Draw Boundary Rail Lines along left/right or top/bottom edges
      if (m.railMin != null && m.railMax != null) {
        for (final crossPos in m.railCrossPositions) {
          final railKey = '${m.isVertical}_$crossPos';
          if (drawnRails.add(railKey)) {
            if (m.isVertical) {
              canvas.drawLine(
                Offset(crossPos, m.railMin!),
                Offset(crossPos, m.railMax!),
                railPaint,
              );
              _drawTick(canvas, Offset(crossPos, m.railMin!), tickLen, isVertical: true);
              _drawTick(canvas, Offset(crossPos, m.railMax!), tickLen, isVertical: true);
            } else {
              canvas.drawLine(
                Offset(m.railMin!, crossPos),
                Offset(m.railMax!, crossPos),
                railPaint,
              );
              _drawTick(canvas, Offset(m.railMin!, crossPos), tickLen, isVertical: false);
              _drawTick(canvas, Offset(m.railMax!, crossPos), tickLen, isVertical: false);
            }
          }
        }
      }

      // Draw Center Measurement Line & Badge Pill
      if (m.isVertical) {
        // Vertical stem line between items
        canvas.drawLine(
          Offset(m.crossAxisPos, m.start),
          Offset(m.crossAxisPos, m.end),
          guidePaint,
        );
        // Small caps at endpoints
        canvas.drawLine(
          Offset(m.crossAxisPos - tickLen, m.start),
          Offset(m.crossAxisPos + tickLen, m.start),
          guidePaint,
        );
        canvas.drawLine(
          Offset(m.crossAxisPos - tickLen, m.end),
          Offset(m.crossAxisPos + tickLen, m.end),
          guidePaint,
        );

        // Distance Badge Pill
        final pillCenter = Offset(m.crossAxisPos, (m.start + m.end) / 2);
        _drawDistancePill(canvas, pillCenter, m.distance.round().toString(), pillFillPaint, effectiveScale);
      } else {
        // Horizontal stem line between items
        canvas.drawLine(
          Offset(m.start, m.crossAxisPos),
          Offset(m.end, m.crossAxisPos),
          guidePaint,
        );
        // Small caps at endpoints
        canvas.drawLine(
          Offset(m.start, m.crossAxisPos - tickLen),
          Offset(m.start, m.crossAxisPos + tickLen),
          guidePaint,
        );
        canvas.drawLine(
          Offset(m.end, m.crossAxisPos - tickLen),
          Offset(m.end, m.crossAxisPos + tickLen),
          guidePaint,
        );

        // Distance Badge Pill
        final pillCenter = Offset((m.start + m.end) / 2, m.crossAxisPos);
        _drawDistancePill(canvas, pillCenter, m.distance.round().toString(), pillFillPaint, effectiveScale);
      }
    }
  }

  void _drawTick(Canvas canvas, Offset point, double tick, {required bool isVertical}) {
    final tickPaint = Paint()
      ..color = const Color(0xFFF24E1E)
      ..strokeWidth = (1.4 / scale.clamp(0.2, 2.5)).clamp(1.5, 4.0)
      ..style = PaintingStyle.stroke;

    if (isVertical) {
      canvas.drawLine(Offset(point.dx - tick, point.dy), Offset(point.dx + tick, point.dy), tickPaint);
    } else {
      canvas.drawLine(Offset(point.dx, point.dy - tick), Offset(point.dx, point.dy + tick), tickPaint);
    }
  }

  void _drawDistancePill(
    Canvas canvas,
    Offset center,
    String text,
    Paint fillPaint,
    double effectiveScale,
  ) {
    // Dynamic font size scaled to look like ~11-11.5pt on phone screens
    final fontSize = (11.0 / effectiveScale).clamp(13.0, 28.0);
    final padH = (5.5 / effectiveScale).clamp(6.0, 15.0);
    final padV = (3.0 / effectiveScale).clamp(3.5, 9.0);
    final radius = (3.0 / effectiveScale).clamp(3.0, 7.0);

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          fontFamily: 'Inter',
          height: 1.0,
          letterSpacing: 0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final pillWidth = textPainter.width + padH * 2;
    final pillHeight = textPainter.height + padV * 2;

    final pillRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: pillWidth, height: pillHeight),
      Radius.circular(radius),
    );

    // Subtle drop shadow for crisp contrast over any dark/light background
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    canvas.drawRRect(pillRect.shift(Offset(0, (1.0 / effectiveScale).clamp(1.0, 3.0))), shadowPaint);

    canvas.drawRRect(pillRect, fillPaint);
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _SmartGuidesPainter oldDelegate) {
    return oldDelegate.guides != guides ||
        oldDelegate.measurements != measurements ||
        oldDelegate.scale != scale;
  }
}
