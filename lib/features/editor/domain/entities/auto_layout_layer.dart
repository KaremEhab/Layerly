import 'package:flutter/material.dart';
import 'layer.dart';
import 'layer_enums.dart';

class AutoLayoutLayer extends Layer {
  final AutoLayoutDirection direction;
  final double gap;
  final double paddingHorizontal;
  final double paddingVertical;
  final AutoLayoutAlignment alignment;
  final AutoLayoutDistribution distribution;
  final List<Layer> children;
  final Color? backgroundColor;
  final double cornerRadius;
  final Color? strokeColor;
  final double strokeWidth;
  final StrokePosition strokePosition;
  final bool clipContent;

  const AutoLayoutLayer({
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
    super.horizontalSizing = AutoLayoutSizingMode.hug,
    super.verticalSizing = AutoLayoutSizingMode.hug,
    this.direction = AutoLayoutDirection.horizontal,
    this.gap = 12.0,
    this.paddingHorizontal = 16.0,
    this.paddingVertical = 16.0,
    this.alignment = AutoLayoutAlignment.center,
    this.distribution = AutoLayoutDistribution.start,
    this.children = const [],
    this.backgroundColor,
    this.cornerRadius = 12.0,
    this.strokeColor,
    this.strokeWidth = 0.0,
    this.strokePosition = StrokePosition.inside,
    this.clipContent = false,
  }) : super(type: LayerType.autoLayout);

  @override
  AutoLayoutLayer copyWithTransform({
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
    return AutoLayoutLayer(
      id: id,
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
      direction: direction,
      gap: gap,
      paddingHorizontal: paddingHorizontal,
      paddingVertical: paddingVertical,
      alignment: alignment,
      distribution: distribution,
      horizontalSizing: horizontalSizing,
      verticalSizing: verticalSizing,
      children: children,
      backgroundColor: backgroundColor,
      cornerRadius: cornerRadius,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
      strokePosition: strokePosition,
      clipContent: clipContent,
    );
  }

  @override
  AutoLayoutLayer copyWithSizing({
    AutoLayoutSizingMode? horizontalSizing,
    AutoLayoutSizingMode? verticalSizing,
  }) {
    return copyWith(
      horizontalSizing: horizontalSizing,
      verticalSizing: verticalSizing,
    );
  }

  AutoLayoutLayer copyWith({
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
    AutoLayoutDirection? direction,
    double? gap,
    double? paddingHorizontal,
    double? paddingVertical,
    AutoLayoutAlignment? alignment,
    AutoLayoutDistribution? distribution,
    AutoLayoutSizingMode? horizontalSizing,
    AutoLayoutSizingMode? verticalSizing,
    List<Layer>? children,
    Color? backgroundColor,
    bool clearBackgroundColor = false,
    double? cornerRadius,
    Color? strokeColor,
    bool clearStrokeColor = false,
    double? strokeWidth,
    StrokePosition? strokePosition,
    bool? clipContent,
  }) {
    return AutoLayoutLayer(
      id: id,
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
      direction: direction ?? this.direction,
      gap: gap ?? this.gap,
      paddingHorizontal: paddingHorizontal ?? this.paddingHorizontal,
      paddingVertical: paddingVertical ?? this.paddingVertical,
      alignment: alignment ?? this.alignment,
      distribution: distribution ?? this.distribution,
      horizontalSizing: horizontalSizing ?? this.horizontalSizing,
      verticalSizing: verticalSizing ?? this.verticalSizing,
      children: children ?? this.children,
      backgroundColor: clearBackgroundColor ? null : (backgroundColor ?? this.backgroundColor),
      cornerRadius: cornerRadius ?? this.cornerRadius,
      strokeColor: clearStrokeColor ? null : (strokeColor ?? this.strokeColor),
      strokeWidth: strokeWidth ?? this.strokeWidth,
      strokePosition: strokePosition ?? this.strokePosition,
      clipContent: clipContent ?? this.clipContent,
    );
  }

  /// Automatically calculates child positions within this container
  List<Layer> get positionedChildren {
    if (children.isEmpty) return [];
    if (direction == AutoLayoutDirection.none) return children;

    final result = <Layer>[];
    double currentOffset = direction == AutoLayoutDirection.horizontal
        ? paddingHorizontal
        : paddingVertical;

    for (int i = 0; i < children.length; i++) {
      final child = children[i];
      double childX;
      double childY;

      if (direction == AutoLayoutDirection.horizontal) {
        childX = currentOffset;
        switch (alignment) {
          case AutoLayoutAlignment.start:
            childY = paddingVertical;
            break;
          case AutoLayoutAlignment.end:
            childY = height - paddingVertical - child.height;
            break;
          case AutoLayoutAlignment.center:
          case AutoLayoutAlignment.stretch:
            childY = (height - child.height) / 2;
            break;
        }
        currentOffset += child.width + gap;
      } else {
        childY = currentOffset;
        switch (alignment) {
          case AutoLayoutAlignment.start:
            childX = paddingHorizontal;
            break;
          case AutoLayoutAlignment.end:
            childX = width - paddingHorizontal - child.width;
            break;
          case AutoLayoutAlignment.center:
          case AutoLayoutAlignment.stretch:
            childX = (width - child.width) / 2;
            break;
        }
        currentOffset += child.height + gap;
      }

      result.add(child.copyWithTransform(x: childX, y: childY));
    }

    return result;
  }

  @override
  List<Object?> get props => [
        ...super.props,
        direction,
        gap,
        paddingHorizontal,
        paddingVertical,
        alignment,
        distribution,
        horizontalSizing,
        verticalSizing,
        children,
        backgroundColor,
        cornerRadius,
        strokeColor,
        strokeWidth,
        strokePosition,
        clipContent,
      ];
}
