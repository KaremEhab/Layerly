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
import 'package:layerly/features/editor/presentation/bloc/editor_state.dart';

enum ToolRailTab {
  text,
  shapes,
  mockups,
  icons,
  components,
  background,
}

class LeftToolRail extends StatefulWidget {
  const LeftToolRail({super.key});

  @override
  State<LeftToolRail> createState() => _LeftToolRailState();
}

class _LeftToolRailState extends State<LeftToolRail> {
  ToolRailTab? _activeTab;

  void _toggleTab(ToolRailTab tab) {
    setState(() {
      if (_activeTab == tab) {
        _activeTab = null;
      } else {
        _activeTab = tab;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Main Narrow Icon Rail
        Container(
          width: 56,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              right: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              _buildRailItem(ToolRailTab.text, Icons.title_rounded, 'Text'),
              _buildRailItem(ToolRailTab.shapes, Icons.interests_outlined, 'Shapes'),
              _buildRailItem(ToolRailTab.mockups, Icons.phone_iphone_rounded, 'Mockups'),
              _buildRailItem(ToolRailTab.icons, Icons.emoji_symbols_rounded, 'Icons'),
              _buildRailItem(ToolRailTab.components, Icons.widgets_rounded, 'Components'),
              const Divider(color: AppColors.border, indent: 10, endIndent: 10),
              _buildRailItem(ToolRailTab.background, Icons.palette_outlined, 'Background'),
              const Spacer(),
            ],
          ),
        ),

        // Expanding Side Drawer with Tool Content
        if (_activeTab != null)
          Container(
            width: 250,
            decoration: const BoxDecoration(
              color: AppColors.surfaceSecondary,
              border: Border(
                right: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drawer Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getTabTitle(_activeTab!),
                        style: const TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        color: AppColors.textMuted,
                        onPressed: () => setState(() => _activeTab = null),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.border, height: 1),

                // Drawer Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(14),
                    child: _buildDrawerContent(_activeTab!),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildRailItem(ToolRailTab tab, IconData icon, String label) {
    final isSelected = _activeTab == tab;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: () => _toggleTab(tab),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.surfaceElevated : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: AppColors.primary, width: 1.5)
                  : null,
            ),
            child: Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  String _getTabTitle(ToolRailTab tab) {
    switch (tab) {
      case ToolRailTab.text:
        return 'Add Typography';
      case ToolRailTab.shapes:
        return 'Insert Shapes';
      case ToolRailTab.mockups:
        return 'Device Mockups';
      case ToolRailTab.icons:
        return 'Vector Icons';
      case ToolRailTab.components:
        return 'Reusable Components';
      case ToolRailTab.background:
        return 'Canvas Background';
    }
  }

  Widget _buildDrawerContent(ToolRailTab tab) {
    switch (tab) {
      case ToolRailTab.text:
        return _buildTextTools();
      case ToolRailTab.shapes:
        return _buildShapesTools();
      case ToolRailTab.mockups:
        return _buildMockupsTools();
      case ToolRailTab.icons:
        return _buildIconsTools();
      case ToolRailTab.components:
        return _buildComponentsTools();
      case ToolRailTab.background:
        return _buildBackgroundTools();
    }
  }

  Widget _buildTextTools() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildActionCard(
          title: 'Add Big Heading',
          subtitle: 'Outfit Bold 48px',
          onTap: () {
            final id = UuidGenerator.generate();
            context.read<EditorBloc>().add(AddLayerEvent(
                  TextLayer(
                    id: id,
                    name: 'Heading',
                    x: 80,
                    y: 120,
                    width: 500,
                    height: 80,
                    content: 'I redesigned Uber Eats screen.',
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                  ),
                ));
          },
        ),
        const SizedBox(height: 10),
        _buildActionCard(
          title: 'Add Subtitle / Body',
          subtitle: 'Inter Regular 20px',
          onTap: () {
            final id = UuidGenerator.generate();
            context.read<EditorBloc>().add(AddLayerEvent(
                  TextLayer(
                    id: id,
                    name: 'Description',
                    x: 80,
                    y: 220,
                    width: 440,
                    height: 60,
                    content: 'Clearer hierarchy, easier choices and better UX flow.',
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                  ),
                ));
          },
        ),
        const SizedBox(height: 10),
        _buildActionCard(
          title: 'Category Label Pill',
          subtitle: 'Uppercase purple badge',
          onTap: () {
            final id = UuidGenerator.generate();
            context.read<EditorBloc>().add(AddLayerEvent(
                  TextLayer(
                    id: id,
                    name: 'Category Pill',
                    x: 80,
                    y: 70,
                    width: 140,
                    height: 32,
                    content: 'REDESIGN',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Inter',
                    color: AppColors.primary,
                    letterSpacing: 1.5,
                  ),
                ));
          },
        ),
      ],
    );
  }

