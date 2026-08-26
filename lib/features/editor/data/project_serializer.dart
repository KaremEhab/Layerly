import 'package:flutter/material.dart';
import '../domain/entities/auto_layout_layer.dart';
import '../domain/entities/canvas_page.dart';
import '../domain/entities/canvas_project.dart';
import '../domain/entities/component_definition.dart';
import '../domain/entities/component_instance_layer.dart';
import '../domain/entities/device_mockup_layer.dart';
import '../domain/entities/icon_layer.dart';
import '../domain/entities/image_layer.dart';
import '../domain/entities/layer.dart';
import '../domain/entities/layer_enums.dart';
import '../domain/entities/shape_layer.dart';
import '../domain/entities/text_layer.dart';
import '../domain/entities/vector_layer.dart';

/// Complete robust JSON serializer and deserializer for Layerly Studio projects.
class ProjectSerializer {
  // ==========================================
  // Project Serialization
  // ==========================================
  static Map<String, dynamic> projectToJson(CanvasProject project) {
    return {
      'id': project.id,
      'name': project.name,
      'description': project.description,
      'activePageIndex': project.activePageIndex,
      'coverPageIndex': project.coverPageIndex,
      'createdAt': project.createdAt.toIso8601String(),
      'updatedAt': project.updatedAt.toIso8601String(),
      'pages': project.pages.map(pageToJson).toList(),
      'components': project.components.map(componentToJson).toList(),
    };
  }

