import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:layerly/core/constants/app_colors.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_bloc.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_event.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_state.dart';
import 'package:layerly/features/editor/presentation/widgets/canvas/page_renderer.dart';

class FullscreenCanvasView extends StatefulWidget {
  final VoidCallback onExitFullscreen;

  const FullscreenCanvasView({
    super.key,
    required this.onExitFullscreen,
  });

  @override
  State<FullscreenCanvasView> createState() => _FullscreenCanvasViewState();
}

class _FullscreenCanvasViewState extends State<FullscreenCanvasView> {
  bool _showToast = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      body: BlocBuilder<EditorBloc, EditorState>(
        builder: (context, state) {
          final activeIndex = state.project.activePageIndex;
          final pages = state.project.pages;
          final activePage = state.activePage;

          return Stack(
            children: [
              // Dot Grid Background
              Positioned.fill(
                child: CustomPaint(
                  painter: _DotGridPainter(),
                ),
              ),

              // Centered Interactive Design Viewport (Preview Only)
              Positioned.fill(
                top: 100,
                bottom: 80,
                left: 16,
                right: 16,
                child: InteractiveViewer(
                  minScale: 0.2,
                  maxScale: 4.0,
                  clipBehavior: Clip.none,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Container(
                        width: activePage.width,
                        height: activePage.height,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.7),
                              blurRadius: 40,
                              spreadRadius: 8,
                              offset: const Offset(0, 14),
                            ),
                            BoxShadow(
                              color: const Color(0xFFA970FF).withValues(alpha: 0.15),
                              blurRadius: 60,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: IgnorePointer(
                            child: PageRenderer(
                              page: activePage,
                              selectedLayerIds: const [],
                              activeGuides: const [],
                              activeSpacingMeasurements: const [],
                              scale: 1.0,
                              getComponentDefinition: (id) =>
                                  state.getComponentDefinition(id),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Top Floating Control Bar
              Positioned(
                top: 48,
                left: 16,
                right: 16,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 460;
                    final isVeryCompact = constraints.maxWidth < 360;

                    return Row(
                      children: [
                        // Left: Preview Mode Pill Badge
                        Container(
                          height: 40,
                          padding: EdgeInsets.symmetric(horizontal: isCompact ? 10 : 12),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.visibility_rounded, color: AppColors.primary, size: 16),
                              if (!isVeryCompact) ...[
                                const SizedBox(width: 6),
                                Text(
                                  isCompact ? 'Preview' : 'Preview Mode',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Center: Page Navigator Pill (Flexible & Truncating)
                        Expanded(
                          child: Center(
                            child: Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surface.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.chevron_left_rounded, size: 18),
                                    color: activeIndex > 0 ? Colors.white : AppColors.textMuted,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                    onPressed: activeIndex > 0
                                        ? () => context.read<EditorBloc>().add(SelectPageEvent(activeIndex - 1))
                                        : null,
                                  ),
                                  Flexible(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Text(
                                        '${activePage.name} (${activeIndex + 1}/${pages.length})',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right_rounded, size: 18),
                                    color: activeIndex < pages.length - 1 ? Colors.white : AppColors.textMuted,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                    onPressed: activeIndex < pages.length - 1
                                        ? () => context.read<EditorBloc>().add(SelectPageEvent(activeIndex + 1))
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Right: Close Fullscreen / Exit Preview
                        Tooltip(
                          message: 'Exit Preview',
                          child: InkWell(
                            onTap: widget.onExitFullscreen,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.surface.withValues(alpha: 0.92),
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Bottom Toast / Hint (Overflow-Safe)
              if (_showToast)
                Positioned(
                  bottom: 30,
                  left: 20,
                  right: 20,
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.touch_app_rounded, color: AppColors.primary, size: 15),
                          const SizedBox(width: 8),
                          const Flexible(
                            child: Text(
                              'Preview Only — Pan & zoom to inspect',
                              style: TextStyle(
                                color: AppColors.text,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => setState(() => _showToast = false),
                            child: const Icon(Icons.close, color: AppColors.textMuted, size: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.canvasDot.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    const double spacing = 28.0;
    const double radius = 1.2;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
