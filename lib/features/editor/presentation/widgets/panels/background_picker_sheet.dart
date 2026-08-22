import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:layerly/core/constants/app_colors.dart';
import 'package:layerly/core/widgets/hex_color_picker_widget.dart';
import 'package:layerly/features/editor/domain/entities/canvas_page.dart';
import 'package:layerly/features/editor/domain/entities/layer_enums.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_bloc.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_event.dart';

class BackgroundPreset {
  final String name;
  final String category;
  final BackgroundType type;
  final Color? color;
  final Gradient? gradient;

  const BackgroundPreset({
    required this.name,
    required this.category,
    required this.type,
    this.color,
    this.gradient,
  });
}

const List<BackgroundPreset> kGradientPresets = [
  // 1. Studio Darks & Glows
  BackgroundPreset(
    name: 'Cosmic Violet',
    category: 'Studio Glow',
    type: BackgroundType.gradient,
    gradient: RadialGradient(
      center: Alignment(0.4, -0.6),
      radius: 1.2,
      colors: [Color(0xFF2C194D), Color(0xFF13141B), Color(0xFF0D0B14)],
      stops: [0.0, 0.5, 1.0],
    ),
  ),
  BackgroundPreset(
    name: 'Midnight Obsidian',
    category: 'Studio Glow',
    type: BackgroundType.gradient,
    gradient: RadialGradient(
      center: Alignment(0.0, -0.8),
      radius: 1.3,
      colors: [Color(0xFF252830), Color(0xFF141518), Color(0xFF090A0D)],
    ),
  ),
  BackgroundPreset(
    name: 'Teal Horizon',
    category: 'Studio Glow',
    type: BackgroundType.gradient,
    gradient: RadialGradient(
      center: Alignment(-0.3, -0.5),
      radius: 1.1,
      colors: [Color(0xFF0C2B38), Color(0xFF0F141C), Color(0xFF090A0D)],
    ),
  ),
  BackgroundPreset(
    name: 'Rose Gold Bloom',
    category: 'Studio Glow',
    type: BackgroundType.gradient,
    gradient: RadialGradient(
      center: Alignment(0.5, -0.5),
      radius: 1.2,
      colors: [Color(0xFF4A192C), Color(0xFF201018), Color(0xFF0F0A0E)],
    ),
  ),
  BackgroundPreset(
    name: 'Dark Sapphire',
    category: 'Studio Glow',
    type: BackgroundType.gradient,
    gradient: RadialGradient(
      center: Alignment(0.2, -0.4),
      radius: 1.2,
      colors: [Color(0xFF1A2A6C), Color(0xFF0F172A), Color(0xFF080C14)],
    ),
  ),
  BackgroundPreset(
    name: 'Emerald Shadow',
    category: 'Studio Glow',
    type: BackgroundType.gradient,
    gradient: RadialGradient(
      center: Alignment(-0.4, -0.6),
      radius: 1.2,
      colors: [Color(0xFF0E382B), Color(0xFF101B17), Color(0xFF080D0B)],
    ),
  ),

  // 2. Vibrant & Neon
  BackgroundPreset(
    name: 'Cyberpunk Neon',
    category: 'Vibrant',
    type: BackgroundType.gradient,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF8A2387), Color(0xFFE94057), Color(0xFFF27121)],
    ),
  ),
  BackgroundPreset(
    name: 'Aurora Borealis',
    category: 'Vibrant',
    type: BackgroundType.gradient,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0052D4), Color(0xFF4364F7), Color(0xFF6FB1FC)],
    ),
  ),
  BackgroundPreset(
    name: 'Ultraviolet',
    category: 'Vibrant',
    type: BackgroundType.gradient,
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF654EA3), Color(0xFFEAAFC8)],
    ),
  ),
  BackgroundPreset(
    name: 'Sunset Flame',
    category: 'Vibrant',
    type: BackgroundType.gradient,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFF512F), Color(0xFFDD2476)],
    ),
  ),
  BackgroundPreset(
    name: 'Emerald Matrix',
    category: 'Vibrant',
    type: BackgroundType.gradient,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0BA360), Color(0xFF3CBA92)],
    ),
  ),
  BackgroundPreset(
    name: 'Golden Amber',
    category: 'Vibrant',
    type: BackgroundType.gradient,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFF8008), Color(0xFFFFC837)],
    ),
  ),
  BackgroundPreset(
    name: 'Deep Indigo',
    category: 'Vibrant',
    type: BackgroundType.gradient,
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
    ),
  ),
  BackgroundPreset(
    name: 'Neon Lime',
    category: 'Vibrant',
    type: BackgroundType.gradient,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
    ),
  ),
  BackgroundPreset(
    name: 'Flamingo Magic',
    category: 'Vibrant',
    type: BackgroundType.gradient,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF59C173), Color(0xFFA17FE0), Color(0xFF5D26C1)],
    ),
  ),

  // 3. Clean & Pastel Lights
  BackgroundPreset(
    name: 'Lavender Mist',
    category: 'Pastel Light',
    type: BackgroundType.gradient,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE0C3FC), Color(0xFF8EC5FC)],
    ),
  ),
  BackgroundPreset(
    name: 'Warm Coral',
    category: 'Pastel Light',
    type: BackgroundType.gradient,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFF9A8B), Color(0xFFFF6A88), Color(0xFFFF99AC)],
    ),
  ),
  BackgroundPreset(
    name: 'Nordic Frost',
    category: 'Pastel Light',
    type: BackgroundType.gradient,
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFE6E9F0), Color(0xFFEEF1F5)],
    ),
  ),
  BackgroundPreset(
    name: 'Mint Glow',
    category: 'Pastel Light',
    type: BackgroundType.gradient,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF84FAB0), Color(0xFF8FD3F4)],
    ),
  ),
];

