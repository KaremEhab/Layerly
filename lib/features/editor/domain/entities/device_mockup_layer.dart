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
    this.device = MockupDevice.iphone,
    this.screenImagePath,
    this.frameColor = const Color(0xFF1E2028),
    this.screenBackgroundColor = const Color(0xFFF6F7FB),
    this.cornerRadius = 38.0,
    this.showShadow = true,
    this.showHeader = true,
    this.title,
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
      ];
}
