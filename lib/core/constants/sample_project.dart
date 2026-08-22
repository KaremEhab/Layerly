import 'package:flutter/material.dart';
import 'package:layerly/core/constants/app_colors.dart';
import 'package:layerly/core/utils/uuid_generator.dart';
import 'package:layerly/features/editor/domain/entities/canvas_project.dart';
import 'package:layerly/features/editor/domain/entities/canvas_page.dart';
import 'package:layerly/features/editor/domain/entities/layer_enums.dart';
import 'package:layerly/features/editor/domain/entities/text_layer.dart';
import 'package:layerly/features/editor/domain/entities/shape_layer.dart';
import 'package:layerly/features/editor/domain/entities/icon_layer.dart';
import 'package:layerly/features/editor/domain/entities/device_mockup_layer.dart';
import 'package:layerly/features/editor/domain/entities/component_definition.dart';
import 'package:layerly/features/editor/domain/entities/component_instance_layer.dart';
import 'package:layerly/features/editor/domain/entities/auto_layout_layer.dart';

class SampleProject {
  static AutoLayoutLayer createFooterLayout({
    required double x,
    required double y,
    int activeIndicatorIndex = 0,
  }) {
    return AutoLayoutLayer(
      id: UuidGenerator.generate(),
      name: 'Profile Footer',
      x: x,
      y: y,
      width: 250,
      height: 42,
      direction: AutoLayoutDirection.horizontal,
      gap: 12,
      paddingHorizontal: 0,
      paddingVertical: 0,
      alignment: AutoLayoutAlignment.center,
      distribution: AutoLayoutDistribution.start,
      children: [
        // Icon (Logo)
        IconLayer(
          id: UuidGenerator.generate(),
          name: 'Brand Logo',
          x: 0,
          y: 0,
          width: 36,
          height: 36,
          icon: Icons.all_inclusive_rounded,
          color: Colors.white,
        ),

        // Vertical layout with 2 things: Text (Kareem Ehab) + Text (kareem.designs_)
        AutoLayoutLayer(
          id: UuidGenerator.generate(),
          name: 'Author Info',
          x: 0,
          y: 0,
          width: 180,
          height: 42,
          direction: AutoLayoutDirection.vertical,
          gap: 2,
          paddingHorizontal: 0,
          paddingVertical: 0,
          alignment: AutoLayoutAlignment.start,
          distribution: AutoLayoutDistribution.start,
          children: [
            TextLayer(
              id: UuidGenerator.generate(),
              name: 'Author Name',
              x: 0,
              y: 0,
              width: 180,
              height: 18,
              content: 'Kareem Ehab',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
            TextLayer(
              id: UuidGenerator.generate(),
              name: 'Author Handle',
              x: 0,
              y: 0,
              width: 180,
              height: 22,
              content: 'kareem.designs_',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ],
        ),
      ],
    );
  }

  static CanvasProject createUberRedesignProject() {
    final footerComponentId = UuidGenerator.generate();

    // 1. Reusable Component: Profile Footer
    final profileFooterComponent = ComponentDefinition(
      id: footerComponentId,
      name: 'Profile Footer',
      description: 'Author branding',
      width: 250,
      height: 42,
      layers: [
        createFooterLayout(x: 0, y: 0),
      ],
    );

    // Slide 1: Cover Screen
    final page1 = CanvasPage(
      id: UuidGenerator.generate(),
      name: 'Cover Screen',
      width: 1080,
      height: 1080,
      horizontalPadding: 80,
      verticalPadding: 80,
      backgroundType: BackgroundType.gradient,
      backgroundColor: AppColors.background,
      showGuides: false,
      backgroundGradient: const RadialGradient(
        center: Alignment(0.85, -0.65),
        radius: 1.25,
        colors: [
          Color(0xFF834DEB), // Vibrant top-right purple glow
          Color(0xFF381B60), // Deep purple
          Color(0xFF13101E), // Dark plum
          Color(0xFF0A0910), // Base black
        ],
        stops: [0.0, 0.38, 0.72, 1.0],
      ),
      layers: [
        // Category Label
        TextLayer(
          id: UuidGenerator.generate(),
          name: 'Category Label',
          x: 80,
          y: 80,
          width: 100,
          height: 20,
          content: 'REDESIGN',
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryLight,
          letterSpacing: 2.0,
        ),

        // Headline (Single Multi-Color Text Layer)
        TextLayer(
          id: UuidGenerator.generate(),
          name: 'Uber Eats Headline',
          x: 80,
          y: 130,
          width: 320,
          height: 190,
          content: "I redesigned\n[color:#6C5CE7]Uber's Eats[/color]\nscreen.",
          fontSize: 48,
          fontWeight: FontWeight.bold,
          fontFamily: 'Outfit',
          color: Colors.white,
          lineHeight: 1.15,
        ),

        // Divider
        ShapeLayer(
          id: UuidGenerator.generate(),
          name: 'Purple Divider',
          shapeType: ShapeType.line,
          x: 80,
          y: 370,
          width: 90,
          height: 4,
          fill: AppColors.primary,
          cornerRadius: 2,
        ),

        // Bullet Checklist 1 (Horizontal Auto Layout)
        AutoLayoutLayer(
          id: UuidGenerator.generate(),
          name: 'Checklist Item 1',
          x: 80,
          y: 430,
          width: 235,
          height: 36,
          direction: AutoLayoutDirection.horizontal,
          gap: 14,
          paddingHorizontal: 0,
          paddingVertical: 0,
          alignment: AutoLayoutAlignment.center,
          distribution: AutoLayoutDistribution.start,
          children: [
            IconLayer(
              id: UuidGenerator.generate(),
              name: 'Check Icon 1',
              x: 0,
              y: 0,
              width: 36,
              height: 36,
              icon: Icons.check_circle_outline_rounded,
              color: AppColors.primary,
            ),
            TextLayer(
              id: UuidGenerator.generate(),
              name: 'Check Text 1',
              x: 0,
              y: 0,
              width: 185,
              height: 28,
              content: 'Clearer hierarchy',
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ],
        ),

        // Bullet Checklist 2 (Horizontal Auto Layout)
        AutoLayoutLayer(
          id: UuidGenerator.generate(),
          name: 'Checklist Item 2',
          x: 80,
          y: 510,
          width: 200,
          height: 36,
          direction: AutoLayoutDirection.horizontal,
          gap: 14,
          paddingHorizontal: 0,
          paddingVertical: 0,
          alignment: AutoLayoutAlignment.center,
          distribution: AutoLayoutDistribution.start,
          children: [
            IconLayer(
              id: UuidGenerator.generate(),
              name: 'Check Icon 2',
              x: 0,
              y: 0,
              width: 36,
              height: 36,
              icon: Icons.check_circle_outline_rounded,
              color: AppColors.primary,
            ),
            TextLayer(
              id: UuidGenerator.generate(),
              name: 'Check Text 2',
              x: 0,
              y: 0,
              width: 150,
              height: 28,
              content: 'Easier choices',
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ],
        ),

        // Bullet Checklist 3 (Horizontal Auto Layout)
        AutoLayoutLayer(
          id: UuidGenerator.generate(),
          name: 'Checklist Item 3',
          x: 80,
          y: 590,
          width: 205,
          height: 36,
          direction: AutoLayoutDirection.horizontal,
          gap: 14,
          paddingHorizontal: 0,
          paddingVertical: 0,
          alignment: AutoLayoutAlignment.center,
          distribution: AutoLayoutDistribution.start,
          children: [
            IconLayer(
              id: UuidGenerator.generate(),
              name: 'Check Icon 3',
              x: 0,
              y: 0,
              width: 36,
              height: 36,
              icon: Icons.check_circle_outline_rounded,
              color: AppColors.primary,
            ),
            TextLayer(
              id: UuidGenerator.generate(),
              name: 'Check Text 3',
              x: 0,
              y: 0,
              width: 155,
              height: 28,
              content: 'Better UX flow',
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ],
        ),

        // Phone Mockup (on the right)
        DeviceMockupLayer(
          id: UuidGenerator.generate(),
          name: 'Uber Eats Mockup',
          x: 520,
          y: 70,
          width: 480,
          height: 940,
          cornerRadius: 48,
          device: MockupDevice.iphone,
        ),

        // Profile Footer (Nested Auto Layout Hierarchy)
        createFooterLayout(x: 80, y: 920, activeIndicatorIndex: 0),
      ],
    );

    // Slide 2: Login Screen
    final page2 = CanvasPage(
      id: UuidGenerator.generate(),
      name: 'Login Screen',
      width: 1080,
      height: 1080,
      horizontalPadding: 80,
      verticalPadding: 80,
      backgroundType: BackgroundType.solid,
      backgroundColor: AppColors.background,
      layers: [
        TextLayer(
          id: UuidGenerator.generate(),
          name: 'Category Label',
          x: 80,
          y: 80,
          width: 300,
          height: 30,
          content: 'THE PROBLEM',
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: AppColors.danger,
          letterSpacing: 2.0,
        ),
        TextLayer(
          id: UuidGenerator.generate(),
          name: 'Problem Title',
          x: 80,
          y: 130,
          width: 800,
          height: 70,
          content: 'Too many competing options.',
          fontSize: 44,
          fontWeight: FontWeight.bold,
          fontFamily: 'Outfit',
          color: Colors.white,
        ),
        ShapeLayer(
          id: UuidGenerator.generate(),
          name: 'Problem Card',
          x: 80,
          y: 240,
          width: 920,
          height: 480,
          fill: AppColors.surface,
          cornerRadius: 20,
          strokeColor: AppColors.border,
          strokeWidth: 1.5,
        ),
        TextLayer(
          id: UuidGenerator.generate(),
          name: 'Problem Explanation',
          x: 120,
          y: 280,
          width: 840,
          height: 180,
          content:
              'Users often get decision paralysis due to cluttered category chips and lack of clear focal points.',
          fontSize: 24,
          fontWeight: FontWeight.normal,
          lineHeight: 1.4,
          color: AppColors.textSecondary,
        ),
        createFooterLayout(x: 80, y: 920, activeIndicatorIndex: 1),
      ],
    );

    // Slide 3: Dashboard
    final page3 = CanvasPage(
      id: UuidGenerator.generate(),
      name: 'Dashboard',
      width: 1080,
      height: 1080,
      horizontalPadding: 80,
      verticalPadding: 80,
      backgroundType: BackgroundType.gradient,
      backgroundColor: AppColors.background,
      backgroundGradient: const RadialGradient(
        center: Alignment(0.0, 0.0),
        radius: 1.0,
        colors: [Color(0xFF2C194D), Color(0xFF0D0B14)],
      ),
      layers: [
        TextLayer(
          id: UuidGenerator.generate(),
          name: 'CTA Heading',
          x: 140,
          y: 280,
          width: 800,
          height: 80,
          content: 'What do you think of this redesign?',
          fontSize: 42,
          fontWeight: FontWeight.bold,
          textAlign: TextAlign.center,
          fontFamily: 'Outfit',
        ),
        TextLayer(
          id: UuidGenerator.generate(),
          name: 'CTA Subtitle',
          x: 140,
          y: 380,
          width: 800,
          height: 60,
          content: 'Save this post for your next UI inspiration 📌',
          fontSize: 24,
          textAlign: TextAlign.center,
          color: AppColors.textSecondary,
        ),
        createFooterLayout(x: 80, y: 920, activeIndicatorIndex: 2),
      ],
    );

    return CanvasProject(
      id: UuidGenerator.generate(),
      name: 'Uber Eats Redesign',
      description: 'UI/UX Redesign Breakdown Carousel',
      pages: [page1, page2, page3],
      activePageIndex: 0,
      components: [profileFooterComponent],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