const Map<String, List<Color>> kSolidPalettes = {
  'Studio Dark': [
    Color(0xFF000000),
    Color(0xFF090A0D),
    Color(0xFF0D0B14),
    Color(0xFF13141B),
    Color(0xFF181820),
    Color(0xFF1F1F2B),
    Color(0xFF272738),
    Color(0xFF323246),
  ],
  'Modern Vibrants': [
    Color(0xFF6C5CE7),
    Color(0xFF0D99FF),
    Color(0xFF00CEC9),
    Color(0xFF2ED573),
    Color(0xFFFFA502),
    Color(0xFFFF4757),
    Color(0xFFFF6B81),
    Color(0xFFA55EEA),
  ],
  'Clean & Light': [
    Color(0xFFFFFFFF),
    Color(0xFFF8F9FA),
    Color(0xFFF1F2F6),
    Color(0xFFE4E7EB),
    Color(0xFFCED6E0),
    Color(0xFFDFE4EA),
    Color(0xFFF5F6FA),
    Color(0xFFE0E0E0),
  ],
  'Earth & Neutral': [
    Color(0xFF2C3E50),
    Color(0xFF34495E),
    Color(0xFF16A085),
    Color(0xFF27AE60),
    Color(0xFF2980B9),
    Color(0xFF8E44AD),
    Color(0xFFD35400),
    Color(0xFFC0392B),
  ],
};

void showBackgroundPickerSheet(BuildContext context, CanvasPage activePage, {EditorBloc? bloc}) {
  final editorBloc = bloc ?? context.read<EditorBloc>();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => BlocProvider.value(
      value: editorBloc,
      child: _BackgroundPickerModal(activePage: activePage, bloc: editorBloc),
    ),
  );
}

class _BackgroundPickerModal extends StatefulWidget {
  final CanvasPage activePage;
  final EditorBloc bloc;

  const _BackgroundPickerModal({
    required this.activePage,
    required this.bloc,
  });

  @override
  State<_BackgroundPickerModal> createState() => _BackgroundPickerModalState();
}

