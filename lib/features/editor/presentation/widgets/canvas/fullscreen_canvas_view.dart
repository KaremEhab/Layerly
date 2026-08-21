import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:layerly/core/constants/app_colors.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_bloc.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_event.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_state.dart';
import 'package:layerly/features/editor/presentation/widgets/canvas/editor_canvas.dart';

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
      backgroundColor: AppColors.background,
      body: BlocBuilder<EditorBloc, EditorState>(
        builder: (context, state) {
          final activeIndex = state.project.activePageIndex;
          final pages = state.project.pages;
          final activePage = state.activePage;

          return Stack(
            children: [
              // Clean Infinite Canvas
              const Positioned.fill(
                child: EditorCanvas(isLockedTop: false),
              ),

              // Top Floating Control Bar
              Positioned(
                top: 48,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left: Add / Tool CTA
                    InkWell(
                      onTap: () {
                        context.read<EditorBloc>().add(const AddPageEvent());
                      },
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 22),
                      ),
                    ),

                    // Center: Page Navigator Pill ‹ Page Name ›
                    Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded, size: 20),
                            color: activeIndex > 0 ? Colors.white : AppColors.textMuted,
                            onPressed: activeIndex > 0
                                ? () => context.read<EditorBloc>().add(SelectPageEvent(activeIndex - 1))
                                : null,
                          ),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 160),
                            child: Text(
                              activePage.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded, size: 20),
                            color: activeIndex < pages.length - 1 ? Colors.white : AppColors.textMuted,
                            onPressed: activeIndex < pages.length - 1
                                ? () => context.read<EditorBloc>().add(SelectPageEvent(activeIndex + 1))
                                : null,
                          ),
                        ],
                      ),
                    ),

                    // Right: Close Fullscreen / Options
                    InkWell(
                      onTap: widget.onExitFullscreen,
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Toast / Hint
              if (_showToast)
                Positioned(
                  bottom: 36,
                  left: 24,
                  right: 24,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(24),
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
                          const Text(
                            'You can move in canvas freely.',
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 14),
                          InkWell(
                            onTap: () => setState(() => _showToast = false),
                            child: const Icon(Icons.close, color: AppColors.danger, size: 16),
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
