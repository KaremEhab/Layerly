import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:layerly/features/editor/domain/entities/auto_layout_layer.dart';
import 'package:layerly/features/editor/domain/entities/layer.dart';
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
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _opacityAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _closeAnd(VoidCallback action) {
    widget.onDismiss();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    const menuWidth = 240.0;
    const estimatedHeight = 380.0;

    // Clamp position within screen bounds
    double left = widget.position.dx;
    double top = widget.position.dy;

    if (left + menuWidth > screenSize.width - 12) {
      left = screenSize.width - menuWidth - 12;
    }
    if (left < 12) left = 12;

    if (top + estimatedHeight > screenSize.height - 12) {
      top = screenSize.height - estimatedHeight - 12;
    }
    if (top < 12) top = 12;

    final selectedLayers = widget.state.selectedLayers;
    final hasSelection = selectedLayers.isNotEmpty;
    final singleLayer = widget.state.singleSelectedLayer;
    final isAutoLayout = singleLayer is AutoLayoutLayer;
    final isLocked = singleLayer?.locked ?? false;
    final isVisible = singleLayer?.visible ?? true;

    return Stack(
      children: [
        // Transparent dismiss barrier
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onDismiss,
            onSecondaryTap: widget.onDismiss,
            child: const ColoredBox(color: Colors.transparent),
          ),
        ),

        // Context Menu Card
        Positioned(
          left: left,
          top: top,
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              alignment: Alignment.topLeft,
              child: Material(
                color: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      width: menuWidth,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E24).withValues(alpha: 0.96),
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
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? shortcut;
  final Color? textColor;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.shortcut,
    this.textColor,
    required this.onTap,
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
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: _isHovered ? const Color(0xFFA970FF) : textColor.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: _isHovered ? Colors.white : textColor,
                    fontSize: 13,
                    fontWeight: _isHovered ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              if (widget.shortcut != null)
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
