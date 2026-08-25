import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:layerly/core/constants/app_colors.dart';
import 'package:layerly/features/editor/domain/entities/layer.dart';
import 'package:layerly/features/editor/domain/entities/layer_enums.dart';
import 'package:layerly/features/editor/domain/entities/auto_layout_layer.dart';
import 'package:layerly/features/editor/domain/entities/text_layer.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_bloc.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_event.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_state.dart';

class LayersPanel extends StatefulWidget {
  const LayersPanel({super.key});

  @override
  State<LayersPanel> createState() => _LayersPanelState();
}

class _LayersPanelState extends State<LayersPanel> {
  // Set of layer IDs that are expanded in the tree view (default open)
  final Set<String> _expandedLayerIds = <String>{};
  bool _isMultiSelectMode = false;
  bool _initialized = false;

  void _expandAllAutoLayouts(List<Layer> layers) {
    for (final l in layers) {
      if (l is AutoLayoutLayer && l.children.isNotEmpty) {
        _expandedLayerIds.add(l.id);
        _expandAllAutoLayouts(l.children);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditorBloc, EditorState>(
      builder: (context, state) {
        final layers = state.activePageLayers;
        final selectedCount = state.selectedLayerIds.length;
        final isMultiActive = _isMultiSelectMode || selectedCount > 1;

        // Auto-expand all AutoLayout layers on first load
        if (!_initialized) {
          _expandAllAutoLayouts(layers);
          _initialized = true;
        }

        if (layers.isEmpty) {
          return const Center(
            child: Text(
              'No layers on this page',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          );
        }

        return Column(
          children: [
            // Top Toolbar: Multi-select pill & Quick actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  // Multi-select toggle button
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isMultiSelectMode = !_isMultiSelectMode;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isMultiActive
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isMultiActive
                              ? AppColors.primary
                              : AppColors.border,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isMultiActive
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded,
                            size: 14,
                            color: isMultiActive ? AppColors.primary : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isMultiActive
                                ? 'Multi-Select ($selectedCount)'
                                : 'Select Multiple',
                            style: TextStyle(
                              color: isMultiActive ? Colors.white : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Quick Auto Layout Group button when 2+ selected
                  if (selectedCount > 1)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.link_rounded, size: 14),
                      label: const Text('Group Layout', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        context.read<EditorBloc>().add(const CreateAutoLayoutFromSelectionEvent());
                      },
                    ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.border),

            // Layers Tree List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                itemCount: layers.length + 1,
                itemBuilder: (context, index) {
                  if (index == layers.length) {
                    return _buildDropSlot(
                      context,
                      targetParentId: null,
                      targetIndex: layers.length,
                    );
                  }

                  final layer = layers[index];
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDropSlot(
                        context,
                        targetParentId: null,
                        targetIndex: index,
                      ),
                      if (layer is AutoLayoutLayer && layer.children.isNotEmpty)
                        _buildAutoLayoutTreeNode(
                          context,
                          state,
                          layer,
                          index: index,
                          totalCount: layers.length,
                          isMultiMode: isMultiActive,
                        )
                      else
                        _buildStandardLayerTile(
                          context,
                          state,
                          layer,
                          index: index,
                          totalCount: layers.length,
                          isMultiMode: isMultiActive,
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  bool _isDescendant(Layer parent, String targetId) {
    if (parent.id == targetId) return true;
    if (parent is AutoLayoutLayer) {
      for (final child in parent.children) {
        if (_isDescendant(child, targetId)) return true;
      }
    }
    return false;
  }

  // Drop Slot indicator between items
  Widget _buildDropSlot(
    BuildContext context, {
    required String? targetParentId,
    required int targetIndex,
  }) {
    return DragTarget<Layer>(
      onWillAcceptWithDetails: (details) {
        if (targetParentId != null && _isDescendant(details.data, targetParentId)) {
          return false;
        }
        return details.data.id != targetParentId;
      },
      onAcceptWithDetails: (details) {
        context.read<EditorBloc>().add(MoveLayerTreeEvent(
              layerId: details.data.id,
              targetParentId: targetParentId,
              targetIndex: targetIndex,
            ));
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: isHovered ? 16 : 8,
          margin: const EdgeInsets.symmetric(vertical: 1),
          alignment: Alignment.center,
          child: isHovered
              ? Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0D99FF),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 2.5,
                        color: const Color(0xFF0D99FF),
                      ),
                    ),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0D99FF),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }

  // 1. Auto Layout Tree Node (Parent + Expandable Children)
  Widget _buildAutoLayoutTreeNode(
    BuildContext context,
    EditorState state,
    AutoLayoutLayer layer, {
    AutoLayoutLayer? rootParent,
    int? index,
    int? totalCount,
    required bool isMultiMode,
  }) {
    final isSelected = state.selectedLayerIds.contains(layer.id);
    final isExpanded = _expandedLayerIds.contains(layer.id);
    final effectiveRoot = rootParent ?? layer;

    return DragTarget<Layer>(
      onWillAcceptWithDetails: (details) {
        if (details.data.id == layer.id) return false;
        if (_isDescendant(details.data, layer.id)) return false;
        return true;
      },
      onAcceptWithDetails: (details) {
        context.read<EditorBloc>().add(MoveLayerTreeEvent(
              layerId: details.data.id,
              targetParentId: layer.id,
              targetIndex: layer.children.length,
            ));
        setState(() {
          _expandedLayerIds.add(layer.id);
        });
      },
      builder: (context, candidateData, rejectedData) {
        final isDroppingInside = candidateData.isNotEmpty;

        Widget card = Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: isDroppingInside
                ? const Color(0xFF0D99FF).withValues(alpha: 0.18)
                : (isSelected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.surface.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDroppingInside
                  ? const Color(0xFF0D99FF)
                  : (isSelected
                      ? AppColors.primary.withValues(alpha: 0.6)
                      : AppColors.border.withValues(alpha: 0.6)),
              width: isDroppingInside ? 1.8 : 1.0,
            ),
            boxShadow: isDroppingInside
                ? [
                    BoxShadow(
                      color: const Color(0xFF0D99FF).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isDroppingInside)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0D99FF),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_circle_outline_rounded, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        'Drop inside ${layer.name}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              // Parent Header Row
              InkWell(
                onTap: () {
                  context.read<EditorBloc>().add(SelectLayerEvent(layer.id, isMultiSelect: isMultiMode));
                },
                onLongPress: () {
                  context.read<EditorBloc>().add(SelectLayerEvent(layer.id, isMultiSelect: true));
                },
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: [
                      // Multi-Select Checkbox
                      if (isMultiMode)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(
                            isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                            size: 16,
                            color: isSelected ? AppColors.primary : AppColors.textMuted,
                          ),
                        ),

                      // Drag Indicator
                      const Icon(
                        Icons.drag_indicator_rounded,
                        color: AppColors.textMuted,
                        size: 14,
                      ),
                      const SizedBox(width: 2),

                      // Expand/Collapse Chevron
                      InkWell(
                        onTap: () {
                          setState(() {
                            if (isExpanded) {
                              _expandedLayerIds.remove(layer.id);
                            } else {
                              _expandedLayerIds.add(layer.id);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_down_rounded
                                : Icons.keyboard_arrow_right_rounded,
                            color: AppColors.textSecondary,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),

                      // Auto Layout Type Icon
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.link_rounded,
                          color: AppColors.primary,
                          size: 15,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Name + Direction Badge
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              layer.name,
                              style: TextStyle(
                                color: layer.visible ? Colors.white : AppColors.textMuted,
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceElevated,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    layer.direction == AutoLayoutDirection.horizontal
                                        ? 'Auto Layout (H)'
                                        : 'Auto Layout (V)',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${layer.children.length} items',
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Move Up
                      if (index != null && index > 0)
                        IconButton(
                          icon: const Icon(Icons.arrow_upward_rounded, size: 14, color: AppColors.textSecondary),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                          onPressed: () {
                            context.read<EditorBloc>().add(MoveLayerTreeEvent(
                                  layerId: layer.id,
                                  targetParentId: rootParent?.id,
                                  targetIndex: index - 1,
                                ));
                          },
                        ),

                      // Move Down
                      if (index != null && totalCount != null && index < totalCount - 1)
                        IconButton(
                          icon: const Icon(Icons.arrow_downward_rounded, size: 14, color: AppColors.textSecondary),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                          onPressed: () {
                            context.read<EditorBloc>().add(MoveLayerTreeEvent(
                                  layerId: layer.id,
                                  targetParentId: rootParent?.id,
                                  targetIndex: index + 2,
                                ));
                          },
                        ),

                      // Lock Action
                      IconButton(
                        icon: Icon(
                          layer.locked ? Icons.lock : Icons.lock_open_rounded,
                          size: 14,
                          color: layer.locked ? AppColors.danger : AppColors.textMuted,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                        onPressed: () {
                          if (rootParent != null) {
                            _toggleChildLock(context, effectiveRoot, layer);
                          } else {
                            context.read<EditorBloc>().add(ToggleLockLayerEvent(layer.id));
                          }
                        },
                      ),

                      // Visibility Action
                      IconButton(
                        icon: Icon(
                          layer.visible ? Icons.visibility : Icons.visibility_off,
                          size: 14,
                          color: layer.visible ? AppColors.textSecondary : AppColors.textMuted,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                        onPressed: () {
                          if (rootParent != null) {
                            _toggleChildVisibility(context, effectiveRoot, layer);
                          } else {
                            context.read<EditorBloc>().add(ToggleVisibilityLayerEvent(layer.id));
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Children Sub-Tree with Drop Slots
              if (isExpanded) ...[
                Container(
                  margin: const EdgeInsets.only(left: 18, right: 4, bottom: 4),
                  decoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: AppColors.border,
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < layer.children.length; i++) ...[
                        _buildDropSlot(
                          context,
                          targetParentId: layer.id,
                          targetIndex: i,
                        ),
                        _buildTreeChildTile(
                          context,
                          state,
                          layer,
                          layer.children[i],
                          effectiveRoot: effectiveRoot,
                          childIndex: i,
                          totalChildren: layer.children.length,
                          isMultiMode: isMultiMode,
                        ),
                      ],
                      _buildDropSlot(
                        context,
                        targetParentId: layer.id,
                        targetIndex: layer.children.length,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );

        return LongPressDraggable<Layer>(
          data: layer,
          delay: const Duration(milliseconds: 150),
          feedback: Material(
            color: Colors.transparent,
            child: Container(
              width: 260,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF0D99FF), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.link_rounded, color: Color(0xFF0D99FF), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      layer.name,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.3, child: card),
          child: card,
        );
      },
    );
  }

  // 2. Child Item Tile inside Auto Layout Tree
  Widget _buildTreeChildTile(
    BuildContext context,
    EditorState state,
    AutoLayoutLayer parent,
    Layer child, {
    required AutoLayoutLayer effectiveRoot,
    required int childIndex,
    required int totalChildren,
    required bool isMultiMode,
  }) {
    if (child is AutoLayoutLayer && child.children.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(left: 6, top: 2, bottom: 2),
        child: _buildAutoLayoutTreeNode(
          context,
          state,
          child,
          rootParent: effectiveRoot,
          index: childIndex,
          totalCount: totalChildren,
          isMultiMode: isMultiMode,
        ),
      );
    }

    final isSelected = state.selectedLayerIds.contains(child.id);

    Widget childTile = Container(
      margin: const EdgeInsets.only(left: 10, top: 2, bottom: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.15)
            : AppColors.surfaceSecondary.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.6)
              : AppColors.border.withValues(alpha: 0.4),
        ),
      ),
      child: InkWell(
        onTap: () {
          if (isMultiMode) {
            context.read<EditorBloc>().add(SelectLayerEvent(child.id, isMultiSelect: true));
          } else {
            context.read<EditorBloc>().add(SelectLayerEvent(effectiveRoot.id, isMultiSelect: false));
          }
        },
        onLongPress: () {
          context.read<EditorBloc>().add(SelectLayerEvent(child.id, isMultiSelect: true));
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              // Multi-select Checkbox
              if (isMultiMode)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                    size: 14,
                    color: isSelected ? AppColors.primary : AppColors.textMuted,
                  ),
                ),

              // Drag Handle / Branch Line
              const Icon(
                Icons.drag_indicator_rounded,
                color: AppColors.textMuted,
                size: 14,
              ),
              const SizedBox(width: 4),

              // Child Layer Icon
              Icon(
                _getLayerIcon(child.type),
                color: AppColors.primaryLight,
                size: 15,
              ),
              const SizedBox(width: 8),

              // Child Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      child.name,
                      style: TextStyle(
                        color: child.visible ? Colors.white70 : AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (child is TextLayer)
                      Text(
                        '"${child.content}"',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // Move Up inside parent
              if (childIndex > 0)
                IconButton(
                  icon: const Icon(Icons.arrow_upward_rounded, size: 12, color: AppColors.textSecondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                  onPressed: () {
                    context.read<EditorBloc>().add(MoveLayerTreeEvent(
                          layerId: child.id,
                          targetParentId: parent.id,
                          targetIndex: childIndex - 1,
                        ));
                  },
                ),

              // Move Down inside parent
              if (childIndex < totalChildren - 1)
                IconButton(
                  icon: const Icon(Icons.arrow_downward_rounded, size: 12, color: AppColors.textSecondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                  onPressed: () {
                    context.read<EditorBloc>().add(MoveLayerTreeEvent(
                          layerId: child.id,
                          targetParentId: parent.id,
                          targetIndex: childIndex + 2,
                        ));
                  },
                ),

              // Child Lock
              IconButton(
                icon: Icon(
                  child.locked ? Icons.lock : Icons.lock_open_rounded,
                  size: 13,
                  color: child.locked ? AppColors.danger : AppColors.textMuted,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                onPressed: () => _toggleChildLock(context, effectiveRoot, child),
              ),

              // Child Visibility
              IconButton(
                icon: Icon(
                  child.visible ? Icons.visibility : Icons.visibility_off,
                  size: 13,
                  color: child.visible ? AppColors.textSecondary : AppColors.textMuted,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                onPressed: () => _toggleChildVisibility(context, effectiveRoot, child),
              ),
            ],
          ),
        ),
      ),
    );

    return LongPressDraggable<Layer>(
      data: child,
      delay: const Duration(milliseconds: 150),
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 220,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(_getLayerIcon(child.type), color: AppColors.primaryLight, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  child.name,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: childTile),
      child: childTile,
    );
  }

  AutoLayoutLayer _updateChildRecursively(AutoLayoutLayer container, Layer targetChild) {
    final updatedChildren = container.children.map((c) {
      if (c.id == targetChild.id) {
        return targetChild;
      } else if (c is AutoLayoutLayer) {
        return _updateChildRecursively(c, targetChild);
      }
      return c;
    }).toList();
    return container.copyWith(children: updatedChildren);
  }

  void _toggleChildLock(BuildContext context, AutoLayoutLayer rootParent, Layer child) {
    final updatedChild = child.copyWithTransform(locked: !child.locked);
    final updatedRoot = _updateChildRecursively(rootParent, updatedChild);
    context.read<EditorBloc>().add(UpdateLayerEvent(updatedRoot));
  }

  void _toggleChildVisibility(BuildContext context, AutoLayoutLayer rootParent, Layer child) {
    final updatedChild = child.copyWithTransform(visible: !child.visible);
    final updatedRoot = _updateChildRecursively(rootParent, updatedChild);
    context.read<EditorBloc>().add(UpdateLayerEvent(updatedRoot));
  }

  // 3. Standard Non-Container Layer Tile
  Widget _buildStandardLayerTile(
    BuildContext context,
    EditorState state,
    Layer layer, {
    required int index,
    required int totalCount,
    required bool isMultiMode,
  }) {
    final isSelected = state.selectedLayerIds.contains(layer.id);

    Widget tile = Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.surfaceElevated : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.5))
            : Border.all(color: Colors.transparent),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMultiMode)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                  size: 16,
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                ),
              ),
            const Icon(Icons.drag_indicator_rounded, color: AppColors.textMuted, size: 14),
            const SizedBox(width: 4),
            Icon(
              _getLayerIcon(layer.type),
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 16,
            ),
          ],
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
            // Move Up
            if (index > 0)
              IconButton(
                icon: const Icon(Icons.arrow_upward_rounded, size: 13, color: AppColors.textSecondary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                onPressed: () {
                  context.read<EditorBloc>().add(MoveLayerTreeEvent(
                        layerId: layer.id,
                        targetParentId: null,
                        targetIndex: index - 1,
                      ));
                },
              ),

            // Move Down
            if (index < totalCount - 1)
              IconButton(
                icon: const Icon(Icons.arrow_downward_rounded, size: 13, color: AppColors.textSecondary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                onPressed: () {
                  context.read<EditorBloc>().add(MoveLayerTreeEvent(
                        layerId: layer.id,
                        targetParentId: null,
                        targetIndex: index + 2,
                      ));
                },
              ),

            // Lock Button
            IconButton(
              icon: Icon(
                layer.locked ? Icons.lock : Icons.lock_open_rounded,
                size: 14,
                color: layer.locked ? AppColors.danger : AppColors.textMuted,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
              onPressed: () {
                context.read<EditorBloc>().add(ToggleLockLayerEvent(layer.id));
              },
            ),
            const SizedBox(width: 2),

            // Visibility Button
            IconButton(
              icon: Icon(
                layer.visible ? Icons.visibility : Icons.visibility_off,
                size: 14,
                color: layer.visible ? AppColors.textSecondary : AppColors.textMuted,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
              onPressed: () {
                context.read<EditorBloc>().add(ToggleVisibilityLayerEvent(layer.id));
              },
            ),
          ],
        ),
        onTap: () {
          context.read<EditorBloc>().add(SelectLayerEvent(layer.id, isMultiSelect: isMultiMode));
        },
        onLongPress: () {
          context.read<EditorBloc>().add(SelectLayerEvent(layer.id, isMultiSelect: true));
        },
      ),
    ),
  );

    return LongPressDraggable<Layer>(
      data: layer,
      delay: const Duration(milliseconds: 150),
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 240,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(_getLayerIcon(layer.type), color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  layer.name,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: tile),
      child: tile,
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
      case LayerType.autoLayout:
        return Icons.link_rounded;
      case LayerType.vector:
        return Icons.polyline_rounded;
    }
  }
}
