import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:layerly/core/constants/app_colors.dart';
import 'package:layerly/core/utils/uuid_generator.dart';
import 'package:layerly/features/editor/domain/entities/shape_layer.dart';
import 'package:layerly/features/editor/domain/entities/icon_layer.dart';
import 'package:layerly/features/editor/domain/entities/device_mockup_layer.dart';
import 'package:layerly/features/editor/domain/entities/image_layer.dart';
import 'package:layerly/features/editor/domain/entities/layer.dart';
import 'package:layerly/features/editor/domain/entities/layer_enums.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_bloc.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_event.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_state.dart';

/// Opens the Media & Mockup Studio bottom sheet.
void showImagePickerBottomSheet(
  BuildContext context, {
  EditorBloc? bloc,
  Layer? targetLayer,
}) {
  final editorBloc = bloc ?? context.read<EditorBloc>();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => BlocProvider.value(
      value: editorBloc,
      child: _ImagePickerSheetModal(
        bloc: editorBloc,
        targetLayer: targetLayer,
      ),
    ),
  );
}

class _ImagePickerSheetModal extends StatefulWidget {
  final EditorBloc bloc;
  final Layer? targetLayer;

  const _ImagePickerSheetModal({
    required this.bloc,
    this.targetLayer,
  });

  @override
  State<_ImagePickerSheetModal> createState() => _ImagePickerSheetModalState();
}

class _ImagePickerSheetModalState extends State<_ImagePickerSheetModal> {
  final ImagePicker _picker = ImagePicker();
  
  // Insertion mode: 0 = Standalone Image, 1 = Inside Device Mockup
  int _selectedMode = 0;
  MockupDevice _selectedMockupDevice = MockupDevice.iphone;
  String _activePresetTab = 'App Screens'; // App Screens, Wallpapers, Vectors

  @override
  void initState() {
    super.initState();
    // If the target layer is a mockup, default to Mockup mode
    if (widget.targetLayer is DeviceMockupLayer) {
      _selectedMode = 1;
      _selectedMockupDevice = (widget.targetLayer as DeviceMockupLayer).device;
    }
  }

  // -------------------------------------------------------------
  // MEDIA PICKING METHODS
  // -------------------------------------------------------------

