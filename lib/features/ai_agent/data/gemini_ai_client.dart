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
        'You are a Principal Product Designer & UI/UX Design Systems Architect for Apple-grade iOS mobile apps and Layerly Studio.\n'
        'You master both minimal, professional mobile application designs (Apple HIG standards) and modern digital product architectures.\n\n'
        'CRITICAL RULE: REAL MOBILE APP SCREENS vs MARKETING GRAPHICS:\n'
        'When the user asks for an APP design (e.g. "uber app ui ux design", "mobile app", "food delivery app", "banking app", "fitness app", "ios app", "iphone screen", or any application interface):\n'
        '1. You MUST set:\n'
        '   - "layoutStyle": "mobileAppScreen"\n'
        '   - "aspectRatio": "9:16"\n'
        '   - "headingFont": "Inter"\n'
        '   - "bodyFont": "Inter"\n'
        '   - "cardAesthetic": "minimal"\n'
        '2. REAL IN-APP CONTENT ONLY (NO MARKETING BANNERS):\n'
        '   - "title": In-app screen header or greeting (e.g. "Where to?", "Uber", "Activity", "Good morning, Alex")\n'
        '   - "subtitle": In-app status or instruction (e.g. "Choose your ride or schedule ahead", "Available balance", "San Francisco, CA")\n'
        '   - "badgeText": Current context/tag (e.g. "NOW", "RIDE", "SAN FRANCISCO", "ACTIVE")\n'
        '   - "features": 3 to 4 real in-app tiers/cards with realistic names, descriptions, prices, ETA, and icons.\n'
        '     For Uber/Mobility:\n'
        '     * Card 1: title: "UberX", subtitle: "Affordable, everyday rides • 3 min away", value: "\\\$18.50", iconName: "directions_car", isHeroTile: true, tag: "POPULAR"\n'
        '     * Card 2: title: "Comfort", subtitle: "Newer cars with extra legroom • 5 min away", value: "\\\$24.20", iconName: "car_rental"\n'
        '     * Card 3: title: "Black", subtitle: "Premium rides with top-rated drivers • 8 min away", value: "\\\$38.00", iconName: "workspace_premium", tag: "PREMIUM"\n'
        '     * Card 4: title: "UberXL", subtitle: "Spacious SUVs for up to 6 people • 6 min away", value: "\\\$29.50", iconName: "airport_shuttle"\n'
        '   - "footerText": "Home • Work • SFO Airport" (Saved place destinations)\n'
        '   - "ctaText": Real in-app action button (e.g. "Choose UberX", "Confirm Ride", "Request Now")\n'
        '   - NEVER output marketing buzzwords like "Next-Gen Food Delivery UX", "Architecture • Layerly Studio Design", or "Explore UI Kit" for an app design! It must look and feel like an installed, minimal Apple iOS app.\n\n'
        'OTHER ARCHETYPES (for social banners, tech posters, and pitch graphics):\n'
        '- splitBento: Modern asymmetric Bento Grid for feature showcases.\n'
        '- featureGrid: Symmetrical 2x2 grid.\n'
        '- statisticFocus: Metrics/KPI dashboard.\n'
        '- heroCards: Vertical stacked glassmorphic cards.\n'
        '- centeredMinimal: Symmetrical editorial composition.\n\n'
        'Output pure JSON ONLY. Do not wrap in markdown code fences (do not include ```json), no conversational preamble.',
      ),
    );

    final promptBuffer = StringBuffer();
    promptBuffer.writeln('Generate a complete design recipe JSON for the user request: "$prompt"');
    promptBuffer.writeln();
    promptBuffer.writeln('Required JSON structure:');
    promptBuffer.writeln('{');
    promptBuffer.writeln('  "title": "In-app header or headline (e.g. Where to? or Uber)",');
    promptBuffer.writeln('  "subtitle": "In-app subheader or status",');
    promptBuffer.writeln('  "badgeText": "Short uppercase tag e.g. NOW or MOBILITY",');
    promptBuffer.writeln('  "badgeIcon": "Icon name e.g. directions_car, location_on, bolt, star, shield, cloud",');
    promptBuffer.writeln('  "domain": "mobility|fintech|ecommerce|saas|tech|fitness|healthcare|pharma|marketing|creative",');
    promptBuffer.writeln('  "layoutStyle": "mobileAppScreen|splitBento|featureGrid|statisticFocus|heroCards|centeredMinimal",');
    promptBuffer.writeln('  "cardAesthetic": "minimal|glass|solidElevated|gradientBorder",');
    promptBuffer.writeln('  "backgroundStyle": "darkStudio|meshRadial|linearAtmosphere|cleanLight",');
    promptBuffer.writeln('  "headingFont": "Inter|Outfit|Space Grotesk",');
    promptBuffer.writeln('  "bodyFont": "Inter|Roboto",');
    promptBuffer.writeln('  "aspectRatio": "9:16|1:1|4:5|16:9",');
    promptBuffer.writeln('  "gradientColors": ["#000000", "#12111A", "#1C1C24"],');
    promptBuffer.writeln('  "primaryColor": "#FFFFFF",');
    promptBuffer.writeln('  "accentColor": "#10B981",');
    promptBuffer.writeln('  "features": [');
    promptBuffer.writeln('    {');
    promptBuffer.writeln('      "title": "UberX",');
    promptBuffer.writeln('      "subtitle": "Affordable, everyday rides • 3 min away",');
    promptBuffer.writeln('      "value": "\\\$18.50",');
    promptBuffer.writeln('      "iconName": "directions_car",');
    promptBuffer.writeln('      "isHeroTile": true,');
    promptBuffer.writeln('      "trend": "3 min",');
    promptBuffer.writeln('      "tag": "POPULAR"');
    promptBuffer.writeln('    }');
    promptBuffer.writeln('  ],');
    promptBuffer.writeln('  "footerText": "Home • Work • SFO Airport",');
    promptBuffer.writeln('  "ctaText": "Choose UberX"');
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
        'title': Schema.string(description: 'In-app header or compelling headline'),
        'subtitle': Schema.string(description: 'In-app subtext or description'),
        'badgeText': Schema.string(description: 'Short uppercase category badge or tag e.g. NOW or MOBILITY'),
        'badgeIcon': Schema.string(description: 'Icon name e.g. directions_car, location_on, bolt, star, shield, cloud'),
        'domain': Schema.string(description: 'One of: mobility, fintech, ecommerce, saas, tech, fitness, healthcare, pharma, marketing, creative'),
        'layoutStyle': Schema.string(description: 'One of: mobileAppScreen, splitBento, featureGrid, statisticFocus, heroCards, centeredMinimal'),
        'cardAesthetic': Schema.string(description: 'One of: minimal, glass, solidElevated, gradientBorder'),
        'backgroundStyle': Schema.string(description: 'One of: darkStudio, meshRadial, linearAtmosphere, cleanLight'),
        'headingFont': Schema.string(description: 'Heading font name e.g. Inter, Outfit, Space Grotesk'),
        'bodyFont': Schema.string(description: 'Body font name e.g. Inter, Roboto'),
        'aspectRatio': Schema.string(description: 'Aspect ratio: 9:16 (for mobile apps), 1:1, 4:5, or 16:9'),
        'gradientColors': Schema.array(
          description: '2 to 3 hex colors for background gradient',
          items: Schema.string(),
        ),
        'primaryColor': Schema.string(description: 'Hex color for primary highlights/buttons'),
        'accentColor': Schema.string(description: 'Hex color for secondary accents/tags'),
        'features': Schema.array(
          description: '2 to 4 in-app service options, features, or metric cards',
          items: Schema.object(
            properties: {
              'title': Schema.string(description: 'Card title e.g. UberX'),
              'subtitle': Schema.string(description: 'Card subtitle or description e.g. Affordable everyday rides'),
              'value': Schema.string(description: 'Price or metric value e.g. \$18.50'),
              'iconName': Schema.string(description: 'Icon name e.g. directions_car, car_rental, workspace_premium, airport_shuttle'),
              'isHeroTile': Schema.boolean(description: 'True if this card should be selected or prominent'),
              'trend': Schema.string(description: 'Optional ETA or trend e.g. 3 min'),
              'tag': Schema.string(description: 'Short status chip e.g. POPULAR, FASTEST, PREMIUM'),
            },
            requiredProperties: ['title'],
          ),
        ),
        'footerText': Schema.string(description: 'Recent destinations or footer text e.g. Home • Work • SFO Airport'),
        'ctaText': Schema.string(description: 'Primary in-app call to action button e.g. Choose UberX'),
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
