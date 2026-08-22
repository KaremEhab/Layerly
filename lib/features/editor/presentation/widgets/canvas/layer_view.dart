import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:layerly/core/utils/text_span_parser.dart';
import 'package:layerly/features/editor/domain/entities/layer.dart';
import 'package:layerly/features/editor/domain/entities/layer_enums.dart';
import 'package:layerly/features/editor/domain/entities/text_layer.dart';
import 'package:layerly/features/editor/domain/entities/shape_layer.dart';
import 'package:layerly/features/editor/domain/entities/image_layer.dart';
import 'package:layerly/features/editor/domain/entities/device_mockup_layer.dart';
import 'package:layerly/features/editor/domain/entities/icon_layer.dart';
import 'package:layerly/features/editor/domain/entities/component_instance_layer.dart';
import 'package:layerly/features/editor/domain/entities/component_definition.dart';
import 'package:layerly/features/editor/domain/entities/auto_layout_layer.dart';
import 'package:layerly/features/editor/domain/entities/vector_layer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:layerly/features/editor/presentation/widgets/canvas/transform_box.dart';

class LayerView extends StatelessWidget {
  final Layer layer;
  final ComponentDefinition? Function(String id)? getComponentDefinition;
  final Function(String layerId, bool isMulti)? onSelectLayer;
  final List<String> selectedLayerIds;
  final double scale;
  final Function(String layerId, ResizeHandle handle, DragUpdateDetails details)? onResizeLayer;
  final Function(String layerId, ResizeHandle handle, DragEndDetails details)? onResizeLayerEnd;
  final Function(String layerId, double angle, bool isFinal)? onRotateLayer;

  const LayerView({
    super.key,
    required this.layer,
    this.getComponentDefinition,
    this.onSelectLayer,
    this.selectedLayerIds = const [],
    this.scale = 1.0,
    this.onResizeLayer,
    this.onResizeLayerEnd,
    this.onRotateLayer,
  });

  @override
  Widget build(BuildContext context) {
    if (!layer.visible) {
      return const SizedBox.shrink();
    }

    Widget content;
    if (layer is TextLayer) {
      content = _buildTextLayer(layer as TextLayer);
    } else if (layer is ShapeLayer) {
      content = _buildShapeLayer(layer as ShapeLayer);
    } else if (layer is ImageLayer) {
      content = _buildImageLayer(layer as ImageLayer);
    } else if (layer is DeviceMockupLayer) {
      content = _buildDeviceMockupLayer(layer as DeviceMockupLayer);
    } else if (layer is IconLayer) {
      content = _buildIconLayer(layer as IconLayer);
    } else if (layer is ComponentInstanceLayer) {
      content = _buildComponentInstanceLayer(layer as ComponentInstanceLayer);
    } else if (layer is AutoLayoutLayer) {
      content = _buildAutoLayoutLayer(layer as AutoLayoutLayer);
    } else if (layer is VectorLayer) {
      content = _buildVectorLayer(layer as VectorLayer);
    } else {
      content = const SizedBox.shrink();
    }

    return Opacity(
      opacity: layer.opacity.clamp(0.0, 1.0),
      child: content,
    );
  }


  Widget _buildTextLayer(TextLayer layer) {
    TextStyle style;
    try {
      style = GoogleFonts.getFont(
        layer.fontFamily,
        color: layer.color,
        fontSize: layer.fontSize,
        fontWeight: layer.fontWeight,
        fontStyle: layer.fontStyle,
        letterSpacing: layer.letterSpacing,
        height: layer.lineHeight,
        decoration: layer.decoration,
        shadows: layer.shadows,
      );
    } catch (_) {
      style = TextStyle(
        fontFamily: layer.fontFamily,
        color: layer.color,
        fontSize: layer.fontSize,
        fontWeight: layer.fontWeight,
        fontStyle: layer.fontStyle,
        letterSpacing: layer.letterSpacing,
        height: layer.lineHeight,
        decoration: layer.decoration,
        shadows: layer.shadows,
      );
    }

    final span = TextSpanParser.parseToTextSpan(layer.content, style);

    Widget textWidget = Text.rich(
      span,
      textAlign: layer.textAlign,
      softWrap: false,
      overflow: TextOverflow.visible,
    );

    if (layer.textGradient != null) {
      textWidget = ShaderMask(
        shaderCallback: (bounds) => layer.textGradient!.createShader(bounds),
        child: Text.rich(
          TextSpanParser.parseToTextSpan(layer.content, style.copyWith(color: Colors.white)),
          textAlign: layer.textAlign,
          softWrap: false,
          overflow: TextOverflow.visible,
        ),
      );
    }

    return Container(
      width: layer.width,
      height: layer.height,
      padding: layer.padding,
      decoration: layer.backgroundColor != null
          ? BoxDecoration(
              color: layer.backgroundColor,
              borderRadius: BorderRadius.circular(layer.backgroundRadius),
            )
          : null,
      alignment: _getAlignmentFromTextAlign(layer.textAlign),
      child: textWidget,
    );
  }

