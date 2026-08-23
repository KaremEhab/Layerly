import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:layerly/core/constants/app_colors.dart';
import 'package:layerly/features/editor/domain/services/export_service.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_bloc.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_event.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_state.dart';

class TopToolbar extends StatelessWidget {
  final VoidCallback? onPreview;
  final VoidCallback? onExport;

  const TopToolbar({
    super.key,
    this.onPreview,
    this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditorBloc, EditorState>(
      builder: (context, state) {
        return Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Studio Logo / Brand
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.layers_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'LAYERLY',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Project Name
                Text(
                  state.project.name,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    'Offline Studio',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                  ),
                ),

                const SizedBox(width: 20),

                // Undo / Redo
                IconButton(
                  icon: const Icon(Icons.undo_rounded, size: 18),
                  color: state.canUndo ? AppColors.text : AppColors.textMuted,
                  tooltip: 'Undo (Ctrl+Z)',
                  onPressed: state.canUndo
                      ? () => context.read<EditorBloc>().add(const UndoEvent())
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.redo_rounded, size: 18),
                  color: state.canRedo ? AppColors.text : AppColors.textMuted,
                  tooltip: 'Redo (Ctrl+Y)',
                  onPressed: state.canRedo
                      ? () => context.read<EditorBloc>().add(const RedoEvent())
                      : null,
                ),
                const SizedBox(width: 8),
                const _ToolbarDivider(),
                const SizedBox(width: 8),

                // Zoom Controls
                IconButton(
                  icon: const Icon(Icons.remove, size: 16),
                  color: AppColors.textSecondary,
                  tooltip: 'Zoom Out',
                  onPressed: () {
                    context.read<EditorBloc>().add(SetZoomEvent(state.zoom - 0.1));
                  },
                ),
                InkWell(
                  onTap: () {
                    context.read<EditorBloc>().add(const SetZoomEvent(0.6));
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Text(
                      '${(state.zoom * 100).toInt()}%',
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 16),
                  color: AppColors.textSecondary,
                  tooltip: 'Zoom In',
                  onPressed: () {
                    context.read<EditorBloc>().add(SetZoomEvent(state.zoom + 0.1));
                  },
                ),

                const SizedBox(width: 8),
                const _ToolbarDivider(),
                const SizedBox(width: 8),

                // Grid Toggle
                IconButton(
                  icon: Icon(
                    Icons.grid_on_rounded,
                    size: 18,
                    color: state.showGrid ? AppColors.primary : AppColors.textSecondary,
                  ),
                  tooltip: 'Toggle Grid',
                  onPressed: () {
                    context.read<EditorBloc>().add(const ToggleGridEvent());
                  },
                ),

                // Smart Guides Toggle
                IconButton(
                  icon: Icon(
                    Icons.align_horizontal_left_rounded,
                    size: 18,
                    color: state.snapEnabled ? AppColors.primary : AppColors.textSecondary,
                  ),
                  tooltip: 'Toggle Smart Snapping',
                  onPressed: () {
                    context.read<EditorBloc>().add(const ToggleSnapEvent());
                  },
                ),

                const SizedBox(width: 14),

                // Export Button
                ElevatedButton.icon(
                  onPressed: onExport ?? () => _showExportDialog(context, state),
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Export'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showExportDialog(BuildContext context, EditorState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Row(
          children: [
            Icon(Icons.photo_library_rounded, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Export to Photos', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Save design slides directly to your phone\'s Photo Gallery.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            _buildExportOption(
              icon: Icons.image_rounded,
              title: 'Current Slide (PNG)',
              subtitle: '${state.activePage.width.round()} × ${state.activePage.height.round()} (High Resolution)',
              onTap: () async {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.surfaceElevated,
                    content: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        ),
                        SizedBox(width: 12),
                        Text('Saving to Photos (Layerly album)...', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                );

                final res = await ExportService.exportPageToGallery(
                  page: state.activePage,
                  project: state.project,
                );

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.surfaceElevated,
                    content: Row(
                      children: [
                        Icon(
                          res.success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                          color: res.success ? AppColors.success : Colors.redAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            res.message ?? (res.success ? 'Saved to Photos!' : 'Export failed'),
                            style: TextStyle(
                              color: res.success ? AppColors.success : Colors.redAccent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _buildExportOption(
              icon: Icons.collections_rounded,
              title: 'All Slides (${state.project.pages.length} Pages)',
              subtitle: 'Save entire carousel to Photos album',
              onTap: () async {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.surfaceElevated,
                    content: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        ),
                        SizedBox(width: 12),
                        Text('Saving all slides to Photos...', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                );

                final res = await ExportService.exportAllPagesToGallery(
                  project: state.project,
                );

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.surfaceElevated,
                    content: Row(
                      children: [
                        Icon(
                          res.success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                          color: res.success ? AppColors.success : Colors.redAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            res.message ?? (res.success ? 'Saved all slides to Photos!' : 'Export failed'),
                            style: TextStyle(
                              color: res.success ? AppColors.success : Colors.redAccent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 20,
      color: AppColors.border,
    );
  }
}
