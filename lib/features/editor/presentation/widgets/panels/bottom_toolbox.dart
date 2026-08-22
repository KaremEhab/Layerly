import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:layerly/core/constants/app_colors.dart';
import 'package:layerly/core/utils/uuid_generator.dart';
import 'package:layerly/features/editor/domain/entities/layer_enums.dart';
import 'package:layerly/features/editor/domain/entities/text_layer.dart';
import 'package:layerly/features/editor/domain/entities/shape_layer.dart';
import 'package:layerly/features/editor/domain/entities/device_mockup_layer.dart';
import 'package:layerly/features/editor/domain/entities/icon_layer.dart';
import 'package:layerly/features/editor/domain/entities/component_instance_layer.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_bloc.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_event.dart';
import 'package:layerly/features/editor/presentation/widgets/panels/layers_panel.dart';
import 'package:layerly/core/widgets/more_rings_icon.dart';
import 'package:layerly/features/editor/presentation/widgets/panels/background_picker_sheet.dart';

class BottomToolbox extends StatelessWidget {
  const BottomToolbox({super.key});

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
                // 1. Shapes with Dropdown Caret
                Tooltip(
                  message: 'Shapes',
                  child: InkWell(
                    onTap: () => _showShapesSheet(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 19,
                            height: 19,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5.0),
                              border: Border.all(
                                color: Colors.white,
                                width: 1.8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
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
                  onTap: () => _showTextSheet(context),
                ),

                // 3. Images & Mockups
                _buildToolButton(
                  customWidget: const CustomPaint(
                    size: Size(20, 20),
                    painter: _PhotoIconPainter(),
                  ),
                  tooltip: 'Images & Mockups',
                  onTap: () => _showImagesSheet(context),
                ),

                // 4. Layers
                _buildToolButton(
                  customWidget: const CustomPaint(
                    size: Size(20, 20),
                    painter: _LayersIconPainter(),
                  ),
                  tooltip: 'Layers',
                  onTap: () => _showLayersSheet(context),
                ),

                // 5. Components / Elements
                _buildToolButton(
                  customWidget: const CustomPaint(
                    size: Size(20, 20),
                    painter: _DiamondGridPainter(),
                  ),
                  tooltip: 'Components',
                  onTap: () => _showComponentsSheet(context),
                ),

                // 6. Bento Layouts / Templates
                _buildToolButton(
                  customWidget: const CustomPaint(
                    size: Size(20, 20),
                    painter: _BentoLayoutPainter(),
                  ),
                  tooltip: 'Layouts & Assets',
                  onTap: () => _showAssetsSheet(context),
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
                  onTap: () => _showMoreSheet(context),
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

  void _showShapesSheet(BuildContext context) {
    final bloc = context.read<EditorBloc>();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Insert Shape',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInsertItem(
                    ctx,
                    Icons.rectangle_outlined,
                    'Rectangle',
                    () {
                      bloc.add(
                        AddLayerEvent(
                          ShapeLayer(
                            id: UuidGenerator.generate(),
                            name: 'Rectangle',
                            shapeType: ShapeType.rectangle,
                            x: 200,
                            y: 200,
                            width: 240,
                            height: 160,
                            fill: AppColors.surfaceSecondary,
                            cornerRadius: 12,
                            strokeColor: AppColors.border,
                            strokeWidth: 1.5,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildInsertItem(ctx, Icons.circle_outlined, 'Circle', () {
                    bloc.add(
                      AddLayerEvent(
                        ShapeLayer(
                          id: UuidGenerator.generate(),
                          name: 'Circle',
                          shapeType: ShapeType.circle,
                          x: 200,
                          y: 200,
                          width: 180,
                          height: 180,
                          fill: AppColors.primary,
                        ),
                      ),
                    );
                  }),
                  _buildInsertItem(
                    ctx,
                    Icons.change_history_rounded,
                    'Triangle',
                    () {
                      bloc.add(
                        AddLayerEvent(
                          ShapeLayer(
                            id: UuidGenerator.generate(),
                            name: 'Triangle',
                            shapeType: ShapeType.triangle,
                            x: 200,
                            y: 200,
                            width: 180,
                            height: 180,
                            fill: AppColors.primaryLight,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildInsertItem(
                    ctx,
                    Icons.horizontal_rule_rounded,
                    'Line',
                    () {
                      bloc.add(
                        AddLayerEvent(
                          ShapeLayer(
                            id: UuidGenerator.generate(),
                            name: 'Line Divider',
                            shapeType: ShapeType.line,
                            x: 200,
                            y: 200,
                            width: 200,
                            height: 4,
                            fill: AppColors.primary,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTextSheet(BuildContext context) {
    final bloc = context.read<EditorBloc>();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Text',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Text(
                  'H1',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                title: const Text(
                  'Heading',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
              ListTile(
                leading: const Text(
                  'H2',
                  style: TextStyle(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                title: const Text(
                  'Subheading',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
              ListTile(
                leading: const Text(
                  'P',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                title: const Text(
                  'Body Text',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
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
      ),
    );
  }

  void _showImagesSheet(BuildContext context) {
    final bloc = context.read<EditorBloc>();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Device Mockup / Image',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(
                  Icons.phone_iphone_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
                title: const Text(
                  'iPhone Device Frame',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Clean mobile frame mockup',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  bloc.add(
                    AddLayerEvent(
                      DeviceMockupLayer(
                        id: UuidGenerator.generate(),
                        name: 'iPhone Mockup',
                        x: 200,
                        y: 100,
                        width: 440,
                        height: 880,
                        device: MockupDevice.iphone,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
                title: const Text(
                  'Checklist Icon',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  bloc.add(
                    AddLayerEvent(
                      IconLayer(
                        id: UuidGenerator.generate(),
                        name: 'Icon Check',
                        x: 100,
                        y: 200,
                        width: 40,
                        height: 40,
                        icon: Icons.check_circle_outline_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLayersSheet(BuildContext context) {
    final bloc = context.read<EditorBloc>();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => BlocProvider.value(
        value: bloc,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: const LayersPanel(),
        ),
      ),
    );
  }

  void _showComponentsSheet(BuildContext context) {
    final bloc = context.read<EditorBloc>();
    final state = bloc.state;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Insert Reusable Component',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (state.project.components.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No components saved yet. Select layers to create components.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                )
              else
                ...state.project.components.map(
                  (comp) => ListTile(
                    leading: const Icon(
                      Icons.widgets_rounded,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      comp.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      '${comp.layers.length} internal layers',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      bloc.add(
                        AddLayerEvent(
                          ComponentInstanceLayer(
                            id: UuidGenerator.generate(),
                            name: comp.name,
                            componentDefinitionId: comp.id,
                            x: 80,
                            y: 800,
                            width: comp.width,
                            height: comp.height,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAssetsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Project Assets & Kit',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _AssetCategoryCard(
                    icon: Icons.palette_outlined,
                    title: 'Colors',
                  ),
                  _AssetCategoryCard(
                    icon: Icons.font_download_outlined,
                    title: 'Typography',
                  ),
                  _AssetCategoryCard(
                    icon: Icons.interests_outlined,
                    title: 'Icons',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoreSheet(BuildContext context) {
    final bloc = context.read<EditorBloc>();
    final state = bloc.state;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'More Settings & Tools',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            SwitchListTile(
              secondary: const Icon(
                Icons.grid_on_rounded,
                color: AppColors.text,
              ),
              title: const Text(
                'Show Grid',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              value: state.showGrid,
              activeColor: AppColors.primary,
              onChanged: (_) {
                bloc.add(const ToggleGridEvent());
                Navigator.pop(ctx);
              },
            ),
            SwitchListTile(
              secondary: const Icon(
                Icons.align_horizontal_left_rounded,
                color: AppColors.text,
              ),
              title: const Text(
                'Smart Snapping Guides',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              value: state.snapEnabled,
              activeColor: AppColors.primary,
              onChanged: (_) {
                bloc.add(const ToggleSnapEvent());
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFFB692F6),
              ),
              title: const Text(
                'Background Studio',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Gradients, solid colors & palettes',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
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
                showBackgroundPickerSheet(context, state.activePage, bloc: bloc);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsertItem(
    BuildContext ctx,
    IconData icon,
    String label,
    VoidCallback onInsert,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(ctx);
        onInsert();
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetCategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;

  const _AssetCategoryCard({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoIconPainter extends CustomPainter {
  final Color color;
  const _PhotoIconPainter({this.color = Colors.white});

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
  const _LayersIconPainter({this.color = Colors.white});

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
  const _DiamondGridPainter({this.color = Colors.white});

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
  const _BentoLayoutPainter({this.color = Colors.white});

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