  Future<void> _pickCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 92,
      );
      if (photo != null && mounted) {
        _handlePickedFile(photo.path, photo.name);
      }
    } catch (e) {
      _showErrorSnackBar('Camera error: ${e.toString()}');
    }
  }

  Future<void> _pickGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 95,
      );
      if (image != null && mounted) {
        _handlePickedFile(image.path, image.name);
      }
    } catch (e) {
      _showErrorSnackBar('Gallery error: ${e.toString()}');
    }
  }

  Future<void> _pickSvgFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['svg'],
      );
      if (result != null && result.files.single.path != null && mounted) {
        final path = result.files.single.path!;
        final name = result.files.single.name;
        _handlePickedFile(path, name);
      }
    } catch (e) {
      _showErrorSnackBar('SVG picker error: ${e.toString()}');
    }
  }

  Future<void> _pickGenericImageFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp', 'svg', 'gif'],
      );
      if (result != null && result.files.single.path != null && mounted) {
        final path = result.files.single.path!;
        final name = result.files.single.name;
        _handlePickedFile(path, name);
      }
    } catch (e) {
      _showErrorSnackBar('File picker error: ${e.toString()}');
    }
  }

  void _handlePickedFile(String filePath, String fileName) {
    Navigator.pop(context);

    // If targetLayer is provided, update it in place
    if (widget.targetLayer != null) {
      if (widget.targetLayer is DeviceMockupLayer) {
        final updated = (widget.targetLayer as DeviceMockupLayer).copyWith(
          screenImagePath: filePath,
        );
        widget.bloc.add(UpdateLayerEvent(updated));
      } else if (widget.targetLayer is ImageLayer) {
        final updated = (widget.targetLayer as ImageLayer).copyWith(
          imagePath: filePath,
        );
        widget.bloc.add(UpdateLayerEvent(updated));
      }
      return;
    }

    final activePage = widget.bloc.state.activePage;
    final centerX = (activePage.width / 2);
    final centerY = (activePage.height / 2);

    if (_selectedMode == 1) {
      // 📱 Insert Inside Device Mockup
      final isMac = _selectedMockupDevice == MockupDevice.macbook;
      final width = isMac ? 340.0 : 220.0;
      final height = isMac ? 210.0 : 440.0;

      final mockupLayer = DeviceMockupLayer(
        id: 'mockup-${UuidGenerator.generate().substring(0, 8)}',
        name: '${_getDeviceName(_selectedMockupDevice)} Mockup',
        x: (centerX - width / 2).clamp(20.0, activePage.width - width - 20.0),
        y: (centerY - height / 2).clamp(20.0, activePage.height - height - 20.0),
        width: width,
        height: height,
        device: _selectedMockupDevice,
        screenImagePath: filePath,
        cornerRadius: isMac ? 14.0 : 38.0,
      );

      widget.bloc.add(AddLayerEvent(mockupLayer));
    } else {
      // 🖼️ Standalone Image or SVG
      final isSvg = filePath.toLowerCase().endsWith('.svg');
      final width = isSvg ? 180.0 : 260.0;
      final height = isSvg ? 180.0 : 190.0;

      final imageLayer = ImageLayer(
        id: 'img-${UuidGenerator.generate().substring(0, 8)}',
        name: fileName.isNotEmpty ? fileName : (isSvg ? 'Vector SVG' : 'Image'),
        x: (centerX - width / 2).clamp(20.0, activePage.width - width - 20.0),
        y: (centerY - height / 2).clamp(20.0, activePage.height - height - 20.0),
        width: width,
        height: height,
        imagePath: filePath,
        borderRadius: isSvg ? 0.0 : 16.0,
      );

      widget.bloc.add(AddLayerEvent(imageLayer));
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF4757),
      ),
    );
  }

  String _getDeviceName(MockupDevice device) {
    switch (device) {
      case MockupDevice.iphone:
        return 'iPhone 15 Pro';
      case MockupDevice.macbook:
        return 'MacBook Pro';
      case MockupDevice.android:
        return 'Android Flagship';
      case MockupDevice.browser:
        return 'Browser Window';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditorBloc, EditorState>(
      bloc: widget.bloc,
      builder: (context, state) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.82,
          decoration: const BoxDecoration(
            color: Color(0xFF131219),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: Color(0xFF2A2838), width: 1.5),
              left: BorderSide(color: Color(0xFF2A2838), width: 1.0),
              right: BorderSide(color: Color(0xFF2A2838), width: 1.0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header
              _buildHeader(context),

              // 2. Mode Selector Segment (Standalone Image vs Device Mockup)
              _buildModeSelector(),

              // 3. Mockup Device Selector (if Mockup mode selected)
              if (_selectedMode == 1) _buildMockupDeviceSelector(),

              const Divider(height: 1, color: Color(0xFF242232)),

              // 4. Scrollable Content (Upload Actions + Curated Presets)
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Upload Actions Grid (4 Cards)
                    _buildUploadActionGrid(),
                    const SizedBox(height: 20),

                    // Curated Presets Section
                    _buildPresetHeader(),
                    const SizedBox(height: 10),
                    _buildPresetCards(state),
                  ],
                ),
              ),
            ],
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
                    colors: [Color(0xFF0984E3), Color(0xFF6C5CE7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0984E3).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_photo_alternate_rounded,
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
                      'Media & Mockup Studio',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Take photos, pick gallery, upload SVG or insert in mockups',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
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

  Widget _buildModeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFF1B1927),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2B283D)),
        ),
        padding: const EdgeInsets.all(3),
        child: Row(
          children: [
            Expanded(
              child: _buildModeTab(
                title: '🖼️ Standalone Image',
                isSelected: _selectedMode == 0,
                onTap: () => setState(() => _selectedMode = 0),
              ),
            ),
            Expanded(
              child: _buildModeTab(
                title: '📱 Inside Device Mockup',
                isSelected: _selectedMode == 1,
                onTap: () => setState(() => _selectedMode = 1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C5CE7) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6C5CE7).withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textMuted,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMockupDeviceSelector() {
    final devices = [
      {'device': MockupDevice.iphone, 'name': 'iPhone 15 Pro', 'icon': Icons.phone_iphone_rounded},
      {'device': MockupDevice.macbook, 'name': 'MacBook Pro', 'icon': Icons.laptop_mac_rounded},
      {'device': MockupDevice.android, 'name': 'Android Flagship', 'icon': Icons.phone_android_rounded},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
      child: Row(
        children: devices.map((d) {
          final device = d['device'] as MockupDevice;
          final isSelected = _selectedMockupDevice == device;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: InkWell(
                onTap: () => setState(() => _selectedMockupDevice = device),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF2B2644) : const Color(0xFF1B1927),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFA78BFA) : const Color(0xFF2C283F),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        d['icon'] as IconData,
                        size: 13,
                        color: isSelected ? const Color(0xFFA78BFA) : AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        d['name'] as String,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUploadActionGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Import Source',
          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Take Photo',
                subtitle: 'Camera snapshot',
                icon: Icons.camera_alt_rounded,
                accentColor: const Color(0xFFFF7675),
                onTap: _pickCamera,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionCard(
                title: 'Photo Library',
                subtitle: 'Pick gallery image',
                icon: Icons.photo_library_rounded,
                accentColor: const Color(0xFF74B9FF),
                onTap: _pickGallery,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Upload SVG',
                subtitle: 'Vector graphics',
                icon: Icons.draw_rounded,
                accentColor: const Color(0xFF55EFC4),
                onTap: _pickSvgFile,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionCard(
                title: 'Browse Files',
                subtitle: 'PNG, JPG, WEBP',
                icon: Icons.folder_open_rounded,
                accentColor: const Color(0xFFFDCB6E),
                onTap: _pickGenericImageFile,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1927),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2C283F)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
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

  Widget _buildPresetHeader() {
    final tabs = ['App Screens', 'Wallpapers', 'Vectors'];

    return Row(
      children: [
        const Text(
          'Curated Design Kits',
          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        Container(
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFF1B1927),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(2),
          child: Row(
            children: tabs.map((t) {
              final isSelected = _activePresetTab == t;
              return InkWell(
                onTap: () => setState(() => _activePresetTab = t),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF6C5CE7) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    t,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetCards(EditorState state) {
    if (_activePresetTab == 'App Screens') {
      return _buildAppScreenPresets();
    } else if (_activePresetTab == 'Wallpapers') {
      return _buildWallpaperPresets();
    } else {
      return _buildVectorPresets();
    }
  }

  Widget _buildAppScreenPresets() {
    final screens = [
      {
        'title': 'Fintech & Banking',
        'subtitle': 'Credit card, stats, transactions',
        'device': MockupDevice.iphone,
        'color': const Color(0xFF6C5CE7),
      },
      {
        'title': 'Crypto Portfolio',
        'subtitle': 'Candlesticks, coin balances',
        'device': MockupDevice.iphone,
        'color': const Color(0xFF00CEC9),
      },
      {
        'title': 'Food Delivery',
        'subtitle': 'Burger card, rating, order button',
        'device': MockupDevice.iphone,
        'color': const Color(0xFFFF7675),
      },
      {
        'title': 'Analytics Dashboard',
        'subtitle': 'Desktop browser graph view',
        'device': MockupDevice.macbook,
        'color': const Color(0xFF0984E3),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.45,
      ),
      itemCount: screens.length,
      itemBuilder: (ctx, idx) {
        final s = screens[idx];
        final device = s['device'] as MockupDevice;
        final color = s['color'] as Color;

        return InkWell(
          onTap: () {
            Navigator.pop(context);
            final activePage = widget.bloc.state.activePage;
            final isMac = device == MockupDevice.macbook;
            final width = isMac ? 340.0 : 220.0;
            final height = isMac ? 210.0 : 440.0;

            final mockup = DeviceMockupLayer(
              id: 'mockup-${UuidGenerator.generate().substring(0, 8)}',
              name: s['title'] as String,
              x: (activePage.width / 2 - width / 2).clamp(20.0, activePage.width - width - 20.0),
              y: (activePage.height / 2 - height / 2).clamp(20.0, activePage.height - height - 20.0),
              width: width,
              height: height,
              device: device,
              cornerRadius: isMac ? 14.0 : 38.0,
            );
            widget.bloc.add(AddLayerEvent(mockup));
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1927),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2C283F)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        device == MockupDevice.macbook ? Icons.laptop_mac_rounded : Icons.phone_iphone_rounded,
                        color: color,
                        size: 16,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF262338),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('1-Tap Insert', style: TextStyle(color: Color(0xFF55EFC4), fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s['title'] as String,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s['subtitle'] as String,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWallpaperPresets() {
    final wallpapers = [
      {'name': 'Cyberpunk Mesh', 'colors': [const Color(0xFF6C5CE7), const Color(0xFFFF7675)]},
      {'name': 'Obsidian Gold', 'colors': [const Color(0xFF1E272E), const Color(0xFFFDCB6E)]},
      {'name': 'Neon Mint', 'colors': [const Color(0xFF00CEC9), const Color(0xFF0984E3)]},
      {'name': 'Deep Sunset', 'colors': [const Color(0xFFE84393), const Color(0xFFFF7675)]},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.7,
      ),
      itemCount: wallpapers.length,
      itemBuilder: (ctx, idx) {
        final w = wallpapers[idx];
        final colors = w['colors'] as List<Color>;

        return InkWell(
          onTap: () {
            Navigator.pop(context);
            final activePage = widget.bloc.state.activePage;
            final shape = ShapeLayer(
              id: 'wallpaper-${UuidGenerator.generate().substring(0, 8)}',
              name: w['name'] as String,
              x: (activePage.width / 2 - 130),
              y: (activePage.height / 2 - 90),
              width: 260,
              height: 180,
              fill: colors.first,
              gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
              cornerRadius: 16,
            );
            widget.bloc.add(AddLayerEvent(shape));
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            padding: const EdgeInsets.all(10),
            alignment: Alignment.bottomLeft,
            child: Text(
              w['name'] as String,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, shadows: [
                Shadow(color: Colors.black54, blurRadius: 4),
              ]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVectorPresets() {
    final vectors = [
      {'name': 'Rocket Launch', 'icon': Icons.rocket_launch_rounded, 'color': const Color(0xFFFF7675)},
      {'name': 'Growth Trend', 'icon': Icons.trending_up_rounded, 'color': const Color(0xFF55EFC4)},
      {'name': 'Shield Security', 'icon': Icons.security_rounded, 'color': const Color(0xFF74B9FF)},
      {'name': 'Sparkle AI', 'icon': Icons.auto_awesome_rounded, 'color': const Color(0xFFA78BFA)},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.6,
      ),
      itemCount: vectors.length,
      itemBuilder: (ctx, idx) {
        final v = vectors[idx];
        final icon = v['icon'] as IconData;
        final color = v['color'] as Color;

        return InkWell(
          onTap: () {
            Navigator.pop(context);
            final activePage = widget.bloc.state.activePage;
            final iconLayer = IconLayer(
              id: 'vector-${UuidGenerator.generate().substring(0, 8)}',
              name: '${v['name']} Vector',
              x: (activePage.width / 2 - 40),
              y: (activePage.height / 2 - 40),
              width: 80,
              height: 80,
              icon: icon,
              color: color,
            );
            widget.bloc.add(AddLayerEvent(iconLayer));
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1927),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2C283F)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    v['name'] as String,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
