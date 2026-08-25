import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:layerly/core/constants/app_colors.dart';
import 'package:layerly/core/utils/uuid_generator.dart';
import 'package:layerly/features/editor/domain/entities/layer_enums.dart';
import 'package:layerly/features/editor/domain/entities/text_layer.dart';
import 'package:layerly/features/editor/domain/entities/shape_layer.dart';
import 'package:layerly/features/editor/domain/entities/auto_layout_layer.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_bloc.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_event.dart';
import 'package:layerly/core/widgets/more_rings_icon.dart';
import 'package:layerly/core/widgets/app_modal_sheet.dart';
import 'package:layerly/features/editor/presentation/widgets/panels/background_picker_sheet.dart';
import 'package:layerly/features/editor/presentation/widgets/panels/components_picker_sheet.dart';
import 'package:layerly/features/editor/presentation/widgets/panels/layouts_assets_sheet.dart';
import 'package:layerly/features/editor/presentation/widgets/panels/layers_sheet.dart';
import 'package:layerly/features/editor/presentation/widgets/panels/image_picker_sheet.dart';

class BottomToolbox extends StatefulWidget {
  const BottomToolbox({super.key});

  @override
  State<BottomToolbox> createState() => _BottomToolboxState();
}

class _BottomToolboxState extends State<BottomToolbox> {
  bool _isShapesOpen = false;
  OverlayEntry? _shapesOverlayEntry;

  void _toggleShapes() {
    if (_isShapesOpen) {
      _closeShapes();
    } else {
      _openShapes();
    }
  }

  void _closeShapes() {
    if (!_isShapesOpen && _shapesOverlayEntry == null) return;
    _shapesOverlayEntry?.remove();
    _shapesOverlayEntry = null;
    if (mounted) {
      setState(() {
        _isShapesOpen = false;
      });
    }
  }

