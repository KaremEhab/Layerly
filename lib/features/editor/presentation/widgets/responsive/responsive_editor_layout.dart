import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:layerly/core/constants/app_colors.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_bloc.dart';
import 'package:layerly/features/editor/presentation/widgets/canvas/editor_canvas.dart';
import 'package:layerly/features/editor/presentation/widgets/panels/top_toolbar.dart';
import 'package:layerly/features/editor/presentation/widgets/panels/left_tool_rail.dart';
import 'package:layerly/features/editor/presentation/widgets/panels/properties_panel.dart';
import 'package:layerly/features/editor/presentation/widgets/panels/layers_panel.dart';
import 'package:layerly/features/editor/presentation/widgets/panels/page_strip.dart';

class ResponsiveEditorLayout extends StatefulWidget {
  const ResponsiveEditorLayout({super.key});

  @override
  State<ResponsiveEditorLayout> createState() => _ResponsiveEditorLayoutState();
}

class _ResponsiveEditorLayoutState extends State<ResponsiveEditorLayout> {
  int _rightPanelTabIndex = 0; // 0 = Properties, 1 = Layers

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          return _buildDesktopLayout();
        } else if (constraints.maxWidth > 600) {
          return _buildTabletLayout();
        } else {
          return _buildMobileLayout();
        }
      },
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Top Navigation & Actions Bar
          const TopToolbar(),

          // Main Studio Body
          Expanded(
            child: Row(
              children: [
                // Left Tool Rail with expanding drawers
                const LeftToolRail(),

                // Center Interactive Canvas
                const Expanded(
                  child: EditorCanvas(),
                ),

                // Right Inspector & Layers Sidebar
                Container(
                  width: 290,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      left: BorderSide(color: AppColors.border, width: 1),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Right Panel Tab Switcher (Properties vs Layers)
                      Container(
                        height: 42,
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: AppColors.border, width: 1),
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildSidebarTab('Properties', Icons.tune_rounded, 0),
                            _buildSidebarTab('Layers', Icons.layers_outlined, 1),
                          ],
                        ),
                      ),

                      // Active Tab View
                      Expanded(
                        child: _rightPanelTabIndex == 0
                            ? const PropertiesPanel()
                            : const LayersPanel(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Slide Carousel
          const PageStrip(),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const TopToolbar(),
          Expanded(
            child: Row(
              children: [
                const LeftToolRail(),
                const Expanded(child: EditorCanvas()),
                // Collapsible right inspector
                Container(
                  width: 250,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      left: BorderSide(color: AppColors.border, width: 1),
                    ),
                  ),
                  child: const PropertiesPanel(),
                ),
              ],
            ),
          ),
          const PageStrip(),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const TopToolbar(),
          const Expanded(child: EditorCanvas()),
          const PageStrip(),
          // Mobile Bottom Action Toolbar
          Container(
            height: 52,
            color: AppColors.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.add_box_outlined, color: AppColors.primary),
                  onPressed: () => _showMobileBottomSheet(context, const LeftToolRail()),
                ),
                IconButton(
                  icon: const Icon(Icons.tune_rounded, color: AppColors.text),
                  onPressed: () => _showMobileBottomSheet(context, const PropertiesPanel()),
                ),
                IconButton(
                  icon: const Icon(Icons.layers_outlined, color: AppColors.text),
                  onPressed: () => _showMobileBottomSheet(context, const LayersPanel()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMobileBottomSheet(BuildContext context, Widget content) {
    final bloc = context.read<EditorBloc>();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (ctx) => BlocProvider.value(
        value: bloc,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.65,
          child: content,
        ),
      ),
    );
  }

  Widget _buildSidebarTab(String title, IconData icon, int index) {
    final isSelected = _rightPanelTabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _rightPanelTabIndex = index),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? AppColors.text : AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
