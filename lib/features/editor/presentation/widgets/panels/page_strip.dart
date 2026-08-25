import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:layerly/core/constants/app_colors.dart';
import 'package:layerly/core/utils/uuid_generator.dart';
import 'package:layerly/features/editor/domain/entities/canvas_page.dart';
import 'package:layerly/features/editor/domain/entities/layer_enums.dart';
import 'package:layerly/features/editor/domain/entities/text_layer.dart';
import 'package:layerly/features/editor/domain/entities/shape_layer.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_bloc.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_event.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_state.dart';
import 'package:layerly/core/widgets/app_modal_sheet.dart';
import 'package:layerly/core/widgets/more_rings_icon.dart';

class PageStrip extends StatefulWidget {
  const PageStrip({super.key});

  @override
  State<PageStrip> createState() => _PageStripState();
}

class _PageStripState extends State<PageStrip> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EditorBloc, EditorState>(
      listenWhen: (previous, current) =>
          previous.project.pages.length != current.project.pages.length ||
          previous.project.activePageIndex != current.project.activePageIndex,
      listener: (context, state) {
        // Auto-scroll when active page changes
        if (_scrollController.hasClients) {
          final targetOffset = (state.project.activePageIndex * 110.0).clamp(
            0.0,
            _scrollController.position.maxScrollExtent,
          );
          _scrollController.animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        }
      },
      builder: (context, state) {
        final pages = state.project.pages;
        final activeIndex = state.project.activePageIndex;

        return Container(
          height: 100,
          color: AppColors.background,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            itemCount: pages.length + 1,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              // 0th Item: + Add Slide CTA
              if (index == 0) {
                return _buildAddSlideCard(context);
              }

              final pageIndex = index - 1;
              final page = pages[pageIndex];
              final isActive = pageIndex == activeIndex;
              final displayIndex = (pageIndex + 1).toString().padLeft(2, '0');

              // Clean display name by stripping existing number prefix if any
              String displayName = page.name;
              final regex = RegExp(r'^\d+\s*[-–—]?\s*');
              if (regex.hasMatch(displayName)) {
                displayName = displayName.replaceFirst(regex, '');
              }

              return InkWell(
                onTap: () {
                  context.read<EditorBloc>().add(SelectPageEvent(pageIndex));
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 115,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isActive ? const Color(0xFF8B5CF6) : AppColors.border,
                      width: isActive ? 1.5 : 1.0,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                              blurRadius: 12,
                              spreadRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            displayIndex,
                            style: TextStyle(
                              color: isActive ? const Color(0xFF9E77F6) : AppColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          InkWell(
                            onTap: () => _showSlideOptions(context, pageIndex, pages.length > 1, displayName),
                            child: const MoreRingsIcon(
                              size: 16,
                              color: AppColors.textMuted,
                              ringRadius: 1.9,
                              strokeWidth: 1.3,
                              spacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        displayName,
                        style: TextStyle(
                          color: isActive ? const Color(0xFF9E77F6) : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAddSlideCard(BuildContext context) {
    return InkWell(
      onTap: () => _showAddSlideTemplateSheet(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 88,
        decoration: BoxDecoration(
          color: const Color(0xFF9D75F6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: Color(0xFF1E0E3B), size: 22),
            SizedBox(height: 4),
            Text(
              'Add Slide',
              style: TextStyle(
                color: Color(0xFF1E0E3B),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSlideTemplateSheet(BuildContext context) {
    final bloc = context.read<EditorBloc>();
    showAppModalSheet(
      context: context,
      builder: (ctx) => AppModalSheet(
        icon: Icons.post_add_rounded,
        title: 'New Slide',
        subtitle: 'Choose a preset layout template or start blank',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTemplateCard(ctx, bloc, 'Blank', Icons.crop_portrait_rounded, 'Empty canvas', _createBlankPage),
                _buildTemplateCard(ctx, bloc, 'Redesign', Icons.auto_awesome_rounded, 'App showcase', _createRedesignPage),
                _buildTemplateCard(ctx, bloc, 'Problem', Icons.warning_amber_rounded, 'Pain point spotlight', _createProblemPage),
                _buildTemplateCard(ctx, bloc, 'Solution', Icons.lightbulb_outline_rounded, 'Feature answer', _createSolutionPage),
                _buildTemplateCard(ctx, bloc, 'Comparison', Icons.compare_arrows_rounded, 'Before vs After', _createComparisonPage),
                _buildTemplateCard(ctx, bloc, 'Case Study', Icons.auto_stories_rounded, 'Story breakdown', _createCaseStudyPage),
                _buildTemplateCard(ctx, bloc, 'Conclusion', Icons.task_alt_rounded, 'Summary & CTA', _createConclusionPage),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard(
    BuildContext sheetCtx,
    EditorBloc bloc,
    String label,
    IconData icon,
    String subtitle,
    CanvasPage Function(String name) creator,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(sheetCtx);
        bloc.add(AddPageEvent(page: creator(label)));
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFFA78BFA)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  CanvasPage _createBlankPage(String name) {
    return CanvasPage(
      id: UuidGenerator.generate(),
      name: name,
      width: 1080,
      height: 1080,
      backgroundType: BackgroundType.solid,
      backgroundColor: AppColors.background,
      layers: const [],
    );
  }

  CanvasPage _createRedesignPage(String name) {
    return CanvasPage(
      id: UuidGenerator.generate(),
      name: 'Redesign Screen',
      width: 1080,
      height: 1080,
      backgroundType: BackgroundType.gradient,
      backgroundColor: AppColors.background,
      layers: [
        TextLayer(
          id: UuidGenerator.generate(),
          name: 'Title',
          x: 80,
          y: 120,
          width: 600,
          height: 60,
          content: 'Redesign Breakdown',
          fontSize: 42,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ],
    );
  }

  CanvasPage _createProblemPage(String name) {
    return CanvasPage(
      id: UuidGenerator.generate(),
      name: 'Problem',
      width: 1080,
      height: 1080,
      backgroundType: BackgroundType.solid,
      backgroundColor: AppColors.background,
      layers: [
        TextLayer(
          id: UuidGenerator.generate(),
          name: 'Problem Header',
          x: 80,
          y: 120,
          width: 800,
          height: 60,
          content: 'The Challenge',
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: AppColors.danger,
        ),
      ],
    );
  }

  CanvasPage _createSolutionPage(String name) {
    return CanvasPage(
      id: UuidGenerator.generate(),
      name: 'Solution',
      width: 1080,
      height: 1080,
      backgroundType: BackgroundType.solid,
      backgroundColor: AppColors.background,
      layers: [
        TextLayer(
          id: UuidGenerator.generate(),
          name: 'Solution Header',
          x: 80,
          y: 120,
          width: 800,
          height: 60,
          content: 'The Solution',
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: AppColors.success,
        ),
      ],
    );
  }

  CanvasPage _createComparisonPage(String name) {
    return CanvasPage(
      id: UuidGenerator.generate(),
      name: 'Before & After',
      width: 1080,
      height: 1080,
      backgroundType: BackgroundType.solid,
      backgroundColor: AppColors.background,
      layers: [
        ShapeLayer(
          id: UuidGenerator.generate(),
          name: 'Before Card',
          x: 80,
          y: 200,
          width: 420,
          height: 600,
          fill: AppColors.surface,
          cornerRadius: 16,
        ),
        ShapeLayer(
          id: UuidGenerator.generate(),
          name: 'After Card',
          x: 580,
          y: 200,
          width: 420,
          height: 600,
          fill: AppColors.surface,
          cornerRadius: 16,
        ),
      ],
    );
  }

  CanvasPage _createCaseStudyPage(String name) {
    return CanvasPage(
      id: UuidGenerator.generate(),
      name: 'Case Study',
      width: 1080,
      height: 1080,
      backgroundType: BackgroundType.solid,
      backgroundColor: AppColors.background,
    );
  }

  CanvasPage _createConclusionPage(String name) {
    return CanvasPage(
      id: UuidGenerator.generate(),
      name: 'Conclusion',
      width: 1080,
      height: 1080,
      backgroundType: BackgroundType.gradient,
      backgroundColor: AppColors.background,
    );
  }

  void _showSlideOptions(BuildContext context, int pageIndex, bool canDelete, String slideName) {
    final bloc = context.read<EditorBloc>();
    showAppModalSheet(
      context: context,
      builder: (ctx) => AppModalSheet(
        icon: Icons.layers_rounded,
        title: 'Slide Options',
        subtitle: slideName,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSheetActionTile(
              icon: Icons.copy_rounded,
              iconColor: const Color(0xFFA78BFA),
              title: 'Duplicate Slide',
              subtitle: 'Create an exact copy right after this slide',
              onTap: () {
                Navigator.pop(ctx);
                bloc.add(DuplicatePageEvent(pageIndex));
              },
            ),
            if (canDelete) ...[
              const SizedBox(height: 6),
              AppSheetActionTile(
                icon: Icons.delete_outline_rounded,
                isDestructive: true,
                title: 'Delete Slide',
                subtitle: 'Permanently remove this slide from project',
                onTap: () {
                  Navigator.pop(ctx);
                  bloc.add(DeletePageEvent(pageIndex));
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
