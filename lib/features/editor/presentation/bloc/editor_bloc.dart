import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:layerly/features/editor/domain/entities/canvas_project.dart';
import 'package:layerly/features/editor/domain/entities/canvas_page.dart';
import 'package:layerly/features/editor/domain/entities/layer.dart';
import 'package:layerly/features/editor/domain/entities/layer_enums.dart';
import 'package:layerly/features/editor/domain/entities/text_layer.dart';
import 'package:layerly/features/editor/domain/entities/shape_layer.dart';
import 'package:layerly/features/editor/domain/entities/image_layer.dart';
import 'package:layerly/features/editor/domain/entities/device_mockup_layer.dart';
import 'package:layerly/features/editor/domain/entities/icon_layer.dart';
import 'package:layerly/features/editor/domain/entities/component_instance_layer.dart';
import 'package:layerly/features/editor/domain/entities/component_definition.dart';
import 'package:layerly/features/editor/domain/entities/auto_layout_layer.dart';
import 'package:layerly/features/editor/domain/services/snapping_service.dart';
import 'package:layerly/core/utils/uuid_generator.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_event.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_state.dart';

class EditorBloc extends Bloc<EditorEvent, EditorState> {
  static const int maxHistoryLength = 50;

  EditorBloc({required CanvasProject initialProject})
      : super(EditorState(project: normalizeProject(initialProject))) {
    on<LoadProjectEvent>(_onLoadProject);
    on<SelectLayerEvent>(_onSelectLayer);
    on<SelectMultipleLayersEvent>(_onSelectMultipleLayers);
    on<ClearSelectionEvent>(_onClearSelection);
    on<HoverLayerEvent>(_onHoverLayer);
    on<AddLayerEvent>(_onAddLayer);
    on<UpdateLayerEvent>(_onUpdateLayer);
    on<MoveLayerDeltaEvent>(_onMoveLayerDelta);
    on<ResizeLayerHandleEvent>(_onResizeLayerHandle);
    on<RotateLayerEvent>(_onRotateLayer);
    on<DeleteSelectedLayersEvent>(_onDeleteSelectedLayers);
    on<DuplicateSelectedLayersEvent>(_onDuplicateSelectedLayers);
    on<ReorderLayerEvent>(_onReorderLayer);
    on<BringForwardEvent>(_onBringForward);
    on<SendBackwardEvent>(_onSendBackward);
    on<BringToFrontEvent>(_onBringToFront);
    on<SendToBackEvent>(_onSendToBack);
    on<ToggleLockLayerEvent>(_onToggleLockLayer);
    on<ToggleVisibilityLayerEvent>(_onToggleVisibilityLayer);
    on<AlignSelectedLayersEvent>(_onAlignSelectedLayers);
    on<SelectPageEvent>(_onSelectPage);
    on<AddPageEvent>(_onAddPage);
    on<DuplicatePageEvent>(_onDuplicatePage);
    on<DeletePageEvent>(_onDeletePage);
    on<ReorderPageEvent>(_onReorderPage);
    on<UpdatePageBackgroundEvent>(_onUpdatePageBackground);
    on<RenameProjectEvent>(_onRenameProject);
    on<RenamePageEvent>(_onRenamePage);
    on<UpdatePagePaddingEvent>(_onUpdatePagePadding);
    on<CreateAutoLayoutFromSelectionEvent>(_onCreateAutoLayoutFromSelection);
    on<UpdateAutoLayoutEvent>(_onUpdateAutoLayout);
    on<RemoveAutoLayoutEvent>(_onRemoveAutoLayout);
    on<MoveLayerTreeEvent>(_onMoveLayerTree);
    on<DetachComponentInstanceEvent>(_onDetachComponentInstance);
    on<RegisterComponentDefinitionEvent>(_onRegisterComponentDefinition);
    on<UpdateComponentDefinitionEvent>(_onUpdateComponentDefinition);
    on<SetZoomEvent>(_onSetZoom);
    on<SetPanOffsetEvent>(_onSetPanOffset);
    on<ToggleGridEvent>(_onToggleGrid);
    on<ToggleGuidesEvent>(_onToggleGuides);
    on<ToggleSnapEvent>(_onToggleSnap);
    on<UndoEvent>(_onUndo);
    on<RedoEvent>(_onRedo);
  }


  List<CanvasProject> _pushHistory(CanvasProject project, List<CanvasProject> history) {
    final updated = List<CanvasProject>.from(history);
    if (updated.length >= maxHistoryLength) {
      updated.removeAt(0);
    }
    updated.add(project);
    return updated;
  }

  void _onLoadProject(LoadProjectEvent event, Emitter<EditorState> emit) {
    emit(EditorState(
      project: normalizeProject(event.project),
      selectedLayerIds: const [],
      undoStack: const [],
      redoStack: const [],
    ));
  }

  void _onSelectLayer(SelectLayerEvent event, Emitter<EditorState> emit) {
    if (event.layerId == null) {
      if (state.selectedLayerIds.isNotEmpty) {
        emit(state.copyWith(selectedLayerIds: []));
      }
      return;
    }

    if (event.isMultiSelect) {
      final current = List<String>.from(state.selectedLayerIds);
      if (current.contains(event.layerId)) {
        current.remove(event.layerId);
      } else {
        current.add(event.layerId!);
      }
      emit(state.copyWith(selectedLayerIds: current));
    } else {
      if (state.selectedLayerIds.length == 1 && state.selectedLayerIds.first == event.layerId) {
        return; // Already selected, avoid unnecessary state churn
      }
      emit(state.copyWith(selectedLayerIds: [event.layerId!]));
    }
  }

  void _onSelectMultipleLayers(
    SelectMultipleLayersEvent event,
    Emitter<EditorState> emit,
  ) {
    emit(state.copyWith(selectedLayerIds: event.layerIds));
  }

  void _onClearSelection(ClearSelectionEvent event, Emitter<EditorState> emit) {
    emit(state.copyWith(selectedLayerIds: []));
  }

  void _onHoverLayer(HoverLayerEvent event, Emitter<EditorState> emit) {
    emit(state.copyWith(
      hoveredLayerId: event.layerId,
      clearHover: event.layerId == null,
    ));
  }

