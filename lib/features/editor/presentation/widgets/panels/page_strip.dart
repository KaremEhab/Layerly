import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:layerly/core/constants/app_colors.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_bloc.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_event.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_state.dart';

class PageStrip extends StatelessWidget {
  const PageStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditorBloc, EditorState>(
      builder: (context, state) {
        final pages = state.project.pages;
        final activeIndex = state.project.activePageIndex;

        return Container(
          height: 80,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              // Page List
              Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: pages.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final page = pages[index];
                    final isActive = index == activeIndex;

                    return InkWell(
                      onTap: () {
                        context.read<EditorBloc>().add(SelectPageEvent(index));
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 100,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isActive ? AppColors.primary : AppColors.border,
                            width: isActive ? 2.0 : 1.0,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '0${index + 1}',
                                  style: TextStyle(
                                    color: isActive ? AppColors.primary : AppColors.textMuted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    _showSlideOptions(context, index, pages.length > 1);
                                  },
                                  borderRadius: BorderRadius.circular(4),
                                  child: const Icon(Icons.more_horiz, size: 14, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                            Text(
                              page.name,
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
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
              ),

              const SizedBox(width: 12),
              // Add Page Button
              InkWell(
                onTap: () {
                  context.read<EditorBloc>().add(const AddPageEvent());
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 74,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, color: AppColors.primary, size: 18),
                      SizedBox(height: 2),
                      Text(
                        'Add Slide',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSlideOptions(BuildContext context, int index, bool canDelete) {
    final bloc = context.read<EditorBloc>();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.copy_rounded, color: Colors.white, size: 18),
              title: const Text('Duplicate Slide', style: TextStyle(color: Colors.white, fontSize: 13)),
              onTap: () {
                Navigator.pop(ctx);
                bloc.add(DuplicatePageEvent(index));
              },
            ),
            if (canDelete)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 18),
                title: const Text('Delete Slide', style: TextStyle(color: AppColors.danger, fontSize: 13)),
                onTap: () {
                  Navigator.pop(ctx);
                  bloc.add(DeletePageEvent(index));
                },
              ),
          ],
        ),
      ),
    );
  }
}
