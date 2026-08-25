import 'package:flutter/material.dart';
import 'layer.dart';
import 'layer_enums.dart';

class ShapeLayer extends Layer {
  final ShapeType shapeType;
  final Color fill;
  final Gradient? gradient;
  final Color? strokeColor;
  final double strokeWidth;
  final double cornerRadius;
  final List<BoxShadow>? shadows;
  final StrokePosition strokePosition;
  final ArrowHeadStyle startHead;
  final ArrowHeadStyle endHead;

  const ShapeLayer({
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
    this.shapeType = ShapeType.roundedRectangle,
    this.fill = const Color(0xFF1D1E24),
    this.gradient,
    this.strokeColor,
    this.strokeWidth = 0.0,
    this.cornerRadius = 12.0,
    this.shadows,
    this.strokePosition = StrokePosition.center,
    this.startHead = ArrowHeadStyle.none,
    this.endHead = ArrowHeadStyle.lineArrow,
  }) : super(type: LayerType.shape);

  @override
  ShapeLayer copyWithTransform({
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

  ShapeLayer copyWith({
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
    ShapeType? shapeType,
    Color? fill,
    Gradient? gradient,
    Color? strokeColor,
    double? strokeWidth,
    double? cornerRadius,
    List<BoxShadow>? shadows,
    StrokePosition? strokePosition,
    ArrowHeadStyle? startHead,
    ArrowHeadStyle? endHead,
  }) {
    return ShapeLayer(
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
      shapeType: shapeType ?? this.shapeType,
      fill: fill ?? this.fill,
      gradient: gradient ?? this.gradient,
      strokeColor: strokeColor ?? this.strokeColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      shadows: shadows ?? this.shadows,
      strokePosition: strokePosition ?? this.strokePosition,
      startHead: startHead ?? this.startHead,
      endHead: endHead ?? this.endHead,
    );
  }

  @override
  List<Object?> get props => [
        ...super.props,
        shapeType,
        fill,
        gradient,
        strokeColor,
        strokeWidth,
        cornerRadius,
        shadows,
        strokePosition,
        startHead,
        endHead,
      ];
}
