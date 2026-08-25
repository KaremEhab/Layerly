import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:layerly/core/constants/app_colors.dart';
import 'package:layerly/core/utils/svg_vector_parser.dart';
import 'package:layerly/core/widgets/app_modal_sheet.dart';
import 'package:layerly/core/widgets/app_dialog.dart';
import 'package:layerly/features/editor/domain/entities/vector_layer.dart';

/// Opens the interactive Figma-style Vector Node & Multi-Layer Studio.
void showVectorNodeEditorSheet(
  BuildContext context,
  VectorLayer layer, {
  required ValueChanged<VectorLayer> onUpdate,
}) {
  showAppModalSheet(
    context: context,
    builder: (ctx) => _VectorNodeEditorModal(
      initialLayer: layer,
      onUpdate: onUpdate,
    ),
  );
}

class _VectorNodeEditorModal extends StatefulWidget {
  final VectorLayer initialLayer;
  final ValueChanged<VectorLayer> onUpdate;

  const _VectorNodeEditorModal({
    required this.initialLayer,
    required this.onUpdate,
  });

  @override
  State<_VectorNodeEditorModal> createState() => _VectorNodeEditorModalState();
}

class _VectorNodeEditorModalState extends State<_VectorNodeEditorModal> {
  late VectorLayer _layer;
  int _selectedElementIndex = 0;
  int? _selectedPointIndex;
  bool _isPenMode = false; // true = tap to add points, false = drag to move

  @override
  void initState() {
    super.initState();
    _layer = widget.initialLayer;
    if (_layer.elements.isNotEmpty && _layer.elements.first.points.isNotEmpty) {
      _selectedPointIndex = 0;
    }
  }

  void _updateLayer(VectorLayer updated) {
    setState(() {
      _layer = updated;
    });
    widget.onUpdate(updated);
  }

  VectorPathElement get _currentElement {
    if (_layer.elements.isEmpty) {
      return const VectorPathElement(id: '0', name: 'Primary Path', points: []);
    }
    final idx = _selectedElementIndex.clamp(0, _layer.elements.length - 1);
    return _layer.elements[idx];
  }

  void _updateCurrentElement(VectorPathElement updatedElem) {
    final elems = List<VectorPathElement>.from(_layer.elements);
    final idx = _selectedElementIndex.clamp(0, elems.length - 1);
    elems[idx] = updatedElem;
    _updateLayer(_layer.copyWith(elements: elems));
  }

  void _handlePointPan(int index, DragUpdateDetails details, Size canvasSize) {
    final dx = details.delta.dx / canvasSize.width;
    final dy = details.delta.dy / canvasSize.height;

    final pts = List<VectorPoint>.from(_currentElement.points);
    final p = pts[index];
    final newX = (p.x + dx).clamp(0.0, 1.0);
    final newY = (p.y + dy).clamp(0.0, 1.0);

    pts[index] = p.copyWith(x: newX, y: newY);
    _updateCurrentElement(_currentElement.copyWith(points: pts));
  }

  void _togglePointSmoothness(int index) {
    final pts = List<VectorPoint>.from(_currentElement.points);
    final p = pts[index];
    final nextSmooth = !p.isSmooth;

    if (nextSmooth) {
      pts[index] = p.copyWith(
        isSmooth: true,
        handleInX: (p.x - 0.08).clamp(0.0, 1.0),
        handleInY: p.y,
        handleOutX: (p.x + 0.08).clamp(0.0, 1.0),
        handleOutY: p.y,
      );
    } else {
      pts[index] = p.copyWith(isSmooth: false, clearHandles: true);
    }
    _updateCurrentElement(_currentElement.copyWith(points: pts));
  }

