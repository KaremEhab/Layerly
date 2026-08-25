import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:layerly/features/editor/domain/entities/auto_layout_layer.dart';
import 'package:layerly/features/editor/domain/entities/layer.dart';
import 'package:layerly/features/editor/domain/entities/layer_enums.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_bloc.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_event.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_state.dart';
import 'package:layerly/core/widgets/hex_color_picker_widget.dart';
import 'package:layerly/features/editor/presentation/widgets/panels/background_picker_sheet.dart';

void showFigmaContextMenu({
  required BuildContext context,
  required Offset globalPosition,
  required EditorState state,
  required EditorBloc bloc,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (ctx) => _FigmaContextMenuOverlay(
      position: globalPosition,
      state: state,
      bloc: bloc,
      onDismiss: () => entry.remove(),
    ),
  );

  overlay.insert(entry);
}

class _FigmaContextMenuOverlay extends StatefulWidget {
  final Offset position;
  final EditorState state;
  final EditorBloc bloc;
  final VoidCallback onDismiss;

  const _FigmaContextMenuOverlay({
    required this.position,
    required this.state,
    required this.bloc,
    required this.onDismiss,
  });

  @override
  State<_FigmaContextMenuOverlay> createState() => _FigmaContextMenuOverlayState();
}

class _FigmaContextMenuOverlayState extends State<_FigmaContextMenuOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _closeAnd(VoidCallback action) {
    _animController.reverse().then((_) {
      widget.onDismiss();
      action();
    });
  }

  void _dismiss() {
    _animController.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return BlocBuilder<EditorBloc, EditorState>(
      bloc: widget.bloc,
      builder: (context, state) {
        final selectedLayers = state.selectedLayers;
        final hasSelection = selectedLayers.isNotEmpty;
        final singleLayer = selectedLayers.length == 1 ? selectedLayers.first : null;
        final isAutoLayout = singleLayer is AutoLayoutLayer;
        final autoLayoutLayer = isAutoLayout ? singleLayer : null;
        final isLocked = singleLayer?.locked ?? false;
        final isVisible = singleLayer?.visible ?? true;

        const double menuWidth = 260.0;
        final double estimatedHeight = hasSelection ? (isAutoLayout ? 540.0 : 400.0) : 530.0;
        final double maxAllowedHeight = math.min(estimatedHeight, (screenSize.height - 32).clamp(120.0, 560.0));

        double left = widget.position.dx;
        double top = widget.position.dy;

        // If tap is in lower portion of the screen, place menu above anchor or shift upward
        if (top + maxAllowedHeight > screenSize.height - 16) {
          final aboveTop = widget.position.dy - maxAllowedHeight - 8;
          if (aboveTop >= 16.0) {
            top = aboveTop;
          } else {
            top = (screenSize.height - maxAllowedHeight - 16).clamp(16.0, screenSize.height - 100);
          }
        }

        if (left + menuWidth > screenSize.width - 16) {
          left = screenSize.width - menuWidth - 16;
        }
        left = left.clamp(16.0, (screenSize.width - menuWidth - 16).clamp(16.0, double.infinity));
        top = top.clamp(16.0, (screenSize.height - 100.0).clamp(16.0, double.infinity));

        final double constrainedMaxHeight = (screenSize.height - top - 16).clamp(120.0, maxAllowedHeight);

        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _dismiss,
                  onSecondaryTap: _dismiss,
                  child: Container(color: Colors.transparent),
                ),
              ),

              Positioned(
                left: left,
                top: top,
                width: menuWidth,
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _opacityAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        alignment: Alignment.topLeft,
                        child: child,
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                      child: Container(
                        constraints: BoxConstraints(maxHeight: constrainedMaxHeight),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E24).withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.65),
                              blurRadius: 28,
                              spreadRadius: 2,
                              offset: const Offset(0, 10),
                            ),
                            BoxShadow(
                              color: const Color(0xFFA970FF).withValues(alpha: 0.15),
                              blurRadius: 20,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (hasSelection) ...[
                                _MenuItem(
                                  icon: Icons.copy_rounded,
                                  label: 'Duplicate',
                                  shortcut: 'Ctrl+D',
                                  onTap: () => _closeAnd(() {
                                    widget.bloc.add(const DuplicateSelectedLayersEvent());
                                  }),
                                ),
                                _MenuItem(
                                  icon: Icons.delete_outline_rounded,
                                  label: 'Delete',
                                  shortcut: 'Del',
                                  textColor: const Color(0xFFFF5C5C),
                                  onTap: () => _closeAnd(() {
                                    widget.bloc.add(const DeleteSelectedLayersEvent());
                                  }),
                                ),
                                _MenuScaleScrubber(
                                  layer: singleLayer ?? selectedLayers.first,
                                  bloc: widget.bloc,
                                ),
                                const _MenuDivider(),
                                _MenuItem(
                                  icon: Icons.flip_to_front_rounded,
                                  label: 'Bring to front',
                                  shortcut: ']',
                                  onTap: () => _closeAnd(() {
                                    if (singleLayer != null) {
                                      widget.bloc.add(BringToFrontEvent(singleLayer.id));
                                    }
                                  }),
                                ),
                          _MenuItem(
                            icon: Icons.flip_to_back_rounded,
                            label: 'Send to back',
                            shortcut: '[',
                            onTap: () => _closeAnd(() {
                              if (singleLayer != null) {
                                widget.bloc.add(SendToBackEvent(singleLayer.id));
                              }
                            }),
                          ),
                          const _MenuDivider(),
                          if (selectedLayers.length > 1)
                            _MenuItem(
                              icon: Icons.view_quilt_rounded,
                              label: 'Add auto layout',
                              shortcut: 'Shift+A',
                              onTap: () => _closeAnd(() {
                                widget.bloc.add(const CreateAutoLayoutFromSelectionEvent());
                              }),
                            ),
                          if (isAutoLayout)
                            _MenuItem(
                              icon: Icons.layers_clear_rounded,
                              label: 'Remove auto layout',
                              shortcut: 'Alt+Shift+A',
                              onTap: () => _closeAnd(() {
                                widget.bloc.add(RemoveAutoLayoutEvent(singleLayer.id));
                              }),
                            ),
                          if (autoLayoutLayer != null) ...[
                            const _MenuDivider(),
                            _MenuItem(
                              icon: Icons.tune_rounded,
                              label: 'Layout settings...',
                              shortcut: 'Alt+S',
                              onTap: () => _closeAnd(() {
                                _showAutoLayoutSettingsDialog(context, autoLayoutLayer);
                              }),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      const SizedBox(
                                        width: 54,
                                        child: Text(
                                          'Width',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: _SizingIconRow(
                                          current: autoLayoutLayer.horizontalSizing,
                                          onSelected: (mode) {
                                            widget.bloc.add(UpdateAutoLayoutEvent(
                                              layerId: autoLayoutLayer.id,
                                              horizontalSizing: mode,
                                            ));
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const SizedBox(
                                        width: 54,
                                        child: Text(
                                          'Height',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: _SizingIconRow(
                                          current: autoLayoutLayer.verticalSizing,
                                          onSelected: (mode) {
                                            widget.bloc.add(UpdateAutoLayoutEvent(
                                              layerId: autoLayoutLayer.id,
                                              verticalSizing: mode,
                                            ));
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Alignment',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  _FigmaAlignmentMatrix(
                                    layer: autoLayoutLayer,
                                    onUpdateAlign: (newAlign, newDist) {
                                      widget.bloc.add(UpdateAutoLayoutEvent(
                                        layerId: autoLayoutLayer.id,
                                        alignment: newAlign,
                                        distribution: newDist,
                                      ));
                                    },
                                    onToggleAutoGap: () {
                                      final isAutoGap = autoLayoutLayer.distribution == AutoLayoutDistribution.spaceBetween;
                                      final nextDist = isAutoGap
                                          ? AutoLayoutDistribution.start
                                          : AutoLayoutDistribution.spaceBetween;
                                      widget.bloc.add(UpdateAutoLayoutEvent(
                                        layerId: autoLayoutLayer.id,
                                        distribution: nextDist,
                                      ));
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Text(
                                        'Fill',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const Spacer(),
                                      for (final fillOption in [
                                        null,
                                        const Color(0xFF1E1E24),
                                        const Color(0xFF2A2A35),
                                        const Color(0xFF6C5CE7),
                                        const Color(0xFF0D99FF),
                                        const Color(0xFFFFFFFF),
                                      ]) ...[
                                        const SizedBox(width: 5),
                                        InkWell(
                                          onTap: () {
                                            widget.bloc.add(UpdateAutoLayoutEvent(
                                              layerId: autoLayoutLayer.id,
                                              backgroundColor: fillOption ?? Colors.transparent,
                                            ));
                                          },
                                          borderRadius: BorderRadius.circular(6),
                                          child: Container(
                                            width: 18,
                                            height: 18,
                                            decoration: BoxDecoration(
                                              color: fillOption ?? Colors.transparent,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: autoLayoutLayer.backgroundColor == fillOption
                                                    ? const Color(0xFF0D99FF)
                                                    : Colors.white24,
                                                width: autoLayoutLayer.backgroundColor == fillOption ? 2 : 1,
                                              ),
                                            ),
                                            child: fillOption == null
                                                ? const Icon(Icons.block_rounded, size: 10, color: Colors.white54)
                                                : null,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(width: 5),
                                      // Custom Fill Color Picker
                                      InkWell(
                                        onTap: () {
                                          _openColorPicker(
                                            context,
                                            autoLayoutLayer.backgroundColor ?? const Color(0xFF6C5CE7),
                                            (c) {
                                              widget.bloc.add(UpdateAutoLayoutEvent(
                                                layerId: autoLayoutLayer.id,
                                                backgroundColor: c == Colors.transparent ? null : c,
                                              ));
                                            },
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          width: 18,
                                          height: 18,
                                          decoration: BoxDecoration(
                                            gradient: const SweepGradient(
                                              colors: [
                                                Colors.red,
                                                Colors.amber,
                                                Colors.green,
                                                Colors.cyan,
                                                Colors.blue,
                                                Colors.purple,
                                                Colors.red,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: (autoLayoutLayer.backgroundColor != null &&
                                                      !const [
                                                        Color(0xFF1E1E24),
                                                        Color(0xFF2A2A35),
                                                        Color(0xFF6C5CE7),
                                                        Color(0xFF0D99FF),
                                                        Color(0xFFFFFFFF),
                                                      ].contains(autoLayoutLayer.backgroundColor))
                                                  ? const Color(0xFF0D99FF)
                                                  : Colors.white30,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: const Icon(Icons.colorize_rounded, size: 10, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  // Stroke Section: Color Presets + Custom Picker + Weight + Position (Inside, Center, Outside)
                                  Row(
                                    children: [
                                      const Text(
                                        'Stroke',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const Spacer(),
                                      for (final strokeOption in [
                                        null,
                                        const Color(0xFFFFFFFF),
                                        const Color(0xFF3A3945),
                                        const Color(0xFF6C5CE7),
                                        const Color(0xFF0D99FF),
                                        const Color(0xFFFFB020),
                                      ]) ...[
                                        const SizedBox(width: 5),
                                        InkWell(
                                          onTap: () {
                                            final currentW = autoLayoutLayer.strokeWidth > 0 ? autoLayoutLayer.strokeWidth : 1.0;
                                            widget.bloc.add(UpdateAutoLayoutEvent(
                                              layerId: autoLayoutLayer.id,
                                              strokeColor: strokeOption ?? Colors.transparent,
                                              strokeWidth: strokeOption == null ? 0.0 : currentW,
                                            ));
                                          },
                                          borderRadius: BorderRadius.circular(6),
                                          child: Container(
                                            width: 18,
                                            height: 18,
                                            decoration: BoxDecoration(
                                              color: strokeOption ?? Colors.transparent,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: (autoLayoutLayer.strokeColor == strokeOption && (strokeOption == null || autoLayoutLayer.strokeWidth > 0))
                                                    ? const Color(0xFF0D99FF)
                                                    : Colors.white24,
                                                width: (autoLayoutLayer.strokeColor == strokeOption && (strokeOption == null || autoLayoutLayer.strokeWidth > 0)) ? 2 : 1,
                                              ),
                                            ),
                                            child: strokeOption == null
                                                ? const Icon(Icons.block_rounded, size: 10, color: Colors.white54)
                                                : null,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(width: 5),
                                      // Custom Stroke Color Picker
                                      InkWell(
                                        onTap: () {
                                          final currentW = autoLayoutLayer.strokeWidth > 0 ? autoLayoutLayer.strokeWidth : 1.0;
                                          _openColorPicker(
                                            context,
                                            autoLayoutLayer.strokeColor ?? const Color(0xFF0D99FF),
                                            (c) {
                                              widget.bloc.add(UpdateAutoLayoutEvent(
                                                layerId: autoLayoutLayer.id,
                                                strokeColor: c == Colors.transparent ? null : c,
                                                strokeWidth: c == Colors.transparent ? 0.0 : currentW,
                                              ));
                                            },
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          width: 18,
                                          height: 18,
                                          decoration: BoxDecoration(
                                            gradient: const SweepGradient(
                                              colors: [
                                                Colors.red,
                                                Colors.amber,
                                                Colors.green,
                                                Colors.cyan,
                                                Colors.blue,
                                                Colors.purple,
                                                Colors.red,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: (autoLayoutLayer.strokeColor != null &&
                                                      !const [
                                                        Color(0xFFFFFFFF),
                                                        Color(0xFF3A3945),
                                                        Color(0xFF6C5CE7),
                                                        Color(0xFF0D99FF),
                                                        Color(0xFFFFB020),
                                                      ].contains(autoLayoutLayer.strokeColor))
                                                  ? const Color(0xFF0D99FF)
                                                  : Colors.white30,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: const Icon(Icons.colorize_rounded, size: 10, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (autoLayoutLayer.strokeColor != null && autoLayoutLayer.strokeWidth > 0) ...[
                                    const SizedBox(height: 6),
                                    // Stroke Weight & Position Row
                                    Row(
                                      children: [
                                        // Weight Stepper
                                        Container(
                                          height: 24,
                                          padding: const EdgeInsets.symmetric(horizontal: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2A2A35),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              InkWell(
                                                onTap: () {
                                                  final newW = (autoLayoutLayer.strokeWidth - 1).clamp(0.0, 50.0);
                                                  widget.bloc.add(UpdateAutoLayoutEvent(
                                                    layerId: autoLayoutLayer.id,
                                                    strokeWidth: newW,
                                                  ));
                                                },
                                                child: const Icon(Icons.remove, size: 12, color: Colors.white70),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${autoLayoutLayer.strokeWidth.toInt()}px',
                                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                              ),
                                              const SizedBox(width: 4),
                                              InkWell(
                                                onTap: () {
                                                  final newW = (autoLayoutLayer.strokeWidth + 1).clamp(0.0, 50.0);
                                                  widget.bloc.add(UpdateAutoLayoutEvent(
                                                    layerId: autoLayoutLayer.id,
                                                    strokeWidth: newW,
                                                  ));
                                                },
                                                child: const Icon(Icons.add, size: 12, color: Colors.white70),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Stroke Position Segmented (Inside / Center / Outside)
                                        Expanded(
                                          child: Container(
                                            height: 24,
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF2A2A35),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              children: [
                                                for (final pos in StrokePosition.values)
                                                  Expanded(
                                                    child: InkWell(
                                                      onTap: () {
                                                        widget.bloc.add(UpdateAutoLayoutEvent(
                                                          layerId: autoLayoutLayer.id,
                                                          strokePosition: pos,
                                                        ));
                                                      },
                                                      borderRadius: BorderRadius.circular(4),
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          color: autoLayoutLayer.strokePosition == pos
                                                              ? const Color(0xFF0D99FF)
                                                              : Colors.transparent,
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        alignment: Alignment.center,
                                                        child: Text(
                                                          pos.name[0].toUpperCase() + pos.name.substring(1),
                                                          style: TextStyle(
                                                            color: autoLayoutLayer.strokePosition == pos
                                                                ? Colors.white
                                                                : Colors.white60,
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                          const _MenuDivider(),
                          _MenuItem(
                            icon: isVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            label: isVisible ? 'Hide' : 'Show',
                            shortcut: 'Ctrl+Shift+H',
                            onTap: () => _closeAnd(() {
                              if (singleLayer != null) {
                                widget.bloc.add(ToggleVisibilityLayerEvent(singleLayer.id));
                              }
                            }),
                          ),
                          _MenuItem(
                            icon: isLocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                            label: isLocked ? 'Unlock' : 'Lock',
                            shortcut: 'Ctrl+Shift+L',
                            onTap: () => _closeAnd(() {
                              if (singleLayer != null) {
                                widget.bloc.add(ToggleLockLayerEvent(singleLayer.id));
                              }
                            }),
                          ),
                        ] else ...[
                          // Page Properties Header
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0D99FF).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.art_track_rounded,
                                    color: Color(0xFF0D99FF),
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.state.activePage.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${widget.state.activePage.width.toInt()} × ${widget.state.activePage.height.toInt()} px',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.5),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const _MenuDivider(),
                          _MenuItem(
                            icon: Icons.auto_awesome_rounded,
                            label: 'Background Studio...',
                            textColor: const Color(0xFFB692F6),
                            onTap: () => _closeAnd(() {
                              showBackgroundPickerSheet(context, widget.state.activePage, bloc: widget.bloc);
                            }),
                          ),
                          _MenuItem(
                            icon: Icons.edit_outlined,
                            label: 'Rename page',
                            onTap: () => _closeAnd(() {
                              _showRenameDialog(context, widget.state.project.activePageIndex, widget.state.activePage.name);
                            }),
                          ),
                          _MenuItem(
                            icon: Icons.copy_rounded,
                            label: 'Duplicate page',
                            shortcut: 'Ctrl+D',
                            onTap: () => _closeAnd(() {
                              widget.bloc.add(DuplicatePageEvent(widget.state.project.activePageIndex));
                            }),
                          ),
                          _MenuItem(
                            icon: Icons.add_to_photos_rounded,
                            label: 'Add new page',
                            onTap: () => _closeAnd(() {
                              widget.bloc.add(const AddPageEvent());
                            }),
                          ),
                          if (widget.state.project.pages.length > 1)
                            _MenuItem(
                              icon: Icons.delete_outline_rounded,
                              label: 'Delete page',
                              shortcut: 'Del',
                              textColor: const Color(0xFFFF5C5C),
                              onTap: () => _closeAnd(() {
                                widget.bloc.add(DeletePageEvent(widget.state.project.activePageIndex));
                              }),
                            ),
                          const _MenuDivider(),
                          const _MenuHeader(label: 'Canvas Presets'),
                          _MenuItem(
                            icon: Icons.crop_square_rounded,
                            label: '1:1 Square (1080×1080)',
                            isSelected: widget.state.activePage.width == 1080 && widget.state.activePage.height == 1080,
                            onTap: () => _closeAnd(() {
                              widget.bloc.add(const UpdatePageDimensionsEvent(width: 1080, height: 1080));
                            }),
                          ),
                          _MenuItem(
                            icon: Icons.stay_current_portrait_rounded,
                            label: '9:16 Story (1080×1920)',
                            isSelected: widget.state.activePage.width == 1080 && widget.state.activePage.height == 1920,
                            onTap: () => _closeAnd(() {
                              widget.bloc.add(const UpdatePageDimensionsEvent(width: 1080, height: 1920));
                            }),
                          ),
                          _MenuItem(
                            icon: Icons.tv_rounded,
                            label: '16:9 Landscape (1920×1080)',
                            isSelected: widget.state.activePage.width == 1920 && widget.state.activePage.height == 1080,
                            onTap: () => _closeAnd(() {
                              widget.bloc.add(const UpdatePageDimensionsEvent(width: 1920, height: 1080));
                            }),
                          ),
                          _MenuItem(
                            icon: Icons.phone_iphone_rounded,
                            label: 'Mobile Frame (393×852)',
                            isSelected: widget.state.activePage.width == 393 && widget.state.activePage.height == 852,
                            onTap: () => _closeAnd(() {
                              widget.bloc.add(const UpdatePageDimensionsEvent(width: 393, height: 852));
                            }),
                          ),
                          _MenuItem(
                            icon: Icons.aspect_ratio_rounded,
                            label: 'Custom dimensions...',
                            onTap: () => _closeAnd(() {
                              _showDimensionsDialog(context, widget.state.activePage.width, widget.state.activePage.height);
                            }),
                          ),
                          const _MenuDivider(),
                          const _MenuHeader(label: 'View & Guides'),
                          _MenuItem(
                            icon: Icons.grid_on_rounded,
                            label: widget.state.showGrid ? 'Hide grid' : 'Show grid',
                            shortcut: "Ctrl+'",
                            isSelected: widget.state.showGrid,
                            onTap: () => _closeAnd(() {
                              widget.bloc.add(const ToggleGridEvent());
                            }),
                          ),
                          _MenuItem(
                            icon: Icons.straighten_rounded,
                            label: widget.state.showGuides ? 'Hide guides' : 'Show guides',
                            shortcut: 'Ctrl+;',
                            isSelected: widget.state.showGuides,
                            onTap: () => _closeAnd(() {
                              widget.bloc.add(const ToggleGuidesEvent());
                            }),
                          ),
                          _MenuItem(
                            icon: Icons.fit_screen_rounded,
                            label: 'Reset page padding (20px)',
                            onTap: () => _closeAnd(() {
                              widget.bloc.add(const UpdatePagePaddingEvent(horizontal: 20, vertical: 20));
                            }),
                          ),
                          const _MenuDivider(),
                          _MenuItem(
                            icon: Icons.select_all_rounded,
                            label: 'Select all layers',
                            shortcut: 'Ctrl+A',
                            onTap: () => _closeAnd(() {
                              final allIds = widget.state.activePage.layers.map((l) => l.id).toList();
                              widget.bloc.add(SelectMultipleLayersEvent(allIds));
                            }),
                          ),
                        ],
                      ],
                    ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  },
);
}

  void _openColorPicker(BuildContext context, Color initialColor, ValueChanged<Color> onColorChanged) {
    Color selected = initialColor == Colors.transparent ? const Color(0xFF6C5CE7) : initialColor;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        title: Row(
          children: [
            const Expanded(
              child: Text('Custom Color', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            InkWell(
              onTap: () {
                onColorChanged(Colors.transparent);
                Navigator.pop(ctx);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A35),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.block_rounded, size: 12, color: Colors.white70),
                    SizedBox(width: 4),
                    Text('No Fill', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: HexColorPickerWidget(
            initialColor: selected,
            onColorChanged: (c) {
              selected = c;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              onColorChanged(selected);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D99FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }



  void _showAutoLayoutSettingsDialog(BuildContext context, AutoLayoutLayer layer) {
    Color? selectedBgColor = layer.backgroundColor;
    bool hasBgFill = layer.backgroundColor != null && layer.backgroundColor != Colors.transparent;
    double selectedCornerRadius = layer.cornerRadius;
    Color? selectedStrokeColor = layer.strokeColor;
    double selectedStrokeWidth = layer.strokeWidth > 0 ? layer.strokeWidth : 1.0;
    StrokePosition selectedStrokePos = layer.strokePosition;
    bool hasStroke = layer.strokeColor != null && layer.strokeColor != Colors.transparent && layer.strokeWidth > 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          ),
          title: const Row(
            children: [
              Icon(Icons.tune_rounded, size: 18, color: Color(0xFF0D99FF)),
              SizedBox(width: 8),
              Expanded(
                child: Text('Layout Settings', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Background Fill Section
                Row(
                  children: [
                    const Text('Background Fill', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    InkWell(
                      onTap: () {
                        setDialogState(() {
                          hasBgFill = false;
                          selectedBgColor = null;
                        });
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A35),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.block_rounded, size: 11, color: Colors.white70),
                            SizedBox(width: 4),
                            Text('No Fill', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ColorPicker(
                  pickerColor: selectedBgColor ?? const Color(0xFF1E1E24),
                  onColorChanged: (c) {
                    setDialogState(() {
                      selectedBgColor = c;
                      hasBgFill = true;
                    });
                  },
                  labelTypes: const [],
                  enableAlpha: false,
                  pickerAreaHeightPercent: 0.55,
                ),
                if (hasBgFill && selectedBgColor != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A35),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: selectedBgColor,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.white24),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '#${(selectedBgColor!).toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Corner Radius Section
                const Text('Corner Radius', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A35),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 14, color: Colors.white70),
                            onPressed: () {
                              setDialogState(() {
                                selectedCornerRadius = (selectedCornerRadius - 2).clamp(0.0, 100.0);
                              });
                            },
                          ),
                          Text('${selectedCornerRadius.toInt()} px', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add, size: 14, color: Colors.white70),
                            onPressed: () {
                              setDialogState(() {
                                selectedCornerRadius = (selectedCornerRadius + 2).clamp(0.0, 100.0);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    for (final r in [0.0, 8.0, 12.0, 20.0]) ...[
                      InkWell(
                        onTap: () {
                          setDialogState(() {
                            selectedCornerRadius = r;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                          decoration: BoxDecoration(
                            color: selectedCornerRadius == r ? const Color(0xFF0D99FF) : const Color(0xFF2A2A35),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('${r.toInt()}px', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // Stroke Settings Header
                Row(
                  children: [
                    const Text('Stroke', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    InkWell(
                      onTap: () {
                        setDialogState(() {
                          hasStroke = false;
                          selectedStrokeColor = null;
                        });
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A35),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.block_rounded, size: 11, color: Colors.white70),
                            SizedBox(width: 4),
                            Text('No Stroke', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Weight Stepper
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A35),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 14, color: Colors.white70),
                            onPressed: () {
                              setDialogState(() {
                                selectedStrokeWidth = (selectedStrokeWidth - 1).clamp(1.0, 50.0);
                                hasStroke = true;
                                selectedStrokeColor ??= const Color(0xFFFFFFFF);
                              });
                            },
                          ),
                          Text('${selectedStrokeWidth.toInt()} px', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add, size: 14, color: Colors.white70),
                            onPressed: () {
                              setDialogState(() {
                                selectedStrokeWidth = (selectedStrokeWidth + 1).clamp(1.0, 50.0);
                                hasStroke = true;
                                selectedStrokeColor ??= const Color(0xFFFFFFFF);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    for (final w in [1.0, 2.0, 4.0]) ...[
                      InkWell(
                        onTap: () {
                          setDialogState(() {
                            selectedStrokeWidth = w;
                            hasStroke = true;
                            selectedStrokeColor ??= const Color(0xFFFFFFFF);
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                          decoration: BoxDecoration(
                            color: selectedStrokeWidth == w && hasStroke ? const Color(0xFF0D99FF) : const Color(0xFF2A2A35),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('${w.toInt()}px', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // Stroke Position (Inside / Center / Outside)
                const Text('Stroke Position', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Container(
                  height: 36,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      for (final pos in StrokePosition.values)
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setDialogState(() {
                                selectedStrokePos = pos;
                                hasStroke = true;
                                selectedStrokeColor ??= const Color(0xFFFFFFFF);
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: selectedStrokePos == pos && hasStroke
                                    ? const Color(0xFF0D99FF)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                pos.name[0].toUpperCase() + pos.name.substring(1),
                                style: TextStyle(
                                  color: selectedStrokePos == pos && hasStroke ? Colors.white : Colors.white60,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Stroke Color Picker
                const Text('Stroke Color', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                ColorPicker(
                  pickerColor: selectedStrokeColor ?? const Color(0xFFFFFFFF),
                  onColorChanged: (c) {
                    setDialogState(() {
                      selectedStrokeColor = c;
                      hasStroke = true;
                    });
                  },
                  labelTypes: const [],
                  enableAlpha: false,
                  pickerAreaHeightPercent: 0.55,
                ),
                if (hasStroke && selectedStrokeColor != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A35),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: selectedStrokeColor,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.white24),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '#${(selectedStrokeColor!).toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: () {
                widget.bloc.add(UpdateAutoLayoutEvent(
                  layerId: layer.id,
                  backgroundColor: hasBgFill ? selectedBgColor : Colors.transparent,
                  cornerRadius: selectedCornerRadius,
                  strokeColor: hasStroke ? selectedStrokeColor : Colors.transparent,
                  strokeWidth: hasStroke ? selectedStrokeWidth : 0.0,
                  strokePosition: selectedStrokePos,
                ));
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D99FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, int pageIndex, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        title: const Text(
          'Rename Page',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF2A2A32),
            hintText: 'Enter page name',
            hintStyle: const TextStyle(color: Colors.white38),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF0D99FF)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                widget.bloc.add(RenamePageEvent(pageIndex, controller.text.trim()));
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D99FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDimensionsDialog(BuildContext context, double currentWidth, double currentHeight) {
    final widthController = TextEditingController(text: currentWidth.toInt().toString());
    final heightController = TextEditingController(text: currentHeight.toInt().toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        title: const Text(
          'Custom Page Dimensions',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Width (px)', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: widthController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF2A2A32),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text('×', style: TextStyle(color: Colors.white54, fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Height (px)', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: heightController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF2A2A32),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              final w = double.tryParse(widthController.text) ?? currentWidth;
              final h = double.tryParse(heightController.text) ?? currentHeight;
              widget.bloc.add(UpdatePageDimensionsEvent(width: w, height: h));
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D99FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

class _MenuHeader extends StatelessWidget {
  final String label;
  const _MenuHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 14, top: 4, bottom: 2),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.38),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _MenuItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? shortcut;
  final Color? textColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.shortcut,
    this.textColor,
    this.isSelected = false,
  });

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final textColor = widget.textColor ?? Colors.white.withValues(alpha: 0.9);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: _isHovered
                ? const Color(0xFFA970FF).withValues(alpha: 0.25)
                : (widget.isSelected ? const Color(0xFFA970FF).withValues(alpha: 0.12) : Colors.transparent),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: widget.isSelected
                    ? const Color(0xFFA970FF)
                    : (_isHovered ? const Color(0xFFA970FF) : textColor.withValues(alpha: 0.7)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.isSelected ? const Color(0xFFA970FF) : (_isHovered ? Colors.white : textColor),
                    fontSize: 13,
                    fontWeight: widget.isSelected || _isHovered ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              if (widget.isSelected)
                const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: Color(0xFFA970FF),
                )
              else if (widget.shortcut != null)
                Text(
                  widget.shortcut!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Colors.white.withValues(alpha: 0.08),
      ),
    );
  }
}

class _SizingIconRow extends StatelessWidget {
  final AutoLayoutSizingMode current;
  final ValueChanged<AutoLayoutSizingMode> onSelected;

  const _SizingIconRow({
    required this.current,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          _buildIconBtn(
            icon: Icons.compress_rounded,
            tooltip: 'Hug contents',
            isSelected: current == AutoLayoutSizingMode.hug,
            onTap: () => onSelected(AutoLayoutSizingMode.hug),
          ),
          _buildIconBtn(
            icon: Icons.fullscreen_rounded,
            tooltip: 'Fill container',
            isSelected: current == AutoLayoutSizingMode.fill,
            onTap: () => onSelected(AutoLayoutSizingMode.fill),
          ),
          _buildIconBtn(
            icon: Icons.lock_outline_rounded,
            tooltip: 'Fixed size',
            isSelected: current == AutoLayoutSizingMode.fixed,
            onTap: () => onSelected(AutoLayoutSizingMode.fixed),
          ),
        ],
      ),
    );
  }

  Widget _buildIconBtn({
    required IconData icon,
    required String tooltip,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFA970FF) : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFFA970FF).withValues(alpha: 0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}

class _FigmaAlignmentMatrix extends StatelessWidget {
  final AutoLayoutLayer layer;
  final void Function(AutoLayoutAlignment newAlign, AutoLayoutDistribution newDist) onUpdateAlign;
  final VoidCallback onToggleAutoGap;

  const _FigmaAlignmentMatrix({
    required this.layer,
    required this.onUpdateAlign,
    required this.onToggleAutoGap,
  });

  @override
  Widget build(BuildContext context) {
    final isAutoGap = layer.distribution == AutoLayoutDistribution.spaceBetween;
    final isHorizontal = layer.direction == AutoLayoutDirection.horizontal;

    int activeRow;
    int activeCol;

    if (isHorizontal) {
      switch (layer.alignment) {
        case AutoLayoutAlignment.start:
          activeRow = 0;
          break;
        case AutoLayoutAlignment.center:
        case AutoLayoutAlignment.stretch:
          activeRow = 1;
          break;
        case AutoLayoutAlignment.end:
          activeRow = 2;
          break;
      }
      switch (layer.distribution) {
        case AutoLayoutDistribution.start:
        case AutoLayoutDistribution.spaceBetween:
          activeCol = 0;
          break;
        case AutoLayoutDistribution.center:
          activeCol = 1;
          break;
        case AutoLayoutDistribution.end:
          activeCol = 2;
          break;
      }
    } else {
      switch (layer.distribution) {
        case AutoLayoutDistribution.start:
        case AutoLayoutDistribution.spaceBetween:
          activeRow = 0;
          break;
        case AutoLayoutDistribution.center:
          activeRow = 1;
          break;
        case AutoLayoutDistribution.end:
          activeRow = 2;
          break;
      }
      switch (layer.alignment) {
        case AutoLayoutAlignment.start:
          activeCol = 0;
          break;
        case AutoLayoutAlignment.center:
        case AutoLayoutAlignment.stretch:
          activeCol = 1;
          break;
        case AutoLayoutAlignment.end:
          activeCol = 2;
          break;
      }
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: onToggleAutoGap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 82,
        decoration: BoxDecoration(
          color: const Color(0xFF232328),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isAutoGap ? const Color(0xFF0D99FF) : Colors.white.withValues(alpha: 0.08),
            width: isAutoGap ? 1.5 : 1.0,
          ),
          boxShadow: isAutoGap
              ? [
                  BoxShadow(
                    color: const Color(0xFF0D99FF).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (int r = 0; r < 3; r++)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (int c = 0; c < 3; c++)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (isHorizontal) {
                          final newAlign = r == 0
                              ? AutoLayoutAlignment.start
                              : (r == 1 ? AutoLayoutAlignment.center : AutoLayoutAlignment.end);
                          final newDist = isAutoGap
                              ? AutoLayoutDistribution.spaceBetween
                              : (c == 0
                                  ? AutoLayoutDistribution.start
                                  : (c == 1 ? AutoLayoutDistribution.center : AutoLayoutDistribution.end));
                          onUpdateAlign(newAlign, newDist);
                        } else {
                          final newDist = isAutoGap
                              ? AutoLayoutDistribution.spaceBetween
                              : (r == 0
                                  ? AutoLayoutDistribution.start
                                  : (r == 1 ? AutoLayoutDistribution.center : AutoLayoutDistribution.end));
                          final newAlign = c == 0
                              ? AutoLayoutAlignment.start
                              : (c == 1 ? AutoLayoutAlignment.center : AutoLayoutAlignment.end);
                          onUpdateAlign(newAlign, newDist);
                        }
                      },
                      onDoubleTap: onToggleAutoGap,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          width: 28,
                          height: 18,
                          alignment: Alignment.center,
                          child: _buildMatrixCellContent(
                            r: r,
                            c: c,
                            activeRow: activeRow,
                            activeCol: activeCol,
                            isAutoGap: isAutoGap,
                            isHorizontal: isHorizontal,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatrixCellContent({
    required int r,
    required int c,
    required int activeRow,
    required int activeCol,
    required bool isAutoGap,
    required bool isHorizontal,
  }) {
    const activeColor = Color(0xFF70B6FF);
    final inactiveColor = Colors.white.withValues(alpha: 0.35);

    if (isAutoGap) {
      if (isHorizontal) {
        if (r == activeRow) {
          if (c == 0 || c == 2) {
            return Container(
              width: 2.5,
              height: 14,
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(1.2),
              ),
            );
          } else {
            return Container(
              width: 2.5,
              height: 6,
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(1.2),
              ),
            );
          }
        }
      } else {
        if (c == activeCol) {
          if (r == 0 || r == 2) {
            return Container(
              width: 14,
              height: 2.5,
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(1.2),
              ),
            );
          } else {
            return Container(
              width: 6,
              height: 2.5,
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(1.2),
              ),
            );
          }
        }
      }
    } else {
      if (r == activeRow && c == activeCol) {
        if (isHorizontal) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 2.2,
                height: 9,
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(1.0),
                ),
              ),
              const SizedBox(width: 1.5),
              Container(
                width: 2.2,
                height: 13,
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(1.0),
                ),
              ),
              const SizedBox(width: 1.5),
              Container(
                width: 2.2,
                height: 9,
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(1.0),
                ),
              ),
            ],
          );
        } else {
          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 9,
                height: 2.2,
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(1.0),
                ),
              ),
              const SizedBox(height: 1.5),
              Container(
                width: 13,
                height: 2.2,
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(1.0),
                ),
              ),
              const SizedBox(height: 1.5),
              Container(
                width: 9,
                height: 2.2,
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(1.0),
                ),
              ),
            ],
          );
        }
      }
    }

    return Container(
      width: 3.5,
      height: 3.5,
      decoration: BoxDecoration(
        color: inactiveColor,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _MenuScaleScrubber extends StatefulWidget {
  final Layer layer;
  final EditorBloc bloc;

  const _MenuScaleScrubber({
    required this.layer,
    required this.bloc,
  });

  @override
  State<_MenuScaleScrubber> createState() => _MenuScaleScrubberState();
}

class _MenuScaleScrubberState extends State<_MenuScaleScrubber> {
  double _currentPercent = 100.0;
  bool _isDragging = false;

  void _applyDelta(double deltaPercent) {
    final nextPercent = (_currentPercent + deltaPercent).clamp(10.0, 500.0);
    if (nextPercent == _currentPercent) return;
    final factor = nextPercent / _currentPercent;
    setState(() {
      _currentPercent = nextPercent;
    });
    widget.bloc.add(ScaleLayerEvent(
      layerId: widget.layer.id,
      scaleFactor: factor,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: _isDragging ? const Color(0xFF2E2E3A) : const Color(0xFF25252E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _isDragging ? const Color(0xFF0D99FF).withValues(alpha: 0.6) : Colors.white10,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.aspect_ratio_rounded, size: 14, color: Colors.white70),
            const SizedBox(width: 8),
            const Text(
              'Scale',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            // Quick Decrement
            InkWell(
              onTap: () => _applyDelta(-10.0),
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.all(2.0),
                child: Icon(Icons.remove, size: 13, color: Colors.white60),
              ),
            ),
            const SizedBox(width: 4),
            // Draggable / Scrubbable % Badge
            GestureDetector(
              onHorizontalDragStart: (_) => setState(() => _isDragging = true),
              onHorizontalDragUpdate: (details) {
                _applyDelta(details.delta.dx * 0.75);
              },
              onHorizontalDragEnd: (_) => setState(() => _isDragging = false),
              onHorizontalDragCancel: () => setState(() => _isDragging = false),
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeLeftRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _isDragging ? const Color(0xFF0D99FF) : const Color(0xFF1E1E24),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _isDragging ? const Color(0xFF0D99FF) : Colors.white24,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.swap_horiz_rounded, size: 11, color: Colors.white54),
                      const SizedBox(width: 3),
                      Text(
                        '${_currentPercent.round()}%',
                        style: TextStyle(
                          color: _isDragging ? Colors.white : const Color(0xFF0D99FF),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Quick Increment
            InkWell(
              onTap: () => _applyDelta(10.0),
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.all(2.0),
                child: Icon(Icons.add, size: 13, color: Colors.white60),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