  void _onAddLayer(AddLayerEvent event, Emitter<EditorState> emit) {
    Layer layerToAdd = event.layer;
    if (layerToAdd is TextLayer) {
      layerToAdd = _recalculateTextDimensions(layerToAdd);
    }
    final activePage = state.activePage;
    final updatedLayers = List<Layer>.from(activePage.layers)..add(layerToAdd);
    final updatedPage = activePage.copyWith(layers: updatedLayers);

    final updatedPages = List<CanvasPage>.from(state.project.pages);
    updatedPages[state.project.activePageIndex] = updatedPage;

    final updatedProject = state.project.copyWith(pages: updatedPages);

    emit(state.copyWith(
      project: updatedProject,
      selectedLayerIds: [event.layer.id],
      undoStack: _pushHistory(state.project, state.undoStack),
      redoStack: [],
    ));
  }

  void _onUpdateLayer(UpdateLayerEvent event, Emitter<EditorState> emit) {
    final activePage = state.activePage;
    final updatedLayers = _updateLayerInTree(activePage.layers, event.layer);

    final updatedPage = activePage.copyWith(layers: updatedLayers);
    final updatedPages = List<CanvasPage>.from(state.project.pages);
    updatedPages[state.project.activePageIndex] = updatedPage;

    final updatedProject = state.project.copyWith(pages: updatedPages);
    emit(state.copyWith(
      project: updatedProject,
      undoStack: event.recordHistory
          ? _pushHistory(state.project, state.undoStack)
          : state.undoStack,
      redoStack: event.recordHistory ? [] : state.redoStack,
    ));
  }

  void _onMoveLayerDelta(MoveLayerDeltaEvent event, Emitter<EditorState> emit) {
    if (event.isFinal && (event.layerId.isEmpty || (event.dx == 0 && event.dy == 0))) {
      emit(state.copyWith(
        activeSnapGuides: [],
        activeSpacingMeasurements: [],
        isInteracting: false,
        undoStack: _pushHistory(state.project, state.undoStack),
        redoStack: [],
      ));
      return;
    }

    final activePage = state.activePage;
    final layerIndex = activePage.layers.indexWhere((l) => l.id == event.layerId);
    if (layerIndex == -1) {
      if (event.isFinal) {
        emit(state.copyWith(
          activeSnapGuides: [],
          activeSpacingMeasurements: [],
          isInteracting: false,
        ));
      }
      return;
    }

    final layer = activePage.layers[layerIndex];
    if (layer.locked) return;

    final double rawTargetX = layer.x + event.dx;
    final double rawTargetY = layer.y + event.dy;

    // Apply smart snapping
    final snap = SnappingService.calculateSnap(
      targetX: rawTargetX,
      targetY: rawTargetY,
      targetWidth: layer.width,
      targetHeight: layer.height,
      page: activePage,
      excludeLayerIds: [layer.id],
      snapEnabled: state.snapEnabled,
    );

    // Clamp layer within page margins so items strictly follow padding limits
    final double minX = activePage.horizontalPadding;
    final double maxX = (activePage.width - activePage.horizontalPadding - layer.width).clamp(minX, activePage.width);
    final double minY = activePage.verticalPadding;
    final double maxY = (activePage.height - activePage.verticalPadding - layer.height).clamp(minY, activePage.height);

    final double clampedX = snap.snappedX.clamp(minX, maxX);
    final double clampedY = snap.snappedY.clamp(minY, maxY);

    final updatedLayer = layer.copyWithTransform(
      x: clampedX,
      y: clampedY,
    );

    final updatedLayers = List<Layer>.from(activePage.layers);
    updatedLayers[layerIndex] = updatedLayer;

    final updatedPage = activePage.copyWith(layers: updatedLayers);
    final updatedPages = List<CanvasPage>.from(state.project.pages);
    updatedPages[state.project.activePageIndex] = updatedPage;

    final updatedProject = state.project.copyWith(pages: updatedPages);

    emit(state.copyWith(
      project: updatedProject,
      activeSnapGuides: event.isFinal ? [] : snap.activeGuides,
      activeSpacingMeasurements: event.isFinal ? [] : snap.spacingMeasurements,
      isInteracting: !event.isFinal,
      undoStack: event.isFinal
          ? _pushHistory(state.project, state.undoStack)
          : state.undoStack,
      redoStack: event.isFinal ? [] : state.redoStack,
    ));
  }

  void _onResizeLayerHandle(
    ResizeLayerHandleEvent event,
    Emitter<EditorState> emit,
  ) {
    final activePage = state.activePage;
    final layer = state.findLayerById(event.layerId);
    if (layer == null || layer.locked) return;

    double newX = layer.x;
    double newY = layer.y;
    double newW = layer.width;
    double newH = layer.height;

    const minSize = 20.0;

    switch (event.handle) {
      case ResizeHandle.topLeft:
        newX += event.dx;
        newY += event.dy;
        newW -= event.dx;
        newH -= event.dy;
        break;
      case ResizeHandle.topCenter:
        newY += event.dy;
        newH -= event.dy;
        break;
      case ResizeHandle.topRight:
        newY += event.dy;
        newW += event.dx;
        newH -= event.dy;
        break;
      case ResizeHandle.centerRight:
        newW += event.dx;
        break;
      case ResizeHandle.bottomRight:
        newW += event.dx;
        newH += event.dy;
        break;
      case ResizeHandle.bottomCenter:
        newH += event.dy;
        break;
      case ResizeHandle.bottomLeft:
        newX += event.dx;
        newW -= event.dx;
        newH += event.dy;
        break;
      case ResizeHandle.centerLeft:
        newX += event.dx;
        newW -= event.dx;
        break;
      case ResizeHandle.rotation:
        break;
    }

    if (newW < minSize) {
      newW = minSize;
      newX = layer.x;
    }
    if (newH < minSize) {
      newH = minSize;
      newY = layer.y;
    }

    final updatedLayer = layer.copyWithTransform(
      x: newX,
      y: newY,
      width: newW,
      height: newH,
    );

    final updatedLayers = _updateLayerInTree(activePage.layers, updatedLayer);
    final updatedPage = activePage.copyWith(layers: updatedLayers);
    final updatedPages = List<CanvasPage>.from(state.project.pages);
    updatedPages[state.project.activePageIndex] = updatedPage;

    final updatedProject = state.project.copyWith(pages: updatedPages);

    emit(state.copyWith(
      project: updatedProject,
      activeSnapGuides: event.isFinal ? [] : state.activeSnapGuides,
      isInteracting: !event.isFinal,
      undoStack: event.isFinal
          ? _pushHistory(state.project, state.undoStack)
          : state.undoStack,
      redoStack: event.isFinal ? [] : state.redoStack,
    ));
  }

