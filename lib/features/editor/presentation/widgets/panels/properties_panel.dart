import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:layerly/core/constants/app_colors.dart';
import 'package:layerly/features/editor/domain/entities/layer_enums.dart';
import 'package:layerly/features/editor/domain/entities/text_layer.dart';
import 'package:layerly/features/editor/domain/entities/shape_layer.dart';
import 'package:layerly/features/editor/domain/entities/image_layer.dart';
import 'package:layerly/features/editor/domain/entities/device_mockup_layer.dart';
import 'package:layerly/features/editor/domain/entities/icon_layer.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_bloc.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_event.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_state.dart';

class PropertiesPanel extends StatelessWidget {
  const PropertiesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditorBloc, EditorState>(
      builder: (context, state) {
        final selectedLayer = state.singleSelectedLayer;

        if (selectedLayer == null) {
          return _buildCanvasPageProperties(context, state);
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          children: [
            // Layer Name & Quick Actions Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    selectedLayer.name,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  color: AppColors.textSecondary,
                  tooltip: 'Duplicate (Ctrl+D)',
                  onPressed: () {
                    context.read<EditorBloc>().add(const DuplicateSelectedLayersEvent());
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  color: AppColors.danger,
                  tooltip: 'Delete (Del)',
                  onPressed: () {
                    context.read<EditorBloc>().add(const DeleteSelectedLayersEvent());
                  },
                ),
              ],
            ),
            const Divider(color: AppColors.border, height: 16),

            // Alignment Tools
            const Text(
              'ALIGNMENT',
              style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAlignButton(context, Icons.align_horizontal_left_rounded, 'Align Left', AlignmentAction.left),
                _buildAlignButton(context, Icons.align_horizontal_center_rounded, 'Align Center', AlignmentAction.center),
                _buildAlignButton(context, Icons.align_horizontal_right_rounded, 'Align Right', AlignmentAction.right),
                _buildAlignButton(context, Icons.align_vertical_top_rounded, 'Align Top', AlignmentAction.top),
                _buildAlignButton(context, Icons.align_vertical_center_rounded, 'Align Middle', AlignmentAction.middle),
                _buildAlignButton(context, Icons.align_vertical_bottom_rounded, 'Align Bottom', AlignmentAction.bottom),
              ],
            ),
            const Divider(color: AppColors.border, height: 20),

            // Layer Transform (X, Y, W, H, Rotation, Opacity)
            const Text(
              'TRANSFORM',
              style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildNumberField('X', selectedLayer.x.toInt().toString(), (val) {
                    final num = double.tryParse(val) ?? selectedLayer.x;
                    context.read<EditorBloc>().add(UpdateLayerEvent(selectedLayer.copyWithTransform(x: num)));
                  }),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildNumberField('Y', selectedLayer.y.toInt().toString(), (val) {
                    final num = double.tryParse(val) ?? selectedLayer.y;
                    context.read<EditorBloc>().add(UpdateLayerEvent(selectedLayer.copyWithTransform(y: num)));
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildNumberField('W', selectedLayer.width.toInt().toString(), (val) {
                    final num = double.tryParse(val) ?? selectedLayer.width;
                    context.read<EditorBloc>().add(UpdateLayerEvent(selectedLayer.copyWithTransform(width: num)));
                  }),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildNumberField('H', selectedLayer.height.toInt().toString(), (val) {
                    final num = double.tryParse(val) ?? selectedLayer.height;
                    context.read<EditorBloc>().add(UpdateLayerEvent(selectedLayer.copyWithTransform(height: num)));
                  }),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Opacity Slider
            Row(
              children: [
                const Text('Opacity', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: selectedLayer.opacity,
                    min: 0.0,
                    max: 1.0,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.border,
                    onChanged: (val) {
                      context.read<EditorBloc>().add(UpdateLayerEvent(
                            selectedLayer.copyWithTransform(opacity: val),
                            recordHistory: false,
                          ));
                    },
                  ),
                ),
                Text(
                  '${(selectedLayer.opacity * 100).toInt()}%',
                  style: const TextStyle(color: AppColors.text, fontSize: 11, fontFamily: 'monospace'),
                ),
              ],
            ),

            const Divider(color: AppColors.border, height: 20),

            // Layer Specific Inspector
            if (selectedLayer is TextLayer)
              _buildTextInspector(context, selectedLayer)
            else if (selectedLayer is ShapeLayer)
              _buildShapeInspector(context, selectedLayer)
            else if (selectedLayer is DeviceMockupLayer)
              _buildDeviceMockupInspector(context, selectedLayer)
            else if (selectedLayer is IconLayer)
              _buildIconInspector(context, selectedLayer)
            else if (selectedLayer is ImageLayer)
              _buildImageInspector(context, selectedLayer),

            const SizedBox(height: 20),
            // Layer Arrangement
            const Text(
              'ORDERING',
              style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      context.read<EditorBloc>().add(BringToFrontEvent(selectedLayer.id));
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.text,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('Bring to Front', style: TextStyle(fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      context.read<EditorBloc>().add(SendToBackEvent(selectedLayer.id));
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.text,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('Send to Back', style: TextStyle(fontSize: 11)),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildCanvasPageProperties(BuildContext context, EditorState state) {
    final page = state.activePage;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      children: [
        const Text(
          'CANVAS PAGE',
          style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          page.name,
          style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 4),
        Text(
          '${page.width.toInt()} × ${page.height.toInt()} px  •  Instagram Square / Carousel',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        const Divider(color: AppColors.border, height: 24),

        const Text(
          'BACKGROUND STYLE',
          style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildBackgroundSwatch(
              context,
              'Cosmic Glow',
              const RadialGradient(
                center: Alignment(0.4, -0.6),
                radius: 1.2,
                colors: [Color(0xFF2C194D), Color(0xFF13141B), Color(0xFF090A0D)],
              ),
              () {
                context.read<EditorBloc>().add(const UpdatePageBackgroundEvent(
                      type: BackgroundType.gradient,
                      gradient: RadialGradient(
                        center: Alignment(0.4, -0.6),
                        radius: 1.2,
                        colors: [Color(0xFF2C194D), Color(0xFF13141B), Color(0xFF090A0D)],
                      ),
                    ));
              },
            ),
            const SizedBox(width: 8),
            _buildBackgroundSwatch(
              context,
              'Pitch Dark',
              null,
              () {
                context.read<EditorBloc>().add(const UpdatePageBackgroundEvent(
                      type: BackgroundType.solid,
                      color: Color(0xFF090A0D),
                    ));
              },
              solidColor: const Color(0xFF090A0D),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Tip: Click any layer on canvas to inspect its properties.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Widget _buildBackgroundSwatch(
    BuildContext context,
    String label,
    Gradient? gradient,
    VoidCallback onTap, {
    Color? solidColor,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: solidColor,
            gradient: gradient,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildTextInspector(BuildContext context, TextLayer layer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TYPOGRAPHY',
          style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        // Text Content input
        TextFormField(
          initialValue: layer.content,
          maxLines: 3,
          style: const TextStyle(color: AppColors.text, fontSize: 13),
          decoration: InputDecoration(
            labelText: 'Text Content',
            labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.border)),
          ),
          onChanged: (val) {
            context.read<EditorBloc>().add(UpdateLayerEvent(layer.copyWith(content: val), recordHistory: false));
          },
        ),
        const SizedBox(height: 12),

        // Font Size & Weight
        Row(
          children: [
            Expanded(
              child: _buildNumberField('Size', layer.fontSize.toInt().toString(), (val) {
                final num = double.tryParse(val) ?? layer.fontSize;
                context.read<EditorBloc>().add(UpdateLayerEvent(layer.copyWith(fontSize: num)));
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<FontWeight>(
                    value: layer.fontWeight,
                    dropdownColor: AppColors.surfaceElevated,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: FontWeight.w400, child: Text('Regular', style: TextStyle(color: Colors.white, fontSize: 12))),
                      DropdownMenuItem(value: FontWeight.w600, child: Text('SemiBold', style: TextStyle(color: Colors.white, fontSize: 12))),
                      DropdownMenuItem(value: FontWeight.w700, child: Text('Bold', style: TextStyle(color: Colors.white, fontSize: 12))),
                      DropdownMenuItem(value: FontWeight.w900, child: Text('Black', style: TextStyle(color: Colors.white, fontSize: 12))),
                    ],
                    onChanged: (weight) {
                      if (weight != null) {
                        context.read<EditorBloc>().add(UpdateLayerEvent(layer.copyWith(fontWeight: weight)));
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Text Color
        Row(
          children: [
            const Text('Color', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const Spacer(),
            _buildColorPill(context, layer.color, (newColor) {
              context.read<EditorBloc>().add(UpdateLayerEvent(layer.copyWith(color: newColor)));
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildShapeInspector(BuildContext context, ShapeLayer layer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SHAPE PROPERTIES',
          style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Fill Color', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const Spacer(),
            _buildColorPill(context, layer.fill, (newColor) {
              context.read<EditorBloc>().add(UpdateLayerEvent(layer.copyWith(fill: newColor)));
            }),
          ],
        ),
        const SizedBox(height: 10),
        _buildNumberField('Corner Radius', layer.cornerRadius.toInt().toString(), (val) {
          final num = double.tryParse(val) ?? layer.cornerRadius;
          context.read<EditorBloc>().add(UpdateLayerEvent(layer.copyWith(cornerRadius: num)));
        }),
      ],
    );
  }

  Widget _buildDeviceMockupInspector(BuildContext context, DeviceMockupLayer layer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MOCKUP FRAME',
          style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Frame Color', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const Spacer(),
            _buildColorPill(context, layer.frameColor, (newColor) {
              context.read<EditorBloc>().add(UpdateLayerEvent(layer.copyWith(frameColor: newColor)));
            }),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Text('Show Shadow', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const Spacer(),
            Switch(
              value: layer.showShadow,
              activeThumbColor: AppColors.primary,
              onChanged: (val) {
                context.read<EditorBloc>().add(UpdateLayerEvent(layer.copyWith(showShadow: val)));
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIconInspector(BuildContext context, IconLayer layer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ICON PROPERTIES',
          style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Icon Color', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const Spacer(),
            _buildColorPill(context, layer.color, (newColor) {
              context.read<EditorBloc>().add(UpdateLayerEvent(layer.copyWith(color: newColor)));
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildImageInspector(BuildContext context, ImageLayer layer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'IMAGE FIT',
          style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildNumberField('Border Radius', layer.borderRadius.toInt().toString(), (val) {
          final num = double.tryParse(val) ?? layer.borderRadius;
          context.read<EditorBloc>().add(UpdateLayerEvent(layer.copyWith(borderRadius: num)));
        }),
      ],
    );
  }

  Widget _buildAlignButton(BuildContext context, IconData icon, String tooltip, AlignmentAction action) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          context.read<EditorBloc>().add(AlignSelectedLayersEvent(action));
        },
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: AppColors.textSecondary, size: 16),
        ),
      ),
    );
  }

  Widget _buildNumberField(String label, String value, Function(String) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              initialValue: value,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.text, fontSize: 12, fontFamily: 'monospace'),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPill(BuildContext context, Color color, Function(Color) onColorChanged) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Pick Color', style: TextStyle(color: Colors.white, fontSize: 14)),
            content: SingleChildScrollView(
              child: ColorPicker(
                pickerColor: color,
                onColorChanged: onColorChanged,
                enableAlpha: true,
                displayThumbColor: true,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Done', style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        );
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Colors.white24),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
              style: const TextStyle(color: AppColors.text, fontSize: 11, fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }
}
