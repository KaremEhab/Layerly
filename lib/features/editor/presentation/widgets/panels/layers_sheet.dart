import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:layerly/core/constants/app_colors.dart';
import 'package:layerly/features/editor/domain/entities/auto_layout_layer.dart';
import 'package:layerly/features/editor/domain/entities/component_instance_layer.dart';
import 'package:layerly/features/editor/domain/entities/device_mockup_layer.dart';
import 'package:layerly/features/editor/domain/entities/icon_layer.dart';
import 'package:layerly/features/editor/domain/entities/image_layer.dart';
import 'package:layerly/features/editor/domain/entities/layer.dart';
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

        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 16),
            height: MediaQuery.of(context).size.height * 0.78,
            decoration: BoxDecoration(
              color: const Color(0xFF131219),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFF2A2838), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Sleek Header
                _buildHeader(context, state, layers, isMultiActive, selectedCount),

                // 2. Streamlined Search & Filter Bar
                _buildSearchBar(),

                // 3. Multi-Select Batch Actions Bar (shown when active)
                if (isMultiActive)
                  _buildBatchActionsBar(context, state, selectedCount),

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
                                if (layer is AutoLayoutLayer)
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
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    EditorState state,
    List<Layer> layers,
    bool isMultiActive,
    int selectedCount,
  ) {
    final allExpanded = _expandedLayerIds.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 16, 6),
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
              const Text(
                'Layers',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF221F32),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF322E48)),
                ),
                child: Text(
                  '${layers.length}',
                  style: const TextStyle(
                    color: Color(0xFFA78BFA),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const Spacer(),

              // Multi-Select toggle button
              InkWell(
                onTap: () {
                  setState(() {
                    _isMultiSelectMode = !_isMultiSelectMode;
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isMultiActive ? const Color(0xFF6C5CE7) : const Color(0xFF1E1C2B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isMultiActive ? const Color(0xFFA78BFA) : const Color(0xFF2E2C40),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isMultiActive ? Icons.check_circle_rounded : Icons.checklist_rounded,
                        size: 14,
                        color: isMultiActive ? Colors.white : AppColors.textMuted,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isMultiActive && selectedCount > 0 ? '$selectedCount Selected' : 'Select',
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

              const SizedBox(width: 6),

              // Expand / Collapse all
              IconButton(
                icon: Icon(
                  allExpanded ? Icons.unfold_less_rounded : Icons.unfold_more_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
                tooltip: allExpanded ? 'Collapse All' : 'Expand All',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () {
                  if (allExpanded) {
                    _collapseAll();
                  } else {
                    _expandAll(layers);
                  }
                },
              ),

              const SizedBox(width: 4),

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
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
      child: Row(
        children: [
          // Search Box
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF1B1927),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _searchQuery.isNotEmpty ? const Color(0xFF6C5CE7) : const Color(0xFF28253A),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Filter by name...',
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
          ),

          const SizedBox(width: 8),

          // Quick Filter Dropdown Button
          PopupMenuButton<String>(
            initialValue: _selectedFilter,
            onSelected: (val) => setState(() => _selectedFilter = val),
            color: const Color(0xFF1E1C2B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFF2E2C40)),
            ),
            itemBuilder: (ctx) => [
              'All',
              'Auto Layouts',
              'Text',
              'Icons',
              'Shapes',
              'Locked / Hidden',
            ].map((f) {
              final isSelected = _selectedFilter == f;
              return PopupMenuItem<String>(
                value: f,
                height: 36,
                child: Row(
                  children: [
                    if (isSelected)
                      const Icon(Icons.check_rounded, size: 14, color: Color(0xFFA78BFA))
                    else
                      const SizedBox(width: 14),
                    const SizedBox(width: 8),
                    Text(
                      f,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: _selectedFilter != 'All'
                    ? const Color(0xFF6C5CE7).withValues(alpha: 0.2)
                    : const Color(0xFF1B1927),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _selectedFilter != 'All'
                      ? const Color(0xFF6C5CE7)
                      : const Color(0xFF28253A),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.filter_list_rounded,
                    size: 15,
                    color: _selectedFilter != 'All' ? const Color(0xFFA78BFA) : AppColors.textMuted,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _selectedFilter == 'All' ? 'Filter' : _selectedFilter,
                    style: TextStyle(
                      color: _selectedFilter != 'All' ? const Color(0xFFA78BFA) : AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 16,
                    color: _selectedFilter != 'All' ? const Color(0xFFA78BFA) : AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchActionsBar(
    BuildContext context,
    EditorState state,
    int selectedCount,
  ) {
    final allPageLayerIds = state.activePageLayers.map((l) => l.id).toList();
    final allSelected = selectedCount > 0 && selectedCount == allPageLayerIds.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1828),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E2A42)),
      ),
      child: Row(
        children: [
          // Select All / Deselect All
          InkWell(
            onTap: () {
              if (allSelected) {
                context.read<EditorBloc>().add(const ClearSelectionEvent());
              } else {
                context.read<EditorBloc>().add(SelectMultipleLayersEvent(allPageLayerIds));
              }
            },
            borderRadius: BorderRadius.circular(6),
            child: Text(
              allSelected ? 'Deselect All' : 'Select All (${allPageLayerIds.length})',
              style: const TextStyle(
                color: Color(0xFFA78BFA),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const Spacer(),

          // Group into Auto Layout button
          if (selectedCount > 1) ...[
            ElevatedButton.icon(
              onPressed: () {
                context.read<EditorBloc>().add(const CreateAutoLayoutFromSelectionEvent());
              },
              icon: const Icon(Icons.link_rounded, size: 14),
              label: const Text('Group Auto Layout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Batch Delete button
          if (selectedCount > 0)
            InkWell(
              onTap: () {
                context.read<EditorBloc>().add(const DeleteSelectedLayersEvent());
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4757).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFF4757).withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF6B81), size: 16),
              ),
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