  void _onRotateLayer(RotateLayerEvent event, Emitter<EditorState> emit) {
    final activePage = state.activePage;
    final layer = state.findLayerById(event.layerId);
    if (layer == null || layer.locked) return;

    final updatedLayer = layer.copyWithTransform(rotation: event.angle);
    final updatedLayers = _updateLayerInTree(activePage.layers, updatedLayer);

    final updatedPage = activePage.copyWith(layers: updatedLayers);
    final updatedPages = List<CanvasPage>.from(state.project.pages);
    updatedPages[state.project.activePageIndex] = updatedPage;

    final updatedProject = state.project.copyWith(pages: updatedPages);

    emit(state.copyWith(
      project: updatedProject,
      isInteracting: !event.isFinal,
      undoStack: event.isFinal
          ? _pushHistory(state.project, state.undoStack)
          : state.undoStack,
      redoStack: event.isFinal ? [] : state.redoStack,
    ));
  }

  void _onDeleteSelectedLayers(
    DeleteSelectedLayersEvent event,
    Emitter<EditorState> emit,
  ) {
    if (state.selectedLayerIds.isEmpty) return;

    final activePage = state.activePage;
    final updatedLayers = activePage.layers
        .where((l) => !state.selectedLayerIds.contains(l.id))
        .toList();

    final updatedPage = activePage.copyWith(layers: updatedLayers);
    final updatedPages = List<CanvasPage>.from(state.project.pages);
    updatedPages[state.project.activePageIndex] = updatedPage;

    final updatedProject = state.project.copyWith(pages: updatedPages);

    emit(state.copyWith(
      project: updatedProject,
      selectedLayerIds: [],
      undoStack: _pushHistory(state.project, state.undoStack),
      redoStack: [],
    ));
  }

  void _onDuplicateSelectedLayers(
    DuplicateSelectedLayersEvent event,
    Emitter<EditorState> emit,
  ) {
    if (state.selectedLayerIds.isEmpty) return;

    final activePage = state.activePage;
    final newLayers = List<Layer>.from(activePage.layers);
    final List<String> newlyCreatedIds = [];

    for (final layerId in state.selectedLayerIds) {
      try {
        final layer = activePage.layers.firstWhere((l) => l.id == layerId);
        final newId = UuidGenerator.generate();
        newlyCreatedIds.add(newId);

        Layer duplicate;
        if (layer is TextLayer) {
          duplicate = layer.copyWith(
            id: newId,
            name: '${layer.name} Copy',
            x: layer.x + 20,
            y: layer.y + 20,
          );
        } else if (layer is ShapeLayer) {
          duplicate = layer.copyWith(
            id: newId,
            name: '${layer.name} Copy',
            x: layer.x + 20,
            y: layer.y + 20,
          );
        } else if (layer is ImageLayer) {
          duplicate = layer.copyWith(
            id: newId,
            name: '${layer.name} Copy',
            x: layer.x + 20,
            y: layer.y + 20,
          );
        } else if (layer is DeviceMockupLayer) {
          duplicate = layer.copyWith(
            id: newId,
            name: '${layer.name} Copy',
            x: layer.x + 20,
            y: layer.y + 20,
          );
        } else if (layer is IconLayer) {
          duplicate = layer.copyWith(
            id: newId,
            name: '${layer.name} Copy',
            x: layer.x + 20,
            y: layer.y + 20,
          );
        } else if (layer is ComponentInstanceLayer) {
          duplicate = layer.copyWith(
            id: newId,
            name: '${layer.name} Copy',
            x: layer.x + 20,
            y: layer.y + 20,
          );
        } else {
          duplicate = layer.copyWithTransform(
            name: '${layer.name} Copy',
            x: layer.x + 20,
            y: layer.y + 20,
          );
        }
        newLayers.add(duplicate);
      } catch (_) {}
    }

    final updatedPage = activePage.copyWith(layers: newLayers);
    final updatedPages = List<CanvasPage>.from(state.project.pages);
    updatedPages[state.project.activePageIndex] = updatedPage;

    final updatedProject = state.project.copyWith(pages: updatedPages);

    emit(state.copyWith(
      project: updatedProject,
      selectedLayerIds: newlyCreatedIds,
      undoStack: _pushHistory(state.project, state.undoStack),
      redoStack: [],
    ));
  }

  void _onReorderLayer(ReorderLayerEvent event, Emitter<EditorState> emit) {
    final activePage = state.activePage;
    final layers = List<Layer>.from(activePage.layers);
    final index = layers.indexWhere((l) => l.id == event.layerId);
    if (index == -1) return;

    final layer = layers.removeAt(index);
    int targetIndex = event.newIndex;
    if (targetIndex > index) targetIndex -= 1;
    targetIndex = targetIndex.clamp(0, layers.length);
    layers.insert(targetIndex, layer);

    final updatedPage = activePage.copyWith(layers: layers);
    final updatedPages = List<CanvasPage>.from(state.project.pages);
    updatedPages[state.project.activePageIndex] = updatedPage;

    emit(state.copyWith(
      project: state.project.copyWith(pages: updatedPages),
      undoStack: _pushHistory(state.project, state.undoStack),
      redoStack: [],
    ));
  }

  void _onBringForward(BringForwardEvent event, Emitter<EditorState> emit) {
    final activePage = state.activePage;
    final index = activePage.layers.indexWhere((l) => l.id == event.layerId);
    if (index == -1 || index >= activePage.layers.length - 1) return;

    final layers = List<Layer>.from(activePage.layers);
    final layer = layers.removeAt(index);
    layers.insert(index + 1, layer);

    final updatedPage = activePage.copyWith(layers: layers);
    final updatedPages = List<CanvasPage>.from(state.project.pages);
    updatedPages[state.project.activePageIndex] = updatedPage;

    emit(state.copyWith(
      project: state.project.copyWith(pages: updatedPages),
      undoStack: _pushHistory(state.project, state.undoStack),
      redoStack: [],
    ));
  }

  void _onSendBackward(SendBackwardEvent event, Emitter<EditorState> emit) {
    final activePage = state.activePage;
    final index = activePage.layers.indexWhere((l) => l.id == event.layerId);
    if (index <= 0) return;

    final layers = List<Layer>.from(activePage.layers);
    final layer = layers.removeAt(index);
    layers.insert(index - 1, layer);

    final updatedPage = activePage.copyWith(layers: layers);
    final updatedPages = List<CanvasPage>.from(state.project.pages);
    updatedPages[state.project.activePageIndex] = updatedPage;

    emit(state.copyWith(
      project: state.project.copyWith(pages: updatedPages),
      undoStack: _pushHistory(state.project, state.undoStack),
      redoStack: [],
    ));
  }

