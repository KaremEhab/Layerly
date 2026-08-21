import 'package:flutter/material.dart';

class ResponsiveBreakpoints {
  static const double mobileMax = 767.0;
  static const double tabletMin = 768.0;
  static const double desktopMin = 1200.0;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < tabletMin;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tabletMin && width < desktopMin;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopMin;
}
