import 'package:equatable/equatable.dart';

enum LayoutStyle {
  heroCards,
  splitBento,
  statisticFocus,
  centeredMinimal,
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

  const RecipeFeatureItem({
    required this.title,
    this.subtitle,
    this.value,
    this.iconName = 'check_circle',
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'value': value,
        'iconName': iconName,
      };

  factory RecipeFeatureItem.fromJson(Map<String, dynamic> json) {
    return RecipeFeatureItem(
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      value: json['value'] as String?,
      iconName: json['iconName'] as String? ?? 'check_circle',
    );
  }

  @override
  List<Object?> get props => [title, subtitle, value, iconName];
}

class DesignRecipe extends Equatable {
  final String title;
  final String subtitle;
  final String badgeText;
  final String? badgeIcon;
  final DesignDomain domain;
  final LayoutStyle layoutStyle;
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
        'aspectRatio': aspectRatio,
        'gradientColors': gradientColors,
        'primaryColor': primaryColor,
        'accentColor': accentColor,
        'features': features.map((f) => f.toJson()).toList(),
        'footerText': footerText,
        'ctaText': ctaText,
      };

  factory DesignRecipe.fromJson(Map<String, dynamic> json) {
    return DesignRecipe(
      title: json['title'] as String? ?? 'Untitled Design',
      subtitle: json['subtitle'] as String? ?? '',
      badgeText: json['badgeText'] as String? ?? '',
      badgeIcon: json['badgeIcon'] as String?,
      domain: DesignDomain.values.firstWhere(
        (d) => d.name.toLowerCase() == (json['domain'] as String? ?? '').toLowerCase(),
        orElse: () => DesignDomain.creative,
      ),
      layoutStyle: LayoutStyle.values.firstWhere(
        (l) => l.name.toLowerCase() == (json['layoutStyle'] as String? ?? '').toLowerCase(),
        orElse: () => LayoutStyle.heroCards,
      ),
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
        aspectRatio,
        gradientColors,
        primaryColor,
        accentColor,
        features,
        footerText,
        ctaText,
      ];
}
