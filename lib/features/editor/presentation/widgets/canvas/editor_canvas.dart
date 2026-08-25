import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:layerly/core/constants/app_colors.dart';
import 'package:layerly/features/editor/domain/entities/canvas_page.dart';
import 'package:layerly/features/editor/domain/entities/layer.dart';
import 'package:layerly/features/editor/domain/entities/auto_layout_layer.dart';
import 'package:layerly/features/editor/domain/entities/layer_enums.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_bloc.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_event.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_state.dart';
import 'package:layerly/features/editor/presentation/widgets/canvas/page_renderer.dart';
import 'package:layerly/features/editor/presentation/widgets/canvas/figma_context_menu.dart';

class EditorCanvas extends StatefulWidget {
  final bool isLockedTop;
  final bool isPreviewOnly;

  const EditorCanvas({
    super.key,
    this.isLockedTop = true,
    this.isPreviewOnly = false,
  });

  @override
  State<EditorCanvas> createState() => _EditorCanvasState();
}

class _EditorCanvasState extends State<EditorCanvas> {
  final FocusNode _focusNode = FocusNode();
  final TransformationController _transformController = TransformationController();

  Offset? _marqueeStart;
  Offset? _marqueeEnd;
  bool _isMarqueeActive = false;
  final Map<int, Offset> _activePointerPositions = {};
  final Map<int, Offset> _pointerStartPositions = {};
  final Map<int, DateTime> _pointerDownTimes = {};
  bool _twoFingerTapCandidate = false;
  Offset? _twoFingerMidpoint;
  DateTime? _twoFingerStartTime;

  void _openContextMenu(Offset globalPosition) {
    final bloc = context.read<EditorBloc>();
    showFigmaContextMenu(
      context: context,
      globalPosition: globalPosition,
      state: bloc.state,
      bloc: bloc,
    );
  }

  Layer? _hitTestLayer(List<Layer> layers, double x, double y) {
    for (int i = layers.length - 1; i >= 0; i--) {
      final l = layers[i];
      if (!l.visible) continue;
      if (l is AutoLayoutLayer && l.children.isNotEmpty) {
        final child = _hitTestLayer(l.children, x - l.x, y - l.y);
        if (child != null) return child;
      }
      if (x >= l.x && x <= l.x + l.width && y >= l.y && y <= l.y + l.height) {
        return l;
      }
    }
    return null;
  }