  void _onBringToFront(BringToFrontEvent event, Emitter<EditorState> emit) {
    final activePage = state.activePage;
    final index = activePage.layers.indexWhere((l) => l.id == event.layerId);
    if (index == -1 || index == activePage.layers.length - 1) return;

    final layers = List<Layer>.from(activePage.layers);
    final layer = layers.removeAt(index);
    layers.add(layer);

    final updatedPage = activePage.copyWith(layers: layers);
    final updatedPages = List<CanvasPage>.from(state.project.pages);
    updatedPages[state.project.activePageIndex] = updatedPage;

    emit(state.copyWith(
      project: state.project.copyWith(pages: updatedPages),
      undoStack: _pushHistory(state.project, state.undoStack),
      redoStack: [],
    ));
  }

  void _onSendToBack(SendToBackEvent event, Emitter<EditorState> emit) {
    final activePage = state.activePage;
    final index = activePage.layers.indexWhere((l) => l.id == event.layerId);
    if (index <= 0) return;

    final layers = List<Layer>.from(activePage.layers);
    final layer = layers.removeAt(index);
    layers.insert(0, layer);

    final updatedPage = activePage.copyWith(layers: layers);
    final updatedPages = List<CanvasPage>.from(state.project.pages);
    updatedPages[state.project.activePageIndex] = updatedPage;

    emit(state.copyWith(
      project: state.project.copyWith(pages: updatedPages),
      undoStack: _pushHistory(state.project, state.undoStack),
      redoStack: [],
    ));
  }

  void _onToggleLockLayer(
    ToggleLockLayerEvent event,
    Emitter<EditorState> emit,
  ) {
    final activePage = state.activePage;
    final updatedLayers = activePage.layers.map((l) {
      if (l.id == event.layerId) {
        return l.copyWithTransform(locked: !l.locked);
      }
      return l;
    }).toList();

    final updatedPage = activePage.copyWith(layers: updatedLayers);
    final updatedPages = List<CanvasPage>.from(state.project.pages);
    updatedPages[state.project.activePageIndex] = updatedPage;

    emit(state.copyWith(
      project: state.project.copyWith(pages: updatedPages),
      undoStack: _pushHistory(state.project, state.undoStack),
      redoStack: [],
    ));
  }

  void _onToggleVisibilityLayer(
    ToggleVisibilityLayerEvent event,
    Emitter<EditorState> emit,
  ) {
    final activePage = state.activePage;
    final updatedLayers = activePage.layers.map((l) {
      if (l.id == event.layerId) {
        return l.copyWithTransform(visible: !l.visible);
      }
      return l;
    }).toList();

    final updatedPage = activePage.copyWith(layers: updatedLayers);
    final updatedPages = List<CanvasPage>.from(state.project.pages);
    updatedPages[state.project.activePageIndex] = updatedPage;

    emit(state.copyWith(
      project: state.project.copyWith(pages: updatedPages),
      undoStack: _pushHistory(state.project, state.undoStack),
      redoStack: [],
    ));
  }

  void _onAlignSelectedLayers(
    AlignSelectedLayersEvent event,
    Emitter<EditorState> emit,
  ) {
    if (state.selectedLayerIds.isEmpty) return;

    final activePage = state.activePage;
    final selected = state.selectedLayers;
    if (selected.isEmpty) return;

    double targetX = 0;
    double targetY = 0;

    final updatedLayers = List<Layer>.from(activePage.layers);

    for (int i = 0; i < updatedLayers.length; i++) {
      final layer = updatedLayers[i];
      if (!state.selectedLayerIds.contains(layer.id) || layer.locked) continue;

      switch (event.action) {
        case AlignmentAction.left:
          targetX = 0;
          updatedLayers[i] = layer.copyWithTransform(x: targetX);
          break;
        case AlignmentAction.center:
          targetX = (activePage.width - layer.width) / 2;
          updatedLayers[i] = layer.copyWithTransform(x: targetX);
          break;
        case AlignmentAction.right:
          targetX = activePage.width - layer.width;
          updatedLayers[i] = layer.copyWithTransform(x: targetX);
          break;
        case AlignmentAction.top:
          targetY = 0;
          updatedLayers[i] = layer.copyWithTransform(y: targetY);
          break;
        case AlignmentAction.middle:
          targetY = (activePage.height - layer.height) / 2;
          updatedLayers[i] = layer.copyWithTransform(y: targetY);
          break;
        case AlignmentAction.bottom:
          targetY = activePage.height - layer.height;
          updatedLayers[i] = layer.copyWithTransform(y: targetY);
          break;
      }
    }

    final updatedPage = activePage.copyWith(layers: updatedLayers);
    final updatedPages = List<CanvasPage>.from(state.project.pages);
    updatedPages[state.project.activePageIndex] = updatedPage;

    emit(state.copyWith(
      project: state.project.copyWith(pages: updatedPages),
      undoStack: _pushHistory(state.project, state.undoStack),
      redoStack: [],
    ));
  }

  void _onSelectPage(SelectPageEvent event, Emitter<EditorState> emit) {
    if (event.pageIndex < 0 || event.pageIndex >= state.project.pages.length) {
      return;
    }
    emit(state.copyWith(
      project: state.project.copyWith(activePageIndex: event.pageIndex),
      selectedLayerIds: [],
      activeSnapGuides: [],
      activeSpacingMeasurements: [],
    ));
  }

  void _onAddPage(AddPageEvent event, Emitter<EditorState> emit) {
    final newPage = event.page ??
        CanvasPage(
          id: UuidGenerator.generate(),
          name: 'Page ${state.project.pages.length + 1}',
          width: state.activePage.width,
          height: state.activePage.height,
          backgroundType: state.activePage.backgroundType,
          backgroundColor: state.activePage.backgroundColor,
          backgroundGradient: state.activePage.backgroundGradient,
        );

    final updatedPages = List<CanvasPage>.from(state.project.pages)..add(newPage);
    final newIndex = updatedPages.length - 1;

    emit(state.copyWith(
      project: state.project.copyWith(
        pages: updatedPages,
        activePageIndex: newIndex,
      ),
      selectedLayerIds: [],
      undoStack: _pushHistory(state.project, state.undoStack),
      redoStack: [],
    ));
  }

