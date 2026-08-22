import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:layerly/core/constants/app_colors.dart';
import 'package:layerly/core/utils/uuid_generator.dart';
import 'package:layerly/features/editor/domain/entities/auto_layout_layer.dart';
import 'package:layerly/features/editor/domain/entities/component_definition.dart';
import 'package:layerly/features/editor/domain/entities/component_instance_layer.dart';
import 'package:layerly/features/editor/domain/entities/icon_layer.dart';
import 'package:layerly/features/editor/domain/entities/image_layer.dart';
import 'package:layerly/features/editor/domain/entities/layer.dart';
import 'package:layerly/features/editor/domain/entities/layer_enums.dart';
import 'package:layerly/features/editor/domain/entities/text_layer.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_bloc.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_event.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_state.dart';

/// Opens the professional Component Studio bottom sheet.
void showComponentsPickerSheet(BuildContext context, {EditorBloc? bloc}) {
  final editorBloc = bloc ?? context.read<EditorBloc>();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => BlocProvider.value(
      value: editorBloc,
      child: _ComponentsPickerModal(bloc: editorBloc),
    ),
  );
}

class PresetComponentItem {
  final String id;
  final String name;
  final String category;
  final String description;
  final IconData icon;
  final double width;
  final double height;
  final List<Layer> Function() createLayers;

  const PresetComponentItem({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.icon,
    required this.width,
    required this.height,
    required this.createLayers,
  });
}

