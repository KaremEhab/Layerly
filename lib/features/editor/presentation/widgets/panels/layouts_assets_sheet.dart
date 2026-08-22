import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:layerly/core/constants/app_colors.dart';
import 'package:layerly/core/utils/uuid_generator.dart';
import 'package:layerly/features/editor/domain/entities/auto_layout_layer.dart';
import 'package:layerly/features/editor/domain/entities/device_mockup_layer.dart';
import 'package:layerly/features/editor/domain/entities/icon_layer.dart';
import 'package:layerly/features/editor/domain/entities/layer.dart';
import 'package:layerly/features/editor/domain/entities/layer_enums.dart';
import 'package:layerly/features/editor/domain/entities/text_layer.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_bloc.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_event.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_state.dart';

/// Opens the professional Layouts & Assets Studio bottom sheet.
void showLayoutsAssetsSheet(BuildContext context, {EditorBloc? bloc}) {
  final editorBloc = bloc ?? context.read<EditorBloc>();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => BlocProvider.value(
      value: editorBloc,
      child: _LayoutsAssetsModal(bloc: editorBloc),
    ),
  );
}

class BentoLayoutPreset {
  final String name;
  final String category;
  final String description;
  final IconData icon;
  final double width;
  final double height;
  final Layer Function(double canvasWidth, double canvasHeight) createLayer;

  const BentoLayoutPreset({
    required this.name,
    required this.category,
    required this.description,
    required this.icon,
    required this.width,
    required this.height,
    required this.createLayer,
  });
}

class ColorPalettePreset {
  final String name;
  final String mood;
  final List<Color> colors;

  const ColorPalettePreset({
    required this.name,
    required this.mood,
    required this.colors,
  });
}

class TypographyPreset {
  final String name;
  final String sample;
  final String fontFamily;
  final double fontSize;
  final FontWeight fontWeight;
  final Color color;

  const TypographyPreset({
    required this.name,
    required this.sample,
    required this.fontFamily,
    required this.fontSize,
    required this.fontWeight,
    required this.color,
  });
}

// -------------------------------------------------------------
// PRESETS DEFINITIONS
// -------------------------------------------------------------

