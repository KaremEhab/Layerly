import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/canvas_project.dart';
import '../../domain/entities/canvas_page.dart';
import '../../domain/entities/layer.dart';
import '../../domain/entities/component_definition.dart';
import '../../domain/services/snapping_service.dart';

class EditorState extends Equatable {
  final CanvasProject project;
  final List<String> selectedLayerIds;
  final String? hoveredLayerId;
  final List<CanvasProject> undoStack;
  final List<CanvasProject> redoStack;
  final double zoom;
  final Offset panOffset;
  final bool showGrid;
  final bool showGuides;
  final bool snapEnabled;
  final List<SnapGuideLine> activeSnapGuides;
  final bool isInteracting;

  const EditorState({
    required this.project,
    this.selectedLayerIds = const [],
    this.hoveredLayerId,
    this.undoStack = const [],
    this.redoStack = const [],
    this.zoom = 0.55,
    this.panOffset = Offset.zero,
    this.showGrid = false,
    this.showGuides = true,
    this.snapEnabled = true,
    this.activeSnapGuides = const [],
    this.isInteracting = false,
  });

  CanvasPage get activePage => project.activePage;

  List<Layer> get activePageLayers => activePage.layers;

  Layer? get singleSelectedLayer {
    if (selectedLayerIds.length == 1) {
      final id = selectedLayerIds.first;
      try {
        return activePageLayers.firstWhere((l) => l.id == id);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  List<Layer> get selectedLayers {
    return activePageLayers
        .where((l) => selectedLayerIds.contains(l.id))
        .toList();
  }

  ComponentDefinition? getComponentDefinition(String id) {
    try {
      return project.components.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;

  EditorState copyWith({
    CanvasProject? project,
    List<String>? selectedLayerIds,
    String? hoveredLayerId,
    bool clearHover = false,
    List<CanvasProject>? undoStack,
    List<CanvasProject>? redoStack,
    double? zoom,
    Offset? panOffset,
    bool? showGrid,
    bool? showGuides,
    bool? snapEnabled,
    List<SnapGuideLine>? activeSnapGuides,
    bool? isInteracting,
  }) {
    return EditorState(
      project: project ?? this.project,
      selectedLayerIds: selectedLayerIds ?? this.selectedLayerIds,
      hoveredLayerId: clearHover ? null : (hoveredLayerId ?? this.hoveredLayerId),
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
      zoom: zoom ?? this.zoom,
      panOffset: panOffset ?? this.panOffset,
      showGrid: showGrid ?? this.showGrid,
      showGuides: showGuides ?? this.showGuides,
      snapEnabled: snapEnabled ?? this.snapEnabled,
      activeSnapGuides: activeSnapGuides ?? this.activeSnapGuides,
      isInteracting: isInteracting ?? this.isInteracting,
    );
  }

  @override
  List<Object?> get props => [
        project,
        selectedLayerIds,
        hoveredLayerId,
        undoStack.length,
        redoStack.length,
        zoom,
        panOffset,
        showGrid,
        showGuides,
        snapEnabled,
        activeSnapGuides,
        isInteracting,
      ];
}
