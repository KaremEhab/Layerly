import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:layerly/core/constants/app_colors.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_bloc.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_event.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_state.dart';

class PageHeaderBar extends StatelessWidget {
  final VoidCallback? onToggleFullscreen;

  const PageHeaderBar({
    super.key,
    this.onToggleFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditorBloc, EditorState>(
      builder: (context, state) {
        final activePage = state.activePage;
        final activeIndex = state.project.activePageIndex;

        return Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          color: AppColors.background,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Current Page Title
              Text(
                activePage.name,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),

              // Fullscreen & More Actions
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.crop_free_rounded, size: 20),
                    color: AppColors.text,
                    tooltip: 'Fullscreen Editor',
                    onPressed: onToggleFullscreen,
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.more_horiz_rounded, size: 22),
                    color: AppColors.text,
                    tooltip: 'Page Options',
                    onPressed: () => _showPageOptionsSheet(context, activeIndex, state),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPageOptionsSheet(BuildContext context, int pageIndex, EditorState state) {
    final bloc = context.read<EditorBloc>();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Page options',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.copy_rounded, color: AppColors.text, size: 18),
                title: const Text('Duplicate page', style: TextStyle(color: Colors.white, fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  bloc.add(DuplicatePageEvent(pageIndex));
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: AppColors.text, size: 18),
                title: const Text('Rename page', style: TextStyle(color: Colors.white, fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showRenamePageDialog(context, pageIndex, state.project.pages[pageIndex].name);
                },
              ),
              if (state.project.pages.length > 1)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 18),
                  title: const Text('Delete page', style: TextStyle(color: AppColors.danger, fontSize: 14)),
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

  void _showRenamePageDialog(BuildContext context, int pageIndex, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text(
          'Rename page',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceSecondary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<EditorBloc>().add(RenamePageEvent(pageIndex, controller.text.trim()));
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
