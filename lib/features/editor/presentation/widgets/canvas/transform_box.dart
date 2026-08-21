import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:layerly/features/editor/domain/entities/layer.dart';
import 'package:layerly/features/editor/domain/entities/layer_enums.dart';

class TransformBox extends StatelessWidget {
  final Layer layer;
  final double scale;
  final Function(ResizeHandle handle, DragUpdateDetails details) onResize;
  final Function(ResizeHandle handle, DragEndDetails details) onResizeEnd;
  final Function(double deltaAngle, bool isFinal) onRotate;

  const TransformBox({
    super.key,
    required this.layer,
    required this.scale,
    required this.onResize,
    required this.onResizeEnd,
    required this.onRotate,
  });

  static const double handleSize = 10.0;
  static const double rotationStemHeight = 26.0;

  @override
  Widget build(BuildContext context) {
    if (layer.locked) {
      return _buildLockedBorder();
    }

    final effectiveScale = scale.clamp(0.2, 3.0);
    final isCompact = layer.width < 50 || layer.height < 40;

    // Balanced scale-invariant dimensions for crisp, comfortable visibility on mobile
    final pillFontSize = (10.5 / effectiveScale).clamp(10.0, 19.0);
    final pillPadH = (7.0 / effectiveScale).clamp(6.0, 15.0);
    final pillPadV = (3.5 / effectiveScale).clamp(3.0, 8.0);
    final pillRadius = (4.0 / effectiveScale).clamp(3.0, 7.0);
    final pillBorderWidth = (1.0 / effectiveScale).clamp(0.8, 1.8);

    final stemHeight = (22.0 / effectiveScale).clamp(18.0, 36.0);
    final rotHandleSize = (9.5 / effectiveScale).clamp(8.0, 16.0);
    final rotBorderWidth = (1.5 / effectiveScale).clamp(1.2, 2.2);

    final baseHandleSize = (8.5 / effectiveScale).clamp(7.0, 14.0);
    final effectiveHandleSize = isCompact
        ? baseHandleSize * 0.75
        : baseHandleSize;
    final handleRadius = (2.0 / effectiveScale).clamp(2.0, 3.5);
    final handleBorderWidth = (1.2 / effectiveScale).clamp(1.0, 2.0);

    final pillTop = -stemHeight - (rotHandleSize / 2) - (14.0 / effectiveScale);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Selection Border
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFFA970FF),
                  width: 1.5 / effectiveScale,
                ),
              ),
            ),
          ),
        ),

        // Live Dimension & Coordinate Pill (Only on spacious items with unconstrained width)
        if (!isCompact)
          Positioned(
            top: pillTop,
            left: -200,
            right: -200,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: pillPadH,
                    vertical: pillPadV,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF15161B),
                    borderRadius: BorderRadius.circular(pillRadius),
                    border: Border.all(
                      color: const Color(0xFFA970FF),
                      width: pillBorderWidth,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '${layer.width.toInt()} × ${layer.height.toInt()}  |  X: ${layer.x.toInt()}, Y: ${layer.y.toInt()}',
                    softWrap: false,
                    maxLines: 1,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: pillFontSize,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Rotation stem line & handle (for regular/larger elements)
        if (!isCompact) ...[
          Positioned(
            top: -stemHeight,
            left: layer.width / 2 - (0.75 / effectiveScale),
            child: IgnorePointer(
              child: Container(
                width: 1.5 / effectiveScale,
                height: stemHeight,
                color: const Color(0xFFA970FF),
              ),
            ),
          ),
          Positioned(
            top: -stemHeight - (rotHandleSize / 2),
            left: layer.width / 2 - (rotHandleSize / 2),
            child: GestureDetector(
              onPanUpdate: (details) {
                final center = layer.center;
                final currentTouch = Offset(
                  layer.x + layer.width / 2 + details.delta.dx,
                  layer.y - stemHeight + details.delta.dy,
                );
                final angle =
                    math.atan2(
                      currentTouch.dy - center.dy,
                      currentTouch.dx - center.dx,
                    ) +
                    (math.pi / 2);
                onRotate(angle, false);
              },
              onPanEnd: (_) => onRotate(layer.rotation, true),
              child: MouseRegion(
                cursor: SystemMouseCursors.grab,
                child: Container(
                  width: rotHandleSize,
                  height: rotHandleSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFA970FF),
                      width: rotBorderWidth,
                    ),
                    boxShadow: const [
                      BoxShadow(color: Colors.black38, blurRadius: 4),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],

        // 4 Corner Handles (Always present, sized appropriately)
        _buildHandle(
          ResizeHandle.topLeft,
          -effectiveHandleSize / 2,
          -effectiveHandleSize / 2,
          effectiveHandleSize,
          handleRadius,
          handleBorderWidth,
          SystemMouseCursors.resizeUpLeft,
        ),
        _buildHandle(
          ResizeHandle.topRight,
          layer.width - effectiveHandleSize / 2,
          -effectiveHandleSize / 2,
          effectiveHandleSize,
          handleRadius,
          handleBorderWidth,
          SystemMouseCursors.resizeUpRight,
        ),
        _buildHandle(
          ResizeHandle.bottomRight,
          layer.width - effectiveHandleSize / 2,
          layer.height - effectiveHandleSize / 2,
          effectiveHandleSize,
          handleRadius,
          handleBorderWidth,
          SystemMouseCursors.resizeDownRight,
        ),
        _buildHandle(
          ResizeHandle.bottomLeft,
          -effectiveHandleSize / 2,
          layer.height - effectiveHandleSize / 2,
          effectiveHandleSize,
          handleRadius,
          handleBorderWidth,
          SystemMouseCursors.resizeDownLeft,
        ),

        // 4 Center Edge Handles (Only on regular/larger elements)
        if (!isCompact) ...[
          _buildHandle(
            ResizeHandle.topCenter,
            layer.width / 2 - baseHandleSize / 2,
            -baseHandleSize / 2,
            baseHandleSize,
            handleRadius,
            handleBorderWidth,
            SystemMouseCursors.resizeUp,
          ),
          _buildHandle(
            ResizeHandle.centerRight,
            layer.width - baseHandleSize / 2,
            layer.height / 2 - baseHandleSize / 2,
            baseHandleSize,
            handleRadius,
            handleBorderWidth,
            SystemMouseCursors.resizeRight,
          ),
          _buildHandle(
            ResizeHandle.bottomCenter,
            layer.width / 2 - baseHandleSize / 2,
            layer.height - baseHandleSize / 2,
            baseHandleSize,
            handleRadius,
            handleBorderWidth,
            SystemMouseCursors.resizeDown,
          ),
          _buildHandle(
            ResizeHandle.centerLeft,
            -baseHandleSize / 2,
            layer.height / 2 - baseHandleSize / 2,
            baseHandleSize,
            handleRadius,
            handleBorderWidth,
            SystemMouseCursors.resizeLeft,
          ),
        ],
      ],
    );
  }

  Widget _buildLockedBorder() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFFFF5C5C),
              width: 1.5 / scale.clamp(0.5, 2.0),
              strokeAlign: BorderSide.strokeAlignOutside,
            ),
          ),
          child: const Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(Icons.lock, color: Color(0xFFFF5C5C), size: 14),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHandle(
    ResizeHandle handle,
    double left,
    double top,
    double size,
    double radius,
    double borderWidth,
    MouseCursor cursor,
  ) {
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onPanUpdate: (details) => onResize(handle, details),
        onPanEnd: (details) => onResizeEnd(handle, details),
        child: MouseRegion(
          cursor: cursor,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: const Color(0xFFA970FF),
                width: borderWidth,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
