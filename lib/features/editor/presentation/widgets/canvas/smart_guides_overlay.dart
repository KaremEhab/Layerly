import 'package:flutter/material.dart';
import 'package:layerly/features/editor/domain/services/snapping_service.dart';

class SmartGuidesOverlay extends StatelessWidget {
  final List<SnapGuideLine> guides;
  final double pageWidth;
  final double pageHeight;

  const SmartGuidesOverlay({
    super.key,
    required this.guides,
    required this.pageWidth,
    required this.pageHeight,
  });

  @override
  Widget build(BuildContext context) {
    if (guides.isEmpty) {
      return const SizedBox.shrink();
    }

    return CustomPaint(
      size: Size(pageWidth, pageHeight),
      painter: _SmartGuidesPainter(guides),
    );
  }
}

class _SmartGuidesPainter extends CustomPainter {
  final List<SnapGuideLine> guides;

  _SmartGuidesPainter(this.guides);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF007F)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (final guide in guides) {
      if (guide.isVertical) {
        canvas.drawLine(
          Offset(guide.position, 0),
          Offset(guide.position, size.height),
          paint,
        );
      } else {
        canvas.drawLine(
          Offset(0, guide.position),
          Offset(size.width, guide.position),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SmartGuidesPainter oldDelegate) {
    return oldDelegate.guides != guides;
  }
}
