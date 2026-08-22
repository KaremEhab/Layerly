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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1B1927),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF2C283F), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'Create new slide',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildTemplateChip(ctx, bloc, 'Blank', _createBlankPage),
                  _buildTemplateChip(ctx, bloc, 'Redesign', _createRedesignPage),
                  _buildTemplateChip(ctx, bloc, 'Problem', _createProblemPage),
                  _buildTemplateChip(ctx, bloc, 'Solution', _createSolutionPage),
                  _buildTemplateChip(ctx, bloc, 'Comparison', _createComparisonPage),
                  _buildTemplateChip(ctx, bloc, 'Case Study', _createCaseStudyPage),
                  _buildTemplateChip(ctx, bloc, 'Conclusion', _createConclusionPage),
                  _buildTemplateChip(ctx, bloc, 'Custom', _createBlankPage),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateChip(
    BuildContext sheetCtx,
    EditorBloc bloc,
    String label,
    CanvasPage Function(String name) creator,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(sheetCtx);
        bloc.add(AddPageEvent(page: creator(label)));
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: const TextStyle(color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w600),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1B1927),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF2C283F), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  'Slide options ($slideName)',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ListTile(
              leading: const Icon(Icons.copy_rounded, color: Colors.white, size: 18),
              title: const Text('Duplicate slide', style: TextStyle(color: Colors.white, fontSize: 13)),
              onTap: () {
                Navigator.pop(ctx);
                bloc.add(DuplicatePageEvent(pageIndex));
              },
            ),
            if (canDelete)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 18),
                title: const Text('Delete slide', style: TextStyle(color: AppColors.danger, fontSize: 13)),
                onTap: () {
                  Navigator.pop(ctx);
                  bloc.add(DeletePageEvent(pageIndex));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