final List<BentoLayoutPreset> kBentoPresets = [
  // 1. Hero 2-Column Bento Grid
  BentoLayoutPreset(
    name: '2-Column Bento Grid',
    category: 'Grid & Cards',
    description: 'Two balanced feature cards with icons and subtitles',
    icon: Icons.dashboard_customize_rounded,
    width: 600,
    height: 180,
    createLayer: (cw, ch) {
      final card1 = AutoLayoutLayer(
        id: UuidGenerator.generate(),
        name: 'Feature Card A',
        x: 0,
        y: 0,
        width: 290,
        height: 180,
        direction: AutoLayoutDirection.vertical,
        alignment: AutoLayoutAlignment.start,
        distribution: AutoLayoutDistribution.spaceBetween,
        gap: 12.0,
        paddingHorizontal: 20.0,
        paddingVertical: 18.0,
        backgroundColor: const Color(0xFF1E1B2E),
        cornerRadius: 18.0,
        strokeColor: const Color(0xFF352F4E),
        strokeWidth: 1.0,
        children: [
          IconLayer(
            id: UuidGenerator.generate(),
            name: 'Sparkle Icon',
            icon: Icons.auto_awesome_rounded,
            color: const Color(0xFFA78BFA),
            x: 0,
            y: 0,
            width: 26,
            height: 26,
          ),
          TextLayer(
            id: UuidGenerator.generate(),
            name: 'Card Title A',
            content: 'Instant AI Workflow',
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            x: 0,
            y: 0,
            width: 240,
            height: 22,
          ),
          TextLayer(
            id: UuidGenerator.generate(),
            name: 'Card Subtitle A',
            content: 'Generate and iterate on modern mobile slides in seconds.',
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.textMuted,
            x: 0,
            y: 0,
            width: 240,
            height: 34,
          ),
        ],
      );

      final card2 = AutoLayoutLayer(
        id: UuidGenerator.generate(),
        name: 'Metric Card B',
        x: 0,
        y: 0,
        width: 290,
        height: 180,
        direction: AutoLayoutDirection.vertical,
        alignment: AutoLayoutAlignment.start,
        distribution: AutoLayoutDistribution.spaceBetween,
        gap: 12.0,
        paddingHorizontal: 20.0,
        paddingVertical: 18.0,
        backgroundColor: const Color(0xFF162529),
        cornerRadius: 18.0,
        strokeColor: const Color(0xFF1E4647),
        strokeWidth: 1.0,
        children: [
          IconLayer(
            id: UuidGenerator.generate(),
            name: 'Bolt Icon',
            icon: Icons.bolt_rounded,
            color: const Color(0xFF00CEC9),
            x: 0,
            y: 0,
            width: 26,
            height: 26,
          ),
          TextLayer(
            id: UuidGenerator.generate(),
            name: 'Metric Number',
            content: '+240% Speed',
            fontFamily: 'Inter',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF55EFC4),
            x: 0,
            y: 0,
            width: 240,
            height: 28,
          ),
          TextLayer(
            id: UuidGenerator.generate(),
            name: 'Metric Label',
            content: 'Optimized rendering engine with zero lag canvas snapping.',
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.textMuted,
            x: 0,
            y: 0,
            width: 240,
            height: 34,
          ),
        ],
      );

      return AutoLayoutLayer(
        id: UuidGenerator.generate(),
        name: '2-Column Bento Container',
        x: ((cw - 600) / 2).clamp(0.0, cw - 600),
        y: ((ch - 180) / 2).clamp(0.0, ch - 180),
        width: 600,
        height: 180,
        direction: AutoLayoutDirection.horizontal,
        alignment: AutoLayoutAlignment.center,
        distribution: AutoLayoutDistribution.spaceBetween,
        gap: 20.0,
        paddingHorizontal: 0.0,
        paddingVertical: 0.0,
        children: [card1, card2],
      );
    },
  ),

  // 2. 3-Card Stat Row (Horizontal Bento)
  BentoLayoutPreset(
    name: '3-Card Stat Banner',
    category: 'Stats & Metrics',
    description: 'Three equal statistic pills in horizontal row',
    icon: Icons.view_column_rounded,
    width: 600,
    height: 100,
    createLayer: (cw, ch) {
      AutoLayoutLayer makeStatPill(String title, String val, IconData ic, Color acc) {
        return AutoLayoutLayer(
          id: UuidGenerator.generate(),
          name: '$title Pill',
          x: 0,
          y: 0,
          width: 186,
          height: 100,
          direction: AutoLayoutDirection.vertical,
          alignment: AutoLayoutAlignment.start,
          distribution: AutoLayoutDistribution.center,
          gap: 4.0,
          paddingHorizontal: 16.0,
          paddingVertical: 12.0,
          backgroundColor: const Color(0xFF1B1927),
          cornerRadius: 16.0,
          strokeColor: const Color(0xFF2C283F),
          strokeWidth: 1.0,
          children: [
            IconLayer(
              id: UuidGenerator.generate(),
              name: 'Icon',
              icon: ic,
              color: acc,
              x: 0,
              y: 0,
              width: 16,
              height: 16,
            ),
            TextLayer(
              id: UuidGenerator.generate(),
              name: 'Value',
              content: val,
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              x: 0,
              y: 0,
              width: 150,
              height: 22,
            ),
            TextLayer(
              id: UuidGenerator.generate(),
              name: 'Label',
              content: title,
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
              x: 0,
              y: 0,
              width: 150,
              height: 16,
            ),
          ],
        );
      }

      return AutoLayoutLayer(
        id: UuidGenerator.generate(),
        name: '3-Card Stat Row',
        x: ((cw - 600) / 2).clamp(0.0, cw - 600),
        y: ((ch - 100) / 2).clamp(0.0, ch - 100),
        width: 600,
        height: 100,
        direction: AutoLayoutDirection.horizontal,
        alignment: AutoLayoutAlignment.center,
        distribution: AutoLayoutDistribution.spaceBetween,
        gap: 16.0,
        paddingHorizontal: 0.0,
        paddingVertical: 0.0,
        children: [
          makeStatPill('Faster Design', '10x', Icons.speed_rounded, const Color(0xFF8B5CF6)),
          makeStatPill('Accuracy', '99.9%', Icons.verified_rounded, const Color(0xFF00CEC9)),
          makeStatPill('Active Designers', '50k+', Icons.people_alt_rounded, const Color(0xFFFDCB6E)),
        ],
      );
    },
  ),

  // 3. Testimonial / Quote Banner
  BentoLayoutPreset(
    name: 'Quote & Review Card',
    category: 'Grid & Cards',
    description: 'Full width testimonial card with 5-star rating and avatar row',
    icon: Icons.format_quote_rounded,
    width: 500,
    height: 150,
    createLayer: (cw, ch) {
      return AutoLayoutLayer(
        id: UuidGenerator.generate(),
        name: 'Testimonial Card',
        x: ((cw - 500) / 2).clamp(0.0, cw - 500),
        y: ((ch - 150) / 2).clamp(0.0, ch - 150),
        width: 500,
        height: 150,
        direction: AutoLayoutDirection.vertical,
        alignment: AutoLayoutAlignment.start,
        distribution: AutoLayoutDistribution.spaceBetween,
        gap: 10.0,
        paddingHorizontal: 22.0,
        paddingVertical: 18.0,
        backgroundColor: const Color(0xFF1E1B2C),
        cornerRadius: 20.0,
        strokeColor: const Color(0xFF363150),
        strokeWidth: 1.0,
        children: [
          IconLayer(
            id: UuidGenerator.generate(),
            name: 'Stars Rating',
            icon: Icons.star_rounded,
            color: const Color(0xFFFDCB6E),
            x: 0,
            y: 0,
            width: 22,
            height: 22,
          ),
          TextLayer(
            id: UuidGenerator.generate(),
            name: 'Quote Text',
            content: '"Layerly transformed the way our team creates mobile UI presentations."',
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            x: 0,
            y: 0,
            width: 450,
            height: 38,
          ),
          TextLayer(
            id: UuidGenerator.generate(),
            name: 'Author',
            content: 'Alex Rivera • Principal Product Designer',
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: const Color(0xFFA78BFA),
            x: 0,
            y: 0,
            width: 450,
            height: 18,
          ),
        ],
      );
    },
  ),

  // 4. Browser Window Frame Layout
  BentoLayoutPreset(
    name: 'Browser Window Frame',
    category: 'Mockups & Frames',
    description: 'Modern desktop web browser frame with traffic light controls',
    icon: Icons.web_asset_rounded,
    width: 600,
    height: 360,
    createLayer: (cw, ch) {
      return AutoLayoutLayer(
        id: UuidGenerator.generate(),
        name: 'Browser Window Frame',
        x: ((cw - 600) / 2).clamp(0.0, cw - 600),
        y: ((ch - 360) / 2).clamp(0.0, ch - 360),
        width: 600,
        height: 360,
        direction: AutoLayoutDirection.vertical,
        alignment: AutoLayoutAlignment.start,
        distribution: AutoLayoutDistribution.start,
        gap: 0.0,
        paddingHorizontal: 0.0,
        paddingVertical: 0.0,
        backgroundColor: const Color(0xFF181722),
        cornerRadius: 16.0,
        strokeColor: const Color(0xFF302D42),
        strokeWidth: 1.5,
        children: [
          // Browser Header
          AutoLayoutLayer(
            id: UuidGenerator.generate(),
            name: 'Browser Bar',
            x: 0,
            y: 0,
            width: 600,
            height: 42,
            direction: AutoLayoutDirection.horizontal,
            alignment: AutoLayoutAlignment.center,
            distribution: AutoLayoutDistribution.start,
            gap: 12.0,
            paddingHorizontal: 16.0,
            paddingVertical: 8.0,
            backgroundColor: const Color(0xFF222030),
            cornerRadius: 0.0,
            children: [
              IconLayer(
                id: UuidGenerator.generate(),
                name: 'Window Controls',
                icon: Icons.circle,
                color: const Color(0xFFFF5F56),
                x: 0,
                y: 0,
                width: 10,
                height: 10,
              ),
              IconLayer(
                id: UuidGenerator.generate(),
                name: 'Window Controls 2',
                icon: Icons.circle,
                color: const Color(0xFFFFBD2E),
                x: 0,
                y: 0,
                width: 10,
                height: 10,
              ),
              IconLayer(
                id: UuidGenerator.generate(),
                name: 'Window Controls 3',
                icon: Icons.circle,
                color: const Color(0xFF27C93F),
                x: 0,
                y: 0,
                width: 10,
                height: 10,
              ),
              TextLayer(
                id: UuidGenerator.generate(),
                name: 'URL Address',
                content: 'https://layerly.design/studio',
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
                x: 0,
                y: 0,
                width: 250,
                height: 16,
              ),
            ],
          ),
        ],
      );
    },
  ),
];

