import 'package:flutter/material.dart';
import 'layer.dart';
import 'layer_enums.dart';

class IconLayer extends Layer {
  final IconData icon;
  final Color color;
  final Color? backgroundColor;
  final double cornerRadius;
  final List<BoxShadow>? shadows;

  const IconLayer({
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
    this.icon = Icons.check_circle_rounded,
    this.color = const Color(0xFFA970FF),
    this.backgroundColor,
    this.cornerRadius = 0.0,
    this.shadows,
  }) : super(type: LayerType.icon);

  @override
  IconLayer copyWithTransform({
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

  IconLayer copyWith({
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
    IconData? icon,
    Color? color,
    Color? backgroundColor,
    double? cornerRadius,
    List<BoxShadow>? shadows,
  }) {
    return IconLayer(
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
      icon: icon ?? this.icon,
      color: color ?? this.color,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      shadows: shadows ?? this.shadows,
    );
  }

  @override
  List<Object?> get props => [
        ...super.props,
        icon,
        color,
        backgroundColor,
        cornerRadius,
        shadows,
      ];
}
