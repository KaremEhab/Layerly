import 'dart:io';
import 'package:flutter/material.dart';
import 'package:layerly/features/editor/domain/entities/canvas_page.dart';
import 'package:layerly/features/editor/domain/entities/layer.dart';
import 'package:layerly/features/editor/domain/entities/text_layer.dart';
import 'package:layerly/features/editor/domain/entities/auto_layout_layer.dart';
import 'package:layerly/features/editor/domain/entities/layer_enums.dart';
import 'package:layerly/features/editor/domain/entities/component_definition.dart';
import 'package:layerly/features/editor/presentation/widgets/canvas/layer_view.dart';
import 'package:layerly/features/editor/presentation/widgets/canvas/transform_box.dart';
import 'package:layerly/features/editor/presentation/widgets/canvas/smart_guides_overlay.dart';
import 'package:layerly/features/editor/domain/services/snapping_service.dart';

class PageRenderer extends StatelessWidget {
  final CanvasPage page;
  final List<String> selectedLayerIds;
  final List<SnapGuideLine> activeGuides;
  final List<SpacingMeasurement> activeSpacingMeasurements;
  final double scale;
  final ComponentDefinition? Function(String id)? getComponentDefinition;
  final Function(String layerId, bool isMultiSelect)? onSelectLayer;
  final Function(String layerId, DragUpdateDetails details)? onMoveLayer;
  final Function(String layerId, DragEndDetails details)? onMoveLayerEnd;
  final Function(String layerId, ResizeHandle handle, DragUpdateDetails details)? onResizeLayer;
  final Function(String layerId, ResizeHandle handle, DragEndDetails details)? onResizeLayerEnd;
  final Function(String layerId, double angle, bool isFinal)? onRotateLayer;
  final Function(String layerId, Offset globalPosition)? onContextMenu;