  Alignment _getAlignmentFromTextAlign(TextAlign align) {
    switch (align) {
      case TextAlign.left:
      case TextAlign.start:
        return Alignment.centerLeft;
      case TextAlign.center:
        return Alignment.center;
      case TextAlign.right:
      case TextAlign.end:
        return Alignment.centerRight;
      case TextAlign.justify:
        return Alignment.centerLeft;
    }
  }

  Widget _buildShapeLayer(ShapeLayer layer) {
    if (layer.shapeType == ShapeType.circle) {
      return Container(
        width: layer.width,
        height: layer.height,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: layer.gradient == null ? layer.fill : null,
          gradient: layer.gradient,
          border: layer.strokeColor != null && layer.strokeWidth > 0
              ? Border.all(
                  color: layer.strokeColor!,
                  width: layer.strokeWidth,
                )
              : null,
          boxShadow: layer.shadows,
        ),
      );
    }

    if (layer.shapeType == ShapeType.line) {
      return Container(
        width: layer.width,
        height: layer.height,
        alignment: Alignment.center,
        child: Container(
          width: layer.width,
          height: layer.strokeWidth > 0 ? layer.strokeWidth : layer.height,
          decoration: BoxDecoration(
            color: layer.fill,
            borderRadius: BorderRadius.circular(layer.cornerRadius),
            boxShadow: layer.shadows,
          ),
        ),
      );
    }

