import 'package:flutter/material.dart';
import 'layer.dart';
import 'layer_enums.dart';

class ImageLayer extends Layer {
  final String? imagePath; // Local path or asset path
  final String? assetPath;
  final BoxFit fit;
  final double borderRadius;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? shadows;

  const ImageLayer({
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
    this.imagePath,
    this.assetPath,
    this.fit = BoxFit.cover,
    this.borderRadius = 12.0,
    this.borderColor,
    this.borderWidth = 0.0,
    this.shadows,
  }) : super(type: LayerType.image);

  @override
  ImageLayer copyWithTransform({
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
    );
  }

  ImageLayer copyWith({
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
    String? imagePath,
    String? assetPath,
    BoxFit? fit,
    double? borderRadius,
    Color? borderColor,
    double? borderWidth,
    List<BoxShadow>? shadows,
  }) {
    return ImageLayer(
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
      imagePath: imagePath ?? this.imagePath,
      assetPath: assetPath ?? this.assetPath,
      fit: fit ?? this.fit,
      borderRadius: borderRadius ?? this.borderRadius,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      shadows: shadows ?? this.shadows,
    );
  }

  @override
  List<Object?> get props => [
        ...super.props,
        imagePath,
        assetPath,
        fit,
        borderRadius,
        borderColor,
        borderWidth,
        shadows,
      ];
}
