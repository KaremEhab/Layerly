import 'package:equatable/equatable.dart';
import 'layer.dart';

class ComponentDefinition extends Equatable {
  final String id;
  final String name;
  final String description;
  final double width;
  final double height;
  final List<Layer> layers;
  final Map<String, dynamic> defaultVariables;

  const ComponentDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.width,
    required this.height,
    required this.layers,
    this.defaultVariables = const {},
  });

  ComponentDefinition copyWith({
    String? id,
    String? name,
    String? description,
    double? width,
    double? height,
    List<Layer>? layers,
    Map<String, dynamic>? defaultVariables,
  }) {
    return ComponentDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      width: width ?? this.width,
      height: height ?? this.height,
      layers: layers ?? this.layers,
      defaultVariables: defaultVariables ?? this.defaultVariables,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        width,
        height,
        layers,
        defaultVariables,
      ];
}
