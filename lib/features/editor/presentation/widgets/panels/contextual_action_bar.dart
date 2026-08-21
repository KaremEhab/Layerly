import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:layerly/core/constants/app_colors.dart';
import 'package:layerly/features/editor/domain/entities/layer_enums.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_bloc.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_event.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_state.dart';

class ContextualActionBar extends StatelessWidget {
  const ContextualActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditorBloc, EditorState>(
      builder: (context, state) {
        final hasSelection = state.selectedLayers.isNotEmpty;
        final singleSelected = state.singleSelectedLayer;
        final isAutoLayout = singleSelected?.type == LayerType.autoLayout;
        final isLocked = singleSelected?.locked ?? false;
        final isVisible = singleSelected?.visible ?? true;

        return Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          color: Colors.transparent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. Undo Button (Leftmost)
              _buildSquircleButton(
                icon: Icons.undo_rounded,
                tooltip: 'Undo',
                isEnabled: state.canUndo,
                onTap: () => context.read<EditorBloc>().add(const UndoEvent()),
              ),

              // 2. Middle Action Cluster (Duplicate, Visibility, Lock, Layout, Delete)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Duplicate
                  _buildSquircleButton(
                    icon: Icons.copy_rounded,
                    tooltip: 'Duplicate',
                    isEnabled: hasSelection,
                    onTap: () => context.read<EditorBloc>().add(const DuplicateSelectedLayersEvent()),
                  ),
                  const SizedBox(width: 8),

                  // Visibility
                  _buildSquircleButton(
                    icon: isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    tooltip: 'Visibility',
                    isEnabled: hasSelection,
                    onTap: () {
                      if (singleSelected != null) {
                        context.read<EditorBloc>().add(ToggleVisibilityLayerEvent(singleSelected.id));
                      }
                    },
                  ),
                  const SizedBox(width: 8),

                  // Lock
                  _buildSquircleButton(
                    icon: isLocked ? Icons.lock_rounded : Icons.lock_outline_rounded,
                    tooltip: 'Lock Layer',
                    isEnabled: hasSelection,
                    onTap: () {
                      if (singleSelected != null) {
                        context.read<EditorBloc>().add(ToggleLockLayerEvent(singleSelected.id));
                      }
                    },
                  ),
                  const SizedBox(width: 8),

                  // Auto Layout / Link Button
                  _buildLayoutButton(
                    context: context,
                    hasSelection: hasSelection,
                    isAutoLayout: isAutoLayout,
                  ),
                  const SizedBox(width: 8),

                  // Delete
                  _buildSquircleButton(
                    icon: Icons.delete_outline_rounded,
                    tooltip: 'Delete',
                    isEnabled: hasSelection,
                    iconColor: const Color(0xFFF87171),
                    onTap: () => context.read<EditorBloc>().add(const DeleteSelectedLayersEvent()),
                  ),
                ],
              ),

              // 3. Redo Button (Rightmost)
              _buildSquircleButton(
                icon: Icons.redo_rounded,
                tooltip: 'Redo',
                isEnabled: state.canRedo,
                onTap: () => context.read<EditorBloc>().add(const RedoEvent()),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSquircleButton({
    required IconData icon,
    required String tooltip,
    required bool isEnabled,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    final effectiveIconColor = isEnabled
        ? (iconColor ?? Colors.white)
        : (iconColor ?? AppColors.textMuted).withValues(alpha: 0.35);

    final effectiveBgColor = isEnabled
        ? const Color(0xFF1E1A2B)
        : const Color(0xFF161420).withValues(alpha: 0.8);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: effectiveBgColor,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 20,
            color: effectiveIconColor,
          ),
        ),
      ),
    );
  }

  Widget _buildLayoutButton({
    required BuildContext context,
    required bool hasSelection,
    required bool isAutoLayout,
  }) {
    if (!hasSelection) {
      // Disabled / Empty Selection (Image 1)
      return Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFF161420).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.link_off_rounded,
          size: 20,
          color: AppColors.textMuted.withValues(alpha: 0.35),
        ),
      );
    }

    if (isAutoLayout) {
      // Auto Layout Active -> LIT UP WITH PURPLE (Image 2)
      return Tooltip(
        message: 'Remove Auto Layout',
        child: InkWell(
          onTap: () {
            final bloc = context.read<EditorBloc>();
            final single = bloc.state.singleSelectedLayer;
            if (single != null) {
              bloc.add(RemoveAutoLayoutEvent(single.id));
            }
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF241C38),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF9D75F6),
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.link_rounded,
              size: 20,
              color: Color(0xFF9D75F6),
            ),
          ),
        ),
      );
    } else {
      // Non-Layout Item Selected -> Shows link_off in white (Image 3)
      return Tooltip(
        message: 'Create Auto Layout',
        child: InkWell(
          onTap: () {
            context.read<EditorBloc>().add(const CreateAutoLayoutFromSelectionEvent());
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1A2B),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.link_off_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
        ),
      );
    }
  }
}
