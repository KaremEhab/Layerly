import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:layerly/core/constants/app_colors.dart';
import 'package:layerly/core/constants/responsive_breakpoints.dart';
import 'package:layerly/core/utils/text_span_parser.dart';
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
import 'package:layerly/features/editor/presentation/widgets/canvas/figma_context_menu.dart';
import 'package:layerly/core/widgets/more_rings_icon.dart';
import 'package:layerly/core/widgets/hex_color_picker_widget.dart';
import 'package:layerly/features/editor/presentation/widgets/panels/background_picker_sheet.dart';

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
            content = _buildAutoLayoutWithChildrenCards(
              context,
              state.activePage,
              layer,
            );
          } else if (layer is TextLayer) {
            content = _buildTextCard(
              context,
              layer,
              onUpdate: (updated) =>
                  context.read<EditorBloc>().add(UpdateLayerEvent(updated)),
            );
          } else if (layer is IconLayer) {
            content = _buildIconCard(
              context,
              layer,
              onUpdate: (updated) =>
                  context.read<EditorBloc>().add(UpdateLayerEvent(updated)),
            );
          } else if (layer is ShapeLayer) {
            content = _buildShapeCard(
              context,
              layer,
              onUpdate: (updated) =>
                  context.read<EditorBloc>().add(UpdateLayerEvent(updated)),
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
          final isMultiCard = selectedLayers.length == 1 &&
              selectedLayers.first is AutoLayoutLayer &&
              (selectedLayers.first as AutoLayoutLayer).children.isNotEmpty;

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMultiCard ? 0 : 16,
              vertical: 4,
            ),
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
      constraints: const BoxConstraints(minHeight: 104),
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
                onTap: () => showBackgroundPickerSheet(
                  context,
                  activePage,
                  bloc: context.read<EditorBloc>(),
                ),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 34,
                  height: 24,
                  decoration: BoxDecoration(
                    color:
                        activePage.backgroundType == BackgroundType.transparent
                        ? Colors.transparent
                        : activePage.backgroundColor,
                    gradient:
                        activePage.backgroundType == BackgroundType.gradient
                        ? activePage.backgroundGradient
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: activePage.backgroundType == BackgroundType.transparent
                      ? const Center(
                          child: Icon(
                            Icons.block_rounded,
                            size: 12,
                            color: Colors.white70,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Builder(
                builder: (btnContext) => InkWell(
                  onTap: () {
                    final box = btnContext.findRenderObject() as RenderBox?;
                    final pos = box != null
                        ? box.localToGlobal(Offset(0, box.size.height + 6))
                        : const Offset(300, 200);
                    showFigmaContextMenu(
                      context: context,
                      globalPosition: pos,
                      state: state,
                      bloc: context.read<EditorBloc>(),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const MoreRingsIcon(
                      color: Colors.white70,
                      size: 18,
                      ringRadius: 2.1,
                      strokeWidth: 1.4,
                      spacing: 1.0,
                    ),
                  ),
                ),
              ),
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
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Transform.scale(
                        scale: 0.7,
                        child: Switch(
                          value: activePage.showGuides,
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            context.read<EditorBloc>().add(
                              const ToggleGuidesEvent(),
                            );
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
                    context.read<EditorBloc>().add(
                      UpdatePagePaddingEvent(
                        horizontal: (activePage.horizontalPadding - 1).clamp(
                          0.0,
                          10000.0,
                        ),
                        vertical: activePage.verticalPadding,
                      ),
                    );
                  },
                  onIncrement: () {
                    context.read<EditorBloc>().add(
                      UpdatePagePaddingEvent(
                        horizontal: (activePage.horizontalPadding + 1).clamp(
                          0.0,
                          10000.0,
                        ),
                        vertical: activePage.verticalPadding,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Vertical Padding Stepper
              Expanded(
                child: _buildStepperPill(
                  value: activePage.verticalPadding.toInt(),
                  onDecrement: () {
                    context.read<EditorBloc>().add(
                      UpdatePagePaddingEvent(
                        horizontal: activePage.horizontalPadding,
                        vertical: (activePage.verticalPadding - 1).clamp(
                          0.0,
                          10000.0,
                        ),
                      ),
                    );
                  },
                  onIncrement: () {
                    context.read<EditorBloc>().add(
                      UpdatePagePaddingEvent(
                        horizontal: activePage.horizontalPadding,
                        vertical: (activePage.verticalPadding + 1).clamp(
                          0.0,
                          10000.0,
                        ),
                      ),
                    );
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
  Widget _buildAutoLayoutWithChildrenCards(
    BuildContext context,
    CanvasPage activePage,
    AutoLayoutLayer layer,
  ) {
    if (layer.children.isEmpty) {
      return _buildAutoLayoutCard(
        context,
        activePage,
        layer,
        onUpdate: (updated) =>
            context.read<EditorBloc>().add(UpdateLayerEvent(updated)),
      );
    }

    final cards = <Widget>[
      _buildAutoLayoutCard(
        context,
        activePage,
        layer,
        onUpdate: (updated) =>
            context.read<EditorBloc>().add(UpdateLayerEvent(updated)),
      ),
      for (final child in layer.children)
        _buildChildLayerCard(context, layer, child),
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = math.max(350.0, screenWidth * 0.8);

    return SizedBox(
      height: 108,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, idx) =>
            SizedBox(width: cardWidth, child: cards[idx]),
      ),
    );
  }

  Widget _buildChildLayerCard(
    BuildContext context,
    AutoLayoutLayer parent,
    Layer child,
  ) {
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
        constraints: const BoxConstraints(minHeight: 104),
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

  void _updateChildInParent(
    BuildContext context,
    AutoLayoutLayer parent,
    Layer updatedChild,
  ) {
    final updatedChildren = parent.children
        .map((c) => c.id == updatedChild.id ? updatedChild : c)
        .toList();
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
    final maxAllowedWidth = (rightMargin - layer.x).clamp(
      40.0,
      activePage.width - activePage.horizontalPadding * 2,
    );
    final maxAllowedHeight = (bottomMargin - layer.y).clamp(
      40.0,
      activePage.height - activePage.verticalPadding * 2,
    );

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
        ? ((maxAllowedWidth - layer.paddingHorizontal * 2 - sumChildrenMain) /
                  numGaps)
              .floorToDouble()
              .clamp(0.0, 10000.0)
        : ((maxAllowedHeight - layer.paddingVertical * 2 - sumChildrenMain) /
                  numGaps)
              .floorToDouble()
              .clamp(0.0, 10000.0);

    final double maxPadH = isHorizontal
        ? ((maxAllowedWidth - sumChildrenMain - numGaps * layer.gap) / 2)
              .floorToDouble()
              .clamp(0.0, 10000.0)
        : ((maxAllowedWidth - maxChildCross) / 2).floorToDouble().clamp(
            0.0,
            10000.0,
          );

    final double maxPadV = isHorizontal
        ? ((maxAllowedHeight - maxChildCross) / 2).floorToDouble().clamp(
            0.0,
            10000.0,
          )
        : ((maxAllowedHeight - sumChildrenMain - numGaps * layer.gap) / 2)
              .floorToDouble()
              .clamp(0.0, 10000.0);

    return Container(
      constraints: const BoxConstraints(minHeight: 104),
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
          // Row 1: Link Icon + "Auto layout" + Direction Pill + Background Color Swatch + More
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
                  final nextDir =
                      layer.direction == AutoLayoutDirection.horizontal
                      ? AutoLayoutDirection.vertical
                      : AutoLayoutDirection.horizontal;
                  onUpdate(layer.copyWith(direction: nextDir));
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        layer.direction == AutoLayoutDirection.horizontal
                            ? 'Horizontal'
                            : 'Vertical',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.sync_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () {
                  _showAutoLayoutSettingsDialog(
                    context,
                    layer: layer,
                    onUpdate: onUpdate,
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: MoreRingsIcon(
                    color: AppColors.textSecondary,
                    size: 20,
                    ringRadius: 2.3,
                    strokeWidth: 1.5,
                    spacing: 1.0,
                  ),
                ),
              ),
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
                  overrideText:
                      layer.distribution == AutoLayoutDistribution.spaceBetween
                      ? 'Auto'
                      : null,
                  onDecrement: () {
                    if (layer.distribution ==
                        AutoLayoutDistribution.spaceBetween) {
                      onUpdate(
                        layer.copyWith(
                          distribution: AutoLayoutDistribution.start,
                          gap: 12.0,
                        ),
                      );
                    } else {
                      final newGap = (layer.gap - 1).clamp(0.0, maxGap);
                      onUpdate(layer.copyWith(gap: newGap));
                    }
                  },
                  onIncrement: () {
                    if (layer.distribution ==
                        AutoLayoutDistribution.spaceBetween) {
                      onUpdate(
                        layer.copyWith(
                          distribution: AutoLayoutDistribution.start,
                          gap: 16.0,
                        ),
                      );
                    } else {
                      final newGap = (layer.gap + 1).clamp(0.0, maxGap);
                      onUpdate(layer.copyWith(gap: newGap));
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Padding H
              Expanded(
                child: _buildStepperPill(
                  value: layer.paddingHorizontal.toInt(),
                  onDecrement: () {
                    final newPad = (layer.paddingHorizontal - 1).clamp(
                      0.0,
                      maxPadH,
                    );
                    onUpdate(layer.copyWith(paddingHorizontal: newPad));
                  },
                  onIncrement: () {
                    final newPad = (layer.paddingHorizontal + 1).clamp(
                      0.0,
                      maxPadH,
                    );
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
                    final newPad = (layer.paddingVertical - 1).clamp(
                      0.0,
                      maxPadV,
                    );
                    onUpdate(layer.copyWith(paddingVertical: newPad));
                  },
                  onIncrement: () {
                    final newPad = (layer.paddingVertical + 1).clamp(
                      0.0,
                      maxPadV,
                    );
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
      constraints: const BoxConstraints(minHeight: 104),
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
                  child: const Text(
                    'Text',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              _buildColorSwatch(context, layer.color, (c) {
                onUpdate(layer.copyWith(color: c));
              }),
              const SizedBox(width: 6),
              const MoreRingsIcon(
                color: AppColors.textMuted,
                size: 18,
                ringRadius: 2.1,
                strokeWidth: 1.4,
                spacing: 1.0,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Font Family Dropdown + Font Weight Dropdown + Font Size Stepper
          Row(
            children: [
              // Font Family Dropdown Pill
              Expanded(
                flex: 4,
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: layer.fontFamily,
                      dropdownColor: AppColors.surfaceElevated,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary,
                        size: 16,
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                      isExpanded: true,
                      items: () {
                        const defaultFonts = [
                          'Inter',
                          'Outfit',
                          'Poppins',
                          'Roboto',
                          'Montserrat',
                          'Lora',
                          'Playfair',
                        ];
                        final allFonts = <String>{
                          ...defaultFonts,
                          layer.fontFamily,
                        }.toList();
                        return allFonts
                            .map(
                              (f) => DropdownMenuItem(
                                value: f,
                                child: Text(
                                  f.toUpperCase(),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList();
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
              const SizedBox(width: 6),

              // Font Weight Dropdown Pill (Bold, Regular, Medium, SemiBold, etc.)
              Expanded(
                flex: 4,
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<FontWeight>(
                      value: layer.fontWeight,
                      dropdownColor: AppColors.surfaceElevated,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary,
                        size: 16,
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                      isExpanded: true,
                      items: () {
                        const weights = [
                          (FontWeight.w100, 'Thin'),
                          (FontWeight.w200, 'ExtraLight'),
                          (FontWeight.w300, 'Light'),
                          (FontWeight.w400, 'Regular'),
                          (FontWeight.w500, 'Medium'),
                          (FontWeight.w600, 'SemiBold'),
                          (FontWeight.w700, 'Bold'),
                          (FontWeight.w800, 'ExtraBold'),
                          (FontWeight.w900, 'Black'),
                        ];
                        final allWeights = <FontWeight>{
                          ...weights.map((e) => e.$1),
                          layer.fontWeight,
                        }.toList();
                        return allWeights.map((w) {
                          final match = weights.where((e) => e.$1 == w);
                          final label = match.isNotEmpty
                              ? match.first.$2
                              : 'W${w.value}';
                          return DropdownMenuItem(
                            value: w,
                            child: Text(
                              label,
                              style: TextStyle(fontWeight: w, fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList();
                      }(),
                      onChanged: (val) {
                        if (val != null) {
                          onUpdate(layer.copyWith(fontWeight: val));
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Font Size Stepper
              Expanded(
                flex: 3,
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
      items.add(
        DropdownMenuItem(
          value: entry.key,
          child: Text(
            entry.value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
    if (!presetIcons.containsKey(layer.icon)) {
      items.add(
        DropdownMenuItem(
          value: layer.icon,
          child: const Text(
            'Icon',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 104),
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
              const MoreRingsIcon(
                color: AppColors.textMuted,
                size: 18,
                ringRadius: 2.1,
                strokeWidth: 1.4,
                spacing: 1.0,
              ),
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
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
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
      constraints: const BoxConstraints(minHeight: 104),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _buildColorSwatch(context, layer.fill, (c) {
                onUpdate(layer.copyWith(fill: c));
              }),
              const SizedBox(width: 6),
              const MoreRingsIcon(
                color: AppColors.textMuted,
                size: 18,
                ringRadius: 2.1,
                strokeWidth: 1.4,
                spacing: 1.0,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'Radius',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
      constraints: const BoxConstraints(minHeight: 104),
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
              _buildTypeIconBox(Icons.image_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  layer.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const MoreRingsIcon(
                color: AppColors.textMuted,
                size: 18,
                ringRadius: 2.1,
                strokeWidth: 1.4,
                spacing: 1.0,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.aspect_ratio_rounded,
                        color: AppColors.textSecondary,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${layer.width.toInt()} × ${layer.height.toInt()} px',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(19),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    layer.fit.name.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 8. Device Mockup Properties
  Widget _buildDeviceMockupProperties(
    BuildContext context,
    DeviceMockupLayer layer,
  ) {
    return Container(
      constraints: const BoxConstraints(minHeight: 104),
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
              _buildTypeIconBox(Icons.phone_iphone_rounded),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Device Mockup',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const MoreRingsIcon(
                color: AppColors.textMuted,
                size: 18,
                ringRadius: 2.1,
                strokeWidth: 1.4,
                spacing: 1.0,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(19),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'iPhone Frame',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(19),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Portrait',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 9. Component Properties
  Widget _buildComponentProperties(
    BuildContext context,
    EditorState state,
    ComponentInstanceLayer layer,
  ) {
    return Container(
      constraints: const BoxConstraints(minHeight: 104),
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
              _buildTypeIconBox(Icons.widgets_rounded),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  layer.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFA970FF).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFFA970FF).withValues(alpha: 0.4),
                  ),
                ),
                child: const Text(
                  'COMPONENT',
                  style: TextStyle(
                    color: Color(0xFFA970FF),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    context.read<EditorBloc>().add(
                      DetachComponentInstanceEvent(layer.id),
                    );
                  },
                  borderRadius: BorderRadius.circular(19),
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(19),
                    ),
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.link_off_rounded,
                          size: 15,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Detach Instance',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 10. Multi-Selection Properties
  Widget _buildMultiSelectProperties(
    BuildContext context,
    EditorState state,
    List<Layer> selected,
  ) {
    return Container(
      constraints: const BoxConstraints(minHeight: 104),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${selected.length} selected',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  context.read<EditorBloc>().add(
                    const DeleteSelectedLayersEvent(),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5C5C).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 14,
                        color: Color(0xFFFF5C5C),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Delete',
                        style: TextStyle(
                          color: Color(0xFFFF5C5C),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<EditorBloc>().add(
                      const CreateAutoLayoutFromSelectionEvent(),
                    );
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
        ],
      ),
    );
  }

  Widget _buildGenericLayerProperties(BuildContext context, Layer layer) {
    return Container(
      constraints: const BoxConstraints(minHeight: 104),
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
              _buildTypeIconBox(Icons.layers_rounded),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  layer.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(19),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'X: ${layer.x.toInt()}  Y: ${layer.y.toInt()}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(19),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'W: ${layer.width.toInt()}  H: ${layer.height.toInt()}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
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
    String? overrideText,
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
                overrideText ?? value.toString(),
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
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
                ),
              ),
              _RepeatableActionButton(
                onTap: onIncrement,
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorSwatch(
    BuildContext context,
    Color color,
    ValueChanged<Color> onColorChanged,
  ) {
    final isTransparent = color == Colors.transparent || color.a == 0;
    return InkWell(
      onTap: () => _showColorPicker(
        context,
        isTransparent ? const Color(0xFF1E1E24) : color,
        onColorChanged,
      ),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isTransparent ? AppColors.surfaceSecondary : color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isTransparent
                ? Colors.white.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.25),
            width: 1.2,
          ),
        ),
        child: isTransparent
            ? const Center(
                child: Icon(
                  Icons.format_color_fill_rounded,
                  size: 14,
                  color: Colors.white70,
                ),
              )
            : null,
      ),
    );
  }

  void _showColorPicker(
    BuildContext context,
    Color initialColor,
    ValueChanged<Color> onColorChanged,
  ) {
    Color selected = initialColor == Colors.transparent
        ? const Color(0xFF6C5CE7)
        : initialColor;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Expanded(
              child: Text(
                'Pick Color',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.block_rounded,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'No Fill',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              onColorChanged(selected);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoLayoutSettingsSquare(
    BuildContext context,
    AutoLayoutLayer layer,
    ValueChanged<AutoLayoutLayer> onUpdate,
  ) {
    final hasStroke =
        layer.strokeColor != null &&
        layer.strokeColor != Colors.transparent &&
        layer.strokeWidth > 0;
    return InkWell(
      onTap: () => _showAutoLayoutSettingsDialog(
        context,
        layer: layer,
        onUpdate: onUpdate,
      ),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasStroke
                ? (layer.strokeColor ?? Colors.white)
                : Colors.white.withValues(alpha: 0.18),
            width: hasStroke ? (layer.strokeWidth.clamp(1.0, 3.0)) : 1.2,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.tune_rounded,
            size: 14,
            color: hasStroke
                ? (layer.strokeColor ?? Colors.white)
                : Colors.white60,
          ),
        ),
      ),
    );
  }

  void _showAutoLayoutSettingsDialog(
    BuildContext context, {
    required AutoLayoutLayer layer,
    required ValueChanged<AutoLayoutLayer> onUpdate,
  }) {
    Color? selectedBgColor = layer.backgroundColor;
    bool hasBgFill =
        layer.backgroundColor != null &&
        layer.backgroundColor != Colors.transparent;
    double selectedCornerRadius = layer.cornerRadius;
    Color? selectedStrokeColor = layer.strokeColor;
    double selectedStrokeWidth = layer.strokeWidth > 0
        ? layer.strokeWidth
        : 1.0;
    StrokePosition selectedStrokePos = layer.strokePosition;
    bool hasStroke =
        layer.strokeColor != null &&
        layer.strokeColor != Colors.transparent &&
        layer.strokeWidth > 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.tune_rounded, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Auto Layout Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
                    const Text(
                      'Background Fill',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () {
                        setDialogState(() {
                          hasBgFill = false;
                          selectedBgColor = null;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.block_rounded,
                              size: 11,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'No Fill',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
                  showLabel: false,
                  enableAlpha: false,
                  pickerAreaHeightPercent: 0.55,
                ),
                if (hasBgFill && selectedBgColor != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Corner Radius Section
                const Text(
                  'Corner Radius',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.remove,
                              size: 14,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                selectedCornerRadius =
                                    (selectedCornerRadius - 2).clamp(
                                      0.0,
                                      100.0,
                                    );
                              });
                            },
                          ),
                          Text(
                            '${selectedCornerRadius.toInt()} px',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.add,
                              size: 14,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                selectedCornerRadius =
                                    (selectedCornerRadius + 2).clamp(
                                      0.0,
                                      100.0,
                                    );
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: selectedCornerRadius == r
                                ? AppColors.primary
                                : AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${r.toInt()}px',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
                    const Text(
                      'Stroke',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () {
                        setDialogState(() {
                          hasStroke = false;
                          selectedStrokeColor = null;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: !hasStroke
                              ? AppColors.primary.withValues(alpha: 0.2)
                              : AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: !hasStroke
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.block_rounded,
                              size: 11,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'None',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Stroke Width Stepper
                Row(
                  children: [
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.remove,
                              size: 14,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                selectedStrokeWidth = (selectedStrokeWidth - 1)
                                    .clamp(1.0, 50.0);
                                hasStroke = true;
                                selectedStrokeColor ??= const Color(0xFFFFFFFF);
                              });
                            },
                          ),
                          Text(
                            '${selectedStrokeWidth.toInt()} px',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.add,
                              size: 14,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                selectedStrokeWidth = (selectedStrokeWidth + 1)
                                    .clamp(1.0, 50.0);
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: selectedStrokeWidth == w && hasStroke
                                ? AppColors.primary
                                : AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${w.toInt()}px',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // Stroke Position (Inside / Center / Outside)
                const Text(
                  'Stroke Position',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 36,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
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
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                pos.name[0].toUpperCase() +
                                    pos.name.substring(1),
                                style: TextStyle(
                                  color: selectedStrokePos == pos && hasStroke
                                      ? Colors.white
                                      : AppColors.textSecondary,
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
                const Text(
                  'Stroke Color',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                ColorPicker(
                  pickerColor: selectedStrokeColor ?? const Color(0xFFFFFFFF),
                  onColorChanged: (c) {
                    setDialogState(() {
                      selectedStrokeColor = c;
                      hasStroke = true;
                    });
                  },
                  showLabel: false,
                  enableAlpha: false,
                  pickerAreaHeightPercent: 0.55,
                ),
                if (hasStroke && selectedStrokeColor != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
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
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                onUpdate(
                  layer.copyWith(
                    backgroundColor: hasBgFill ? selectedBgColor : null,
                    clearBackgroundColor: !hasBgFill || selectedBgColor == null,
                    cornerRadius: selectedCornerRadius,
                    strokeColor: hasStroke ? selectedStrokeColor : null,
                    clearStrokeColor: !hasStroke || selectedStrokeColor == null,
                    strokeWidth: hasStroke ? selectedStrokeWidth : 0.0,
                    strokePosition: selectedStrokePos,
                  ),
                );
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTextDialog(
    BuildContext context,
    TextLayer layer,
    ValueChanged<String> onSaved,
  ) {
    final controller = TextEditingController(text: layer.content);
    TextStyle previewStyle;
    try {
      previewStyle = GoogleFonts.getFont(
        layer.fontFamily,
        color: layer.color,
        fontSize: 18,
        fontWeight: layer.fontWeight,
        fontStyle: layer.fontStyle,
      );
    } catch (_) {
      previewStyle = TextStyle(
        fontFamily: layer.fontFamily,
        color: layer.color,
        fontSize: 18,
        fontWeight: layer.fontWeight,
        fontStyle: layer.fontStyle,
      );
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final words = TextSpanParser.extractWordSegments(controller.text);

          return AlertDialog(
            backgroundColor: AppColors.surfaceElevated,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.title_rounded, size: 18, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Edit Text & Colors',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live Preview Box
                  const Text(
                    'Preview',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141419),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text.rich(
                      TextSpanParser.parseToTextSpan(
                        controller.text.isEmpty ? ' ' : controller.text,
                        previewStyle,
                      ),
                      textAlign: layer.textAlign,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Text Input
                  const Text(
                    'Content',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.surfaceSecondary,
                      hintText: 'Enter text...',
                      hintStyle: const TextStyle(color: AppColors.textMuted),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Character & Selection Color Toolbar
                  const Row(
                    children: [
                      Icon(
                        Icons.palette_rounded,
                        size: 13,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Color Selection / Letters',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Select any letters or words above, then tap a color:',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Quick Color Palette for Selection
                  Row(
                    children: [
                      for (final color in const [
                        Color(0xFF6C5CE7), // Purple
                        Color(0xFF0D99FF), // Blue
                        Color(0xFFFFA502), // Amber
                        Color(0xFF2ED573), // Green
                        Color(0xFFFF4757), // Red
                        Color(0xFFFFFFFF), // White
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: InkWell(
                            onTap: () {
                              final sel = controller.selection;
                              if (sel.isValid &&
                                  !sel.isCollapsed &&
                                  sel.start >= 0 &&
                                  sel.end <= controller.text.length) {
                                final selectedText = controller.text.substring(
                                  sel.start,
                                  sel.end,
                                );
                                final updated =
                                    TextSpanParser.applyColorToSubstring(
                                      controller.text,
                                      selectedText,
                                      color,
                                    );
                                controller.text = updated;
                              } else {
                                // Default color picker for whole or word
                                _showColorPicker(context, color, (newColor) {
                                  controller.text =
                                      '[color:${TextSpanParser.colorToHex(newColor)}]${controller.text}[/color]';
                                  setDialogState(() {});
                                });
                              }
                              setDialogState(() {});
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white24,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Custom Color Picker Button
                      InkWell(
                        onTap: () {
                          final sel = controller.selection;
                          final initialColor = const Color(0xFF6C5CE7);
                          _showColorPicker(context, initialColor, (
                            customColor,
                          ) {
                            if (sel.isValid &&
                                !sel.isCollapsed &&
                                sel.start >= 0 &&
                                sel.end <= controller.text.length) {
                              final selectedText = controller.text.substring(
                                sel.start,
                                sel.end,
                              );
                              controller.text =
                                  TextSpanParser.applyColorToSubstring(
                                    controller.text,
                                    selectedText,
                                    customColor,
                                  );
                            } else {
                              controller.text =
                                  '[color:${TextSpanParser.colorToHex(customColor)}]${controller.text}[/color]';
                            }
                            setDialogState(() {});
                          });
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 28,
                          height: 28,
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
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white38,
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.colorize_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Reset / Clear formatting for selection
                      InkWell(
                        onTap: () {
                          final sel = controller.selection;
                          if (sel.isValid &&
                              !sel.isCollapsed &&
                              sel.start >= 0 &&
                              sel.end <= controller.text.length) {
                            final selectedText = controller.text.substring(
                              sel.start,
                              sel.end,
                            );
                            controller.text =
                                TextSpanParser.applyColorToSubstring(
                                  controller.text,
                                  selectedText,
                                  null,
                                );
                          } else {
                            controller.text = TextSpanParser.stripTags(
                              controller.text,
                            );
                          }
                          setDialogState(() {});
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          height: 28,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.format_clear_rounded,
                                size: 13,
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Clear',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Word Quick Chips
                  if (words.isNotEmpty) ...[
                    const Text(
                      'Or tap word:',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final seg in words)
                          InkWell(
                            onTap: () {
                              _showColorPicker(
                                context,
                                seg.color ?? layer.color,
                                (newColor) {
                                  final updated =
                                      TextSpanParser.applyColorToWord(
                                        controller.text,
                                        seg.text,
                                        newColor,
                                      );
                                  controller.text = updated;
                                  setDialogState(() {});
                                },
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSecondary,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: seg.color != null
                                      ? seg.color!.withValues(alpha: 0.8)
                                      : AppColors.border,
                                  width: seg.color != null ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: seg.color ?? layer.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    seg.text,
                                    style: TextStyle(
                                      color: seg.color ?? Colors.white,
                                      fontSize: 11,
                                      fontWeight: seg.color != null
                                          ? FontWeight.bold
                                          : FontWeight.w500,
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
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textMuted),
                ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RepeatableActionButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _RepeatableActionButton({required this.child, required this.onTap});

  @override
  State<_RepeatableActionButton> createState() =>
      _RepeatableActionButtonState();
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