  void _onDuplicatePage(DuplicatePageEvent event, Emitter<EditorState> emit) {
    if (event.pageIndex < 0 || event.pageIndex >= state.project.pages.length) {
      return;
    }
    final originalPage = state.project.pages[event.pageIndex];

    final clonedLayers = originalPage.layers.map((l) {
      return l.copyWithTransform(name: l.name);
    }).toList();

    // Strip leading number if present for clean naming
    String baseName = originalPage.name;
    final regex = RegExp(r'^\d+\s*[-–—]?\s*');
    if (regex.hasMatch(baseName)) {
      baseName = baseName.replaceFirst(regex, '');
    }

    final duplicatedPage = originalPage.copyWith(
      id: UuidGenerator.generate(),
      name: '$baseName Copy',
      layers: clonedLayers,
    );

    final updatedPages = List<CanvasPage>.from(state.project.pages)..add(duplicatedPage);
    final newIndex = updatedPages.length - 1;

    emit(state.copyWith(
      project: state.project.copyWith(
        pages: updatedPages,
        activePageIndex: newIndex,
      ),
      selectedLayerIds: [],
      undoStack: _pushHistory(state.project, state.undoStack),
      redoStack: [],
    ));
  }

  void _onRenameProject(RenameProjectEvent event, Emitter<EditorState> emit) {
    if (event.newName.trim().isEmpty) return;
    emit(state.copyWith(
      project: state.project.copyWith(name: event.newName.trim()),
      undoStack: _pushHistory(state.project, state.undoStack),
      redoStack: [],
    ));
  }

  void _onRenamePage(RenamePageEvent event, Emitter<EditorState> emit) {
    if (event.pageIndex < 0 || event.pageIndex >= state.project.pages.length) return;
    if (event.newName.trim().isEmpty) return;

    final updatedPages = List<CanvasPage>.from(state.project.pages);
    final currentPage = updatedPages[event.pageIndex];
    updatedPages[event.pageIndex] = currentPage.copyWith(name: event.newName.trim());

    emit(state.copyWith(
      project: state.project.copyWith(pages: updatedPages),
      undoStack: _pushHistory(state.project, state.undoStack),
      redoStack: [],
    ));
  }

  void _onUpdatePagePadding(UpdatePagePaddingEvent event, Emitter<EditorState> emit) {
    final updatedPages = List<CanvasPage>.from(state.project.pages);
    final activeIndex = state.project.activePageIndex;
    final currentPage = updatedPages[activeIndex];

    final double oldPadH = currentPage.horizontalPadding;
    final double oldPadV = currentPage.verticalPadding;
    final double newPadH = event.horizontal;
    final double newPadV = event.vertical;

    final double deltaH = newPadH - oldPadH;
    final double deltaV = newPadV - oldPadV;

    // Shift layers according to margin changes so items dynamically follow the margins
    final updatedLayers = currentPage.layers.map((layer) {
      if (layer.locked) return layer;

      double newX = layer.x;
      double newY = layer.y;

      final double centerX = currentPage.width / 2;
      final double centerY = currentPage.height / 2;

      // Horizontal shift based on whether layer was left-anchored, right-anchored, or center
      if (layer.x + layer.width / 2 < centerX) {
        // Left side item -> moves with left margin
        newX = layer.x + deltaH;
      } else {
        // Right side item -> moves with right margin
        newX = layer.x - deltaH;
      }

      // Vertical shift based on top vs bottom anchor
      if (layer.y + layer.height / 2 < centerY) {
        // Top side item -> moves with top margin
        newY = layer.y + deltaV;
      } else {
        // Bottom side item -> moves with bottom margin
        newY = layer.y - deltaV;
      }

      // Clamp strictly within the new page margins
      final double minX = newPadH;
      final double maxX = (currentPage.width - newPadH - layer.width).clamp(minX, currentPage.width);
      final double minY = newPadV;
      final double maxY = (currentPage.height - newPadV - layer.height).clamp(minY, currentPage.height);

      newX = newX.clamp(minX, maxX);
      newY = newY.clamp(minY, maxY);

      return layer.copyWithTransform(x: newX, y: newY);
    }).toList();

    updatedPages[activeIndex] = currentPage.copyWith(
      horizontalPadding: newPadH,
      verticalPadding: newPadV,
      layers: updatedLayers,
    );

    emit(state.copyWith(
      project: state.project.copyWith(pages: updatedPages),
      undoStack: _pushHistory(state.project, state.undoStack),
      redoStack: [],
    ));
  }

  void _onCreateAutoLayoutFromSelection(
    CreateAutoLayoutFromSelectionEvent event,
    Emitter<EditorState> emit,
  ) {
    if (state.selectedLayers.isEmpty) return;

    final selected = List<Layer>.from(state.selectedLayers);
    if (selected.length == 1 && selected.first is AutoLayoutLayer) return;

    double minX = selected.first.x;
    double minY = selected.first.y;
    double maxX = selected.first.x + selected.first.width;
    double maxY = selected.first.y + selected.first.height;

    for (final l in selected) {
      if (l.x < minX) minX = l.x;
      if (l.y < minY) minY = l.y;
      if (l.x + l.width > maxX) maxX = l.x + l.width;
      if (l.y + l.height > maxY) maxY = l.y + l.height;
    }

    // Smart Direction Detection: Analyze spatial arrangement of items relative to each other
    // Compare horizontal origin spread vs vertical origin spread
    double minOriginX = selected.first.x;
    double maxOriginX = selected.first.x;
    double minOriginY = selected.first.y;
    double maxOriginY = selected.first.y;

    for (final l in selected) {
      if (l.x < minOriginX) minOriginX = l.x;
      if (l.x > maxOriginX) maxOriginX = l.x;
      if (l.y < minOriginY) minOriginY = l.y;
      if (l.y > maxOriginY) maxOriginY = l.y;
    }

    final double xSpread = maxOriginX - minOriginX;
    final double ySpread = maxOriginY - minOriginY;

    // If items are positioned under each other (ySpread > xSpread), choose vertical
    // If items are positioned beside each other (xSpread >= ySpread), choose horizontal
    final bool isHorizontal = xSpread > ySpread;

    // Sort items by spatial order along primary axis
    if (isHorizontal) {
      selected.sort((a, b) => a.x.compareTo(b.x));
    } else {
      selected.sort((a, b) => a.y.compareTo(b.y));
    }

    // Calculate natural gap between consecutive items
    double calculatedGap = 12.0;
    if (selected.length > 1) {
      if (isHorizontal) {
        calculatedGap = (selected[1].x - (selected[0].x + selected[0].width)).clamp(0.0, 200.0);
      } else {
        calculatedGap = (selected[1].y - (selected[0].y + selected[0].height)).clamp(0.0, 200.0);
      }
    }

    // Calculate total required dimensions without extra arbitrary padding
    double totalMainAxis = 0;
    double maxCrossAxis = 0;
    for (int i = 0; i < selected.length; i++) {
      totalMainAxis += isHorizontal ? selected[i].width : selected[i].height;
      if (isHorizontal) {
        if (selected[i].height > maxCrossAxis) maxCrossAxis = selected[i].height;
      } else {
        if (selected[i].width > maxCrossAxis) maxCrossAxis = selected[i].width;
      }
      if (i > 0) totalMainAxis += calculatedGap;
    }

    final double layoutWidth = isHorizontal ? totalMainAxis : maxCrossAxis;
    final double layoutHeight = isHorizontal ? maxCrossAxis : totalMainAxis;

    final autoLayoutId = UuidGenerator.generate();
    final autoLayout = AutoLayoutLayer(
      id: autoLayoutId,
      name: 'Auto Layout (${selected.length} items)',
      x: minX,
      y: minY,
      width: layoutWidth.clamp(20.0, state.activePage.width),
      height: layoutHeight.clamp(20.0, state.activePage.height),
      direction: isHorizontal ? AutoLayoutDirection.horizontal : AutoLayoutDirection.vertical,
      gap: calculatedGap,
      paddingHorizontal: 0.0,
      paddingVertical: 0.0,
      alignment: isHorizontal ? AutoLayoutAlignment.center : AutoLayoutAlignment.start,
      distribution: AutoLayoutDistribution.start,
      children: selected.map((l) => l.copyWithTransform(x: 0, y: 0)).toList(),
    );

    final selectedIds = selected.map((l) => l.id).toSet();
    final pageLayers = List<Layer>.from(state.activePage.layers);

    // Insert at the first index of selected layers to maintain layer stack order
    final insertIndex = pageLayers.indexWhere((l) => selectedIds.contains(l.id));
    final remainingLayers = pageLayers.where((l) => !selectedIds.contains(l.id)).toList();

    if (insertIndex != -1 && insertIndex <= remainingLayers.length) {
      remainingLayers.insert(insertIndex, autoLayout);
    } else {
      remainingLayers.add(autoLayout);
    }

    final updatedPages = List<CanvasPage>.from(state.project.pages);
    final activeIndex = state.project.activePageIndex;
    updatedPages[activeIndex] = state.activePage.copyWith(layers: remainingLayers);

    emit(state.copyWith(
      project: state.project.copyWith(pages: updatedPages),
      selectedLayerIds: [autoLayoutId],
      undoStack: _pushHistory(state.project, state.undoStack),
      redoStack: [],
    ));
  }