class _BackgroundPickerModalState extends State<_BackgroundPickerModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late BackgroundType _currentType;
  Color? _currentColor;
  Gradient? _currentGradient;

  // Custom Gradient Builder State
  Color _gradColor1 = const Color(0xFF6C5CE7);
  Color _gradColor2 = const Color(0xFF0D99FF);
  Alignment _gradBegin = Alignment.topLeft;
  Alignment _gradEnd = Alignment.bottomRight;
  bool _isCustomRadial = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentType = widget.activePage.backgroundType;
    _currentColor = widget.activePage.backgroundColor;
    _currentGradient = widget.activePage.backgroundGradient;

    if (_currentType == BackgroundType.gradient && _currentGradient is LinearGradient) {
      final lin = _currentGradient as LinearGradient;
      if (lin.colors.length >= 2) {
        _gradColor1 = lin.colors.first;
        _gradColor2 = lin.colors.last;
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _applyBackground({
    required BackgroundType type,
    Color? color,
    Gradient? gradient,
  }) {
    setState(() {
      _currentType = type;
      _currentColor = color;
      _currentGradient = gradient;
    });

    widget.bloc.add(
      UpdatePageBackgroundEvent(
        type: type,
        color: color,
        gradient: gradient,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
        maxWidth: 640,
      ),
      margin: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: bottomInset > 0 ? bottomInset : 16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF16151E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 36,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle & Header
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9E77F6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFFB692F6),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Background Studio',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Gradients, solid colors, and custom palettes',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Quick Transparent / No Fill Button
                    InkWell(
                      onTap: () {
                        _applyBackground(
                          type: BackgroundType.transparent,
                          color: Colors.transparent,
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _currentType == BackgroundType.transparent
                              ? const Color(0xFF9E77F6).withValues(alpha: 0.25)
                              : const Color(0xFF24222E),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _currentType == BackgroundType.transparent
                                ? const Color(0xFF9E77F6)
                                : Colors.white12,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.block_rounded, size: 13, color: Colors.white70),
                            SizedBox(width: 5),
                            Text(
                              'Transparent',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tabs Switcher Pill
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Container(
              height: 40,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFF22202C),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xFF9E77F6),
                  borderRadius: BorderRadius.circular(9),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                tabs: const [
                  Tab(text: '✨ Gradients'),
                  Tab(text: '🎨 Solid'),
                  Tab(text: '⚙️ Custom'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Tab Content
          Flexible(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGradientsTab(),
                _buildSolidsTab(),
                _buildCustomTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 1. Gradients Tab
  Widget _buildGradientsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        for (final category in ['Studio Glow', 'Vibrant', 'Pastel Light']) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Text(
              category.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF9E77F6),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: kGradientPresets.where((p) => p.category == category).length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.4,
            ),
            itemBuilder: (ctx, idx) {
              final preset = kGradientPresets.where((p) => p.category == category).elementAt(idx);
              final isSelected = _currentType == BackgroundType.gradient &&
                  _currentGradient == preset.gradient;

              return InkWell(
                onTap: () {
                  _applyBackground(
                    type: BackgroundType.gradient,
                    gradient: preset.gradient,
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: preset.gradient,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF9E77F6) : Colors.white.withValues(alpha: 0.15),
                      width: isSelected ? 2.5 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF9E77F6).withValues(alpha: 0.4),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              const Icon(Icons.check_circle_rounded, color: Color(0xFF9E77F6), size: 10),
                              const SizedBox(width: 3),
                            ],
                            Flexible(
                              child: Text(
                                preset.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  // 2. Solids Tab
  Widget _buildSolidsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        for (final entry in kSolidPalettes.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Text(
              entry.key.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF9E77F6),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: entry.value.map((color) {
              final isSelected = _currentType == BackgroundType.solid && _currentColor == color;
              final hexString = '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

              return InkWell(
                onTap: () {
                  _applyBackground(
                    type: BackgroundType.solid,
                    color: color,
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 68,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF9E77F6) : Colors.white.withValues(alpha: 0.15),
                      width: isSelected ? 2.5 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF9E77F6).withValues(alpha: 0.4),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.bottomCenter,
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      hexString,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  // 3. Custom Tab (Custom Solid Hex & Custom Gradient Builder)
  Widget _buildCustomTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section 1: Custom Solid Color
          const Text(
            'CUSTOM SOLID COLOR',
            style: TextStyle(
              color: Color(0xFF9E77F6),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          HexColorPickerWidget(
            initialColor: _currentColor ?? const Color(0xFF0D0B14),
            pickerAreaHeightPercent: 0.48,
            onColorChanged: (newColor) {
              _applyBackground(
                type: BackgroundType.solid,
                color: newColor,
              );
            },
          ),
          const SizedBox(height: 24),

          // Section 2: Custom Gradient Creator
          const Text(
            'CUSTOM 2-COLOR GRADIENT CREATOR',
            style: TextStyle(
              color: Color(0xFF9E77F6),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),

          // Gradient Live Preview Card
          Container(
            height: 90,
            decoration: BoxDecoration(
              gradient: _isCustomRadial
                  ? RadialGradient(
                      center: Alignment.center,
                      radius: 1.0,
                      colors: [_gradColor1, _gradColor2],
                    )
                  : LinearGradient(
                      begin: _gradBegin,
                      end: _gradEnd,
                      colors: [_gradColor1, _gradColor2],
                    ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: _gradColor1.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _isCustomRadial ? 'Radial Flow' : 'Linear Flow',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    final grad = _isCustomRadial
                        ? RadialGradient(
                            center: Alignment.center,
                            radius: 1.0,
                            colors: [_gradColor1, _gradColor2],
                          )
                        : LinearGradient(
                            begin: _gradBegin,
                            end: _gradEnd,
                            colors: [_gradColor1, _gradColor2],
                          );
                    _applyBackground(
                      type: BackgroundType.gradient,
                      gradient: grad,
                    );
                  },
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Apply Canvas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Colors.white30),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Color 1 & Color 2 Swatches Row
          Row(
            children: [
              Expanded(
                child: _buildGradientColorTile('Start Color', _gradColor1, (c) {
                  setState(() => _gradColor1 = c);
                  _applyCustomGradient();
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGradientColorTile('End Color', _gradColor2, (c) {
                  setState(() => _gradColor2 = c);
                  _applyCustomGradient();
                }),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Direction Pills
          const Text(
            'Direction',
            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDirectionPill('↘ Diagonal', !_isCustomRadial && _gradBegin == Alignment.topLeft, () {
                  setState(() {
                    _isCustomRadial = false;
                    _gradBegin = Alignment.topLeft;
                    _gradEnd = Alignment.bottomRight;
                  });
                  _applyCustomGradient();
                }),
                const SizedBox(width: 6),
                _buildDirectionPill('↓ Top-Down', !_isCustomRadial && _gradBegin == Alignment.topCenter, () {
                  setState(() {
                    _isCustomRadial = false;
                    _gradBegin = Alignment.topCenter;
                    _gradEnd = Alignment.bottomCenter;
                  });
                  _applyCustomGradient();
                }),
                const SizedBox(width: 6),
                _buildDirectionPill('→ Left-Right', !_isCustomRadial && _gradBegin == Alignment.centerLeft, () {
                  setState(() {
                    _isCustomRadial = false;
                    _gradBegin = Alignment.centerLeft;
                    _gradEnd = Alignment.centerRight;
                  });
                  _applyCustomGradient();
                }),
                const SizedBox(width: 6),
                _buildDirectionPill('↗ Up-Right', !_isCustomRadial && _gradBegin == Alignment.bottomLeft, () {
                  setState(() {
                    _isCustomRadial = false;
                    _gradBegin = Alignment.bottomLeft;
                    _gradEnd = Alignment.topRight;
                  });
                  _applyCustomGradient();
                }),
                const SizedBox(width: 6),
                _buildDirectionPill('◎ Radial Center', _isCustomRadial, () {
                  setState(() {
                    _isCustomRadial = true;
                  });
                  _applyCustomGradient();
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _applyCustomGradient() {
    final grad = _isCustomRadial
        ? RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [_gradColor1, _gradColor2],
          )
        : LinearGradient(
            begin: _gradBegin,
            end: _gradEnd,
            colors: [_gradColor1, _gradColor2],
          );
    _applyBackground(
      type: BackgroundType.gradient,
      gradient: grad,
    );
  }

  Widget _buildGradientColorTile(String label, Color color, ValueChanged<Color> onChanged) {
    final hexString = '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Pick $label', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: HexColorPickerWidget(
                initialColor: color,
                onColorChanged: onChanged,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Done', style: TextStyle(color: Color(0xFF9E77F6), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF22202C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white24),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                  Text(
                    hexString,
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
            const Icon(Icons.colorize_rounded, size: 14, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionPill(String title, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF9E77F6) : const Color(0xFF22202C),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF9E77F6) : Colors.white12,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
