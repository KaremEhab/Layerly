import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:layerly/core/constants/app_colors.dart';
import 'package:layerly/features/editor/domain/entities/layer_enums.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_bloc.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_event.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_state.dart';
import 'package:layerly/features/editor/presentation/widgets/canvas/page_renderer.dart';

class EditorCanvas extends StatefulWidget {
  final bool isLockedTop;

  const EditorCanvas({
    super.key,
    this.isLockedTop = true,
  });

  @override
  State<EditorCanvas> createState() => _EditorCanvasState();
}

class _EditorCanvasState extends State<EditorCanvas> {
  final FocusNode _focusNode = FocusNode();
  final TransformationController _transformController = TransformationController();

  @override
  void initState() {
    super.initState();
    if (!widget.isLockedTop) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centerCanvas();
      });
    }
  }

  void _centerCanvas() {
    if (!mounted) return;
    final state = context.read<EditorBloc>().state;
    final size = MediaQuery.of(context).size;
    final pageWidth = state.activePage.width * state.zoom;
    final pageHeight = state.activePage.height * state.zoom;

    final double dx = (size.width - pageWidth) / 2;
    final double dy = (size.height - pageHeight) / 2;

    _transformController.value = Matrix4.identity()
      ..setTranslationRaw(dx > 0 ? dx : 40.0, dy > 0 ? dy : 40.0, 0.0)
      ..scaleByDouble(state.zoom, state.zoom, 1.0, 1.0);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final isControlPressed = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;

    if (event.logicalKey == LogicalKeyboardKey.delete ||
        event.logicalKey == LogicalKeyboardKey.backspace) {
      context.read<EditorBloc>().add(const DeleteSelectedLayersEvent());
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      context.read<EditorBloc>().add(const ClearSelectionEvent());
    } else if (isControlPressed && event.logicalKey == LogicalKeyboardKey.keyZ) {
      if (isShiftPressed) {
        context.read<EditorBloc>().add(const RedoEvent());
      } else {
        context.read<EditorBloc>().add(const UndoEvent());
      }
    } else if (isControlPressed && event.logicalKey == LogicalKeyboardKey.keyY) {
      context.read<EditorBloc>().add(const RedoEvent());
    } else if (isControlPressed && event.logicalKey == LogicalKeyboardKey.keyD) {
      context.read<EditorBloc>().add(const DuplicateSelectedLayersEvent());
    } else if (isControlPressed && event.logicalKey == LogicalKeyboardKey.keyG) {
      if (isShiftPressed) {
        final selected = context.read<EditorBloc>().state.singleSelectedLayer;
        if (selected != null && selected.type == LayerType.componentInstance) {
          context.read<EditorBloc>().add(DetachComponentInstanceEvent(selected.id));
        }
      } else {
        context.read<EditorBloc>().add(const CreateAutoLayoutFromSelectionEvent());
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _nudgeSelected(-1, 0, isShiftPressed ? 10 : 1);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _nudgeSelected(1, 0, isShiftPressed ? 10 : 1);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _nudgeSelected(0, -1, isShiftPressed ? 10 : 1);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _nudgeSelected(0, 1, isShiftPressed ? 10 : 1);
    }
  }

  void _nudgeSelected(double dx, double dy, double multiplier) {
    final state = context.read<EditorBloc>().state;
    for (final layer in state.selectedLayers) {
      context.read<EditorBloc>().add(MoveLayerDeltaEvent(
            layerId: layer.id,
            dx: dx * multiplier,
            dy: dy * multiplier,
            isFinal: true,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: BlocBuilder<EditorBloc, EditorState>(
        builder: (context, state) {
          final activePage = state.activePage;

          return GestureDetector(
            onTapDown: (_) {
              _focusNode.requestFocus();
              context.read<EditorBloc>().add(const ClearSelectionEvent());
            },
            child: widget.isLockedTop
                ? _buildLockedTopCanvas(context, state)
                : _buildFreeInfiniteCanvas(context, state),
          );
        },
      ),
    );
  }

  // 1. Locked on top design container (Non-fullscreen mode as shown in 2nd image)
  Widget _buildLockedTopCanvas(BuildContext context, EditorState state) {
    final activePage = state.activePage;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Fit within horizontal margins and available vertical height
        final availableWidth = (constraints.maxWidth - 32.0).clamp(100.0, 10000.0);
        final availableHeight = (constraints.maxHeight - 16.0).clamp(100.0, 10000.0);
        final pageRatio = activePage.width / activePage.height;

        double fitWidth = availableWidth;
        double fitHeight = fitWidth / pageRatio;

        if (fitHeight > availableHeight) {
          fitHeight = availableHeight;
          fitWidth = fitHeight * pageRatio;
        }

        final double scale = fitWidth / activePage.width;

        return Container(
          color: AppColors.canvasBackground,
          child: Stack(
            children: [
              // Dot Grid Canvas Texture
              Positioned.fill(
                child: CustomPaint(
                  painter: _DotGridPainter(),
                ),
              ),

              // Locked-to-top design container
              Positioned(
                top: 8,
                left: (constraints.maxWidth - fitWidth) / 2,
                width: fitWidth,
                height: fitHeight,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.65),
                        blurRadius: 30,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: const Color(0xFFA970FF).withValues(alpha: 0.12),
                        blurRadius: 45,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      width: fitWidth,
                      height: fitHeight,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: activePage.width,
                          height: activePage.height,
                          child: PageRenderer(
                            page: activePage,
                            selectedLayerIds: state.selectedLayerIds,
                            activeGuides: state.activeSnapGuides,
                            scale: scale,
                            getComponentDefinition: (id) =>
                                state.getComponentDefinition(id),
                            onSelectLayer: (layerId, isMulti) {
                              _focusNode.requestFocus();
                              context.read<EditorBloc>().add(
                                    SelectLayerEvent(layerId, isMultiSelect: isMulti),
                                  );
                            },
                            onMoveLayer: (layerId, details) {
                              context.read<EditorBloc>().add(
                                    MoveLayerDeltaEvent(
                                      layerId: layerId,
                                      dx: details.delta.dx / scale,
                                      dy: details.delta.dy / scale,
                                      isFinal: false,
                                    ),
                                  );
                            },
                            onMoveLayerEnd: (layerId, details) {
                              context.read<EditorBloc>().add(
                                    MoveLayerDeltaEvent(
                                      layerId: layerId,
                                      dx: 0,
                                      dy: 0,
                                      isFinal: true,
                                    ),
                                  );
                            },
                            onResizeLayer: (layerId, handle, details) {
                              context.read<EditorBloc>().add(
                                    ResizeLayerHandleEvent(
                                      layerId: layerId,
                                      handle: handle,
                                      dx: details.delta.dx / scale,
                                      dy: details.delta.dy / scale,
                                      isFinal: false,
                                    ),
                                  );
                            },
                            onResizeLayerEnd: (layerId, handle, details) {
                              context.read<EditorBloc>().add(
                                    ResizeLayerHandleEvent(
                                      layerId: layerId,
                                      handle: handle,
                                      dx: 0,
                                      dy: 0,
                                      isFinal: true,
                                    ),
                                  );
                            },
                            onRotateLayer: (layerId, angle, isFinal) {
                              context.read<EditorBloc>().add(
                                    RotateLayerEvent(
                                      layerId: layerId,
                                      angle: angle,
                                      isFinal: isFinal,
                                    ),
                                  );
                            },
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

  // 2. Free Infinite Canvas with Pan & Zoom (Fullscreen mode)
  Widget _buildFreeInfiniteCanvas(BuildContext context, EditorState state) {
    final activePage = state.activePage;

    return Container(
      color: AppColors.canvasBackground,
      child: Stack(
        children: [
          // Dot Grid Canvas Texture
          Positioned.fill(
            child: CustomPaint(
              painter: _DotGridPainter(),
            ),
          ),

          // Interactive Viewport with Pan and Zoom
          InteractiveViewer(
            transformationController: _transformController,
            minScale: 0.1,
            maxScale: 3.5,
            boundaryMargin: const EdgeInsets.all(2000),
            constrained: false,
            onInteractionUpdate: (details) {
              final scale = _transformController.value.getMaxScaleOnAxis();
              if ((scale - state.zoom).abs() > 0.05) {
                context.read<EditorBloc>().add(SetZoomEvent(scale));
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(200),
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.7),
                        blurRadius: 40,
                        spreadRadius: 10,
                        offset: const Offset(0, 15),
                      ),
                      BoxShadow(
                        color: const Color(0xFFA970FF).withValues(alpha: 0.1),
                        blurRadius: 60,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: PageRenderer(
                      page: activePage,
                      selectedLayerIds: state.selectedLayerIds,
                      activeGuides: state.activeSnapGuides,
                      scale: state.zoom,
                      getComponentDefinition: (id) =>
                          state.getComponentDefinition(id),
                      onSelectLayer: (layerId, isMulti) {
                        _focusNode.requestFocus();
                        context.read<EditorBloc>().add(
                              SelectLayerEvent(layerId, isMultiSelect: isMulti),
                            );
                      },
                      onMoveLayer: (layerId, details) {
                        context.read<EditorBloc>().add(
                              MoveLayerDeltaEvent(
                                layerId: layerId,
                                dx: details.delta.dx,
                                dy: details.delta.dy,
                                isFinal: false,
                              ),
                            );
                      },
                      onMoveLayerEnd: (layerId, details) {
                        context.read<EditorBloc>().add(
                              MoveLayerDeltaEvent(
                                layerId: layerId,
                                dx: 0,
                                dy: 0,
                                isFinal: true,
                              ),
                            );
                      },
                      onResizeLayer: (layerId, handle, details) {
                        context.read<EditorBloc>().add(
                              ResizeLayerHandleEvent(
                                layerId: layerId,
                                handle: handle,
                                dx: details.delta.dx,
                                dy: details.delta.dy,
                                isFinal: false,
                              ),
                            );
                      },
                      onResizeLayerEnd: (layerId, handle, details) {
                        context.read<EditorBloc>().add(
                              ResizeLayerHandleEvent(
                                layerId: layerId,
                                handle: handle,
                                dx: 0,
                                dy: 0,
                                isFinal: true,
                              ),
                            );
                      },
                      onRotateLayer: (layerId, angle, isFinal) {
                        context.read<EditorBloc>().add(
                              RotateLayerEvent(
                                layerId: layerId,
                                angle: angle,
                                isFinal: isFinal,
                              ),
                            );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.canvasDot.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    const double spacing = 28.0;
    const double radius = 1.2;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
