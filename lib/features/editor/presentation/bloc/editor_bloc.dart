import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'package:layerly/features/editor/domain/services/snapping_service.dart';
import 'package:layerly/core/utils/uuid_generator.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_event.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_state.dart';

class EditorBloc extends Bloc<EditorEvent, EditorState> {
  static const int maxHistoryLength = 50;

  EditorBloc({required CanvasProject initialProject})
      : super(EditorState(project: initialProject)) {
    on<LoadProjectEvent>(_onLoadProject);
    on<SelectLayerEvent>(_onSelectLayer);
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
      project: event.project,
      selectedLayerIds: const [],
      undoStack: const [],
      redoStack: const [],
    ));
  }

  void _onSelectLayer(SelectLayerEvent event, Emitter<EditorState> emit) {
    if (event.layerId == null) {
      emit(state.copyWith(selectedLayerIds: []));
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
      emit(state.copyWith(selectedLayerIds: [event.layerId!]));
    }
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
    final activePage = state.activePage;
    final updatedLayers = List<Layer>.from(activePage.layers)..add(event.layer);
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
    final updatedLayers = activePage.layers.map((layer) {
      if (layer.id == event.layer.id) {
        return event.layer;
      }
      return layer;
    }).toList();

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
    final activePage = state.activePage;
    final layerIndex = activePage.layers.indexWhere((l) => l.id == event.layerId);
    if (layerIndex == -1) return;

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

    final updatedLayer = layer.copyWithTransform(
      x: snap.snappedX,
      y: snap.snappedY,
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
    final layerIndex = activePage.layers.indexWhere((l) => l.id == event.layerId);
    if (layerIndex == -1) return;

    final layer = activePage.layers[layerIndex];
    if (layer.locked) return;

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

    final updatedLayers = List<Layer>.from(activePage.layers);
    updatedLayers[layerIndex] = updatedLayer;

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
    final layerIndex = activePage.layers.indexWhere((l) => l.id == event.layerId);
    if (layerIndex == -1) return;

    final layer = activePage.layers[layerIndex];
    if (layer.locked) return;

    final updatedLayer = layer.copyWithTransform(rotation: event.angle);
    final updatedLayers = List<Layer>.from(activePage.layers);
    updatedLayers[layerIndex] = updatedLayer;

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

    final duplicatedPage = originalPage.copyWith(
      id: UuidGenerator.generate(),
      name: '${originalPage.name} Copy',
      layers: clonedLayers,
    );

    final updatedPages = List<CanvasPage>.from(state.project.pages);
    updatedPages.insert(event.pageIndex + 1, duplicatedPage);

    emit(state.copyWith(
      project: state.project.copyWith(
        pages: updatedPages,
        activePageIndex: event.pageIndex + 1,
      ),
      selectedLayerIds: [],
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
    emit(state.copyWith(showGrid: !state.showGrid));
  }

  void _onToggleGuides(ToggleGuidesEvent event, Emitter<EditorState> emit) {
    emit(state.copyWith(showGuides: !state.showGuides));
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
