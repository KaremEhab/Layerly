import 'package:flutter/material.dart';
import 'package:layerly/core/utils/uuid_generator.dart';
import 'package:layerly/features/editor/domain/entities/auto_layout_layer.dart';
import 'package:layerly/features/editor/domain/entities/canvas_page.dart';
import 'package:layerly/features/editor/domain/entities/icon_layer.dart';
import 'package:layerly/features/editor/domain/entities/layer.dart';
import 'package:layerly/features/editor/domain/entities/layer_enums.dart';
import 'package:layerly/features/editor/domain/entities/shape_layer.dart';
import 'package:layerly/features/editor/domain/entities/text_layer.dart';
import '../domain/entities/design_recipe.dart';

/// Intelligent Synthesis Engine V2
/// Generates Figma-grade, pixel-perfect CanvasPages with deep layout archetypes:
/// - Asymmetric Bento Grids
/// - 2x2 Feature Grids
/// - KPI / Statistic Dashboards
/// - Hero Feature Stacks
/// - Centered Editorial Minimalist
class IntelligentSynthesisEngine {
  /// Heuristically parse a natural language prompt into a rich DesignRecipe offline.
  static DesignRecipe parsePromptToRecipe(String prompt) {
    final lower = prompt.toLowerCase();

    // 1. Aspect Ratio Detection
    String aspectRatio = '1:1';
    if (lower.contains('4:5') || lower.contains('portrait')) {
      aspectRatio = '4:5';
    } else if (lower.contains('9:16') || lower.contains('story') || lower.contains('reel')) {
      aspectRatio = '9:16';
    } else if (lower.contains('16:9') || lower.contains('landscape') || lower.contains('banner')) {
      aspectRatio = '16:9';
    }

    // 2. Layout Style Archetype Detection
    LayoutStyle layoutStyle = LayoutStyle.heroCards;
    if (lower.contains('bento')) {
      layoutStyle = LayoutStyle.splitBento;
    } else if (lower.contains('grid') || lower.contains('2x2') || lower.contains('four')) {
      layoutStyle = LayoutStyle.featureGrid;
    } else if (lower.contains('stat') || lower.contains('metric') || lower.contains('kpi') || lower.contains('number') || lower.contains('dashboard')) {
      layoutStyle = LayoutStyle.statisticFocus;
    } else if (lower.contains('minimal') || lower.contains('editorial') || lower.contains('luxury') || lower.contains('simple')) {
      layoutStyle = LayoutStyle.centeredMinimal;
    }

    // 3. Domain Detection
    DesignDomain domain = DesignDomain.creative;
    if (lower.contains('pharma') || lower.contains('medicine') || lower.contains('drug') || lower.contains('clinical') || lower.contains('biotech') || lower.contains('health')) {
      domain = DesignDomain.pharma;
    } else if (lower.contains('saas') || lower.contains('software') || lower.contains('tech') || lower.contains('cloud') || lower.contains('api')) {
      domain = DesignDomain.saas;
    } else if (lower.contains('fitness') || lower.contains('gym') || lower.contains('workout') || lower.contains('training')) {
      domain = DesignDomain.fitness;
    } else if (lower.contains('finance') || lower.contains('crypto') || lower.contains('banking') || lower.contains('invest')) {
      domain = DesignDomain.marketing;
    }

    if (domain == DesignDomain.pharma) {
      return DesignRecipe(
        title: 'Precision Pharmacology & Molecular Delivery',
        subtitle: 'Next-generation clinical research powering targeted therapeutic biopolymers.',
        badgeText: 'PHARMACEUTICAL R&D',
        badgeIcon: 'medication',
        domain: DesignDomain.pharma,
        layoutStyle: layoutStyle,
        cardAesthetic: CardAesthetic.glass,
        backgroundStyle: BackgroundStyle.meshRadial,
        headingFont: 'Outfit',
        bodyFont: 'Inter',
        aspectRatio: aspectRatio,
        gradientColors: const ['#041C24', '#063B48', '#07161C'],
        primaryColor: '#00D2B4',
        accentColor: '#10B981',
        features: const [
          RecipeFeatureItem(
            title: 'Compound Efficacy',
            subtitle: 'Targeted receptor binding rate',
            value: '99.4%',
            iconName: 'biotech',
            isHeroTile: true,
            trend: '+18.2% vs Std',
            tag: 'PHASE III',
          ),
          RecipeFeatureItem(
            title: 'Bioavailability',
            subtitle: 'Plasma absorption curve',
            value: '< 15min',
            iconName: 'health_and_safety',
            trend: 'Instant Peak',
            tag: 'FDA CLEARED',
          ),
          RecipeFeatureItem(
            title: 'Controlled Release',
            subtitle: 'Micro-encapsulated sustained delivery',
            value: '24hr',
            iconName: 'medication',
            trend: 'Zero Spike',
          ),
          RecipeFeatureItem(
            title: 'Patient Retention',
            subtitle: 'Clinical multicenter tolerance',
            value: '98.7%',
            iconName: 'shield',
            trend: '▲ High Safety',
          ),
        ],
        footerText: 'Layerly Pharma Studio • clinical.layerly.io',
        ctaText: 'Explore Research Paper',
      );
    } else if (domain == DesignDomain.saas) {
      return DesignRecipe(
        title: 'Autonomous Cloud Scale & Edge Compute',
        subtitle: 'Sub-millisecond latency distributed across 280+ global edge points of presence.',
        badgeText: 'INFRASTRUCTURE 3.0',
        badgeIcon: 'cloud',
        domain: DesignDomain.saas,
        layoutStyle: layoutStyle,
        cardAesthetic: CardAesthetic.glass,
        backgroundStyle: BackgroundStyle.meshRadial,
        headingFont: 'Outfit',
        bodyFont: 'Inter',
        aspectRatio: aspectRatio,
        gradientColors: const ['#0F0C20', '#1F1440', '#0C0A1A'],
        primaryColor: '#8B5CF6',
        accentColor: '#00D2B4',
        features: const [
          RecipeFeatureItem(
            title: 'Global Latency',
            subtitle: 'P99 round-trip edge network time',
            value: '< 4ms',
            iconName: 'bolt',
            isHeroTile: true,
            trend: '▲ 6x Faster',
            tag: 'ULTRA LOW',
          ),
          RecipeFeatureItem(
            title: 'Availability SLA',
            subtitle: 'Multi-region active-active cluster failovers',
            value: '99.99%',
            iconName: 'shield',
            trend: 'Zero Outage',
            tag: 'ENTERPRISE',
          ),
          RecipeFeatureItem(
            title: 'Auto Scaling',
            subtitle: 'Instant burst throughput capacity',
            value: '2.4M req/s',
            iconName: 'cloud',
            trend: '+140% MoM',
          ),
          RecipeFeatureItem(
            title: 'Cost Efficiency',
            subtitle: 'Dynamic resource optimization',
            value: '-42%',
            iconName: 'star',
            trend: 'Annual Savings',
          ),
        ],
        footerText: 'Layerly Cloud • platform.layerly.io',
        ctaText: 'Deploy in 60 Seconds',
      );
    } else {
      return DesignRecipe(
        title: 'Precision Visual Studio & Design Systems',
        subtitle: 'Craft production-ready graphics, social campaigns, and interactive design layouts.',
        badgeText: 'STUDIO GENERATIVE',
        badgeIcon: 'auto_awesome',
        domain: DesignDomain.creative,
        layoutStyle: layoutStyle,
        cardAesthetic: CardAesthetic.glass,
        backgroundStyle: BackgroundStyle.meshRadial,
        headingFont: 'Outfit',
        bodyFont: 'Inter',
        aspectRatio: aspectRatio,
        gradientColors: const ['#120E24', '#26184E', '#100D1E'],
        primaryColor: '#A855F7',
        accentColor: '#06B6D4',
        features: const [
          RecipeFeatureItem(
            title: 'AutoLayout Precision',
            subtitle: 'Mathematical token alignment & spatial distribution',
            value: '100% Vector',
            iconName: 'layers',
            isHeroTile: true,
            trend: 'Figma Parity',
            tag: 'FEATURED',
          ),
          RecipeFeatureItem(
            title: 'Color Dynamics',
            subtitle: 'Curated harmonic gradient meshes',
            value: 'HDR Palette',
            iconName: 'palette',
            trend: 'Vibrant',
          ),
          RecipeFeatureItem(
            title: 'Instant Export',
            subtitle: 'High-resolution gallery saving and sharing',
            value: '4K Ready',
            iconName: 'download',
            trend: 'Lossless',
          ),
          RecipeFeatureItem(
            title: 'Smart Typography',
            subtitle: 'Fluid scale hierarchy and text wrap',
            value: 'AAA Contrast',
            iconName: 'star',
            trend: 'Editorial',
          ),
        ],
        footerText: 'Layerly AI Studio • layerly.design',
        ctaText: 'Generate Your Next Post',
      );
    }
  }

