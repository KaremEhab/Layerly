import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../editor/domain/entities/canvas_page.dart';
import '../../../editor/domain/entities/canvas_project.dart';
import '../../../editor/domain/entities/layer_enums.dart';
import '../../../editor/presentation/widgets/canvas/page_renderer.dart';

/// Renders a live, pixel-accurate vector & layer preview of a project's cover slide.
class ProjectCoverThumbnail extends StatelessWidget {
  final CanvasProject project;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const ProjectCoverThumbnail({
    super.key,
    required this.project,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final coverPage = project.coverPage;
    final radius = borderRadius ?? BorderRadius.circular(14);

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.canvasBackground,
          borderRadius: radius,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background fallback texture
            _buildPageBackground(coverPage),

            // Live rendered canvas page
            FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: coverPage.width,
                height: coverPage.height,
                child: PageRenderer(
                  page: coverPage,
                  selectedLayerIds: const [],
                  // Non-interactive thumbnail mode
                  onSelectLayer: null,
                  onMoveLayer: null,
                  onResizeLayer: null,
                  onRotateLayer: null,
                  onContextMenu: null,
                ),
              ),
            ),

            // Subtle inner vignette border for premium finish
            Container(
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageBackground(CanvasPage page) {
    Decoration decoration;
    switch (page.backgroundType) {
      case BackgroundType.solid:
        decoration = BoxDecoration(color: page.backgroundColor);
        break;
      case BackgroundType.gradient:
        decoration = BoxDecoration(
          gradient: page.backgroundGradient ??
              const RadialGradient(
                center: Alignment(0.4, -0.6),
                radius: 1.2,
                colors: [Color(0xFF2C194D), Color(0xFF13141B), Color(0xFF0D0B14)],
              ),
        );
        break;
      case BackgroundType.image:
        decoration = BoxDecoration(
          color: page.backgroundColor,
          image: page.backgroundImagePath != null
              ? DecorationImage(
                  image: AssetImage(page.backgroundImagePath!),
                  fit: BoxFit.cover,
                )
              : null,
        );
        break;
      case BackgroundType.transparent:
        decoration = const BoxDecoration(color: Colors.transparent);
        break;
    }

    return Container(decoration: decoration);
  }
}