  void _deletePoint(int index) {
    if (_currentElement.points.length <= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A sub-layer path must have at least 3 anchor points.'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    final pts = List<VectorPoint>.from(_currentElement.points);
    pts.removeAt(index);
    setState(() {
      _selectedPointIndex = (_selectedPointIndex != null && _selectedPointIndex! >= pts.length)
          ? pts.length - 1
          : _selectedPointIndex;
    });
    _updateCurrentElement(_currentElement.copyWith(points: pts));
  }

  void _addNewPointAtNormalized(Offset normOffset) {
    final pts = List<VectorPoint>.from(_currentElement.points);
    final newPt = VectorPoint(x: normOffset.dx.clamp(0.0, 1.0), y: normOffset.dy.clamp(0.0, 1.0));
    pts.add(newPt);
    setState(() {
      _selectedPointIndex = pts.length - 1;
    });
    _updateCurrentElement(_currentElement.copyWith(points: pts));
  }

  void _showFlutterCodeDialog(BuildContext context) {
    final code = SvgVectorParser.generateFlutterPainterCode(_layer);

    showAppDialog(
      context: context,
      builder: (dialogCtx) => AppDialog(
        icon: Icons.flutter_dash_rounded,
        title: 'Flutter CustomPainter',
        subtitle: 'GPU-accelerated bezier paths for vector sub-layers',
        confirmLabel: 'Copy Code',
        confirmIcon: Icons.copy_rounded,
        onConfirm: () {
          Clipboard.setData(ClipboardData(text: code));
          Navigator.pop(dialogCtx);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Flutter CustomPainter code copied to clipboard!'),
              backgroundColor: Color(0xFF00CEC9),
              duration: Duration(seconds: 2),
            ),
          );
        },
        content: SizedBox(
          width: 540,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 260,
                decoration: BoxDecoration(
                  color: const Color(0xFF0E0D17),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2E2A42)),
                ),
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  child: SelectableText(
                    code,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Color(0xFF55EFC4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final curElem = _currentElement;
    final activePt = (_selectedPointIndex != null && _selectedPointIndex! < curElem.points.length)
        ? curElem.points[_selectedPointIndex!]
        : null;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 16),
        height: MediaQuery.of(context).size.height * 0.90,
        decoration: BoxDecoration(
          color: const Color(0xFF111018),
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
          children: [
            // 1. Figma Vector Header
            _buildHeader(context),

          // 2. Sub-Layers / Elements Chip Bar
          _buildSubLayersBar(),

          // 3. Interactive Vector Stage (Figma Node Canvas)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0910),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF28253B)),
                  ),
                  child: Stack(
                    children: [
                      // Grid background pattern
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _FigmaGridPainter(),
                        ),
                      ),

                      // Interactive Multi-Path Vector Canvas
                      Positioned.fill(
                        child: LayoutBuilder(
                          builder: (ctx, constraints) {
                            final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
                            return GestureDetector(
                              onTapDown: (details) {
                                if (_isPenMode) {
                                  final norm = Offset(
                                    details.localPosition.dx / canvasSize.width,
                                    details.localPosition.dy / canvasSize.height,
                                  );
                                  _addNewPointAtNormalized(norm);
                                }
                              },
                              child: Stack(
                                children: [
                                  // Vector Path Rendering for ALL elements
                                  CustomPaint(
                                    size: canvasSize,
                                    painter: _MultiVectorInteractivePainter(
                                      layer: _layer,
                                      selectedElementIndex: _selectedElementIndex,
                                      selectedPointIndex: _selectedPointIndex,
                                    ),
                                  ),

                                  // Draggable Node Handles for ACTIVE element
                                  for (int i = 0; i < curElem.points.length; i++)
                                    _buildNodeHandle(i, curElem.points[i], canvasSize),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      // Mode Indicator Pill overlay
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1C2B).withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isPenMode ? Icons.edit_rounded : Icons.touch_app_rounded,
                                size: 12,
                                color: const Color(0xFF55EFC4),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isPenMode ? 'Pen: Tap to Add Point' : 'Editing: ${curElem.name}',
                                style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4. Selected Node & Sub-Layer Controls Toolbar
          _buildNodeToolbar(curElem, activePt),
        ],
      ),
    ),
  );
}

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 4),
      child: Column(
        children: [
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
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.polyline_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Figma Vector & Layers Studio',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${_layer.elements.length} Sub-Layers • Multi-Color Paths',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              // Flutter Painter Code button
              InkWell(
                onTap: () => _showFlutterCodeDialog(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00CEC9).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF00CEC9).withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.flutter_dash_rounded, size: 13, color: Color(0xFF00CEC9)),
                      SizedBox(width: 4),
                      Text('Flutter Code', style: TextStyle(color: Color(0xFF00CEC9), fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.check_rounded, size: 15),
                label: const Text('Done'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubLayersBar() {
    return Container(
      height: 38,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _layer.elements.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final elem = _layer.elements[i];
          final isSelected = _selectedElementIndex == i;
          final color = elem.fill ?? elem.strokeColor ?? const Color(0xFF6C5CE7);

          return InkWell(
            onTap: () {
              setState(() {
                _selectedElementIndex = i;
                _selectedPointIndex = elem.points.isNotEmpty ? 0 : null;
              });
            },
            borderRadius: BorderRadius.circular(19),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6C5CE7) : const Color(0xFF1E1C2B),
                borderRadius: BorderRadius.circular(19),
                border: Border.all(
                  color: isSelected ? const Color(0xFFA29BFE) : const Color(0xFF2E2A42),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white60, width: 1),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    elem.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${elem.points.length} pts)',
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : AppColors.textMuted,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNodeHandle(int index, VectorPoint pt, Size canvasSize) {
    final isSelected = _selectedPointIndex == index;
    final pixelX = pt.x * canvasSize.width;
    final pixelY = pt.y * canvasSize.height;

    return Positioned(
      left: pixelX - 16,
      top: pixelY - 16,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPointIndex = index;
          });
        },
        onPanUpdate: (details) => _handlePointPan(index, details, canvasSize),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          color: Colors.transparent,
          child: Container(
            width: isSelected ? 16 : 12,
            height: isSelected ? 16 : 12,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF00CEC9) : Colors.white,
              shape: pt.isSmooth ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: pt.isSmooth ? null : BorderRadius.circular(2),
              border: Border.all(
                color: isSelected ? Colors.white : const Color(0xFF6C5CE7),
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected ? const Color(0xFF00CEC9).withValues(alpha: 0.6) : Colors.black45,
                  blurRadius: isSelected ? 8 : 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNodeToolbar(VectorPathElement curElem, VectorPoint? activePt) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF181622),
        border: Border(top: BorderSide(color: Color(0xFF252236))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Pen Mode, Smooth/Corner Toggle, Delete Point
          Row(
            children: [
              InkWell(
                onTap: () => setState(() => _isPenMode = !_isPenMode),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isPenMode ? const Color(0xFF6C5CE7) : const Color(0xFF242135),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _isPenMode ? const Color(0xFFA29BFE) : Colors.white12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded, size: 14, color: _isPenMode ? Colors.white : AppColors.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        _isPenMode ? 'Pen (Active)' : 'Pen Tool',
                        style: TextStyle(
                          color: _isPenMode ? Colors.white : AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              if (activePt != null && _selectedPointIndex != null) ...[
                // Sharp vs Smooth Vertex Toggle
                InkWell(
                  onTap: () => _togglePointSmoothness(_selectedPointIndex!),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: activePt.isSmooth ? const Color(0xFF00CEC9).withValues(alpha: 0.2) : const Color(0xFF242135),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: activePt.isSmooth ? const Color(0xFF00CEC9) : Colors.white12,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          activePt.isSmooth ? Icons.all_inclusive_rounded : Icons.square_outlined,
                          size: 14,
                          color: activePt.isSmooth ? const Color(0xFF00CEC9) : Colors.white70,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          activePt.isSmooth ? 'Smooth Curve' : 'Sharp Corner',
                          style: TextStyle(
                            color: activePt.isSmooth ? const Color(0xFF00CEC9) : Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Delete Node
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF7675), size: 18),
                  tooltip: 'Delete Anchor Node',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _deletePoint(_selectedPointIndex!),
                ),
              ],
            ],
          ),

          const SizedBox(height: 12),

          // Row 2: Selected Sub-Layer Color Controls
          Row(
            children: [
              // Fill Color
              const Text('Fill:', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _showColorPicker(context, curElem.fill ?? Colors.white, (c) => _updateCurrentElement(curElem.copyWith(fill: c))),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: curElem.fill ?? Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white38),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Stroke Color
              const Text('Stroke:', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _showColorPicker(context, curElem.strokeColor ?? Colors.white, (c) => _updateCurrentElement(curElem.copyWith(strokeColor: c))),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: curElem.strokeColor ?? Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white38),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Stroke Width Stepper
              const Text('Width:', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(width: 6),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF221F32),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF383350)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        final w = (curElem.strokeWidth - 1.0).clamp(0.0, 20.0);
                        _updateCurrentElement(curElem.copyWith(strokeWidth: w));
                      },
                      child: const Icon(Icons.remove, size: 13, color: Colors.white70),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '${curElem.strokeWidth.toInt()}px',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        final w = (curElem.strokeWidth + 1.0).clamp(0.0, 20.0);
                        _updateCurrentElement(curElem.copyWith(strokeWidth: w));
                      },
                      child: const Icon(Icons.add, size: 13, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showColorPicker(BuildContext context, Color initialColor, ValueChanged<Color> onColorChanged) {
    showAppDialog(
      context: context,
      builder: (ctx) => AppDialog(
        icon: Icons.palette_rounded,
        title: 'Pick Color',
        subtitle: 'Select vector element fill or stroke color',
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: initialColor,
            onColorChanged: (c) {
              onColorChanged(c);
              Navigator.pop(ctx);
            },
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// PAINTERS
// -------------------------------------------------------------

class _MultiVectorInteractivePainter extends CustomPainter {
  final VectorLayer layer;
  final int selectedElementIndex;
  final int? selectedPointIndex;

  const _MultiVectorInteractivePainter({
    required this.layer,
    required this.selectedElementIndex,
    this.selectedPointIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int idx = 0; idx < layer.elements.length; idx++) {
      final elem = layer.elements[idx];
      if (!elem.visible || elem.points.isEmpty) continue;

      final path = Path();
      final points = elem.points;

      final startX = points.first.x * size.width;
      final startY = points.first.y * size.height;
      path.moveTo(startX, startY);

      for (int i = 1; i < points.length; i++) {
        final p = points[i];
        final prev = points[i - 1];

        final px = p.x * size.width;
        final py = p.y * size.height;

        if (p.isSmooth && (p.handleInX != null || prev.handleOutX != null)) {
          final cp1x = (prev.handleOutX != null) ? prev.handleOutX! * size.width : prev.x * size.width;
          final cp1y = (prev.handleOutY != null) ? prev.handleOutY! * size.height : prev.y * size.height;
          final cp2x = (p.handleInX != null) ? p.handleInX! * size.width : px;
          final cp2y = (p.handleInY != null) ? p.handleInY! * size.height : py;
          path.cubicTo(cp1x, cp1y, cp2x, cp2y, px, py);
        } else {
          path.lineTo(px, py);
        }
      }

      if (elem.isClosed) {
        final last = points.last;
        final first = points.first;
        if (first.isSmooth && (first.handleInX != null || last.handleOutX != null)) {
          final cp1x = (last.handleOutX != null) ? last.handleOutX! * size.width : last.x * size.width;
          final cp1y = (last.handleOutY != null) ? last.handleOutY! * size.height : last.y * size.height;
          final cp2x = (first.handleInX != null) ? first.handleInX! * size.width : startX;
          final cp2y = (first.handleInY != null) ? first.handleInY! * size.height : startY;
          path.cubicTo(cp1x, cp1y, cp2x, cp2y, startX, startY);
        } else {
          path.close();
        }
      }

      // Draw Fill
      if (elem.fill != null) {
        final fillPaint = Paint()
          ..color = elem.fill!.withValues(alpha: elem.opacity.clamp(0.0, 1.0))
          ..style = PaintingStyle.fill;
        canvas.drawPath(path, fillPaint);
      }

      // Draw Stroke
      if (elem.strokeColor != null && elem.strokeWidth > 0) {
        final strokePaint = Paint()
          ..color = elem.strokeColor!.withValues(alpha: elem.opacity.clamp(0.0, 1.0))
          ..strokeWidth = elem.strokeWidth
          ..strokeCap = elem.strokeCap
          ..strokeJoin = elem.strokeJoin
          ..style = PaintingStyle.stroke;
        canvas.drawPath(path, strokePaint);
      }

      // If this is the active element, highlight its path with a glowing cyan outline!
      if (idx == selectedElementIndex) {
        final highlightPaint = Paint()
          ..color = const Color(0xFF00CEC9)
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;
        canvas.drawPath(path, highlightPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MultiVectorInteractivePainter oldDelegate) => true;
}

class _FigmaGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1.0;

    const step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
