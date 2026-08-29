import 'package:flutter/material.dart';
import 'layer.dart';
import 'layer_enums.dart';

/// A single vector anchor point / vertex in a Figma-style vector path.
class VectorPoint {
  /// Normalized coordinates (0.0 to 1.0) relative to element/layer width & height.
  final double x;
  final double y;
  final double? handleInX;
  final double? handleInY;
  final double? handleOutX;
  final double? handleOutY;
  final bool isSmooth;

  const VectorPoint({
    required this.x,
    required this.y,
    this.handleInX,
    this.handleInY,
    this.handleOutX,
    this.handleOutY,
    this.isSmooth = false,
  });

  VectorPoint copyWith({
    double? x,
    double? y,
    double? handleInX,
    double? handleInY,
    double? handleOutX,
    double? handleOutY,
    bool? isSmooth,
    bool clearHandles = false,
  }) {
    return VectorPoint(
      x: x ?? this.x,
      y: y ?? this.y,
      handleInX: clearHandles ? null : (handleInX ?? this.handleInX),
      handleInY: clearHandles ? null : (handleInY ?? this.handleInY),
      handleOutX: clearHandles ? null : (handleOutX ?? this.handleOutX),
      handleOutY: clearHandles ? null : (handleOutY ?? this.handleOutY),
      isSmooth: isSmooth ?? this.isSmooth,
    );
  }
}

/// A discrete sub-path/layer element within a multi-element vector graphic.
class VectorPathElement {
  final String id;
  final String name;
  final List<VectorPoint> points;
  final Color? fill;
  final Color? strokeColor;
  final double strokeWidth;
  final StrokeCap strokeCap;
  final StrokeJoin strokeJoin;
  final double opacity;
  final bool isClosed;
  final bool visible;

  const VectorPathElement({
    required this.id,
    required this.name,
    required this.points,
    this.fill = const Color(0xFF6C5CE7),
    this.strokeColor,
    this.strokeWidth = 0.0,
    this.strokeCap = StrokeCap.round,
    this.strokeJoin = StrokeJoin.round,
    this.opacity = 1.0,
    this.isClosed = true,
    this.visible = true,
  });

  VectorPathElement copyWith({
    String? id,
    String? name,
    List<VectorPoint>? points,
    Color? fill,
    bool clearFill = false,
    Color? strokeColor,
    bool clearStroke = false,
    double? strokeWidth,
    StrokeCap? strokeCap,
    StrokeJoin? strokeJoin,
    double? opacity,
    bool? isClosed,
    bool? visible,
  }) {
    return VectorPathElement(
      id: id ?? this.id,
      name: name ?? this.name,
      points: points ?? this.points,
      fill: clearFill ? null : (fill ?? this.fill),
      strokeColor: clearStroke ? null : (strokeColor ?? this.strokeColor),
      strokeWidth: strokeWidth ?? this.strokeWidth,
      strokeCap: strokeCap ?? this.strokeCap,
      strokeJoin: strokeJoin ?? this.strokeJoin,
      opacity: opacity ?? this.opacity,
      isClosed: isClosed ?? this.isClosed,
      visible: visible ?? this.visible,
    );
  }
}

/// A native vector layer containing multi-element vector sub-layers, anchor points, fills, and strokes.
class VectorLayer extends Layer {
  final List<VectorPathElement> elements;
  final List<BoxShadow>? shadows;

  VectorLayer({
    required super.id,
    required super.name,
    required super.x,
    required super.y,
    required super.width,
    required super.height,
    super.rotation = 0.0,
    super.opacity = 1.0,
    super.zIndex = 0,
    super.visible = true,
    super.locked = false,
    super.scale = 1.0,
    super.horizontalSizing = AutoLayoutSizingMode.fixed,
    super.verticalSizing = AutoLayoutSizingMode.fixed,
    List<VectorPathElement>? elements,
    // Backwards compatibility constructors
    List<VectorPoint>? points,
    bool isClosed = true,
    Color fill = const Color(0xFF6C5CE7),
    Color? strokeColor,
    double strokeWidth = 0.0,
    StrokeCap strokeCap = StrokeCap.round,
    StrokeJoin strokeJoin = StrokeJoin.round,
    this.shadows,
  })  : elements = elements ??
            [
              VectorPathElement(
                id: 'elem-0',
                name: 'Primary Path',
                points: points ?? const [],
                fill: fill,
                strokeColor: strokeColor,
                strokeWidth: strokeWidth,
                strokeCap: strokeCap,
                strokeJoin: strokeJoin,
                isClosed: isClosed,
              )
            ],
        super(type: LayerType.vector);

