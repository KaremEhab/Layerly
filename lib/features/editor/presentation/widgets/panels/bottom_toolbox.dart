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

class BottomToolbox extends StatelessWidget {
  const BottomToolbox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Shapes
          _buildToolButton(
            icon: Icons.crop_square_rounded,
            tooltip: 'Shapes',
            onTap: () => _showShapesSheet(context),
          ),

          // Text
          _buildToolButton(
            icon: Icons.title_rounded,
            tooltip: 'Text',
            onTap: () => _showTextSheet(context),
          ),

          // Images & Mockups
          _buildToolButton(
            icon: Icons.image_outlined,
            tooltip: 'Images & Mockups',
            onTap: () => _showImagesSheet(context),
          ),

          // Layers
          _buildToolButton(
            icon: Icons.layers_outlined,
            tooltip: 'Layers',
            onTap: () => _showLayersSheet(context),
          ),

          // Components
          _buildToolButton(
            icon: Icons.widgets_outlined,
            tooltip: 'Components',
            onTap: () => _showComponentsSheet(context),
          ),

          // Assets
          _buildToolButton(
            icon: Icons.grid_view_rounded,
            tooltip: 'Assets',
            onTap: () => _showAssetsSheet(context),
          ),

          // More
          _buildToolButton(
            icon: Icons.more_horiz_rounded,
            tooltip: 'More options',
            onTap: () => _showMoreSheet(context),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          child: Icon(icon, color: AppColors.textSecondary, size: 20),
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
              const Text('Insert Shape', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInsertItem(ctx, Icons.rectangle_outlined, 'Rectangle', () {
                    bloc.add(AddLayerEvent(ShapeLayer(
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
                    )));
                  }),
                  _buildInsertItem(ctx, Icons.circle_outlined, 'Circle', () {
                    bloc.add(AddLayerEvent(ShapeLayer(
                      id: UuidGenerator.generate(),
                      name: 'Circle',
                      shapeType: ShapeType.circle,
                      x: 200,
                      y: 200,
                      width: 180,
                      height: 180,
                      fill: AppColors.primary,
                    )));
                  }),
                  _buildInsertItem(ctx, Icons.change_history_rounded, 'Triangle', () {
                    bloc.add(AddLayerEvent(ShapeLayer(
                      id: UuidGenerator.generate(),
                      name: 'Triangle',
                      shapeType: ShapeType.triangle,
                      x: 200,
                      y: 200,
                      width: 180,
                      height: 180,
                      fill: AppColors.primaryLight,
                    )));
                  }),
                  _buildInsertItem(ctx, Icons.horizontal_rule_rounded, 'Line', () {
                    bloc.add(AddLayerEvent(ShapeLayer(
                      id: UuidGenerator.generate(),
                      name: 'Line Divider',
                      shapeType: ShapeType.line,
                      x: 200,
                      y: 200,
                      width: 200,
                      height: 4,
                      fill: AppColors.primary,
                    )));
                  }),
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
              const Text('Add Text', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Text('H1', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18)),
                title: const Text('Heading', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  bloc.add(AddLayerEvent(TextLayer(
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
                  )));
                },
              ),
              ListTile(
                leading: const Text('H2', style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 16)),
                title: const Text('Subheading', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  bloc.add(AddLayerEvent(TextLayer(
                    id: UuidGenerator.generate(),
                    name: 'Subheading',
                    x: 100,
                    y: 200,
                    width: 440,
                    height: 50,
                    content: 'Subheading description',
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  )));
                },
              ),
              ListTile(
                leading: const Text('P', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 14)),
                title: const Text('Body Text', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  bloc.add(AddLayerEvent(TextLayer(
                    id: UuidGenerator.generate(),
                    name: 'Body',
                    x: 100,
                    y: 200,
                    width: 400,
                    height: 60,
                    content: 'Add your clean paragraph content here.',
                    fontSize: 16,
                  )));
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
              const Text('Add Device Mockup / Image', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.phone_iphone_rounded, color: AppColors.primary, size: 24),
                title: const Text('iPhone Device Frame', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Clean mobile frame mockup', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  bloc.add(AddLayerEvent(DeviceMockupLayer(
                    id: UuidGenerator.generate(),
                    name: 'iPhone Mockup',
                    x: 200,
                    y: 100,
                    width: 440,
                    height: 880,
                    device: MockupDevice.iphone,
                  )));
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle_outline_rounded, color: AppColors.primary, size: 24),
                title: const Text('Checklist Icon', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  bloc.add(AddLayerEvent(IconLayer(
                    id: UuidGenerator.generate(),
                    name: 'Icon Check',
                    x: 100,
                    y: 200,
                    width: 40,
                    height: 40,
                    icon: Icons.check_circle_outline_rounded,
                    color: AppColors.primary,
                  )));
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
              const Text('Insert Reusable Component', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (state.project.components.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('No components saved yet. Select layers to create components.', style: TextStyle(color: AppColors.textMuted)),
                )
              else
                ...state.project.components.map((comp) => ListTile(
                      leading: const Icon(Icons.widgets_rounded, color: AppColors.primary),
                      title: Text(comp.name, style: const TextStyle(color: Colors.white)),
                      subtitle: Text('${comp.layers.length} internal layers', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      onTap: () {
                        Navigator.pop(ctx);
                        bloc.add(AddLayerEvent(ComponentInstanceLayer(
                          id: UuidGenerator.generate(),
                          name: comp.name,
                          componentDefinitionId: comp.id,
                          x: 80,
                          y: 800,
                          width: comp.width,
                          height: comp.height,
                        )));
                      },
                    )),
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
              Text('Project Assets & Kit', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _AssetCategoryCard(icon: Icons.palette_outlined, title: 'Colors'),
                  _AssetCategoryCard(icon: Icons.font_download_outlined, title: 'Typography'),
                  _AssetCategoryCard(icon: Icons.interests_outlined, title: 'Icons'),
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
              child: Text('More Settings & Tools', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.grid_on_rounded, color: AppColors.text),
              title: const Text('Show Grid', style: TextStyle(color: Colors.white, fontSize: 14)),
              value: state.showGrid,
              activeColor: AppColors.primary,
              onChanged: (_) {
                bloc.add(const ToggleGridEvent());
                Navigator.pop(ctx);
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.align_horizontal_left_rounded, color: AppColors.text),
              title: const Text('Smart Snapping Guides', style: TextStyle(color: Colors.white, fontSize: 14)),
              value: state.snapEnabled,
              activeColor: AppColors.primary,
              onChanged: (_) {
                bloc.add(const ToggleSnapEvent());
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsertItem(BuildContext ctx, IconData icon, String label, VoidCallback onInsert) {
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
            Text(label, style: const TextStyle(color: AppColors.text, fontSize: 11, fontWeight: FontWeight.w500)),
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
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