final List<PresetComponentItem> kPresetComponents = [
  // 1. Profile / Author Footer
  PresetComponentItem(
    id: 'preset-comp-author-footer',
    name: 'Profile Footer',
    category: 'Branding & Nav',
    description: 'Author branding with infinity icon and handle',
    icon: Icons.all_inclusive_rounded,
    width: 250,
    height: 42,
    createLayers: () => [
      AutoLayoutLayer(
        id: UuidGenerator.generate(),
        name: 'Profile Footer Layout',
        x: 0,
        y: 0,
        width: 250,
        height: 42,
        direction: AutoLayoutDirection.horizontal,
        alignment: AutoLayoutAlignment.center,
        distribution: AutoLayoutDistribution.start,
        gap: 8.0,
        paddingHorizontal: 12.0,
        paddingVertical: 6.0,
        backgroundColor: const Color(0xFF1E1633).withValues(alpha: 0.8),
        cornerRadius: 21.0,
        strokeColor: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
        strokeWidth: 1.0,
        children: [
          ImageLayer(
            id: UuidGenerator.generate(),
            name: 'Brand Logo',
            assetPath: 'assets/images/Kareem-Ehab-Logo.svg',
            tintColor: Colors.white,
            fit: BoxFit.contain,
            borderRadius: 0,
            x: 0,
            y: 0,
            width: 20,
            height: 20,
          ),
          TextLayer(
            id: UuidGenerator.generate(),
            name: 'Author Name',
            content: 'kareem.designs',
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            x: 0,
            y: 0,
            width: 140,
            height: 20,
          ),
        ],
      ),
    ],
  ),

  // 2. Primary CTA Button
  PresetComponentItem(
    id: 'preset-comp-primary-cta',
    name: 'Primary CTA Button',
    category: 'Buttons & Badges',
    description: 'Sleek gradient action button with sparkle icon',
    icon: Icons.touch_app_rounded,
    width: 200,
    height: 48,
    createLayers: () => [
      AutoLayoutLayer(
        id: UuidGenerator.generate(),
        name: 'CTA Button Container',
        x: 0,
        y: 0,
        width: 200,
        height: 48,
        direction: AutoLayoutDirection.horizontal,
        alignment: AutoLayoutAlignment.center,
        distribution: AutoLayoutDistribution.center,
        gap: 8.0,
        paddingHorizontal: 18.0,
        paddingVertical: 10.0,
        backgroundColor: const Color(0xFF6C5CE7),
        cornerRadius: 24.0,
        strokeColor: const Color(0xFFA29BFE),
        strokeWidth: 1.0,
        children: [
          IconLayer(
            id: UuidGenerator.generate(),
            name: 'Sparkle Icon',
            icon: Icons.auto_awesome_rounded,
            color: Colors.white,
            x: 0,
            y: 0,
            width: 18,
            height: 18,
          ),
          TextLayer(
            id: UuidGenerator.generate(),
            name: 'Button Label',
            content: 'Get Started',
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            x: 0,
            y: 0,
            width: 100,
            height: 20,
          ),
        ],
      ),
    ],
  ),

  // 3. Feature Benefit Pill
  PresetComponentItem(
    id: 'preset-comp-feature-pill',
    name: 'Feature Benefit Row',
    category: 'Cards & Widgets',
    description: 'Auto layout benefit row with checkmark indicator',
    icon: Icons.check_circle_rounded,
    width: 240,
    height: 40,
    createLayers: () => [
      AutoLayoutLayer(
        id: UuidGenerator.generate(),
        name: 'Benefit Row',
        x: 0,
        y: 0,
        width: 240,
        height: 40,
        direction: AutoLayoutDirection.horizontal,
        alignment: AutoLayoutAlignment.center,
        distribution: AutoLayoutDistribution.start,
        gap: 10.0,
        paddingHorizontal: 12.0,
        paddingVertical: 8.0,
        backgroundColor: const Color(0xFF1B1A28).withValues(alpha: 0.6),
        cornerRadius: 12.0,
        strokeColor: const Color(0xFF2E2B44),
        strokeWidth: 1.0,
        children: [
          IconLayer(
            id: UuidGenerator.generate(),
            name: 'Checkmark Icon',
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF00CEC9),
            x: 0,
            y: 0,
            width: 18,
            height: 18,
          ),
          TextLayer(
            id: UuidGenerator.generate(),
            name: 'Benefit Text',
            content: 'Clearer hierarchy',
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            x: 0,
            y: 0,
            width: 150,
            height: 20,
          ),
        ],
      ),
    ],
  ),

  // 4. Metric Growth Badge
  PresetComponentItem(
    id: 'preset-comp-metric-badge',
    name: 'Metric Growth Pill',
    category: 'Buttons & Badges',
    description: 'Compact statistic pill with accent bolt indicator',
    icon: Icons.bolt_rounded,
    width: 180,
    height: 38,
    createLayers: () => [
      AutoLayoutLayer(
        id: UuidGenerator.generate(),
        name: 'Metric Badge',
        x: 0,
        y: 0,
        width: 180,
        height: 38,
        direction: AutoLayoutDirection.horizontal,
        alignment: AutoLayoutAlignment.center,
        distribution: AutoLayoutDistribution.center,
        gap: 6.0,
        paddingHorizontal: 14.0,
        paddingVertical: 6.0,
        backgroundColor: const Color(0xFF102A27),
        cornerRadius: 19.0,
        strokeColor: const Color(0xFF00B894).withValues(alpha: 0.5),
        strokeWidth: 1.0,
        children: [
          IconLayer(
            id: UuidGenerator.generate(),
            name: 'Bolt Icon',
            icon: Icons.bolt_rounded,
            color: const Color(0xFF00CEC9),
            x: 0,
            y: 0,
            width: 16,
            height: 16,
          ),
          TextLayer(
            id: UuidGenerator.generate(),
            name: 'Metric Value',
            content: '+142% Better UX',
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF55EFC4),
            x: 0,
            y: 0,
            width: 120,
            height: 18,
          ),
        ],
      ),
    ],
  ),

  // 5. Category Tag Pill
  PresetComponentItem(
    id: 'preset-comp-tag-pill',
    name: 'Category Tag',
    category: 'Buttons & Badges',
    description: 'Subtle neon category pill for slide labels',
    icon: Icons.label_important_rounded,
    width: 130,
    height: 32,
    createLayers: () => [
      AutoLayoutLayer(
        id: UuidGenerator.generate(),
        name: 'Tag Container',
        x: 0,
        y: 0,
        width: 130,
        height: 32,
        direction: AutoLayoutDirection.horizontal,
        alignment: AutoLayoutAlignment.center,
        distribution: AutoLayoutDistribution.center,
        gap: 6.0,
        paddingHorizontal: 10.0,
        paddingVertical: 4.0,
        backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
        cornerRadius: 8.0,
        strokeColor: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
        strokeWidth: 1.0,
        children: [
          TextLayer(
            id: UuidGenerator.generate(),
            name: 'Tag Text',
            content: 'REDESIGN',
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: const Color(0xFFA78BFA),
            x: 0,
            y: 0,
            width: 90,
            height: 16,
          ),
        ],
      ),
    ],
  ),

  // 6. Notification Toast Banner
  PresetComponentItem(
    id: 'preset-comp-toast-banner',
    name: 'Notification Banner',
    category: 'Cards & Widgets',
    description: 'Glassmorphic banner with bell icon and action hint',
    icon: Icons.notifications_active_rounded,
    width: 280,
    height: 48,
    createLayers: () => [
      AutoLayoutLayer(
        id: UuidGenerator.generate(),
        name: 'Toast Container',
        x: 0,
        y: 0,
        width: 280,
        height: 48,
        direction: AutoLayoutDirection.horizontal,
        alignment: AutoLayoutAlignment.center,
        distribution: AutoLayoutDistribution.spaceBetween,
        gap: 8.0,
        paddingHorizontal: 14.0,
        paddingVertical: 8.0,
        backgroundColor: const Color(0xFF221F33),
        cornerRadius: 14.0,
        strokeColor: const Color(0xFF383353),
        strokeWidth: 1.2,
        children: [
          IconLayer(
            id: UuidGenerator.generate(),
            name: 'Bell Icon',
            icon: Icons.notifications_active_rounded,
            color: const Color(0xFFFDCB6E),
            x: 0,
            y: 0,
            width: 18,
            height: 18,
          ),
          TextLayer(
            id: UuidGenerator.generate(),
            name: 'Message',
            content: 'Ride on your schedule',
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            x: 0,
            y: 0,
            width: 180,
            height: 20,
          ),
          IconLayer(
            id: UuidGenerator.generate(),
            name: 'Arrow Icon',
            icon: Icons.arrow_forward_ios_rounded,
            color: Colors.white54,
            x: 0,
            y: 0,
            width: 12,
            height: 12,
          ),
        ],
      ),
    ],
  ),
];

