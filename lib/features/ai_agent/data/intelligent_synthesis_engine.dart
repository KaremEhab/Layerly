import 'package:flutter/material.dart';
import 'package:layerly/core/utils/uuid_generator.dart';
import 'package:layerly/features/editor/domain/entities/auto_layout_layer.dart';
import 'package:layerly/features/editor/domain/entities/canvas_page.dart';
import 'package:layerly/features/editor/domain/entities/icon_layer.dart';
import 'package:layerly/features/editor/domain/entities/layer.dart';
import 'package:layerly/features/editor/domain/entities/layer_enums.dart';
import 'package:layerly/features/editor/domain/entities/text_layer.dart';
import '../domain/entities/design_recipe.dart';

/// Intelligent Synthesis Engine
/// Converts semantic Design Recipes (IR) into mathematically balanced,
/// pixel-perfect CanvasPages leveraging AutoLayout, typography scales, and rich gradients.
class IntelligentSynthesisEngine {
  /// Heuristically parse a natural language prompt into a DesignRecipe offline.
  static DesignRecipe parsePromptToRecipe(String prompt) {
    final lower = prompt.toLowerCase();

    // 1. Aspect Ratio Detection
    String aspectRatio = '1:1';
    if (lower.contains('1:1') || lower.contains('square') || lower.contains('instagram post')) {
      aspectRatio = '1:1';
    } else if (lower.contains('4:5') || lower.contains('portrait')) {
      aspectRatio = '4:5';
    } else if (lower.contains('9:16') || lower.contains('story') || lower.contains('reel')) {
      aspectRatio = '9:16';
    } else if (lower.contains('16:9') || lower.contains('landscape') || lower.contains('banner')) {
      aspectRatio = '16:9';
    }

    // 2. Domain Detection
    DesignDomain domain = DesignDomain.creative;
    if (lower.contains('pharma') ||
        lower.contains('medicine') ||
        lower.contains('drug') ||
        lower.contains('clinical') ||
        lower.contains('biotech') ||
        lower.contains('health')) {
      domain = DesignDomain.pharma;
    } else if (lower.contains('saas') || lower.contains('software') || lower.contains('tech') || lower.contains('app')) {
      domain = DesignDomain.saas;
    } else if (lower.contains('fitness') || lower.contains('gym') || lower.contains('workout')) {
      domain = DesignDomain.fitness;
    } else if (lower.contains('finance') || lower.contains('crypto') || lower.contains('banking')) {
      domain = DesignDomain.marketing;
    }

    // 3. Domain-specific content generation
    if (domain == DesignDomain.pharma) {
      return DesignRecipe(
        title: 'Precision Pharmacology & Molecular Therapeutics',
        subtitle: 'Breakthrough clinical research powering next-generation targeted pharmaceutical delivery.',
        badgeText: 'PHARMACEUTICAL R&D',
        badgeIcon: 'medication',
        domain: DesignDomain.pharma,
        layoutStyle: LayoutStyle.heroCards,
        aspectRatio: aspectRatio,
        gradientColors: const ['#041C24', '#063B48', '#0A1E24'],
        primaryColor: '#00D2B4', // Vibrant Clinical Cyan/Teal
        accentColor: '#10B981',  // Medical Emerald
        features: const [
          RecipeFeatureItem(
            title: 'Compound Efficacy',
            subtitle: 'Targeted receptor binding rate',
            value: '99.4%',
            iconName: 'biotech',
          ),
          RecipeFeatureItem(
            title: 'Clinical Validation',
            subtitle: 'FDA Multicenter Phase III trials',
            value: 'Phase III',
            iconName: 'health_and_safety',
          ),
          RecipeFeatureItem(
            title: 'Controlled Delivery',
            subtitle: 'Micro-encapsulated biopolymer release',
            value: '24hr Sustained',
            iconName: 'medication',
          ),
        ],
        footerText: 'Layerly Pharma Studio • clinical.layerly.io',
        ctaText: 'Explore Research Paper',
      );
    } else if (domain == DesignDomain.saas) {
      return DesignRecipe(
        title: 'Next-Generation Cloud Architecture',
        subtitle: 'Scalable infrastructure and sub-millisecond edge compute for global platforms.',
        badgeText: 'INFRASTRUCTURE 2.0',
        badgeIcon: 'cloud',
        domain: DesignDomain.saas,
        layoutStyle: LayoutStyle.heroCards,
        aspectRatio: aspectRatio,
        gradientColors: const ['#0F0C20', '#1F1440', '#0C0A1A'],
        primaryColor: '#8B5CF6',
        accentColor: '#EC4899',
        features: const [
          RecipeFeatureItem(
            title: 'Global Latency',
            subtitle: 'Real-time multi-region edge delivery',
            value: '< 8ms',
            iconName: 'bolt',
          ),
          RecipeFeatureItem(
            title: 'High Availability',
            subtitle: 'Guaranteed SLA uptime with zero downtime',
            value: '99.99%',
            iconName: 'shield',
          ),
          RecipeFeatureItem(
            title: 'Developer Velocity',
            subtitle: 'Automated CI/CD with smart deployments',
            value: '10x Faster',
            iconName: 'auto_awesome',
          ),
        ],
        footerText: 'Designed with Layerly Studio',
        ctaText: 'Get Started Today',
      );
    }

    // Default High-Aesthetic Creative Template
    return DesignRecipe(
      title: 'Elevate Your Digital Presence',
      subtitle: 'Harmonious typography, dynamic gradients, and fluid layout hierarchy designed with AI.',
      badgeText: 'CREATIVE SHOWCASE',
      badgeIcon: 'star',
      domain: DesignDomain.creative,
      layoutStyle: LayoutStyle.heroCards,
      aspectRatio: aspectRatio,
      gradientColors: const ['#120E24', '#26184E', '#100D1E'],
      primaryColor: '#A855F7',
      accentColor: '#06B6D4',
      features: const [
        RecipeFeatureItem(
          title: 'Design Precision',
          subtitle: 'Fluid AutoLayout calculations',
          value: '100% Vector',
          iconName: 'layers',
        ),
        RecipeFeatureItem(
          title: 'Color Palette',
          subtitle: 'Curated multi-stop gradient depth',
          value: 'Vibrant Mesh',
          iconName: 'palette',
        ),
        RecipeFeatureItem(
          title: 'Export Ready',
          subtitle: 'Direct high-res photo gallery saving',
          value: '4K Ready',
          iconName: 'download',
        ),
      ],
      footerText: 'Layerly AI Studio • layerly.design',
      ctaText: 'Create Your Next Post',
    );
  }

