import 'package:flutter/material.dart';
import 'package:layerly/core/constants/app_colors.dart';
import 'package:layerly/core/constants/responsive_breakpoints.dart';
import 'package:layerly/features/editor/presentation/widgets/canvas/editor_canvas.dart';
import 'package:layerly/features/editor/presentation/widgets/canvas/fullscreen_canvas_view.dart';
import 'package:layerly/features/editor/presentation/widgets/panels/layerly_app_bar.dart';
import 'package:layerly/features/editor/presentation/widgets/panels/page_header_bar.dart';
import 'package:layerly/features/editor/presentation/widgets/panels/page_strip.dart';
import 'package:layerly/features/editor/presentation/widgets/panels/properties_panel.dart';
import 'package:layerly/features/editor/presentation/widgets/panels/contextual_action_bar.dart';
import 'package:layerly/features/editor/presentation/widgets/panels/bottom_toolbox.dart';
import 'package:layerly/features/editor/presentation/widgets/panels/left_tool_rail.dart';
import 'package:layerly/features/editor/presentation/widgets/panels/layers_panel.dart';

class ResponsiveEditorLayout extends StatefulWidget {
  const ResponsiveEditorLayout({super.key});

  @override
  State<ResponsiveEditorLayout> createState() => _ResponsiveEditorLayoutState();
}

class _ResponsiveEditorLayoutState extends State<ResponsiveEditorLayout> {
  bool _isFullscreen = false;
  int _rightPanelTabIndex = 0; // 0 = Properties, 1 = Layers

  @override
  Widget build(BuildContext context) {
    if (_isFullscreen) {
      return FullscreenCanvasView(
        onExitFullscreen: () => setState(() => _isFullscreen = false),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= ResponsiveBreakpoints.desktopMin) {
          return _buildDesktopLayout();
        } else if (constraints.maxWidth >= ResponsiveBreakpoints.tabletMin) {
          return _buildTabletLayout();
        } else {
          return _buildMobileLayout();
        }
      },
    );
  }

  // 1. Mobile Layout (< 768px) matching exact screenshots
  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            const LayerlyAppBar(),

            // Page Header (Cover Screen + Fullscreen + More)
            PageHeaderBar(
              onToggleFullscreen: () => setState(() => _isFullscreen = true),
            ),

            // Canvas Workspace
            const Expanded(
              child: EditorCanvas(),
            ),

            // Slide Strip (+ Add Slide, 01, 02, 03...)
            const PageStrip(),

            const SizedBox(height: 4),

            // Contextual Inspector (Changes depending on selection)
            const PropertiesPanel(),

            const SizedBox(height: 4),

            // Contextual Action Bar (Undo, Redo, Duplicate, Visibility, Lock, Layout, Delete)
            const ContextualActionBar(),

            // Bottom Toolbox (Shapes, Text, Images, Layers, Components, Assets, More)
            const BottomToolbox(),
          ],
        ),
      ),
    );
  }

  // 2. Tablet Layout (768 - 1199px)
  Widget _buildTabletLayout() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const LayerlyAppBar(),
            PageHeaderBar(
              onToggleFullscreen: () => setState(() => _isFullscreen = true),
            ),
            Expanded(
              child: Row(
                children: [
                  const LeftToolRail(),
                  const Expanded(
                    child: EditorCanvas(),
                  ),
                  Container(
                    width: 310,
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
            const ContextualActionBar(),
          ],
        ),
      ),
    );
  }

  // 3. Desktop Pro Editor Layout (≥ 1200px)
  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Pro Top Navigation & Actions Bar
          const LayerlyAppBar(),

          // Main Studio Body
          Expanded(
            child: Row(
              children: [
                // Left Tool Rail with expanding drawers
                const LeftToolRail(),

                // Center Infinite Canvas
                const Expanded(
                  child: EditorCanvas(),
                ),

                // Right Contextual Inspector & Layers Sidebar
                Container(
                  width: 310,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      left: BorderSide(color: AppColors.border, width: 1),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Tab Switcher (Properties vs Layers)
                      Container(
                        height: 44,
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: AppColors.border, width: 1),
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildSidebarTab('Inspector', Icons.tune_rounded, 0),
                            _buildSidebarTab('Layers', Icons.layers_outlined, 1),
                          ],
                        ),
                      ),

                      // Active Tab Content
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
