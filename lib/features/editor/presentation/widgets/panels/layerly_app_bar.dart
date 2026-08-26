import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:layerly/core/constants/app_colors.dart';
import 'package:layerly/core/constants/responsive_breakpoints.dart';
import 'package:layerly/core/widgets/app_dialog.dart';
import 'package:layerly/core/widgets/app_modal_sheet.dart';
import 'package:layerly/core/widgets/glass_popup_menu.dart';
import 'package:layerly/features/editor/domain/services/export_service.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_bloc.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_event.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_state.dart';

class LayerlyAppBar extends StatelessWidget {
  final VoidCallback? onHome;
  final VoidCallback? onExport;

  const LayerlyAppBar({
    super.key,
    this.onHome,
    this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    return BlocBuilder<EditorBloc, EditorState>(
      builder: (context, state) {
        if (isMobile) {
          return _buildMobileAppBar(context, state);
        } else {
          return _buildDesktopAppBar(context, state);
        }
      },
    );
  }

  Widget _buildMobileAppBar(BuildContext context, EditorState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Home Icon Pill (60 x 45)
          _buildGlassButton(
            width: 50,
            height: 50,
            borderRadius: 25,
            onTap: onHome ?? () => _showLeaveConfirmDialog(context),
            child: const Icon(
              Icons.home_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),

          const SizedBox(width: 20),

          // Center: Layerly + Project Name (Takes rest of screen, Height 50)
          Expanded(
            child: _buildGlassButton(
              height: 50,
              borderRadius: 25,
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Layerly',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Flexible(
                      child: GlassPopupMenuButton<String>(
                        width: 240,
                        onSelected: (val) {
                          switch (val) {
                            case 'rename':
                              _showRenameDialog(context, state.project.name);
                              break;
                            case 'export':
                              if (onExport != null) {
                                onExport!();
                              } else {
                                _showExportDialog(context, state);
                              }
                              break;
                            case 'home':
                              if (onHome != null) {
                                onHome!();
                              } else {
                                _showLeaveConfirmDialog(context);
                              }
                              break;
                          }
                        },
                        itemBuilder: (ctx) => [
                          GlassMenuHeader<String>(
                            title: state.project.name,
                            icon: Icons.design_services_rounded,
                          ),
                          const GlassMenuDivider<String>(),
                          const GlassMenuItem<String>(
                            value: 'rename',
                            title: 'Rename Project',
                            subtitle: 'Change project title',
                            icon: Icons.edit_rounded,
                            iconColor: Color(0xFFA78BFA),
                            iconBackgroundColor: Color(0x338B5CF6),
                          ),
                          const GlassMenuItem<String>(
                            value: 'export',
                            title: 'Export Design',
                            subtitle: 'Download PNG / JPG / PDF',
                            icon: Icons.file_download_outlined,
                            iconColor: Color(0xFF38BDF8),
                            iconBackgroundColor: Color(0x3338BDF8),
                          ),
                          const GlassMenuDivider<String>(),
                          const GlassMenuItem<String>(
                            value: 'home',
                            title: 'Back to Home',
                            subtitle: 'Return to dashboard',
                            icon: Icons.home_rounded,
                            iconColor: Color(0xFF94A3B8),
                            iconBackgroundColor: Color(0x3394A3B8),
                          ),
                        ],
                        child: Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF241A3E).withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.75),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  state.project.name.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 20),

          // Right: Export Download Button (60 x 45)
          _buildGlassButton(
            width: 60,
            height: 45,
            borderRadius: 22.5,
            onTap: onExport ?? () => _showExportDialog(context, state),
            child: const Icon(
              Icons.file_download_outlined,
              color: Color(0xFFA881FF),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton({
    double? width,
    required double height,
    required double borderRadius,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(borderRadius),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF282136).withValues(alpha: 0.65),
                  const Color(0xFF14111E).withValues(alpha: 0.55),
                ],
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.16),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Top Specular Highlight Arc
                Positioned(
                  top: 0,
                  left: borderRadius / 2,
                  right: borderRadius / 2,
                  height: 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.35),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                Center(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopAppBar(BuildContext context, EditorState state) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left side items
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Home
                      InkWell(
                        onTap: onHome ?? () => _showLeaveConfirmDialog(context),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(Icons.home_outlined, size: 16, color: AppColors.text),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Brand Logo
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
                            Icon(Icons.layers_rounded, color: Colors.white, size: 14),
                            SizedBox(width: 6),
                            Text(
                              'LAYERLY',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Editable Project Name
                      InkWell(
                        onTap: () => _showRenameDialog(context, state.project.name),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Row(
                            children: [
                              Text(
                                state.project.name,
                                style: const TextStyle(
                                  color: AppColors.text,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.edit_outlined, size: 12, color: AppColors.textMuted),
                            ],
                          ),
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
                    ],
                  ),

                  const SizedBox(width: 24),

                  // Right side items
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                        tooltip: 'Redo (Ctrl+Shift+Z)',
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
                          context.read<EditorBloc>().add(const SetZoomEvent(0.55));
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
                        icon: const Icon(Icons.file_download_outlined, size: 16),
                        label: const Text('Export'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
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
    );
  }

  void _showLeaveConfirmDialog(BuildContext context) {
    showAppDialog(
      context: context,
      builder: (ctx) => AppDialog(
        icon: Icons.exit_to_app_rounded,
        title: 'Leave design?',
        subtitle: 'Return to your projects hub',
        confirmLabel: 'Leave',
        onConfirm: () {
          Navigator.pop(ctx);
          Navigator.of(context).maybePop();
        },
        content: const Text(
          'Your latest changes are safely saved in local storage.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);
    showAppDialog(
      context: context,
      builder: (ctx) => AppDialog(
        icon: Icons.edit_note_rounded,
        title: 'Rename design',
        subtitle: 'Update project title',
        confirmLabel: 'Save',
        onConfirm: () {
          if (controller.text.trim().isNotEmpty) {
            context.read<EditorBloc>().add(RenameProjectEvent(controller.text.trim()));
          }
          Navigator.pop(ctx);
        },
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceSecondary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  void _showExportDialog(BuildContext context, EditorState state) {
    showAppModalSheet(
      context: context,
      builder: (ctx) => AppModalSheet(
        icon: Icons.file_upload_outlined,
        title: 'Export Studio',
        subtitle: 'Save high-res renders to Photos or share',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current slide',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildFormatChip(
                  context,
                  'PNG (Photos)',
                  () => _exportCurrentPage(context, ctx, state, ExportImageFormat.png),
                ),
                const SizedBox(width: 8),
                _buildFormatChip(
                  context,
                  'JPG (Photos)',
                  () => _exportCurrentPage(context, ctx, state, ExportImageFormat.jpg),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'All slides (${state.project.pages.length} pages)',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildFormatChip(
                  context,
                  'All to Photos',
                  () => _exportAllPages(context, ctx, state, ExportImageFormat.png),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatChip(BuildContext context, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  void _exportCurrentPage(
    BuildContext context,
    BuildContext sheetCtx,
    EditorState state,
    ExportImageFormat format,
  ) async {
    Navigator.pop(sheetCtx);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        duration: Duration(seconds: 2),
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
            SizedBox(width: 12),
            Text('Saving design to Photos (Layerly album)...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );

    final result = await ExportService.exportPageToGallery(
      page: state.activePage,
      project: state.project,
      format: format,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        content: Row(
          children: [
            Icon(
              result.success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              color: result.success ? AppColors.success : Colors.redAccent,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                result.message ?? (result.success ? 'Saved to Photos!' : 'Export failed'),
                style: TextStyle(
                  color: result.success ? AppColors.success : Colors.redAccent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _exportAllPages(
    BuildContext context,
    BuildContext sheetCtx,
    EditorState state,
    ExportImageFormat format,
  ) async {
    Navigator.pop(sheetCtx);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        duration: Duration(seconds: 4),
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
            SizedBox(width: 12),
            Text('Saving all slides to Photos (Layerly album)...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );

    final result = await ExportService.exportAllPagesToGallery(
      project: state.project,
      format: format,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        content: Row(
          children: [
            Icon(
              result.success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              color: result.success ? AppColors.success : Colors.redAccent,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                result.message ?? (result.success ? 'Saved all slides to Photos!' : 'Export failed'),
                style: TextStyle(
                  color: result.success ? AppColors.success : Colors.redAccent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
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