  void _openShapes() {
    _closeShapes();
    final overlay = Overlay.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    _shapesOverlayEntry = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          // Dismiss on tap outside
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closeShapes,
              child: const SizedBox.expand(),
            ),
          ),
          // Floating Shapes Card overlayed right above navbar
          Positioned(
            left: 14,
            right: 14,
            bottom: 74 + bottomPadding,
            child: Material(
              color: Colors.transparent,
              child: _buildGlassyShapesCard(context),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_shapesOverlayEntry!);
    setState(() {
      _isShapesOpen = true;
    });
  }

  @override
  void dispose() {
    _shapesOverlayEntry?.remove();
    _shapesOverlayEntry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      margin: const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(27),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF9D75F6).withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF2A2342).withValues(alpha: 0.65),
                  const Color(0xFF13101E).withValues(alpha: 0.70),
                  const Color(0xFF0C0A14).withValues(alpha: 0.85),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
              borderRadius: BorderRadius.circular(27),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.16),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 1. Shapes Button (Filled icon + colored arrow container when selected)
                Tooltip(
                  message: 'Shapes',
                  child: InkWell(
                    onTap: _toggleShapes,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Shape: Filled when open, outlined when closed
                          Container(
                            width: 19,
                            height: 19,
                            decoration: BoxDecoration(
                              color: _isShapesOpen
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(5.0),
                              border: _isShapesOpen
                                  ? null
                                  : Border.all(color: Colors.white, width: 1.8),
                            ),
                          ),
                          const SizedBox(width: 5),
                          // Arrow: Colored container with up-caret when open, regular icon when closed
                          if (_isShapesOpen)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4C3E75),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.keyboard_arrow_up_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            )
                          else
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. Text 'T'
                _buildToolButton(
                  customWidget: const Text(
                    'T',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                  tooltip: 'Text',
                  onTap: () {
                    _closeShapes();
                    _showTextSheet(context);
                  },
                ),

                // 3. Images & Gallery
                _buildToolButton(
                  customWidget: const CustomPaint(
                    size: Size(20, 20),
                    painter: _PhotoIconPainter(),
                  ),
                  tooltip: 'Images & Gallery',
                  onTap: () {
                    _closeShapes();
                    _showImagesSheet(context);
                  },
                ),

                // 4. Layers
                _buildToolButton(
                  customWidget: const CustomPaint(
                    size: Size(20, 20),
                    painter: _LayersIconPainter(),
                  ),
                  tooltip: 'Layers',
                  onTap: () {
                    _closeShapes();
                    _showLayersSheet(context);
                  },
                ),

                // 5. Components / Elements
                _buildToolButton(
                  customWidget: const CustomPaint(
                    size: Size(20, 20),
                    painter: _DiamondGridPainter(),
                  ),
                  tooltip: 'Components',
                  onTap: () {
                    _closeShapes();
                    _showComponentsSheet(context);
                  },
                ),

                // 6. Bento Layouts / Templates
                _buildToolButton(
                  customWidget: const CustomPaint(
                    size: Size(20, 20),
                    painter: _BentoLayoutPainter(),
                  ),
                  tooltip: 'Layouts & Assets',
                  onTap: () {
                    _closeShapes();
                    _showAssetsSheet(context);
                  },
                ),

                // Vertical Divider
                Container(
                  height: 24,
                  width: 1.2,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: const Color(0xFF38324E),
                ),

                // 7. More options (... rings)
                _buildToolButton(
                  customWidget: const MoreRingsIcon(
                    size: 20,
                    color: Colors.white,
                  ),
                  tooltip: 'More options',
                  onTap: () {
                    _closeShapes();
                    _showMoreSheet(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required Widget customWidget,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          child: customWidget,
        ),
      ),
    );
  }

  Widget _buildGlassyShapesCard(BuildContext context) {
    final bloc = context.read<EditorBloc>();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: const Color(0xFF9E77F6).withValues(alpha: 0.20),
            blurRadius: 30,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF2C2448).withValues(alpha: 0.72),
                  const Color(0xFF181428).withValues(alpha: 0.78),
                  const Color(0xFF0F0D1A).withValues(alpha: 0.85),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
                width: 1.2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Drag Indicator
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Header
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
                            color: const Color(
                              0xFF6C5CE7,
                            ).withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.category_rounded,
                        color: Colors.white,
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Shapes & Containers',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          SizedBox(height: 1),
                          Text(
                            'Tap any shape or frame to insert onto canvas',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: _closeShapes,
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                          size: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Glassy Shapes 2-Column Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildGlassShapeTile(
                        icon: Icons.crop_free_rounded,
                        title: 'Frame',
                        subtitle: 'Auto container',
                        shortcut: 'F',
                        accentColor: const Color(0xFF9E77F6),
                        onTap: () {
                          bloc.add(
                            AddLayerEvent(
                              AutoLayoutLayer(
                                id: UuidGenerator.generate(),
                                name: 'Frame',
                                direction: AutoLayoutDirection.none,
                                x: 120,
                                y: 160,
                                width: 340,
                                height: 260,
                                backgroundColor: const Color(0xFF1E1C2B),
                                cornerRadius: 16,
                                strokeColor: const Color(0xFF37334F),
                                strokeWidth: 1.5,
                                horizontalSizing: AutoLayoutSizingMode.fixed,
                                verticalSizing: AutoLayoutSizingMode.fixed,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildGlassShapeTile(
                        icon: Icons.crop_square_rounded,
                        title: 'Rectangle',
                        subtitle: 'Sharp box',
                        shortcut: 'R',
                        accentColor: const Color(0xFF0D99FF),
                        onTap: () {
                          bloc.add(
                            AddLayerEvent(
                              ShapeLayer(
                                id: UuidGenerator.generate(),
                                name: 'Rectangle',
                                shapeType: ShapeType.rectangle,
                                x: 180,
                                y: 200,
                                width: 240,
                                height: 150,
                                fill: const Color(0xFF262438),
                                cornerRadius: 0,
                                strokeColor: const Color(0xFF3B3754),
                                strokeWidth: 1.5,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildGlassShapeTile(
                        icon: Icons.rectangle_outlined,
                        title: 'Rounded',
                        subtitle: 'Pill / card',
                        shortcut: 'U',
                        accentColor: const Color(0xFF00F298),
                        onTap: () {
                          bloc.add(
                            AddLayerEvent(
                              ShapeLayer(
                                id: UuidGenerator.generate(),
                                name: 'Rounded Rectangle',
                                shapeType: ShapeType.roundedRectangle,
                                x: 180,
                                y: 200,
                                width: 240,
                                height: 150,
                                fill: const Color(0xFF262438),
                                cornerRadius: 16,
                                strokeColor: const Color(0xFF3B3754),
                                strokeWidth: 1.5,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildGlassShapeTile(
                        icon: Icons.circle_outlined,
                        title: 'Ellipse',
                        subtitle: 'Circle',
                        shortcut: 'O',
                        accentColor: const Color(0xFF6C5CE7),
                        onTap: () {
                          bloc.add(
                            AddLayerEvent(
                              ShapeLayer(
                                id: UuidGenerator.generate(),
                                name: 'Ellipse',
                                shapeType: ShapeType.circle,
                                x: 200,
                                y: 200,
                                width: 180,
                                height: 180,
                                fill: const Color(0xFF6C5CE7),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildGlassShapeTile(
                        icon: Icons.horizontal_rule_rounded,
                        title: 'Line',
                        subtitle: 'Stroke vector',
                        shortcut: 'L',
                        accentColor: const Color(0xFF00D2D3),
                        onTap: () {
                          bloc.add(
                            AddLayerEvent(
                              ShapeLayer(
                                id: UuidGenerator.generate(),
                                name: 'Line',
                                shapeType: ShapeType.line,
                                x: 180,
                                y: 240,
                                width: 220,
                                height: 4,
                                strokeWidth: 3.0,
                                fill: const Color(0xFF8B5CF6),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildGlassShapeTile(
                        icon: Icons.arrow_outward_rounded,
                        title: 'Arrow',
                        subtitle: 'Directional',
                        shortcut: 'Shift+L',
                        accentColor: const Color(0xFFFF4757),
                        onTap: () {
                          bloc.add(
                            AddLayerEvent(
                              ShapeLayer(
                                id: UuidGenerator.generate(),
                                name: 'Arrow',
                                shapeType: ShapeType.arrow,
                                x: 180,
                                y: 200,
                                width: 220,
                                height: 24,
                                strokeWidth: 3.0,
                                fill: const Color(0xFFFF4757),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildGlassShapeTile(
                        icon: Icons.change_history_rounded,
                        title: 'Polygon',
                        subtitle: 'Triangle',
                        shortcut: 'P',
                        accentColor: const Color(0xFFFFA502),
                        onTap: () {
                          bloc.add(
                            AddLayerEvent(
                              ShapeLayer(
                                id: UuidGenerator.generate(),
                                name: 'Polygon',
                                shapeType: ShapeType.triangle,
                                x: 200,
                                y: 200,
                                width: 180,
                                height: 180,
                                fill: const Color(0xFFFFA502),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildGlassShapeTile(
                        icon: Icons.star_border_rounded,
                        title: 'Star',
                        subtitle: '5-Point badge',
                        shortcut: 'S',
                        accentColor: const Color(0xFFFFB800),
                        onTap: () {
                          bloc.add(
                            AddLayerEvent(
                              ShapeLayer(
                                id: UuidGenerator.generate(),
                                name: 'Star',
                                shapeType: ShapeType.star,
                                x: 200,
                                y: 200,
                                width: 180,
                                height: 180,
                                fill: const Color(0xFFFFB800),
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
          ),
        ),
      ),
    );
  }

  Widget _buildGlassShapeTile({
    required IconData icon,
    required String title,
    required String subtitle,
    String? shortcut,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        _closeShapes();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF241F38).withValues(alpha: 0.50),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.4),
                  width: 1.0,
                ),
              ),
              child: Icon(icon, size: 18, color: accentColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (shortcut != null) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            shortcut,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTextSheet(BuildContext context) {
    final bloc = context.read<EditorBloc>();
    showAppModalSheet(
      context: context,
      builder: (ctx) => AppModalSheet(
        icon: Icons.title_rounded,
        title: 'Add Text',
        subtitle: 'Select typography level to insert on canvas',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSheetActionTile(
              icon: Icons.format_size_rounded,
              iconColor: AppColors.primaryLight,
              title: 'Heading',
              subtitle: '48px Outfit Bold — Main hero titles',
              onTap: () {
                Navigator.pop(ctx);
                bloc.add(
                  AddLayerEvent(
                    TextLayer(
                      id: UuidGenerator.generate(),
                      name: 'Heading',
                      x: 100,
                      y: 200,
                      width: 500,
                      height: 70,
                      content: 'Heading Text',
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 6),
            AppSheetActionTile(
              icon: Icons.text_fields_rounded,
              iconColor: const Color(0xFF00CEC9),
              title: 'Subheading',
              subtitle: '28px SemiBold — Section subtitles',
              onTap: () {
                Navigator.pop(ctx);
                bloc.add(
                  AddLayerEvent(
                    TextLayer(
                      id: UuidGenerator.generate(),
                      name: 'Subheading',
                      x: 100,
                      y: 200,
                      width: 440,
                      height: 50,
                      content: 'Subheading description',
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 6),
            AppSheetActionTile(
              icon: Icons.notes_rounded,
              iconColor: const Color(0xFFA78BFA),
              title: 'Body Text',
              subtitle: '16px Regular — Paragraphs and details',
              onTap: () {
                Navigator.pop(ctx);
                bloc.add(
                  AddLayerEvent(
                    TextLayer(
                      id: UuidGenerator.generate(),
                      name: 'Body',
                      x: 100,
                      y: 200,
                      width: 400,
                      height: 60,
                      content: 'Add your clean paragraph content here.',
                      fontSize: 16,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showImagesSheet(BuildContext context) {
    showImagePickerBottomSheet(context, bloc: context.read<EditorBloc>());
  }

  void _showLayersSheet(BuildContext context) {
    showLayersBottomSheet(context, bloc: context.read<EditorBloc>());
  }

  void _showComponentsSheet(BuildContext context) {
    showComponentsPickerSheet(context, bloc: context.read<EditorBloc>());
  }

  void _showAssetsSheet(BuildContext context) {
    showLayoutsAssetsSheet(context, bloc: context.read<EditorBloc>());
  }

  void _showMoreSheet(BuildContext context) {
    final bloc = context.read<EditorBloc>();
    final state = bloc.state;
    showAppModalSheet(
      context: context,
      builder: (ctx) => AppModalSheet(
        icon: Icons.tune_rounded,
        title: 'Settings & Tools',
        subtitle: 'Canvas layout, snapping, and background options',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSheetActionTile(
              icon: Icons.grid_on_rounded,
              iconColor: state.showGrid ? AppColors.primary : AppColors.textSecondary,
              title: 'Show Grid',
              subtitle: 'Toggle alignment grid overlay',
              trailing: Switch(
                value: state.showGrid,
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                onChanged: (_) {
                  bloc.add(const ToggleGridEvent());
                  Navigator.pop(ctx);
                },
              ),
              onTap: () {
                bloc.add(const ToggleGridEvent());
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 6),
            AppSheetActionTile(
              icon: Icons.align_horizontal_left_rounded,
              iconColor: state.snapEnabled ? AppColors.primary : AppColors.textSecondary,
              title: 'Smart Snapping Guides',
              subtitle: 'Snap layers to center and neighbor edges',
              trailing: Switch(
                value: state.snapEnabled,
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                onChanged: (_) {
                  bloc.add(const ToggleSnapEvent());
                  Navigator.pop(ctx);
                },
              ),
              onTap: () {
                bloc.add(const ToggleSnapEvent());
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 6),
            AppSheetActionTile(
              icon: Icons.auto_awesome_rounded,
              iconColor: const Color(0xFFB692F6),
              title: 'Background Studio',
              subtitle: 'Gradients, solid colors & curated palettes',
              trailing: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: state.activePage.backgroundColor,
                  gradient: state.activePage.backgroundGradient,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white30),
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                showBackgroundPickerSheet(
                  context,
                  state.activePage,
                  bloc: bloc,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}



class _PhotoIconPainter extends CustomPainter {
  final Color color;
  const _PhotoIconPainter() : color = Colors.white;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Outer rounded box
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
      const Radius.circular(5.5),
    );
    canvas.drawRRect(rrect, stroke);

    // Sun dot
    canvas.drawCircle(Offset(size.width * 0.32, size.height * 0.32), 1.6, fill);

    // Wave / landscape
    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.72)
      ..cubicTo(
        size.width * 0.38,
        size.height * 0.52,
        size.width * 0.60,
        size.height * 0.85,
        size.width * 0.85,
        size.height * 0.58,
      );
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _PhotoIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _LayersIconPainter extends CustomPainter {
  final Color color;
  const _LayersIconPainter() : color = Colors.white;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Top rhombus
    final topPath = Path()
      ..moveTo(w * 0.5, h * 0.15)
      ..lineTo(w * 0.85, h * 0.40)
      ..lineTo(w * 0.5, h * 0.65)
      ..lineTo(w * 0.15, h * 0.40)
      ..close();
    canvas.drawPath(topPath, stroke);

    // Bottom layer chevron
    final bottomPath = Path()
      ..moveTo(w * 0.18, h * 0.60)
      ..lineTo(w * 0.5, h * 0.85)
      ..lineTo(w * 0.82, h * 0.60);
    canvas.drawPath(bottomPath, stroke);
  }

  @override
  bool shouldRepaint(covariant _LayersIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _DiamondGridPainter extends CustomPainter {
  final Color color;
  const _DiamondGridPainter() : color = Colors.white;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    const boxSize = 5.2;

    void drawRotatedBox(double dx, double dy) {
      canvas.save();
      canvas.translate(cx + dx, cy + dy);
      canvas.rotate(math.pi / 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: boxSize, height: boxSize),
          const Radius.circular(1.5),
        ),
        stroke,
      );
      canvas.restore();
    }

    drawRotatedBox(0, -5.2); // top
    drawRotatedBox(5.2, 0); // right
    drawRotatedBox(0, 5.2); // bottom
    drawRotatedBox(-5.2, 0); // left
  }

  @override
  bool shouldRepaint(covariant _DiamondGridPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _BentoLayoutPainter extends CustomPainter {
  final Color color;
  const _BentoLayoutPainter() : color = Colors.white;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Left tall box
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(1, 1, w * 0.38, h - 2),
        const Radius.circular(3.5),
      ),
      stroke,
    );

    // Right top box
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.48, 1, w * 0.50, (h - 2) * 0.45),
        const Radius.circular(3.0),
      ),
      stroke,
    );

    // Right bottom box
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.48, h * 0.52, w * 0.50, (h - 2) * 0.45),
        const Radius.circular(3.0),
      ),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _BentoLayoutPainter oldDelegate) =>
      oldDelegate.color != color;
}
