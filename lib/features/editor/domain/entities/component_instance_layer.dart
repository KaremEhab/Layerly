import 'layer.dart';
import 'layer_enums.dart';

class ComponentInstanceLayer extends Layer {
  final String componentDefinitionId;
  final Map<String, dynamic> variableOverrides;

  const ComponentInstanceLayer({
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
    required this.componentDefinitionId,
    this.variableOverrides = const {},
  }) : super(type: LayerType.componentInstance);

  @override
  ComponentInstanceLayer copyWithTransform({
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
  ComponentInstanceLayer copyWithSizing({
    AutoLayoutSizingMode? horizontalSizing,
    AutoLayoutSizingMode? verticalSizing,
  }) {
    return copyWith(
      horizontalSizing: horizontalSizing,
      verticalSizing: verticalSizing,
    );
  }

  ComponentInstanceLayer copyWith({
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
    String? componentDefinitionId,
    Map<String, dynamic>? variableOverrides,
  }) {
    return ComponentInstanceLayer(
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
      componentDefinitionId:
          componentDefinitionId ?? this.componentDefinitionId,
      variableOverrides: variableOverrides ?? this.variableOverrides,
    );
  }

  @override
  List<Object?> get props => [
        ...super.props,
        componentDefinitionId,
        variableOverrides,
      ];
}
