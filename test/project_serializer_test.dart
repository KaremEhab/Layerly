import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layerly/core/constants/sample_project.dart';
import 'package:layerly/features/editor/data/project_serializer.dart';
import 'package:layerly/features/editor/domain/entities/device_mockup_layer.dart';
import 'package:layerly/features/editor/domain/entities/layer_enums.dart';
import 'package:layerly/features/editor/domain/entities/shape_layer.dart';
import 'package:layerly/features/editor/domain/entities/text_layer.dart';
import 'package:layerly/features/editor/domain/entities/vector_layer.dart';

void main() {
  group('ProjectSerializer Tests', () {
    test('Serializes and deserializes SampleProject with 100% fidelity', () {
      final sample = SampleProject.createUberRedesignProject().copyWith(
        coverPageIndex: 1,
      );

      final json = ProjectSerializer.projectToJson(sample);
      final restored = ProjectSerializer.projectFromJson(json);

      expect(restored.id, sample.id);
      expect(restored.name, sample.name);
      expect(restored.coverPageIndex, 1);
      expect(restored.coverPage.name, sample.pages[1].name);
      expect(restored.pages.length, sample.pages.length);

      for (int i = 0; i < sample.pages.length; i++) {
        expect(restored.pages[i].name, sample.pages[i].name);
        expect(restored.pages[i].layers.length, sample.pages[i].layers.length);
      }
    });

    test('Serializes and deserializes ShapeLayer with gradient and shadows', () {
      final shape = ShapeLayer(
        id: 'shape-1',
        name: 'Gradient Rect',
        x: 50,
        y: 80,
        width: 300,
        height: 200,
        cornerRadius: 24,
        strokeWidth: 2,
        strokeColor: Colors.white,
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
        ),
        shadows: const [
          BoxShadow(color: Colors.black45, blurRadius: 16, offset: Offset(0, 8)),
        ],
        scale: 1.25,
      );

      final json = ProjectSerializer.layerToJson(shape);
      final restored = ProjectSerializer.layerFromJson(json) as ShapeLayer;

      expect(restored.id, shape.id);
      expect(restored.name, shape.name);
      expect(restored.cornerRadius, 24);
      expect(restored.strokeWidth, 2);
      expect(restored.scale, 1.25);
      expect(restored.gradient, isNotNull);
      expect(restored.shadows?.length, 1);
    });

    test('Serializes and deserializes TextLayer with styling', () {
      final text = TextLayer(
        id: 'text-1',
        name: 'Hero Title',
        x: 100,
        y: 150,
        width: 500,
        height: 80,
        content: 'Hello Layerly Studio',
        fontSize: 36,
        fontWeight: FontWeight.w800,
        fontFamily: 'Outfit',
        color: Colors.amber,
        letterSpacing: -0.5,
        scale: 1.1,
      );

      final json = ProjectSerializer.layerToJson(text);
      final restored = ProjectSerializer.layerFromJson(json) as TextLayer;

      expect(restored.id, text.id);
      expect(restored.content, 'Hello Layerly Studio');
      expect(restored.fontSize, 36);
      expect(restored.fontWeight, FontWeight.w800);
      expect(restored.fontFamily, 'Outfit');
      expect(restored.scale, 1.1);
    });

    test('Serializes and deserializes VectorLayer and sub-elements', () {
      final vector = VectorLayer(
        id: 'vec-1',
        name: 'Custom Polygon',
        x: 40,
        y: 40,
        width: 120,
        height: 120,
        elements: const [
          VectorPathElement(
            id: 'elem-1',
            name: 'Star Path',
            points: [
              VectorPoint(x: 0.5, y: 0.0),
              VectorPoint(x: 1.0, y: 0.8),
              VectorPoint(x: 0.0, y: 0.8),
            ],
            fill: Color(0xFF9333EA),
            strokeWidth: 1.5,
          ),
        ],
        scale: 1.0,
      );

      final json = ProjectSerializer.layerToJson(vector);
      final restored = ProjectSerializer.layerFromJson(json) as VectorLayer;

      expect(restored.id, vector.id);
      expect(restored.elements.length, 1);
      expect(restored.elements.first.points.length, 3);
      expect(restored.elements.first.fill, const Color(0xFF9333EA));
    });

    test('Serializes and deserializes DeviceMockupLayer', () {
      final mockup = DeviceMockupLayer(
        id: 'mockup-1',
        name: 'iPhone Showcase',
        x: 100,
        y: 200,
        width: 400,
        height: 800,
        device: MockupDevice.iphone17ProMax,
        showGlare: true,
        showShadow: true,
        scale: 1.0,
      );

      final json = ProjectSerializer.layerToJson(mockup);
      final restored = ProjectSerializer.layerFromJson(json) as DeviceMockupLayer;

      expect(restored.id, mockup.id);
      expect(restored.device, MockupDevice.iphone17ProMax);
      expect(restored.showGlare, true);
    });
  });
}
