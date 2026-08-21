import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:layerly/features/editor/domain/entities/canvas_page.dart';

class SpacingMeasurement {
  final bool isVertical; // true = vertical gap, false = horizontal gap
  final double start; // start coordinate along the measurement axis
  final double end; // end coordinate along the measurement axis
  final double crossAxisPos; // X pos for vertical, Y pos for horizontal
  final double distance;
  final String label;
  final double? railMin;
  final double? railMax;
  final List<double> railCrossPositions;

  const SpacingMeasurement({
    required this.isVertical,
    required this.start,
    required this.end,
    required this.crossAxisPos,
    required this.distance,
    this.label = '',
    this.railMin,
    this.railMax,
    this.railCrossPositions = const [],
  });
}

class SnapResult {
  final double snappedX;
  final double snappedY;
  final List<SnapGuideLine> activeGuides;
  final List<SpacingMeasurement> spacingMeasurements;

  const SnapResult({
    required this.snappedX,
    required this.snappedY,
    this.activeGuides = const [],
    this.spacingMeasurements = const [],
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
    final List<SpacingMeasurement> measurements = [];

    // Target reference points
    final double targetLeft = targetX;
    final double targetCenterX = targetX + targetWidth / 2;
    final double targetRight = targetX + targetWidth;

    final double targetTop = targetY;
    final double targetCenterY = targetY + targetHeight / 2;
    final double targetBottom = targetY + targetHeight;

    // 1. Canvas Reference Points & Page Margins
    final List<double> verticalSnapPoints = [
      0.0,
      if (page.horizontalPadding > 0) page.horizontalPadding,
      page.width / 2,
      if (page.horizontalPadding > 0) page.width - page.horizontalPadding,
      page.width,
    ];

    final List<double> horizontalSnapPoints = [
      0.0,
      if (page.verticalPadding > 0) page.verticalPadding,
      page.height / 2,
      if (page.verticalPadding > 0) page.height - page.verticalPadding,
      page.height,
    ];

    // Collect Other Layers Bounding Rectangles
    final List<Rect> otherRects = [];
    for (final layer in page.layers) {
      if (excludeLayerIds.contains(layer.id) || !layer.visible) continue;
      verticalSnapPoints.add(layer.x);
      verticalSnapPoints.add(layer.x + layer.width / 2);
      verticalSnapPoints.add(layer.x + layer.width);

      horizontalSnapPoints.add(layer.y);
      horizontalSnapPoints.add(layer.y + layer.height / 2);
      horizontalSnapPoints.add(layer.y + layer.height);

      otherRects.add(Rect.fromLTWH(layer.x, layer.y, layer.width, layer.height));
    }

    // Check vertical snaps (X-axis alignment)
    bool snappedXAxis = false;
    for (final snapX in verticalSnapPoints) {
      if ((targetLeft - snapX).abs() < snapThreshold && !snappedXAxis) {
        finalX = snapX;
        snappedXAxis = true;
        guides.add(SnapGuideLine(isVertical: true, position: snapX));
      } else if ((targetCenterX - snapX).abs() < snapThreshold && !snappedXAxis) {
        finalX = snapX - targetWidth / 2;
        snappedXAxis = true;
        guides.add(SnapGuideLine(isVertical: true, position: snapX));
      } else if ((targetRight - snapX).abs() < snapThreshold && !snappedXAxis) {
        finalX = snapX - targetWidth;
        snappedXAxis = true;
        guides.add(SnapGuideLine(isVertical: true, position: snapX));
      }
    }

    // Check horizontal snaps (Y-axis alignment)
    bool snappedYAxis = false;
    for (final snapY in horizontalSnapPoints) {
      if ((targetTop - snapY).abs() < snapThreshold && !snappedYAxis) {
        finalY = snapY;
        snappedYAxis = true;
        guides.add(SnapGuideLine(isVertical: false, position: snapY));
      } else if ((targetCenterY - snapY).abs() < snapThreshold && !snappedYAxis) {
        finalY = snapY - targetHeight / 2;
        snappedYAxis = true;
        guides.add(SnapGuideLine(isVertical: false, position: snapY));
      } else if ((targetBottom - snapY).abs() < snapThreshold && !snappedYAxis) {
        finalY = snapY - targetHeight;
        snappedYAxis = true;
        guides.add(SnapGuideLine(isVertical: false, position: snapY));
      }
    }

    // 2. EQUAL SPACING & DISTANCE DETECTION (VERTICAL AXIS)
    if (otherRects.isNotEmpty) {
      // Find candidate rects with overlapping or aligned X range
      final colRects = otherRects.where((r) {
        final overlapX = math.max(0.0, math.min(targetRight, r.right) - math.max(targetLeft, r.left));
        final centerDistX = ((targetLeft + targetRight) / 2 - (r.left + r.right) / 2).abs();
        return overlapX > 0 || centerDistX < math.max(targetWidth, r.width) * 0.8;
      }).toList();

      if (colRects.length >= 2) {
        colRects.sort((a, b) => a.top.compareTo(b.top));

        // Check for reference pairs (A, B) with positive gap
        for (int i = 0; i < colRects.length - 1; i++) {
          final a = colRects[i];
          final b = colRects[i + 1];
          final double refGap = b.top - a.bottom;
          if (refGap <= 2) continue;

          final double targetMidX = finalX + targetWidth / 2;
          final double sharedLeft = math.min(a.left, math.min(b.left, finalX));
          final double sharedRight = math.max(a.right, math.max(b.right, finalX + targetWidth));

          // Case A: Target placed below B
          final double gapBelow = finalY - b.bottom;
          if ((gapBelow - refGap).abs() <= snapThreshold) {
            finalY = b.bottom + refGap;
            final double railStart = a.top;
            final double railEnd = finalY + targetHeight;

            measurements.add(SpacingMeasurement(
              isVertical: true,
              start: a.bottom,
              end: b.top,
              crossAxisPos: (a.left + a.right) / 2,
              distance: refGap,
              railMin: railStart,
              railMax: railEnd,
              railCrossPositions: [sharedLeft, sharedRight],
            ));
            measurements.add(SpacingMeasurement(
              isVertical: true,
              start: b.bottom,
              end: finalY,
              crossAxisPos: targetMidX,
              distance: refGap,
              railMin: railStart,
              railMax: railEnd,
              railCrossPositions: [sharedLeft, sharedRight],
            ));
            break;
          }

          // Case B: Target placed between A and B
          if (finalY > a.bottom && (finalY + targetHeight) < b.top) {
            final double gapTop = finalY - a.bottom;
            final double gapBottom = b.top - (finalY + targetHeight);
            if ((gapTop - gapBottom).abs() <= snapThreshold * 2) {
              final double equalGap = (b.top - a.bottom - targetHeight) / 2;
              finalY = a.bottom + equalGap;
              final double railStart = a.top;
              final double railEnd = b.bottom;

              measurements.add(SpacingMeasurement(
                isVertical: true,
                start: a.bottom,
                end: finalY,
                crossAxisPos: targetMidX,
                distance: equalGap,
                railMin: railStart,
                railMax: railEnd,
                railCrossPositions: [sharedLeft, sharedRight],
              ));
              measurements.add(SpacingMeasurement(
                isVertical: true,
                start: finalY + targetHeight,
                end: b.top,
                crossAxisPos: targetMidX,
                distance: equalGap,
                railMin: railStart,
                railMax: railEnd,
                railCrossPositions: [sharedLeft, sharedRight],
              ));
              break;
            }
          }

          // Case C: Target placed above A
          final double gapAbove = a.top - (finalY + targetHeight);
          if ((gapAbove - refGap).abs() <= snapThreshold) {
            finalY = a.top - targetHeight - refGap;
            final double railStart = finalY;
            final double railEnd = b.bottom;

            measurements.add(SpacingMeasurement(
              isVertical: true,
              start: finalY + targetHeight,
              end: a.top,
              crossAxisPos: targetMidX,
              distance: refGap,
              railMin: railStart,
              railMax: railEnd,
              railCrossPositions: [sharedLeft, sharedRight],
            ));
            measurements.add(SpacingMeasurement(
              isVertical: true,
              start: a.bottom,
              end: b.top,
              crossAxisPos: (a.left + a.right) / 2,
              distance: refGap,
              railMin: railStart,
              railMax: railEnd,
              railCrossPositions: [sharedLeft, sharedRight],
            ));
            break;
          }
        }
      }

      // If no equal spacing was triggered, check single nearest vertical neighbor distance
      if (measurements.isEmpty && colRects.isNotEmpty) {
        Rect? nearestAbove;
        Rect? nearestBelow;
        for (final r in colRects) {
          if (r.bottom <= finalY && (nearestAbove == null || r.bottom > nearestAbove.bottom)) {
            nearestAbove = r;
          }
          if (r.top >= (finalY + targetHeight) && (nearestBelow == null || r.top < nearestBelow.top)) {
            nearestBelow = r;
          }
        }

        if (nearestAbove != null) {
          final double gap = finalY - nearestAbove.bottom;
          if (gap > 0 && gap < 250) {
            final double midX = finalX + targetWidth / 2;
            measurements.add(SpacingMeasurement(
              isVertical: true,
              start: nearestAbove.bottom,
              end: finalY,
              crossAxisPos: midX,
              distance: gap,
              railMin: nearestAbove.top,
              railMax: finalY + targetHeight,
              railCrossPositions: [
                math.min(nearestAbove.left, finalX),
                math.max(nearestAbove.right, finalX + targetWidth),
              ],
            ));
          }
        } else if (nearestBelow != null) {
          final double gap = nearestBelow.top - (finalY + targetHeight);
          if (gap > 0 && gap < 250) {
            final double midX = finalX + targetWidth / 2;
            measurements.add(SpacingMeasurement(
              isVertical: true,
              start: finalY + targetHeight,
              end: nearestBelow.top,
              crossAxisPos: midX,
              distance: gap,
              railMin: finalY,
              railMax: nearestBelow.bottom,
              railCrossPositions: [
                math.min(nearestBelow.left, finalX),
                math.max(nearestBelow.right, finalX + targetWidth),
              ],
            ));
          }
        }
      }

      // 3. EQUAL SPACING & DISTANCE DETECTION (HORIZONTAL AXIS)
      final rowRects = otherRects.where((r) {
        final overlapY = math.max(0.0, math.min(targetBottom, r.bottom) - math.max(targetTop, r.top));
        final centerDistY = ((targetTop + targetBottom) / 2 - (r.top + r.bottom) / 2).abs();
        return overlapY > 0 || centerDistY < math.max(targetHeight, r.height) * 0.8;
      }).toList();

      if (rowRects.length >= 2) {
        rowRects.sort((a, b) => a.left.compareTo(b.left));

        for (int i = 0; i < rowRects.length - 1; i++) {
          final a = rowRects[i];
          final b = rowRects[i + 1];
          final double refGap = b.left - a.right;
          if (refGap <= 2) continue;

          final double targetMidY = finalY + targetHeight / 2;
          final double sharedTop = math.min(a.top, math.min(b.top, finalY));
          final double sharedBottom = math.max(a.bottom, math.max(b.bottom, finalY + targetHeight));

          // Target placed to the right of B
          final double gapRight = finalX - b.right;
          if ((gapRight - refGap).abs() <= snapThreshold) {
            finalX = b.right + refGap;
            final double railStart = a.left;
            final double railEnd = finalX + targetWidth;

            measurements.add(SpacingMeasurement(
              isVertical: false,
              start: a.right,
              end: b.left,
              crossAxisPos: (a.top + a.bottom) / 2,
              distance: refGap,
              railMin: railStart,
              railMax: railEnd,
              railCrossPositions: [sharedTop, sharedBottom],
            ));
            measurements.add(SpacingMeasurement(
              isVertical: false,
              start: b.right,
              end: finalX,
              crossAxisPos: targetMidY,
              distance: refGap,
              railMin: railStart,
              railMax: railEnd,
              railCrossPositions: [sharedTop, sharedBottom],
            ));
            break;
          }
        }
      }
    }

    return SnapResult(
      snappedX: finalX,
      snappedY: finalY,
      activeGuides: guides,
      spacingMeasurements: measurements,
    );
  }
}
