import 'package:flutter/material.dart';
import 'layer.dart';
import 'layer_enums.dart';

class DeviceMockupLayer extends Layer {
  final MockupDevice device;
  final String? screenImagePath;
  final Color frameColor;
  final Color screenBackgroundColor;
  final double cornerRadius;
  final bool showShadow;
  final bool showHeader;
  final String? title;
  final BoxFit imageFit;
  final double imageOffsetX;
  final double imageOffsetY;
  final double imageScale;
  final bool showGlare;
  final bool showDynamicIsland;

  const DeviceMockupLayer({
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
    this.device = MockupDevice.iphone17ProMax,
    this.screenImagePath,
    this.frameColor = const Color(0xFF050507),
    this.screenBackgroundColor = const Color(0xFFF5F5F7),
    this.cornerRadius = 52.0,
    this.showShadow = true,
    this.showHeader = true,
    this.title,
    this.imageFit = BoxFit.cover,
    this.imageOffsetX = 0.0,
    this.imageOffsetY = 0.0,
    this.imageScale = 1.0,
    this.showGlare = true,
    this.showDynamicIsland = true,
  }) : super(type: LayerType.deviceMockup);

  @override
  DeviceMockupLayer copyWithTransform({
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

  DeviceMockupLayer copyWith({
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
    MockupDevice? device,
    String? screenImagePath,
    Color? frameColor,
    Color? screenBackgroundColor,
    double? cornerRadius,
    bool? showShadow,
    bool? showHeader,
    String? title,
    BoxFit? imageFit,
    double? imageOffsetX,
    double? imageOffsetY,
    double? imageScale,
    bool? showGlare,
    bool? showDynamicIsland,
  }) {
    return DeviceMockupLayer(
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
      device: device ?? this.device,
      screenImagePath: screenImagePath ?? this.screenImagePath,
      frameColor: frameColor ?? this.frameColor,
      screenBackgroundColor: screenBackgroundColor ?? this.screenBackgroundColor,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      showShadow: showShadow ?? this.showShadow,
      showHeader: showHeader ?? this.showHeader,
      title: title ?? this.title,
      imageFit: imageFit ?? this.imageFit,
      imageOffsetX: imageOffsetX ?? this.imageOffsetX,
      imageOffsetY: imageOffsetY ?? this.imageOffsetY,
      imageScale: imageScale ?? this.imageScale,
      showGlare: showGlare ?? this.showGlare,
      showDynamicIsland: showDynamicIsland ?? this.showDynamicIsland,
    );
  }

  @override
  List<Object?> get props => [
        ...super.props,
        device,
        screenImagePath,
        frameColor,
        screenBackgroundColor,
        cornerRadius,
        showShadow,
        showHeader,
        title,
        imageFit,
        imageOffsetX,
        imageOffsetY,
        imageScale,
        showGlare,
        showDynamicIsland,
      ];
}
