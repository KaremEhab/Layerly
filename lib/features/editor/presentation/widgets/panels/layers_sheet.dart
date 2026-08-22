import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:layerly/core/constants/app_colors.dart';
import 'package:layerly/core/utils/uuid_generator.dart';
import 'package:layerly/features/editor/domain/entities/auto_layout_layer.dart';
import 'package:layerly/features/editor/domain/entities/component_instance_layer.dart';
import 'package:layerly/features/editor/domain/entities/device_mockup_layer.dart';
import 'package:layerly/features/editor/domain/entities/icon_layer.dart';
import 'package:layerly/features/editor/domain/entities/image_layer.dart';
import 'package:layerly/features/editor/domain/entities/layer.dart';
import 'package:layerly/features/editor/domain/entities/layer_enums.dart';
import 'package:layerly/features/editor/domain/entities/shape_layer.dart';
import 'package:layerly/features/editor/domain/entities/text_layer.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_bloc.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_event.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_state.dart';

/// Opens the professional Layer Hierarchy bottom sheet.
void showLayersBottomSheet(BuildContext context, {EditorBloc? bloc}) {
  final editorBloc = bloc ?? context.read<EditorBloc>();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => BlocProvider.value(
      value: editorBloc,
      child: _LayersSheetModal(bloc: editorBloc),
    ),
  );
}

class _LayersSheetModal extends StatefulWidget {
  final EditorBloc bloc;

  const _LayersSheetModal({required this.bloc});

  @override
  State<_LayersSheetModal> createState() => _LayersSheetModalState();
}

class _LayersSheetModalState extends State<_LayersSheetModal> {
  final Set<String> _expandedLayerIds = <String>{};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All'; // All, Auto Layout, Text, Icons, Shapes, Locked/Hidden
  bool _isMultiSelectMode = false;
  bool _initialized = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _expandAllAutoLayouts(List<Layer> layers) {
    for (final l in layers) {
      if (l is AutoLayoutLayer && l.children.isNotEmpty) {
        _expandedLayerIds.add(l.id);
        _expandAllAutoLayouts(l.children);
      }
    }
  }

  void _collapseAll() {
    setState(() {
      _expandedLayerIds.clear();
    });
  }