  void _onUpdateAutoLayout(UpdateAutoLayoutEvent event, Emitter<EditorState> emit) {
    final updatedLayers = _updateAutoLayoutInTree(state.activePage.layers, event.layerId, event);

    final updatedPages = List<CanvasPage>.from(state.project.pages);
    final activeIndex = state.project.activePageIndex;
    updatedPages[activeIndex] = state.activePage.copyWith(layers: updatedLayers);

    emit(state.copyWith(
      project: state.project.copyWith(pages: updatedPages),
      undoStack: _pushHistory(state.project, state.undoStack),
      redoStack: [],
    ));
  }

  void _onRemoveAutoLayout(RemoveAutoLayoutEvent event, Emitter<EditorState> emit) {
    final layers = List<Layer>.from(state.activePage.layers);
    final index = layers.indexWhere((l) => l.id == event.layerId);
    if (index == -1) return;

    final currentLayer = layers[index];
    if (currentLayer is! AutoLayoutLayer) return;

    final unpackedLayers = <Layer>[];

    if (currentLayer.direction == AutoLayoutDirection.horizontal) {
      double currentX = currentLayer.x + currentLayer.paddingHorizontal;
      for (final child in currentLayer.children) {
        double childY;
        switch (currentLayer.alignment) {
          case AutoLayoutAlignment.start:
            childY = currentLayer.y + currentLayer.paddingVertical;
            break;
          case AutoLayoutAlignment.end:
            childY = currentLayer.y + currentLayer.height - currentLayer.paddingVertical - child.height;
            break;
          case AutoLayoutAlignment.center:
          case AutoLayoutAlignment.stretch:
            childY = currentLayer.y + (currentLayer.height - child.height) / 2;
            break;
        }

        unpackedLayers.add(child.copyWithTransform(
          x: currentX,
          y: childY,
        ));

        currentX += child.width + currentLayer.gap;
      }
    } else {
      double currentY = currentLayer.y + currentLayer.paddingVertical;
      for (final child in currentLayer.children) {
        double childX;
        switch (currentLayer.alignment) {
          case AutoLayoutAlignment.start:
            childX = currentLayer.x + currentLayer.paddingHorizontal;
            break;
          case AutoLayoutAlignment.end:
            childX = currentLayer.x + currentLayer.width - currentLayer.paddingHorizontal - child.width;
            break;
          case AutoLayoutAlignment.center:
          case AutoLayoutAlignment.stretch:
            childX = currentLayer.x + (currentLayer.width - child.width) / 2;
            break;
        }

        unpackedLayers.add(child.copyWithTransform(
          x: childX,
          y: currentY,
        ));

        currentY += child.height + currentLayer.gap;
      }
    }

    layers.removeAt(index);
    layers.insertAll(index, unpackedLayers);

    final updatedPages = List<CanvasPage>.from(state.project.pages);
    final activeIndex = state.project.activePageIndex;
    updatedPages[activeIndex] = state.activePage.copyWith(layers: layers);

    emit(state.copyWith(
      project: state.project.copyWith(pages: updatedPages),
      selectedLayerIds: unpackedLayers.map((l) => l.id).toList(),
      undoStack: _pushHistory(state.project, state.undoStack),
      redoStack: [],
    ));
  }

  void _onMoveLayerTree(MoveLayerTreeEvent event, Emitter<EditorState> emit) {
    var layers = List<Layer>.from(state.activePage.layers);

    // 1. Extract layer from its current source (top-level or nested inside AutoLayout)
    final extraction = _extractLayerFromTree(layers, event.layerId);
    if (extraction.layer == null) return;
    final extractedLayer = extraction.layer!;
    layers = extraction.updatedLayers;

    // 2. Insert into destination
    if (event.targetParentId == null) {
      // Top level
      final targetIndex = event.targetIndex.clamp(0, layers.length);
      layers.insert(targetIndex, extractedLayer);
    } else {
      // Inside an AutoLayout container
      layers = _insertLayerIntoParentTree(
        layers,
        event.targetParentId!,
        extractedLayer,
        event.targetIndex,
      );
    }

    final updatedPages = List<CanvasPage>.from(state.project.pages);
    final activeIndex = state.project.activePageIndex;
    updatedPages[activeIndex] = state.activePage.copyWith(layers: layers);

    emit(state.copyWith(
      project: state.project.copyWith(pages: updatedPages),
      selectedLayerIds: [extractedLayer.id],
      undoStack: _pushHistory(state.project, state.undoStack),
      redoStack: [],
    ));
  }

