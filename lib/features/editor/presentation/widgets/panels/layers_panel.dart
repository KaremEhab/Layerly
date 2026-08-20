import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:layerly/core/constants/app_colors.dart';
import 'package:layerly/features/editor/domain/entities/layer_enums.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_bloc.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_event.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_state.dart';

class LayersPanel extends StatelessWidget {
  const LayersPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditorBloc, EditorState>(
      builder: (context, state) {
        final layers = state.activePageLayers.reversed.toList(); // top layer first

        if (layers.isEmpty) {
          return const Center(
            child: Text(
              'No layers on this page',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          );
        }

        return ReorderableListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 6),
          itemCount: layers.length,
          onReorder: (oldIndex, newIndex) {
            final realNewIndex = state.activePageLayers.length - newIndex;
            final layerId = layers[oldIndex].id;
            context.read<EditorBloc>().add(ReorderLayerEvent(layerId, realNewIndex));
          },
          itemBuilder: (context, index) {
            final layer = layers[index];
            final isSelected = state.selectedLayerIds.contains(layer.id);

            return Container(
              key: ValueKey(layer.id),
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.surfaceElevated : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: isSelected
                    ? Border.all(color: AppColors.primary.withValues(alpha: 0.5))
                    : null,
              ),
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                leading: Icon(
                  _getLayerIcon(layer.type),
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: 16,
                ),
                title: Text(
                  layer.name,
                  style: TextStyle(
                    color: layer.visible ? AppColors.text : AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Lock Button
                    IconButton(
                      icon: Icon(
                        layer.locked ? Icons.lock : Icons.lock_open_rounded,
                        size: 14,
                        color: layer.locked ? AppColors.danger : AppColors.textMuted,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        context
                            .read<EditorBloc>()
                            .add(ToggleLockLayerEvent(layer.id));
                      },
                    ),
                    const SizedBox(width: 8),

                    // Visibility Button
                    IconButton(
                      icon: Icon(
                        layer.visible ? Icons.visibility : Icons.visibility_off,
                        size: 14,
                        color: layer.visible ? AppColors.textSecondary : AppColors.textMuted,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        context
                            .read<EditorBloc>()
                            .add(ToggleVisibilityLayerEvent(layer.id));
                      },
                    ),
                  ],
                ),
                onTap: () {
                  context
                      .read<EditorBloc>()
                      .add(SelectLayerEvent(layer.id, isMultiSelect: false));
                },
              ),
            );
          },
        );
      },
    );
  }

  IconData _getLayerIcon(LayerType type) {
    switch (type) {
      case LayerType.text:
        return Icons.title_rounded;
      case LayerType.shape:
        return Icons.interests_outlined;
      case LayerType.image:
        return Icons.image_outlined;
      case LayerType.deviceMockup:
        return Icons.phone_iphone_rounded;
      case LayerType.icon:
        return Icons.emoji_symbols_rounded;
      case LayerType.group:
        return Icons.folder_outlined;
      case LayerType.componentInstance:
        return Icons.widgets_rounded;
    }
  }
}
