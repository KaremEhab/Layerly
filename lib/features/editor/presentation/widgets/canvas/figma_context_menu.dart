import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:layerly/features/editor/domain/entities/auto_layout_layer.dart';
import 'package:layerly/features/editor/domain/entities/layer.dart';
import 'package:layerly/features/editor/domain/entities/layer_enums.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_bloc.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_event.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_state.dart';

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
        final autoLayoutLayer = isAutoLayout ? singleLayer as AutoLayoutLayer : null;
        final isLocked = singleLayer?.locked ?? false;
        final isVisible = singleLayer?.visible ?? true;

        const double menuWidth = 240.0;
        final double estimatedHeight = hasSelection ? (isAutoLayout ? 480.0 : 340.0) : 180.0;

        double left = widget.position.dx;
        double top = widget.position.dy;

        if (left + menuWidth > screenSize.width - 16) {
          left = screenSize.width - menuWidth - 16;
        }
        if (top + estimatedHeight > screenSize.height - 16) {
          top = screenSize.height - estimatedHeight - 16;
        }
        left = left.clamp(16.0, screenSize.width - menuWidth - 16);
        top = top.clamp(16.0, screenSize.height - estimatedHeight - 16);

        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // Dismiss background barrier
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _dismiss,
                  onSecondaryTap: _dismiss,
                  child: Container(color: Colors.transparent),
                ),
              ),

              // Menu Popup Container
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
                borderRadius: BorderRadius.circular(10),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E24).withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
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
                          _MenuItem(
                            icon: Icons.select_all_rounded,
                            label: 'Select all',
                            shortcut: 'Ctrl+A',
                            onTap: () => _closeAnd(() {
                              final allIds = widget.state.activePage.layers.map((l) => l.id).toList();
                              widget.bloc.add(SelectMultipleLayersEvent(allIds));
                            }),
                          ),
                          _MenuItem(
                            icon: Icons.grid_on_rounded,
                            label: widget.state.showGrid ? 'Hide grid' : 'Show grid',
                            shortcut: "Ctrl+'",
                            onTap: () => _closeAnd(() {
                              // Grid toggle handled via keyboard / inspector
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
        ],
      ),
    );
  },
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