final List<ColorPalettePreset> kColorPalettes = [
  const ColorPalettePreset(
    name: 'Cyberpunk Violet',
    mood: 'Vibrant & Modern',
    colors: [
      Color(0xFF8B5CF6),
      Color(0xFF6C5CE7),
      Color(0xFF00CEC9),
      Color(0xFFFD79A8),
      Color(0xFF0A0910),
    ],
  ),
  const ColorPalettePreset(
    name: 'Emerald Mint',
    mood: 'Fresh & High Tech',
    colors: [
      Color(0xFF00B894),
      Color(0xFF55EFC4),
      Color(0xFF0984E3),
      Color(0xFF74B9FF),
      Color(0xFF1E272E),
    ],
  ),
  const ColorPalettePreset(
    name: 'Sunset Coral',
    mood: 'Warm & Dynamic',
    colors: [
      Color(0xFFFF7675),
      Color(0xFFFAB1A0),
      Color(0xFFFDCB6E),
      Color(0xFFFFEAA7),
      Color(0xFF2D3436),
    ],
  ),
  const ColorPalettePreset(
    name: 'Minimal Slate',
    mood: 'Clean & Executive',
    colors: [
      Color(0xFF2D3748),
      Color(0xFF4A5568),
      Color(0xFF718096),
      Color(0xFFCBD5E0),
      Color(0xFF0F172A),
    ],
  ),
];

