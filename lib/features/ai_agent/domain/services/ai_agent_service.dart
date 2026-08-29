import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:layerly/core/utils/uuid_generator.dart';
import 'package:layerly/features/editor/data/project_storage_service.dart';
import 'package:layerly/features/editor/domain/entities/canvas_page.dart';
import 'package:layerly/features/editor/domain/entities/canvas_project.dart';
import '../../data/gemini_ai_client.dart';
import '../../data/intelligent_synthesis_engine.dart';
import '../entities/ai_generation_step.dart';
import '../entities/design_recipe.dart';

class AiGenerationResult {
  final CanvasProject project;
  final CanvasPage page;
  final DesignRecipe recipe;
  final bool isGeminiGenerated;
  final String? modelUsed;
  final String? geminiError;

  const AiGenerationResult({
    required this.project,
    required this.page,
    required this.recipe,
    this.isGeminiGenerated = false,
    this.modelUsed,
    this.geminiError,
  });
}

class AiAgentService {
  static final AiAgentService instance = AiAgentService._internal();
  AiAgentService._internal();

  static const String _geminiApiKeyPref = 'layerly_gemini_api_key';

  Future<String?> getStoredApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_geminiApiKeyPref);
  }

  Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geminiApiKeyPref, apiKey.trim());
  }

  Future<void> removeApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_geminiApiKeyPref);
  }

  /// Single, unified design generation pipeline:
  /// Dispatches progress updates via [onProgress], calls Gemini exactly ONCE (avoiding rate-limit bursts),
  /// falls back gracefully if Gemini fails while recording the exact diagnostic error, and constructs the canvas project.
  Future<AiGenerationResult> generateDesign({
    required String prompt,
    String? explicitApiKey,
    bool forceOffline = false,
    double horizontalPadding = 20.0,
    double verticalPadding = 20.0,
    void Function(AiGenerationStep)? onProgress,
  }) async {
    onProgress?.call(const AiGenerationStep(
      type: AiStepType.analyzingPrompt,
      message: 'Analyzing prompt and extracting design requirements...',
      progress: 0.15,
    ));

    await Future.delayed(const Duration(milliseconds: 250));

    final apiKey = explicitApiKey ?? await getStoredApiKey();
    DesignRecipe? recipe;
    bool isGeminiGenerated = false;
    String? modelUsed;
    String? geminiError;

    if (!forceOffline && apiKey != null && apiKey.trim().isNotEmpty) {
      onProgress?.call(const AiGenerationStep(
        type: AiStepType.synthesizingRecipe,
        message: 'Calling Google Gemini to synthesize custom design...',
        progress: 0.35,
      ));

      try {
        final client = GeminiAiClient(apiKey: apiKey.trim());
        recipe = await client.generateRecipeFromPrompt(prompt);
        isGeminiGenerated = true;
        modelUsed = client.lastUsedModel ?? 'Gemini AI';
        debugPrint('[AiAgentService] Gemini successfully composed recipe with model $modelUsed');
      } catch (e, st) {
        debugPrint('[AiAgentService] Gemini call failed: $e\n$st');
        geminiError = e.toString().replaceAll('Exception: ', '');
        onProgress?.call(AiGenerationStep(
          type: AiStepType.synthesizingRecipe,
          message: 'Gemini unavailable (${geminiError.length > 35 ? "${geminiError.substring(0, 32)}..." : geminiError}). Switching to Synthesis Engine...',
          progress: 0.45,
        ));
        await Future.delayed(const Duration(milliseconds: 400));
        recipe = IntelligentSynthesisEngine.parsePromptToRecipe(prompt);
      }
    } else {
      onProgress?.call(const AiGenerationStep(
        type: AiStepType.synthesizingRecipe,
        message: 'Synthesizing layout recipe via intelligent engine...',
        progress: 0.40,
      ));
      await Future.delayed(const Duration(milliseconds: 250));
      recipe = IntelligentSynthesisEngine.parsePromptToRecipe(prompt);
    }

    final domainLabel = recipe.domain.name.toUpperCase();
    onProgress?.call(AiGenerationStep(
      type: AiStepType.buildingLayoutHierarchy,
      message: 'Composing $domainLabel AutoLayout cards, hierarchy & typography scales...',
      progress: 0.70,
    ));
    await Future.delayed(const Duration(milliseconds: 250));

    onProgress?.call(const AiGenerationStep(
      type: AiStepType.renderingElements,
      message: 'Rendering vector ambient lighting and thematic icons...',
      progress: 0.90,
    ));
    await Future.delayed(const Duration(milliseconds: 200));

    final page = IntelligentSynthesisEngine.synthesizeCanvasPage(
      recipe,
      horizontalPadding: horizontalPadding,
      verticalPadding: verticalPadding,
    );

    final project = CanvasProject(
      id: UuidGenerator.generate(),
      name: recipe.title.length > 30 ? '${recipe.title.substring(0, 30)}...' : recipe.title,
      description: isGeminiGenerated
          ? 'Generated by $modelUsed: ${recipe.subtitle}'
          : 'AI Generated: ${recipe.subtitle}',
      pages: [page],
      activePageIndex: 0,
      coverPageIndex: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save project into local storage so it immediately persists
    await ProjectStorageService.instance.saveProject(project);

    onProgress?.call(const AiGenerationStep(
      type: AiStepType.finalizing,
      message: 'Finalizing pixel-perfect design on canvas...',
      progress: 1.0,
    ));

    return AiGenerationResult(
      project: project,
      page: page,
      recipe: recipe,
      isGeminiGenerated: isGeminiGenerated,
      modelUsed: modelUsed,
      geminiError: geminiError,
    );
  }

  /// Backward-compatible stream generator
  Stream<AiGenerationStep> generateDesignStream({
    required String prompt,
    String? explicitApiKey,
    bool forceOffline = false,
  }) async* {
    yield const AiGenerationStep(
      type: AiStepType.analyzingPrompt,
      message: 'Analyzing prompt and extracting design requirements...',
      progress: 0.15,
    );
  }

  /// Backward-compatible build result
  Future<AiGenerationResult> buildDesignResult({
    required String prompt,
    String? explicitApiKey,
    bool forceOffline = false,
  }) async {
    return generateDesign(
      prompt: prompt,
      explicitApiKey: explicitApiKey,
      forceOffline: forceOffline,
    );
  }
}
