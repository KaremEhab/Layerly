import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:layerly/features/editor/domain/entities/mockup_definition.dart';

class Iphone17ProMaxMockup extends StatefulWidget {
  const Iphone17ProMaxMockup({
    super.key,
    this.initialImage,
    this.maxWidth = 340,
    this.imageFit = BoxFit.cover,
    this.imageOffsetX = 0.0,
    this.imageOffsetY = 0.0,
    this.imageScale = 1.0,
    this.showGlare = true,
    this.showDynamicIsland = true,
    this.onImageChanged,
  });

  final File? initialImage;
  final double maxWidth;
  final BoxFit imageFit;
  final double imageOffsetX;
  final double imageOffsetY;
  final double imageScale;
  final bool showGlare;
  final bool showDynamicIsland;
  final ValueChanged<File?>? onImageChanged;

  @override
  State<Iphone17ProMaxMockup> createState() => _Iphone17ProMaxMockupState();
}

class _Iphone17ProMaxMockupState extends State<Iphone17ProMaxMockup> {
  final ImagePicker _picker = ImagePicker();
  File? _image;

  @override
  void initState() {
    super.initState();
    _image = widget.initialImage;
  }

  @override
  void didUpdateWidget(covariant Iphone17ProMaxMockup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialImage != oldWidget.initialImage) {
      _image = widget.initialImage;
    }
  }

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );
    if (picked == null) return;
    setState(() {
      _image = File(picked.path);
    });
    widget.onImageChanged?.call(_image);
  }

  Future<void> _showPickerOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF191622),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF706A7D),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Choose design',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _PickerOption(
                  icon: Icons.photo_library_outlined,
                  title: 'Choose from gallery',
                  subtitle: 'Use an existing design image',
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImage();
                  },
                ),
                if (_image != null) ...[
                  const SizedBox(height: 10),
                  _PickerOption(
                    icon: Icons.delete_outline,
                    title: 'Remove design',
                    subtitle: 'Return to the empty mockup',
                    destructive: true,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _image = null;
                      });
                      widget.onImageChanged?.call(null);
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const def = MockupDefinition.iphone17ProMax;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final phoneWidth = availableWidth.clamp(180.0, widget.maxWidth);
        final phoneHeight = phoneWidth / def.physicalAspectRatio;

        return Center(
          child: SizedBox(
            width: phoneWidth,
            height: phoneHeight,
            child: _PhoneFrame(
              image: _image,
              imageFit: widget.imageFit,
              imageOffsetX: widget.imageOffsetX,
              imageOffsetY: widget.imageOffsetY,
              imageScale: widget.imageScale,
              showGlare: widget.showGlare,
              showDynamicIsland: widget.showDynamicIsland,
              definition: def,
              onPickImage: _showPickerOptions,
            ),
          ),
        );
      },
    );
  }
}

class MockupCanvas extends StatelessWidget {
  const MockupCanvas({
    super.key,
    required this.mockup,
    this.image,
    this.maxWidth = 340,
  });

  final String mockup;
  final File? image;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    switch (mockup) {
      case 'iphone_17_pro_max':
      default:
        return Iphone17ProMaxMockup(
          initialImage: image,
          maxWidth: maxWidth,
        );
    }
  }
}

class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({
    required this.image,
    required this.onPickImage,
    required this.definition,
    this.imageFit = BoxFit.cover,
    this.imageOffsetX = 0.0,
    this.imageOffsetY = 0.0,
    this.imageScale = 1.0,
    this.showGlare = true,
    this.showDynamicIsland = true,
  });

  final File? image;
  final VoidCallback onPickImage;
  final MockupDefinition definition;
  final BoxFit imageFit;
  final double imageOffsetX;
  final double imageOffsetY;
  final double imageScale;
  final bool showGlare;
  final bool showDynamicIsland;

  @override
  Widget build(BuildContext context) {
    final cornerRadius = definition.cornerRadius;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF050507),
        borderRadius: BorderRadius.circular(cornerRadius),
        border: Border.all(
          color: const Color(0xFF303039),
          width: 2.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 35,
            spreadRadius: 4,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(definition.bezelWidth),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(cornerRadius - definition.bezelWidth),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Screen container
              Container(
                color: const Color(0xFFF5F5F7),
                child: image == null
                    ? _EmptyScreen(onTap: onPickImage)
                    : GestureDetector(
                        onTap: onPickImage,
                        child: Transform.translate(
                          offset: Offset(imageOffsetX, imageOffsetY),
                          child: Transform.scale(
                            scale: imageScale,
                            child: Image.file(
                              image!,
                              fit: imageFit,
                              width: double.infinity,
                              height: double.infinity,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ),
                      ),
              ),

              // Dynamic Island
              if (definition.hasDynamicIsland && showDynamicIsland)
                Positioned(
                  top: definition.dynamicIslandTop,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: definition.dynamicIslandWidth,
                      height: definition.dynamicIslandHeight,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(definition.dynamicIslandHeight / 2),
                        border: Border.all(color: Colors.white12, width: 0.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0F1426),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Subtle screen reflection
              if (showGlare)
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.04),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.03),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyScreen extends StatelessWidget {
  const _EmptyScreen({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(28),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
          decoration: BoxDecoration(
            color: const Color(0xFF191622),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF9B6CFF).withValues(alpha: 0.45),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9B6CFF).withValues(alpha: 0.12),
                blurRadius: 18,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF9B6CFF).withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_photo_alternate_outlined,
                  color: Color(0xFF9B6CFF),
                  size: 26,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Add design',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Select an image to preview',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFA7A1B5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerOption extends StatelessWidget {
  const _PickerOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? const Color(0xFFFF5C67) : const Color(0xFF9B6CFF);
    return Material(
      color: const Color(0xFF211D2C),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF706A7D),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF706A7D),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
