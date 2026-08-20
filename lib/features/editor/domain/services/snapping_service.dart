import 'package:layerly/features/editor/domain/entities/canvas_page.dart';

class SnapResult {
  final double snappedX;
  final double snappedY;
  final List<SnapGuideLine> activeGuides;

  const SnapResult({
    required this.snappedX,
    required this.snappedY,
    this.activeGuides = const [],
  });
}

class SnapGuideLine {
  final bool isVertical; // true = vertical (has x coord), false = horizontal (has y coord)
  final double position;
  final String label;

  const SnapGuideLine({
    required this.isVertical,
    required this.position,
    this.label = '',
  });
}

class SnappingService {
  static const double snapThreshold = 6.0;

  static SnapResult calculateSnap({
    required double targetX,
    required double targetY,
    required double targetWidth,
    required double targetHeight,
    required CanvasPage page,
    required List<String> excludeLayerIds,
    bool snapEnabled = true,
  }) {
    if (!snapEnabled) {
      return SnapResult(snappedX: targetX, snappedY: targetY);
    }

    double finalX = targetX;
    double finalY = targetY;
    final List<SnapGuideLine> guides = [];

    // Target reference points
    final double targetLeft = targetX;
    final double targetCenterX = targetX + targetWidth / 2;
    final double targetRight = targetX + targetWidth;

    final double targetTop = targetY;
    final double targetCenterY = targetY + targetHeight / 2;
    final double targetBottom = targetY + targetHeight;

    // 1. Canvas Reference Points
    final List<double> verticalSnapPoints = [
      0.0,
      page.width / 2,
      page.width,
    ];

    final List<double> horizontalSnapPoints = [
      0.0,
      page.height / 2,
      page.height,
    ];

    // 2. Collect Other Layers Reference Points
    for (final layer in page.layers) {
      if (excludeLayerIds.contains(layer.id) || !layer.visible) continue;
      verticalSnapPoints.add(layer.x);
      verticalSnapPoints.add(layer.x + layer.width / 2);
      verticalSnapPoints.add(layer.x + layer.width);

      horizontalSnapPoints.add(layer.y);
      horizontalSnapPoints.add(layer.y + layer.height / 2);
      horizontalSnapPoints.add(layer.y + layer.height);
    }

    // Check vertical snaps (X-axis)
    bool snappedXAxis = false;
    for (final snapX in verticalSnapPoints) {
      // Left snap
      if ((targetLeft - snapX).abs() < snapThreshold && !snappedXAxis) {
        finalX = snapX;
        snappedXAxis = true;
        guides.add(SnapGuideLine(isVertical: true, position: snapX));
      }
      // Center snap
      else if ((targetCenterX - snapX).abs() < snapThreshold && !snappedXAxis) {
        finalX = snapX - targetWidth / 2;
        snappedXAxis = true;
        guides.add(SnapGuideLine(isVertical: true, position: snapX));
      }
      // Right snap
      else if ((targetRight - snapX).abs() < snapThreshold && !snappedXAxis) {
        finalX = snapX - targetWidth;
        snappedXAxis = true;
        guides.add(SnapGuideLine(isVertical: true, position: snapX));
      }
    }

    // Check horizontal snaps (Y-axis)
    bool snappedYAxis = false;
    for (final snapY in horizontalSnapPoints) {
      // Top snap
      if ((targetTop - snapY).abs() < snapThreshold && !snappedYAxis) {
        finalY = snapY;
        snappedYAxis = true;
        guides.add(SnapGuideLine(isVertical: false, position: snapY));
      }
      // Center snap
      else if ((targetCenterY - snapY).abs() < snapThreshold && !snappedYAxis) {
        finalY = snapY - targetHeight / 2;
        snappedYAxis = true;
        guides.add(SnapGuideLine(isVertical: false, position: snapY));
      }
      // Bottom snap
      else if ((targetBottom - snapY).abs() < snapThreshold && !snappedYAxis) {
        finalY = snapY - targetHeight;
        snappedYAxis = true;
        guides.add(SnapGuideLine(isVertical: false, position: snapY));
      }
    }

    return SnapResult(
      snappedX: finalX,
      snappedY: finalY,
      activeGuides: guides,
    );
  }
}