  void _handleTwoFingerTap(
    Offset screenPos,
    double scale,
    Offset pageOrigin,
    CanvasPage activePage,
  ) {
    final canvasX = (screenPos.dx - pageOrigin.dx) / scale;
    final canvasY = (screenPos.dy - pageOrigin.dy) / scale;
    final hit = _hitTestLayer(activePage.layers, canvasX, canvasY);
    _focusNode.requestFocus();
    if (hit != null) {
      context.read<EditorBloc>().add(SelectLayerEvent(hit.id));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openContextMenu(screenPos);
      });
    } else {
      _openContextMenu(screenPos);
    }
  }

  void _handleTwoFingerTapInfinite(
    Offset screenPos,
    CanvasPage activePage,
  ) {
    final scenePos = _transformController.toScene(screenPos);
    final canvasX = scenePos.dx - 200;
    final canvasY = scenePos.dy - 200;
    final hit = _hitTestLayer(activePage.layers, canvasX, canvasY);
    _focusNode.requestFocus();
    if (hit != null) {
      context.read<EditorBloc>().add(SelectLayerEvent(hit.id));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openContextMenu(screenPos);
      });
    } else {
      _openContextMenu(screenPos);
    }
  }

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

  void _updateMarqueeSelection({
    required Rect screenMarquee,
    required Offset pageOrigin,
    required double scale,
    required CanvasPage activePage,
  }) {
    final canvasLeft = (screenMarquee.left - pageOrigin.dx) / scale;
    final canvasTop = (screenMarquee.top - pageOrigin.dy) / scale;
    final canvasRight = (screenMarquee.right - pageOrigin.dx) / scale;
    final canvasBottom = (screenMarquee.bottom - pageOrigin.dy) / scale;

    final canvasMarquee = Rect.fromLTRB(
      math.min(canvasLeft, canvasRight),
      math.min(canvasTop, canvasBottom),
      math.max(canvasLeft, canvasRight),
      math.max(canvasTop, canvasBottom),
    );

    final matchingIds = <String>[];
    for (final layer in activePage.layers) {
      final layerRect = Rect.fromLTWH(layer.x, layer.y, layer.width, layer.height);
      if (canvasMarquee.overlaps(layerRect) ||
          canvasMarquee.contains(Offset(layer.x + layer.width / 2, layer.y + layer.height / 2))) {
        matchingIds.add(layer.id);
      }
    }

    context.read<EditorBloc>().add(SelectMultipleLayersEvent(matchingIds));
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
          return widget.isLockedTop
              ? _buildLockedTopCanvas(context, state)
              : _buildFreeInfiniteCanvas(context, state);
        },
      ),
    );
  }

  Widget _buildLockedTopCanvas(BuildContext context, EditorState state) {
    final activePage = state.activePage;

    return LayoutBuilder(
      builder: (context, constraints) {
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
        final pageOrigin = Offset((constraints.maxWidth - fitWidth) / 2, 8.0);

        return Listener(
          onPointerDown: (event) {
            _activePointerPositions[event.pointer] = event.position;
            _pointerStartPositions[event.pointer] = event.position;
            _pointerDownTimes[event.pointer] = DateTime.now();

            if (_activePointerPositions.length == 2) {
              final entries = _activePointerPositions.values.toList();
              final times = _pointerDownTimes.values.toList();
              if (times.length >= 2 &&
                  (times[1].difference(times[0])).abs().inMilliseconds < 400) {
                _twoFingerTapCandidate = true;
                _twoFingerMidpoint = (entries[0] + entries[1]) / 2;
                _twoFingerStartTime = DateTime.now();
              }
            } else if (_activePointerPositions.length > 2) {
              _twoFingerTapCandidate = false;
            }
          },
          onPointerMove: (event) {
            if (_activePointerPositions.containsKey(event.pointer)) {
              _activePointerPositions[event.pointer] = event.position;
            }
            if (_pointerStartPositions.containsKey(event.pointer)) {
              final start = _pointerStartPositions[event.pointer]!;
              if ((event.position - start).distance > 24.0) {
                _twoFingerTapCandidate = false;
              }
            }
          },
          onPointerUp: (event) {
            if (_twoFingerTapCandidate &&
                _twoFingerMidpoint != null &&
                _twoFingerStartTime != null) {
              final elapsed =
                  DateTime.now().difference(_twoFingerStartTime!).inMilliseconds;
              if (elapsed < 500) {
                _twoFingerTapCandidate = false;
                final midpoint = _twoFingerMidpoint!;
                _handleTwoFingerTap(midpoint, scale, pageOrigin, activePage);
              }
            }
            _activePointerPositions.remove(event.pointer);
            _pointerStartPositions.remove(event.pointer);
            _pointerDownTimes.remove(event.pointer);
          },
          onPointerCancel: (event) {
            _twoFingerTapCandidate = false;
            _activePointerPositions.remove(event.pointer);
            _pointerStartPositions.remove(event.pointer);
            _pointerDownTimes.remove(event.pointer);
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // A tap on empty canvas clears selection. Doing this on tap-down
            // used to clear a multi-selection before a child layer could claim
            // the gesture, which made selection and dragging feel jumpy.
            onTap: () {
              _focusNode.requestFocus();
              context.read<EditorBloc>().add(const ClearSelectionEvent());
            },
            onSecondaryTapDown: (details) {
              _openContextMenu(details.globalPosition);
            },
            onLongPressStart: (details) {
              _focusNode.requestFocus();
              setState(() {
                _marqueeStart = details.localPosition;
                _marqueeEnd = details.localPosition;
                _isMarqueeActive = true;
              });
            },
            onLongPressMoveUpdate: (details) {
              if (!_isMarqueeActive || _marqueeStart == null) return;
              setState(() {
                _marqueeEnd = details.localPosition;
              });
              _updateMarqueeSelection(
                screenMarquee: Rect.fromPoints(_marqueeStart!, _marqueeEnd!),
                pageOrigin: pageOrigin,
                scale: scale,
                activePage: activePage,
              );
            },
            onLongPressEnd: (_) {
              setState(() {
                _isMarqueeActive = false;
                _marqueeStart = null;
                _marqueeEnd = null;
              });
            },
            onLongPressCancel: () {
              setState(() {
                _isMarqueeActive = false;
                _marqueeStart = null;
                _marqueeEnd = null;
              });
            },
            child: Container(
              color: AppColors.canvasBackground,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _DotGridPainter(),
                    ),
                  ),
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
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Visual background with rounded corners — clipped for aesthetics only
                          Positioned.fill(
                            child: IgnorePointer(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  width: fitWidth,
                                  height: fitHeight,
                                  color: Colors.transparent,
                                ),
                              ),
                            ),
                          ),
                          // Interactive PageRenderer — NOT clipped so layers outside
                          // the page boundary remain selectable and draggable
                          SizedBox(
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
                                  selectedLayerIds: widget.isPreviewOnly ? const [] : state.selectedLayerIds,
                                  activeGuides: widget.isPreviewOnly ? const [] : state.activeSnapGuides,
                                  activeSpacingMeasurements: widget.isPreviewOnly ? const [] : state.activeSpacingMeasurements,
                                  scale: scale,
                                  getComponentDefinition: (id) =>
                                      state.getComponentDefinition(id),
                                  onContextMenu: widget.isPreviewOnly
                                      ? null
                                      : (layerId, globalPosition) {
                                          _openContextMenu(globalPosition);
                                        },
                                  onSelectLayer: widget.isPreviewOnly
                                      ? null
                                      : (layerId, isMulti) {
                                          _focusNode.requestFocus();
                                          context.read<EditorBloc>().add(
                                                SelectLayerEvent(layerId, isMultiSelect: isMulti),
                                              );
                                        },
                                  onMoveLayer: widget.isPreviewOnly
                                      ? null
                                      : (layerId, details) {
                                          context.read<EditorBloc>().add(
                                                MoveLayerDeltaEvent(
                                                  layerId: layerId,
                                                  dx: details.delta.dx,
                                                  dy: details.delta.dy,
                                                  isFinal: false,
                                                ),
                                              );
                                        },
                                  onMoveLayerEnd: widget.isPreviewOnly
                                      ? null
                                      : (layerId, details) {
                                          context.read<EditorBloc>().add(
                                                MoveLayerDeltaEvent(
                                                  layerId: layerId,
                                                  dx: 0,
                                                  dy: 0,
                                                  isFinal: true,
                                                ),
                                              );
                                        },
                                  onResizeLayer: widget.isPreviewOnly
                                      ? null
                                      : (layerId, handle, details) {
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
                                  onResizeLayerEnd: widget.isPreviewOnly
                                      ? null
                                      : (layerId, handle, details) {
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
                                  onRotateLayer: widget.isPreviewOnly
                                      ? null
                                      : (layerId, angle, isFinal) {
                                          context.read<EditorBloc>().add(
                                                RotateLayerEvent(
                                                  layerId: layerId,
                                                  angle: angle,
                                                  isFinal: isFinal,
                                                ),
                                              );
                                        },
                                  hoveredFrameId: widget.isPreviewOnly
                                      ? null
                                      : state.hoveredFrameId,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isMarqueeActive && _marqueeStart != null && _marqueeEnd != null)
                    Positioned.fromRect(
                      rect: Rect.fromPoints(_marqueeStart!, _marqueeEnd!),
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D99FF).withValues(alpha: 0.12),
                            border: Border.all(
                              color: const Color(0xFF0D99FF),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 2. Free Infinite Canvas with Pan & Zoom (Fullscreen mode)
  Widget _buildFreeInfiniteCanvas(BuildContext context, EditorState state) {
    final activePage = state.activePage;

    return Listener(
      onPointerDown: (event) {
        _activePointerPositions[event.pointer] = event.position;
        _pointerStartPositions[event.pointer] = event.position;
        _pointerDownTimes[event.pointer] = DateTime.now();

        if (_activePointerPositions.length == 2) {
          final entries = _activePointerPositions.values.toList();
          final times = _pointerDownTimes.values.toList();
          if (times.length >= 2 &&
              (times[1].difference(times[0])).abs().inMilliseconds < 400) {
            _twoFingerTapCandidate = true;
            _twoFingerMidpoint = (entries[0] + entries[1]) / 2;
            _twoFingerStartTime = DateTime.now();
          }
        } else if (_activePointerPositions.length > 2) {
          _twoFingerTapCandidate = false;
        }
      },
      onPointerMove: (event) {
        if (_activePointerPositions.containsKey(event.pointer)) {
          _activePointerPositions[event.pointer] = event.position;
        }
        if (_pointerStartPositions.containsKey(event.pointer)) {
          final start = _pointerStartPositions[event.pointer]!;
          if ((event.position - start).distance > 24.0) {
            _twoFingerTapCandidate = false;
          }
        }
      },
      onPointerUp: (event) {
        if (_twoFingerTapCandidate &&
            _twoFingerMidpoint != null &&
            _twoFingerStartTime != null) {
          final elapsed =
              DateTime.now().difference(_twoFingerStartTime!).inMilliseconds;
          if (elapsed < 500) {
            _twoFingerTapCandidate = false;
            final midpoint = _twoFingerMidpoint!;
            _handleTwoFingerTapInfinite(midpoint, activePage);
          }
        }
        _activePointerPositions.remove(event.pointer);
        _pointerStartPositions.remove(event.pointer);
        _pointerDownTimes.remove(event.pointer);
      },
      onPointerCancel: (event) {
        _twoFingerTapCandidate = false;
        _activePointerPositions.remove(event.pointer);
        _pointerStartPositions.remove(event.pointer);
        _pointerDownTimes.remove(event.pointer);
      },
      child: Container(
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
                        selectedLayerIds: widget.isPreviewOnly ? const [] : state.selectedLayerIds,
                        activeGuides: widget.isPreviewOnly ? const [] : state.activeSnapGuides,
                        activeSpacingMeasurements: widget.isPreviewOnly ? const [] : state.activeSpacingMeasurements,
                        scale: state.zoom,
                        getComponentDefinition: (id) =>
                            state.getComponentDefinition(id),
                        onContextMenu: widget.isPreviewOnly
                            ? null
                            : (layerId, globalPosition) {
                                _openContextMenu(globalPosition);
                              },
                        onSelectLayer: widget.isPreviewOnly
                            ? null
                            : (layerId, isMulti) {
                                _focusNode.requestFocus();
                                context.read<EditorBloc>().add(
                                      SelectLayerEvent(layerId, isMultiSelect: isMulti),
                                    );
                              },
                        onMoveLayer: widget.isPreviewOnly
                            ? null
                            : (layerId, details) {
                                context.read<EditorBloc>().add(
                                      MoveLayerDeltaEvent(
                                        layerId: layerId,
                                        dx: details.delta.dx,
                                        dy: details.delta.dy,
                                        isFinal: false,
                                      ),
                                    );
                              },
                        onMoveLayerEnd: widget.isPreviewOnly
                            ? null
                            : (layerId, details) {
                                context.read<EditorBloc>().add(
                                      MoveLayerDeltaEvent(
                                        layerId: layerId,
                                        dx: 0,
                                        dy: 0,
                                        isFinal: true,
                                      ),
                                    );
                              },
                        onResizeLayer: widget.isPreviewOnly
                            ? null
                            : (layerId, handle, details) {
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
                        onResizeLayerEnd: widget.isPreviewOnly
                            ? null
                            : (layerId, handle, details) {
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
                        onRotateLayer: widget.isPreviewOnly
                            ? null
                            : (layerId, angle, isFinal) {
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