  /// Backwards-compatibility getters targeting the primary element
  List<VectorPoint> get points => elements.isNotEmpty ? elements.first.points : const [];
  bool get isClosed => elements.isNotEmpty ? elements.first.isClosed : true;
  Color get fill => elements.isNotEmpty ? (elements.first.fill ?? const Color(0xFF6C5CE7)) : const Color(0xFF6C5CE7);
  Color? get strokeColor => elements.isNotEmpty ? elements.first.strokeColor : null;
  double get strokeWidth => elements.isNotEmpty ? elements.first.strokeWidth : 0.0;
  StrokeCap get strokeCap => elements.isNotEmpty ? elements.first.strokeCap : StrokeCap.round;
  StrokeJoin get strokeJoin => elements.isNotEmpty ? elements.first.strokeJoin : StrokeJoin.round;

  @override
  VectorLayer copyWithTransform({
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    double? opacity,
    int? zIndex,
    bool? visible,
    bool? locked,
    String? name,
    double? scale,
  }) {
    return copyWith(
      x: x,
      y: y,
      width: width,
      height: height,
      rotation: rotation,
      opacity: opacity,
      zIndex: zIndex,
      visible: visible,
      locked: locked,
      name: name,
      scale: scale,
    );
  }

  @override
  VectorLayer copyWithSizing({
    AutoLayoutSizingMode? horizontalSizing,
    AutoLayoutSizingMode? verticalSizing,
  }) {
    return copyWith(
      horizontalSizing: horizontalSizing,
      verticalSizing: verticalSizing,
    );
  }

  VectorLayer copyWith({
    String? id,
    String? name,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    double? opacity,
    int? zIndex,
    bool? visible,
    bool? locked,
    double? scale,
    AutoLayoutSizingMode? horizontalSizing,
    AutoLayoutSizingMode? verticalSizing,
    List<VectorPathElement>? elements,
    // Backwards compatibility params
    List<VectorPoint>? points,
    bool? isClosed,
    Color? fill,
    Color? strokeColor,
    bool clearStroke = false,
    double? strokeWidth,
    StrokeCap? strokeCap,
    StrokeJoin? strokeJoin,
    List<BoxShadow>? shadows,
  }) {
    List<VectorPathElement> updatedElements;
    if (elements != null) {
      updatedElements = elements;
    } else if (points != null || fill != null || strokeColor != null || strokeWidth != null || isClosed != null) {
      // Modify first element for backwards compatibility
      final first = this.elements.isNotEmpty
          ? this.elements.first
          : const VectorPathElement(id: 'elem-0', name: 'Primary Path', points: []);
      final updatedFirst = first.copyWith(
        points: points,
        fill: fill,
        strokeColor: strokeColor,
        clearStroke: clearStroke,
        strokeWidth: strokeWidth,
        strokeCap: strokeCap,
        strokeJoin: strokeJoin,
        isClosed: isClosed,
      );
      updatedElements = [
        updatedFirst,
        if (this.elements.length > 1) ...this.elements.sublist(1),
      ];
    } else {
      updatedElements = this.elements;
    }

    return VectorLayer(
      id: id ?? this.id,
      name: name ?? this.name,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      opacity: opacity ?? this.opacity,
      zIndex: zIndex ?? this.zIndex,
      visible: visible ?? this.visible,
      locked: locked ?? this.locked,
      scale: scale ?? this.scale,
      horizontalSizing: horizontalSizing ?? this.horizontalSizing,
      verticalSizing: verticalSizing ?? this.verticalSizing,
      elements: updatedElements,
      shadows: shadows ?? this.shadows,
    );
  }

  @override
  List<Object?> get props => [
        ...super.props,
        elements,
        shadows,
      ];
}
