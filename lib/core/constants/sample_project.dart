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

class SampleProject {
  static CanvasProject createUberRedesignProject() {
    final footerComponentId = UuidGenerator.generate();

    // 1. Reusable Component: Profile Footer
    final profileFooterComponent = ComponentDefinition(
      id: footerComponentId,
      name: 'Profile Footer',
      description: 'Author branding and carousel pagination indicators',
      width: 440,
      height: 60,
      layers: [
        // Carousel Pagination line pills
        ShapeLayer(
          id: UuidGenerator.generate(),
          name: 'Indicator Active',
          x: 0,
          y: 0,
          width: 42,
          height: 6,
          fill: AppColors.primary,
          cornerRadius: 3,
        ),
        ShapeLayer(
          id: UuidGenerator.generate(),
          name: 'Indicator 2',
          x: 48,
          y: 0,
          width: 42,
          height: 6,
          fill: const Color(0xFF383A45),
          cornerRadius: 3,
        ),
        ShapeLayer(
          id: UuidGenerator.generate(),
          name: 'Indicator 3',
          x: 96,
          y: 0,
          width: 42,
          height: 6,
          fill: const Color(0xFF383A45),
          cornerRadius: 3,
        ),
        ShapeLayer(
          id: UuidGenerator.generate(),
          name: 'Indicator 4',
          x: 144,
          y: 0,
          width: 42,
          height: 6,
          fill: const Color(0xFF383A45),
          cornerRadius: 3,
        ),
        ShapeLayer(
          id: UuidGenerator.generate(),
          name: 'Indicator 5',
          x: 192,
          y: 0,
          width: 42,
          height: 6,
          fill: const Color(0xFF383A45),
          cornerRadius: 3,
        ),

        // Brand Mark Icon
        IconLayer(
          id: UuidGenerator.generate(),
          name: 'Brand Logo Mark',
          x: 0,
          y: 20,
          width: 36,
          height: 36,
          icon: Icons.all_inclusive_rounded,
          color: Colors.white,
        ),

        // Author Name & Handle
        TextLayer(
          id: UuidGenerator.generate(),
          name: 'Author Name',
          x: 44,
          y: 18,
          width: 200,
          height: 18,
          content: 'Kareem Ehab',
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        TextLayer(
          id: UuidGenerator.generate(),
          name: 'Handle',
          x: 44,
          y: 36,
          width: 200,
          height: 22,
          content: 'kareem.designs_',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ],
    );

    // Slide 1: Cover
    final page1 = CanvasPage(
      id: UuidGenerator.generate(),
      name: '01 - Cover',
      width: 1080,
      height: 1080,
      backgroundType: BackgroundType.gradient,
      backgroundColor: const Color(0xFF090A0D),
      backgroundGradient: const RadialGradient(
        center: Alignment(0.4, -0.6),
        radius: 1.2,
        colors: [
          Color(0xFF2C194D),
          Color(0xFF13141B),
          Color(0xFF090A0D),
        ],
        stops: [0.0, 0.5, 1.0],
      ),
      layers: [
        // Category Label
        TextLayer(
          id: UuidGenerator.generate(),
          name: 'Category Label',
          x: 80,
          y: 80,
          width: 300,
          height: 30,
          content: 'REDESIGN',
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryLight,
          letterSpacing: 2.0,
        ),

        // Headline
        TextLayer(
          id: UuidGenerator.generate(),
          name: 'Heading Line 1',
          x: 80,
          y: 130,
          width: 440,
          height: 70,
          content: 'I redesigned',
          fontSize: 48,
          fontWeight: FontWeight.bold,
          fontFamily: 'Outfit',
          color: Colors.white,
        ),
        TextLayer(
          id: UuidGenerator.generate(),
          name: 'Heading Line 2 (Purple)',
          x: 80,
          y: 200,
          width: 440,
          height: 70,
          content: "Uber's Eats",
          fontSize: 48,
          fontWeight: FontWeight.bold,
          fontFamily: 'Outfit',
          color: AppColors.primary,
        ),
        TextLayer(
          id: UuidGenerator.generate(),
          name: 'Heading Line 3',
          x: 80,
          y: 270,
          width: 440,
          height: 70,
          content: 'screen.',
          fontSize: 48,
          fontWeight: FontWeight.bold,
          fontFamily: 'Outfit',
          color: Colors.white,
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

        // Bullet Checklist 1
        IconLayer(
          id: UuidGenerator.generate(),
          name: 'Check 1',
          x: 80,
          y: 430,
          width: 44,
          height: 44,
          icon: Icons.check_circle_outline_rounded,
          color: AppColors.primary,
        ),
        TextLayer(
          id: UuidGenerator.generate(),
          name: 'Check Text 1',
          x: 136,
          y: 436,
          width: 320,
          height: 36,
          content: 'Clearer hierarchy',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),

        // Bullet Checklist 2
        IconLayer(
          id: UuidGenerator.generate(),
          name: 'Check 2',
          x: 80,
          y: 520,
          width: 44,
          height: 44,
          icon: Icons.check_circle_outline_rounded,
          color: AppColors.primary,
        ),
        TextLayer(
          id: UuidGenerator.generate(),
          name: 'Check Text 2',
          x: 136,
          y: 526,
          width: 320,
          height: 36,
          content: 'Easier choices',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),

        // Bullet Checklist 3
        IconLayer(
          id: UuidGenerator.generate(),
          name: 'Check 3',
          x: 80,
          y: 610,
          width: 44,
          height: 44,
          icon: Icons.check_circle_outline_rounded,
          color: AppColors.primary,
        ),
        TextLayer(
          id: UuidGenerator.generate(),
          name: 'Check Text 3',
          x: 136,
          y: 616,
          width: 320,
          height: 36,
          content: 'Better UX flow',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.white,
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

        // Linked Component Instance: Profile Footer
        ComponentInstanceLayer(
          id: UuidGenerator.generate(),
          name: 'Profile Footer',
          componentDefinitionId: footerComponentId,
          x: 80,
          y: 900,
          width: 440,
          height: 60,
        ),
      ],
    );

    // Slide 2: Problem
    final page2 = CanvasPage(
      id: UuidGenerator.generate(),
      name: '02 - Problem',
      width: 1080,
      height: 1080,
      backgroundType: BackgroundType.solid,
      backgroundColor: const Color(0xFF090A0D),
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
          fill: const Color(0xFF15161B),
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
        ComponentInstanceLayer(
          id: UuidGenerator.generate(),
          name: 'Profile Footer',
          componentDefinitionId: footerComponentId,
          x: 80,
          y: 900,
          width: 440,
          height: 60,
        ),
      ],
    );

    // Slide 3: Conclusion / CTA
    final page3 = CanvasPage(
      id: UuidGenerator.generate(),
      name: '03 - Conclusion',
      width: 1080,
      height: 1080,
      backgroundType: BackgroundType.gradient,
      backgroundColor: const Color(0xFF090A0D),
      backgroundGradient: const RadialGradient(
        center: Alignment(0.0, 0.0),
        radius: 1.0,
        colors: [Color(0xFF2C194D), Color(0xFF090A0D)],
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
        ComponentInstanceLayer(
          id: UuidGenerator.generate(),
          name: 'Profile Footer',
          componentDefinitionId: footerComponentId,
          x: 80,
          y: 900,
          width: 440,
          height: 60,
        ),
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
