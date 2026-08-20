import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:layerly/features/editor/domain/entities/layer.dart';
import 'package:layerly/features/editor/domain/entities/layer_enums.dart';
import 'package:layerly/features/editor/domain/entities/text_layer.dart';
import 'package:layerly/features/editor/domain/entities/shape_layer.dart';
import 'package:layerly/features/editor/domain/entities/image_layer.dart';
import 'package:layerly/features/editor/domain/entities/device_mockup_layer.dart';
import 'package:layerly/features/editor/domain/entities/icon_layer.dart';
import 'package:layerly/features/editor/domain/entities/component_instance_layer.dart';
import 'package:layerly/features/editor/domain/entities/component_definition.dart';

class LayerView extends StatelessWidget {
  final Layer layer;
  final ComponentDefinition? Function(String id)? getComponentDefinition;

  const LayerView({
    super.key,
    required this.layer,
    this.getComponentDefinition,
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

    Widget textWidget = Text(
      layer.content,
      textAlign: layer.textAlign,
      style: style,
    );

    if (layer.textGradient != null) {
      textWidget = ShaderMask(
        shaderCallback: (bounds) => layer.textGradient!.createShader(bounds),
        child: Text(
          layer.content,
          textAlign: layer.textAlign,
          style: style.copyWith(color: Colors.white),
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

    if (layer.imagePath != null && layer.imagePath!.isNotEmpty) {
      final file = File(layer.imagePath!);
      if (file.existsSync()) {
        imageContent = Image.file(
          file,
          fit: layer.fit,
          width: layer.width,
          height: layer.height,
        );
      } else {
        imageContent = _buildImagePlaceholder(layer);
      }
    } else if (layer.assetPath != null && layer.assetPath!.isNotEmpty) {
      imageContent = Image.asset(
        layer.assetPath!,
        fit: layer.fit,
        width: layer.width,
        height: layer.height,
        errorBuilder: (ctx, err, stack) => _buildImagePlaceholder(layer),
      );
    } else {
      imageContent = _buildImagePlaceholder(layer);
    }

    return Container(
      width: layer.width,
      height: layer.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(layer.borderRadius),
        border: layer.borderColor != null && layer.borderWidth > 0
            ? Border.all(color: layer.borderColor!, width: layer.borderWidth)
            : null,
        boxShadow: layer.shadows,
      ),
      clipBehavior: Clip.antiAlias,
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
              Image.file(
                File(layer.screenImagePath!),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (ctx, err, stack) => _buildSimulatedAppScreen(),
              )
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
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7E3FF2), Color(0xFFA970FF)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ride on your schedule',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                ],
              ),
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
}
