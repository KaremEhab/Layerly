import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/layer.dart';
import '../../domain/entities/layer_enums.dart';
import '../../domain/entities/canvas_page.dart';
import '../../domain/entities/canvas_project.dart';
import '../../domain/entities/component_definition.dart';

abstract class EditorEvent extends Equatable {
  const EditorEvent();

  @override
  List<Object?> get props => [];
}

// Project Initialization
class LoadProjectEvent extends EditorEvent {
  final CanvasProject project;
  const LoadProjectEvent(this.project);

  @override
  List<Object?> get props => [project];
}

// Selection & Hover
class SelectLayerEvent extends EditorEvent {
  final String? layerId;
  final bool isMultiSelect;
  const SelectLayerEvent(this.layerId, {this.isMultiSelect = false});

  @override
  List<Object?> get props => [layerId, isMultiSelect];
}

class ClearSelectionEvent extends EditorEvent {
  const ClearSelectionEvent();
}

class SelectMultipleLayersEvent extends EditorEvent {
  final List<String> layerIds;
  const SelectMultipleLayersEvent(this.layerIds);

  @override
  List<Object?> get props => [layerIds];
}

class HoverLayerEvent extends EditorEvent {
  final String? layerId;
  const HoverLayerEvent(this.layerId);

  @override
  List<Object?> get props => [layerId];
}

// Layer Transformations & Actions
class AddLayerEvent extends EditorEvent {
  final Layer layer;
  const AddLayerEvent(this.layer);

  @override
  List<Object?> get props => [layer];
}

class UpdateLayerEvent extends EditorEvent {
  final Layer layer;
  final bool recordHistory;
  const UpdateLayerEvent(this.layer, {this.recordHistory = true});

  @override
  List<Object?> get props => [layer, recordHistory];
}

class MoveLayerDeltaEvent extends EditorEvent {
  final String layerId;
  final double dx;
  final double dy;
  final bool isFinal;
  const MoveLayerDeltaEvent({
    required this.layerId,
    required this.dx,
    required this.dy,
    this.isFinal = false,
  });

  @override
  List<Object?> get props => [layerId, dx, dy, isFinal];
}

class ResizeLayerHandleEvent extends EditorEvent {
  final String layerId;
  final ResizeHandle handle;
  final double dx;
  final double dy;
  final bool lockAspectRatio;
  final bool isFinal;

  const ResizeLayerHandleEvent({
    required this.layerId,
    required this.handle,
    required this.dx,
    required this.dy,
    this.lockAspectRatio = false,
    this.isFinal = false,
  });

  @override
  List<Object?> get props => [layerId, handle, dx, dy, lockAspectRatio, isFinal];
}

class ScaleLayerEvent extends EditorEvent {
  final String layerId;
  final double scaleFactor;

  const ScaleLayerEvent({
    required this.layerId,
    required this.scaleFactor,
  });

  @override
  List<Object?> get props => [layerId, scaleFactor];
}

class RotateLayerEvent extends EditorEvent {
  final String layerId;
  final double angle; // in radians
  final bool isFinal;

  const RotateLayerEvent({
    required this.layerId,
    required this.angle,
    this.isFinal = false,
  });

  @override
  List<Object?> get props => [layerId, angle, isFinal];
}

class DeleteSelectedLayersEvent extends EditorEvent {
  const DeleteSelectedLayersEvent();
}

class DuplicateSelectedLayersEvent extends EditorEvent {
  const DuplicateSelectedLayersEvent();
}

class ReorderLayerEvent extends EditorEvent {
  final String layerId;
  final int newIndex;

  const ReorderLayerEvent(this.layerId, this.newIndex);

  @override
  List<Object?> get props => [layerId, newIndex];
}

class BringForwardEvent extends EditorEvent {
  final String layerId;
  const BringForwardEvent(this.layerId);

  @override
  List<Object?> get props => [layerId];
}

class SendBackwardEvent extends EditorEvent {
  final String layerId;
  const SendBackwardEvent(this.layerId);

  @override
  List<Object?> get props => [layerId];
}

class BringToFrontEvent extends EditorEvent {
  final String layerId;
  const BringToFrontEvent(this.layerId);

  @override
  List<Object?> get props => [layerId];
}

class SendToBackEvent extends EditorEvent {
  final String layerId;
  const SendToBackEvent(this.layerId);

  @override
  List<Object?> get props => [layerId];
}

class ToggleLockLayerEvent extends EditorEvent {
  final String layerId;
  const ToggleLockLayerEvent(this.layerId);

  @override
  List<Object?> get props => [layerId];
}

class ToggleVisibilityLayerEvent extends EditorEvent {
  final String layerId;
  const ToggleVisibilityLayerEvent(this.layerId);

  @override
  List<Object?> get props => [layerId];
}

// Alignment tools
enum AlignmentAction {
  left,
  center,
  right,
  top,
  middle,
  bottom,
}

class AlignSelectedLayersEvent extends EditorEvent {
  final AlignmentAction action;
  const AlignSelectedLayersEvent(this.action);

  @override
  List<Object?> get props => [action];
}

// Pages
class SelectPageEvent extends EditorEvent {
  final int pageIndex;
  const SelectPageEvent(this.pageIndex);

  @override
  List<Object?> get props => [pageIndex];
}

class AddPageEvent extends EditorEvent {
  final CanvasPage? page;
  const AddPageEvent({this.page});