  Widget _buildShapesTools() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildActionCard(
          title: 'Rounded Card Container',
          subtitle: 'Fill: Surface Dark, Radius: 16',
          onTap: () {
            final id = UuidGenerator.generate();
            context.read<EditorBloc>().add(AddLayerEvent(
                  ShapeLayer(
                    id: id,
                    name: 'Card Background',
                    x: 80,
                    y: 100,
                    width: 400,
                    height: 250,
                    fill: const Color(0xFF15161B),
                    cornerRadius: 16,
                    strokeColor: const Color(0xFF2B2D35),
                    strokeWidth: 1.5,
                  ),
                ));
          },
        ),
        const SizedBox(height: 10),
        _buildActionCard(
          title: 'Accent Divider Line',
          subtitle: 'Purple 3px line',
          onTap: () {
            final id = UuidGenerator.generate();
            context.read<EditorBloc>().add(AddLayerEvent(
                  ShapeLayer(
                    id: id,
                    name: 'Divider Line',
                    shapeType: ShapeType.line,
                    x: 80,
                    y: 350,
                    width: 80,
                    height: 4,
                    fill: AppColors.primary,
                    cornerRadius: 2,
                  ),
                ));
          },
        ),
        const SizedBox(height: 10),
        _buildActionCard(
          title: 'Circle Glow Accent',
          subtitle: 'Gradient sphere',
          onTap: () {
            final id = UuidGenerator.generate();
            context.read<EditorBloc>().add(AddLayerEvent(
                  ShapeLayer(
                    id: id,
                    name: 'Gradient Circle',
                    shapeType: ShapeType.circle,
                    x: 300,
                    y: 200,
                    width: 180,
                    height: 180,
                    gradient: const RadialGradient(
                      colors: [AppColors.primary, Colors.transparent],
                    ),
                  ),
                ));
          },
        ),
      ],
    );
  }

  Widget _buildMockupsTools() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildActionCard(
          title: 'iPhone Device Mockup',
          subtitle: 'Interactive UI screen container',
          onTap: () {
            final id = UuidGenerator.generate();
            context.read<EditorBloc>().add(AddLayerEvent(
                  DeviceMockupLayer(
                    id: id,
                    name: 'Mobile Mockup',
                    x: 540,
                    y: 70,
                    width: 460,
                    height: 880,
                    device: MockupDevice.iphone,
                    cornerRadius: 44,
                  ),
                ));
          },
        ),
      ],
    );
  }

  Widget _buildIconsTools() {
    final icons = [
      Icons.check_circle_rounded,
      Icons.arrow_forward_rounded,
      Icons.star_rounded,
      Icons.bookmark_rounded,
      Icons.auto_awesome,
      Icons.lightbulb_outline_rounded,
      Icons.favorite_rounded,
      Icons.trending_up_rounded,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: icons.map((icon) {
        return InkWell(
          onTap: () {
            final id = UuidGenerator.generate();
            context.read<EditorBloc>().add(AddLayerEvent(
                  IconLayer(
                    id: id,
                    name: 'Icon',
                    icon: icon,
                    x: 100,
                    y: 400,
                    width: 48,
                    height: 48,
                    color: AppColors.primary,
                  ),
                ));
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildComponentsTools() {
    return BlocBuilder<EditorBloc, EditorState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Synced Components',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...state.project.components.map((component) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _buildActionCard(
                  title: component.name,
                  subtitle: component.description,
                  onTap: () {
                    final id = UuidGenerator.generate();
                    context.read<EditorBloc>().add(AddLayerEvent(
                          ComponentInstanceLayer(
                            id: id,
                            name: component.name,
                            componentDefinitionId: component.id,
                            x: 80,
                            y: 880,
                            width: component.width,
                            height: component.height,
                          ),
                        ));
                  },
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildBackgroundTools() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildActionCard(
          title: 'Purple Cosmic Glow',
          subtitle: 'Deep radial background',
          onTap: () {
            context.read<EditorBloc>().add(
                  const UpdatePageBackgroundEvent(
                    type: BackgroundType.gradient,
                    gradient: RadialGradient(
                      center: Alignment(0.4, -0.6),
                      radius: 1.2,
                      colors: [
                        Color(0xFF2C194D),
                        Color(0xFF13141B),
                        Color(0xFF090A0D),
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                  ),
                );
          },
        ),
        const SizedBox(height: 10),
        _buildActionCard(
          title: 'Minimal Pitch Black',
          subtitle: 'Pure studio dark',
          onTap: () {
            context.read<EditorBloc>().add(
                  const UpdatePageBackgroundEvent(
                    type: BackgroundType.solid,
                    color: Color(0xFF090A0D),
                  ),
                );
          },
        ),
        const SizedBox(height: 10),
        _buildActionCard(
          title: 'Cyan Horizon Glow',
          subtitle: 'Teal gradient background',
          onTap: () {
            context.read<EditorBloc>().add(
                  const UpdatePageBackgroundEvent(
                    type: BackgroundType.gradient,
                    gradient: RadialGradient(
                      center: Alignment(-0.3, -0.5),
                      radius: 1.1,
                      colors: [
                        Color(0xFF0C2B38),
                        Color(0xFF0F141C),
                        Color(0xFF090A0D),
                      ],
                    ),
                  ),
                );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
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
    );
  }
}
