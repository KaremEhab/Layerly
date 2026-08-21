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
                  width: 1.5 / scale.clamp(0.5, 2.0),
                ),
              ),
            ),
          ),
        ),

        // Live Dimension & Coordinate Pill
        Positioned(
          top: -28,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF15161B),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFA970FF), width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${layer.width.toInt()} × ${layer.height.toInt()}  |  X: ${layer.x.toInt()}, Y: ${layer.y.toInt()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ),
        ),

        // Rotation stem line
        Positioned(
          top: -rotationStemHeight,
          left: layer.width / 2 - 0.5,
          child: IgnorePointer(
            child: Container(
              width: 1.5,
              height: rotationStemHeight,
              color: const Color(0xFFA970FF),
            ),
          ),
        ),
        Positioned(
          top: -rotationStemHeight - (handleSize / 2),
          left: layer.width / 2 - (handleSize / 2),
          child: GestureDetector(
            onPanUpdate: (details) {
              final center = layer.center;
              final currentTouch = Offset(layer.x + layer.width / 2 + details.delta.dx, layer.y - rotationStemHeight + details.delta.dy);
              final angle = math.atan2(currentTouch.dy - center.dy, currentTouch.dx - center.dx) + (math.pi / 2);
              onRotate(angle, false);
            },
            onPanEnd: (_) => onRotate(layer.rotation, true),
            child: MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: Container(
                width: handleSize + 2,
                height: handleSize + 2,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFA970FF), width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black38, blurRadius: 4),
                  ],
                ),
              ),
            ),
          ),
        ),

        // 8 Corner & Edge Handles
        _buildHandle(ResizeHandle.topLeft, -handleSize / 2, -handleSize / 2, SystemMouseCursors.resizeUpLeft),
        _buildHandle(ResizeHandle.topCenter, layer.width / 2 - handleSize / 2, -handleSize / 2, SystemMouseCursors.resizeUp),
        _buildHandle(ResizeHandle.topRight, layer.width - handleSize / 2, -handleSize / 2, SystemMouseCursors.resizeUpRight),
        _buildHandle(ResizeHandle.centerRight, layer.width - handleSize / 2, layer.height / 2 - handleSize / 2, SystemMouseCursors.resizeRight),
        _buildHandle(ResizeHandle.bottomRight, layer.width - handleSize / 2, layer.height - handleSize / 2, SystemMouseCursors.resizeDownRight),
        _buildHandle(ResizeHandle.bottomCenter, layer.width / 2 - handleSize / 2, layer.height - handleSize / 2, SystemMouseCursors.resizeDown),
        _buildHandle(ResizeHandle.bottomLeft, -handleSize / 2, layer.height - handleSize / 2, SystemMouseCursors.resizeDownLeft),
        _buildHandle(ResizeHandle.centerLeft, -handleSize / 2, layer.height / 2 - handleSize / 2, SystemMouseCursors.resizeLeft),
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
              width: 1.5,
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
            width: handleSize,
            height: handleSize,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: const Color(0xFFA970FF), width: 1.5),
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
