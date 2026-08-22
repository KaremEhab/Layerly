import 'package:flutter/material.dart';

class MoreRingsPainter extends CustomPainter {
  final Color color;
  final double ringRadius;
  final double strokeWidth;
  final double spacing;

  const MoreRingsPainter({
    this.color = Colors.white,
    this.ringRadius = 2.4,
    this.strokeWidth = 1.6,
    this.spacing = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final cy = size.height / 2;
    final cx = size.width / 2;

    // 1px space between outer edges of rings
    final outerDiameter = (ringRadius * 2) + strokeWidth;
    final centerDistance = outerDiameter + spacing;

    canvas.drawCircle(Offset(cx - centerDistance, cy), ringRadius, stroke);
    canvas.drawCircle(Offset(cx, cy), ringRadius, stroke);
    canvas.drawCircle(Offset(cx + centerDistance, cy), ringRadius, stroke);
  }

  @override
  bool shouldRepaint(covariant MoreRingsPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.ringRadius != ringRadius ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.spacing != spacing;
}

class MoreRingsIcon extends StatelessWidget {
  final double size;
  final Color color;
  final double ringRadius;
  final double strokeWidth;
  final double spacing;

  const MoreRingsIcon({
    super.key,
    this.size = 22,
    this.color = Colors.white,
    this.ringRadius = 2.4,
    this.strokeWidth = 1.6,
    this.spacing = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: CustomPaint(
          size: Size(size, size),
          painter: MoreRingsPainter(
            color: color,
            ringRadius: ringRadius,
            strokeWidth: strokeWidth,
            spacing: spacing,
          ),
        ),
      ),
    );
  }
}