class _ComponentsPickerModal extends StatefulWidget {
  final EditorBloc bloc;

  const _ComponentsPickerModal({required this.bloc});

  @override
  State<_ComponentsPickerModal> createState() => _ComponentsPickerModalState();
}

class _ComponentsPickerModalState extends State<_ComponentsPickerModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditorBloc, EditorState>(
      bloc: widget.bloc,
      builder: (context, state) {
        final projectComponents = state.project.components;
        final selectedLayers = state.selectedLayers;

        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 16),
            height: MediaQuery.of(context).size.height * 0.78,
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
                // 1. Drag Handle & Header
                _buildHeader(context, selectedLayers),

              // 2. Search Box
              _buildSearchBar(),

              // 3. Navigation Tabs
              _buildTabs(projectComponents.length),

              // 4. Quick Selection Create Banner
              if (selectedLayers.isNotEmpty)
                _buildCreateFromSelectionBanner(context, selectedLayers),

              // 5. Main Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: All Components
                    _buildComponentsGrid(
                      context,
                      state,
                      _getAllFilteredComponents(projectComponents),
                      emptyTitle: 'No components found',
                      emptySubtitle: 'Try adjusting your search or create a new component from canvas layers.',
                    ),

                    // Tab 2: Design System Presets
                    _buildPresetsGrid(context, state),

                    // Tab 3: My Project Components
                    _buildProjectComponentsGrid(context, state, projectComponents),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  Widget _buildHeader(BuildContext context, List<Layer> selectedLayers) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
      child: Column(
        children: [
          // Drag Handle
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
                  Icons.widgets_rounded,
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
                      'Component Studio',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Reusable design system elements & UI blocks',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => Navigator.pop(context),
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
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1C28),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _searchQuery.isNotEmpty ? const Color(0xFF8B5CF6) : const Color(0xFF2E2C3D),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Search reusable components...',
                  hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              InkWell(
                onTap: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                child: const Icon(Icons.clear_rounded, color: Colors.white70, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs(int customCount) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1925),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2838)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF6C5CE7),
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        tabs: [
          const Tab(text: '✨ All Library'),
          const Tab(text: '🎨 Presets'),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('❖ My Project'),
                if (customCount > 0) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$customCount',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateFromSelectionBanner(BuildContext context, List<Layer> selectedLayers) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6C5CE7).withValues(alpha: 0.22),
            const Color(0xFF8B5CF6).withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_fix_high_rounded, color: Color(0xFFA78BFA), size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${selectedLayers.length} layer${selectedLayers.length > 1 ? 's' : ''} selected',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Save selection as a reusable component',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _promptCreateComponentDialog(context, selectedLayers),
            icon: const Icon(Icons.add_rounded, size: 14),
            label: const Text('Create'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  List<dynamic> _getAllFilteredComponents(List<ComponentDefinition> projectComponents) {
    final List<dynamic> combined = [...projectComponents, ...kPresetComponents];
    if (_searchQuery.isEmpty) return combined;

    return combined.where((item) {
      if (item is ComponentDefinition) {
        return item.name.toLowerCase().contains(_searchQuery);
      } else if (item is PresetComponentItem) {
        return item.name.toLowerCase().contains(_searchQuery) ||
            item.category.toLowerCase().contains(_searchQuery) ||
            item.description.toLowerCase().contains(_searchQuery);
      }
      return false;
    }).toList();
  }

  Widget _buildComponentsGrid(
    BuildContext context,
    EditorState state,
    List<dynamic> items, {
    required String emptyTitle,
    required String emptySubtitle,
  }) {
    if (items.isEmpty) {
      return _buildEmptyState(emptyTitle, emptySubtitle);
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.15,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, idx) {
        final item = items[idx];
        if (item is ComponentDefinition) {
          return _buildCustomComponentCard(context, state, item);
        } else {
          return _buildPresetComponentCard(context, state, item as PresetComponentItem);
        }
      },
    );
  }

  Widget _buildPresetsGrid(BuildContext context, EditorState state) {
    var presets = kPresetComponents;
    if (_searchQuery.isNotEmpty) {
      presets = presets
          .where((p) =>
              p.name.toLowerCase().contains(_searchQuery) ||
              p.category.toLowerCase().contains(_searchQuery) ||
              p.description.toLowerCase().contains(_searchQuery))
          .toList();
    }

    if (presets.isEmpty) {
      return _buildEmptyState('No presets match your search', 'Try searching for button, badge, banner or card.');
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.15,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: presets.length,
      itemBuilder: (ctx, idx) => _buildPresetComponentCard(context, state, presets[idx]),
    );
  }

  Widget _buildProjectComponentsGrid(
    BuildContext context,
    EditorState state,
    List<ComponentDefinition> projectComponents,
  ) {
    var comps = projectComponents;
    if (_searchQuery.isNotEmpty) {
      comps = comps.where((c) => c.name.toLowerCase().contains(_searchQuery)).toList();
    }

    if (comps.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1C2B),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF2E2C40)),
                ),
                child: const Icon(Icons.widgets_outlined, size: 36, color: Color(0xFFA78BFA)),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Custom Components Yet',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Select any layer or Auto Layout on your canvas and tap "Create Component" to build your reusable design library.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.15,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: comps.length,
      itemBuilder: (ctx, idx) => _buildCustomComponentCard(context, state, comps[idx]),
    );
  }

  Widget _buildPresetComponentCard(
    BuildContext context,
    EditorState state,
    PresetComponentItem preset,
  ) {
    return InkWell(
      onTap: () => _insertPresetComponent(context, state, preset),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1B1926),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2E2B3E)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Icon + Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(preset.icon, color: const Color(0xFFA78BFA), size: 16),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF262335),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text(
                    '${preset.width.toInt()}×${preset.height.toInt()}',
                    style: const TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),

            // Title & Description
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  preset.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  preset.category,
                  style: const TextStyle(color: Color(0xFF8B5CF6), fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ],
            ),

            // Insert Button Pill
            Container(
              height: 26,
              decoration: BoxDecoration(
                color: const Color(0xFF262338),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: const Color(0xFF383350)),
              ),
              alignment: Alignment.center,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 13),
                  SizedBox(width: 4),
                  Text(
                    'Insert',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomComponentCard(
    BuildContext context,
    EditorState state,
    ComponentDefinition comp,
  ) {
    return InkWell(
      onTap: () => _insertComponentDefinition(context, state, comp),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1B1926),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.35)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Purple Diamond Badge + Delete Option
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('❖', style: TextStyle(color: Color(0xFFA78BFA), fontSize: 10, fontWeight: FontWeight.bold)),
                      SizedBox(width: 3),
                      Text(
                        'CUSTOM',
                        style: TextStyle(color: Color(0xFFA78BFA), fontSize: 9, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => _confirmDeleteComponent(context, comp),
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.all(2.0),
                    child: Icon(Icons.delete_outline_rounded, color: Colors.white38, size: 15),
                  ),
                ),
              ],
            ),

            // Title & Layer count
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comp.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${comp.layers.length} internal layer${comp.layers.length > 1 ? 's' : ''} • ${comp.width.toInt()}×${comp.height.toInt()}px',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                ),
              ],
            ),

            // Insert Button
            Container(
              height: 26,
              decoration: BoxDecoration(
                color: const Color(0xFF6C5CE7),
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 13),
                  SizedBox(width: 4),
                  Text(
                    'Insert to Canvas',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 36, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _insertPresetComponent(BuildContext context, EditorState state, PresetComponentItem preset) {
    Navigator.pop(context);

    // 1. Ensure ComponentDefinition is registered in the project
    final existingDef = state.project.components.where((c) => c.id == preset.id);
    if (existingDef.isEmpty) {
      final newDef = ComponentDefinition(
        id: preset.id,
        name: preset.name,
        description: preset.description,
        width: preset.width,
        height: preset.height,
        layers: preset.createLayers(),
      );
      widget.bloc.add(RegisterComponentDefinitionEvent(newDef));
    }

    // 2. Insert ComponentInstanceLayer at centered position
    final activePage = state.activePage;
    final insertX = ((activePage.width - preset.width) / 2).clamp(0.0, activePage.width - preset.width);
    final insertY = ((activePage.height - preset.height) / 2).clamp(0.0, activePage.height - preset.height);

    final instance = ComponentInstanceLayer(
      id: UuidGenerator.generate(),
      name: preset.name,
      componentDefinitionId: preset.id,
      x: insertX,
      y: insertY,
      width: preset.width,
      height: preset.height,
    );

    widget.bloc.add(AddLayerEvent(instance));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❖ Inserted ${preset.name}'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF6C5CE7),
      ),
    );
  }

  void _insertComponentDefinition(BuildContext context, EditorState state, ComponentDefinition comp) {
    Navigator.pop(context);

    final activePage = state.activePage;
    final insertX = ((activePage.width - comp.width) / 2).clamp(0.0, activePage.width - comp.width);
    final insertY = ((activePage.height - comp.height) / 2).clamp(0.0, activePage.height - comp.height);

    final instance = ComponentInstanceLayer(
      id: UuidGenerator.generate(),
      name: comp.name,
      componentDefinitionId: comp.id,
      x: insertX,
      y: insertY,
      width: comp.width,
      height: comp.height,
    );

    widget.bloc.add(AddLayerEvent(instance));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❖ Inserted ${comp.name}'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF6C5CE7),
      ),
    );
  }

  void _promptCreateComponentDialog(BuildContext context, List<Layer> selectedLayers) {
    final controller = TextEditingController(
      text: selectedLayers.length == 1 ? selectedLayers.first.name : 'Custom Component',
    );

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.widgets_rounded, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text('Create Component', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Component Name:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceSecondary,
                hintText: 'e.g. Header Nav Bar',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final compName = controller.text.trim().isNotEmpty ? controller.text.trim() : 'Custom Component';
              Navigator.pop(dialogCtx);

              // Calculate bounding box
              final minX = selectedLayers.map((l) => l.x).reduce(math.min);
              final minY = selectedLayers.map((l) => l.y).reduce(math.min);
              final maxX = selectedLayers.map((l) => l.x + l.width).reduce(math.max);
              final maxY = selectedLayers.map((l) => l.y + l.height).reduce(math.max);

              final normalizedLayers = selectedLayers
                  .map((l) => l.copyWithTransform(x: l.x - minX, y: l.y - minY))
                  .toList();

              final newDef = ComponentDefinition(
                id: UuidGenerator.generate(),
                name: compName,
                description: 'Custom reusable component',
                width: math.max(20.0, maxX - minX),
                height: math.max(20.0, maxY - minY),
                layers: normalizedLayers,
              );

              widget.bloc.add(RegisterComponentDefinitionEvent(newDef));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❖ Registered "$compName" in design system!'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: const Color(0xFF6C5CE7),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Create Component'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteComponent(BuildContext context, ComponentDefinition comp) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Component?', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to remove "${comp.name}" from your component library?',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              widget.bloc.add(DeleteComponentDefinitionEvent(comp.id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5C5C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
