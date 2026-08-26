import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_modal_sheet.dart';
import '../../../editor/data/project_storage_service.dart';
import '../../../editor/domain/entities/canvas_project.dart';
import 'project_cover_thumbnail.dart';

/// Interactive modal sheet to pick which slide will be used as the project's cover.
class CoverSlidePickerSheet extends StatelessWidget {
  final CanvasProject project;
  final ValueChanged<int>? onCoverSelected;

  const CoverSlidePickerSheet({
    super.key,
    required this.project,
    this.onCoverSelected,
  });

  static Future<int?> show(BuildContext context, CanvasProject project) {
    return showAppModalSheet<int>(
      context: context,
      builder: (ctx) => CoverSlidePickerSheet(
        project: project,
        onCoverSelected: (index) => Navigator.pop(ctx, index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = project.pages;

    return AppModalSheet(
      icon: Icons.star_rounded,
      iconGradient: const LinearGradient(
        colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
      ),
      title: 'Pick Project Cover',
      subtitle: 'Choose which slide appears as the thumbnail on Home Page',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (pages.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'No slides available in this project.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                itemCount: pages.length,
                separatorBuilder: (context, index) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final page = pages[index];
                  final isCurrentCover = index == project.coverPageIndex;
                  final displayNum = (index + 1).toString().padLeft(2, '0');

                  return InkWell(
                    onTap: () async {
                      final updated = project.copyWith(
                        coverPageIndex: index,
                        updatedAt: DateTime.now(),
                      );
                      await ProjectStorageService.instance.saveProject(updated);
                      onCoverSelected?.call(index);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 150,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isCurrentCover
                              ? const Color(0xFFFBBF24)
                              : Colors.white.withValues(alpha: 0.1),
                          width: isCurrentCover ? 2.0 : 1.0,
                        ),
                        boxShadow: isCurrentCover
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFFBBF24).withValues(alpha: 0.25),
                                  blurRadius: 14,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Thumbnail Preview
                          Expanded(
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: ProjectCoverThumbnail(
                                    project: project.copyWith(coverPageIndex: index),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                if (isCurrentCover)
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFBBF24),
                                        borderRadius: BorderRadius.circular(6),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.4),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.star_rounded, size: 10, color: Colors.black),
                                          SizedBox(width: 2),
                                          Text(
                                            'COVER',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Slide label
                          Row(
                            children: [
                              Text(
                                '$displayNum.',
                                style: TextStyle(
                                  color: isCurrentCover
                                      ? const Color(0xFFFBBF24)
                                      : AppColors.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  page.name,
                                  style: TextStyle(
                                    color: isCurrentCover
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: isCurrentCover
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
