import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../../../../core/widgets/app_modal_sheet.dart';
import '../../../editor/data/project_storage_service.dart';
import '../../../editor/domain/entities/canvas_page.dart';
import '../../../editor/domain/entities/canvas_project.dart';
import '../../../editor/domain/entities/device_mockup_layer.dart';
import '../../../editor/domain/entities/layer_enums.dart';
import '../../../editor/domain/entities/shape_layer.dart';
import '../../../editor/domain/entities/text_layer.dart';

class CanvasPreset {
  final String title;
  final String category;
  final double width;
  final double height;
  final IconData icon;
  final String ratio;

  const CanvasPreset({
    required this.title,
    required this.category,
    required this.width,
    required this.height,
    required this.icon,
    required this.ratio,
  });
}

const List<CanvasPreset> kCanvasPresets = [
  CanvasPreset(
    title: 'Square Carousel',
    category: 'Instagram / LinkedIn',
    width: 1080,
    height: 1080,
    icon: Icons.crop_square_rounded,
    ratio: '1:1',
  ),
  CanvasPreset(
    title: 'App Store Screenshot',
    category: 'iPhone 17 Pro Max',
    width: 1290,
    height: 2796,
    icon: Icons.phone_iphone_rounded,
    ratio: '9:19.5',
  ),
  CanvasPreset(
    title: 'Dribbble Shot',
    category: 'Design Portfolio',
    width: 1600,
    height: 1200,
    icon: Icons.palette_outlined,
    ratio: '4:3',
  ),
  CanvasPreset(
    title: 'X / Twitter Post',
    category: 'Social Graphic',
    width: 1200,
    height: 675,
    icon: Icons.aspect_ratio_rounded,
    ratio: '16:9',
  ),
  CanvasPreset(
    title: 'Story / Reel',
    category: 'Vertical Story',
    width: 1080,
    height: 1920,
    icon: Icons.stay_current_portrait_rounded,
    ratio: '9:16',
  ),
  CanvasPreset(
    title: 'Custom Size',
    category: 'Custom dimensions',
    width: 1080,
    height: 1080,
    icon: Icons.dashboard_customize_rounded,
    ratio: 'Custom',
  ),
];

class NewProjectSheet extends StatefulWidget {
  const NewProjectSheet({super.key});

  static Future<CanvasProject?> show(BuildContext context) {
    return showAppModalSheet<CanvasProject>(
      context: context,
      builder: (ctx) => const NewProjectSheet(),
    );
  }

  @override
  State<NewProjectSheet> createState() => _NewProjectSheetState();
}

class _NewProjectSheetState extends State<NewProjectSheet> {
  final TextEditingController _nameController = TextEditingController(text: 'Untitled Project');
  final TextEditingController _widthController = TextEditingController(text: '1080');
  final TextEditingController _heightController = TextEditingController(text: '1080');

  int _selectedPresetIndex = 0;
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _onPresetChanged(int index) {
    setState(() {
      _selectedPresetIndex = index;
      if (index < kCanvasPresets.length - 1) {
        final preset = kCanvasPresets[index];
        _widthController.text = preset.width.toInt().toString();
        _heightController.text = preset.height.toInt().toString();
      }
    });
  }

  Future<void> _handleCreate() async {
    final name = _nameController.text.trim().isEmpty ? 'Untitled Project' : _nameController.text.trim();
    final width = double.tryParse(_widthController.text) ?? 1080.0;
    final height = double.tryParse(_heightController.text) ?? 1080.0;

    setState(() => _isCreating = true);

    final isPhoneScreenshot = _selectedPresetIndex == 1;

    final initialPage = CanvasPage(
      id: UuidGenerator.generate(),
      name: 'Slide 01',
      width: width,
      height: height,
      backgroundType: BackgroundType.gradient,
      backgroundColor: const Color(0xFF0D0B14),
      backgroundGradient: const RadialGradient(
        center: Alignment(0.4, -0.6),
        radius: 1.2,
        colors: [Color(0xFF2C194D), Color(0xFF13141B), Color(0xFF0D0B14)],
        stops: [0.0, 0.5, 1.0],
      ),
      layers: isPhoneScreenshot
          ? [
              TextLayer(
                id: UuidGenerator.generate(),
                name: 'Headline',
                x: width * 0.1,
                y: height * 0.08,
                width: width * 0.8,
                height: 120,
                content: 'Experience The\nNext-Gen App',
                fontSize: 64,
                fontWeight: FontWeight.w800,
                textAlign: TextAlign.center,
                fontFamily: 'Outfit',
                color: Colors.white,
              ),
              DeviceMockupLayer(
                id: UuidGenerator.generate(),
                name: 'App Mockup',
                x: (width - 860) / 2,
                y: height * 0.28,
                width: 860,
                height: 1750,
                device: MockupDevice.iphone17ProMax,
              ),
            ]
          : [
              TextLayer(
                id: UuidGenerator.generate(),
                name: 'Title',
                x: width * 0.1,
                y: height * 0.15,
                width: width * 0.8,
                height: 90,
                content: name,
                fontSize: 44,
                fontWeight: FontWeight.w800,
                fontFamily: 'Outfit',
                color: Colors.white,
              ),
              TextLayer(
                id: UuidGenerator.generate(),
                name: 'Subtitle',
                x: width * 0.1,
                y: height * 0.28,
                width: width * 0.8,
                height: 50,
                content: 'Design modern visuals, carousels & mockups in Layerly.',
                fontSize: 22,
                color: AppColors.textSecondary,
              ),
              ShapeLayer(
                id: UuidGenerator.generate(),
                name: 'Card Base',
                x: width * 0.1,
                y: height * 0.40,
                width: width * 0.8,
                height: height * 0.45,
                shapeType: ShapeType.roundedRectangle,
                fill: const Color(0xFF1D1E28),
                cornerRadius: 28,
                strokeColor: Colors.white.withValues(alpha: 0.12),
                strokeWidth: 1.5,
              ),
            ],
    );

    final project = await ProjectStorageService.instance.createNewProject(
      name: name,
      width: width,
      height: height,
      initialPages: [initialPage],
    );

    if (!mounted) return;
    Navigator.pop(context, project);
  }

  @override
  Widget build(BuildContext context) {
    final isCustom = _selectedPresetIndex == kCanvasPresets.length - 1;

    return AppModalSheet(
      icon: Icons.add_to_photos_rounded,
      title: 'New Design Project',
      subtitle: 'Set up your canvas size, format & starter artboard',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Project Name Input
          const Text(
            'PROJECT NAME',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'e.g. Finance App Showcase',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surfaceSecondary,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Presets Grid
          const Text(
            'CANVAS FORMAT & PRESETS',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.3,
            ),
            itemCount: kCanvasPresets.length,
            itemBuilder: (context, index) {
              final preset = kCanvasPresets[index];
              final isSelected = index == _selectedPresetIndex;

              return InkWell(
                onTap: () => _onPresetChanged(index),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF261D42) : AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF8B5CF6) : Colors.white.withValues(alpha: 0.08),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF8B5CF6).withValues(alpha: 0.25)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          preset.icon,
                          size: 18,
                          color: isSelected ? const Color(0xFFA78BFA) : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              preset.title,
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.text,
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              preset.ratio,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
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

          if (isCustom) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'WIDTH (PX)',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _widthController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surfaceSecondary,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'HEIGHT (PX)',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _heightController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surfaceSecondary,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),

          // Create CTA Button
          ElevatedButton(
            onPressed: _isCreating ? null : _handleCreate,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 4,
              shadowColor: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
            ),
            child: _isCreating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome_rounded, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Create & Open Studio',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
