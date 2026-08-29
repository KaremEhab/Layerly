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

    for (final m in available) {
      if (!sorted.contains(m) && (m.contains('flash') || m.contains('pro'))) {
        sorted.add(m);
      }
    }

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
      debugPrint('[GeminiAiClient] Attempting generation with $modelName (with responseSchema)...');
      try {
        final recipe = await _generateWithModel(modelName, prompt, withSchema: true);
        lastUsedModel = modelName;
        _cachedBestModel = modelName;
        _cachedApiKey = cleanKey;
        debugPrint('[GeminiAiClient] Successfully generated recipe with $modelName');
        return recipe;
      } catch (e) {
        lastError = e;
        final errStr = e.toString();
        debugPrint('[GeminiAiClient] $modelName with schema failed: $errStr');

        // If it's 503 high demand or 429 quota, don't waste time on the same overloaded model; cascade to next candidate
        final isServerOverloaded = errStr.contains('503') ||
            errStr.contains('high demand') ||
            errStr.contains('UNAVAILABLE') ||
            errStr.contains('429') ||
            errStr.contains('RESOURCE_EXHAUSTED');

        if (isServerOverloaded) {
          debugPrint('[GeminiAiClient] Model $modelName is busy/overloaded (503/429). Cascading to next candidate...');
          await Future.delayed(const Duration(milliseconds: 600));
          continue;
        }

        // If it's a schema syntax issue, retry without schema
        try {
          debugPrint('[GeminiAiClient] Retrying $modelName without schema...');
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
        'You are a Principal Figma Design Architect & Visual AI Agent for Layerly Studio. '
        'You master modern digital product graphic design, social banners, and layout architectures.\n\n'
        'DESIGN RULES YOU MUST ADHERE TO:\n'
        '1. ARCHETYPE SELECTION (layoutStyle):\n'
        '   - splitBento: Modern asymmetric Bento Grid. Use for tech/SaaS feature showcases or rich multi-metric posts. Provide 1 hero feature (isHeroTile: true) and 2 supporting cards.\n'
        '   - featureGrid: Symmetrical 2x2 grid. Use when showcasing exactly 4 features or comparison items.\n'
        '   - statisticFocus: Heavy KPI / metrics focus. Highlight big statistics (e.g. 99.99%, < 5ms, 142%) with trend arrows and clear metric labels.\n'
        '   - heroCards: Vertical stacked glassmorphic cards with icons and value chips. High clarity, easy scanning.\n'
        '   - centeredMinimal: Symmetrical editorial composition with elegant spacing, divider lines, and central typography focus.\n\n'
        '2. 8PT SPATIAL SYSTEM & RATIO CONTAINMENT:\n'
        '   - All elements must be strictly contained inside the safe margins (7.5% padding on all sides). Never generate elements outside canvas bounds.\n'
        '   - Use standard 8pt tokens for gaps (12, 16, 20px) and card paddings (16, 20, 24px).\n\n'
        '3. TYPOGRAPHY & CONTRAST:\n'
        '   - Headlines must be punchy, high-contrast, and concise (under 8 words).\n'
        '   - Subtitles must provide clear context in 1-2 lines.\n'
        '   - Badges should be uppercase with short category tags (e.g. "CLINICAL R&D", "ENTERPRISE SAAS").\n\n'
        '4. COLOR HARMONY & MOOD:\n'
        '   - Generate rich, non-generic palettes with 2-3 deep gradient background tones and high-vibrancy primary/accent highlights (e.g. Clinical Teal #00D2B4, Electric Violet #8B5CF6, Emerald #10B981, Cyberpunk Coral #F43F5E).\n\n'
        'Output pure JSON ONLY. Do not wrap in markdown code fences (do not include ```json), no conversational preamble.',
      ),
    );

    final promptBuffer = StringBuffer();
    promptBuffer.writeln('Generate a complete graphic design recipe JSON for the user request: "$prompt"');
    promptBuffer.writeln();
    promptBuffer.writeln('Required JSON structure:');
    promptBuffer.writeln('{');
    promptBuffer.writeln('  "title": "Compelling headline (e.g. Unmatched Cloud Performance)",');
    promptBuffer.writeln('  "subtitle": "Informative subtext explaining the subject",');
    promptBuffer.writeln('  "badgeText": "UPPERCASE CATEGORY BADGE",');
    promptBuffer.writeln('  "badgeIcon": "Icon name e.g. medication, biotech, health_and_safety, bolt, shield, cloud, star",');
    promptBuffer.writeln('  "domain": "pharma|healthcare|tech|saas|fitness|marketing|ecommerce|creative",');
    promptBuffer.writeln('  "layoutStyle": "splitBento|featureGrid|statisticFocus|heroCards|centeredMinimal",');
    promptBuffer.writeln('  "cardAesthetic": "glass|solidElevated|gradientBorder|minimal",');
    promptBuffer.writeln('  "backgroundStyle": "meshRadial|linearAtmosphere|darkStudio|cleanLight",');
    promptBuffer.writeln('  "headingFont": "Outfit|Space Grotesk|Poppins|Inter",');
    promptBuffer.writeln('  "bodyFont": "Inter|Roboto",');
    promptBuffer.writeln('  "aspectRatio": "1:1|4:5|9:16|16:9",');
    promptBuffer.writeln('  "gradientColors": ["#0F0C20", "#1F1440", "#0C0A1A"],');
    promptBuffer.writeln('  "primaryColor": "#8B5CF6",');
    promptBuffer.writeln('  "accentColor": "#00D2B4",');
    promptBuffer.writeln('  "features": [');
    promptBuffer.writeln('    {');
    promptBuffer.writeln('      "title": "Card Title",');
    promptBuffer.writeln('      "subtitle": "Card Description",');
    promptBuffer.writeln('      "value": "99.99%",');
    promptBuffer.writeln('      "iconName": "cloud",');
    promptBuffer.writeln('      "isHeroTile": true,');
    promptBuffer.writeln('      "trend": "+142%",');
    promptBuffer.writeln('      "tag": "LIVE"');
    promptBuffer.writeln('    }');
    promptBuffer.writeln('  ],');
    promptBuffer.writeln('  "footerText": "Attribution or brand text",');
    promptBuffer.writeln('  "ctaText": "Call to action label"');
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
        'badgeIcon': Schema.string(description: 'Icon name e.g. medication, health_and_safety, biotech, bolt, star, cloud'),
        'domain': Schema.string(description: 'One of: pharma, healthcare, tech, saas, fitness, marketing, ecommerce, creative'),
        'layoutStyle': Schema.string(description: 'One of: splitBento, featureGrid, statisticFocus, heroCards, centeredMinimal'),
        'cardAesthetic': Schema.string(description: 'One of: glass, solidElevated, gradientBorder, minimal'),
        'backgroundStyle': Schema.string(description: 'One of: meshRadial, linearAtmosphere, darkStudio, cleanLight'),
        'headingFont': Schema.string(description: 'Heading font name e.g. Outfit, Space Grotesk, Poppins, Inter'),
        'bodyFont': Schema.string(description: 'Body font name e.g. Inter, Roboto'),
        'aspectRatio': Schema.string(description: 'Aspect ratio: 1:1, 4:5, 9:16, or 16:9'),
        'gradientColors': Schema.array(
          description: '2 to 3 hex colors for rich background gradient',
          items: Schema.string(),
        ),
        'primaryColor': Schema.string(description: 'Hex color for primary highlights/buttons'),
        'accentColor': Schema.string(description: 'Hex color for secondary accents/tags'),
        'features': Schema.array(
          description: '2 to 4 feature or metric cards',
          items: Schema.object(
            properties: {
              'title': Schema.string(description: 'Card title'),
              'subtitle': Schema.string(description: 'Card subtitle or description'),
              'value': Schema.string(description: 'Stat or metric value e.g. 99.4% or Phase III'),
              'iconName': Schema.string(description: 'Icon name e.g. medication, biotech, health_and_safety, shield, bolt, cloud'),
              'isHeroTile': Schema.boolean(description: 'True if this card should be the prominent hero tile in a Bento layout'),
              'trend': Schema.string(description: 'Optional trend or growth indicator e.g. +142% or 4.9/5'),
              'tag': Schema.string(description: 'Short status chip e.g. LIVE, NEW, PRO'),
            },
            requiredProperties: ['title'],
          ),
        ),
        'footerText': Schema.string(description: 'Footer attribution or branding text'),
        'ctaText': Schema.string(description: 'Call to action text'),
      },
      requiredProperties: ['title', 'subtitle', 'badgeText', 'domain', 'aspectRatio', 'layoutStyle'],
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
    if (str.contains('503') || str.contains('high demand') || str.contains('UNAVAILABLE')) {
      return 'Google Gemini model servers are temporarily experiencing high traffic (503). Retrying with alternative models...';
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