final List<TypographyPreset> kTypographyPresets = [
  const TypographyPreset(
    name: 'Display Hero Title',
    sample: 'Designed for Impact.',
    fontFamily: 'Outfit',
    fontSize: 36,
    fontWeight: FontWeight.w800,
    color: Colors.white,
  ),
  const TypographyPreset(
    name: 'Section Headline',
    sample: 'Interactive Prototype',
    fontFamily: 'Inter',
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  ),
  const TypographyPreset(
    name: 'Body Lead Paragraph',
    sample: 'Experience fluid gestures, auto layout containers, and smart guides in one studio.',
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Color(0xFFB0AEBA),
  ),
  const TypographyPreset(
    name: 'Eyebrow Tag / Pill',
    sample: 'CASE STUDY 2026',
    fontFamily: 'Poppins',
    fontSize: 11,
    fontWeight: FontWeight.w800,
    color: Color(0xFFA78BFA),
  ),
];

// -------------------------------------------------------------
// MODAL IMPLEMENTATION
// -------------------------------------------------------------

class _LayoutsAssetsModal extends StatefulWidget {
  final EditorBloc bloc;

  const _LayoutsAssetsModal({required this.bloc});

  @override
  State<_LayoutsAssetsModal> createState() => _LayoutsAssetsModalState();
}