  @override
  List<Object?> get props => [page];
}

class DuplicatePageEvent extends EditorEvent {
  final int pageIndex;
  const DuplicatePageEvent(this.pageIndex);

  @override
  List<Object?> get props => [pageIndex];
}

class DeletePageEvent extends EditorEvent {
  final int pageIndex;
  const DeletePageEvent(this.pageIndex);

  @override
  List<Object?> get props => [pageIndex];
}

class ReorderPageEvent extends EditorEvent {
  final int oldIndex;
  final int newIndex;
  const ReorderPageEvent(this.oldIndex, this.newIndex);

  @override
  List<Object?> get props => [oldIndex, newIndex];
}

class UpdatePageBackgroundEvent extends EditorEvent {
  final BackgroundType type;
  final Color? color;
  final Gradient? gradient;
  final String? imagePath;

  const UpdatePageBackgroundEvent({
    required this.type,
    this.color,
    this.gradient,
    this.imagePath,
  });

  @override
  List<Object?> get props => [type, color, gradient, imagePath];
}

// Component Definitions
class RegisterComponentDefinitionEvent extends EditorEvent {
  final ComponentDefinition definition;
  const RegisterComponentDefinitionEvent(this.definition);

  @override
  List<Object?> get props => [definition];
}

class UpdateComponentDefinitionEvent extends EditorEvent {
  final ComponentDefinition definition;
  const UpdateComponentDefinitionEvent(this.definition);

  @override
  List<Object?> get props => [definition];
}

// Project / Page Metadata Events
class RenameProjectEvent extends EditorEvent {
  final String newName;
  const RenameProjectEvent(this.newName);

  @override
  List<Object?> get props => [newName];
}

class RenamePageEvent extends EditorEvent {
  final int pageIndex;
  final String newName;
  const RenamePageEvent(this.pageIndex, this.newName);

  @override
  List<Object?> get props => [pageIndex, newName];
}

class UpdatePagePaddingEvent extends EditorEvent {
  final double horizontal;
  final double vertical;
  const UpdatePagePaddingEvent({required this.horizontal, required this.vertical});

  @override
  List<Object?> get props => [horizontal, vertical];
}

class UpdatePageDimensionsEvent extends EditorEvent {
  final double width;
  final double height;
  const UpdatePageDimensionsEvent({required this.width, required this.height});

  @override
  List<Object?> get props => [width, height];
}

// Auto Layout Events
class CreateAutoLayoutFromSelectionEvent extends EditorEvent {
  const CreateAutoLayoutFromSelectionEvent();
}

class UpdateAutoLayoutEvent extends EditorEvent {
  final String layerId;
  final AutoLayoutDirection? direction;
  final double? gap;
  final double? paddingHorizontal;
  final double? paddingVertical;
  final AutoLayoutAlignment? alignment;
  final AutoLayoutDistribution? distribution;
  final AutoLayoutSizingMode? horizontalSizing;
  final AutoLayoutSizingMode? verticalSizing;
  final Color? backgroundColor;
  final double? cornerRadius;
  final Color? strokeColor;
  final double? strokeWidth;
  final StrokePosition? strokePosition;

  const UpdateAutoLayoutEvent({
    required this.layerId,
    this.direction,
    this.gap,
    this.paddingHorizontal,
    this.paddingVertical,
    this.alignment,
    this.distribution,
    this.horizontalSizing,
    this.verticalSizing,
    this.backgroundColor,
    this.cornerRadius,
    this.strokeColor,
    this.strokeWidth,
    this.strokePosition,
  });

  @override
  List<Object?> get props => [
        layerId,
        direction,
        gap,
        paddingHorizontal,
        paddingVertical,
        alignment,
        distribution,
        horizontalSizing,
        verticalSizing,
        backgroundColor,
        cornerRadius,
        strokeColor,
        strokeWidth,
        strokePosition,
      ];
}

class RemoveAutoLayoutEvent extends EditorEvent {
  final String layerId;
  const RemoveAutoLayoutEvent(this.layerId);

  @override
  List<Object?> get props => [layerId];
}

class MoveLayerTreeEvent extends EditorEvent {
  final String layerId;
  final String? targetParentId;
  final int targetIndex;

  const MoveLayerTreeEvent({
    required this.layerId,
    this.targetParentId,
    required this.targetIndex,
  });

  @override
  List<Object?> get props => [layerId, targetParentId, targetIndex];
}

class DetachComponentInstanceEvent extends EditorEvent {
  final String layerId;
  const DetachComponentInstanceEvent(this.layerId);

  @override
  List<Object?> get props => [layerId];
}

// Viewport / Studio options
class SetZoomEvent extends EditorEvent {
  final double zoom;
  const SetZoomEvent(this.zoom);

  @override
  List<Object?> get props => [zoom];
}

class SetPanOffsetEvent extends EditorEvent {
  final Offset offset;
  const SetPanOffsetEvent(this.offset);

  @override
  List<Object?> get props => [offset];
}

class ToggleGridEvent extends EditorEvent {
  const ToggleGridEvent();
}

class ToggleGuidesEvent extends EditorEvent {
  const ToggleGuidesEvent();
}

class ToggleSnapEvent extends EditorEvent {
  const ToggleSnapEvent();
}

// History
class UndoEvent extends EditorEvent {
  const UndoEvent();
}

class RedoEvent extends EditorEvent {
  const RedoEvent();
}

