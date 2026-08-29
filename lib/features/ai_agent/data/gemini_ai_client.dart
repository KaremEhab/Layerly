import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../domain/entities/design_recipe.dart';

class GeminiAiClient {
  final String apiKey;
  String? lastUsedModel;
  static String? _cachedBestModel;
  static String? _cachedApiKey;

  GeminiAiClient({required this.apiKey});

  /// Dynamically queries Google's ModelService to fetch all models that support 'generateContent' for this key.
  static Future<List<String>> fetchAvailableModels(String key) async {
    final cleanKey = key.trim();
    if (cleanKey.isEmpty) {
      throw Exception('API key cannot be empty.');
    }

    final client = HttpClient();
    try {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models?key=$cleanKey',
      );
      final request = await client.getUrl(uri);
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        try {
          final errorJson = jsonDecode(responseBody) as Map<String, dynamic>;
          final msg = errorJson['error']?['message']?.toString();
          if (msg != null && msg.isNotEmpty) {
            throw Exception(_formatGeminiError(msg));
          }
        } catch (e) {
          if (e is Exception) rethrow;
        }
        throw Exception('HTTP ${response.statusCode}: ${_formatGeminiError(responseBody)}');
      }

      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      final modelsList = decoded['models'] as List<dynamic>? ?? [];

