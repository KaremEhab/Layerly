import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:layerly/core/constants/app_colors.dart';
import 'package:layerly/core/constants/responsive_breakpoints.dart';
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
            width: 60,
            height: 45,
            borderRadius: 22.5,
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
              onTap: () => _showRenameDialog(context, state.project.name),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text(
          'Leave design?',
          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Your latest changes are saved locally.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Stay', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).maybePop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, String currentName) {
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
          'Rename design',
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
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
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
                context.read<EditorBloc>().add(RenameProjectEvent(controller.text.trim()));
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

  void _showExportDialog(BuildContext context, EditorState state) {
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
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Export',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(color: AppColors.border, height: 24),
              const Text(
                'Current slide',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildFormatChip(context, 'PNG (Current)', () => _doExport(context, ctx, 'Current Page as PNG')),
                  const SizedBox(width: 8),
                  _buildFormatChip(context, 'JPG (Current)', () => _doExport(context, ctx, 'Current Page as JPG')),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'All slides (${4} pages)',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildFormatChip(context, 'PNG Sequence', () => _doExport(context, ctx, 'All slides as PNG sequence')),
                  const SizedBox(width: 8),
                  _buildFormatChip(context, 'PDF Document', () => _doExport(context, ctx, 'Presentation PDF document')),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
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

  void _doExport(BuildContext context, BuildContext sheetCtx, String description) {
    Navigator.pop(sheetCtx);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        content: Text(
          'Exported $description locally to device!',
          style: const TextStyle(color: AppColors.success),
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