    return Container(
      width: layer.width,
      height: layer.height,
      decoration: BoxDecoration(
        color: layer.gradient == null ? layer.fill : null,
        gradient: layer.gradient,
        borderRadius: BorderRadius.circular(layer.cornerRadius),
        border: layer.strokeColor != null && layer.strokeWidth > 0
            ? Border.all(
                color: layer.strokeColor!,
                width: layer.strokeWidth,
              )
            : null,
        boxShadow: layer.shadows,
      ),
    );
  }

  Widget _buildImageLayer(ImageLayer layer) {
    Widget imageContent;

    if (layer.svgContent != null && layer.svgContent!.isNotEmpty) {
      imageContent = SvgPicture.string(
        layer.svgContent!,
        fit: layer.fit,
        width: layer.width,
        height: layer.height,
        colorFilter: layer.tintColor != null
            ? ColorFilter.mode(layer.tintColor!, BlendMode.srcIn)
            : null,
      );
    } else if (layer.imagePath != null && layer.imagePath!.isNotEmpty) {
      final file = File(layer.imagePath!);
      if (file.existsSync()) {
        if (layer.imagePath!.toLowerCase().endsWith('.svg')) {
          imageContent = SvgPicture.file(
            file,
            fit: layer.fit,
            width: layer.width,
            height: layer.height,
            colorFilter: layer.tintColor != null
                ? ColorFilter.mode(layer.tintColor!, BlendMode.srcIn)
                : null,
          );
        } else {
          imageContent = Image.file(
            file,
            fit: layer.fit,
            width: layer.width,
            height: layer.height,
          );
        }
      } else {
        imageContent = _buildImagePlaceholder(layer);
      }
    } else if (layer.assetPath != null && layer.assetPath!.isNotEmpty) {
      if (layer.assetPath!.toLowerCase().endsWith('.svg')) {
        imageContent = SvgPicture.asset(
          layer.assetPath!,
          fit: layer.fit,
          width: layer.width,
          height: layer.height,
          colorFilter: layer.tintColor != null
              ? ColorFilter.mode(layer.tintColor!, BlendMode.srcIn)
              : null,
        );
      } else {
        imageContent = Image.asset(
          layer.assetPath!,
          fit: layer.fit,
          width: layer.width,
          height: layer.height,
          errorBuilder: (ctx, err, stack) => _buildImagePlaceholder(layer),
        );
      }
    } else {
      imageContent = _buildImagePlaceholder(layer);
    }

    return Container(
      width: layer.width,
      height: layer.height,
      decoration: BoxDecoration(
        borderRadius: layer.borderRadius > 0 ? BorderRadius.circular(layer.borderRadius) : null,
        border: layer.borderColor != null && layer.borderWidth > 0
            ? Border.all(color: layer.borderColor!, width: layer.borderWidth)
            : null,
        boxShadow: layer.shadows,
      ),
      clipBehavior: layer.borderRadius > 0 ? Clip.antiAlias : Clip.none,
      child: imageContent,
    );
  }

  Widget _buildImagePlaceholder(ImageLayer layer) {
    return Container(
      width: layer.width,
      height: layer.height,
      color: const Color(0xFF1E2028),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_outlined, color: Color(0xFF636674), size: 36),
            SizedBox(height: 6),
            Text(
              'Select Image',
              style: TextStyle(color: Color(0xFF9698A3), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconLayer(IconLayer layer) {
    return Container(
      width: layer.width,
      height: layer.height,
      decoration: layer.backgroundColor != null
          ? BoxDecoration(
              color: layer.backgroundColor,
              borderRadius: BorderRadius.circular(layer.cornerRadius),
              boxShadow: layer.shadows,
            )
          : null,
      alignment: Alignment.center,
      child: Icon(
        layer.icon,
        color: layer.color,
        size: math.min(layer.width, layer.height) * 0.85,
      ),
    );
  }

  Widget _buildDeviceMockupLayer(DeviceMockupLayer layer) {
    return Container(
      width: layer.width,
      height: layer.height,
      decoration: BoxDecoration(
        color: layer.frameColor,
        borderRadius: BorderRadius.circular(layer.cornerRadius),
        boxShadow: layer.showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 40,
                  spreadRadius: 8,
                  offset: const Offset(0, 20),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          color: layer.screenBackgroundColor,
          borderRadius: BorderRadius.circular(layer.cornerRadius - 6),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Inner Screen Content (or Simulated Uber/App UI)
            if (layer.screenImagePath != null)
              Builder(builder: (ctx) {
                final file = File(layer.screenImagePath!);
                if (file.existsSync()) {
                  if (layer.screenImagePath!.toLowerCase().endsWith('.svg')) {
                    return SvgPicture.file(
                      file,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    );
                  } else {
                    return Image.file(
                      file,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (ctx, err, stack) => _buildSimulatedAppScreen(),
                    );
                  }
                }
                return _buildSimulatedAppScreen();
              })
            else
              _buildSimulatedAppScreen(),

            // Top Camera / Speaker Notch
            if (layer.showHeader)
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Container(
                    width: 70,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVectorLayer(VectorLayer layer) {
    return SizedBox(
      width: layer.width,
      height: layer.height,
      child: CustomPaint(
        painter: _VectorCanvasPainter(layer: layer),
      ),
    );
  }

  Widget _buildSimulatedAppScreen() {
    return Container(
      color: const Color(0xFFFFFFFF),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 34),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Tab switcher (Rides | Eats)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.black, width: 2.5),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions_car, size: 16, color: Colors.black),
                        SizedBox(width: 6),
                        Text(
                          'Rides',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lunch_dining, size: 16, color: Colors.black54),
                        SizedBox(width: 6),
                        Text(
                          'Eats',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEF2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, size: 18, color: Colors.black87),
                  SizedBox(width: 8),
                  Text(
                    'Where to?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.access_time_filled, size: 14, color: Colors.black54),
                  SizedBox(width: 4),
                  Text(
                    'Now',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Suggestions header
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Suggestions',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'See All',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Category cards
            Row(
              children: [
                _buildCategoryCard(Icons.local_taxi, 'Ride'),
                _buildCategoryCard(Icons.two_wheeler, '2-Wheels'),
                _buildCategoryCard(Icons.key, 'Rental'),
                _buildCategoryCard(Icons.train, 'Transit'),
              ],
            ),
            const SizedBox(height: 18),

            // Promo Banner
            Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7E3FF2), Color(0xFFA970FF)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ride on your schedule',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.white, size: 12),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Save everyday section
            const Text(
              'Save everyday',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F6F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 45,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD54F).withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Icon(Icons.electric_scooter, color: Colors.deepOrange, size: 24),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Go on 2 wheels →',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        const Text(
                          'Take an electric bike',
                          style: TextStyle(fontSize: 8, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F6F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 45,
                          decoration: BoxDecoration(
                            color: const Color(0xFF81C784).withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Icon(Icons.car_rental, color: Colors.teal, size: 24),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Add a stop or 5 →',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        const Text(
                          'Pick up something',
                          style: TextStyle(fontSize: 8, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Bottom Navigation Bar
            Container(
              padding: const EdgeInsets.only(top: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MockTabItem(icon: Icons.home, label: 'Home', isSelected: true),
                  _MockTabItem(icon: Icons.grid_view_rounded, label: 'Services'),
                  _MockTabItem(icon: Icons.receipt_long_rounded, label: 'Activity'),
                  _MockTabItem(icon: Icons.person_rounded, label: 'Account'),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Android 3-Button Nav Bar
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('|||', style: TextStyle(color: Colors.black45, fontSize: 11, fontWeight: FontWeight.w900)),
                Icon(Icons.crop_square_rounded, size: 12, color: Colors.black45),
                Icon(Icons.arrow_back_ios_new_rounded, size: 10, color: Colors.black45),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(IconData icon, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F3F7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: Colors.black87),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComponentInstanceLayer(ComponentInstanceLayer layer) {
    final definition = getComponentDefinition != null
        ? getComponentDefinition!(layer.componentDefinitionId)
        : null;

    if (definition == null) {
      return Container(
        width: layer.width,
        height: layer.height,
        decoration: BoxDecoration(
          color: const Color(0xFF1E2028),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFA970FF), width: 1),
        ),
        child: Center(
          child: Text(
            'Component: ${layer.name}',
            style: const TextStyle(color: Color(0xFFA970FF), fontSize: 11),
          ),
        ),
      );
    }

    // Render component layers scaled to fit the instance bounds
    final scaleX = layer.width / definition.width;
    final scaleY = layer.height / definition.height;

    return SizedBox(
      width: layer.width,
      height: layer.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: definition.layers.map((childLayer) {
          final mappedLayer = childLayer.copyWithTransform(
            x: childLayer.x * scaleX,
            y: childLayer.y * scaleY,
            width: childLayer.width * scaleX,
            height: childLayer.height * scaleY,
          );

          return Positioned(
            left: mappedLayer.x,
            top: mappedLayer.y,
            width: mappedLayer.width,
            height: mappedLayer.height,
            child: LayerView(
              layer: mappedLayer,
              getComponentDefinition: getComponentDefinition,
            ),
          );
        }).toList(),
      ),
    );
  }

  static Size measureTextSize(TextLayer textLayer) {
    TextStyle style;
    try {
      style = GoogleFonts.getFont(
        textLayer.fontFamily,
        color: textLayer.color,
        fontSize: textLayer.fontSize,
        fontWeight: textLayer.fontWeight,
        fontStyle: textLayer.fontStyle,
        letterSpacing: textLayer.letterSpacing,
        height: textLayer.lineHeight,
      );
    } catch (_) {
      style = TextStyle(
        fontFamily: textLayer.fontFamily,
        color: textLayer.color,
        fontSize: textLayer.fontSize,
        fontWeight: textLayer.fontWeight,
        fontStyle: textLayer.fontStyle,
        letterSpacing: textLayer.letterSpacing,
        height: textLayer.lineHeight,
      );
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: textLayer.content.isEmpty ? ' ' : textLayer.content,
        style: style,
      ),
      textDirection: TextDirection.ltr,
      textAlign: textLayer.textAlign,
    )..layout();

    final paddingH = textLayer.padding?.horizontal ?? 0.0;
    final paddingV = textLayer.padding?.vertical ?? 0.0;

    return Size(
      (textPainter.width * 1.06 + paddingH + 8.0).ceilToDouble().clamp(1.0, 5000.0),
      (textPainter.height + paddingV).ceilToDouble().clamp(1.0, 5000.0),
    );
  }

  static Size measureAutoLayoutSize(AutoLayoutLayer layer, {double? parentWidth, double? parentHeight}) {
    double requiredMainAxis = 0;
    double maxCrossAxis = 0;
    final isHorizontal = layer.direction == AutoLayoutDirection.horizontal;

    for (int i = 0; i < layer.children.length; i++) {
      final child = layer.children[i];
      final childSize = child is TextLayer
          ? measureTextSize(child)
          : (child is AutoLayoutLayer ? measureAutoLayoutSize(child) : Size(child.width, child.height));
      if (isHorizontal) {
        requiredMainAxis += childSize.width;
        if (childSize.height > maxCrossAxis) maxCrossAxis = childSize.height;
      } else {
        requiredMainAxis += childSize.height;
        if (childSize.width > maxCrossAxis) maxCrossAxis = childSize.width;
      }
      if (i > 0) requiredMainAxis += layer.gap;
    }

    final hugWidth = isHorizontal
        ? (requiredMainAxis + layer.paddingHorizontal * 2)
        : (maxCrossAxis + layer.paddingHorizontal * 2);

    final hugHeight = isHorizontal
        ? (maxCrossAxis + layer.paddingVertical * 2)
        : (requiredMainAxis + layer.paddingVertical * 2);

    double finalWidth;
    switch (layer.horizontalSizing) {
      case AutoLayoutSizingMode.fixed:
        finalWidth = layer.width > 0 ? layer.width : hugWidth.ceilToDouble();
        break;
      case AutoLayoutSizingMode.fill:
        finalWidth = parentWidth ?? (layer.width > 0 ? layer.width : hugWidth.ceilToDouble());
        break;
      case AutoLayoutSizingMode.hug:
        finalWidth = hugWidth.ceilToDouble();
        break;
    }

    double finalHeight;
    switch (layer.verticalSizing) {
      case AutoLayoutSizingMode.fixed:
        finalHeight = layer.height > 0 ? layer.height : hugHeight.ceilToDouble();
        break;
      case AutoLayoutSizingMode.fill:
        finalHeight = parentHeight ?? (layer.height > 0 ? layer.height : hugHeight.ceilToDouble());
        break;
      case AutoLayoutSizingMode.hug:
        finalHeight = hugHeight.ceilToDouble();
        break;
    }

    return Size(
      finalWidth.clamp(1.0, 5000.0),
      finalHeight.clamp(1.0, 5000.0),
    );
  }

  Widget _buildAutoLayoutLayer(AutoLayoutLayer layer) {
    final size = measureAutoLayoutSize(layer);
    final isHorizontal = layer.direction == AutoLayoutDirection.horizontal;
    final innerW = math.max(0.0, size.width - layer.paddingHorizontal * 2);
    final innerH = math.max(0.0, size.height - layer.paddingVertical * 2);

    // Calculate dynamic auto gap when spaceBetween is active
    double effectiveGap = layer.gap;
    if (layer.distribution == AutoLayoutDistribution.spaceBetween && layer.children.length > 1) {
      double totalChildrenSize = 0;
      for (final child in layer.children) {
        final cSize = child is TextLayer
            ? measureTextSize(child)
            : (child is AutoLayoutLayer ? measureAutoLayoutSize(child) : Size(child.width, child.height));
        totalChildrenSize += isHorizontal ? cSize.width : cSize.height;
      }
      final available = isHorizontal ? innerW : innerH;
      effectiveGap = math.max(0.0, (available - totalChildrenSize) / (layer.children.length - 1));
    }

    final alignX = isHorizontal ? _getDistOffset(layer.distribution) : _getAlignOffset(layer.alignment);
    final alignY = isHorizontal ? _getAlignOffset(layer.alignment) : _getDistOffset(layer.distribution);
    final boxAlignment = Alignment(alignX, alignY);

    return Container(
      width: size.width,
      height: size.height,
      clipBehavior: Clip.none,
      padding: EdgeInsets.symmetric(
        horizontal: layer.paddingHorizontal,
        vertical: layer.paddingVertical,
      ),
      decoration: BoxDecoration(
        color: layer.backgroundColor ?? Colors.transparent,
        borderRadius: BorderRadius.circular(layer.cornerRadius),
        border: layer.strokeWidth > 0 && layer.strokeColor != null
            ? Border.all(
                color: layer.strokeColor!,
                width: layer.strokeWidth,
                strokeAlign: switch (layer.strokePosition) {
                  StrokePosition.inside => BorderSide.strokeAlignInside,
                  StrokePosition.center => BorderSide.strokeAlignCenter,
                  StrokePosition.outside => BorderSide.strokeAlignOutside,
                },
              )
            : null,
      ),
      child: SizedBox(
        width: innerW,
        height: innerH,
        child: OverflowBox(
          alignment: boxAlignment,
          minWidth: 0,
          minHeight: 0,
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          child: Flex(
            direction: isHorizontal ? Axis.horizontal : Axis.vertical,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: _getFlexCrossAxis(layer.alignment),
            children: [
              for (int i = 0; i < layer.children.length; i++) ...[
                if (i > 0)
                  SizedBox(
                    width: isHorizontal ? effectiveGap : 0,
                    height: isHorizontal ? 0 : effectiveGap,
                  ),
                () {
                  final child = layer.children[i];
                  final isChildSelected = selectedLayerIds.contains(child.id);
                  final childSize = child is TextLayer
                      ? measureTextSize(child)
                      : (child is AutoLayoutLayer
                          ? measureAutoLayoutSize(
                              child,
                              parentWidth: innerW,
                              parentHeight: innerH,
                            )
                          : Size(child.width, child.height));
                  final childLayer = child is TextLayer
                      ? child.copyWith(width: childSize.width, height: childSize.height)
                      : (child is AutoLayoutLayer
                          ? child.copyWith(width: childSize.width, height: childSize.height)
                          : child);

                  Widget childView = LayerView(
                    layer: childLayer,
                    getComponentDefinition: getComponentDefinition,
                    onSelectLayer: onSelectLayer,
                    selectedLayerIds: selectedLayerIds,
                    scale: scale,
                    onResizeLayer: onResizeLayer,
                    onResizeLayerEnd: onResizeLayerEnd,
                    onRotateLayer: onRotateLayer,
                  );

                  if (isChildSelected) {
                    childView = Stack(
                      clipBehavior: Clip.none,
                      children: [
                        childView,
                        TransformBox(
                          layer: childLayer,
                          scale: scale,
                          onResize: (handle, details) {
                            onResizeLayer?.call(child.id, handle, details);
                          },
                          onResizeEnd: (handle, details) {
                            onResizeLayerEnd?.call(child.id, handle, details);
                          },
                          onRotate: (angle, isFinal) {
                            onRotateLayer?.call(child.id, angle, isFinal);
                          },
                        ),
                      ],
                    );
                  }

                  final isParentSelected = selectedLayerIds.contains(layer.id);

                  return SizedBox(
                    width: childSize.width,
                    height: childSize.height,
                    child: isParentSelected
                        ? GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onDoubleTap: () {
                              // Double-clicking dives directly into this immediate direct child layer (1 level down)
                              onSelectLayer?.call(child.id, false);
                            },
                            child: childView,
                          )
                        : childView,
                  );
                }(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  double _getAlignOffset(AutoLayoutAlignment align) {
    switch (align) {
      case AutoLayoutAlignment.start:
        return -1.0;
      case AutoLayoutAlignment.center:
      case AutoLayoutAlignment.stretch:
        return 0.0;
      case AutoLayoutAlignment.end:
        return 1.0;
    }
  }

  double _getDistOffset(AutoLayoutDistribution dist) {
    switch (dist) {
      case AutoLayoutDistribution.start:
      case AutoLayoutDistribution.spaceBetween:
        return -1.0;
      case AutoLayoutDistribution.center:
        return 0.0;
      case AutoLayoutDistribution.end:
        return 1.0;
    }
  }

  MainAxisAlignment _getFlexMainAxis(AutoLayoutDistribution dist) {
    switch (dist) {
      case AutoLayoutDistribution.start:
        return MainAxisAlignment.start;
      case AutoLayoutDistribution.center:
        return MainAxisAlignment.center;
      case AutoLayoutDistribution.end:
        return MainAxisAlignment.end;
      case AutoLayoutDistribution.spaceBetween:
        return MainAxisAlignment.spaceBetween;
    }
  }

  CrossAxisAlignment _getFlexCrossAxis(AutoLayoutAlignment align) {
    switch (align) {
      case AutoLayoutAlignment.start:
        return CrossAxisAlignment.start;
      case AutoLayoutAlignment.center:
        return CrossAxisAlignment.center;
      case AutoLayoutAlignment.end:
        return CrossAxisAlignment.end;
      case AutoLayoutAlignment.stretch:
        return CrossAxisAlignment.stretch;
    }
  }
}

class _MockTabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;

  const _MockTabItem({
    required this.icon,
    required this.label,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: isSelected ? Colors.black : Colors.black45,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.black : Colors.black45,
          ),
        ),
      ],
    );
  }
}

class _VectorCanvasPainter extends CustomPainter {
  final VectorLayer layer;

  const _VectorCanvasPainter({required this.layer});

  @override
  void paint(Canvas canvas, Size size) {
    if (layer.elements.isEmpty) return;

    for (final elem in layer.elements) {
      if (!elem.visible || elem.points.isEmpty) continue;

      final path = Path();
      final points = elem.points;

      final startX = points.first.x * size.width;
      final startY = points.first.y * size.height;
      path.moveTo(startX, startY);

      for (int i = 1; i < points.length; i++) {
        final p = points[i];
        final prev = points[i - 1];

        final px = p.x * size.width;
        final py = p.y * size.height;

        if (p.isSmooth && (p.handleInX != null || prev.handleOutX != null)) {
          final cp1x = (prev.handleOutX != null) ? prev.handleOutX! * size.width : prev.x * size.width;
          final cp1y = (prev.handleOutY != null) ? prev.handleOutY! * size.height : prev.y * size.height;
          final cp2x = (p.handleInX != null) ? p.handleInX! * size.width : px;
          final cp2y = (p.handleInY != null) ? p.handleInY! * size.height : py;
          path.cubicTo(cp1x, cp1y, cp2x, cp2y, px, py);
        } else {
          path.lineTo(px, py);
        }
      }

      if (elem.isClosed) {
        final last = points.last;
        final first = points.first;
        if (first.isSmooth && (first.handleInX != null || last.handleOutX != null)) {
          final cp1x = (last.handleOutX != null) ? last.handleOutX! * size.width : last.x * size.width;
          final cp1y = (last.handleOutY != null) ? last.handleOutY! * size.height : last.y * size.height;
          final cp2x = (first.handleInX != null) ? first.handleInX! * size.width : startX;
          final cp2y = (first.handleInY != null) ? first.handleInY! * size.height : startY;
          path.cubicTo(cp1x, cp1y, cp2x, cp2y, startX, startY);
        } else {
          path.close();
        }
      }

      // Fill
      if (elem.fill != null) {
        final fillPaint = Paint()
          ..color = elem.fill!.withValues(alpha: elem.opacity.clamp(0.0, 1.0))
          ..style = PaintingStyle.fill;
        canvas.drawPath(path, fillPaint);
      }

      // Stroke
      if (elem.strokeColor != null && elem.strokeWidth > 0) {
        final strokePaint = Paint()
          ..color = elem.strokeColor!.withValues(alpha: elem.opacity.clamp(0.0, 1.0))
          ..strokeWidth = elem.strokeWidth
          ..strokeCap = elem.strokeCap
          ..strokeJoin = elem.strokeJoin
          ..style = PaintingStyle.stroke;
        canvas.drawPath(path, strokePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _VectorCanvasPainter oldDelegate) => true;
}