  const PageRenderer({
    super.key,
    required this.page,
    required this.selectedLayerIds,
    this.activeGuides = const [],
    this.activeSpacingMeasurements = const [],
    this.scale = 1.0,
    this.getComponentDefinition,
    this.onSelectLayer,
    this.onMoveLayer,
    this.onMoveLayerEnd,
    this.onResizeLayer,
    this.onResizeLayerEnd,
    this.onRotateLayer,
    this.onContextMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: page.width,
      height: page.height,
      decoration: _buildBackgroundDecoration(),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Grid Overlay if enabled
          if (page.showGrid) _buildGridOverlay(),

          // Page Padding & Guides Overlay
          if (page.showGuides) _buildGuidesOverlay(),

          // Render all layers in z-index order
          ...page.layers.map((layer) => _buildLayerItem(layer)),

          // Smart Guides (snapping alignment lines & Figma spacing measurements)
          SmartGuidesOverlay(
            guides: activeGuides,
            measurements: activeSpacingMeasurements,
            pageWidth: page.width,
            pageHeight: page.height,
            scale: scale,
          ),
        ],
      ),
    );
  }

  Widget _buildGuidesOverlay() {
    return IgnorePointer(
      child: CustomPaint(
        size: Size(page.width, page.height),
        painter: _GuidesPainter(
          horizontalPadding: page.horizontalPadding,
          verticalPadding: page.verticalPadding,
        ),
      ),
    );
  }

  BoxDecoration _buildBackgroundDecoration() {
    switch (page.backgroundType) {
      case BackgroundType.transparent:
        return const BoxDecoration(color: Colors.transparent);
      case BackgroundType.solid:
        return BoxDecoration(color: page.backgroundColor);
      case BackgroundType.gradient:
        return BoxDecoration(
          color: page.backgroundColor,
          gradient: page.backgroundGradient,
        );
      case BackgroundType.image:
        if (page.backgroundImagePath != null &&
            File(page.backgroundImagePath!).existsSync()) {
          return BoxDecoration(
            image: DecorationImage(
              image: FileImage(File(page.backgroundImagePath!)),
              fit: BoxFit.cover,
            ),
          );
        }
        return BoxDecoration(color: page.backgroundColor);
    }
  }

  Widget _buildGridOverlay() {
    return IgnorePointer(
      child: CustomPaint(
        size: Size(page.width, page.height),
        painter: _GridPainter(),
      ),
    );
  }

  Widget _buildLayerItem(Layer layer) {
    final isSelected = selectedLayerIds.contains(layer.id);
    final effectiveLayer = layer is TextLayer
        ? (layer as TextLayer).copyWith(
            width: LayerView.measureTextSize(layer as TextLayer).width,
            height: LayerView.measureTextSize(layer as TextLayer).height,
          )
        : (layer is AutoLayoutLayer
            ? (layer as AutoLayoutLayer).copyWith(
                width: LayerView.measureAutoLayoutSize(layer as AutoLayoutLayer).width,
                height: LayerView.measureAutoLayoutSize(layer as AutoLayoutLayer).height,
              )
            : layer);

    Widget layerWidget = LayerView(
      layer: effectiveLayer,
      getComponentDefinition: getComponentDefinition,
      onSelectLayer: onSelectLayer,
      selectedLayerIds: selectedLayerIds,
      scale: scale,
      onResizeLayer: onResizeLayer,
      onResizeLayerEnd: onResizeLayerEnd,
      onRotateLayer: onRotateLayer,
    );

    // If selected and editable, attach TransformBox
    if (isSelected) {
      layerWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          layerWidget,
          TransformBox(
            layer: effectiveLayer,
            scale: scale,
            onResize: (handle, details) {
              onResizeLayer?.call(layer.id, handle, details);
            },
            onResizeEnd: (handle, details) {
              onResizeLayerEnd?.call(layer.id, handle, details);
            },
            onRotate: (angle, isFinal) {
              onRotateLayer?.call(layer.id, angle, isFinal);
            },
          ),
        ],
      );
    }

    final isInteractive = onSelectLayer != null || onMoveLayer != null || onContextMenu != null;

    final interactiveWidget = isInteractive
        ? GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onSelectLayer != null
                ? () {
                    onSelectLayer?.call(layer.id, false);
                  }
                : null,
            onSecondaryTapDown: onContextMenu != null
                ? (details) {
                    final isChildOrSelfSelected = isSelected || _isAnyChildSelected(layer, selectedLayerIds);
                    if (!isChildOrSelfSelected) {
                      onSelectLayer?.call(layer.id, false);
                    }
                    onContextMenu?.call(layer.id, details.globalPosition);
                  }
                : null,
            onLongPress: onSelectLayer != null
                ? () {
                    onSelectLayer?.call(layer.id, true);
                  }
                : null,
            onPanStart: onMoveLayer != null
                ? (details) {
                    if (!isSelected) {
                      onSelectLayer?.call(layer.id, false);
                    }
                  }
                : null,
            onPanUpdate: onMoveLayer != null
                ? (details) {
                    onMoveLayer?.call(layer.id, details);
                  }
                : null,
            onPanEnd: onMoveLayerEnd != null
                ? (details) {
                    onMoveLayerEnd?.call(layer.id, details);
                  }
                : null,
            child: layerWidget,
          )
        : layerWidget;

    return Positioned(
      left: effectiveLayer.x,
      top: effectiveLayer.y,
      width: effectiveLayer.width,
      height: effectiveLayer.height,
      child: Transform.rotate(
        angle: effectiveLayer.rotation,
        child: interactiveWidget,
      ),
    );
  }

  bool _isAnyChildSelected(Layer layer, List<String> selectedIds) {
    if (layer is AutoLayoutLayer) {
      for (final child in layer.children) {
        if (selectedIds.contains(child.id) || _isAnyChildSelected(child, selectedIds)) {
          return true;
        }
      }
    }
    return false;
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    const double step = 40.0;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GuidesPainter extends CustomPainter {
  final double horizontalPadding;
  final double verticalPadding;

  _GuidesPainter({
    required this.horizontalPadding,
    required this.verticalPadding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (horizontalPadding <= 0 && verticalPadding <= 0) return;

    final guidePaint = Paint()
      ..color = const Color(0xFF9B6CFF).withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = const Color(0xFF9B6CFF).withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;

    // Draw Margin Rectangle
    final marginRect = Rect.fromLTRB(
      horizontalPadding,
      verticalPadding,
      size.width - horizontalPadding,
      size.height - verticalPadding,
    );

    canvas.drawRect(marginRect, fillPaint);
    canvas.drawRect(marginRect, guidePaint);

    // Corner tick marks
    final tickPaint = Paint()
      ..color = const Color(0xFF9B6CFF).withValues(alpha: 0.9)
      ..strokeWidth = 2.0;

    const double tick = 12.0;
    // Top-Left
    canvas.drawLine(Offset(horizontalPadding, verticalPadding), Offset(horizontalPadding + tick, verticalPadding), tickPaint);
    canvas.drawLine(Offset(horizontalPadding, verticalPadding), Offset(horizontalPadding, verticalPadding + tick), tickPaint);
    // Top-Right
    canvas.drawLine(Offset(size.width - horizontalPadding, verticalPadding), Offset(size.width - horizontalPadding - tick, verticalPadding), tickPaint);
    canvas.drawLine(Offset(size.width - horizontalPadding, verticalPadding), Offset(size.width - horizontalPadding, verticalPadding + tick), tickPaint);
    // Bottom-Left
    canvas.drawLine(Offset(horizontalPadding, size.height - verticalPadding), Offset(horizontalPadding + tick, size.height - verticalPadding), tickPaint);
    canvas.drawLine(Offset(horizontalPadding, size.height - verticalPadding), Offset(horizontalPadding, size.height - verticalPadding - tick), tickPaint);
    // Bottom-Right
    canvas.drawLine(Offset(size.width - horizontalPadding, size.height - verticalPadding), Offset(size.width - horizontalPadding - tick, size.height - verticalPadding), tickPaint);
    canvas.drawLine(Offset(size.width - horizontalPadding, size.height - verticalPadding), Offset(size.width - horizontalPadding, size.height - verticalPadding - tick), tickPaint);
  }

  @override
  bool shouldRepaint(covariant _GuidesPainter oldDelegate) {
    return oldDelegate.horizontalPadding != horizontalPadding ||
        oldDelegate.verticalPadding != verticalPadding;
  }
}

