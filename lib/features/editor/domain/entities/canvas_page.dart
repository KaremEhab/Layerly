import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'layer.dart';
import 'layer_enums.dart';

class CanvasPage extends Equatable {
  final String id;
  final String name;
  final double width;
  final double height;
  final BackgroundType backgroundType;
  final Color backgroundColor;
  final Gradient? backgroundGradient;
  final String? backgroundImagePath;
  final List<Layer> layers;
  final bool showGrid;
  final bool showGuides;
  final bool showSafeArea;

  const CanvasPage({
    required this.id,
    required this.name,
    this.width = 1080.0,
    this.height = 1080.0,
    this.backgroundType = BackgroundType.gradient,
    this.backgroundColor = const Color(0xFF090A0D),
    this.backgroundGradient = const RadialGradient(
      center: Alignment(0.4, -0.6),
      radius: 1.2,
      colors: [
        Color(0xFF2C194D),
        Color(0xFF13141B),
        Color(0xFF090A0D),
      ],
      stops: [0.0, 0.5, 1.0],
    ),
    this.backgroundImagePath,
    this.layers = const [],
    this.showGrid = false,
    this.showGuides = true,
    this.showSafeArea = false,
  });

  CanvasPage copyWith({
    String? id,
    String? name,
    double? width,
    double? height,
    BackgroundType? backgroundType,
    Color? backgroundColor,
    Gradient? backgroundGradient,
    String? backgroundImagePath,
    List<Layer>? layers,
    bool? showGrid,
    bool? showGuides,
    bool? showSafeArea,
  }) {
    return CanvasPage(
      id: id ?? this.id,
      name: name ?? this.name,
      width: width ?? this.width,
      height: height ?? this.height,
      backgroundType: backgroundType ?? this.backgroundType,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      backgroundImagePath: backgroundImagePath ?? this.backgroundImagePath,
      layers: layers ?? this.layers,
      showGrid: showGrid ?? this.showGrid,
      showGuides: showGuides ?? this.showGuides,
      showSafeArea: showSafeArea ?? this.showSafeArea,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        width,
        height,
        backgroundType,
        backgroundColor,
        backgroundGradient,
        backgroundImagePath,
        layers,
        showGrid,
        showGuides,
        showSafeArea,
      ];
}
