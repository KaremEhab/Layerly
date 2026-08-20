import 'package:flutter/material.dart';
import 'layer.dart';
import 'layer_enums.dart';

class TextLayer extends Layer {
  final String content;
  final String fontFamily;
  final double fontSize;
  final FontWeight fontWeight;
  final FontStyle fontStyle;
  final Color color;
  final double letterSpacing;
  final double lineHeight;
  final TextAlign textAlign;
  final TextDecoration? decoration;
  final List<Shadow>? shadows;
  final Color? backgroundColor;
  final double backgroundRadius;
  final EdgeInsets padding;
  final Gradient? textGradient;

  const TextLayer({
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
    required this.content,
    this.fontFamily = 'Inter',
    this.fontSize = 28.0,
    this.fontWeight = FontWeight.w600,
    this.fontStyle = FontStyle.normal,
    this.color = Colors.white,
    this.letterSpacing = -0.2,
    this.lineHeight = 1.2,
    this.textAlign = TextAlign.left,
    this.decoration,
    this.shadows,
    this.backgroundColor,
    this.backgroundRadius = 6.0,
    this.padding = EdgeInsets.zero,
    this.textGradient,
  }) : super(type: LayerType.text);

  @override
  TextLayer copyWithTransform({
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

  TextLayer copyWith({
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
    String? content,
    String? fontFamily,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    Color? color,
    double? letterSpacing,
    double? lineHeight,
    TextAlign? textAlign,
    TextDecoration? decoration,
    List<Shadow>? shadows,
    Color? backgroundColor,
    double? backgroundRadius,
    EdgeInsets? padding,
    Gradient? textGradient,
  }) {
    return TextLayer(
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
      content: content ?? this.content,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      fontStyle: fontStyle ?? this.fontStyle,
      color: color ?? this.color,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      lineHeight: lineHeight ?? this.lineHeight,
      textAlign: textAlign ?? this.textAlign,
      decoration: decoration ?? this.decoration,
      shadows: shadows ?? this.shadows,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundRadius: backgroundRadius ?? this.backgroundRadius,
      padding: padding ?? this.padding,
      textGradient: textGradient ?? this.textGradient,
    );
  }

  @override
  List<Object?> get props => [
        ...super.props,
        content,
        fontFamily,
        fontSize,
        fontWeight,
        fontStyle,
        color,
        letterSpacing,
        lineHeight,
        textAlign,
        decoration,
        shadows,
        backgroundColor,
        backgroundRadius,
        padding,
        textGradient,
      ];
}