class _LayoutsAssetsModalState extends State<_LayoutsAssetsModal>
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
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 16),
            height: MediaQuery.of(context).size.height * 0.80,
            decoration: BoxDecoration(
              color: const Color(0xFF131219),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFF2A273C), width: 1.5),
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
                _buildHeader(context),

                // 2. Live Search Bar
                _buildSearchBar(),

              // 3. Navigation Tabs
              _buildTabs(),

              // 4. Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Bento & UI Layouts
                    _buildBentoLayoutsTab(context, state),

                    // Tab 2: Device Mockups & Frames
                    _buildDeviceMockupsTab(context, state),

                    // Tab 3: Design Tokens & Asset Kit
                    _buildAssetKitTab(context, state),
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
      child: Column(
        children: [
          // Drag handle
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
                    colors: [Color(0xFF00B894), Color(0xFF00CEC9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00B894).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.dashboard_customize_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Layouts & Asset Hub',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Bento grids, device mockups, color palettes & typography',
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
          color: const Color(0xFF1D1B28),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _searchQuery.isNotEmpty ? const Color(0xFF00CEC9) : const Color(0xFF2B283D),
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
                  hintText: 'Search layouts, mockups, palettes & typography...',
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

  Widget _buildTabs() {
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
          color: const Color(0xFF00B894),
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        tabs: const [
          Tab(text: '🍱 Bento Grids'),
          Tab(text: '📱 Mockups'),
          Tab(text: '🎨 Design Kit'),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 1: BENTO LAYOUTS
  // -------------------------------------------------------------
  Widget _buildBentoLayoutsTab(BuildContext context, EditorState state) {
    var presets = kBentoPresets;
    if (_searchQuery.isNotEmpty) {
      presets = presets
          .where((p) =>
              p.name.toLowerCase().contains(_searchQuery) ||
              p.category.toLowerCase().contains(_searchQuery) ||
              p.description.toLowerCase().contains(_searchQuery))
          .toList();
    }

    if (presets.isEmpty) {
      return _buildEmptyState('No layouts match your search', 'Try searching for bento, stat, quote, or grid.');
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      physics: const BouncingScrollPhysics(),
      itemCount: presets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, idx) {
        final item = presets[idx];
        return InkWell(
          onTap: () => _insertBentoLayout(context, state, item),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1B1927),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2E2A40)),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B894).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: const Color(0xFF55EFC4), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF262338),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${item.width.toInt()}×${item.height.toInt()}px',
                              style: const TextStyle(color: Color(0xFF55EFC4), fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.description,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B894),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Insert',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
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

  // -------------------------------------------------------------
  // TAB 2: DEVICE MOCKUPS & FRAMES
  // -------------------------------------------------------------
  Widget _buildDeviceMockupsTab(BuildContext context, EditorState state) {
    final mockups = [
      (
        'iPhone 15 Pro Portrait',
        'Titanium Dark frame mockup for mobile screens',
        Icons.phone_iphone_rounded,
        MockupDevice.iphone,
        380.0,
        780.0,
      ),
      (
        'MacBook Pro Landscape',
        'Laptop frame mockup for responsive web presentations',
        Icons.laptop_chromebook_rounded,
        MockupDevice.macbook,
        640.0,
        420.0,
      ),
      (
        'Android Flagship Portrait',
        'Modern Android device frame with edge display',
        Icons.phone_android_rounded,
        MockupDevice.android,
        380.0,
        780.0,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      physics: const BouncingScrollPhysics(),
      children: [
        ...mockups.map((m) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                Navigator.pop(context);
                final activePage = state.activePage;
                final insX = ((activePage.width - m.$5) / 2).clamp(0.0, activePage.width - m.$5);
                final insY = ((activePage.height - m.$6) / 2).clamp(0.0, activePage.height - m.$6);

                final mockupLayer = DeviceMockupLayer(
                  id: UuidGenerator.generate(),
                  name: m.$1,
                  device: m.$4,
                  x: insX,
                  y: insY,
                  width: m.$5,
                  height: m.$6,
                );
                widget.bloc.add(AddLayerEvent(mockupLayer));
                _showSuccessToast(context, '📱 Inserted ${m.$1}');
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1927),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2E2A40)),
                ),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(m.$3, color: const Color(0xFFA78BFA), size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.$1,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            m.$2,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C5CE7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Insert',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 3: DESIGN TOKENS & ASSET KIT
  // -------------------------------------------------------------
  Widget _buildAssetKitTab(BuildContext context, EditorState state) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      physics: const BouncingScrollPhysics(),
      children: [
        // 1. Color Palettes
        const Text(
          '🎨 Curated Color Palettes (Tap swatch to apply)',
          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...kColorPalettes.map((pal) => _buildColorPaletteCard(context, state, pal)),

        const SizedBox(height: 16),

        // 2. Typography Kits
        const Text(
          '🔤 Typography Presets (Tap to insert)',
          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...kTypographyPresets.map((t) => _buildTypographyCard(context, state, t)),
      ],
    );
  }

  Widget _buildColorPaletteCard(BuildContext context, EditorState state, ColorPalettePreset palette) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1927),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2C283F)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                palette.name,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Text(
                palette.mood,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: palette.colors.map((c) {
              final hexCode = '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
              return Expanded(
                child: InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: hexCode));
                    // Also apply to background if selected
                    widget.bloc.add(UpdatePageBackgroundEvent(
                      type: BackgroundType.solid,
                      color: c,
                    ));
                    _showSuccessToast(context, '🎨 Applied $hexCode to Canvas & Copied');
                  },
                  child: Container(
                    height: 38,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTypographyCard(BuildContext context, EditorState state, TypographyPreset typo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1927),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2C283F)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        title: Text(
          typo.sample,
          style: TextStyle(
            color: typo.color,
            fontSize: typo.fontSize > 20 ? 18 : typo.fontSize,
            fontWeight: typo.fontWeight,
            fontFamily: typo.fontFamily,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${typo.name} • ${typo.fontFamily} ${typo.fontSize.toInt()}px',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
        trailing: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF00CEC9), size: 20),
        onTap: () {
          Navigator.pop(context);
          final activePage = state.activePage;
          final txtLayer = TextLayer(
            id: UuidGenerator.generate(),
            name: typo.name,
            content: typo.sample,
            fontFamily: typo.fontFamily,
            fontSize: typo.fontSize,
            fontWeight: typo.fontWeight,
            color: typo.color,
            x: ((activePage.width - 320) / 2).clamp(0.0, activePage.width - 320),
            y: ((activePage.height - 60) / 2).clamp(0.0, activePage.height - 60),
            width: 320,
            height: typo.fontSize * 1.5,
          );
          widget.bloc.add(AddLayerEvent(txtLayer));
          _showSuccessToast(context, '🔤 Inserted ${typo.name}');
        },
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

  void _insertBentoLayout(BuildContext context, EditorState state, BentoLayoutPreset preset) {
    Navigator.pop(context);

    final activePage = state.activePage;
    final layer = preset.createLayer(activePage.width, activePage.height);
    widget.bloc.add(AddLayerEvent(layer));

    _showSuccessToast(context, '🍱 Inserted ${preset.name}');
  }

  void _showSuccessToast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF00B894),
      ),
    );
  }
}
