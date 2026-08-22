import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:layerly/core/constants/app_colors.dart';
import 'package:layerly/core/constants/responsive_breakpoints.dart';
import 'package:layerly/core/utils/text_span_parser.dart';
import 'package:layerly/core/utils/uuid_generator.dart';
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
import 'package:layerly/features/editor/domain/entities/vector_layer.dart';
import 'package:layerly/features/editor/domain/entities/mockup_definition.dart';
import 'package:image_picker/image_picker.dart';

import 'package:layerly/features/editor/presentation/widgets/canvas/vector_node_editor.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_bloc.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_event.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_state.dart';
import 'package:layerly/features/editor/presentation/widgets/canvas/figma_context_menu.dart';
import 'package:layerly/core/widgets/more_rings_icon.dart';
import 'package:layerly/core/widgets/hex_color_picker_widget.dart';
import 'package:layerly/features/editor/presentation/widgets/panels/background_picker_sheet.dart';
import 'package:layerly/features/editor/presentation/widgets/panels/image_picker_sheet.dart';

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
          } else if (layer is VectorLayer) {
            content = _buildVectorProperties(context, layer);
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
                  final nextDir = switch (layer.direction) {
                    AutoLayoutDirection.horizontal => AutoLayoutDirection.vertical,
                    AutoLayoutDirection.vertical => AutoLayoutDirection.none,
                    AutoLayoutDirection.none => AutoLayoutDirection.horizontal,
                  };
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
                        switch (layer.direction) {
                          AutoLayoutDirection.horizontal => 'Horizontal',
                          AutoLayoutDirection.vertical => 'Vertical',
                          AutoLayoutDirection.none => 'Freeform (Frame)',
                        },
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  onTap: () => _showEditTextBottomSheet(context, layer, (newText) {
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
              InkWell(
                onTap: () => _showTextTypographyBottomSheet(context, layer, onUpdate),
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: MoreRingsIcon(
                    color: AppColors.textSecondary,
                    size: 18,
                    ringRadius: 2.1,
                    strokeWidth: 1.4,
                    spacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

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

  // 4b. Text Typography & Spacing Bottom Sheet
  void _showTextTypographyBottomSheet(
    BuildContext context,
    TextLayer initialLayer,
    ValueChanged<TextLayer> onUpdate,
  ) {
    var currentLayer = initialLayer;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return SafeArea(
            child: Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 16),
              height: MediaQuery.of(context).size.height * 0.76,
              decoration: BoxDecoration(
                color: const Color(0xFF14131A),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // 1. Drag handle & Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
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
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF9E77F6), Color(0xFF6C5CE7)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6C5CE7).withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.text_fields_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Typography & Spacing',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Letter spacing, line height & alignment studio',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.pop(modalCtx),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF22202C),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white10),
                              ),
                              child: const Icon(Icons.close_rounded, color: Colors.white70, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(color: Color(0xFF242232), height: 1),

                // 2. Scrollable Body
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // A. Live Preview Box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B1927),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF2E2B40)),
                        ),
                        child: () {
                          final baseStyle = TextStyle(
                            fontFamily: currentLayer.fontFamily,
                            fontSize: currentLayer.fontSize.clamp(12.0, 32.0),
                            fontWeight: currentLayer.fontWeight,
                            fontStyle: currentLayer.fontStyle,
                            letterSpacing: currentLayer.letterSpacing,
                            height: currentLayer.lineHeight,
                            color: currentLayer.color,
                            decoration: currentLayer.decoration,
                            shadows: currentLayer.shadows,
                          );
                          final span = TextSpanParser.parseToTextSpan(
                            currentLayer.content.isEmpty ? 'Typography Preview' : currentLayer.content,
                            baseStyle,
                          );
                          Widget previewWidget = Text.rich(
                            span,
                            textAlign: currentLayer.textAlign,
                          );
                          if (currentLayer.strokeColor != null &&
                              currentLayer.strokeColor != Colors.transparent &&
                              currentLayer.strokeWidth > 0) {
                            final strokeStyle = baseStyle.copyWith(
                              color: null,
                              foreground: Paint()
                                ..style = PaintingStyle.stroke
                                ..strokeWidth = currentLayer.strokeWidth * 2
                                ..strokeCap = StrokeCap.round
                                ..strokeJoin = StrokeJoin.round
                                ..color = currentLayer.strokeColor!,
                            );
                            previewWidget = Stack(
                              alignment: currentLayer.textAlign == TextAlign.center
                                  ? Alignment.center
                                  : (currentLayer.textAlign == TextAlign.right || currentLayer.textAlign == TextAlign.end
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft),
                              children: [
                                Text.rich(
                                  TextSpanParser.parseToTextSpan(
                                    currentLayer.content.isEmpty ? 'Typography Preview' : currentLayer.content,
                                    strokeStyle,
                                  ),
                                  textAlign: currentLayer.textAlign,
                                ),
                                previewWidget,
                              ],
                            );
                          }
                          return previewWidget;
                        }(),
                      ),
                      const SizedBox(height: 20),

                      // B. Letter Spacing (Tracking)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.space_bar_rounded, color: Color(0xFFA78BFA), size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Letter Spacing (Tracking)',
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              _buildSheetMicroButton(
                                icon: Icons.remove,
                                onTap: () {
                                  final val = (currentLayer.letterSpacing - 0.2).clamp(-5.0, 30.0);
                                  currentLayer = currentLayer.copyWith(letterSpacing: double.parse(val.toStringAsFixed(2)));
                                  onUpdate(currentLayer);
                                  setModalState(() {});
                                },
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 70,
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF221F32),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF383350)),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${currentLayer.letterSpacing >= 0 ? '+' : ''}${currentLayer.letterSpacing.toStringAsFixed(2)} px',
                                  style: const TextStyle(color: Color(0xFF55EFC4), fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildSheetMicroButton(
                                icon: Icons.add,
                                onTap: () {
                                  final val = (currentLayer.letterSpacing + 0.2).clamp(-5.0, 30.0);
                                  currentLayer = currentLayer.copyWith(letterSpacing: double.parse(val.toStringAsFixed(2)));
                                  onUpdate(currentLayer);
                                  setModalState(() {});
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      Slider(
                        value: currentLayer.letterSpacing.clamp(-5.0, 20.0),
                        min: -5.0,
                        max: 20.0,
                        divisions: 50,
                        activeColor: const Color(0xFF6C5CE7),
                        inactiveColor: const Color(0xFF262338),
                        onChanged: (val) {
                          currentLayer = currentLayer.copyWith(letterSpacing: double.parse(val.toStringAsFixed(2)));
                          onUpdate(currentLayer);
                          setModalState(() {});
                        },
                      ),
                      const SizedBox(height: 14),

                      // C. Line Height (Leading)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.format_line_spacing_rounded, color: Color(0xFFA78BFA), size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Line Height (Leading)',
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              _buildSheetMicroButton(
                                icon: Icons.remove,
                                onTap: () {
                                  final val = (currentLayer.lineHeight - 0.1).clamp(0.5, 4.0);
                                  currentLayer = currentLayer.copyWith(lineHeight: double.parse(val.toStringAsFixed(2)));
                                  onUpdate(currentLayer);
                                  setModalState(() {});
                                },
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 70,
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF221F32),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF383350)),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${currentLayer.lineHeight.toStringAsFixed(2)} ×',
                                  style: const TextStyle(color: Color(0xFF55EFC4), fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildSheetMicroButton(
                                icon: Icons.add,
                                onTap: () {
                                  final val = (currentLayer.lineHeight + 0.1).clamp(0.5, 4.0);
                                  currentLayer = currentLayer.copyWith(lineHeight: double.parse(val.toStringAsFixed(2)));
                                  onUpdate(currentLayer);
                                  setModalState(() {});
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      Slider(
                        value: currentLayer.lineHeight.clamp(0.6, 3.0),
                        min: 0.6,
                        max: 3.0,
                        divisions: 48,
                        activeColor: const Color(0xFF6C5CE7),
                        inactiveColor: const Color(0xFF262338),
                        onChanged: (val) {
                          currentLayer = currentLayer.copyWith(lineHeight: double.parse(val.toStringAsFixed(2)));
                          onUpdate(currentLayer);
                          setModalState(() {});
                        },
                      ),
                      const SizedBox(height: 14),

                      // D. Text Alignment
                      const Text(
                        'Text Alignment',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildAlignmentTabItem(
                            label: 'Left',
                            icon: Icons.format_align_left_rounded,
                            isSelected: currentLayer.textAlign == TextAlign.left || currentLayer.textAlign == TextAlign.start,
                            onTap: () {
                              currentLayer = currentLayer.copyWith(textAlign: TextAlign.left);
                              onUpdate(currentLayer);
                              setModalState(() {});
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildAlignmentTabItem(
                            label: 'Center',
                            icon: Icons.format_align_center_rounded,
                            isSelected: currentLayer.textAlign == TextAlign.center,
                            onTap: () {
                              currentLayer = currentLayer.copyWith(textAlign: TextAlign.center);
                              onUpdate(currentLayer);
                              setModalState(() {});
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildAlignmentTabItem(
                            label: 'Right',
                            icon: Icons.format_align_right_rounded,
                            isSelected: currentLayer.textAlign == TextAlign.right || currentLayer.textAlign == TextAlign.end,
                            onTap: () {
                              currentLayer = currentLayer.copyWith(textAlign: TextAlign.right);
                              onUpdate(currentLayer);
                              setModalState(() {});
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildAlignmentTabItem(
                            label: 'Justify',
                            icon: Icons.format_align_justify_rounded,
                            isSelected: currentLayer.textAlign == TextAlign.justify,
                            onTap: () {
                              currentLayer = currentLayer.copyWith(textAlign: TextAlign.justify);
                              onUpdate(currentLayer);
                              setModalState(() {});
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // E. Text Style & Decoration
                      const Text(
                        'Style & Decoration',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStylePill(
                            label: 'Normal',
                            icon: Icons.format_clear_rounded,
                            isSelected: currentLayer.fontStyle == FontStyle.normal && (currentLayer.decoration == null || currentLayer.decoration == TextDecoration.none),
                            onTap: () {
                              currentLayer = currentLayer.copyWith(
                                fontStyle: FontStyle.normal,
                                decoration: TextDecoration.none,
                              );
                              onUpdate(currentLayer);
                              setModalState(() {});
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildStylePill(
                            label: 'Italic',
                            icon: Icons.format_italic_rounded,
                            isSelected: currentLayer.fontStyle == FontStyle.italic,
                            onTap: () {
                              final next = currentLayer.fontStyle == FontStyle.italic
                                  ? FontStyle.normal
                                  : FontStyle.italic;
                              currentLayer = currentLayer.copyWith(fontStyle: next);
                              onUpdate(currentLayer);
                              setModalState(() {});
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildStylePill(
                            label: 'Underline',
                            icon: Icons.format_underlined_rounded,
                            isSelected: currentLayer.decoration == TextDecoration.underline,
                            onTap: () {
                              final next = currentLayer.decoration == TextDecoration.underline
                                  ? TextDecoration.none
                                  : TextDecoration.underline;
                              currentLayer = currentLayer.copyWith(decoration: next);
                              onUpdate(currentLayer);
                              setModalState(() {});
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildStylePill(
                            label: 'Strike',
                            icon: Icons.strikethrough_s_rounded,
                            isSelected: currentLayer.decoration == TextDecoration.lineThrough,
                            onTap: () {
                              final next = currentLayer.decoration == TextDecoration.lineThrough
                                  ? TextDecoration.none
                                  : TextDecoration.lineThrough;
                              currentLayer = currentLayer.copyWith(decoration: next);
                              onUpdate(currentLayer);
                              setModalState(() {});
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // F. Text Stroke (Outline)
                      () {
                        final hasStroke = currentLayer.strokeColor != null &&
                            currentLayer.strokeColor != Colors.transparent &&
                            currentLayer.strokeWidth > 0;
                        final activeStrokeColor = currentLayer.strokeColor ?? const Color(0xFF6C5CE7);
                        final activeStrokeWidth = currentLayer.strokeWidth > 0 ? currentLayer.strokeWidth : 1.5;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.border_color_rounded, color: Color(0xFFA78BFA), size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      'Text Stroke (Outline)',
                                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Switch(
                                  value: hasStroke,
                                  activeColor: const Color(0xFF6C5CE7),
                                  onChanged: (val) {
                                    if (val) {
                                      currentLayer = currentLayer.copyWith(
                                        strokeColor: activeStrokeColor,
                                        strokeWidth: activeStrokeWidth,
                                      );
                                    } else {
                                      currentLayer = currentLayer.copyWith(
                                        clearStrokeColor: true,
                                        strokeWidth: 0.0,
                                      );
                                    }
                                    onUpdate(currentLayer);
                                    setModalState(() {});
                                  },
                                ),
                              ],
                            ),
                            if (hasStroke) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  // Color swatch
                                  InkWell(
                                    onTap: () {
                                      _showColorPicker(context, activeStrokeColor, (c) {
                                        currentLayer = currentLayer.copyWith(strokeColor: c);
                                        onUpdate(currentLayer);
                                        setModalState(() {});
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF221F32),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0xFF383350)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 16,
                                            height: 16,
                                            decoration: BoxDecoration(
                                              color: activeStrokeColor,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white30),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            TextSpanParser.colorToHex(activeStrokeColor),
                                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        _buildSheetMicroButton(
                                          icon: Icons.remove,
                                          onTap: () {
                                            final w = (currentLayer.strokeWidth - 0.5).clamp(0.5, 10.0);
                                            currentLayer = currentLayer.copyWith(strokeWidth: double.parse(w.toStringAsFixed(1)));
                                            onUpdate(currentLayer);
                                            setModalState(() {});
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 60,
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF221F32),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFF383350)),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '${currentLayer.strokeWidth.toStringAsFixed(1)} px',
                                            style: const TextStyle(color: Color(0xFF55EFC4), fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        _buildSheetMicroButton(
                                          icon: Icons.add,
                                          onTap: () {
                                            final w = (currentLayer.strokeWidth + 0.5).clamp(0.5, 10.0);
                                            currentLayer = currentLayer.copyWith(strokeWidth: double.parse(w.toStringAsFixed(1)));
                                            onUpdate(currentLayer);
                                            setModalState(() {});
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Slider(
                                value: currentLayer.strokeWidth.clamp(0.5, 10.0),
                                min: 0.5,
                                max: 10.0,
                                divisions: 19,
                                activeColor: const Color(0xFF6C5CE7),
                                inactiveColor: const Color(0xFF262338),
                                onChanged: (val) {
                                  currentLayer = currentLayer.copyWith(strokeWidth: double.parse(val.toStringAsFixed(1)));
                                  onUpdate(currentLayer);
                                  setModalState(() {});
                                },
                              ),
                            ],
                          ],
                        );
                      }(),
                      const SizedBox(height: 20),

                      // G. Text Shadow (Drop Shadow)
                      () {
                        final hasShadow = currentLayer.shadows != null && currentLayer.shadows!.isNotEmpty;
                        final currentShadow = hasShadow
                            ? currentLayer.shadows!.first
                            : const Shadow(color: Colors.black54, offset: Offset(2, 2), blurRadius: 4);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.wb_sunny_rounded, color: Color(0xFFA78BFA), size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      'Text Shadow (Drop Shadow)',
                                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Switch(
                                  value: hasShadow,
                                  activeColor: const Color(0xFF6C5CE7),
                                  onChanged: (val) {
                                    if (val) {
                                      currentLayer = currentLayer.copyWith(
                                        shadows: [currentShadow],
                                      );
                                    } else {
                                      currentLayer = currentLayer.copyWith(
                                        clearShadows: true,
                                      );
                                    }
                                    onUpdate(currentLayer);
                                    setModalState(() {});
                                  },
                                ),
                              ],
                            ),
                            if (hasShadow) ...[
                              const SizedBox(height: 8),
                              // Shadow Color Row
                              Row(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      _showColorPicker(context, currentShadow.color, (c) {
                                        currentLayer = currentLayer.copyWith(
                                          shadows: [
                                            Shadow(
                                              color: c,
                                              offset: currentShadow.offset,
                                              blurRadius: currentShadow.blurRadius,
                                            ),
                                          ],
                                        );
                                        onUpdate(currentLayer);
                                        setModalState(() {});
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF221F32),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0xFF383350)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 16,
                                            height: 16,
                                            decoration: BoxDecoration(
                                              color: currentShadow.color,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white30),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            TextSpanParser.colorToHex(currentShadow.color),
                                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Blur: ${currentShadow.blurRadius.toStringAsFixed(1)}px | Offset: (${currentShadow.offset.dx.toInt()}, ${currentShadow.offset.dy.toInt()})',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Blur Slider
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Blur Radius', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  Text('${currentShadow.blurRadius.toStringAsFixed(1)} px', style: const TextStyle(color: Color(0xFF55EFC4), fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Slider(
                                value: currentShadow.blurRadius.clamp(0.0, 30.0),
                                min: 0.0,
                                max: 30.0,
                                divisions: 30,
                                activeColor: const Color(0xFF6C5CE7),
                                inactiveColor: const Color(0xFF262338),
                                onChanged: (val) {
                                  currentLayer = currentLayer.copyWith(
                                    shadows: [
                                      Shadow(
                                        color: currentShadow.color,
                                        offset: currentShadow.offset,
                                        blurRadius: val,
                                      ),
                                    ],
                                  );
                                  onUpdate(currentLayer);
                                  setModalState(() {});
                                },
                              ),
                              // Offset X & Y Sliders
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text('Offset X', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                            Text('${currentShadow.offset.dx.toInt()} px', style: const TextStyle(color: Color(0xFF55EFC4), fontSize: 11, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                        Slider(
                                          value: currentShadow.offset.dx.clamp(-20.0, 20.0),
                                          min: -20.0,
                                          max: 20.0,
                                          divisions: 40,
                                          activeColor: const Color(0xFF6C5CE7),
                                          inactiveColor: const Color(0xFF262338),
                                          onChanged: (val) {
                                            currentLayer = currentLayer.copyWith(
                                              shadows: [
                                                Shadow(
                                                  color: currentShadow.color,
                                                  offset: Offset(val, currentShadow.offset.dy),
                                                  blurRadius: currentShadow.blurRadius,
                                                ),
                                              ],
                                            );
                                            onUpdate(currentLayer);
                                            setModalState(() {});
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text('Offset Y', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                            Text('${currentShadow.offset.dy.toInt()} px', style: const TextStyle(color: Color(0xFF55EFC4), fontSize: 11, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                        Slider(
                                          value: currentShadow.offset.dy.clamp(-20.0, 20.0),
                                          min: -20.0,
                                          max: 20.0,
                                          divisions: 40,
                                          activeColor: const Color(0xFF6C5CE7),
                                          inactiveColor: const Color(0xFF262338),
                                          onChanged: (val) {
                                            currentLayer = currentLayer.copyWith(
                                              shadows: [
                                                Shadow(
                                                  color: currentShadow.color,
                                                  offset: Offset(currentShadow.offset.dx, val),
                                                  blurRadius: currentShadow.blurRadius,
                                                ),
                                              ],
                                            );
                                            onUpdate(currentLayer);
                                            setModalState(() {});
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        );
                      }(),
                    ],
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

  Widget _buildSheetMicroButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF262338),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF383350)),
        ),
        child: Icon(icon, color: Colors.white70, size: 14),
      ),
    );
  }

  Widget _buildAlignmentTabItem({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6C5CE7) : const Color(0xFF1E1C2B),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFFA29BFE) : const Color(0xFF2E2C40),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: isSelected ? Colors.white : AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStylePill({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6C5CE7) : const Color(0xFF1E1C2B),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFFA29BFE) : const Color(0xFF2E2C40),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSelected ? Colors.white : AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
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
    final isArrowOrLine = layer.shapeType == ShapeType.arrow || layer.shapeType == ShapeType.line;

    if (isArrowOrLine) {
      return _buildArrowLineCard(context, layer, onUpdate: onUpdate);
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

  Widget _buildArrowLineCard(
    BuildContext context,
    ShapeLayer layer, {
    required ValueChanged<ShapeLayer> onUpdate,
  }) {
    final effectiveColor = layer.strokeColor ?? layer.fill;
    final currentWeight = layer.strokeWidth > 0 ? layer.strokeWidth : 2.0;

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
          // 1. Top Header Row: Icon, Title ('Stroke'), Color swatch, More button
          Row(
            children: [
              _buildTypeIconBox(Icons.arrow_outward_rounded),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Stroke',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _buildColorSwatch(context, effectiveColor, (c) {
                onUpdate(layer.copyWith(fill: c, strokeColor: c));
              }),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => _showArrowEndpointsBottomSheet(context, layer, onUpdate),
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: MoreRingsIcon(
                    color: AppColors.textMuted,
                    size: 18,
                    ringRadius: 2.1,
                    strokeWidth: 1.4,
                    spacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 2. Position & Stroke Size (Weight) Row only
          Row(
            children: [
              // Position Dropdown (Inside, Center, Outside)
              Expanded(
                flex: 3,
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<StrokePosition>(
                      value: layer.strokePosition,
                      dropdownColor: AppColors.surfaceElevated,
                      isExpanded: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: StrokePosition.inside,
                          child: Text(
                            'Inside',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        DropdownMenuItem(
                          value: StrokePosition.center,
                          child: Text(
                            'Center',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        DropdownMenuItem(
                          value: StrokePosition.outside,
                          child: Text(
                            'Outside',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          onUpdate(layer.copyWith(strokePosition: val));
                        }
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Weight (Stroke Size) Stepper Pill
              Expanded(
                flex: 3,
                child: _buildStepperPill(
                  value: currentWeight.toInt(),
                  onDecrement: () {
                    final newW = (currentWeight - 1).clamp(1.0, 100.0);
                    onUpdate(layer.copyWith(strokeWidth: newW));
                  },
                  onIncrement: () {
                    final newW = (currentWeight + 1).clamp(1.0, 100.0);
                    onUpdate(layer.copyWith(strokeWidth: newW));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showArrowEndpointsBottomSheet(
    BuildContext context,
    ShapeLayer initialLayer,
    ValueChanged<ShapeLayer> onUpdate, {
    bool isStart = true,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final headStyles = [
              (ArrowHeadStyle.none, 'None', 'Flat butt end cap'),
              (ArrowHeadStyle.round, 'Round', 'Smooth rounded cap'),
              (ArrowHeadStyle.square, 'Square', 'Projecting square cap'),
              (ArrowHeadStyle.lineArrow, 'Line arrow', 'Open chevron arrow'),
              (ArrowHeadStyle.triangleArrow, 'Triangle arrow', 'Closed solid triangle'),
              (ArrowHeadStyle.reversedTriangle, 'Reversed triangle', 'Inverted triangle'),
              (ArrowHeadStyle.circleArrow, 'Circle arrow', 'Solid round terminal'),
              (ArrowHeadStyle.diamondArrow, 'Diamond arrow', 'Solid diamond terminal'),
            ];

            return SafeArea(
              child: Container(
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF161522),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF2C283F), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 16, 12),
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
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Terminal Endpoints',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              InkWell(
                                onTap: () => Navigator.pop(sheetCtx),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF22202E),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded, color: Colors.white70, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1, color: Color(0xFF242135)),

                    // Switcher Tabs for Start Point vs End Point + Reverse Button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 38,
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F1D2E),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => setModalState(() => isStart = true),
                                      borderRadius: BorderRadius.circular(9),
                                      child: Container(
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: isStart ? const Color(0xFF6C5CE7) : Colors.transparent,
                                          borderRadius: BorderRadius.circular(9),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            _buildHeadPreviewIcon(initialLayer.startHead, isStart: true),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Start Point',
                                              style: TextStyle(
                                                color: isStart ? Colors.white : AppColors.textSecondary,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => setModalState(() => isStart = false),
                                      borderRadius: BorderRadius.circular(9),
                                      child: Container(
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: !isStart ? const Color(0xFF6C5CE7) : Colors.transparent,
                                          borderRadius: BorderRadius.circular(9),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            _buildHeadPreviewIcon(initialLayer.endHead, isStart: false),
                                            const SizedBox(width: 6),
                                            Text(
                                              'End Point',
                                              style: TextStyle(
                                                color: !isStart ? Colors.white : AppColors.textSecondary,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Reverse / Swap Button
                          InkWell(
                            onTap: () {
                              initialLayer = initialLayer.copyWith(
                                startHead: initialLayer.endHead,
                                endHead: initialLayer.startHead,
                              );
                              onUpdate(initialLayer);
                              setModalState(() {});
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 38,
                              width: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F1D2E),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF2C283F)),
                              ),
                              child: const Icon(
                                Icons.sync_alt_rounded,
                                color: Color(0xFFA78BFA),
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Options List matching 2nd image
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: headStyles.length,
                        separatorBuilder: (c, i) => const Divider(height: 1, color: Color(0xFF221F33)),
                        itemBuilder: (ctx, index) {
                          final item = headStyles[index];
                          final style = item.$1;
                          final title = item.$2;
                          final subtitle = item.$3;

                          final isSelected = isStart
                              ? initialLayer.startHead == style
                              : initialLayer.endHead == style;

                          return InkWell(
                            onTap: () {
                              if (isStart) {
                                initialLayer = initialLayer.copyWith(startHead: style);
                              } else {
                                initialLayer = initialLayer.copyWith(endHead: style);
                              }
                              onUpdate(initialLayer);
                              setModalState(() {});
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    child: isSelected
                                        ? const Icon(Icons.check_rounded, color: Color(0xFFA78BFA), size: 18)
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildHeadPreviewIcon(style, isStart: isStart),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : Colors.white70,
                                            fontSize: 14,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          subtitle,
                                          style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getHeadLabel(ArrowHeadStyle style) {
    return switch (style) {
      ArrowHeadStyle.none => 'None',
      ArrowHeadStyle.round => 'Round',
      ArrowHeadStyle.square => 'Square',
      ArrowHeadStyle.lineArrow => 'Line arrow',
      ArrowHeadStyle.triangleArrow => 'Triangle',
      ArrowHeadStyle.reversedTriangle => 'Rev triangle',
      ArrowHeadStyle.circleArrow => 'Circle',
      ArrowHeadStyle.diamondArrow => 'Diamond',
    };
  }

  Widget _buildHeadPreviewIcon(ArrowHeadStyle style, {required bool isStart}) {
    return SizedBox(
      width: 24,
      height: 16,
      child: CustomPaint(
        painter: _EndpointPreviewPainter(style: style, isStart: isStart),
      ),
    );
  }

  // 7. Image Properties & Vector SVG Studio
  Widget _buildImageProperties(
    BuildContext context,
    ImageLayer layer,
  ) {
    final isSvg = (layer.svgContent != null && layer.svgContent!.isNotEmpty) ||
        (layer.imagePath?.toLowerCase().endsWith('.svg') ?? false);

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
              _buildTypeIconBox(isSvg ? Icons.draw_rounded : Icons.image_outlined),
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
              InkWell(
                onTap: () => showImagePickerBottomSheet(context, targetLayer: layer),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C5CE7).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cached_rounded, size: 12, color: Color(0xFFA78BFA)),
                      SizedBox(width: 4),
                      Text(
                        'Replace',
                        style: TextStyle(color: Color(0xFFA78BFA), fontSize: 11, fontWeight: FontWeight.bold),
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
                child: InkWell(
                  onTap: () => showImagePickerBottomSheet(context, targetLayer: layer),
                  borderRadius: BorderRadius.circular(19),
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
                        Icon(
                          isSvg ? Icons.draw_rounded : Icons.add_photo_alternate_rounded,
                          color: const Color(0xFF55EFC4),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isSvg ? 'Vector SVG' : (layer.imagePath != null ? 'Change File' : 'Pick Image / SVG'),
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
                    '${layer.width.toInt()} × ${layer.height.toInt()} px',
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

  // 8. Vector Layer Properties & Multi-Sublayer Studio
  Widget _buildVectorProperties(
    BuildContext context,
    VectorLayer layer,
  ) {
    // Unique colors across all sub-elements
    final colors = <Color>{};
    for (final elem in layer.elements) {
      if (elem.fill != null) colors.add(elem.fill!);
      if (elem.strokeColor != null) colors.add(elem.strokeColor!);
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
          // Header Row
          Row(
            children: [
              _buildTypeIconBox(Icons.polyline_rounded),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      layer.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${layer.elements.length} Sub-Layers • Vector Graphic',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => showVectorNodeEditorSheet(
                  context,
                  layer,
                  onUpdate: (u) => context.read<EditorBloc>().add(UpdateLayerEvent(u)),
                ),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_road_rounded, size: 13, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Edit Nodes',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Palette preview of all sub-layer colors
          if (colors.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Vector Palette: ', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                const SizedBox(width: 4),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: colors.map((c) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white30, width: 1),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 10),

          // Action Buttons: Unpack Sub-Layers into Canvas Layers
          Row(
            children: [
              if (layer.elements.length > 1) ...[
                Expanded(
                  child: InkWell(
                    onTap: () {
                      final bloc = context.read<EditorBloc>();
                      // Remove composite layer
                      bloc.add(const DeleteSelectedLayersEvent());
                      // Add each sub-layer as an independent layer on canvas
                      final newIds = <String>[];
                      for (int i = 0; i < layer.elements.length; i++) {
                        final elem = layer.elements[i];
                        final subLayer = VectorLayer(
                          id: 'subvec-${UuidGenerator.generate().substring(0, 8)}',
                          name: '${layer.name} / ${elem.name}',
                          x: layer.x,
                          y: layer.y,
                          width: layer.width,
                          height: layer.height,
                          elements: [elem],
                        );
                        newIds.add(subLayer.id);
                        bloc.add(AddLayerEvent(subLayer));
                      }
                      if (newIds.isNotEmpty) {
                        bloc.add(SelectMultipleLayersEvent(newIds));
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Unpacked ${layer.elements.length} vector sub-layers into independent canvas layers!'),
                          backgroundColor: const Color(0xFF6C5CE7),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(19),
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00CEC9).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(color: const Color(0xFF00CEC9).withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.layers_outlined, color: Color(0xFF00CEC9), size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Unpack to Layers',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: InkWell(
                  onTap: () => showVectorNodeEditorSheet(
                    context,
                    layer,
                    onUpdate: (u) => context.read<EditorBloc>().add(UpdateLayerEvent(u)),
                  ),
                  borderRadius: BorderRadius.circular(19),
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(19),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${layer.width.toInt()} × ${layer.height.toInt()} px',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
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

  void _showSvgCodeEditorDialog(BuildContext context, ImageLayer layer) {
    String initialCode = layer.svgContent ?? '';
    if (initialCode.isEmpty && layer.imagePath != null) {
      try {
        final f = File(layer.imagePath!);
        if (f.existsSync()) {
          initialCode = f.readAsStringSync();
        }
      } catch (_) {}
    }
    if (initialCode.isEmpty) {
      initialCode = '<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">\n  <circle cx="50" cy="50" r="40" fill="#6C5CE7" />\n</svg>';
    }

    final textController = TextEditingController(text: initialCode);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF161522),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF55EFC4).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.code_rounded, color: Color(0xFF55EFC4), size: 18),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Live SVG Code Editor',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 18),
              onPressed: () => Navigator.pop(dialogCtx),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit or paste SVG XML markup below. Changes update the canvas in real time.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F0E17),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2E2A42)),
                ),
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: textController,
                  maxLines: null,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Color(0xFF55EFC4),
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final newCode = textController.text.trim();
              if (newCode.isNotEmpty) {
                context.read<EditorBloc>().add(
                  UpdateLayerEvent(layer.copyWith(svgContent: newCode)),
                );
              }
              Navigator.pop(dialogCtx);
            },
            child: const Text('Apply SVG to Canvas'),
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
    final bloc = context.read<EditorBloc>();
    final currentDef = MockupDefinition.fromDevice(layer.device);

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
          // Header: Device Icon, Name, and Quick Upload
          Row(
            children: [
              _buildTypeIconBox(Icons.phone_iphone_rounded),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      layer.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      currentDef.name,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () async {
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
                  if (picked != null) {
                    bloc.add(UpdateLayerEvent(layer.copyWith(screenImagePath: picked.path)));
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0984E3).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF0984E3).withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_library_outlined, size: 12, color: Color(0xFF74B9FF)),
                      SizedBox(width: 4),
                      Text(
                        'Gallery',
                        style: TextStyle(color: Color(0xFF74B9FF), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Device Selector Dropdown
          Row(
            children: [
              const SizedBox(
                width: 65,
                child: Text(
                  'Device',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<MockupDevice>(
                      value: layer.device,
                      dropdownColor: const Color(0xFF1E2028),
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
                      items: const [
                        DropdownMenuItem(
                          value: MockupDevice.iphone17ProMax,
                          child: Text('iPhone 17 Pro Max', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: MockupDevice.iphone17Pro,
                          child: Text('iPhone 17 Pro', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: MockupDevice.iphone,
                          child: Text('iPhone 16 Pro', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: MockupDevice.android,
                          child: Text('Android Phone', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: MockupDevice.macbook,
                          child: Text('MacBook Pro 16"', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: MockupDevice.ipadPro,
                          child: Text('iPad Pro 13"', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: MockupDevice.appleWatch,
                          child: Text('Apple Watch Ultra', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: MockupDevice.browser,
                          child: Text('Desktop Browser', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      ],
                      onChanged: (MockupDevice? newDevice) {
                        if (newDevice != null) {
                          final newDef = MockupDefinition.fromDevice(newDevice);
                          final newHeight = layer.width / newDef.physicalAspectRatio;
                          bloc.add(
                            UpdateLayerEvent(
                              layer.copyWith(
                                device: newDevice,
                                height: newHeight,
                                cornerRadius: newDef.cornerRadius,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Artwork Image Management Row
          Row(
            children: [
              const SizedBox(
                width: 65,
                child: Text(
                  'Artwork',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
                    if (picked != null) {
                      bloc.add(UpdateLayerEvent(layer.copyWith(screenImagePath: picked.path)));
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_photo_alternate_outlined, color: Color(0xFFA78BFA), size: 14),
                        const SizedBox(width: 6),
                        Text(
                          layer.screenImagePath != null ? 'Replace image' : 'Pick image',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (layer.screenImagePath != null) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: () {
                    bloc.add(UpdateLayerEvent(layer.copyWith(screenImagePath: null)));
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5C67).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline, color: Color(0xFFFF5C67), size: 16),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Image Fit Row: Cover, Contain, Fill
          Row(
            children: [
              const SizedBox(
                width: 65,
                child: Text(
                  'Fit',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(
                child: Container(
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildFitOption(
                          label: 'Cover',
                          isSelected: layer.imageFit == BoxFit.cover,
                          onTap: () => bloc.add(UpdateLayerEvent(layer.copyWith(imageFit: BoxFit.cover))),
                        ),
                      ),
                      Expanded(
                        child: _buildFitOption(
                          label: 'Contain',
                          isSelected: layer.imageFit == BoxFit.contain,
                          onTap: () => bloc.add(UpdateLayerEvent(layer.copyWith(imageFit: BoxFit.contain))),
                        ),
                      ),
                      Expanded(
                        child: _buildFitOption(
                          label: 'Fill',
                          isSelected: layer.imageFit == BoxFit.fill,
                          onTap: () => bloc.add(UpdateLayerEvent(layer.copyWith(imageFit: BoxFit.fill))),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Scale Slider Row
          Row(
            children: [
              const SizedBox(
                width: 65,
                child: Text(
                  'Scale',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: const Color(0xFF9B6CFF),
                    inactiveTrackColor: Colors.white12,
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    value: layer.imageScale.clamp(0.5, 2.5),
                    min: 0.5,
                    max: 2.5,
                    onChanged: (v) {
                      bloc.add(UpdateLayerEvent(layer.copyWith(imageScale: (v * 100).round() / 100)));
                    },
                  ),
                ),
              ),
              SizedBox(
                width: 44,
                child: Text(
                  '${(layer.imageScale * 100).toInt()}%',
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Toggles: Dynamic Island & Glass Glare
          Row(
            children: [
              if (currentDef.hasDynamicIsland) ...[
                Expanded(
                  child: InkWell(
                    onTap: () => bloc.add(UpdateLayerEvent(layer.copyWith(showDynamicIsland: !layer.showDynamicIsland))),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: layer.showDynamicIsland ? const Color(0xFF9B6CFF).withValues(alpha: 0.18) : AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: layer.showDynamicIsland ? const Color(0xFF9B6CFF).withValues(alpha: 0.4) : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.panorama_fish_eye_rounded,
                            size: 13,
                            color: layer.showDynamicIsland ? const Color(0xFFB388FF) : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Island',
                            style: TextStyle(
                              color: layer.showDynamicIsland ? Colors.white : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: InkWell(
                  onTap: () => bloc.add(UpdateLayerEvent(layer.copyWith(showGlare: !layer.showGlare))),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: layer.showGlare ? const Color(0xFF9B6CFF).withValues(alpha: 0.18) : AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: layer.showGlare ? const Color(0xFF9B6CFF).withValues(alpha: 0.4) : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 13,
                          color: layer.showGlare ? const Color(0xFFB388FF) : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Glare',
                          style: TextStyle(
                            color: layer.showGlare ? Colors.white : AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => bloc.add(UpdateLayerEvent(layer.copyWith(showShadow: !layer.showShadow))),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: layer.showShadow ? const Color(0xFF9B6CFF).withValues(alpha: 0.18) : AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: layer.showShadow ? const Color(0xFF9B6CFF).withValues(alpha: 0.4) : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wb_shade_rounded,
                          size: 13,
                          color: layer.showShadow ? const Color(0xFFB388FF) : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Shadow',
                          style: TextStyle(
                            color: layer.showShadow ? Colors.white : AppColors.textSecondary,
                            fontSize: 11,
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

  Widget _buildFitOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF9B6CFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
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

  void _showEditTextBottomSheet(
    BuildContext context,
    TextLayer layer,
    ValueChanged<String> onSaved,
  ) {
    final controller = RichColorTextEditingController(taggedText: layer.content);
    Color activeColor = controller.ranges.isNotEmpty
        ? controller.ranges.first.color
        : layer.color;
    controller.activeColor = activeColor;

    TextStyle editorBaseStyle;
    try {
      editorBaseStyle = GoogleFonts.getFont(
        layer.fontFamily,
        color: layer.color,
        fontSize: layer.fontSize.clamp(14.0, 26.0),
        fontWeight: layer.fontWeight,
        fontStyle: layer.fontStyle,
        letterSpacing: layer.letterSpacing,
        height: layer.lineHeight,
      );
    } catch (_) {
      editorBaseStyle = TextStyle(
        fontFamily: layer.fontFamily,
        color: layer.color,
        fontSize: layer.fontSize.clamp(14.0, 26.0),
        fontWeight: layer.fontWeight,
        fontStyle: layer.fontStyle,
        letterSpacing: layer.letterSpacing,
        height: layer.lineHeight,
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final words = TextSpanParser.extractCleanWordSegments(
            controller.text,
            controller.ranges,
          );

          // Update active color based on cursor position
          if (controller.selection.isValid && controller.selection.isCollapsed) {
            final cursorColor = controller.getColorAtCursor(controller.selection.baseOffset);
            if (cursorColor != null && cursorColor != activeColor) {
              activeColor = cursorColor;
              controller.activeColor = activeColor;
            }
          }

          return SafeArea(
            child: Container(
              margin: EdgeInsets.only(
                left: 14,
                right: 14,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 16,
              ),
              height: MediaQuery.of(context).size.height * 0.78,
              decoration: BoxDecoration(
                color: const Color(0xFF14131A),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: const Color(0xFF2A2838), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Drag handle & Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
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
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF9E77F6), Color(0xFF6C5CE7)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6C5CE7).withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.title_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Edit Text & Multi-Colors',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Type & format directly with live inline styling',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () => Navigator.pop(modalCtx),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22202C),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: const Icon(Icons.close_rounded, color: Colors.white70, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Divider(color: Color(0xFF242232), height: 1),

                  // 2. Scrollable Content Area
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        // A. Live WYSIWYG Editable Text Area
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.edit_note_rounded, size: 15, color: Color(0xFFA78BFA)),
                                SizedBox(width: 6),
                                Text(
                                  'Editable Content (Direct Preview)',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                    color: activeColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: activeColor.withValues(alpha: 0.6),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Typing style',
                                  style: TextStyle(
                                    color: activeColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(minHeight: 120),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B1927),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF2E2B40), width: 1.2),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: TextField(
                            controller: controller,
                            autofocus: true,
                            maxLines: null,
                            textAlign: layer.textAlign,
                            style: editorBaseStyle,
                            cursorColor: activeColor,
                            onChanged: (_) {
                              setModalState(() {});
                            },
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: 'Enter text here...',
                              hintStyle: TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // B. Premium Color Palette Bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.palette_rounded, size: 15, color: Color(0xFFA78BFA)),
                                SizedBox(width: 6),
                                Text(
                                  'Color Palette',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1B2E),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF383350)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: activeColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: activeColor.withValues(alpha: 0.6),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    TextSpanParser.colorToHex(activeColor),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Select text in editor above to apply color, or pick a color to type with it:',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                        const SizedBox(height: 12),

                        // Enhanced Swatches Row
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            for (final color in const [
                              Color(0xFFFFFFFF), // White
                              Color(0xFF6C5CE7), // Electric Purple
                              Color(0xFF8B5CF6), // Deep Violet
                              Color(0xFF0D99FF), // Vivid Blue
                              Color(0xFF00F298), // Neon Mint
                              Color(0xFFFFA502), // Golden Amber
                              Color(0xFFFF4757), // Coral Flame
                              Color(0xFFFF007F), // Hot Magenta
                            ])
                              InkWell(
                                onTap: () {
                                  activeColor = color;
                                  controller.activeColor = color;
                                  if (controller.selection.isValid && !controller.selection.isCollapsed) {
                                    controller.applyColorToSelection(color);
                                  }
                                  setModalState(() {});
                                },
                                borderRadius: BorderRadius.circular(18),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: activeColor == color ? Colors.white : Colors.white24,
                                      width: activeColor == color ? 2.8 : 1.2,
                                    ),
                                    boxShadow: [
                                      if (activeColor == color)
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.65),
                                          blurRadius: 12,
                                          spreadRadius: 1,
                                        )
                                      else
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                    ],
                                  ),
                                  child: activeColor == color
                                      ? Center(
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            // Custom Color Picker Button
                            InkWell(
                              onTap: () {
                                _showColorPicker(context, activeColor, (customColor) {
                                  activeColor = customColor;
                                  controller.activeColor = customColor;
                                  if (controller.selection.isValid && !controller.selection.isCollapsed) {
                                    controller.applyColorToSelection(customColor);
                                  }
                                  setModalState(() {});
                                });
                              },
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                width: 36,
                                height: 36,
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
                                  border: Border.all(color: Colors.white38, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.4),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.colorize_rounded, size: 16, color: Colors.white),
                              ),
                            ),
                            // Clear formatting pill
                            InkWell(
                              onTap: () {
                                activeColor = layer.color;
                                controller.activeColor = layer.color;
                                if (controller.selection.isValid && !controller.selection.isCollapsed) {
                                  controller.applyColorToSelection(null);
                                } else {
                                  controller.ranges.clear();
                                  controller.notifyListeners();
                                }
                                setModalState(() {});
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                height: 36,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF221F32),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFF383350)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.format_clear_rounded, size: 14, color: AppColors.textSecondary),
                                    SizedBox(width: 5),
                                    Text(
                                      'Reset',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 3. Footer Action Bar
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF14131A),
                      border: Border(top: BorderSide(color: Color(0xFF242232))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(modalCtx),
                          child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () {
                            if (controller.text.isNotEmpty) {
                              onSaved(controller.toTaggedString());
                            }
                            Navigator.pop(modalCtx);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF9E77F6), Color(0xFF6C5CE7)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6C5CE7).withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Save Changes',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
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

class _EndpointPreviewPainter extends CustomPainter {
  final ArrowHeadStyle style;
  final bool isStart;

  _EndpointPreviewPainter({required this.style, required this.isStart});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = switch (style) {
        ArrowHeadStyle.round => StrokeCap.round,
        ArrowHeadStyle.square => StrokeCap.square,
        _ => StrokeCap.butt,
      };

    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final y = size.height / 2;
    // Line shaft
    canvas.drawLine(Offset(0, y), Offset(size.width, y), strokePaint);

    final p = isStart ? Offset(0, y) : Offset(size.width, y);
    final angle = isStart ? math.pi : 0.0;
    const headSize = 6.0;

    if (style == ArrowHeadStyle.none || style == ArrowHeadStyle.round || style == ArrowHeadStyle.square) {
      return;
    }

    canvas.save();
    canvas.translate(p.dx, p.dy);
    canvas.rotate(angle);

    final path = Path();
    switch (style) {
      case ArrowHeadStyle.lineArrow:
        path.moveTo(-headSize, -headSize * 0.6);
        path.lineTo(0, 0);
        path.lineTo(-headSize, headSize * 0.6);
        canvas.drawPath(path, strokePaint);
        break;

      case ArrowHeadStyle.triangleArrow:
        path.moveTo(0, 0);
        path.lineTo(-headSize, -headSize * 0.55);
        path.lineTo(-headSize, headSize * 0.55);
        path.close();
        canvas.drawPath(path, fillPaint);
        break;

      case ArrowHeadStyle.reversedTriangle:
        path.moveTo(-headSize, 0);
        path.lineTo(0, -headSize * 0.55);
        path.lineTo(0, headSize * 0.55);
        path.close();
        canvas.drawPath(path, fillPaint);
        break;

      case ArrowHeadStyle.circleArrow:
        canvas.drawCircle(const Offset(-3, 0), 2.5, fillPaint);
        break;

      case ArrowHeadStyle.diamondArrow:
        path.moveTo(0, 0);
        path.lineTo(-3, -2.5);
        path.lineTo(-6, 0);
        path.lineTo(-3, 2.5);
        path.close();
        canvas.drawPath(path, fillPaint);
        break;

      default:
        break;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _EndpointPreviewPainter oldDelegate) =>
      oldDelegate.style != style || oldDelegate.isStart != isStart;
}

