import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:layerly/core/constants/app_colors.dart';
import 'package:layerly/core/constants/responsive_breakpoints.dart';
import 'package:layerly/features/editor/domain/entities/canvas_page.dart';
import 'package:layerly/features/editor/domain/entities/layer.dart';
import 'package:layerly/features/editor/domain/entities/layer_enums.dart';
import 'package:layerly/features/editor/domain/entities/text_layer.dart';
import 'package:layerly/features/editor/domain/entities/shape_layer.dart';
import 'package:layerly/features/editor/domain/entities/image_layer.dart';
import 'package:layerly/features/editor/domain/entities/device_mockup_layer.dart';
import 'package:layerly/features/editor/domain/entities/icon_layer.dart';
import 'package:layerly/features/editor/domain/entities/component_instance_layer.dart';
import 'package:layerly/features/editor/domain/entities/auto_layout_layer.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_bloc.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_event.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_state.dart';

class PropertiesPanel extends StatelessWidget {
  const PropertiesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditorBloc, EditorState>(
      builder: (context, state) {
        final selectedLayers = state.selectedLayers;

        Widget content;
        if (selectedLayers.isEmpty) {
          // Nothing selected -> Page Properties
          content = _buildPageProperties(context, state);
        } else if (selectedLayers.length > 1) {
          // Multiple objects selected -> Multi-selection Actions
          content = _buildMultiSelectProperties(context, state, selectedLayers);
        } else {
          // Single object selected -> Contextual Layer Properties
          final layer = selectedLayers.first;
          if (layer is AutoLayoutLayer) {
            content = _buildAutoLayoutWithChildrenCards(context, state.activePage, layer);
          } else if (layer is TextLayer) {
            content = _buildTextCard(
              context,
              layer,
              onUpdate: (updated) => context.read<EditorBloc>().add(UpdateLayerEvent(updated)),
            );
          } else if (layer is IconLayer) {
            content = _buildIconCard(
              context,
              layer,
              onUpdate: (updated) => context.read<EditorBloc>().add(UpdateLayerEvent(updated)),
            );
          } else if (layer is ShapeLayer) {
            content = _buildShapeCard(
              context,
              layer,
              onUpdate: (updated) => context.read<EditorBloc>().add(UpdateLayerEvent(updated)),
            );
          } else if (layer is ImageLayer) {
            content = _buildImageProperties(context, layer);
          } else if (layer is DeviceMockupLayer) {
            content = _buildDeviceMockupProperties(context, layer);
          } else if (layer is ComponentInstanceLayer) {
            content = _buildComponentProperties(context, state, layer);
          } else {
            content = _buildGenericLayerProperties(context, layer);
          }
        }

        final isDesktop = ResponsiveBreakpoints.isDesktop(context);
        if (isDesktop) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: content,
          );
        } else {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: content,
          );
        }
      },
    );
  }

  // 1. Page Properties (When nothing is selected)
  Widget _buildPageProperties(BuildContext context, EditorState state) {
    final activePage = state.activePage;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              _buildTypeIconBox(Icons.link_rounded),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Page properties',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              InkWell(
                onTap: () => _showColorPicker(
                  context,
                  activePage.backgroundColor,
                  (c) {
                    context.read<EditorBloc>().add(UpdatePageBackgroundEvent(
                          type: activePage.backgroundType,
                          color: c,
                        ));
                  },
                ),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 34,
                  height: 24,
                  decoration: BoxDecoration(
                    color: activePage.backgroundColor,
                    gradient: activePage.backgroundGradient,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.more_horiz_rounded, color: AppColors.textMuted, size: 20),
            ],
          ),
          const SizedBox(height: 10),

          // Controls Row: Guides Switch + Padding H + Padding V
          Row(
            children: [
              // Guides Switch
              InkWell(
                onTap: () {
                  context.read<EditorBloc>().add(const ToggleGuidesEvent());
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Guides',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 6),
                      Transform.scale(
                        scale: 0.7,
                        child: Switch(
                          value: activePage.showGuides,
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            context.read<EditorBloc>().add(const ToggleGuidesEvent());
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Horizontal Padding Stepper
              Expanded(
                child: _buildStepperPill(
                  value: activePage.horizontalPadding.toInt(),
                  onDecrement: () {
                    context.read<EditorBloc>().add(UpdatePagePaddingEvent(
                          horizontal: (activePage.horizontalPadding - 1).clamp(0.0, 10000.0),
                          vertical: activePage.verticalPadding,
                        ));
                  },
                  onIncrement: () {
                    context.read<EditorBloc>().add(UpdatePagePaddingEvent(
                          horizontal: (activePage.horizontalPadding + 1).clamp(0.0, 10000.0),
                          vertical: activePage.verticalPadding,
                        ));
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Vertical Padding Stepper
              Expanded(
                child: _buildStepperPill(
                  value: activePage.verticalPadding.toInt(),
                  onDecrement: () {
                    context.read<EditorBloc>().add(UpdatePagePaddingEvent(
                          horizontal: activePage.horizontalPadding,
                          vertical: (activePage.verticalPadding - 1).clamp(0.0, 10000.0),
                        ));
                  },
                  onIncrement: () {
                    context.read<EditorBloc>().add(UpdatePagePaddingEvent(
                          horizontal: activePage.horizontalPadding,
                          vertical: (activePage.verticalPadding + 1).clamp(0.0, 10000.0),
                        ));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Auto Layout with Horizontal Scrolling Cards
  Widget _buildAutoLayoutWithChildrenCards(BuildContext context, CanvasPage activePage, AutoLayoutLayer layer) {
    if (layer.children.isEmpty) {
      return _buildAutoLayoutCard(
        context,
        activePage,
        layer,
        onUpdate: (updated) => context.read<EditorBloc>().add(UpdateLayerEvent(updated)),
      );
    }

    final cards = <Widget>[
      _buildAutoLayoutCard(
        context,
        activePage,
        layer,
        onUpdate: (updated) => context.read<EditorBloc>().add(UpdateLayerEvent(updated)),
      ),
      for (final child in layer.children)
        _buildChildLayerCard(context, layer, child),
    ];

    return SizedBox(
      height: 114,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (ctx, idx) => SizedBox(
          width: 310,
          child: cards[idx],
        ),
      ),
    );
  }

  Widget _buildChildLayerCard(BuildContext context, AutoLayoutLayer parent, Layer child) {
    if (child is IconLayer) {
      return _buildIconCard(
        context,
        child,
        onUpdate: (updated) => _updateChildInParent(context, parent, updated),
      );
    } else if (child is TextLayer) {
      return _buildTextCard(
        context,
        child,
        onUpdate: (updated) => _updateChildInParent(context, parent, updated),
      );
    } else if (child is ShapeLayer) {
      return _buildShapeCard(
        context,
        child,
        onUpdate: (updated) => _updateChildInParent(context, parent, updated),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Text(
            child.name,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      );
    }
  }

  void _updateChildInParent(BuildContext context, AutoLayoutLayer parent, Layer updatedChild) {
    final updatedChildren = parent.children.map((c) => c.id == updatedChild.id ? updatedChild : c).toList();
    context.read<EditorBloc>().add(
          UpdateLayerEvent(parent.copyWith(children: updatedChildren)),
        );
  }

  // 3. Auto Layout Card (Screenshot 3)
  Widget _buildAutoLayoutCard(
    BuildContext context,
    CanvasPage activePage,
    AutoLayoutLayer layer, {
    required ValueChanged<AutoLayoutLayer> onUpdate,
  }) {
    final rightMargin = activePage.width - activePage.horizontalPadding;
    final bottomMargin = activePage.height - activePage.verticalPadding;
    final maxAllowedWidth = (rightMargin - layer.x).clamp(40.0, activePage.width - activePage.horizontalPadding * 2);
    final maxAllowedHeight = (bottomMargin - layer.y).clamp(40.0, activePage.height - activePage.verticalPadding * 2);

    final isHorizontal = layer.direction == AutoLayoutDirection.horizontal;
    double sumChildrenMain = 0;
    double maxChildCross = 0;
    for (final c in layer.children) {
      if (isHorizontal) {
        sumChildrenMain += c.width;
        if (c.height > maxChildCross) maxChildCross = c.height;
      } else {
        sumChildrenMain += c.height;
        if (c.width > maxChildCross) maxChildCross = c.width;
      }
    }

    final int numGaps = math.max(1, layer.children.length - 1);

    final double maxGap = isHorizontal
        ? ((maxAllowedWidth - layer.paddingHorizontal * 2 - sumChildrenMain) / numGaps).floorToDouble().clamp(0.0, 10000.0)
        : ((maxAllowedHeight - layer.paddingVertical * 2 - sumChildrenMain) / numGaps).floorToDouble().clamp(0.0, 10000.0);

    final double maxPadH = isHorizontal
        ? ((maxAllowedWidth - sumChildrenMain - numGaps * layer.gap) / 2).floorToDouble().clamp(0.0, 10000.0)
        : ((maxAllowedWidth - maxChildCross) / 2).floorToDouble().clamp(0.0, 10000.0);

    final double maxPadV = isHorizontal
        ? ((maxAllowedHeight - maxChildCross) / 2).floorToDouble().clamp(0.0, 10000.0)
        : ((maxAllowedHeight - sumChildrenMain - numGaps * layer.gap) / 2).floorToDouble().clamp(0.0, 10000.0);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Link Icon + "Auto layout" + Direction Pill + More
          Row(
            children: [
              _buildTypeIconBox(Icons.link_rounded),
              const SizedBox(width: 10),
              const Text(
                'Auto layout',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  final nextDir = layer.direction == AutoLayoutDirection.horizontal
                      ? AutoLayoutDirection.vertical
                      : AutoLayoutDirection.horizontal;
                  onUpdate(layer.copyWith(direction: nextDir));
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        layer.direction == AutoLayoutDirection.horizontal ? 'Horizontal' : 'Vertical',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.sync_rounded, size: 14, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.more_horiz_rounded, color: AppColors.textMuted, size: 18),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Gap Stepper + Padding H Stepper + Padding V Stepper
          Row(
            children: [
              // Gap
              Expanded(
                child: _buildStepperPill(
                  value: layer.gap.toInt(),
                  onDecrement: () {
                    final newGap = (layer.gap - 1).clamp(0.0, maxGap);
                    onUpdate(layer.copyWith(gap: newGap));
                  },
                  onIncrement: () {
                    final newGap = (layer.gap + 1).clamp(0.0, maxGap);
                    onUpdate(layer.copyWith(gap: newGap));
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Padding H
              Expanded(
                child: _buildStepperPill(
                  value: layer.paddingHorizontal.toInt(),
                  onDecrement: () {
                    final newPad = (layer.paddingHorizontal - 1).clamp(0.0, maxPadH);
                    onUpdate(layer.copyWith(paddingHorizontal: newPad));
                  },
                  onIncrement: () {
                    final newPad = (layer.paddingHorizontal + 1).clamp(0.0, maxPadH);
                    onUpdate(layer.copyWith(paddingHorizontal: newPad));
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Padding V
              Expanded(
                child: _buildStepperPill(
                  value: layer.paddingVertical.toInt(),
                  onDecrement: () {
                    final newPad = (layer.paddingVertical - 1).clamp(0.0, maxPadV);
                    onUpdate(layer.copyWith(paddingVertical: newPad));
                  },
                  onIncrement: () {
                    final newPad = (layer.paddingVertical + 1).clamp(0.0, maxPadV);
                    onUpdate(layer.copyWith(paddingVertical: newPad));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4. Text Card (Screenshot 2)
  Widget _buildTextCard(
    BuildContext context,
    TextLayer layer, {
    required ValueChanged<TextLayer> onUpdate,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Icon + Title + Text Preview + Color + More
          Row(
            children: [
              _buildTypeIconBox(Icons.title_rounded),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => _showEditTextDialog(context, layer, (newText) {
                    onUpdate(layer.copyWith(content: newText));
                  }),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Text',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        layer.content,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              _buildColorSwatch(context, layer.color, (c) {
                onUpdate(layer.copyWith(color: c));
              }),
              const SizedBox(width: 6),
              const Icon(Icons.more_horiz_rounded, color: AppColors.textMuted, size: 18),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Font Family Dropdown + Font Size Stepper
          Row(
            children: [
              // Font Family Dropdown Pill
              Expanded(
                flex: 3,
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: layer.fontFamily,
                      dropdownColor: AppColors.surfaceElevated,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary, size: 18),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                      items: () {
                        const defaultFonts = ['Inter', 'Outfit', 'Poppins', 'Roboto', 'Montserrat'];
                        final allFonts = <String>{...defaultFonts, layer.fontFamily}.toList();
                        return allFonts.map((f) => DropdownMenuItem(value: f, child: Text(f.toUpperCase()))).toList();
                      }(),
                      onChanged: (val) {
                        if (val != null) {
                          onUpdate(layer.copyWith(fontFamily: val));
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Font Size Stepper
              Expanded(
                flex: 2,
                child: _buildStepperPill(
                  value: layer.fontSize.toInt(),
                  onDecrement: () {
                    final newSize = (layer.fontSize - 1).clamp(1.0, 1000.0);
                    onUpdate(layer.copyWith(fontSize: newSize));
                  },
                  onIncrement: () {
                    final newSize = (layer.fontSize + 1).clamp(1.0, 1000.0);
                    onUpdate(layer.copyWith(fontSize: newSize));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 5. Icon Card (Screenshot 1)
  Widget _buildIconCard(
    BuildContext context,
    IconLayer layer, {
    required ValueChanged<IconLayer> onUpdate,
  }) {
    final presetIcons = <IconData, String>{
      Icons.check_circle_outline_rounded: 'Checkmark',
      Icons.check_rounded: 'Check',
      Icons.star_rounded: 'Star',
      Icons.favorite_rounded: 'Heart',
      Icons.arrow_forward_rounded: 'Arrow',
      Icons.bolt_rounded: 'Bolt',
      Icons.auto_awesome_rounded: 'Sparkle',
      Icons.circle_outlined: 'Circle',
    };

    final items = <DropdownMenuItem<IconData>>[];
    for (final entry in presetIcons.entries) {
      items.add(DropdownMenuItem(
        value: entry.key,
        child: Text(entry.value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      ));
    }
    if (!presetIcons.containsKey(layer.icon)) {
      items.add(DropdownMenuItem(
        value: layer.icon,
        child: const Text('Icon', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      ));
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildTypeIconBox(layer.icon),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Icon',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _buildColorSwatch(context, layer.color, (c) {
                onUpdate(layer.copyWith(color: c));
              }),
              const SizedBox(width: 6),
              const Icon(Icons.more_horiz_rounded, color: AppColors.textMuted, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<IconData>(
                      value: layer.icon,
                      dropdownColor: AppColors.surfaceElevated,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary, size: 18),
                      items: items,
                      onChanged: (val) {
                        if (val != null) {
                          onUpdate(layer.copyWith(icon: val));
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _buildStepperPill(
                  value: layer.width.toInt(),
                  onDecrement: () {
                    final size = (layer.width - 1).clamp(12.0, 200.0);
                    onUpdate(layer.copyWith(width: size, height: size));
                  },
                  onIncrement: () {
                    final size = (layer.width + 1).clamp(12.0, 200.0);
                    onUpdate(layer.copyWith(width: size, height: size));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 6. Shape Card
  Widget _buildShapeCard(
    BuildContext context,
    ShapeLayer layer, {
    required ValueChanged<ShapeLayer> onUpdate,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildTypeIconBox(Icons.crop_square_rounded),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  layer.name,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              _buildColorSwatch(context, layer.fill, (c) {
                onUpdate(layer.copyWith(fill: c));
              }),
              const SizedBox(width: 6),
              const Icon(Icons.more_horiz_rounded, color: AppColors.textMuted, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Radius', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStepperPill(
                  value: layer.cornerRadius.toInt(),
                  onDecrement: () {
                    final newR = (layer.cornerRadius - 1).clamp(0.0, 10000.0);
                    onUpdate(layer.copyWith(cornerRadius: newR));
                  },
                  onIncrement: () {
                    final newR = (layer.cornerRadius + 1).clamp(0.0, 10000.0);
                    onUpdate(layer.copyWith(cornerRadius: newR));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 7. Image Properties
  Widget _buildImageProperties(BuildContext context, ImageLayer layer) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _buildTypeIconBox(Icons.image_outlined),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(layer.name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                Text('${layer.width.toInt()} × ${layer.height.toInt()}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 8. Device Mockup Properties
  Widget _buildDeviceMockupProperties(BuildContext context, DeviceMockupLayer layer) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _buildTypeIconBox(Icons.phone_iphone_rounded),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Phone Mockup', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                Text('iPhone Frame (Simulated App)', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 9. Component Properties
  Widget _buildComponentProperties(BuildContext context, EditorState state, ComponentInstanceLayer layer) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _buildTypeIconBox(Icons.widgets_rounded),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Component Instance', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                Text(layer.name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<EditorBloc>().add(DetachComponentInstanceEvent(layer.id));
            },
            child: const Text('Detach', style: TextStyle(color: AppColors.primary, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // 10. Multi-Selection Properties
  Widget _buildMultiSelectProperties(BuildContext context, EditorState state, List<Layer> selected) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${selected.length} selected',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                context.read<EditorBloc>().add(const CreateAutoLayoutFromSelectionEvent());
              },
              icon: const Icon(Icons.link_rounded, size: 16),
              label: const Text('Create Layout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceSecondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenericLayerProperties(BuildContext context, Layer layer) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Center(
        child: Text(layer.name, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  // Helper Widgets
  Widget _buildTypeIconBox(IconData icon) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(icon, color: Colors.white, size: 16),
    );
  }

  Widget _buildStepperPill({
    required int value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(19),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              _RepeatableActionButton(
                onTap: onDecrement,
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary, size: 16),
                ),
              ),
              _RepeatableActionButton(
                onTap: onIncrement,
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(Icons.keyboard_arrow_up_rounded, color: AppColors.textSecondary, size: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorSwatch(BuildContext context, Color color, ValueChanged<Color> onColorChanged) {
    return InkWell(
      onTap: () => _showColorPicker(context, color, onColorChanged),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.2),
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context, Color initialColor, ValueChanged<Color> onColorChanged) {
    Color selected = initialColor;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Pick Color', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: initialColor,
            onColorChanged: (c) => selected = c,
            enableAlpha: false,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              onColorChanged(selected);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showEditTextDialog(BuildContext context, TextLayer layer, ValueChanged<String> onSaved) {
    final controller = TextEditingController(text: layer.content);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Edit Text', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                onSaved(controller.text);
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _RepeatableActionButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _RepeatableActionButton({
    required this.child,
    required this.onTap,
  });

  @override
  State<_RepeatableActionButton> createState() => _RepeatableActionButtonState();
}

class _RepeatableActionButtonState extends State<_RepeatableActionButton> {
  Timer? _timer;
  Timer? _delayTimer;

  void _startHold() {
    widget.onTap(); // Fire immediately on single tap
    _delayTimer = Timer(const Duration(milliseconds: 280), () {
      _timer = Timer.periodic(const Duration(milliseconds: 40), (_) {
        if (!mounted) return;
        widget.onTap();
      });
    });
  }

  void _stopHold() {
    _delayTimer?.cancel();
    _delayTimer = null;
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopHold();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _startHold(),
      onTapUp: (_) => _stopHold(),
      onTapCancel: _stopHold,
      child: widget.child,
    );
  }
}
