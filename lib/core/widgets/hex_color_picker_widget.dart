import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:layerly/core/constants/app_colors.dart';

class HexColorPickerWidget extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;
  final double pickerAreaHeightPercent;
  final bool enableAlpha;

  const HexColorPickerWidget({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
    this.pickerAreaHeightPercent = 0.65,
    this.enableAlpha = true,
  });

  @override
  State<HexColorPickerWidget> createState() => _HexColorPickerWidgetState();
}

class _HexColorPickerWidgetState extends State<HexColorPickerWidget> {
  late Color _currentColor;
  late TextEditingController _hexController;
  late TextEditingController _opacityController;
  final FocusNode _hexFocusNode = FocusNode();
  final FocusNode _opacityFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentColor = widget.initialColor;
    _hexController = TextEditingController(text: _formatHex(_currentColor));
    _opacityController = TextEditingController(text: '${(_currentColor.a * 100).round()}%');

    _hexFocusNode.addListener(() {
      if (!_hexFocusNode.hasFocus) {
        _hexController.text = _formatHex(_currentColor);
      }
    });

    _opacityFocusNode.addListener(() {
      if (!_opacityFocusNode.hasFocus) {
        _opacityController.text = '${(_currentColor.a * 100).round()}%';
      }
    });
  }

  @override
  void didUpdateWidget(covariant HexColorPickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialColor != widget.initialColor) {
      if (!_hexFocusNode.hasFocus) {
        _currentColor = widget.initialColor;
        _hexController.text = _formatHex(_currentColor);
      }
      if (!_opacityFocusNode.hasFocus) {
        _opacityController.text = '${(_currentColor.a * 100).round()}%';
      }
    }
  }

  String _formatHex(Color c) {
    return '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  void _onColorPicked(Color c) {
    // If the color picker returns a color without maintaining custom alpha, or with alpha
    final newAlpha = widget.enableAlpha ? c.a : _currentColor.a;
    final updatedColor = c.withValues(alpha: newAlpha);

    setState(() {
      _currentColor = updatedColor;
      if (!_hexFocusNode.hasFocus) {
        _hexController.text = _formatHex(updatedColor);
      }
      if (!_opacityFocusNode.hasFocus) {
        _opacityController.text = '${(newAlpha * 100).round()}%';
      }
    });
    widget.onColorChanged(updatedColor);
  }

  void _onHexChanged(String val) {
    String cleaned = val.replaceAll('#', '').trim();
    if (cleaned.length == 3) {
      cleaned = '${cleaned[0]}${cleaned[0]}${cleaned[1]}${cleaned[1]}${cleaned[2]}${cleaned[2]}';
    }
    if (cleaned.length == 6) {
      final intVal = int.tryParse('FF$cleaned', radix: 16);
      if (intVal != null) {
        final c = Color(intVal).withValues(alpha: _currentColor.a);
        setState(() {
          _currentColor = c;
        });
        widget.onColorChanged(c);
      }
    } else if (cleaned.length == 8) {
      final intVal = int.tryParse(cleaned, radix: 16);
      if (intVal != null) {
        final c = Color(intVal);
        setState(() {
          _currentColor = c;
          if (!_opacityFocusNode.hasFocus) {
            _opacityController.text = '${(c.a * 100).round()}%';
          }
        });
        widget.onColorChanged(c);
      }
    }
  }

  void _onOpacityChanged(double newOpacity) {
    final clamped = newOpacity.clamp(0.0, 1.0);
    final updated = _currentColor.withValues(alpha: clamped);
    setState(() {
      _currentColor = updated;
      if (!_opacityFocusNode.hasFocus) {
        _opacityController.text = '${(clamped * 100).round()}%';
      }
    });
    widget.onColorChanged(updated);
  }

  void _onOpacityTextSubmitted(String val) {
    final cleaned = val.replaceAll('%', '').trim();
    final parsed = double.tryParse(cleaned);
    if (parsed != null) {
      final alpha = (parsed / 100.0).clamp(0.0, 1.0);
      _onOpacityChanged(alpha);
    } else {
      _opacityController.text = '${(_currentColor.a * 100).round()}%';
    }
  }

  @override
  void dispose() {
    _hexController.dispose();
    _opacityController.dispose();
    _hexFocusNode.dispose();
    _opacityFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentOpacityPercent = (_currentColor.a * 100).round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ColorPicker(
          pickerColor: _currentColor,
          onColorChanged: _onColorPicked,
          showLabel: false,
          enableAlpha: false,
          pickerAreaHeightPercent: widget.pickerAreaHeightPercent,
        ),
        const SizedBox(height: 12),

        // Hex Code + Opacity Input Row
        Row(
          children: [
            // Hex Code Input Box
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    // Swatch with Checkerboard background
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Stack(
                        children: [
                          CustomPaint(
                            size: const Size(22, 22),
                            painter: const _CheckeredPainter(),
                          ),
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: _currentColor,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white24, width: 1.0),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'HEX',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _hexController,
                        focusNode: _hexFocusNode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          letterSpacing: 1.0,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          hintText: '#RRGGBB',
                          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                        onChanged: _onHexChanged,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.enableAlpha) ...[
              const SizedBox(width: 8),
              // Opacity Input Box
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.opacity_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: _opacityController,
                          focusNode: _opacityFocusNode,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            hintText: '100%',
                            hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                          onSubmitted: _onOpacityTextSubmitted,
                          onChanged: (val) {
                            final cleaned = val.replaceAll('%', '').trim();
                            final parsed = double.tryParse(cleaned);
                            if (parsed != null) {
                              final alpha = (parsed / 100.0).clamp(0.0, 1.0);
                              final updated = _currentColor.withValues(alpha: alpha);
                              setState(() {
                                _currentColor = updated;
                              });
                              widget.onColorChanged(updated);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),

        // Opacity Slider Bar & Quick Chips
        if (widget.enableAlpha) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Opacity',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$currentOpacityPercent%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                // Gradient opacity slider track
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 6,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: Colors.white12,
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    value: _currentColor.a,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (val) {
                      _onOpacityChanged(val);
                    },
                  ),
                ),
                // Quick preset pills
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final p in [100, 75, 50, 25, 0])
                      InkWell(
                        onTap: () => _onOpacityChanged(p / 100.0),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: currentOpacityPercent == p
                                ? AppColors.primary.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: currentOpacityPercent == p
                                  ? AppColors.primary
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            '$p%',
                            style: TextStyle(
                              color: currentOpacityPercent == p ? Colors.white : Colors.white60,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _CheckeredPainter extends CustomPainter {
  final double cellSize;
  const _CheckeredPainter() : cellSize = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final lightPaint = Paint()..color = const Color(0xFF444444);
    final darkPaint = Paint()..color = const Color(0xFF222222);

    final cols = (size.width / cellSize).ceil();
    final rows = (size.height / cellSize).ceil();

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final paint = (r + c) % 2 == 0 ? lightPaint : darkPaint;
        canvas.drawRect(
          Rect.fromLTWH(
            c * cellSize,
            r * cellSize,
            cellSize,
            cellSize,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CheckeredPainter oldDelegate) => false;
}