  /// Synthesizes a full CanvasPage adhering to the specified Figma layout archetype.
  static CanvasPage synthesizeCanvasPage(
    DesignRecipe recipe, {
    double horizontalPadding = 20.0,
    double verticalPadding = 20.0,
  }) {
    // 1. Compute Page Dimensions
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

    // 3. Build Organic Ambient Background Gradient
    final Gradient pageGradient = recipe.backgroundStyle == BackgroundStyle.linearAtmosphere
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              gradColors.first,
              gradColors.length > 1 ? gradColors[1] : primaryColor.withValues(alpha: 0.2),
              Color.lerp(gradColors.last, Colors.black, 0.5) ?? const Color(0xFF07050E),
            ],
            stops: const [0.0, 0.5, 1.0],
          )
        : RadialGradient(
            center: recipe.layoutStyle == LayoutStyle.centeredMinimal
                ? Alignment.topCenter
                : const Alignment(-0.25, -0.45),
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

    // Spatial Margins (Aligned with the page's 20x20px guide margins)
    final double marginX = horizontalPadding;
    final double marginY = verticalPadding;
    final double contentWidth = width - (marginX * 2);

    // 4. Header Section
    final headerLayer = _buildHeaderSection(
      recipe: recipe,
      contentWidth: contentWidth,
      marginX: marginX,
      marginY: marginY,
      primaryColor: primaryColor,
      isCentered: recipe.layoutStyle == LayoutStyle.centeredMinimal,
    );
    layers.add(headerLayer);

    // 5. Body Section (Archetype Builder)
    final double bodyStartY = marginY + 225.0;
    final double bodyHeight = height - bodyStartY - marginY - 50.0;

    switch (recipe.layoutStyle) {
      case LayoutStyle.splitBento:
        final bentoLayer = _buildSplitBentoSection(
          recipe: recipe,
          contentWidth: contentWidth,
          bodyStartY: bodyStartY,
          bodyHeight: bodyHeight,
          primaryColor: primaryColor,
          accentColor: accentColor,
          marginX: marginX,
        );
        layers.add(bentoLayer);
        break;

      case LayoutStyle.featureGrid:
        final gridLayer = _buildFeatureGridSection(
          recipe: recipe,
          contentWidth: contentWidth,
          bodyStartY: bodyStartY,
          bodyHeight: bodyHeight,
          primaryColor: primaryColor,
          accentColor: accentColor,
          marginX: marginX,
        );
        layers.add(gridLayer);
        break;

      case LayoutStyle.statisticFocus:
        final statLayer = _buildStatisticFocusSection(
          recipe: recipe,
          contentWidth: contentWidth,
          bodyStartY: bodyStartY,
          bodyHeight: bodyHeight,
          primaryColor: primaryColor,
          accentColor: accentColor,
          marginX: marginX,
        );
        layers.add(statLayer);
        break;

      case LayoutStyle.centeredMinimal:
        final minimalLayer = _buildCenteredMinimalSection(
          recipe: recipe,
          contentWidth: contentWidth,
          bodyStartY: bodyStartY,
          bodyHeight: bodyHeight,
          primaryColor: primaryColor,
          accentColor: accentColor,
          marginX: marginX,
        );
        layers.add(minimalLayer);
        break;

      case LayoutStyle.heroCards:
        final cardsLayer = _buildHeroCardsSection(
          recipe: recipe,
          contentWidth: contentWidth,
          bodyStartY: bodyStartY,
          bodyHeight: bodyHeight,
          primaryColor: primaryColor,
          accentColor: accentColor,
          marginX: marginX,
        );
        layers.add(cardsLayer);
        break;
    }

    // 6. Footer Section
    final footerLayer = _buildFooterSection(
      recipe: recipe,
      contentWidth: contentWidth,
      marginX: marginX,
      y: height - marginY - 44,
      primaryColor: primaryColor,
    );
    layers.add(footerLayer);

    return CanvasPage(
      id: UuidGenerator.generate(),
      name: '${recipe.domain.name.toUpperCase()} ${recipe.aspectRatio} Design',
      width: width,
      height: height,
      backgroundType: BackgroundType.gradient,
      backgroundColor: gradColors.first,
      backgroundGradient: pageGradient,
      layers: layers,
      horizontalPadding: horizontalPadding,
      verticalPadding: verticalPadding,
    );
  }

  // --- Layout Section Builders ---

  static AutoLayoutLayer _buildHeaderSection({
    required DesignRecipe recipe,
    required double contentWidth,
    required double marginX,
    required double marginY,
    required Color primaryColor,
    required bool isCentered,
  }) {
    final List<Layer> headerChildren = [];

    // Badge Pill
    if (recipe.badgeText.isNotEmpty) {
      final badgePill = AutoLayoutLayer(
        id: UuidGenerator.generate(),
        name: 'Badge Pill',
        x: 0,
        y: 0,
        width: 240,
        height: 36,
        direction: AutoLayoutDirection.horizontal,
        horizontalSizing: AutoLayoutSizingMode.hug,
        verticalSizing: AutoLayoutSizingMode.hug,
        gap: 8,
        paddingHorizontal: 14,
        paddingVertical: 7,
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
            width: 15,
            height: 15,
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
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            fontFamily: recipe.headingFont,
            color: primaryColor,
          ),
        ],
      );
      headerChildren.add(badgePill);
    }

    // Hero Title (Fixed sizing enables softWrap: true)
    final titleLayer = TextLayer(
      id: UuidGenerator.generate(),
      name: 'Hero Title',
      x: 0,
      y: 0,
      width: contentWidth,
      height: 115,
      horizontalSizing: AutoLayoutSizingMode.fixed,
      content: recipe.title,
      fontSize: 42,
      fontWeight: FontWeight.w900,
      fontFamily: recipe.headingFont,
      lineHeight: 1.16,
      letterSpacing: -0.6,
      textAlign: isCentered ? TextAlign.center : TextAlign.left,
      color: Colors.white,
      shadows: [
        Shadow(
          color: Colors.black.withValues(alpha: 0.5),
          offset: const Offset(0, 4),
          blurRadius: 14,
        ),
      ],
    );
    headerChildren.add(titleLayer);

    // Subtitle (Fixed sizing enables softWrap: true)
    final subtitleLayer = TextLayer(
      id: UuidGenerator.generate(),
      name: 'Subtitle',
      x: 0,
      y: 0,
      width: contentWidth,
      height: 52,
      horizontalSizing: AutoLayoutSizingMode.fixed,
      content: recipe.subtitle,
      fontSize: 17,
      fontWeight: FontWeight.w400,
      fontFamily: recipe.bodyFont,
      lineHeight: 1.38,
      textAlign: isCentered ? TextAlign.center : TextAlign.left,
      color: Colors.white.withValues(alpha: 0.78),
    );
    headerChildren.add(subtitleLayer);

    return AutoLayoutLayer(
      id: UuidGenerator.generate(),
      name: 'Header Section',
      x: marginX,
      y: marginY,
      width: contentWidth,
      height: 220,
      direction: AutoLayoutDirection.vertical,
      horizontalSizing: AutoLayoutSizingMode.fixed,
      verticalSizing: AutoLayoutSizingMode.hug,
      gap: 12,
      paddingHorizontal: 0,
      paddingVertical: 0,
      alignment: isCentered ? AutoLayoutAlignment.center : AutoLayoutAlignment.start,
      distribution: AutoLayoutDistribution.start,
      children: headerChildren,
    );
  }

  /// 1. Asymmetric Modern Bento Grid (1 Hero Bento card + 2 Companion Bento cards)
  static AutoLayoutLayer _buildSplitBentoSection({
    required DesignRecipe recipe,
    required double contentWidth,
    required double bodyStartY,
    required double bodyHeight,
    required Color primaryColor,
    required Color accentColor,
    required double marginX,
  }) {
    final features = recipe.features.isNotEmpty
        ? recipe.features
        : [
            const RecipeFeatureItem(title: 'Feature High', subtitle: 'Desc', value: '99%'),
            const RecipeFeatureItem(title: 'Companion 1', subtitle: 'Desc', value: '4ms'),
            const RecipeFeatureItem(title: 'Companion 2', subtitle: 'Desc', value: '24/7'),
          ];

    final heroFeature = features.firstWhere(
      (f) => f.isHeroTile,
      orElse: () => features.first,
    );
    final companionFeatures = features.where((f) => f != heroFeature).take(2).toList();
    if (companionFeatures.isEmpty && features.length > 1) {
      companionFeatures.add(features[1]);
    }

    final double heroHeight = 140.0;
    final heroCard = _buildBentoHeroCard(
      feature: heroFeature,
      width: contentWidth,
      height: heroHeight,
      primaryColor: primaryColor,
      accentColor: accentColor,
      headingFont: recipe.headingFont,
      bodyFont: recipe.bodyFont,
    );

    // Companion Row
    final double gap = 16.0;
    final double companionWidth = (contentWidth - gap) / 2;
    final double companionHeight = 120.0;
    final List<Layer> companionCards = [];

    for (int i = 0; i < companionFeatures.length; i++) {
      final f = companionFeatures[i];
      companionCards.add(
        _buildBentoTileCard(
          feature: f,
          width: companionWidth,
          height: companionHeight,
          accentColor: i == 0 ? accentColor : primaryColor,
          headingFont: recipe.headingFont,
          bodyFont: recipe.bodyFont,
        ),
      );
    }

    final companionRow = AutoLayoutLayer(
      id: UuidGenerator.generate(),
      name: 'Bento Companion Row',
      x: 0,
      y: 0,
      width: contentWidth,
      height: companionHeight,
      direction: AutoLayoutDirection.horizontal,
      horizontalSizing: AutoLayoutSizingMode.fixed,
      verticalSizing: AutoLayoutSizingMode.fixed,
      gap: gap,
      paddingHorizontal: 0,
      paddingVertical: 0,
      alignment: AutoLayoutAlignment.center,
      distribution: AutoLayoutDistribution.spaceBetween,
      children: companionCards,
    );

    return AutoLayoutLayer(
      id: UuidGenerator.generate(),
      name: 'Bento Grid Section',
      x: marginX,
      y: bodyStartY,
      width: contentWidth,
      height: heroHeight + gap + companionHeight,
      direction: AutoLayoutDirection.vertical,
      horizontalSizing: AutoLayoutSizingMode.fixed,
      verticalSizing: AutoLayoutSizingMode.hug,
      gap: gap,
      paddingHorizontal: 0,
      paddingVertical: 0,
      alignment: AutoLayoutAlignment.center,
      distribution: AutoLayoutDistribution.start,
      children: [heroCard, companionRow],
    );
  }

  /// 2. 2x2 Symmetrical Feature Grid
  static AutoLayoutLayer _buildFeatureGridSection({
    required DesignRecipe recipe,
    required double contentWidth,
    required double bodyStartY,
    required double bodyHeight,
    required Color primaryColor,
    required Color accentColor,
    required double marginX,
  }) {
    final features = List<RecipeFeatureItem>.from(recipe.features);
    while (features.length < 4) {
      features.add(RecipeFeatureItem(
        title: 'Feature ${features.length + 1}',
        subtitle: 'High precision capability',
        value: '100%',
        iconName: 'check_circle',
      ));
    }

    final double gap = 16.0;
    final double cardWidth = (contentWidth - gap) / 2;
    final double cardHeight = 115.0;

    final row1Cards = [
      _buildBentoTileCard(
        feature: features[0],
        width: cardWidth,
        height: cardHeight,
        accentColor: primaryColor,
        headingFont: recipe.headingFont,
        bodyFont: recipe.bodyFont,
      ),
      _buildBentoTileCard(
        feature: features[1],
        width: cardWidth,
        height: cardHeight,
        accentColor: accentColor,
        headingFont: recipe.headingFont,
        bodyFont: recipe.bodyFont,
      ),
    ];

    final row2Cards = [
      _buildBentoTileCard(
        feature: features[2],
        width: cardWidth,
        height: cardHeight,
        accentColor: accentColor,
        headingFont: recipe.headingFont,
        bodyFont: recipe.bodyFont,
      ),
      _buildBentoTileCard(
        feature: features[3],
        width: cardWidth,
        height: cardHeight,
        accentColor: primaryColor,
        headingFont: recipe.headingFont,
        bodyFont: recipe.bodyFont,
      ),
    ];

    final row1 = AutoLayoutLayer(
      id: UuidGenerator.generate(),
      name: 'Grid Row 1',
      x: 0,
      y: 0,
      width: contentWidth,
      height: cardHeight,
      direction: AutoLayoutDirection.horizontal,
      horizontalSizing: AutoLayoutSizingMode.fixed,
      verticalSizing: AutoLayoutSizingMode.fixed,
      gap: gap,
      paddingHorizontal: 0,
      paddingVertical: 0,
      alignment: AutoLayoutAlignment.center,
      distribution: AutoLayoutDistribution.spaceBetween,
      children: row1Cards,
    );

    final row2 = AutoLayoutLayer(
      id: UuidGenerator.generate(),
      name: 'Grid Row 2',
      x: 0,
      y: 0,
      width: contentWidth,
      height: cardHeight,
      direction: AutoLayoutDirection.horizontal,
      horizontalSizing: AutoLayoutSizingMode.fixed,
      verticalSizing: AutoLayoutSizingMode.fixed,
      gap: gap,
      paddingHorizontal: 0,
      paddingVertical: 0,
      alignment: AutoLayoutAlignment.center,
      distribution: AutoLayoutDistribution.spaceBetween,
      children: row2Cards,
    );

    return AutoLayoutLayer(
      id: UuidGenerator.generate(),
      name: '2x2 Grid Section',
      x: marginX,
      y: bodyStartY,
      width: contentWidth,
      height: (cardHeight * 2) + gap,
      direction: AutoLayoutDirection.vertical,
      horizontalSizing: AutoLayoutSizingMode.fixed,
      verticalSizing: AutoLayoutSizingMode.hug,
      gap: gap,
      paddingHorizontal: 0,
      paddingVertical: 0,
      alignment: AutoLayoutAlignment.center,
      distribution: AutoLayoutDistribution.start,
      children: [row1, row2],
    );
  }

  /// 3. Statistic / KPI Heavy Focus Layout
  static AutoLayoutLayer _buildStatisticFocusSection({
    required DesignRecipe recipe,
    required double contentWidth,
    required double bodyStartY,
    required double bodyHeight,
    required Color primaryColor,
    required Color accentColor,
    required double marginX,
  }) {
    final features = recipe.features.isNotEmpty
        ? recipe.features
        : [
            const RecipeFeatureItem(title: 'Global Uptime', subtitle: 'Continuous enterprise SLA', value: '99.99%', trend: '+0.4%'),
            const RecipeFeatureItem(title: 'Network Speed', subtitle: 'Edge processing', value: '< 2ms', trend: '▲ 4x faster'),
          ];

    final primaryStat = features.first;
    final secondaryStats = features.skip(1).take(2).toList();

    // Prominent Primary Stat Banner
    final primaryBanner = AutoLayoutLayer(
      id: UuidGenerator.generate(),
      name: 'Primary KPI Banner',
      x: 0,
      y: 0,
      width: contentWidth,
      height: 135,
      direction: AutoLayoutDirection.horizontal,
      horizontalSizing: AutoLayoutSizingMode.fixed,
      verticalSizing: AutoLayoutSizingMode.fixed,
      gap: 20,
      paddingHorizontal: 24,
      paddingVertical: 18,
      alignment: AutoLayoutAlignment.center,
      distribution: AutoLayoutDistribution.spaceBetween,
      backgroundColor: const Color(0xFF131722).withValues(alpha: 0.82),
      cornerRadius: 20,
      strokeColor: primaryColor.withValues(alpha: 0.60),
      strokeWidth: 1.5,
      children: [
        // Left Column: Title & Subtitle
        AutoLayoutLayer(
          id: UuidGenerator.generate(),
          name: 'Banner Info',
          x: 0,
          y: 0,
          width: contentWidth * 0.50,
          height: 85,
          direction: AutoLayoutDirection.vertical,
          horizontalSizing: AutoLayoutSizingMode.hug,
          verticalSizing: AutoLayoutSizingMode.hug,
          gap: 6,
          paddingHorizontal: 0,
          paddingVertical: 0,
          alignment: AutoLayoutAlignment.start,
          distribution: AutoLayoutDistribution.center,
          children: [
            if (primaryStat.tag != null)
              AutoLayoutLayer(
                id: UuidGenerator.generate(),
                name: 'KPI Tag Chip',
                x: 0,
                y: 0,
                width: 80,
                height: 20,
                direction: AutoLayoutDirection.horizontal,
                horizontalSizing: AutoLayoutSizingMode.hug,
                verticalSizing: AutoLayoutSizingMode.hug,
                paddingHorizontal: 8,
                paddingVertical: 3,
                backgroundColor: primaryColor.withValues(alpha: 0.2),
                cornerRadius: 6,
                children: [
                  TextLayer(
                    id: UuidGenerator.generate(),
                    name: 'Tag Text',
                    x: 0,
                    y: 0,
                    width: 70,
                    height: 14,
                    horizontalSizing: AutoLayoutSizingMode.hug,
                    content: primaryStat.tag!,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                  ),
                ],
              ),
            TextLayer(
              id: UuidGenerator.generate(),
              name: 'KPI Title',
              x: 0,
              y: 0,
              width: contentWidth * 0.50,
              height: 26,
              horizontalSizing: AutoLayoutSizingMode.hug,
              content: primaryStat.title,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              fontFamily: recipe.headingFont,
              color: Colors.white,
            ),
            if (primaryStat.subtitle != null)
              TextLayer(
                id: UuidGenerator.generate(),
                name: 'KPI Subtitle',
                x: 0,
                y: 0,
                width: contentWidth * 0.50,
                height: 18,
                horizontalSizing: AutoLayoutSizingMode.hug,
                content: primaryStat.subtitle!,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                fontFamily: recipe.bodyFont,
                color: Colors.white70,
              ),
          ],
        ),
        // Right Column: Giant Stat Number + Trend Pill
        AutoLayoutLayer(
          id: UuidGenerator.generate(),
          name: 'Stat Metric Block',
          x: 0,
          y: 0,
          width: contentWidth * 0.35,
          height: 85,
          direction: AutoLayoutDirection.vertical,
          horizontalSizing: AutoLayoutSizingMode.hug,
          verticalSizing: AutoLayoutSizingMode.hug,
          gap: 4,
          alignment: AutoLayoutAlignment.end,
          distribution: AutoLayoutDistribution.center,
          paddingHorizontal: 0,
          paddingVertical: 0,
          children: [
            TextLayer(
              id: UuidGenerator.generate(),
              name: 'Giant Number',
              x: 0,
              y: 0,
              width: 160,
              height: 48,
              horizontalSizing: AutoLayoutSizingMode.hug,
              content: primaryStat.value ?? '100%',
              fontSize: 44,
              fontWeight: FontWeight.w900,
              fontFamily: recipe.headingFont,
              textAlign: TextAlign.right,
              color: primaryColor,
            ),
            if (primaryStat.trend != null)
              AutoLayoutLayer(
                id: UuidGenerator.generate(),
                name: 'Trend Chip',
                x: 0,
                y: 0,
                width: 100,
                height: 24,
                direction: AutoLayoutDirection.horizontal,
                horizontalSizing: AutoLayoutSizingMode.hug,
                verticalSizing: AutoLayoutSizingMode.hug,
                gap: 4,
                paddingHorizontal: 8,
                paddingVertical: 3,
                alignment: AutoLayoutAlignment.center,
                distribution: AutoLayoutDistribution.center,
                backgroundColor: accentColor.withValues(alpha: 0.18),
                cornerRadius: 8,
                children: [
                  IconLayer(
                    id: UuidGenerator.generate(),
                    name: 'Trend Icon',
                    x: 0,
                    y: 0,
                    width: 12,
                    height: 12,
                    icon: Icons.trending_up_rounded,
                    color: accentColor,
                  ),
                  TextLayer(
                    id: UuidGenerator.generate(),
                    name: 'Trend Value',
                    x: 0,
                    y: 0,
                    width: 70,
                    height: 16,
                    horizontalSizing: AutoLayoutSizingMode.hug,
                    content: primaryStat.trend!,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ],
              ),
          ],
        ),
      ],
    );

    // Secondary Stat Row
    final double gap = 16.0;
    final double secWidth = (contentWidth - gap) / 2;
    final List<Layer> secondaryCards = [];

    for (final sec in secondaryStats) {
      secondaryCards.add(
        _buildBentoTileCard(
          feature: sec,
          width: secWidth,
          height: 115,
          accentColor: accentColor,
          headingFont: recipe.headingFont,
          bodyFont: recipe.bodyFont,
        ),
      );
    }

    final secRow = AutoLayoutLayer(
      id: UuidGenerator.generate(),
      name: 'Secondary Stats Row',
      x: 0,
      y: 0,
      width: contentWidth,
      height: 115,
      direction: AutoLayoutDirection.horizontal,
      horizontalSizing: AutoLayoutSizingMode.fixed,
      verticalSizing: AutoLayoutSizingMode.fixed,
      gap: gap,
      paddingHorizontal: 0,
      paddingVertical: 0,
      alignment: AutoLayoutAlignment.center,
      distribution: AutoLayoutDistribution.spaceBetween,
      children: secondaryCards,
    );

    return AutoLayoutLayer(
      id: UuidGenerator.generate(),
      name: 'Statistic Focus Section',
      x: marginX,
      y: bodyStartY,
      width: contentWidth,
      height: 135 + gap + 115,
      direction: AutoLayoutDirection.vertical,
      horizontalSizing: AutoLayoutSizingMode.fixed,
      verticalSizing: AutoLayoutSizingMode.hug,
      gap: gap,
      paddingHorizontal: 0,
      paddingVertical: 0,
      alignment: AutoLayoutAlignment.center,
      distribution: AutoLayoutDistribution.start,
      children: [primaryBanner, if (secondaryCards.isNotEmpty) secRow],
    );
  }

  /// 4. Symmetrical Centered Minimalist Layout
  static AutoLayoutLayer _buildCenteredMinimalSection({
    required DesignRecipe recipe,
    required double contentWidth,
    required double bodyStartY,
    required double bodyHeight,
    required Color primaryColor,
    required Color accentColor,
    required double marginX,
  }) {
    final List<Layer> items = [];

    // Subtle divider line
    items.add(
      ShapeLayer(
        id: UuidGenerator.generate(),
        name: 'Minimal Divider',
        x: 0,
        y: 0,
        width: contentWidth * 0.7,
        height: 1.5,
        shapeType: ShapeType.rectangle,
        fill: Colors.white.withValues(alpha: 0.15),
      ),
    );

    // Centered feature pills
    for (final f in recipe.features.take(3)) {
      items.add(
        AutoLayoutLayer(
          id: UuidGenerator.generate(),
          name: 'Minimal Item: ${f.title}',
          x: 0,
          y: 0,
          width: contentWidth * 0.85,
          height: 52,
          direction: AutoLayoutDirection.horizontal,
          horizontalSizing: AutoLayoutSizingMode.fixed,
          verticalSizing: AutoLayoutSizingMode.fixed,
          gap: 14,
          paddingHorizontal: 16,
          paddingVertical: 8,
          alignment: AutoLayoutAlignment.center,
          distribution: AutoLayoutDistribution.spaceBetween,
          backgroundColor: Colors.white.withValues(alpha: 0.04),
          cornerRadius: 12,
          strokeColor: Colors.white.withValues(alpha: 0.08),
          strokeWidth: 1,
          children: [
            AutoLayoutLayer(
              id: UuidGenerator.generate(),
              name: 'Minimal Item Left',
              x: 0,
              y: 0,
              width: contentWidth * 0.55,
              height: 36,
              direction: AutoLayoutDirection.horizontal,
              horizontalSizing: AutoLayoutSizingMode.hug,
              verticalSizing: AutoLayoutSizingMode.hug,
              gap: 10,
              paddingHorizontal: 0,
              paddingVertical: 0,
              alignment: AutoLayoutAlignment.center,
              distribution: AutoLayoutDistribution.start,
              children: [
                IconLayer(
                  id: UuidGenerator.generate(),
                  name: 'Icon',
                  x: 0,
                  y: 0,
                  width: 18,
                  height: 18,
                  icon: _resolveIcon(f.iconName),
                  color: primaryColor,
                ),
                TextLayer(
                  id: UuidGenerator.generate(),
                  name: 'Title',
                  x: 0,
                  y: 0,
                  width: 220,
                  height: 20,
                  horizontalSizing: AutoLayoutSizingMode.hug,
                  content: f.title,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ],
            ),
            if (f.value != null)
              TextLayer(
                id: UuidGenerator.generate(),
                name: 'Value',
                x: 0,
                y: 0,
                width: 80,
                height: 20,
                horizontalSizing: AutoLayoutSizingMode.hug,
                content: f.value!,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: accentColor,
              ),
          ],
        ),
      );
    }

    return AutoLayoutLayer(
      id: UuidGenerator.generate(),
      name: 'Centered Minimal Section',
      x: marginX,
      y: bodyStartY,
      width: contentWidth,
      height: 220,
      direction: AutoLayoutDirection.vertical,
      horizontalSizing: AutoLayoutSizingMode.fixed,
      verticalSizing: AutoLayoutSizingMode.hug,
      gap: 14,
      paddingHorizontal: 0,
      paddingVertical: 0,
      alignment: AutoLayoutAlignment.center,
      distribution: AutoLayoutDistribution.center,
      children: items,
    );
  }

  /// 5. Classic Full-Width Hero Cards Section
  static AutoLayoutLayer _buildHeroCardsSection({
    required DesignRecipe recipe,
    required double contentWidth,
    required double bodyStartY,
    required double bodyHeight,
    required Color primaryColor,
    required Color accentColor,
    required double marginX,
  }) {
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
                    fontFamily: recipe.headingFont,
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
                      fontFamily: recipe.bodyFont,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                ],
              ),
            ],
          ),
          // Right: Value Pill
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
                  fontFamily: recipe.headingFont,
                  textAlign: TextAlign.center,
                  color: isAccent ? primaryColor : accentColor,
                ),
              ],
            ),
        ],
      );
      featureCards.add(card);
    }

    return AutoLayoutLayer(
      id: UuidGenerator.generate(),
      name: 'Features Group',
      x: marginX,
      y: bodyStartY,
      width: contentWidth,
      height: bodyHeight,
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
  }

  // --- Sub-Card Helpers ---

  static AutoLayoutLayer _buildBentoHeroCard({
    required RecipeFeatureItem feature,
    required double width,
    required double height,
    required Color primaryColor,
    required Color accentColor,
    required String headingFont,
    required String bodyFont,
  }) {
    return AutoLayoutLayer(
      id: UuidGenerator.generate(),
      name: 'Bento Hero Tile: ${feature.title}',
      x: 0,
      y: 0,
      width: width,
      height: height,
      direction: AutoLayoutDirection.horizontal,
      horizontalSizing: AutoLayoutSizingMode.fixed,
      verticalSizing: AutoLayoutSizingMode.fixed,
      gap: 20,
      paddingHorizontal: 22,
      paddingVertical: 18,
      alignment: AutoLayoutAlignment.center,
      distribution: AutoLayoutDistribution.spaceBetween,
      backgroundColor: const Color(0xFF131722).withValues(alpha: 0.84),
      cornerRadius: 20,
      strokeColor: primaryColor.withValues(alpha: 0.55),
      strokeWidth: 1.4,
      children: [
        // Left info
        AutoLayoutLayer(
          id: UuidGenerator.generate(),
          name: 'Hero Tile Left',
          x: 0,
          y: 0,
          width: width * 0.6,
          height: 90,
          direction: AutoLayoutDirection.vertical,
          horizontalSizing: AutoLayoutSizingMode.hug,
          verticalSizing: AutoLayoutSizingMode.hug,
          gap: 6,
          paddingHorizontal: 0,
          paddingVertical: 0,
          alignment: AutoLayoutAlignment.start,
          distribution: AutoLayoutDistribution.center,
          children: [
            AutoLayoutLayer(
              id: UuidGenerator.generate(),
              name: 'Hero Tag Row',
              x: 0,
              y: 0,
              width: width * 0.5,
              height: 28,
              direction: AutoLayoutDirection.horizontal,
              horizontalSizing: AutoLayoutSizingMode.hug,
              verticalSizing: AutoLayoutSizingMode.hug,
              gap: 8,
              alignment: AutoLayoutAlignment.center,
              distribution: AutoLayoutDistribution.start,
              paddingHorizontal: 0,
              paddingVertical: 0,
              children: [
                AutoLayoutLayer(
                  id: UuidGenerator.generate(),
                  name: 'Hero Icon Box',
                  x: 0,
                  y: 0,
                  width: 32,
                  height: 32,
                  direction: AutoLayoutDirection.horizontal,
                  horizontalSizing: AutoLayoutSizingMode.fixed,
                  verticalSizing: AutoLayoutSizingMode.fixed,
                  paddingHorizontal: 7,
                  paddingVertical: 7,
                  alignment: AutoLayoutAlignment.center,
                  distribution: AutoLayoutDistribution.center,
                  backgroundColor: primaryColor.withValues(alpha: 0.2),
                  cornerRadius: 10,
                  children: [
                    IconLayer(
                      id: UuidGenerator.generate(),
                      name: 'Icon',
                      x: 0,
                      y: 0,
                      width: 18,
                      height: 18,
                      icon: _resolveIcon(feature.iconName),
                      color: primaryColor,
                    ),
                  ],
                ),
                if (feature.tag != null)
                  AutoLayoutLayer(
                    id: UuidGenerator.generate(),
                    name: 'Hero Tag',
                    x: 0,
                    y: 0,
                    width: 70,
                    height: 20,
                    direction: AutoLayoutDirection.horizontal,
                    horizontalSizing: AutoLayoutSizingMode.hug,
                    verticalSizing: AutoLayoutSizingMode.hug,
                    paddingHorizontal: 7,
                    paddingVertical: 3,
                    backgroundColor: accentColor.withValues(alpha: 0.18),
                    cornerRadius: 6,
                    children: [
                      TextLayer(
                        id: UuidGenerator.generate(),
                        name: 'Tag Text',
                        x: 0,
                        y: 0,
                        width: 60,
                        height: 14,
                        horizontalSizing: AutoLayoutSizingMode.hug,
                        content: feature.tag!,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                      ),
                    ],
                  ),
              ],
            ),
            TextLayer(
              id: UuidGenerator.generate(),
              name: 'Hero Title',
              x: 0,
              y: 0,
              width: width * 0.6,
              height: 24,
              horizontalSizing: AutoLayoutSizingMode.hug,
              content: feature.title,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              fontFamily: headingFont,
              color: Colors.white,
            ),
            if (feature.subtitle != null)
              TextLayer(
                id: UuidGenerator.generate(),
                name: 'Hero Subtitle',
                x: 0,
                y: 0,
                width: width * 0.6,
                height: 18,
                horizontalSizing: AutoLayoutSizingMode.hug,
                content: feature.subtitle!,
                fontSize: 13,
                fontFamily: bodyFont,
                color: Colors.white70,
              ),
          ],
        ),
        // Right Stat
        if (feature.value != null)
          AutoLayoutLayer(
            id: UuidGenerator.generate(),
            name: 'Hero Stat Box',
            x: 0,
            y: 0,
            width: width * 0.32,
            height: 90,
            direction: AutoLayoutDirection.vertical,
            horizontalSizing: AutoLayoutSizingMode.hug,
            verticalSizing: AutoLayoutSizingMode.hug,
            gap: 4,
            paddingHorizontal: 0,
            paddingVertical: 0,
            alignment: AutoLayoutAlignment.end,
            distribution: AutoLayoutDistribution.center,
            children: [
              TextLayer(
                id: UuidGenerator.generate(),
                name: 'Hero Metric',
                x: 0,
                y: 0,
                width: 140,
                height: 38,
                horizontalSizing: AutoLayoutSizingMode.hug,
                content: feature.value!,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                fontFamily: headingFont,
                textAlign: TextAlign.right,
                color: primaryColor,
              ),
              if (feature.trend != null)
                TextLayer(
                  id: UuidGenerator.generate(),
                  name: 'Hero Trend',
                  x: 0,
                  y: 0,
                  width: 100,
                  height: 16,
                  horizontalSizing: AutoLayoutSizingMode.hug,
                  content: feature.trend!,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  textAlign: TextAlign.right,
                  color: accentColor,
                ),
            ],
          ),
      ],
    );
  }

  static AutoLayoutLayer _buildBentoTileCard({
    required RecipeFeatureItem feature,
    required double width,
    required double height,
    required Color accentColor,
    required String headingFont,
    required String bodyFont,
  }) {
    return AutoLayoutLayer(
      id: UuidGenerator.generate(),
      name: 'Tile: ${feature.title}',
      x: 0,
      y: 0,
      width: width,
      height: height,
      direction: AutoLayoutDirection.vertical,
      horizontalSizing: AutoLayoutSizingMode.fixed,
      verticalSizing: AutoLayoutSizingMode.fixed,
      gap: 8,
      paddingHorizontal: 18,
      paddingVertical: 14,
      alignment: AutoLayoutAlignment.start,
      distribution: AutoLayoutDistribution.spaceBetween,
      backgroundColor: const Color(0xFF131722).withValues(alpha: 0.76),
      cornerRadius: 18,
      strokeColor: Colors.white.withValues(alpha: 0.12),
      strokeWidth: 1.2,
      children: [
        // Top Header: Icon + Value
        AutoLayoutLayer(
          id: UuidGenerator.generate(),
          name: 'Tile Top Row',
          x: 0,
          y: 0,
          width: width - 36,
          height: 32,
          direction: AutoLayoutDirection.horizontal,
          horizontalSizing: AutoLayoutSizingMode.fixed,
          verticalSizing: AutoLayoutSizingMode.fixed,
          alignment: AutoLayoutAlignment.center,
          distribution: AutoLayoutDistribution.spaceBetween,
          paddingHorizontal: 0,
          paddingVertical: 0,
          children: [
            AutoLayoutLayer(
              id: UuidGenerator.generate(),
              name: 'Tile Icon Box',
              x: 0,
              y: 0,
              width: 28,
              height: 28,
              direction: AutoLayoutDirection.horizontal,
              horizontalSizing: AutoLayoutSizingMode.fixed,
              verticalSizing: AutoLayoutSizingMode.fixed,
              paddingHorizontal: 6,
              paddingVertical: 6,
              alignment: AutoLayoutAlignment.center,
              distribution: AutoLayoutDistribution.center,
              backgroundColor: accentColor.withValues(alpha: 0.18),
              cornerRadius: 8,
              children: [
                IconLayer(
                  id: UuidGenerator.generate(),
                  name: 'Tile Icon',
                  x: 0,
                  y: 0,
                  width: 16,
                  height: 16,
                  icon: _resolveIcon(feature.iconName),
                  color: accentColor,
                ),
              ],
            ),
            if (feature.value != null)
              TextLayer(
                id: UuidGenerator.generate(),
                name: 'Tile Value',
                x: 0,
                y: 0,
                width: 80,
                height: 22,
                horizontalSizing: AutoLayoutSizingMode.hug,
                content: feature.value!,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                fontFamily: headingFont,
                color: accentColor,
              ),
          ],
        ),
        // Bottom Text Block
        AutoLayoutLayer(
          id: UuidGenerator.generate(),
          name: 'Tile Text Block',
          x: 0,
          y: 0,
          width: width - 36,
          height: 44,
          direction: AutoLayoutDirection.vertical,
          horizontalSizing: AutoLayoutSizingMode.fixed,
          verticalSizing: AutoLayoutSizingMode.hug,
          gap: 2,
          alignment: AutoLayoutAlignment.start,
          distribution: AutoLayoutDistribution.center,
          paddingHorizontal: 0,
          paddingVertical: 0,
          children: [
            TextLayer(
              id: UuidGenerator.generate(),
              name: 'Tile Title',
              x: 0,
              y: 0,
              width: width - 36,
              height: 20,
              horizontalSizing: AutoLayoutSizingMode.fixed,
              content: feature.title,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFamily: headingFont,
              color: Colors.white,
            ),
            if (feature.subtitle != null)
              TextLayer(
                id: UuidGenerator.generate(),
                name: 'Tile Subtitle',
                x: 0,
                y: 0,
                width: width - 36,
                height: 16,
                horizontalSizing: AutoLayoutSizingMode.fixed,
                content: feature.subtitle!,
                fontSize: 12,
                fontFamily: bodyFont,
                color: Colors.white60,
              ),
          ],
        ),
      ],
    );
  }

  static AutoLayoutLayer _buildFooterSection({
    required DesignRecipe recipe,
    required double contentWidth,
    required double marginX,
    required double y,
    required Color primaryColor,
  }) {
    final footerText = recipe.footerText ?? 'Layerly Studio • Generated by AI';
    return AutoLayoutLayer(
      id: UuidGenerator.generate(),
      name: 'Footer Bar',
      x: marginX,
      y: y,
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
          width: contentWidth * 0.58,
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
  }

  // --- Helpers ---
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
      case 'trending_up':
        return Icons.trending_up_rounded;
      case 'check_circle':
      default:
        return Icons.check_circle_rounded;
    }
  }
}
