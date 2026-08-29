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

    final isAppRequest = lower.contains('app') ||
        lower.contains('mobile') ||
        lower.contains('ui ux') ||
        lower.contains('ui/ux') ||
        lower.contains('screen') ||
        lower.contains('ios') ||
        lower.contains('iphone') ||
        lower.contains('uber') ||
        lower.contains('lyft');

    // 1. Aspect Ratio Detection
    String aspectRatio = isAppRequest ? '9:16' : '1:1';
    if (lower.contains('4:5') || lower.contains('portrait')) {
      aspectRatio = '4:5';
    } else if (lower.contains('9:16') || lower.contains('story') || lower.contains('reel') || isAppRequest) {
      aspectRatio = '9:16';
    } else if (lower.contains('16:9') || lower.contains('landscape') || lower.contains('banner')) {
      aspectRatio = '16:9';
    }

    // 2. Layout Style Archetype Detection
    LayoutStyle layoutStyle = isAppRequest ? LayoutStyle.mobileAppScreen : LayoutStyle.heroCards;
    if (!isAppRequest) {
      if (lower.contains('bento')) {
        layoutStyle = LayoutStyle.splitBento;
      } else if (lower.contains('grid') || lower.contains('2x2') || lower.contains('four')) {
        layoutStyle = LayoutStyle.featureGrid;
      } else if (lower.contains('stat') || lower.contains('metric') || lower.contains('kpi') || lower.contains('number') || lower.contains('dashboard')) {
        layoutStyle = LayoutStyle.statisticFocus;
      } else if (lower.contains('minimal') || lower.contains('editorial') || lower.contains('luxury') || lower.contains('simple')) {
        layoutStyle = LayoutStyle.centeredMinimal;
      }
    }

    // 3. Domain Detection
    DesignDomain domain = DesignDomain.creative;
    if (lower.contains('uber') || lower.contains('ride') || lower.contains('taxi') || lower.contains('cab') || lower.contains('transit')) {
      domain = DesignDomain.mobility;
    } else if (lower.contains('food') || lower.contains('eats') || lower.contains('restaurant') || lower.contains('grocery') || lower.contains('delivery')) {
      domain = DesignDomain.ecommerce;
    } else if (lower.contains('bank') || lower.contains('crypto') || lower.contains('wallet') || lower.contains('fintech') || lower.contains('pay')) {
      domain = DesignDomain.fintech;
    } else if (lower.contains('pharma') || lower.contains('medicine') || lower.contains('drug') || lower.contains('clinical') || lower.contains('biotech') || lower.contains('health')) {
      domain = DesignDomain.pharma;
    } else if (lower.contains('saas') || lower.contains('software') || lower.contains('tech') || lower.contains('cloud') || lower.contains('api')) {
      domain = DesignDomain.saas;
    } else if (lower.contains('fitness') || lower.contains('gym') || lower.contains('workout') || lower.contains('training')) {
      domain = DesignDomain.fitness;
    } else if (lower.contains('finance') || lower.contains('invest')) {
      domain = DesignDomain.marketing;
    }

    if (domain == DesignDomain.mobility || (isAppRequest && lower.contains('uber'))) {
      return const DesignRecipe(
        title: 'Where to?',
        subtitle: 'San Francisco, CA • Choose a ride',
        badgeText: 'NOW',
        badgeIcon: 'directions_car',
        domain: DesignDomain.mobility,
        layoutStyle: LayoutStyle.mobileAppScreen,
        cardAesthetic: CardAesthetic.minimal,
        backgroundStyle: BackgroundStyle.darkStudio,
        headingFont: 'Inter',
        bodyFont: 'Inter',
        aspectRatio: '9:16',
        gradientColors: ['#000000', '#0D0D12', '#14141A'],
        primaryColor: '#FFFFFF',
        accentColor: '#10B981',
        features: [
          RecipeFeatureItem(
            title: 'UberX',
            subtitle: 'Affordable, everyday rides • 3 min away',
            value: '\$18.50',
            iconName: 'directions_car',
            isHeroTile: true,
            trend: '3 min',
            tag: 'POPULAR',
          ),
          RecipeFeatureItem(
            title: 'Comfort',
            subtitle: 'Newer cars with extra legroom • 5 min away',
            value: '\$24.20',
            iconName: 'car_rental',
            trend: '5 min',
            tag: 'EXTRA ROOM',
          ),
          RecipeFeatureItem(
            title: 'Black',
            subtitle: 'Premium rides with professional drivers • 8 min away',
            value: '\$38.00',
            iconName: 'workspace_premium',
            trend: '8 min',
            tag: 'PREMIUM',
          ),
          RecipeFeatureItem(
            title: 'UberXL',
            subtitle: 'Spacious rides for groups up to 6 • 6 min away',
            value: '\$29.50',
            iconName: 'airport_shuttle',
            trend: '6 min',
            tag: '6 SEATS',
          ),
        ],
        footerText: 'Home • Workplace • SFO Airport',
        ctaText: 'Choose UberX • \$18.50',
      );
    }

    if (isAppRequest && domain == DesignDomain.ecommerce) {
      return const DesignRecipe(
        title: 'Deliver to 124 Market St',
        subtitle: 'San Francisco • 15-25 min delivery',
        badgeText: 'FASTEST',
        badgeIcon: 'fastfood',
        domain: DesignDomain.ecommerce,
        layoutStyle: LayoutStyle.mobileAppScreen,
        cardAesthetic: CardAesthetic.minimal,
        backgroundStyle: BackgroundStyle.darkStudio,
        headingFont: 'Inter',
        bodyFont: 'Inter',
        aspectRatio: '9:16',
        gradientColors: ['#000000', '#0F0E14', '#161420'],
        primaryColor: '#FFFFFF',
        accentColor: '#10B981',
        features: [
          RecipeFeatureItem(
            title: 'Sweetgreen Greens Co.',
            subtitle: 'Warm bowls, fresh salads • 15-20 min',
            value: '4.9 ★',
            iconName: 'lunch_dining',
            isHeroTile: true,
            trend: '\$0 Delivery',
            tag: 'POPULAR',
          ),
          RecipeFeatureItem(
            title: 'Blue Bottle Coffee',
            subtitle: 'Single origin espresso & pastries • 10 min',
            value: '4.8 ★',
            iconName: 'local_cafe',
            trend: 'Fast',
          ),
          RecipeFeatureItem(
            title: 'Tartine Bakery',
            subtitle: 'Artisan sourdough & croissants • 25 min',
            value: '4.9 ★',
            iconName: 'bakery_dining',
            trend: 'Top Rated',
            tag: 'FEATURED',
          ),
        ],
        footerText: 'View Cart (2 items) • \$28.40',
        ctaText: 'Checkout • \$28.40',
      );
    }

    if (isAppRequest && domain == DesignDomain.fintech) {
      return const DesignRecipe(
        title: '\$24,850.40',
        subtitle: 'Total Balance • +12.4% this month',
        badgeText: 'CHECKING',
        badgeIcon: 'account_balance_wallet',
        domain: DesignDomain.fintech,
        layoutStyle: LayoutStyle.mobileAppScreen,
        cardAesthetic: CardAesthetic.minimal,
        backgroundStyle: BackgroundStyle.darkStudio,
        headingFont: 'Inter',
        bodyFont: 'Inter',
        aspectRatio: '9:16',
        gradientColors: ['#000000', '#0A0A10', '#12121A'],
        primaryColor: '#FFFFFF',
        accentColor: '#00D2B4',
        features: [
          RecipeFeatureItem(
            title: 'Apple Store Inc.',
            subtitle: 'Electronics & Subscriptions • Today 2:15 PM',
            value: '-\$199.00',
            iconName: 'laptop_mac',
            isHeroTile: true,
            tag: 'SHOPPING',
          ),
          RecipeFeatureItem(
            title: 'Payroll Direct Deposit',
            subtitle: 'Stripe Payments USA • Yesterday',
            value: '+\$4,850.00',
            iconName: 'payments',
            trend: 'Cleared',
            tag: 'INCOME',
          ),
          RecipeFeatureItem(
            title: 'Uber Technologies',
            subtitle: 'Ride Transport • Aug 27',
            value: '-\$24.50',
            iconName: 'directions_car',
            tag: 'RIDE',
          ),
        ],
        footerText: 'Account ending in •••• 4921',
        ctaText: 'Send Money',
      );
    }

    if (isAppRequest) {
      return DesignRecipe(
        title: 'App Dashboard',
        subtitle: 'Minimal, professional mobile experience',
        badgeText: 'MOBILE',
        badgeIcon: 'phone_iphone',
        domain: domain,
        layoutStyle: LayoutStyle.mobileAppScreen,
        cardAesthetic: CardAesthetic.minimal,
        backgroundStyle: BackgroundStyle.darkStudio,
        headingFont: 'Inter',
        bodyFont: 'Inter',
        aspectRatio: '9:16',
        gradientColors: const ['#000000', '#0D0C14', '#151420'],
        primaryColor: '#FFFFFF',
        accentColor: '#8B5CF6',
        features: const [
          RecipeFeatureItem(
            title: 'Primary Service',
            subtitle: 'Active session & real-time telemetry',
            value: '99.4%',
            iconName: 'check_circle',
            isHeroTile: true,
            tag: 'ACTIVE',
          ),
          RecipeFeatureItem(
            title: 'Quick Activity',
            subtitle: 'Instant synchronization with cloud',
            value: '< 10ms',
            iconName: 'bolt',
            trend: 'Fast',
          ),
          RecipeFeatureItem(
            title: 'Account Settings',
            subtitle: 'Manage profile, security & devices',
            value: 'Pro',
            iconName: 'security',
            tag: 'SECURE',
          ),
        ],
        footerText: 'Synced with Apple iCloud',
        ctaText: 'Get Started',
      );
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

    if (recipe.layoutStyle == LayoutStyle.mobileAppScreen) {
      final appLayers = _buildMobileAppScreenLayers(
        recipe: recipe,
        width: width,
        height: height,
        marginX: 44.0,
        contentWidth: width - 88.0,
        primaryColor: primaryColor,
        accentColor: accentColor,
      );
      layers.addAll(appLayers);
    } else {
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

        case LayoutStyle.mobileAppScreen:
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
    }

    final pageName = recipe.layoutStyle == LayoutStyle.mobileAppScreen
        ? (recipe.title.contains('?')
            ? 'Uber iOS App UI'
            : (recipe.title.length > 24 ? '${recipe.title.substring(0, 24)} App UI' : '${recipe.title} App UI'))
        : '${recipe.domain.name.toUpperCase()} ${recipe.aspectRatio} Design';

    return CanvasPage(
      id: UuidGenerator.generate(),
      name: pageName,
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

  /// Apple-Grade Minimal Professional Mobile App Screen Architecture
  static List<Layer> _buildMobileAppScreenLayers({
    required DesignRecipe recipe,
    required double width,
    required double height,
    required double marginX,
    required double contentWidth,
    required Color primaryColor,
    required Color accentColor,
  }) {
    final List<Layer> layers = [];

    // 1. iOS Status Bar & Dynamic Island (y = 20, height = 48)
    final timeLayer = TextLayer(
      id: UuidGenerator.generate(),
      name: 'Status Time',
      x: 0,
      y: 0,
      width: 70,
      height: 30,
      content: '9:41',
      fontSize: 22,
      fontWeight: FontWeight.w700,
      fontFamily: 'Inter',
      color: Colors.white,
    );

    final dynamicIsland = AutoLayoutLayer(
      id: UuidGenerator.generate(),
      name: 'Dynamic Island',
      x: 0,
      y: 0,
      width: 170,
      height: 36,
      direction: AutoLayoutDirection.horizontal,
      horizontalSizing: AutoLayoutSizingMode.fixed,
      verticalSizing: AutoLayoutSizingMode.fixed,
      gap: 8,
      paddingHorizontal: 12,
      paddingVertical: 0,
      alignment: AutoLayoutAlignment.center,
      distribution: AutoLayoutDistribution.center,
      backgroundColor: Colors.black,
      cornerRadius: 18,
      strokeColor: Colors.white.withValues(alpha: 0.12),
      strokeWidth: 1.2,
      children: [
        ShapeLayer(
          id: UuidGenerator.generate(),
          name: 'Camera Lens',
          x: 0,
          y: 0,
          width: 11,
          height: 11,
          shapeType: ShapeType.roundedRectangle,
          cornerRadius: 6,
          fill: const Color(0xFF1E1E28),
        ),
      ],
    );

    final statusIconsRow = AutoLayoutLayer(
      id: UuidGenerator.generate(),
      name: 'Status Indicators',
      x: 0,
      y: 0,
      width: 86,
      height: 30,
      direction: AutoLayoutDirection.horizontal,
      horizontalSizing: AutoLayoutSizingMode.hug,
      verticalSizing: AutoLayoutSizingMode.hug,
      gap: 8,
      alignment: AutoLayoutAlignment.center,
      distribution: AutoLayoutDistribution.end,
      children: [
        IconLayer(
          id: UuidGenerator.generate(),
          name: 'Cellular Icon',
          x: 0,
          y: 0,
          width: 20,
          height: 20,
          icon: Icons.signal_cellular_alt_rounded,
          color: Colors.white,
        ),
        IconLayer(
          id: UuidGenerator.generate(),
          name: 'WiFi Icon',
          x: 0,
          y: 0,
          width: 20,
          height: 20,
          icon: Icons.wifi_rounded,
          color: Colors.white,
        ),
        IconLayer(
          id: UuidGenerator.generate(),
          name: 'Battery Icon',
          x: 0,
          y: 0,
          width: 24,
          height: 24,
          icon: Icons.battery_full_rounded,
          color: Colors.white,
        ),
      ],
    );

    final statusBarLayer = AutoLayoutLayer(
      id: UuidGenerator.generate(),
      name: 'Status Bar & Island',
      x: marginX,
      y: 20,
      width: contentWidth,
      height: 48,
      direction: AutoLayoutDirection.horizontal,
      horizontalSizing: AutoLayoutSizingMode.fixed,
      verticalSizing: AutoLayoutSizingMode.fixed,
      alignment: AutoLayoutAlignment.center,
      distribution: AutoLayoutDistribution.spaceBetween,
      children: [timeLayer, dynamicIsland, statusIconsRow],
    );
    layers.add(statusBarLayer);

    // 2. In-App Navigation Bar / Header (y = 86, height = 74)
    final brandTitle = (recipe.title.contains('?') || recipe.title.toLowerCase().contains('where'))
        ? 'Uber'
        : recipe.title;

    final headerTitleBlock = AutoLayoutLayer(
      id: UuidGenerator.generate(),
      name: 'App Header Block',
      x: 0,
      y: 0,
      width: contentWidth * 0.55,
      height: 70,
      direction: AutoLayoutDirection.vertical,
      horizontalSizing: AutoLayoutSizingMode.hug,
      verticalSizing: AutoLayoutSizingMode.hug,
      gap: 4,
      alignment: AutoLayoutAlignment.start,
      distribution: AutoLayoutDistribution.start,
      children: [
        TextLayer(
          id: UuidGenerator.generate(),
          name: 'App Title',
          x: 0,
          y: 0,
          width: 220,
          height: 40,
          content: brandTitle,
          fontSize: 34,
          fontWeight: FontWeight.w900,
          fontFamily: 'Inter',
          color: Colors.white,
          letterSpacing: -1.0,
        ),
        TextLayer(
          id: UuidGenerator.generate(),
          name: 'Location Subtitle',
          x: 0,
          y: 0,
          width: 260,
          height: 22,
          content: recipe.subtitle.isNotEmpty ? recipe.subtitle : 'San Francisco, CA ▾',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: 'Inter',
          color: Colors.white.withValues(alpha: 0.65),
        ),
      ],
    );

    final headerActionBlock = AutoLayoutLayer(
      id: UuidGenerator.generate(),
      name: 'Header Actions',
      x: 0,
      y: 0,
      width: 160,
      height: 48,
      direction: AutoLayoutDirection.horizontal,
      horizontalSizing: AutoLayoutSizingMode.hug,
      verticalSizing: AutoLayoutSizingMode.hug,
      gap: 10,
      alignment: AutoLayoutAlignment.center,
      distribution: AutoLayoutDistribution.end,
      children: [
        AutoLayoutLayer(
          id: UuidGenerator.generate(),
          name: 'Activity Pill',
          x: 0,
          y: 0,
          width: 100,
          height: 40,
          direction: AutoLayoutDirection.horizontal,
          horizontalSizing: AutoLayoutSizingMode.hug,
          verticalSizing: AutoLayoutSizingMode.hug,
          gap: 6,
          paddingHorizontal: 12,
          paddingVertical: 8,
          backgroundColor: const Color(0xFF1E1C28),
          cornerRadius: 20,
          strokeColor: Colors.white.withValues(alpha: 0.12),
          strokeWidth: 1.0,
          alignment: AutoLayoutAlignment.center,
          children: [
            IconLayer(
              id: UuidGenerator.generate(),
              name: 'Activity Icon',
              x: 0,
              y: 0,
              width: 16,
              height: 16,
              icon: Icons.history_rounded,
              color: Colors.white70,
            ),
            const TextLayer(
              id: 'activity-label',
              name: 'Activity Label',
              x: 0,
              y: 0,
              width: 50,
              height: 18,
              content: 'Activity',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
              color: Colors.white,
            ),
          ],
        ),
        AutoLayoutLayer(
          id: UuidGenerator.generate(),
          name: 'Profile Avatar',
          x: 0,
          y: 0,
          width: 44,
          height: 44,
          direction: AutoLayoutDirection.horizontal,
          horizontalSizing: AutoLayoutSizingMode.fixed,
          verticalSizing: AutoLayoutSizingMode.fixed,
          backgroundColor: const Color(0xFF2C2A3C),
          cornerRadius: 22,
          strokeColor: Colors.white.withValues(alpha: 0.15),
          strokeWidth: 1.2,
          alignment: AutoLayoutAlignment.center,
          distribution: AutoLayoutDistribution.center,
          children: [
            IconLayer(
              id: UuidGenerator.generate(),
              name: 'Avatar Icon',
              x: 0,
              y: 0,
              width: 22,
              height: 22,
              icon: Icons.person_rounded,
              color: Colors.white,
            ),
          ],
        ),
      ],
    );

    final appHeaderLayer = AutoLayoutLayer(
      id: UuidGenerator.generate(),
      name: 'In-App Navigation Header',
      x: marginX,
      y: 86,
      width: contentWidth,
      height: 74,
      direction: AutoLayoutDirection.horizontal,
      horizontalSizing: AutoLayoutSizingMode.fixed,
      verticalSizing: AutoLayoutSizingMode.hug,
      alignment: AutoLayoutAlignment.center,
      distribution: AutoLayoutDistribution.spaceBetween,
      children: [headerTitleBlock, headerActionBlock],
    );
    layers.add(appHeaderLayer);

    // 3. Apple-Style Search Destination Card (y = 176, height = 78)
    final searchCard = AutoLayoutLayer(
      id: UuidGenerator.generate(),
      name: 'Destination Search Bar',
      x: marginX,
      y: 176,
      width: contentWidth,
      height: 78,
      direction: AutoLayoutDirection.horizontal,
      horizontalSizing: AutoLayoutSizingMode.fixed,
      verticalSizing: AutoLayoutSizingMode.fixed,
      paddingHorizontal: 16,
      paddingVertical: 12,
      backgroundColor: const Color(0xFF161522),
      cornerRadius: 24,
      strokeColor: Colors.white.withValues(alpha: 0.12),
      strokeWidth: 1.2,
      alignment: AutoLayoutAlignment.center,
      distribution: AutoLayoutDistribution.spaceBetween,
      children: [
        AutoLayoutLayer(
          id: UuidGenerator.generate(),
          name: 'Search Icon Box',
          x: 0,
          y: 0,
          width: 44,
          height: 44,
          direction: AutoLayoutDirection.horizontal,
          horizontalSizing: AutoLayoutSizingMode.fixed,
          verticalSizing: AutoLayoutSizingMode.fixed,
          backgroundColor: const Color(0xFF252336),
          cornerRadius: 22,
          alignment: AutoLayoutAlignment.center,
          distribution: AutoLayoutDistribution.center,
          children: [
            IconLayer(
              id: UuidGenerator.generate(),
              name: 'Search Icon',
              x: 0,
              y: 0,
              width: 22,
              height: 22,
              icon: Icons.search_rounded,
              color: accentColor,
            ),
          ],
        ),
        AutoLayoutLayer(
          id: UuidGenerator.generate(),
          name: 'Search Text Block',
          x: 0,
          y: 0,
          width: contentWidth * 0.55,
          height: 46,
          direction: AutoLayoutDirection.vertical,
          horizontalSizing: AutoLayoutSizingMode.fixed,
          verticalSizing: AutoLayoutSizingMode.hug,
          gap: 2,
          alignment: AutoLayoutAlignment.start,
          distribution: AutoLayoutDistribution.center,
          children: [
            const TextLayer(
              id: 'where-to-title',
              name: 'Where to Title',
              x: 0,
              y: 0,
              width: 200,
              height: 24,
              content: 'Where to?',
              fontSize: 19,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
              color: Colors.white,
            ),
            TextLayer(
              id: UuidGenerator.generate(),
              name: 'Where to Subtext',
              x: 0,
              y: 0,
              width: 280,
              height: 18,
              content: 'Search rides, airports or saved places',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              fontFamily: 'Inter',
              color: Colors.white.withValues(alpha: 0.52),
            ),
          ],
        ),
        AutoLayoutLayer(
          id: UuidGenerator.generate(),
          name: 'Now Pill',
          x: 0,
          y: 0,
          width: 82,
          height: 38,
          direction: AutoLayoutDirection.horizontal,
          horizontalSizing: AutoLayoutSizingMode.hug,
          verticalSizing: AutoLayoutSizingMode.hug,
          gap: 4,
          paddingHorizontal: 12,
          paddingVertical: 7,
          backgroundColor: const Color(0xFF262438),
          cornerRadius: 19,
          alignment: AutoLayoutAlignment.center,
          children: [
            IconLayer(
              id: UuidGenerator.generate(),
              name: 'Clock Icon',
              x: 0,
              y: 0,
              width: 14,
              height: 14,
              icon: Icons.access_time_filled_rounded,
              color: Colors.white70,
            ),
            const TextLayer(
              id: 'now-label',
              name: 'Now Label',
              x: 0,
              y: 0,
              width: 44,
              height: 18,
              content: 'Now ▾',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
              color: Colors.white,
            ),
          ],
        ),
      ],
    );
    layers.add(searchCard);

    // 4. Service Selection Section (Rides / App tiers) (y = 272, height = 470)
    final serviceItems = recipe.features.isNotEmpty
        ? recipe.features
        : const [
            RecipeFeatureItem(
              title: 'UberX',
              subtitle: 'Affordable, everyday rides • 3 min away',
              value: '\$18.50',
              iconName: 'directions_car',
              isHeroTile: true,
              trend: '3 min',
              tag: 'POPULAR',
            ),
            RecipeFeatureItem(
              title: 'Comfort',
              subtitle: 'Newer cars with extra legroom • 5 min away',
              value: '\$24.20',
              iconName: 'car_rental',
              trend: '5 min',
              tag: 'EXTRA ROOM',
            ),
            RecipeFeatureItem(
              title: 'Black',
              subtitle: 'Premium rides with professional drivers • 8 min away',
              value: '\$38.00',
              iconName: 'workspace_premium',
              trend: '8 min',
              tag: 'PREMIUM',
            ),
            RecipeFeatureItem(
              title: 'UberXL',
              subtitle: 'Spacious rides for groups up to 6 • 6 min away',
              value: '\$29.50',
              iconName: 'airport_shuttle',
              trend: '6 min',
              tag: '6 SEATS',
            ),
          ];

    final servicesHeaderRow = AutoLayoutLayer(
      id: UuidGenerator.generate(),
      name: 'Services Header Row',
      x: 0,
      y: 0,
      width: contentWidth,
      height: 30,
      direction: AutoLayoutDirection.horizontal,
      horizontalSizing: AutoLayoutSizingMode.fixed,
      verticalSizing: AutoLayoutSizingMode.hug,
      alignment: AutoLayoutAlignment.center,
      distribution: AutoLayoutDistribution.spaceBetween,
      children: [
        const TextLayer(
          id: 'suggested-rides-title',
          name: 'Section Title',
          x: 0,
          y: 0,
          width: 180,
          height: 26,
          content: 'Suggested Rides',
          fontSize: 20,
          fontWeight: FontWeight.w800,
          fontFamily: 'Inter',
          color: Colors.white,
        ),
        TextLayer(
          id: UuidGenerator.generate(),
          name: 'Fastest Badge',
          x: 0,
          y: 0,
          width: 130,
          height: 18,
          content: 'FASTEST PICKUP',
          fontSize: 12,
          fontWeight: FontWeight.w800,
          fontFamily: 'Inter',
          color: accentColor,
          textAlign: TextAlign.right,
        ),
      ],
    );

    final List<Layer> serviceCardLayers = [];
    for (int i = 0; i < serviceItems.length && i < 4; i++) {
      final item = serviceItems[i];
      final isHero = item.isHeroTile || i == 0;

      final cardLayer = AutoLayoutLayer(
        id: UuidGenerator.generate(),
        name: '${item.title} Tier Card',
        x: 0,
        y: 0,
        width: contentWidth,
        height: isHero ? 100 : 92,
        direction: AutoLayoutDirection.horizontal,
        horizontalSizing: AutoLayoutSizingMode.fixed,
        verticalSizing: AutoLayoutSizingMode.fixed,
        paddingHorizontal: 16,
        paddingVertical: 12,
        backgroundColor: isHero ? const Color(0xFF221F34) : const Color(0xFF14131E),
        cornerRadius: 20,
        strokeColor: isHero ? accentColor.withValues(alpha: 0.60) : Colors.white.withValues(alpha: 0.08),
        strokeWidth: isHero ? 1.6 : 1.0,
        alignment: AutoLayoutAlignment.center,
        distribution: AutoLayoutDistribution.spaceBetween,
        children: [
          AutoLayoutLayer(
            id: UuidGenerator.generate(),
            name: 'Service Icon Container',
            x: 0,
            y: 0,
            width: isHero ? 56 : 50,
            height: isHero ? 56 : 50,
            direction: AutoLayoutDirection.horizontal,
            horizontalSizing: AutoLayoutSizingMode.fixed,
            verticalSizing: AutoLayoutSizingMode.fixed,
            backgroundColor: isHero ? const Color(0xFF2F2A4A) : const Color(0xFF1D1B2A),
            cornerRadius: 15,
            alignment: AutoLayoutAlignment.center,
            distribution: AutoLayoutDistribution.center,
            children: [
              IconLayer(
                id: UuidGenerator.generate(),
                name: 'Service Icon',
                x: 0,
                y: 0,
                width: isHero ? 30 : 26,
                height: isHero ? 30 : 26,
                icon: _resolveIcon(item.iconName),
                color: isHero ? Colors.white : Colors.white70,
              ),
            ],
          ),
          AutoLayoutLayer(
            id: UuidGenerator.generate(),
            name: 'Service Info Block',
            x: 0,
            y: 0,
            width: contentWidth * 0.54,
            height: isHero ? 58 : 52,
            direction: AutoLayoutDirection.vertical,
            horizontalSizing: AutoLayoutSizingMode.fixed,
            verticalSizing: AutoLayoutSizingMode.hug,
            gap: 3,
            alignment: AutoLayoutAlignment.start,
            distribution: AutoLayoutDistribution.center,
            children: [
              AutoLayoutLayer(
                id: UuidGenerator.generate(),
                name: 'Title Row',
                x: 0,
                y: 0,
                width: contentWidth * 0.52,
                height: 24,
                direction: AutoLayoutDirection.horizontal,
                horizontalSizing: AutoLayoutSizingMode.hug,
                verticalSizing: AutoLayoutSizingMode.hug,
                gap: 8,
                alignment: AutoLayoutAlignment.center,
                children: [
                  TextLayer(
                    id: UuidGenerator.generate(),
                    name: 'Tier Title',
                    x: 0,
                    y: 0,
                    width: 100,
                    height: 22,
                    content: item.title,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Inter',
                    color: Colors.white,
                  ),
                  if (item.tag != null && item.tag!.isNotEmpty)
                    AutoLayoutLayer(
                      id: UuidGenerator.generate(),
                      name: 'Tag Chip',
                      x: 0,
                      y: 0,
                      width: 70,
                      height: 20,
                      direction: AutoLayoutDirection.horizontal,
                      horizontalSizing: AutoLayoutSizingMode.hug,
                      verticalSizing: AutoLayoutSizingMode.hug,
                      paddingHorizontal: 7,
                      paddingVertical: 3,
                      backgroundColor: isHero ? accentColor.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.10),
                      cornerRadius: 6,
                      alignment: AutoLayoutAlignment.center,
                      children: [
                        TextLayer(
                          id: UuidGenerator.generate(),
                          name: 'Tag Text',
                          x: 0,
                          y: 0,
                          width: 60,
                          height: 14,
                          content: item.tag!.toUpperCase(),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Inter',
                          color: isHero ? accentColor : Colors.white70,
                        ),
                      ],
                    ),
                ],
              ),
              if (item.subtitle != null)
                TextLayer(
                  id: UuidGenerator.generate(),
                  name: 'Tier Subtitle',
                  x: 0,
                  y: 0,
                  width: contentWidth * 0.52,
                  height: 18,
                  content: item.subtitle!,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Inter',
                  color: Colors.white.withValues(alpha: 0.65),
                ),
            ],
          ),
          AutoLayoutLayer(
            id: UuidGenerator.generate(),
            name: 'Price Block',
            x: 0,
            y: 0,
            width: contentWidth * 0.20,
            height: isHero ? 50 : 46,
            direction: AutoLayoutDirection.vertical,
            horizontalSizing: AutoLayoutSizingMode.fixed,
            verticalSizing: AutoLayoutSizingMode.hug,
            gap: 2,
            alignment: AutoLayoutAlignment.end,
            distribution: AutoLayoutDistribution.center,
            children: [
              TextLayer(
                id: UuidGenerator.generate(),
                name: 'Price Text',
                x: 0,
                y: 0,
                width: 90,
                height: 24,
                content: item.value ?? '\$18.50',
                fontSize: isHero ? 20 : 18,
                fontWeight: FontWeight.w900,
                fontFamily: 'Inter',
                color: Colors.white,
                textAlign: TextAlign.right,
              ),
              TextLayer(
                id: UuidGenerator.generate(),
                name: 'ETA Text',
                x: 0,
                y: 0,
                width: 90,
                height: 16,
                content: item.trend ?? '3 min',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
                color: Colors.white.withValues(alpha: 0.50),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ],
      );
      serviceCardLayers.add(cardLayer);
    }

    final servicesSection = AutoLayoutLayer(
      id: UuidGenerator.generate(),
      name: 'Services Tier Stack',
      x: marginX,
      y: 272,
      width: contentWidth,
      height: 440,
      direction: AutoLayoutDirection.vertical,
      horizontalSizing: AutoLayoutSizingMode.fixed,
      verticalSizing: AutoLayoutSizingMode.hug,
      gap: 10,
      alignment: AutoLayoutAlignment.start,
      children: [servicesHeaderRow, ...serviceCardLayers],
    );
    layers.add(servicesSection);

    // 5. Apple Grouped Recent Destinations (y = 740, height = 250)
    final savedPlaces = [
      ('Home', '124 Market Street, Financial District', Icons.home_rounded, const Color(0xFF38BDF8)),
      ('Workplace', '500 Howard Street, Suite 400', Icons.work_rounded, const Color(0xFFF59E0B)),
      ('SFO Airport', 'Terminal 2, Departures Level', Icons.flight_takeoff_rounded, const Color(0xFFA855F7)),
    ];

    final List<Layer> savedPlaceRows = [];
    for (int i = 0; i < savedPlaces.length; i++) {
      final p = savedPlaces[i];
      final placeRow = AutoLayoutLayer(
        id: UuidGenerator.generate(),
        name: '${p.$1} Row',
        x: 0,
        y: 0,
        width: contentWidth - 32,
        height: 54,
        direction: AutoLayoutDirection.horizontal,
        horizontalSizing: AutoLayoutSizingMode.fixed,
        verticalSizing: AutoLayoutSizingMode.fixed,
        alignment: AutoLayoutAlignment.center,
        distribution: AutoLayoutDistribution.spaceBetween,
        children: [
          AutoLayoutLayer(
            id: UuidGenerator.generate(),
            name: 'Place Icon Box',
            x: 0,
            y: 0,
            width: 38,
            height: 38,
            direction: AutoLayoutDirection.horizontal,
            horizontalSizing: AutoLayoutSizingMode.fixed,
            verticalSizing: AutoLayoutSizingMode.fixed,
            backgroundColor: p.$4.withValues(alpha: 0.16),
            cornerRadius: 19,
            alignment: AutoLayoutAlignment.center,
            distribution: AutoLayoutDistribution.center,
            children: [
              IconLayer(
                id: UuidGenerator.generate(),
                name: 'Icon',
                x: 0,
                y: 0,
                width: 18,
                height: 18,
                icon: p.$3,
                color: p.$4,
              ),
            ],
          ),
          AutoLayoutLayer(
            id: UuidGenerator.generate(),
            name: 'Place Text Block',
            x: 0,
            y: 0,
            width: contentWidth - 140,
            height: 44,
            direction: AutoLayoutDirection.vertical,
            horizontalSizing: AutoLayoutSizingMode.fixed,
            verticalSizing: AutoLayoutSizingMode.hug,
            gap: 2,
            alignment: AutoLayoutAlignment.start,
            distribution: AutoLayoutDistribution.center,
            children: [
              TextLayer(
                id: UuidGenerator.generate(),
                name: 'Place Name',
                x: 0,
                y: 0,
                width: 200,
                height: 20,
                content: p.$1,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
                color: Colors.white,
              ),
              TextLayer(
                id: UuidGenerator.generate(),
                name: 'Place Address',
                x: 0,
                y: 0,
                width: contentWidth - 150,
                height: 16,
                content: p.$2,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                fontFamily: 'Inter',
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ],
          ),
          IconLayer(
            id: UuidGenerator.generate(),
            name: 'Chevron',
            x: 0,
            y: 0,
            width: 14,
            height: 14,
            icon: Icons.arrow_forward_ios_rounded,
            color: Colors.white.withValues(alpha: 0.35),
          ),
        ],
      );

      savedPlaceRows.add(placeRow);

      if (i < savedPlaces.length - 1) {
        savedPlaceRows.add(
          ShapeLayer(
            id: UuidGenerator.generate(),
            name: 'Divider Line',
            x: 0,
            y: 0,
            width: contentWidth - 32,
            height: 1,
            fill: Colors.white.withValues(alpha: 0.06),
          ),
        );
      }
    }

    final savedPlacesSection = AutoLayoutLayer(
      id: UuidGenerator.generate(),
      name: 'Recent Destinations Card',
      x: marginX,
      y: 740,
      width: contentWidth,
      height: 240,
      direction: AutoLayoutDirection.vertical,
      horizontalSizing: AutoLayoutSizingMode.fixed,
      verticalSizing: AutoLayoutSizingMode.hug,
      gap: 6,
      paddingHorizontal: 16,
      paddingVertical: 10,
      backgroundColor: const Color(0xFF14131E),
      cornerRadius: 22,
      strokeColor: Colors.white.withValues(alpha: 0.08),
      strokeWidth: 1.0,
      alignment: AutoLayoutAlignment.start,
      children: savedPlaceRows,
    );
    layers.add(savedPlacesSection);

    // 6. Sticky Booking CTA Button (y = 1005, height = 70)
    final ctaButton = AutoLayoutLayer(
      id: UuidGenerator.generate(),
      name: 'Primary CTA Button',
      x: marginX,
      y: 1005,
      width: contentWidth,
      height: 70,
      direction: AutoLayoutDirection.horizontal,
      horizontalSizing: AutoLayoutSizingMode.fixed,
      verticalSizing: AutoLayoutSizingMode.fixed,
      backgroundColor: Colors.white,
      cornerRadius: 24,
      alignment: AutoLayoutAlignment.center,
      distribution: AutoLayoutDistribution.center,
      gap: 8,
      children: [
        const IconLayer(
          id: 'cta-icon',
          name: 'CTA Check Icon',
          x: 0,
          y: 0,
          width: 20,
          height: 20,
          icon: Icons.check_circle_rounded,
          color: Colors.black,
        ),
        TextLayer(
          id: UuidGenerator.generate(),
          name: 'CTA Text',
          x: 0,
          y: 0,
          width: 280,
          height: 26,
          content: recipe.ctaText ?? 'Choose UberX • \$18.50',
          fontSize: 19,
          fontWeight: FontWeight.w800,
          fontFamily: 'Inter',
          color: Colors.black,
          textAlign: TextAlign.center,
        ),
      ],
    );
    layers.add(ctaButton);

    // 7. iOS Bottom Navigation Bar & Home Indicator (y = 1775, height = 110)
    final tabs = [
      ('Home', Icons.home_filled, true),
      ('Services', Icons.grid_view_rounded, false),
      ('Activity', Icons.receipt_long_rounded, false),
      ('Account', Icons.person_rounded, false),
    ];

    final List<Layer> tabWidgets = [];
    for (final t in tabs) {
      tabWidgets.add(
        AutoLayoutLayer(
          id: UuidGenerator.generate(),
          name: '${t.$1} Tab',
          x: 0,
          y: 0,
          width: 70,
          height: 52,
          direction: AutoLayoutDirection.vertical,
          horizontalSizing: AutoLayoutSizingMode.hug,
          verticalSizing: AutoLayoutSizingMode.hug,
          gap: 4,
          alignment: AutoLayoutAlignment.center,
          distribution: AutoLayoutDistribution.center,
          children: [
            IconLayer(
              id: UuidGenerator.generate(),
              name: 'Tab Icon',
              x: 0,
              y: 0,
              width: 24,
              height: 24,
              icon: t.$2,
              color: t.$3 ? Colors.white : Colors.white.withValues(alpha: 0.45),
            ),
            TextLayer(
              id: UuidGenerator.generate(),
              name: 'Tab Label',
              x: 0,
              y: 0,
              width: 60,
              height: 16,
              content: t.$1,
              fontSize: 11,
              fontWeight: t.$3 ? FontWeight.w700 : FontWeight.w500,
              fontFamily: 'Inter',
              color: t.$3 ? Colors.white : Colors.white.withValues(alpha: 0.45),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final bottomNavBar = AutoLayoutLayer(
      id: UuidGenerator.generate(),
      name: 'iOS Tab Bar',
      x: 0,
      y: 1775,
      width: width,
      height: 105,
      direction: AutoLayoutDirection.horizontal,
      horizontalSizing: AutoLayoutSizingMode.fixed,
      verticalSizing: AutoLayoutSizingMode.fixed,
      paddingHorizontal: 40,
      backgroundColor: const Color(0xFF0C0B12),
      strokeColor: Colors.white.withValues(alpha: 0.08),
      strokeWidth: 1.0,
      alignment: AutoLayoutAlignment.center,
      distribution: AutoLayoutDistribution.spaceBetween,
      children: tabWidgets,
    );
    layers.add(bottomNavBar);

    final homeIndicator = ShapeLayer(
      id: UuidGenerator.generate(),
      name: 'Home Indicator Pill',
      x: (width - 150) / 2,
      y: 1895,
      width: 150,
      height: 5,
      shapeType: ShapeType.roundedRectangle,
      cornerRadius: 3,
      fill: Colors.white.withValues(alpha: 0.38),
    );
    layers.add(homeIndicator);

    return layers;
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
      case 'directions_car':
      case 'car':
      case 'ride':
      case 'taxi':
        return Icons.directions_car_rounded;
      case 'car_rental':
      case 'comfort':
        return Icons.car_rental_rounded;
      case 'workspace_premium':
      case 'black':
      case 'premium':
      case 'vip':
        return Icons.workspace_premium_rounded;
      case 'airport_shuttle':
      case 'xl':
      case 'van':
        return Icons.airport_shuttle_rounded;
      case 'search':
        return Icons.search_rounded;
      case 'history':
      case 'activity':
        return Icons.history_rounded;
      case 'person':
      case 'user':
        return Icons.person_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'work':
      case 'business':
        return Icons.work_rounded;
      case 'flight':
      case 'flight_takeoff':
      case 'airport':
      case 'airplane':
        return Icons.flight_takeoff_rounded;
      case 'access_time':
      case 'time':
      case 'clock':
        return Icons.access_time_filled_rounded;
      case 'location_on':
      case 'pin':
        return Icons.location_on_rounded;
      case 'fastfood':
      case 'food':
      case 'burger':
        return Icons.fastfood_rounded;
      case 'lunch_dining':
      case 'salad':
        return Icons.lunch_dining_rounded;
      case 'local_cafe':
      case 'coffee':
        return Icons.local_cafe_rounded;
      case 'bakery_dining':
      case 'bakery':
        return Icons.bakery_dining_rounded;
      case 'account_balance_wallet':
      case 'wallet':
        return Icons.account_balance_wallet_rounded;
      case 'laptop_mac':
      case 'apple':
      case 'laptop':
        return Icons.laptop_mac_rounded;
      case 'payments':
      case 'payment':
      case 'salary':
        return Icons.payments_rounded;
      case 'fitness_center':
      case 'gym':
      case 'workout':
        return Icons.fitness_center_rounded;
      case 'phone_iphone':
      case 'phone':
        return Icons.phone_iphone_rounded;
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
