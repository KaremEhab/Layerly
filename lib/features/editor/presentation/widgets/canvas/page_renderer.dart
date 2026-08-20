import 'dart:io';
import 'package:flutter/material.dart';
import 'package:layerly/features/editor/domain/entities/canvas_page.dart';
import 'package:layerly/features/editor/domain/entities/layer.dart';
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
  final double scale;
  final ComponentDefinition? Function(String id)? getComponentDefinition;
  final Function(String layerId, bool isMultiSelect)? onSelectLayer;
  final Function(String layerId, DragUpdateDetails details)? onMoveLayer;
  final Function(String layerId, DragEndDetails details)? onMoveLayerEnd;
  final Function(String layerId, ResizeHandle handle, DragUpdateDetails details)? onResizeLayer;
  final Function(String layerId, ResizeHandle handle, DragEndDetails details)? onResizeLayerEnd;
  final Function(String layerId, double angle, bool isFinal)? onRotateLayer;

  const PageRenderer({
    super.key,
    required this.page,
    required this.selectedLayerIds,
    this.activeGuides = const [],
    this.scale = 1.0,
    this.getComponentDefinition,
    this.onSelectLayer,
    this.onMoveLayer,
    this.onMoveLayerEnd,
    this.onResizeLayer,
    this.onResizeLayerEnd,
    this.onRotateLayer,
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

          // Render all layers in z-index order
          ...page.layers.map((layer) => _buildLayerItem(layer)),

          // Smart Guides (snapping alignment lines)
          SmartGuidesOverlay(
            guides: activeGuides,
            pageWidth: page.width,
            pageHeight: page.height,
          ),
        ],
      ),
    );
  }

  BoxDecoration _buildBackgroundDecoration() {
    switch (page.backgroundType) {
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
    return CustomPaint(
      size: Size(page.width, page.height),
      painter: _GridPainter(),
    );
  }

  Widget _buildLayerItem(Layer layer) {
    final isSelected = selectedLayerIds.contains(layer.id);

    Widget layerWidget = LayerView(
      layer: layer,
      getComponentDefinition: getComponentDefinition,
    );

    // If selected and editable, attach TransformBox
    if (isSelected) {
      layerWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          layerWidget,
          TransformBox(
            layer: layer,
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

    return Positioned(
      left: layer.x,
      top: layer.y,
      width: layer.width,
      height: layer.height,
      child: Transform.rotate(
        angle: layer.rotation,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (details) {
            onSelectLayer?.call(layer.id, false);
          },
          onPanUpdate: (details) {
            if (isSelected) {
              onMoveLayer?.call(layer.id, details);
            }
          },
          onPanEnd: (details) {
            if (isSelected) {
              onMoveLayerEnd?.call(layer.id, details);
            }
          },
          child: layerWidget,
        ),
      ),
    );
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