      final available = <String>[];
      for (final item in modelsList) {
        if (item is Map<String, dynamic>) {
          final methods = (item['supportedGenerationMethods'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];
          if (methods.contains('generateContent')) {
            final name = item['name']?.toString() ?? '';
            final cleanName = name.replaceFirst('models/', '');
            if (cleanName.isNotEmpty) {
              available.add(cleanName);
            }
          }
        }
      }

      if (available.isEmpty) {
        throw Exception(
          'No models supporting content generation were found for this API key. '
          'Please ensure the Gemini API is enabled in your Google Cloud / AI Studio project.',
        );
      }

      return available;
    } finally {
      client.close();
    }
  }

  /// Sort models prioritizing the latest stable Flash models (e.g. gemini-3.6-flash).
  static List<String> sortModelsByPriority(List<String> available) {
    final priorities = [
      'gemini-3.6-flash',
      'gemini-3.6-pro',
      'gemini-3.5-flash',
      'gemini-3.5-pro',
      'gemini-3.0-flash',
      'gemini-2.5-flash',
      'gemini-2.0-flash',
      'gemini-2.0-flash-exp',
      'gemini-1.5-flash',
      'gemini-1.5-flash-latest',
      'gemini-1.5-flash-8b',
      'gemini-1.5-pro',
      'gemini-1.5-pro-latest',
      'gemini-pro',
    ];

    final sorted = <String>[];
    for (final pref in priorities) {
      if (available.contains(pref) && !sorted.contains(pref)) {
        sorted.add(pref);
      }
    }

    // Add any remaining flash/pro models
    for (final m in available) {
      if (!sorted.contains(m) && (m.contains('flash') || m.contains('pro'))) {
        sorted.add(m);
      }
    }

    // Add anything else
    for (final m in available) {
      if (!sorted.contains(m)) {
        sorted.add(m);
      }
    }

    return sorted.isEmpty ? ['gemini-3.6-flash', 'gemini-2.0-flash', 'gemini-1.5-flash'] : sorted;
  }

  /// Test connectivity and validity of an API key by cascading through candidate models.
  static Future<String> testApiKey(String key) async {
    final cleanKey = key.trim();
    if (cleanKey.isEmpty) {
      throw Exception('API key cannot be empty.');
    }

    debugPrint('[GeminiAiClient.testApiKey] Fetching available models for key...');
    final availableModels = await fetchAvailableModels(cleanKey);
    debugPrint('[GeminiAiClient.testApiKey] Discovered ${availableModels.length} models: $availableModels');

    final candidateModels = sortModelsByPriority(availableModels);
    Object? lastError;

    for (final modelName in candidateModels) {
      try {
        debugPrint('[GeminiAiClient.testApiKey] Testing candidate model: $modelName...');
        final model = GenerativeModel(
          model: modelName,
          apiKey: cleanKey,
        );

        final response = await model.generateContent([
          Content.text('Respond with one word: OK'),
        ]);

        final text = response.text?.trim();
        if (text != null && text.isNotEmpty) {
          _cachedBestModel = modelName;
          _cachedApiKey = cleanKey;
          debugPrint('[GeminiAiClient.testApiKey] Verified working model: $modelName');
          return 'Connected! Key verified with $modelName (${availableModels.length} models available)';
        }
      } catch (e) {
        debugPrint('[GeminiAiClient.testApiKey] Model $modelName failed: $e');
        lastError = e;
      }
    }

    throw Exception(_formatGeminiError(lastError));
  }

  Future<DesignRecipe> generateRecipeFromPrompt(String prompt) async {
    final cleanKey = apiKey.trim();
    if (cleanKey.isEmpty) {
      throw Exception('Gemini API key is empty.');
    }

    List<String> modelsToTry = [];
    if (_cachedApiKey == cleanKey && _cachedBestModel != null) {
      modelsToTry.add(_cachedBestModel!);
    }

    try {
      final available = await fetchAvailableModels(cleanKey);
      final sorted = sortModelsByPriority(available);
      for (final m in sorted) {
        if (!modelsToTry.contains(m)) {
          modelsToTry.add(m);
        }
      }
    } catch (e) {
      debugPrint('[GeminiAiClient] Could not fetch models dynamically: $e');
      if (modelsToTry.isEmpty) {
        modelsToTry = ['gemini-3.6-flash', 'gemini-2.0-flash', 'gemini-1.5-flash'];
      }
    }

    Object? lastError;
    for (final modelName in modelsToTry) {
      // 1. Try with structured responseSchema
      try {
        debugPrint('[GeminiAiClient] Attempting generation with $modelName (with responseSchema)...');
        final recipe = await _generateWithModel(modelName, prompt, withSchema: true);
        lastUsedModel = modelName;
        _cachedBestModel = modelName;
        _cachedApiKey = cleanKey;
        debugPrint('[GeminiAiClient] Successfully generated recipe with $modelName');
        return recipe;
      } catch (e) {
        debugPrint('[GeminiAiClient] $modelName with schema failed: $e. Retrying without schema...');
        lastError = e;

        // 2. Retry without responseSchema in case strict schema is rejected
        try {
          final recipe = await _generateWithModel(modelName, prompt, withSchema: false);
          lastUsedModel = modelName;
          _cachedBestModel = modelName;
          _cachedApiKey = cleanKey;
          debugPrint('[GeminiAiClient] Successfully generated recipe with $modelName (pure JSON prompt)');
          return recipe;
        } catch (e2) {
          debugPrint('[GeminiAiClient] $modelName without schema also failed: $e2');
          lastError = e2;
        }
      }
    }

    throw Exception(_formatGeminiError(lastError));
  }

  Future<DesignRecipe> _generateWithModel(
    String modelName,
    String prompt, {
    required bool withSchema,
  }) async {
    final model = GenerativeModel(
      model: modelName,
      apiKey: apiKey.trim(),
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: withSchema ? _buildSchema() : null,
      ),
      systemInstruction: Content.system(
        'You are an expert graphic design AI agent for Layerly Studio. '
        'Your goal is to parse the user request and generate a rich, professional Design Recipe as a valid JSON object. '
        'Output pure JSON ONLY. Do not wrap in markdown code blocks, do not include ```json fences or commentary. '
        'Tailor color palettes, headlines, metrics, and icons directly to the user domain (e.g. pharmaceutical, medical, biotech, tech, marketing). '
        'Always ensure high visual contrast and premium aesthetic choices.',
      ),
    );

    final promptBuffer = StringBuffer();
    promptBuffer.writeln('Generate a graphic design recipe JSON for the following user request: "$prompt"');
    promptBuffer.writeln();
    promptBuffer.writeln('Output a valid JSON object with the following fields:');
    promptBuffer.writeln('{');
    promptBuffer.writeln('  "title": "Compelling headline for the graphic design",');
    promptBuffer.writeln('  "subtitle": "Detailed supportive subtext explaining the subject",');
    promptBuffer.writeln('  "badgeText": "UPPERCASE CATEGORY BADGE",');
    promptBuffer.writeln('  "badgeIcon": "Icon name e.g. medication, biotech, health_and_safety, bolt, star",');
    promptBuffer.writeln('  "domain": "pharma|healthcare|tech|saas|fitness|marketing|ecommerce|creative",');
    promptBuffer.writeln('  "layoutStyle": "heroCards|splitBento|statisticFocus|centeredMinimal",');
    promptBuffer.writeln('  "aspectRatio": "1:1|4:5|9:16|16:9",');
    promptBuffer.writeln('  "gradientColors": ["#041C24", "#063B48", "#0A1E24"],');
    promptBuffer.writeln('  "primaryColor": "#00D2B4",');
    promptBuffer.writeln('  "accentColor": "#10B981",');
    promptBuffer.writeln('  "features": [');
    promptBuffer.writeln('    {"title": "Metric Title", "subtitle": "Detail", "value": "99.4%", "iconName": "biotech"}');
    promptBuffer.writeln('  ],');
    promptBuffer.writeln('  "footerText": "Attribution or brand name",');
    promptBuffer.writeln('  "ctaText": "Call to action button label"');
    promptBuffer.writeln('}');

    final response = await model.generateContent([
      Content.text(promptBuffer.toString()),
    ]);

    final rawText = response.text;
    if (rawText == null || rawText.trim().isEmpty) {
      throw Exception('Gemini returned an empty response.');
    }

    final cleaned = _cleanJsonString(rawText);
    final dynamic decoded = jsonDecode(cleaned);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Gemini response was not a valid JSON object.');
    }

    return DesignRecipe.fromJson(decoded);
  }

  static Schema _buildSchema() {
    return Schema.object(
      properties: {
        'title': Schema.string(description: 'Compelling headline for the graphic design'),
        'subtitle': Schema.string(description: 'Detailed supportive subtext explaining the subject'),
        'badgeText': Schema.string(description: 'Short uppercase category badge or tag e.g. PHARMACEUTICAL R&D'),
        'badgeIcon': Schema.string(description: 'Icon name e.g. medication, health_and_safety, biotech, bolt, star'),
        'domain': Schema.string(description: 'One of: pharma, healthcare, tech, saas, fitness, marketing, ecommerce, creative'),
        'layoutStyle': Schema.string(description: 'One of: heroCards, splitBento, statisticFocus, centeredMinimal'),
        'aspectRatio': Schema.string(description: 'Aspect ratio: 1:1, 4:5, 9:16, or 16:9'),
        'gradientColors': Schema.array(
          description: '2 to 3 hex colors for rich background gradient',
          items: Schema.string(),
        ),
        'primaryColor': Schema.string(description: 'Hex color for primary highlights/buttons'),
        'accentColor': Schema.string(description: 'Hex color for secondary accents/tags'),
        'features': Schema.array(
          description: '2 to 3 feature or metric cards',
          items: Schema.object(
            properties: {
              'title': Schema.string(description: 'Card title'),
              'subtitle': Schema.string(description: 'Card subtitle or description'),
              'value': Schema.string(description: 'Stat or metric value e.g. 99.4% or Phase III'),
              'iconName': Schema.string(description: 'Icon name e.g. medication, biotech, health_and_safety, shield, bolt'),
            },
            requiredProperties: ['title'],
          ),
        ),
        'footerText': Schema.string(description: 'Footer attribution or branding text'),
        'ctaText': Schema.string(description: 'Call to action text'),
      },
      requiredProperties: ['title', 'subtitle', 'badgeText', 'domain', 'aspectRatio'],
    );
  }

  static String _cleanJsonString(String raw) {
    var text = raw.trim();

    // 1. Strip markdown code fences (```json ... ``` or ``` ... ```)
    if (text.startsWith('```')) {
      final firstNewline = text.indexOf('\n');
      if (firstNewline != -1) {
        text = text.substring(firstNewline + 1);
      }
    }
    if (text.endsWith('```')) {
      text = text.substring(0, text.length - 3);
    }
    text = text.trim();

    // 2. Extract substring between first '{' and last '}'
    final firstBrace = text.indexOf('{');
    final lastBrace = text.lastIndexOf('}');
    if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
      text = text.substring(firstBrace, lastBrace + 1);
    }

    return text;
  }

  static String _formatGeminiError(Object? error) {
    if (error == null) return 'Unknown error occurred communicating with Gemini.';
    final str = error.toString();
    if (str.contains('API_KEY_INVALID') || str.contains('API key not valid')) {
      return 'Google Gemini API key is invalid. Please verify the key at aistudio.google.com.';
    }
    if (str.contains('quota') || str.contains('RESOURCE_EXHAUSTED') || str.contains('429')) {
      return 'Gemini rate limit or quota exceeded (429). Please wait a moment or check your quota.';
    }
    if (str.contains('User location is not supported')) {
      return 'Google Gemini API is not supported in your current region or country.';
    }
    if (str.contains('not found') || str.contains('404')) {
      return 'Requested Gemini model was not found: $str';
    }
    return str.replaceAll('Exception: ', '');
  }
}