  void _expandAll(List<Layer> layers) {
    setState(() {
      _expandAllAutoLayouts(layers);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditorBloc, EditorState>(
      bloc: widget.bloc,
      builder: (context, state) {
        final layers = state.activePageLayers;
        final selectedCount = state.selectedLayerIds.length;
        final isMultiActive = _isMultiSelectMode || selectedCount > 1;

        if (!_initialized) {
          _expandAllAutoLayouts(layers);
          _initialized = true;
        }

        final filteredLayers = _filterLayers(layers);

        return Container(
          height: MediaQuery.of(context).size.height * 0.78,
          decoration: const BoxDecoration(
            color: Color(0xFF131219),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: Color(0xFF2A2838), width: 1.5),
              left: BorderSide(color: Color(0xFF2A2838), width: 1.0),
              right: BorderSide(color: Color(0xFF2A2838), width: 1.0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Drag Handle & Header
              _buildHeader(context, state, layers),

              // 2. Search & Quick Filters
              _buildSearchBar(),
              _buildFilterChips(),

              // 3. Multi-Select & Batch Actions Bar
              _buildBatchActionsBar(context, state, isMultiActive, selectedCount),

              const Divider(height: 1, color: Color(0xFF242232)),

              // 4. Layers Tree View
              Expanded(
                child: filteredLayers.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredLayers.length + 1,
                        itemBuilder: (ctx, index) {
                          if (index == filteredLayers.length) {
                            return _buildDropSlot(
                              context,
                              targetParentId: null,
                              targetIndex: filteredLayers.length,
                            );
                          }

                          final layer = filteredLayers[index];
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
                                  isMultiMode: isMultiActive,
                                )
                              else
                                _buildStandardLayerTile(
                                  context,
                                  state,
                                  layer,
                                  isMultiMode: isMultiActive,
                                ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, EditorState state, List<Layer> layers) {
    final allExpanded = _expandedLayerIds.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 6),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C5CE7), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C5CE7).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.layers_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Layer Hierarchy',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF262338),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Text(
                            '${layers.length} Layers',
                            style: const TextStyle(color: Color(0xFFA78BFA), fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Page: ${state.activePage.name} • Drag to reorder & group',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),

              // Expand / Collapse all
              IconButton(
                icon: Icon(
                  allExpanded ? Icons.unfold_less_rounded : Icons.unfold_more_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
                tooltip: allExpanded ? 'Collapse All' : 'Expand All',
                onPressed: () {
                  if (allExpanded) {
                    _collapseAll();
                  } else {
                    _expandAll(layers);
                  }
                },
              ),

              // Close
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22202C),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white70, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFF1D1B28),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _searchQuery.isNotEmpty ? const Color(0xFF8B5CF6) : const Color(0xFF2B283D),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 17),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Filter layer names...',
                  hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              InkWell(
                onTap: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                child: const Icon(Icons.clear_rounded, color: Colors.white70, size: 15),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Auto Layouts', 'Text', 'Icons', 'Shapes', 'Locked / Hidden'];

    return SizedBox(
      height: 34,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (ctx, idx) {
          final f = filters[idx];
          final isSelected = _selectedFilter == f;
          return InkWell(
            onTap: () => setState(() => _selectedFilter = f),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6C5CE7) : const Color(0xFF1C1A27),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? const Color(0xFFA29BFE) : const Color(0xFF2C283F),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                f,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBatchActionsBar(
    BuildContext context,
    EditorState state,
    bool isMultiActive,
    int selectedCount,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Row(
        children: [
          // Multi-Select Toggle Pill
          InkWell(
            onTap: () {
              setState(() {
                _isMultiSelectMode = !_isMultiSelectMode;
              });
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isMultiActive ? const Color(0xFF6C5CE7).withValues(alpha: 0.25) : const Color(0xFF1E1C2B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isMultiActive ? const Color(0xFF8B5CF6) : const Color(0xFF2C283F),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isMultiActive ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                    size: 14,
                    color: isMultiActive ? const Color(0xFFA78BFA) : AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isMultiActive ? 'Multi-Select ($selectedCount)' : 'Select Multiple',
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

          // Batch Group into Auto Layout
          if (selectedCount > 1) ...[
            ElevatedButton.icon(
              onPressed: () {
                context.read<EditorBloc>().add(const CreateAutoLayoutFromSelectionEvent());
              },
              icon: const Icon(Icons.link_rounded, size: 14),
              label: const Text('Group Layout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(width: 6),
          ],

          // Batch Delete
          if (selectedCount > 0)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.white60, size: 18),
              tooltip: 'Delete Selected',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                context.read<EditorBloc>().add(const DeleteSelectedLayersEvent());
              },
            ),
        ],
      ),
    );
  }

  List<Layer> _filterLayers(List<Layer> layers) {
    return layers.where((l) {
      // 1. Text Search Filter
      if (_searchQuery.isNotEmpty && !l.name.toLowerCase().contains(_searchQuery)) {
        // If it's an auto layout, check if any child matches
        if (l is AutoLayoutLayer) {
          final hasMatchingChild = l.children.any((c) => c.name.toLowerCase().contains(_searchQuery));
          if (!hasMatchingChild) return false;
        } else {
          return false;
        }
      }

      // 2. Category Filter
      if (_selectedFilter == 'Auto Layouts' && l is! AutoLayoutLayer) return false;
      if (_selectedFilter == 'Text' && l is! TextLayer) return false;
      if (_selectedFilter == 'Icons' && l is! IconLayer) return false;
      if (_selectedFilter == 'Shapes' && l is! ShapeLayer) return false;
      if (_selectedFilter == 'Locked / Hidden' && l.visible && !l.locked) return false;

      return true;
    }).toList();
  }

  // -------------------------------------------------------------
  // TREE NODE BUILDERS
  // -------------------------------------------------------------

  Widget _buildAutoLayoutTreeNode(
    BuildContext context,
    EditorState state,
    AutoLayoutLayer layer, {
    required bool isMultiMode,
  }) {
    final isSelected = state.selectedLayerIds.contains(layer.id);
    final isExpanded = _expandedLayerIds.contains(layer.id);

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
                ? const Color(0xFF0D99FF).withValues(alpha: 0.2)
                : (isSelected ? const Color(0xFF6C5CE7).withValues(alpha: 0.18) : const Color(0xFF1B1927)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDroppingInside
                  ? const Color(0xFF0D99FF)
                  : (isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF2C283F)),
              width: isDroppingInside ? 1.8 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              InkWell(
                onTap: () {
                  context.read<EditorBloc>().add(SelectLayerEvent(layer.id, isMultiSelect: isMultiMode));
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  child: Row(
                    children: [
                      if (isMultiMode)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(
                            isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                            size: 15,
                            color: isSelected ? const Color(0xFFA78BFA) : AppColors.textMuted,
                          ),
                        ),
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
                        child: Icon(
                          isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                          color: AppColors.textSecondary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 4),
                      _buildLayerTypeBadge(layer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          layer.name,
                          style: TextStyle(
                            color: layer.visible ? Colors.white : AppColors.textMuted,
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildLayerInlineActions(context, layer),
                    ],
                  ),
                ),
              ),

              // Expandable Children Tree
              if (isExpanded && layer.children.isNotEmpty)
                Container(
                  decoration: const BoxDecoration(
                    border: Border(left: BorderSide(color: Color(0xFF2F2B44), width: 2)),
                  ),
                  margin: const EdgeInsets.only(left: 20, bottom: 4),
                  padding: const EdgeInsets.only(left: 6),
                  child: Column(
                    children: [
                      for (int cIdx = 0; cIdx < layer.children.length; cIdx++) ...[
                        _buildDropSlot(
                          context,
                          targetParentId: layer.id,
                          targetIndex: cIdx,
                        ),
                        _buildChildLayerTile(
                          context,
                          state,
                          layer,
                          layer.children[cIdx],
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
          ),
        );

        return LongPressDraggable<Layer>(
          data: layer,
          feedback: Material(
            color: Colors.transparent,
            child: Opacity(
              opacity: 0.9,
              child: Container(
                width: 260,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF221F32),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF8B5CF6), width: 1.5),
                  boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
                ),
                child: Row(
                  children: [
                    _buildLayerTypeBadge(layer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        layer.name,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          child: card,
        );
      },
    );
  }

  Widget _buildChildLayerTile(
    BuildContext context,
    EditorState state,
    AutoLayoutLayer parent,
    Layer child, {
    required bool isMultiMode,
  }) {
    final isSelected = state.selectedLayerIds.contains(child.id);

    return LongPressDraggable<Layer>(
      data: child,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.9,
          child: Container(
            width: 220,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF221F32),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF8B5CF6)),
            ),
            child: Row(
              children: [
                _buildLayerTypeBadge(child),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    child.name,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      child: InkWell(
        onTap: () {
          context.read<EditorBloc>().add(SelectLayerEvent(child.id, isMultiSelect: isMultiMode));
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6C5CE7).withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected ? Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.6)) : null,
          ),
          child: Row(
            children: [
              _buildLayerTypeBadge(child),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  child.name,
                  style: TextStyle(
                    color: child.visible ? Colors.white70 : AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildLayerInlineActions(context, child, parent: parent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStandardLayerTile(
    BuildContext context,
    EditorState state,
    Layer layer, {
    required bool isMultiMode,
  }) {
    final isSelected = state.selectedLayerIds.contains(layer.id);

    return LongPressDraggable<Layer>(
      data: layer,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.9,
          child: Container(
            width: 240,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF221F32),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF8B5CF6)),
            ),
            child: Row(
              children: [
                _buildLayerTypeBadge(layer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    layer.name,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      child: InkWell(
        onTap: () {
          context.read<EditorBloc>().add(SelectLayerEvent(layer.id, isMultiSelect: isMultiMode));
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6C5CE7).withValues(alpha: 0.18) : const Color(0xFF1B1927),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF2C283F),
            ),
          ),
          child: Row(
            children: [
              if (isMultiMode)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                    size: 15,
                    color: isSelected ? const Color(0xFFA78BFA) : AppColors.textMuted,
                  ),
                ),
              const Icon(Icons.drag_indicator_rounded, color: Colors.white24, size: 14),
              const SizedBox(width: 4),
              _buildLayerTypeBadge(layer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  layer.name,
                  style: TextStyle(
                    color: layer.visible ? Colors.white : AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildLayerInlineActions(context, layer),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLayerTypeBadge(Layer layer) {
    IconData icon;
    Color color;

    if (layer is AutoLayoutLayer) {
      icon = Icons.link_rounded;
      color = const Color(0xFF8B5CF6);
    } else if (layer is TextLayer) {
      icon = Icons.title_rounded;
      color = const Color(0xFF00CEC9);
    } else if (layer is IconLayer) {
      icon = Icons.star_rounded;
      color = const Color(0xFFFDCB6E);
    } else if (layer is ShapeLayer) {
      icon = Icons.crop_square_rounded;
      color = const Color(0xFF55EFC4);
    } else if (layer is DeviceMockupLayer) {
      icon = Icons.phone_iphone_rounded;
      color = const Color(0xFFE056FD);
    } else if (layer is ComponentInstanceLayer) {
      icon = Icons.widgets_rounded;
      color = const Color(0xFF8B5CF6);
    } else if (layer is ImageLayer) {
      icon = Icons.image_rounded;
      color = const Color(0xFF0984E3);
    } else {
      icon = Icons.layers_rounded;
      color = Colors.white54;
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, color: color, size: 14),
    );
  }

  Widget _buildLayerInlineActions(BuildContext context, Layer layer, {AutoLayoutLayer? parent}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Visibility Eye Toggle
        InkWell(
          onTap: () {
            final updated = layer.copyWithTransform(visible: !layer.visible);
            if (parent != null) {
              final newChildren = parent.children.map((c) => c.id == layer.id ? updated : c).toList();
              context.read<EditorBloc>().add(UpdateLayerEvent(parent.copyWith(children: newChildren)));
            } else {
              context.read<EditorBloc>().add(UpdateLayerEvent(updated));
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              layer.visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              size: 15,
              color: layer.visible ? Colors.white38 : const Color(0xFFFF7675),
            ),
          ),
        ),

        // Lock Toggle
        InkWell(
          onTap: () {
            final updated = layer.copyWithTransform(locked: !layer.locked);
            if (parent != null) {
              final newChildren = parent.children.map((c) => c.id == layer.id ? updated : c).toList();
              context.read<EditorBloc>().add(UpdateLayerEvent(parent.copyWith(children: newChildren)));
            } else {
              context.read<EditorBloc>().add(UpdateLayerEvent(updated));
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              layer.locked ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
              size: 15,
              color: layer.locked ? const Color(0xFFFDCB6E) : Colors.white24,
            ),
          ),
        ),
      ],
    );
  }

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
          height: isHovered ? 14 : 4,
          margin: const EdgeInsets.symmetric(vertical: 1),
          alignment: Alignment.center,
          child: isHovered
              ? Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: Color(0xFF0D99FF), shape: BoxShape.circle),
                    ),
                    Expanded(
                      child: Container(height: 2.5, color: const Color(0xFF0D99FF)),
                    ),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: Color(0xFF0D99FF), shape: BoxShape.circle),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.layers_clear_rounded, size: 36, color: AppColors.textMuted),
            const SizedBox(height: 12),
            const Text(
              'No matching layers found',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Try changing your search query or category filter.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
