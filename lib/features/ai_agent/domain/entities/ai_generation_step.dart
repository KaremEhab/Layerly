import 'package:equatable/equatable.dart';

enum AiStepType {
  analyzingPrompt,
  synthesizingRecipe,
  buildingLayoutHierarchy,
  renderingElements,
  finalizing,
  error,
}

class AiGenerationStep extends Equatable {
  final AiStepType type;
  final String message;
  final double progress; // 0.0 to 1.0

  const AiGenerationStep({
    required this.type,
    required this.message,
    required this.progress,
  });

  @override
  List<Object?> get props => [type, message, progress];
}
