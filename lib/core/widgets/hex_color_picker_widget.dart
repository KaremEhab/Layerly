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
    this.enableAlpha = false,
  });

  @override
  State<HexColorPickerWidget> createState() => _HexColorPickerWidgetState();
}

class _HexColorPickerWidgetState extends State<HexColorPickerWidget> {
  late Color _currentColor;
  late TextEditingController _hexController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentColor = widget.initialColor;
    _hexController = TextEditingController(text: _formatHex(_currentColor));
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _hexController.text = _formatHex(_currentColor);
      }
    });
  }

  @override
  void didUpdateWidget(covariant HexColorPickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialColor != widget.initialColor && !_focusNode.hasFocus) {
      _currentColor = widget.initialColor;
      _hexController.text = _formatHex(_currentColor);
    }
  }

  String _formatHex(Color c) {
    return '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  void _onColorPicked(Color c) {
    setState(() {
      _currentColor = c;
      if (!_focusNode.hasFocus) {
        _hexController.text = _formatHex(c);
      }
    });
    widget.onColorChanged(c);
  }

  void _onHexChanged(String val) {
    String cleaned = val.replaceAll('#', '').trim();
    if (cleaned.length == 3) {
      cleaned = '${cleaned[0]}${cleaned[0]}${cleaned[1]}${cleaned[1]}${cleaned[2]}${cleaned[2]}';
    }
    if (cleaned.length == 6) {
      final intVal = int.tryParse('FF$cleaned', radix: 16);
      if (intVal != null) {
        final c = Color(intVal);
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
        });
        widget.onColorChanged(c);
      }
    }
  }

  @override
  void dispose() {
    _hexController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ColorPicker(
          pickerColor: _currentColor,
          onColorChanged: _onColorPicked,
          showLabel: false,
          enableAlpha: widget.enableAlpha,
          pickerAreaHeightPercent: widget.pickerAreaHeightPercent,
        ),
        const SizedBox(height: 12),
        // Hex Code Input Box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _currentColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white24, width: 1.2),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'HEX',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _hexController,
                  focusNode: _focusNode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    letterSpacing: 1.2,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: '#RRGGBB',
                    hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                  onChanged: _onHexChanged,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
