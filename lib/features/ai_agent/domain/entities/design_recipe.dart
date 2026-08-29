import 'package:equatable/equatable.dart';

enum LayoutStyle {
  heroCards,
  splitBento,
  featureGrid,
  statisticFocus,
  centeredMinimal,
}

enum CardAesthetic {
  glass,
  solidElevated,
  gradientBorder,
  minimal,
}

enum BackgroundStyle {
  meshRadial,
  linearAtmosphere,
  darkStudio,
  cleanLight,
}

enum DesignDomain {
  pharma,
  healthcare,
  tech,
  saas,
  fitness,
  marketing,
  ecommerce,
  creative,
}

class RecipeFeatureItem extends Equatable {
  final String title;
  final String? subtitle;
  final String? value;
  final String iconName;
  final bool isHeroTile;
  final String? trend;
  final String? tag;

  const RecipeFeatureItem({
    required this.title,
    this.subtitle,
    this.value,
    this.iconName = 'check_circle',
    this.isHeroTile = false,
    this.trend,
    this.tag,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'value': value,
        'iconName': iconName,
        'isHeroTile': isHeroTile,
        'trend': trend,
        'tag': tag,
      };

  factory RecipeFeatureItem.fromJson(Map<String, dynamic> json) {
    return RecipeFeatureItem(
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      value: json['value'] as String?,
      iconName: json['iconName'] as String? ?? 'check_circle',
      isHeroTile: json['isHeroTile'] as bool? ?? false,
      trend: json['trend'] as String?,
      tag: json['tag'] as String?,
    );
  }

  @override
  List<Object?> get props => [title, subtitle, value, iconName, isHeroTile, trend, tag];
}

class DesignRecipe extends Equatable {
  final String title;
  final String subtitle;
  final String badgeText;
  final String? badgeIcon;
  final DesignDomain domain;
  final LayoutStyle layoutStyle;
  final CardAesthetic cardAesthetic;
  final BackgroundStyle backgroundStyle;
  final String headingFont;
  final String bodyFont;
  final String aspectRatio; // '1:1', '4:5', '9:16', '16:9'
  final List<String> gradientColors; // Hex strings e.g. '#0D1B2A', '#1B263B'
  final String primaryColor;
  final String accentColor;
  final List<RecipeFeatureItem> features;
  final String? footerText;
  final String? ctaText;

  const DesignRecipe({
    required this.title,
    required this.subtitle,
    this.badgeText = '',
    this.badgeIcon,
    this.domain = DesignDomain.creative,
    this.layoutStyle = LayoutStyle.heroCards,
    this.cardAesthetic = CardAesthetic.glass,
    this.backgroundStyle = BackgroundStyle.meshRadial,
    this.headingFont = 'Outfit',
    this.bodyFont = 'Inter',
    this.aspectRatio = '1:1',
    this.gradientColors = const ['#0B132B', '#1C2541', '#3A506B'],
    this.primaryColor = '#8B5CF6',
    this.accentColor = '#10B981',
    this.features = const [],
    this.footerText,
    this.ctaText,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'badgeText': badgeText,
        'badgeIcon': badgeIcon,
        'domain': domain.name,
        'layoutStyle': layoutStyle.name,
        'cardAesthetic': cardAesthetic.name,
        'backgroundStyle': backgroundStyle.name,
        'headingFont': headingFont,
        'bodyFont': bodyFont,
        'aspectRatio': aspectRatio,
        'gradientColors': gradientColors,
        'primaryColor': primaryColor,
        'accentColor': accentColor,
        'features': features.map((f) => f.toJson()).toList(),
        'footerText': footerText,
        'ctaText': ctaText,
      };

  factory DesignRecipe.fromJson(Map<String, dynamic> json) {
    final rawLayout = (json['layoutStyle'] as String? ?? '').toLowerCase();
    final layoutStyle = LayoutStyle.values.firstWhere(
      (l) => l.name.toLowerCase() == rawLayout ||
          (rawLayout.contains('bento') && l == LayoutStyle.splitBento) ||
          (rawLayout.contains('grid') && l == LayoutStyle.featureGrid) ||
          (rawLayout.contains('stat') && l == LayoutStyle.statisticFocus) ||
          (rawLayout.contains('minimal') && l == LayoutStyle.centeredMinimal),
      orElse: () => LayoutStyle.heroCards,
    );

    final rawCardAesthetic = (json['cardAesthetic'] as String? ?? '').toLowerCase();
    final cardAesthetic = CardAesthetic.values.firstWhere(
      (c) => c.name.toLowerCase() == rawCardAesthetic,
      orElse: () => CardAesthetic.glass,
    );

    final rawBg = (json['backgroundStyle'] as String? ?? '').toLowerCase();
    final backgroundStyle = BackgroundStyle.values.firstWhere(
      (b) => b.name.toLowerCase() == rawBg,
      orElse: () => BackgroundStyle.meshRadial,
    );

    return DesignRecipe(
      title: json['title'] as String? ?? 'Untitled Design',
      subtitle: json['subtitle'] as String? ?? '',
      badgeText: json['badgeText'] as String? ?? '',
      badgeIcon: json['badgeIcon'] as String?,
      domain: DesignDomain.values.firstWhere(
        (d) => d.name.toLowerCase() == (json['domain'] as String? ?? '').toLowerCase(),
        orElse: () => DesignDomain.creative,
      ),
      layoutStyle: layoutStyle,
      cardAesthetic: cardAesthetic,
      backgroundStyle: backgroundStyle,
      headingFont: json['headingFont'] as String? ?? 'Outfit',
      bodyFont: json['bodyFont'] as String? ?? 'Inter',
      aspectRatio: json['aspectRatio'] as String? ?? '1:1',
      gradientColors: (json['gradientColors'] as List<dynamic>?)
              ?.map((c) => c.toString())
              .toList() ??
          const ['#0B132B', '#1C2541'],
      primaryColor: json['primaryColor'] as String? ?? '#8B5CF6',
      accentColor: json['accentColor'] as String? ?? '#10B981',
      features: (json['features'] as List<dynamic>?)
              ?.map((f) => RecipeFeatureItem.fromJson(f as Map<String, dynamic>))
              .toList() ??
          const [],
      footerText: json['footerText'] as String?,
      ctaText: json['ctaText'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        title,
        subtitle,
        badgeText,
        badgeIcon,
        domain,
        layoutStyle,
        cardAesthetic,
        backgroundStyle,
        headingFont,
        bodyFont,
        aspectRatio,
        gradientColors,
        primaryColor,
        accentColor,
        features,
        footerText,
        ctaText,
      ];
}
