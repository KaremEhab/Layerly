import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'layer_enums.dart';

abstract class Layer extends Equatable {
  final String id;
  final String name;
  final LayerType type;
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation; // in radians
  final double opacity;
  final int zIndex;
  final bool visible;
  final bool locked;

  const Layer({
    required this.id,
    required this.name,
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.rotation = 0.0,
    this.opacity = 1.0,
    this.zIndex = 0,
    this.visible = true,
    this.locked = false,
  });

  Rect get bounds => Rect.fromLTWH(x, y, width, height);

  Offset get center => Offset(x + width / 2, y + height / 2);

  Layer copyWithTransform({
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
  });

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        x,
        y,
        width,
        height,
        rotation,
        opacity,
        zIndex,
        visible,
        locked,
      ];
}