  /// Synthesize a full CanvasPage from a DesignRecipe.
  static CanvasPage synthesizeCanvasPage(DesignRecipe recipe) {
    // 1. Calculate Page Dimensions
    double width = 1080.0;
    double height = 1080.0;

    switch (recipe.aspectRatio) {
      case '4:5':
        width = 1080.0;
        height = 1350.0;
        break;
      case '9:16':
        width = 1080.0;
        height = 1920.0;
        break;
      case '16:9':
        width = 1920.0;
        height = 1080.0;
        break;
      case '1:1':
      default:
        width = 1080.0;
        height = 1080.0;
        break;
    }

    // 2. Derive Color Palette
    final gradColors = recipe.gradientColors.isNotEmpty
        ? recipe.gradientColors.map(_hexToColor).toList()
        : [const Color(0xFF0D0B14), const Color(0xFF1E1435)];
    final primaryColor = _hexToColor(recipe.primaryColor);
    final accentColor = _hexToColor(recipe.accentColor);

    // 3. Build Organic Ambient Background Gradient (Self-contained, no bleeding out-of-bounds layers)
    final pageGradient = RadialGradient(
      center: const Alignment(-0.25, -0.45),
      radius: 1.35,
      colors: [
        gradColors.length > 1
            ? gradColors[1].withValues(alpha: 0.92)
            : primaryColor.withValues(alpha: 0.28),
        gradColors.first,
        Color.lerp(gradColors.first, Colors.black, 0.48) ?? const Color(0xFF07050E),
      ],
      stops: const [0.0, 0.55, 1.0],
    );

    final List<Layer> layers = [];

    // Layout Margins
    final double marginX = width * 0.075;
    final double marginY = height * 0.075;
    final double contentWidth = width - (marginX * 2);

    // 4. Header AutoLayout: Badge Pill + Title + Subtitle
    final List<Layer> headerChildren = [];

    if (recipe.badgeText.isNotEmpty) {
      final badgePill = AutoLayoutLayer(
        id: UuidGenerator.generate(),
        name: 'Badge Pill',
        x: 0,
        y: 0,
        width: 240,
        height: 38,
        direction: AutoLayoutDirection.horizontal,
        horizontalSizing: AutoLayoutSizingMode.hug,
        verticalSizing: AutoLayoutSizingMode.hug,
        gap: 8,
        paddingHorizontal: 14,
        paddingVertical: 8,
        alignment: AutoLayoutAlignment.center,
        distribution: AutoLayoutDistribution.start,
        backgroundColor: primaryColor.withValues(alpha: 0.18),
        cornerRadius: 20,
        strokeColor: primaryColor.withValues(alpha: 0.50),
        strokeWidth: 1.2,
        children: [
          IconLayer(
            id: UuidGenerator.generate(),
            name: 'Badge Icon',
            x: 0,
            y: 0,
            width: 16,
            height: 16,
            icon: _resolveIcon(recipe.badgeIcon ?? 'medication'),
            color: primaryColor,
          ),
          TextLayer(
            id: UuidGenerator.generate(),
            name: 'Badge Text',
            x: 0,
            y: 0,
            width: 180,
            height: 20,
            horizontalSizing: AutoLayoutSizingMode.hug,
            content: recipe.badgeText.toUpperCase(),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            fontFamily: 'Outfit',
            color: primaryColor,
          ),
        ],
      );
      headerChildren.add(badgePill);
    }

    // Title Layer (with fixed sizing so text wraps properly within content width)
    final titleLayer = TextLayer(
      id: UuidGenerator.generate(),
      name: 'Hero Title',
      x: 0,
      y: 0,
      width: contentWidth,
      height: 120,
      horizontalSizing: AutoLayoutSizingMode.fixed,
      content: recipe.title,
      fontSize: width > 1200 ? 52 : 42,
      fontWeight: FontWeight.w900,
      fontFamily: 'Outfit',
      lineHeight: 1.18,
      letterSpacing: -0.6,
      color: Colors.white,
      shadows: [
        Shadow(
          color: Colors.black.withValues(alpha: 0.45),
          offset: const Offset(0, 4),
          blurRadius: 14,
        ),
      ],
    );
    headerChildren.add(titleLayer);

    // Subtitle Layer (with fixed sizing so it wraps gracefully)
    final subtitleLayer = TextLayer(
      id: UuidGenerator.generate(),
      name: 'Subtitle',
      x: 0,
      y: 0,
      width: contentWidth,
      height: 56,
      horizontalSizing: AutoLayoutSizingMode.fixed,
      content: recipe.subtitle,
      fontSize: 18,
      fontWeight: FontWeight.w400,
      fontFamily: 'Inter',
      lineHeight: 1.38,
      color: Colors.white.withValues(alpha: 0.78),
    );
    headerChildren.add(subtitleLayer);

    final headerAutoLayout = AutoLayoutLayer(
      id: UuidGenerator.generate(),
      name: 'Header Section',
      x: marginX,
      y: marginY,
      width: contentWidth,
      height: 230,
      direction: AutoLayoutDirection.vertical,
      horizontalSizing: AutoLayoutSizingMode.fixed,
      verticalSizing: AutoLayoutSizingMode.hug,
      gap: 14,
      paddingHorizontal: 0,
      paddingVertical: 0,
      alignment: AutoLayoutAlignment.start,
      distribution: AutoLayoutDistribution.start,
      children: headerChildren,
    );
    layers.add(headerAutoLayout);

    // 5. Cards Section: AutoLayout Cards with Stats
    if (recipe.features.isNotEmpty) {
      final List<Layer> featureCards = [];

      for (int i = 0; i < recipe.features.length; i++) {
        final feature = recipe.features[i];
        final isAccent = i == 0;

        final card = AutoLayoutLayer(
          id: UuidGenerator.generate(),
          name: 'Card: ${feature.title}',
          x: 0,
          y: 0,
          width: contentWidth,
          height: 104,
          direction: AutoLayoutDirection.horizontal,
          horizontalSizing: AutoLayoutSizingMode.fixed,
          verticalSizing: AutoLayoutSizingMode.fixed,
          gap: 16,
          paddingHorizontal: 20,
          paddingVertical: 14,
          alignment: AutoLayoutAlignment.center,
          distribution: AutoLayoutDistribution.spaceBetween,
          backgroundColor: const Color(0xFF131722).withValues(alpha: 0.76),
          cornerRadius: 18,
          strokeColor: isAccent
              ? primaryColor.withValues(alpha: 0.50)
              : Colors.white.withValues(alpha: 0.14),
          strokeWidth: 1.2,
          clipContent: true,
          children: [
            // Left: Icon Box + Title/Subtitle Column
            AutoLayoutLayer(
              id: UuidGenerator.generate(),
              name: 'Icon & Info',
              x: 0,
              y: 0,
              width: contentWidth * 0.65,
              height: 70,
              direction: AutoLayoutDirection.horizontal,
              horizontalSizing: AutoLayoutSizingMode.hug,
              verticalSizing: AutoLayoutSizingMode.hug,
              gap: 16,
              paddingHorizontal: 0,
              paddingVertical: 0,
              alignment: AutoLayoutAlignment.center,
              distribution: AutoLayoutDistribution.start,
              children: [
                // Icon Container
                AutoLayoutLayer(
                  id: UuidGenerator.generate(),
                  name: 'Icon Wrapper',
                  x: 0,
                  y: 0,
                  width: 48,
                  height: 48,
                  direction: AutoLayoutDirection.horizontal,
                  horizontalSizing: AutoLayoutSizingMode.fixed,
                  verticalSizing: AutoLayoutSizingMode.fixed,
                  gap: 0,
                  paddingHorizontal: 12,
                  paddingVertical: 12,
                  alignment: AutoLayoutAlignment.center,
                  distribution: AutoLayoutDistribution.center,
                  backgroundColor: (isAccent ? primaryColor : accentColor).withValues(alpha: 0.18),
                  cornerRadius: 14,
                  children: [
                    IconLayer(
                      id: UuidGenerator.generate(),
                      name: 'Icon',
                      x: 0,
                      y: 0,
                      width: 24,
                      height: 24,
                      icon: _resolveIcon(feature.iconName),
                      color: isAccent ? primaryColor : accentColor,
                    ),
                  ],
                ),
                // Text Column
                AutoLayoutLayer(
                  id: UuidGenerator.generate(),
                  name: 'Text Column',
                  x: 0,
                  y: 0,
                  width: contentWidth * 0.48,
                  height: 56,
                  direction: AutoLayoutDirection.vertical,
                  horizontalSizing: AutoLayoutSizingMode.hug,
                  verticalSizing: AutoLayoutSizingMode.hug,
                  gap: 3,
                  paddingHorizontal: 0,
                  paddingVertical: 0,
                  alignment: AutoLayoutAlignment.start,
                  distribution: AutoLayoutDistribution.center,
                  children: [
                    TextLayer(
                      id: UuidGenerator.generate(),
                      name: 'Feature Title',
                      x: 0,
                      y: 0,
                      width: contentWidth * 0.48,
                      height: 24,
                      horizontalSizing: AutoLayoutSizingMode.hug,
                      content: feature.title,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Outfit',
                      color: Colors.white,
                    ),
                    if (feature.subtitle != null)
                      TextLayer(
                        id: UuidGenerator.generate(),
                        name: 'Feature Subtitle',
                        x: 0,
                        y: 0,
                        width: contentWidth * 0.48,
                        height: 18,
                        horizontalSizing: AutoLayoutSizingMode.hug,
                        content: feature.subtitle!,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Inter',
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                  ],
                ),
              ],
            ),
            // Right: Highlight Value Pill
            if (feature.value != null)
              AutoLayoutLayer(
                id: UuidGenerator.generate(),
                name: 'Value Pill',
                x: 0,
                y: 0,
                width: 130,
                height: 40,
                direction: AutoLayoutDirection.horizontal,
                horizontalSizing: AutoLayoutSizingMode.hug,
                verticalSizing: AutoLayoutSizingMode.hug,
                gap: 6,
                paddingHorizontal: 16,
                paddingVertical: 8,
                alignment: AutoLayoutAlignment.center,
                distribution: AutoLayoutDistribution.center,
                backgroundColor: (isAccent ? primaryColor : accentColor).withValues(alpha: 0.18),
                cornerRadius: 12,
                strokeColor: (isAccent ? primaryColor : accentColor).withValues(alpha: 0.38),
                strokeWidth: 1.2,
                children: [
                  TextLayer(
                    id: UuidGenerator.generate(),
                    name: 'Value',
                    x: 0,
                    y: 0,
                    width: 100,
                    height: 22,
                    horizontalSizing: AutoLayoutSizingMode.hug,
                    content: feature.value!,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Outfit',
                    textAlign: TextAlign.center,
                    color: isAccent ? primaryColor : accentColor,
                  ),
                ],
              ),
          ],
        );
        featureCards.add(card);
      }

      final cardsContainer = AutoLayoutLayer(
        id: UuidGenerator.generate(),
        name: 'Features Group',
        x: marginX,
        y: height * 0.42,
        width: contentWidth,
        height: height * 0.42,
        direction: AutoLayoutDirection.vertical,
        horizontalSizing: AutoLayoutSizingMode.fixed,
        verticalSizing: AutoLayoutSizingMode.hug,
        gap: 14,
        paddingHorizontal: 0,
        paddingVertical: 0,
        alignment: AutoLayoutAlignment.center,
        distribution: AutoLayoutDistribution.start,
        children: featureCards,
      );
      layers.add(cardsContainer);
    }

    // 6. Footer Section: Watermark & Branding Info (Pushed to bottom of page within margins)
    final footerText = recipe.footerText ?? 'Layerly Studio • Generated by AI';
    final footerLayer = AutoLayoutLayer(
      id: UuidGenerator.generate(),
      name: 'Footer Bar',
      x: marginX,
      y: height - marginY - 44,
      width: contentWidth,
      height: 44,
      direction: AutoLayoutDirection.horizontal,
      horizontalSizing: AutoLayoutSizingMode.fixed,
      verticalSizing: AutoLayoutSizingMode.hug,
      gap: 10,
      paddingHorizontal: 4,
      paddingVertical: 4,
      alignment: AutoLayoutAlignment.center,
      distribution: AutoLayoutDistribution.spaceBetween,
      children: [
        TextLayer(
          id: UuidGenerator.generate(),
          name: 'Footer Text',
          x: 0,
          y: 0,
          width: contentWidth * 0.60,
          height: 20,
          horizontalSizing: AutoLayoutSizingMode.hug,
          content: footerText,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.white.withValues(alpha: 0.55),
        ),
        if (recipe.ctaText != null)
          AutoLayoutLayer(
            id: UuidGenerator.generate(),
            name: 'Footer CTA',
            x: 0,
            y: 0,
            width: 170,
            height: 36,
            direction: AutoLayoutDirection.horizontal,
            horizontalSizing: AutoLayoutSizingMode.hug,
            verticalSizing: AutoLayoutSizingMode.hug,
            gap: 6,
            paddingHorizontal: 14,
            paddingVertical: 7,
            alignment: AutoLayoutAlignment.center,
            distribution: AutoLayoutDistribution.center,
            backgroundColor: primaryColor.withValues(alpha: 0.22),
            cornerRadius: 18,
            strokeColor: primaryColor.withValues(alpha: 0.45),
            strokeWidth: 1,
            children: [
              TextLayer(
                id: UuidGenerator.generate(),
                name: 'CTA Text',
                x: 0,
                y: 0,
                width: 130,
                height: 18,
                horizontalSizing: AutoLayoutSizingMode.hug,
                content: recipe.ctaText!,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                textAlign: TextAlign.center,
                color: Colors.white,
              ),
              IconLayer(
                id: UuidGenerator.generate(),
                name: 'CTA Arrow',
                x: 0,
                y: 0,
                width: 14,
                height: 14,
                icon: Icons.arrow_forward_rounded,
                color: Colors.white,
              ),
            ],
          ),
      ],
    );
    layers.add(footerLayer);

    return CanvasPage(
      id: UuidGenerator.generate(),
      name: '${recipe.domain.name.toUpperCase()} 1:1 Design',
      width: width,
      height: height,
      backgroundType: BackgroundType.gradient,
      backgroundColor: gradColors.first,
      backgroundGradient: pageGradient,
      layers: layers,
    );
  }

  // --- Helper Methods ---
  static Color _hexToColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return const Color(0xFF8B5CF6);
    }
  }

  static IconData _resolveIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'medication':
      case 'pill':
        return Icons.medication_rounded;
      case 'health_and_safety':
      case 'health':
        return Icons.health_and_safety_rounded;
      case 'biotech':
      case 'dna':
        return Icons.biotech_rounded;
      case 'science':
      case 'flask':
        return Icons.science_rounded;
      case 'local_hospital':
      case 'hospital':
        return Icons.local_hospital_rounded;
      case 'healing':
        return Icons.healing_rounded;
      case 'bolt':
      case 'flash':
        return Icons.bolt_rounded;
      case 'shield':
      case 'security':
        return Icons.shield_rounded;
      case 'auto_awesome':
      case 'sparkle':
      case 'ai':
        return Icons.auto_awesome_rounded;
      case 'layers':
        return Icons.layers_rounded;
      case 'palette':
        return Icons.palette_rounded;
      case 'cloud':
        return Icons.cloud_rounded;
      case 'download':
        return Icons.download_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'check_circle':
      default:
        return Icons.check_circle_rounded;
    }
  }
}