  ({Layer? layer, List<Layer> updatedLayers}) _extractLayerFromTree(
    List<Layer> list,
    String targetId,
  ) {
    Layer? found;
    final result = <Layer>[];

    for (final item in list) {
      if (item.id == targetId) {
        found = item;
      } else if (item is AutoLayoutLayer) {
        final nested = _extractLayerFromTree(item.children, targetId);
        if (nested.layer != null) {
          found = nested.layer;
          final updated = item.copyWith(children: nested.updatedLayers);
          result.add(_recalculateAutoLayoutDimensions(updated));
        } else {
          result.add(item);
        }
      } else {
        result.add(item);
      }
    }

    return (layer: found, updatedLayers: result);
  }

  List<Layer> _insertLayerIntoParentTree(
    List<Layer> list,
    String parentId,
    Layer layerToInsert,
    int targetIndex,
  ) {
    return list.map((item) {
      if (item is AutoLayoutLayer) {
        if (item.id == parentId) {
          final newChildren = List<Layer>.from(item.children);
          final idx = targetIndex.clamp(0, newChildren.length);
          newChildren.insert(idx, layerToInsert);
          final updated = item.copyWith(children: newChildren);
          return _recalculateAutoLayoutDimensions(updated);
        } else {
          final updated = item.copyWith(
            children: _insertLayerIntoParentTree(
              item.children,
              parentId,
              layerToInsert,
              targetIndex,
            ),
          );
          return _recalculateAutoLayoutDimensions(updated);
        }
      }
      return item;
    }).toList();
  }

  static AutoLayoutLayer _recalculateAutoLayoutDimensions(AutoLayoutLayer container) {
    if (container.children.isEmpty) return container;

    final isHorizontal = container.direction == AutoLayoutDirection.horizontal;
    double totalMainAxis = 0;
    double maxCrossAxis = 0;

    for (int i = 0; i < container.children.length; i++) {
      final child = container.children[i];
      if (isHorizontal) {
        totalMainAxis += child.width;
        if (child.height > maxCrossAxis) maxCrossAxis = child.height;
      } else {
        totalMainAxis += child.height;
        if (child.width > maxCrossAxis) maxCrossAxis = child.width;
      }
      if (i > 0) totalMainAxis += container.gap;
    }

    final newWidth = isHorizontal
        ? (totalMainAxis + container.paddingHorizontal * 2)
        : (maxCrossAxis + container.paddingHorizontal * 2);

    final newHeight = isHorizontal
        ? (maxCrossAxis + container.paddingVertical * 2)
        : (totalMainAxis + container.paddingVertical * 2);

    return container.copyWith(
      width: newWidth.clamp(20.0, 5000.0),
      height: newHeight.clamp(20.0, 5000.0),
    );
  }

  List<Layer> _updateAutoLayoutInTree(
    List<Layer> list,
    String targetId,
    UpdateAutoLayoutEvent event,
  ) {
    return list.map((item) {
      if (item is AutoLayoutLayer) {
        if (item.id == targetId) {
          final updated = item.copyWith(
            direction: event.direction,
            gap: event.gap,
            paddingHorizontal: event.paddingHorizontal,
            paddingVertical: event.paddingVertical,
            alignment: event.alignment,
            distribution: event.distribution,
          );
          return _recalculateAutoLayoutDimensions(updated);
        } else {
          final updatedChildren = _updateAutoLayoutInTree(item.children, targetId, event);
          final updated = item.copyWith(children: updatedChildren);
          return _recalculateAutoLayoutDimensions(updated);
        }
      }
      return item;
    }).toList();
  }

  static TextLayer _recalculateTextDimensions(TextLayer textLayer) {
    final style = TextStyle(
      fontFamily: textLayer.fontFamily,
      fontSize: textLayer.fontSize,
      fontWeight: textLayer.fontWeight,
      fontStyle: textLayer.fontStyle,
      letterSpacing: textLayer.letterSpacing,
      height: textLayer.lineHeight,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: textLayer.content.isEmpty ? ' ' : textLayer.content,
        style: style,
      ),
      textDirection: TextDirection.ltr,
      textAlign: textLayer.textAlign,
    )..layout();

    final paddingH = (textLayer.padding?.horizontal ?? 0.0);
    final paddingV = (textLayer.padding?.vertical ?? 0.0);

    // Exact intrinsic width and height hugging without excess margin
    final measuredWidth = (textPainter.width + paddingH).ceilToDouble().clamp(1.0, 5000.0);
    final measuredHeight = (textPainter.height + paddingV).ceilToDouble().clamp(1.0, 5000.0);

