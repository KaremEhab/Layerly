import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:layerly/core/constants/app_colors.dart';
import 'package:layerly/core/utils/uuid_generator.dart';
import 'package:layerly/features/editor/domain/entities/device_mockup_layer.dart';
import 'package:layerly/features/editor/domain/entities/image_layer.dart';
import 'package:layerly/features/editor/domain/entities/layer.dart';
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
      final result = await FilePickerPlatform.instance.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['svg'],
      );
      if (result.isNotEmpty && result.first.path != null && mounted) {
        final path = result.first.path!;
        final name = result.first.name;
        _handlePickedFile(path, name);
      }
    } catch (e) {
      _showErrorSnackBar('SVG picker error: ${e.toString()}');
    }
  }

  Future<void> _pickGenericImageFile() async {
    try {
      final result = await FilePickerPlatform.instance.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp', 'svg', 'gif'],
      );
      if (result.isNotEmpty && result.first.path != null && mounted) {
        final path = result.first.path!;
        final name = result.first.name;
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF4757),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditorBloc, EditorState>(
      bloc: widget.bloc,
      builder: (context, state) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 16),
            decoration: BoxDecoration(
              color: const Color(0xFF131219),
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
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header
                _buildHeader(context),

                const Divider(height: 1, color: Color(0xFF242232)),

                // 2. Upload Actions Grid
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                  child: _buildUploadActionGrid(),
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
                      'Media & Gallery Studio',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Take photos, pick gallery, upload SVG or browse files',
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
}