  static CanvasProject projectFromJson(Map<String, dynamic> json) {
    return CanvasProject(
      id: json['id'] as String? ?? 'proj-${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Untitled Project',
      description: json['description'] as String? ?? '',
      activePageIndex: json['activePageIndex'] as int? ?? 0,
      coverPageIndex: json['coverPageIndex'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      pages: (json['pages'] as List<dynamic>?)
              ?.map((p) => pageFromJson(p as Map<String, dynamic>))
              .toList() ??
          const [],
      components: (json['components'] as List<dynamic>?)
              ?.map((c) => componentFromJson(c as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  // ==========================================
  // Page Serialization
  // ==========================================
  static Map<String, dynamic> pageToJson(CanvasPage page) {
    return {
      'id': page.id,
      'name': page.name,
      'width': page.width,
      'height': page.height,
      'backgroundType': page.backgroundType.name,
      'backgroundColor': page.backgroundColor.toARGB32(),
      'backgroundGradient': gradientToJson(page.backgroundGradient),
      'backgroundImagePath': page.backgroundImagePath,
      'showGrid': page.showGrid,
      'showGuides': page.showGuides,
      'showSafeArea': page.showSafeArea,
      'horizontalPadding': page.horizontalPadding,
      'verticalPadding': page.verticalPadding,
      'layers': page.layers.map(layerToJson).toList(),
    };
  }

  static CanvasPage pageFromJson(Map<String, dynamic> json) {
    return CanvasPage(
      id: json['id'] as String? ?? 'page-1',
      name: json['name'] as String? ?? 'Page',
      width: (json['width'] as num?)?.toDouble() ?? 1080.0,
      height: (json['height'] as num?)?.toDouble() ?? 1080.0,
      backgroundType: BackgroundType.values.firstWhere(
        (b) => b.name == json['backgroundType'],
        orElse: () => BackgroundType.gradient,
      ),
      backgroundColor: json['backgroundColor'] != null
          ? Color(json['backgroundColor'] as int)
          : const Color(0xFF0D0B14),
      backgroundGradient: gradientFromJson(json['backgroundGradient'] as Map<String, dynamic>?),
      backgroundImagePath: json['backgroundImagePath'] as String?,
      showGrid: json['showGrid'] as bool? ?? false,
      showGuides: json['showGuides'] as bool? ?? false,
      showSafeArea: json['showSafeArea'] as bool? ?? false,
      horizontalPadding: (json['horizontalPadding'] as num?)?.toDouble() ?? 20.0,
      verticalPadding: (json['verticalPadding'] as num?)?.toDouble() ?? 20.0,
      layers: (json['layers'] as List<dynamic>?)
              ?.map((l) => layerFromJson(l as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  // ==========================================
  // Layer Serialization Dispatcher
  // ==========================================
  static Map<String, dynamic> layerToJson(Layer layer) {
    final base = <String, dynamic>{
      'id': layer.id,
      'name': layer.name,
      'type': layer.type.name,
      'x': layer.x,
      'y': layer.y,
      'width': layer.width,
      'height': layer.height,
      'rotation': layer.rotation,
      'opacity': layer.opacity,
      'zIndex': layer.zIndex,
      'visible': layer.visible,
      'locked': layer.locked,
      'scale': layer.scale,
    };

    if (layer is ShapeLayer) {
      base.addAll({
        'shapeType': layer.shapeType.name,
        'fill': layer.fill.toARGB32(),
        'gradient': gradientToJson(layer.gradient),
        'strokeColor': layer.strokeColor?.toARGB32(),
        'strokeWidth': layer.strokeWidth,
        'cornerRadius': layer.cornerRadius,
        'shadows': layer.shadows?.map(boxShadowToJson).toList(),
        'strokePosition': layer.strokePosition.name,
        'startHead': layer.startHead.name,
        'endHead': layer.endHead.name,
      });
    } else if (layer is TextLayer) {
      base.addAll({
        'content': layer.content,
        'fontFamily': layer.fontFamily,
        'fontSize': layer.fontSize,
        'fontWeight': layer.fontWeight.value,
        'fontStyle': layer.fontStyle.name,
        'color': layer.color.toARGB32(),
        'letterSpacing': layer.letterSpacing,
        'lineHeight': layer.lineHeight,
        'textAlign': layer.textAlign.name,
        'decoration': layer.decoration?.toString(),
        'shadows': layer.shadows?.map(shadowToJson).toList(),
        'strokeColor': layer.strokeColor?.toARGB32(),
        'strokeWidth': layer.strokeWidth,
        'backgroundColor': layer.backgroundColor?.toARGB32(),
        'backgroundRadius': layer.backgroundRadius,
        'padding': edgeInsetsToJson(layer.padding),
        'textGradient': gradientToJson(layer.textGradient),
      });
    } else if (layer is ImageLayer) {
      base.addAll({
        'imagePath': layer.imagePath,
        'assetPath': layer.assetPath,
        'svgContent': layer.svgContent,
        'tintColor': layer.tintColor?.toARGB32(),
        'fit': layer.fit.name,
        'borderRadius': layer.borderRadius,
        'borderColor': layer.borderColor?.toARGB32(),
        'borderWidth': layer.borderWidth,
        'shadows': layer.shadows?.map(boxShadowToJson).toList(),
      });
    } else if (layer is DeviceMockupLayer) {
      base.addAll({
        'device': layer.device.name,
        'screenImagePath': layer.screenImagePath,
        'frameColor': layer.frameColor.toARGB32(),
        'screenBackgroundColor': layer.screenBackgroundColor.toARGB32(),
        'cornerRadius': layer.cornerRadius,
        'showShadow': layer.showShadow,
        'showHeader': layer.showHeader,
        'title': layer.title,
        'imageFit': layer.imageFit.name,
        'imageOffsetX': layer.imageOffsetX,
        'imageOffsetY': layer.imageOffsetY,
        'imageScale': layer.imageScale,
        'showGlare': layer.showGlare,
        'showDynamicIsland': layer.showDynamicIsland,
      });
    } else if (layer is AutoLayoutLayer) {
      base.addAll({
        'direction': layer.direction.name,
        'gap': layer.gap,
        'paddingHorizontal': layer.paddingHorizontal,
        'paddingVertical': layer.paddingVertical,
        'alignment': layer.alignment.name,
        'distribution': layer.distribution.name,
        'horizontalSizing': layer.horizontalSizing.name,
        'verticalSizing': layer.verticalSizing.name,
        'backgroundColor': layer.backgroundColor?.toARGB32(),
        'cornerRadius': layer.cornerRadius,
        'strokeColor': layer.strokeColor?.toARGB32(),
        'strokeWidth': layer.strokeWidth,
        'strokePosition': layer.strokePosition.name,
        'clipContent': layer.clipContent,
        'children': layer.children.map(layerToJson).toList(),
      });
    } else if (layer is VectorLayer) {
      base.addAll({
        'elements': layer.elements.map(vectorPathElementToJson).toList(),
        'shadows': layer.shadows?.map(boxShadowToJson).toList(),
      });
    } else if (layer is IconLayer) {
      base.addAll({
        'iconCodePoint': layer.icon.codePoint,
        'iconFontFamily': layer.icon.fontFamily,
        'iconFontPackage': layer.icon.fontPackage,
        'color': layer.color.toARGB32(),
        'backgroundColor': layer.backgroundColor?.toARGB32(),
        'cornerRadius': layer.cornerRadius,
        'shadows': layer.shadows?.map(boxShadowToJson).toList(),
      });
    } else if (layer is ComponentInstanceLayer) {
      base.addAll({
        'componentDefinitionId': layer.componentDefinitionId,
        'variableOverrides': layer.variableOverrides,
      });
    }

    return base;
  }

  static Layer layerFromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'shape';
    final type = LayerType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => LayerType.shape,
    );

    final id = json['id'] as String? ?? 'layer-${DateTime.now().millisecondsSinceEpoch}';
    final name = json['name'] as String? ?? 'Layer';
    final x = (json['x'] as num?)?.toDouble() ?? 0.0;
    final y = (json['y'] as num?)?.toDouble() ?? 0.0;
    final width = (json['width'] as num?)?.toDouble() ?? 100.0;
    final height = (json['height'] as num?)?.toDouble() ?? 100.0;
    final rotation = (json['rotation'] as num?)?.toDouble() ?? 0.0;
    final opacity = (json['opacity'] as num?)?.toDouble() ?? 1.0;
    final zIndex = json['zIndex'] as int? ?? 0;
    final visible = json['visible'] as bool? ?? true;
    final locked = json['locked'] as bool? ?? false;
    final scale = (json['scale'] as num?)?.toDouble() ?? 1.0;

    switch (type) {
      case LayerType.shape:
        return ShapeLayer(
          id: id,
          name: name,
          x: x,
          y: y,
          width: width,
          height: height,
          rotation: rotation,
          opacity: opacity,
          zIndex: zIndex,
          visible: visible,
          locked: locked,
          scale: scale,
          shapeType: ShapeType.values.firstWhere(
            (s) => s.name == json['shapeType'],
            orElse: () => ShapeType.roundedRectangle,
          ),
          fill: json['fill'] != null ? Color(json['fill'] as int) : const Color(0xFF1D1E24),
          gradient: gradientFromJson(json['gradient'] as Map<String, dynamic>?),
          strokeColor: json['strokeColor'] != null ? Color(json['strokeColor'] as int) : null,
          strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 0.0,
          cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 12.0,
          shadows: (json['shadows'] as List<dynamic>?)
              ?.map((s) => boxShadowFromJson(s as Map<String, dynamic>))
              .toList(),
          strokePosition: StrokePosition.values.firstWhere(
            (sp) => sp.name == json['strokePosition'],
            orElse: () => StrokePosition.center,
          ),
          startHead: ArrowHeadStyle.values.firstWhere(
            (a) => a.name == json['startHead'],
            orElse: () => ArrowHeadStyle.none,
          ),
          endHead: ArrowHeadStyle.values.firstWhere(
            (a) => a.name == json['endHead'],
            orElse: () => ArrowHeadStyle.lineArrow,
          ),
        );

      case LayerType.text:
        final weightVal = json['fontWeight'] as int? ?? 600;
        final fontWeight = FontWeight.values.firstWhere(
          (w) => w.value == weightVal,
          orElse: () => FontWeight.w600,
        );

        return TextLayer(
          id: id,
          name: name,
          x: x,
          y: y,
          width: width,
          height: height,
          rotation: rotation,
          opacity: opacity,
          zIndex: zIndex,
          visible: visible,
          locked: locked,
          scale: scale,
          content: json['content'] as String? ?? '',
          fontFamily: json['fontFamily'] as String? ?? 'Inter',
          fontSize: (json['fontSize'] as num?)?.toDouble() ?? 28.0,
          fontWeight: fontWeight,
          fontStyle: json['fontStyle'] == 'italic' ? FontStyle.italic : FontStyle.normal,
          color: json['color'] != null ? Color(json['color'] as int) : Colors.white,
          letterSpacing: (json['letterSpacing'] as num?)?.toDouble() ?? -0.2,
          lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.2,
          textAlign: TextAlign.values.firstWhere(
            (t) => t.name == json['textAlign'],
            orElse: () => TextAlign.left,
          ),
          decoration: _parseTextDecoration(json['decoration'] as String?),
          shadows: (json['shadows'] as List<dynamic>?)
              ?.map((s) => shadowFromJson(s as Map<String, dynamic>))
              .toList(),
          strokeColor: json['strokeColor'] != null ? Color(json['strokeColor'] as int) : null,
          strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 0.0,
          backgroundColor:
              json['backgroundColor'] != null ? Color(json['backgroundColor'] as int) : null,
          backgroundRadius: (json['backgroundRadius'] as num?)?.toDouble() ?? 6.0,
          padding: edgeInsetsFromJson(json['padding'] as Map<String, dynamic>?),
          textGradient: gradientFromJson(json['textGradient'] as Map<String, dynamic>?),
        );

      case LayerType.image:
        return ImageLayer(
          id: id,
          name: name,
          x: x,
          y: y,
          width: width,
          height: height,
          rotation: rotation,
          opacity: opacity,
          zIndex: zIndex,
          visible: visible,
          locked: locked,
          scale: scale,
          imagePath: json['imagePath'] as String?,
          assetPath: json['assetPath'] as String?,
          svgContent: json['svgContent'] as String?,
          tintColor: json['tintColor'] != null ? Color(json['tintColor'] as int) : null,
          fit: BoxFit.values.firstWhere(
            (f) => f.name == json['fit'],
            orElse: () => BoxFit.cover,
          ),
          borderRadius: (json['borderRadius'] as num?)?.toDouble() ?? 12.0,
          borderColor: json['borderColor'] != null ? Color(json['borderColor'] as int) : null,
          borderWidth: (json['borderWidth'] as num?)?.toDouble() ?? 0.0,
          shadows: (json['shadows'] as List<dynamic>?)
              ?.map((s) => boxShadowFromJson(s as Map<String, dynamic>))
              .toList(),
        );

      case LayerType.deviceMockup:
        return DeviceMockupLayer(
          id: id,
          name: name,
          x: x,
          y: y,
          width: width,
          height: height,
          rotation: rotation,
          opacity: opacity,
          zIndex: zIndex,
          visible: visible,
          locked: locked,
          scale: scale,
          device: MockupDevice.values.firstWhere(
            (d) => d.name == json['device'],
            orElse: () => MockupDevice.iphone17ProMax,
          ),
          screenImagePath: json['screenImagePath'] as String?,
          frameColor: json['frameColor'] != null
              ? Color(json['frameColor'] as int)
              : const Color(0xFF050507),
          screenBackgroundColor: json['screenBackgroundColor'] != null
              ? Color(json['screenBackgroundColor'] as int)
              : const Color(0xFFF5F5F7),
          cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 52.0,
          showShadow: json['showShadow'] as bool? ?? true,
          showHeader: json['showHeader'] as bool? ?? true,
          title: json['title'] as String?,
          imageFit: BoxFit.values.firstWhere(
            (f) => f.name == json['imageFit'],
            orElse: () => BoxFit.cover,
          ),
          imageOffsetX: (json['imageOffsetX'] as num?)?.toDouble() ?? 0.0,
          imageOffsetY: (json['imageOffsetY'] as num?)?.toDouble() ?? 0.0,
          imageScale: (json['imageScale'] as num?)?.toDouble() ?? 1.0,
          showGlare: json['showGlare'] as bool? ?? true,
          showDynamicIsland: json['showDynamicIsland'] as bool? ?? true,
        );

      case LayerType.autoLayout:
        return AutoLayoutLayer(
          id: id,
          name: name,
          x: x,
          y: y,
          width: width,
          height: height,
          rotation: rotation,
          opacity: opacity,
          zIndex: zIndex,
          visible: visible,
          locked: locked,
          scale: scale,
          direction: AutoLayoutDirection.values.firstWhere(
            (d) => d.name == json['direction'],
            orElse: () => AutoLayoutDirection.horizontal,
          ),
          gap: (json['gap'] as num?)?.toDouble() ?? 12.0,
          paddingHorizontal: (json['paddingHorizontal'] as num?)?.toDouble() ?? 16.0,
          paddingVertical: (json['paddingVertical'] as num?)?.toDouble() ?? 16.0,
          alignment: AutoLayoutAlignment.values.firstWhere(
            (a) => a.name == json['alignment'],
            orElse: () => AutoLayoutAlignment.center,
          ),
          distribution: AutoLayoutDistribution.values.firstWhere(
            (d) => d.name == json['distribution'],
            orElse: () => AutoLayoutDistribution.start,
          ),
          horizontalSizing: AutoLayoutSizingMode.values.firstWhere(
            (h) => h.name == json['horizontalSizing'],
            orElse: () => AutoLayoutSizingMode.hug,
          ),
          verticalSizing: AutoLayoutSizingMode.values.firstWhere(
            (v) => v.name == json['verticalSizing'],
            orElse: () => AutoLayoutSizingMode.hug,
          ),
          backgroundColor:
              json['backgroundColor'] != null ? Color(json['backgroundColor'] as int) : null,
          cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 12.0,
          strokeColor: json['strokeColor'] != null ? Color(json['strokeColor'] as int) : null,
          strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 0.0,
          strokePosition: StrokePosition.values.firstWhere(
            (sp) => sp.name == json['strokePosition'],
            orElse: () => StrokePosition.inside,
          ),
          clipContent: json['clipContent'] as bool? ?? false,
          children: (json['children'] as List<dynamic>?)
                  ?.map((c) => layerFromJson(c as Map<String, dynamic>))
                  .toList() ??
              const [],
        );

      case LayerType.vector:
        return VectorLayer(
          id: id,
          name: name,
          x: x,
          y: y,
          width: width,
          height: height,
          rotation: rotation,
          opacity: opacity,
          zIndex: zIndex,
          visible: visible,
          locked: locked,
          scale: scale,
          elements: (json['elements'] as List<dynamic>?)
                  ?.map((e) => vectorPathElementFromJson(e as Map<String, dynamic>))
                  .toList() ??
              const [],
          shadows: (json['shadows'] as List<dynamic>?)
              ?.map((s) => boxShadowFromJson(s as Map<String, dynamic>))
              .toList(),
        );

      case LayerType.icon:
        final codePoint = json['iconCodePoint'] as int? ?? Icons.check_circle_rounded.codePoint;
        final fontFamily = json['iconFontFamily'] as String? ?? 'MaterialIcons';
        final fontPackage = json['iconFontPackage'] as String?;
        return IconLayer(
          id: id,
          name: name,
          x: x,
          y: y,
          width: width,
          height: height,
          rotation: rotation,
          opacity: opacity,
          zIndex: zIndex,
          visible: visible,
          locked: locked,
          scale: scale,
          // ignore: non_const_argument_for_const_parameter
          icon: IconData(codePoint, fontFamily: fontFamily, fontPackage: fontPackage),
          color: json['color'] != null ? Color(json['color'] as int) : const Color(0xFFA970FF),
          backgroundColor:
              json['backgroundColor'] != null ? Color(json['backgroundColor'] as int) : null,
          cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 0.0,
          shadows: (json['shadows'] as List<dynamic>?)
              ?.map((s) => boxShadowFromJson(s as Map<String, dynamic>))
              .toList(),
        );

      case LayerType.group:
        return AutoLayoutLayer(
          id: id,
          name: name,
          x: x,
          y: y,
          width: width,
          height: height,
          rotation: rotation,
          opacity: opacity,
          zIndex: zIndex,
          visible: visible,
          locked: locked,
          scale: scale,
          children: (json['children'] as List<dynamic>?)
                  ?.map((c) => layerFromJson(c as Map<String, dynamic>))
                  .toList() ??
              const [],
        );

      case LayerType.componentInstance:
        return ComponentInstanceLayer(
          id: id,
          name: name,
          x: x,
          y: y,
          width: width,
          height: height,
          rotation: rotation,
          opacity: opacity,
          zIndex: zIndex,
          visible: visible,
          locked: locked,
          scale: scale,
          componentDefinitionId: json['componentDefinitionId'] as String? ?? '',
          variableOverrides: (json['variableOverrides'] as Map<String, dynamic>?) ?? const {},
        );
    }
  }

  // ==========================================
  // Vector Elements Serialization
  // ==========================================
  static Map<String, dynamic> vectorPathElementToJson(VectorPathElement elem) {
    return {
      'id': elem.id,
      'name': elem.name,
      'points': elem.points.map(vectorPointToJson).toList(),
      'fill': elem.fill?.toARGB32(),
      'strokeColor': elem.strokeColor?.toARGB32(),
      'strokeWidth': elem.strokeWidth,
      'strokeCap': elem.strokeCap.name,
      'strokeJoin': elem.strokeJoin.name,
      'opacity': elem.opacity,
      'isClosed': elem.isClosed,
      'visible': elem.visible,
    };
  }

  static VectorPathElement vectorPathElementFromJson(Map<String, dynamic> json) {
    return VectorPathElement(
      id: json['id'] as String? ?? 'elem-0',
      name: json['name'] as String? ?? 'Path',
      points: (json['points'] as List<dynamic>?)
              ?.map((p) => vectorPointFromJson(p as Map<String, dynamic>))
              .toList() ??
          const [],
      fill: json['fill'] != null ? Color(json['fill'] as int) : null,
      strokeColor: json['strokeColor'] != null ? Color(json['strokeColor'] as int) : null,
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 0.0,
      strokeCap: StrokeCap.values.firstWhere(
        (c) => c.name == json['strokeCap'],
        orElse: () => StrokeCap.round,
      ),
      strokeJoin: StrokeJoin.values.firstWhere(
        (j) => j.name == json['strokeJoin'],
        orElse: () => StrokeJoin.round,
      ),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      isClosed: json['isClosed'] as bool? ?? true,
      visible: json['visible'] as bool? ?? true,
    );
  }

  static Map<String, dynamic> vectorPointToJson(VectorPoint point) {
    return {
      'x': point.x,
      'y': point.y,
      'handleInX': point.handleInX,
      'handleInY': point.handleInY,
      'handleOutX': point.handleOutX,
      'handleOutY': point.handleOutY,
      'isSmooth': point.isSmooth,
    };
  }

  static VectorPoint vectorPointFromJson(Map<String, dynamic> json) {
    return VectorPoint(
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      handleInX: (json['handleInX'] as num?)?.toDouble(),
      handleInY: (json['handleInY'] as num?)?.toDouble(),
      handleOutX: (json['handleOutX'] as num?)?.toDouble(),
      handleOutY: (json['handleOutY'] as num?)?.toDouble(),
      isSmooth: json['isSmooth'] as bool? ?? false,
    );
  }

  // ==========================================
  // Component Definition Serialization
  // ==========================================
  static Map<String, dynamic> componentToJson(ComponentDefinition comp) {
    return {
      'id': comp.id,
      'name': comp.name,
      'description': comp.description,
      'width': comp.width,
      'height': comp.height,
      'layers': comp.layers.map(layerToJson).toList(),
      'defaultVariables': comp.defaultVariables,
    };
  }

  static ComponentDefinition componentFromJson(Map<String, dynamic> json) {
    return ComponentDefinition(
      id: json['id'] as String? ?? 'comp-0',
      name: json['name'] as String? ?? 'Component',
      description: json['description'] as String? ?? '',
      width: (json['width'] as num?)?.toDouble() ?? 100.0,
      height: (json['height'] as num?)?.toDouble() ?? 100.0,
      layers: (json['layers'] as List<dynamic>?)
              ?.map((l) => layerFromJson(l as Map<String, dynamic>))
              .toList() ??
          const [],
      defaultVariables: (json['defaultVariables'] as Map<String, dynamic>?) ?? const {},
    );
  }

  // ==========================================
  // Geometry & Visual Primitives Helpers
  // ==========================================
  static Map<String, dynamic>? gradientToJson(Gradient? gradient) {
    if (gradient == null) return null;
    if (gradient is LinearGradient) {
      return {
        'type': 'linear',
        'colors': gradient.colors.map((c) => c.toARGB32()).toList(),
        'stops': gradient.stops,
        'beginX': (gradient.begin as Alignment).x,
        'beginY': (gradient.begin as Alignment).y,
        'endX': (gradient.end as Alignment).x,
        'endY': (gradient.end as Alignment).y,
      };
    } else if (gradient is RadialGradient) {
      return {
        'type': 'radial',
        'colors': gradient.colors.map((c) => c.toARGB32()).toList(),
        'stops': gradient.stops,
        'centerX': (gradient.center as Alignment).x,
        'centerY': (gradient.center as Alignment).y,
        'radius': gradient.radius,
      };
    } else if (gradient is SweepGradient) {
      return {
        'type': 'sweep',
        'colors': gradient.colors.map((c) => c.toARGB32()).toList(),
        'stops': gradient.stops,
        'centerX': (gradient.center as Alignment).x,
        'centerY': (gradient.center as Alignment).y,
        'startAngle': gradient.startAngle,
        'endAngle': gradient.endAngle,
      };
    }
    return null;
  }

  static Gradient? gradientFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final type = json['type'] as String?;
    final colors = (json['colors'] as List<dynamic>?)
            ?.map((c) => Color(c as int))
            .toList() ??
        [Colors.black, Colors.white];
    final stops = (json['stops'] as List<dynamic>?)?.map((s) => (s as num).toDouble()).toList();

    if (type == 'radial') {
      final cx = (json['centerX'] as num?)?.toDouble() ?? 0.0;
      final cy = (json['centerY'] as num?)?.toDouble() ?? 0.0;
      final radius = (json['radius'] as num?)?.toDouble() ?? 1.0;
      return RadialGradient(
        center: Alignment(cx, cy),
        radius: radius,
        colors: colors,
        stops: stops,
      );
    } else if (type == 'sweep') {
      final cx = (json['centerX'] as num?)?.toDouble() ?? 0.0;
      final cy = (json['centerY'] as num?)?.toDouble() ?? 0.0;
      final startAngle = (json['startAngle'] as num?)?.toDouble() ?? 0.0;
      final endAngle = (json['endAngle'] as num?)?.toDouble() ?? 6.283;
      return SweepGradient(
        center: Alignment(cx, cy),
        startAngle: startAngle,
        endAngle: endAngle,
        colors: colors,
        stops: stops,
      );
    } else {
      final bx = (json['beginX'] as num?)?.toDouble() ?? 0.0;
      final by = (json['beginY'] as num?)?.toDouble() ?? -1.0;
      final ex = (json['endX'] as num?)?.toDouble() ?? 0.0;
      final ey = (json['endY'] as num?)?.toDouble() ?? 1.0;
      return LinearGradient(
        begin: Alignment(bx, by),
        end: Alignment(ex, ey),
        colors: colors,
        stops: stops,
      );
    }
  }

  static Map<String, dynamic> boxShadowToJson(BoxShadow shadow) {
    return {
      'color': shadow.color.toARGB32(),
      'offsetX': shadow.offset.dx,
      'offsetY': shadow.offset.dy,
      'blurRadius': shadow.blurRadius,
      'spreadRadius': shadow.spreadRadius,
    };
  }

  static BoxShadow boxShadowFromJson(Map<String, dynamic> json) {
    return BoxShadow(
      color: json['color'] != null ? Color(json['color'] as int) : Colors.black45,
      offset: Offset(
        (json['offsetX'] as num?)?.toDouble() ?? 0.0,
        (json['offsetY'] as num?)?.toDouble() ?? 4.0,
      ),
      blurRadius: (json['blurRadius'] as num?)?.toDouble() ?? 12.0,
      spreadRadius: (json['spreadRadius'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static Map<String, dynamic> shadowToJson(Shadow shadow) {
    return {
      'color': shadow.color.toARGB32(),
      'offsetX': shadow.offset.dx,
      'offsetY': shadow.offset.dy,
      'blurRadius': shadow.blurRadius,
    };
  }

  static Shadow shadowFromJson(Map<String, dynamic> json) {
    return Shadow(
      color: json['color'] != null ? Color(json['color'] as int) : Colors.black45,
      offset: Offset(
        (json['offsetX'] as num?)?.toDouble() ?? 0.0,
        (json['offsetY'] as num?)?.toDouble() ?? 2.0,
      ),
      blurRadius: (json['blurRadius'] as num?)?.toDouble() ?? 4.0,
    );
  }

  static Map<String, dynamic> edgeInsetsToJson(EdgeInsets insets) {
    return {
      'left': insets.left,
      'top': insets.top,
      'right': insets.right,
      'bottom': insets.bottom,
    };
  }

  static EdgeInsets edgeInsetsFromJson(Map<String, dynamic>? json) {
    if (json == null) return EdgeInsets.zero;
    return EdgeInsets.fromLTRB(
      (json['left'] as num?)?.toDouble() ?? 0.0,
      (json['top'] as num?)?.toDouble() ?? 0.0,
      (json['right'] as num?)?.toDouble() ?? 0.0,
      (json['bottom'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static TextDecoration? _parseTextDecoration(String? dec) {
    if (dec == null) return null;
    if (dec.contains('underline')) return TextDecoration.underline;
    if (dec.contains('lineThrough')) return TextDecoration.lineThrough;
    if (dec.contains('overline')) return TextDecoration.overline;
    return null;
  }
}