    return textLayer.copyWith(
      width: measuredWidth,
      height: measuredHeight,
    );
  }

  static Layer _normalizeLayer(Layer layer) {
    if (layer is TextLayer) {
      return _recalculateTextDimensions(layer);
    } else if (layer is AutoLayoutLayer) {
      final normalizedChildren = layer.children.map(_normalizeLayer).toList();
      final withChildren = layer.copyWith(children: normalizedChildren);
      return _recalculateAutoLayoutDimensions(withChildren);
    }
    return layer;
  }

  static CanvasProject normalizeProject(CanvasProject project) {
    final normalizedPages = project.pages.map((page) {
      final normalizedLayers = page.layers.map(_normalizeLayer).toList();
      return page.copyWith(layers: normalizedLayers);
    }).toList();

    return project.copyWith(pages: normalizedPages);
  }

  List<Layer> _updateLayerInTree(List<Layer> list, Layer updatedLayer) {
    return list.map((item) {
      if (item.id == updatedLayer.id) {
        Layer finalLayer = updatedLayer;
        if (finalLayer is TextLayer) {
          finalLayer = _recalculateTextDimensions(finalLayer);
        } else if (finalLayer is AutoLayoutLayer) {
          finalLayer = _recalculateAutoLayoutDimensions(finalLayer);
        }
        return finalLayer;
      } else if (item is AutoLayoutLayer) {
        final updatedChildren = _updateLayerInTree(item.children, updatedLayer);
        final updated = item.copyWith(children: updatedChildren);
        return _recalculateAutoLayoutDimensions(updated);
      }
      return item;
    }).toList();
  }

  void _onDetachComponentInstance(DetachComponentInstanceEvent event, Emitter<EditorState> emit) {
    final layers = List<Layer>.from(state.activePage.layers);
    final index = layers.indexWhere((l) => l.id == event.layerId);
    if (index == -1) return;

    final currentLayer = layers[index];
    if (currentLayer is! ComponentInstanceLayer) return;

    final def = state.getComponentDefinition(currentLayer.componentDefinitionId);
    if (def == null) return;

    final detachedLayers = def.layers.map((l) {
      return l.copyWithTransform(
        x: currentLayer.x + l.x,
        y: currentLayer.y + l.y,
        name: '${currentLayer.name} - ${l.name}',
      );
    }).toList();

    layers.removeAt(index);
    layers.insertAll(index, detachedLayers);

    final updatedPages = List<CanvasPage>.from(state.project.pages);
    final activeIndex = state.project.activePageIndex;
    updatedPages[activeIndex] = state.activePage.copyWith(layers: layers);

    emit(state.copyWith(
      project: state.project.copyWith(pages: updatedPages),
      selectedLayerIds: detachedLayers.map((l) => l.id).toList(),
      undoStack: _pushHistory(state.project, state.undoStack),
      redoStack: [],
    ));
  }

  void _onDeletePage(DeletePageEvent event, Emitter<EditorState> emit) {
    if (state.project.pages.length <= 1) return;

    final updatedPages = List<CanvasPage>.from(state.project.pages)
      ..removeAt(event.pageIndex);
    int newIndex = state.project.activePageIndex;
    if (newIndex >= updatedPages.length) {
      newIndex = updatedPages.length - 1;
    }

    emit(state.copyWith(
      project: state.project.copyWith(
        pages: updatedPages,
        activePageIndex: newIndex,
      ),
      selectedLayerIds: [],
      undoStack: _pushHistory(state.project, state.undoStack),
      redoStack: [],
    ));
  }

  void _onReorderPage(ReorderPageEvent event, Emitter<EditorState> emit) {
    final updatedPages = List<CanvasPage>.from(state.project.pages);
    final page = updatedPages.removeAt(event.oldIndex);
    int target = event.newIndex;
    if (target > event.oldIndex) target -= 1;
    updatedPages.insert(target.clamp(0, updatedPages.length), page);

    emit(state.copyWith(
      project: state.project.copyWith(
        pages: updatedPages,
        activePageIndex: target,
      ),
      undoStack: _pushHistory(state.project, state.undoStack),
      redoStack: [],
    ));
  }

  void _onUpdatePageBackground(
    UpdatePageBackgroundEvent event,
    Emitter<EditorState> emit,
  ) {
    final activePage = state.activePage;
    final updatedPage = activePage.copyWith(
      backgroundType: event.type,
      backgroundColor: event.color,
      backgroundGradient: event.gradient,
      backgroundImagePath: event.imagePath,
    );

    final updatedPages = List<CanvasPage>.from(state.project.pages);
    updatedPages[state.project.activePageIndex] = updatedPage;

    emit(state.copyWith(
      project: state.project.copyWith(pages: updatedPages),
      undoStack: _pushHistory(state.project, state.undoStack),
      redoStack: [],
    ));
  }

  void _onRegisterComponentDefinition(
    RegisterComponentDefinitionEvent event,
    Emitter<EditorState> emit,
  ) {
    final updatedComponents =
        List<ComponentDefinition>.from(state.project.components)
          ..removeWhere((c) => c.id == event.definition.id)
          ..add(event.definition);

    emit(state.copyWith(
      project: state.project.copyWith(components: updatedComponents),
      undoStack: _pushHistory(state.project, state.undoStack),
      redoStack: [],
    ));
  }

  void _onUpdateComponentDefinition(
    UpdateComponentDefinitionEvent event,
    Emitter<EditorState> emit,
  ) {
    final updatedComponents = state.project.components.map((c) {
      if (c.id == event.definition.id) {
        return event.definition;
      }
      return c;
    }).toList();

    emit(state.copyWith(
      project: state.project.copyWith(components: updatedComponents),
      undoStack: _pushHistory(state.project, state.undoStack),
      redoStack: [],
    ));
  }

  void _onSetZoom(SetZoomEvent event, Emitter<EditorState> emit) {
    emit(state.copyWith(zoom: event.zoom.clamp(0.1, 4.0)));
  }

  void _onSetPanOffset(SetPanOffsetEvent event, Emitter<EditorState> emit) {
    emit(state.copyWith(panOffset: event.offset));
  }

  void _onToggleGrid(ToggleGridEvent event, Emitter<EditorState> emit) {
    final activePage = state.activePage;
    final newShowGrid = !activePage.showGrid;
    final updatedPage = activePage.copyWith(showGrid: newShowGrid);
    final updatedPages = List<CanvasPage>.from(state.project.pages);
    updatedPages[state.project.activePageIndex] = updatedPage;

    emit(state.copyWith(
      showGrid: newShowGrid,
      project: state.project.copyWith(pages: updatedPages),
    ));
  }

  void _onToggleGuides(ToggleGuidesEvent event, Emitter<EditorState> emit) {
    final activePage = state.activePage;
    final newShowGuides = !activePage.showGuides;
    final updatedPage = activePage.copyWith(showGuides: newShowGuides);
    final updatedPages = List<CanvasPage>.from(state.project.pages);
    updatedPages[state.project.activePageIndex] = updatedPage;

    emit(state.copyWith(
      showGuides: newShowGuides,
      project: state.project.copyWith(pages: updatedPages),
    ));
  }

  void _onToggleSnap(ToggleSnapEvent event, Emitter<EditorState> emit) {
    emit(state.copyWith(snapEnabled: !state.snapEnabled));
  }

  void _onUndo(UndoEvent event, Emitter<EditorState> emit) {
    if (!state.canUndo) return;

    final previousProjects = List<CanvasProject>.from(state.undoStack);
    final previousState = previousProjects.removeLast();

    final nextRedo = List<CanvasProject>.from(state.redoStack)
      ..add(state.project);

    emit(state.copyWith(
      project: previousState,
      undoStack: previousProjects,
      redoStack: nextRedo,
      selectedLayerIds: [],
    ));
  }

  void _onRedo(RedoEvent event, Emitter<EditorState> emit) {
    if (!state.canRedo) return;

    final nextRedos = List<CanvasProject>.from(state.redoStack);
    final nextState = nextRedos.removeLast();

    final nextUndo = List<CanvasProject>.from(state.undoStack)
      ..add(state.project);

    emit(state.copyWith(
      project: nextState,
      undoStack: nextUndo,
      redoStack: nextRedos,
      selectedLayerIds: [],
    ));
  }
}
