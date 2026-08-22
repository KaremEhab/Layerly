import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:layerly/core/constants/app_colors.dart';
import 'package:layerly/core/utils/text_span_parser.dart';
import 'package:layerly/features/editor/domain/entities/canvas_page.dart';
import 'package:layerly/features/editor/domain/entities/canvas_project.dart';
import 'package:layerly/features/editor/domain/entities/component_definition.dart';
import 'package:layerly/features/editor/domain/entities/component_instance_layer.dart';
import 'package:layerly/features/editor/domain/entities/layer_enums.dart';
import 'package:layerly/features/editor/domain/entities/text_layer.dart';
import 'package:layerly/features/editor/domain/entities/shape_layer.dart';
import 'package:layerly/features/editor/domain/entities/auto_layout_layer.dart';
import 'package:layerly/features/editor/domain/services/snapping_service.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_bloc.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_event.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Editor Engine Domain & Logic Tests', () {
    late CanvasProject project;
    late ComponentDefinition footerComponent;

    setUp(() {
      footerComponent = const ComponentDefinition(
        id: 'comp-footer',
        name: 'Profile Footer',
        description: 'Branded footer with pagination',
        width: 440,
        height: 60,
        layers: [
          TextLayer(
            id: 'footer-text',
            name: 'Handle',
            x: 0,
            y: 0,
            width: 200,
            height: 30,
            content: '@kareem.designs_',
          ),
        ],
      );

      final page1 = CanvasPage(
        id: 'page-1',
        name: '01 - Cover',
        width: 1080,
        height: 1080,
        layers: [
          const TextLayer(
            id: 'txt-1',
            name: 'Heading',
            x: 80,
            y: 120,
            width: 500,
            height: 80,
            content: 'I redesigned Uber Eats screen.',
          ),
          const ShapeLayer(
            id: 'shp-1',
            name: 'Card',
            x: 80,
            y: 240,
            width: 400,
            height: 200,
            fill: AppColors.surface,
          ),
          const ComponentInstanceLayer(
            id: 'instance-1',
            name: 'Profile Footer Instance',
            componentDefinitionId: 'comp-footer',
            x: 80,
            y: 900,
            width: 440,
            height: 60,
          ),
        ],
      );

      project = CanvasProject(
        id: 'proj-1',
        name: 'Uber Redesign',
        pages: [page1],
        components: [footerComponent],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    test('SnappingService snaps within threshold to canvas center', () {
      final page = project.pages.first;
      final result = SnappingService.calculateSnap(
        targetX: 492.0, // 2px off center (540 - 100/2 = 490)
        targetY: 100.0,
        targetWidth: 100.0,
        targetHeight: 100.0,
        page: page,
        excludeLayerIds: [],
      );

      expect(result.snappedX, 490.0);
      expect(result.activeGuides.isNotEmpty, true);
    });

    test('EditorBloc adds, selects, and transforms layers with Undo/Redo', () async {
      final bloc = EditorBloc(initialProject: project);

      // Select Layer
      bloc.add(const SelectLayerEvent('txt-1'));
      await Future.delayed(Duration.zero);
      expect(bloc.state.selectedLayerIds, ['txt-1']);
      expect(bloc.state.singleSelectedLayer?.name, 'Heading');

      // Move Layer
      bloc.add(const MoveLayerDeltaEvent(
        layerId: 'txt-1',
        dx: 20,
        dy: 30,
        isFinal: true,
      ));
      await Future.delayed(Duration.zero);

      final movedLayer = bloc.state.activePage.layers.firstWhere((l) => l.id == 'txt-1');
      expect(movedLayer.x, closeTo(100.0, 5.0));
      expect(movedLayer.y, 150.0);
      expect(bloc.state.canUndo, true);

      // Undo
      bloc.add(const UndoEvent());
      await Future.delayed(Duration.zero);
      final undoneLayer = bloc.state.activePage.layers.firstWhere((l) => l.id == 'txt-1');
      expect(undoneLayer.x, 80.0);
      expect(undoneLayer.y, 120.0);
      expect(bloc.state.canRedo, true);

      // Redo
      bloc.add(const RedoEvent());
      await Future.delayed(Duration.zero);
      final redoneLayer = bloc.state.activePage.layers.firstWhere((l) => l.id == 'txt-1');
      expect(redoneLayer.x, closeTo(100.0, 5.0));
      expect(redoneLayer.y, 150.0);
    });

    test('EditorBloc clamps moving layers within page padding margins', () async {
      final bloc = EditorBloc(initialProject: project);

      // Try moving layer far off the top-left beyond page margins
      bloc.add(const MoveLayerDeltaEvent(
        layerId: 'txt-1',
        dx: -500,
        dy: -500,
        isFinal: true,
      ));
      await Future.delayed(Duration.zero);

      final movedLayer = bloc.state.activePage.layers.firstWhere((l) => l.id == 'txt-1');
      expect(movedLayer.x, bloc.state.activePage.horizontalPadding);
      expect(movedLayer.y, bloc.state.activePage.verticalPadding);
    });

    test('EditorBloc dynamically shifts layers when page padding updates', () async {
      final bloc = EditorBloc(initialProject: project);
      final initialLayer = bloc.state.activePage.layers.firstWhere((l) => l.id == 'txt-1');
      expect(initialLayer.x, 80.0);

      // Change horizontal padding from 20 to 15 (delta = -5)
      bloc.add(const UpdatePagePaddingEvent(horizontal: 15, vertical: 15));
      await Future.delayed(Duration.zero);

      final shiftedLayer = bloc.state.activePage.layers.firstWhere((l) => l.id == 'txt-1');
      expect(shiftedLayer.x, 75.0);
      expect(bloc.state.activePage.horizontalPadding, 15.0);
    });

    test('EditorBloc supports multi-page carousel workflows', () async {
      final bloc = EditorBloc(initialProject: project);
      expect(bloc.state.project.pages.length, 1);

      // Add second page
      bloc.add(const AddPageEvent());
      await Future.delayed(Duration.zero);
      expect(bloc.state.project.pages.length, 2);
      expect(bloc.state.project.activePageIndex, 1);

      // Duplicate page
      bloc.add(const DuplicatePageEvent(0));
      await Future.delayed(Duration.zero);
      expect(bloc.state.project.pages.length, 3);
      expect(bloc.state.project.activePageIndex, 2);
      expect(bloc.state.project.pages.last.name, 'Cover Copy');
    });

    test('EditorBloc creates Auto Layout container from multi-selection', () async {
      final bloc = EditorBloc(initialProject: project);

      // Select both txt-1 and shp-1
      bloc.add(const SelectLayerEvent('txt-1', isMultiSelect: true));
      bloc.add(const SelectLayerEvent('shp-1', isMultiSelect: true));
      await Future.delayed(Duration.zero);
      expect(bloc.state.selectedLayerIds.length, 2);

      // Create Auto Layout
      bloc.add(const CreateAutoLayoutFromSelectionEvent());
      await Future.delayed(Duration.zero);

      expect(bloc.state.selectedLayerIds.length, 1);
      final autoLayout = bloc.state.singleSelectedLayer;
      expect(autoLayout, isNotNull);
      expect(autoLayout!.type, LayerType.autoLayout);

      // Remove Auto Layout -> Unpacks children at exact computed positions
      bloc.add(RemoveAutoLayoutEvent(autoLayout.id));
      await Future.delayed(Duration.zero);

      expect(bloc.state.selectedLayerIds.length, 2);
      expect(bloc.state.activePage.layers.any((l) => l.id == 'txt-1'), isTrue);
      expect(bloc.state.activePage.layers.any((l) => l.id == 'shp-1'), isTrue);
      expect(bloc.state.activePage.layers.any((l) => l.id == autoLayout.id), isFalse);
    });

    test('EditorBloc smartly detects vertical layout for vertically stacked elements', () async {
      final item1 = ShapeLayer(id: 'i1', name: 'Item 1', x: 80, y: 100, width: 300, height: 40);
      final item2 = ShapeLayer(id: 'i2', name: 'Item 2', x: 80, y: 160, width: 300, height: 40);
      final item3 = ShapeLayer(id: 'i3', name: 'Item 3', x: 80, y: 220, width: 300, height: 40);

      final customProject = project.copyWith(
        pages: [
          project.pages[0].copyWith(layers: [item1, item2, item3]),
        ],
      );

      final bloc = EditorBloc(initialProject: customProject);
      bloc.add(const SelectLayerEvent('i1', isMultiSelect: true));
      bloc.add(const SelectLayerEvent('i2', isMultiSelect: true));
      bloc.add(const SelectLayerEvent('i3', isMultiSelect: true));
      await Future.delayed(Duration.zero);

      bloc.add(const CreateAutoLayoutFromSelectionEvent());
      await Future.delayed(Duration.zero);

      final layout = bloc.state.singleSelectedLayer as AutoLayoutLayer;
      expect(layout.direction, AutoLayoutDirection.vertical);
      expect(layout.children.length, 3);
      expect(layout.gap, 20.0);
      expect(layout.height, 160.0); // 40 + 20 + 40 + 20 + 40

      // Update gap from 20 to 16
      bloc.add(UpdateAutoLayoutEvent(layerId: layout.id, gap: 16.0));
      await Future.delayed(Duration.zero);

      final updatedLayout = bloc.state.singleSelectedLayer as AutoLayoutLayer;
      expect(updatedLayout.gap, 16.0);
      expect(updatedLayout.height, 152.0); // 40 + 16 + 40 + 16 + 40 (shrinks automatically!)

      // Select nested child directly (Figma-style dive in)
      bloc.add(const SelectLayerEvent('i2'));
      await Future.delayed(Duration.zero);

      final selectedChild = bloc.state.singleSelectedLayer;
      expect(selectedChild, isNotNull);
      expect(selectedChild!.id, 'i2');
      expect(selectedChild.name, 'Item 2');
    });

    test('EditorBloc dynamically recalculates TextLayer bounds to hug text when font size changes', () async {
      final textLayer = TextLayer(
        id: 't-hug',
        name: 'Heading',
        content: 'Hello World',
        x: 50,
        y: 50,
        width: 100,
        height: 20,
        fontSize: 16,
      );

      final customProject = project.copyWith(
        pages: [
          project.pages[0].copyWith(layers: [textLayer]),
        ],
      );

      final bloc = EditorBloc(initialProject: customProject);
      
      // Update font size from 16 to 48
      bloc.add(UpdateLayerEvent(textLayer.copyWith(fontSize: 48)));
      await Future.delayed(Duration.zero);

      final updatedText = bloc.state.activePage.layers.firstWhere((l) => l.id == 't-hug') as TextLayer;
      expect(updatedText.fontSize, 48.0);
      expect(updatedText.width > 150.0, isTrue); // Auto-expands to hug large text
      expect(updatedText.height > 40.0, isTrue);
    });

    test('EditorBloc moves layers in tree and inside/outside Auto Layout containers', () async {
      final bloc = EditorBloc(initialProject: project);

      // Create Auto Layout from txt-1
      bloc.add(const SelectLayerEvent('txt-1'));
      bloc.add(const CreateAutoLayoutFromSelectionEvent());
      await Future.delayed(Duration.zero);

      final autoLayout = bloc.state.activePage.layers.firstWhere((l) => l is AutoLayoutLayer) as AutoLayoutLayer;
      expect(autoLayout.children.length, 1);

      // Move shp-1 from root into the autoLayout container
      bloc.add(MoveLayerTreeEvent(
        layerId: 'shp-1',
        targetParentId: autoLayout.id,
        targetIndex: 1,
      ));
      await Future.delayed(Duration.zero);

      final updatedAutoLayout = bloc.state.activePage.layers.firstWhere((l) => l is AutoLayoutLayer) as AutoLayoutLayer;
      expect(updatedAutoLayout.children.length, 2);
      expect(updatedAutoLayout.children.any((c) => c.id == 'shp-1'), isTrue);
      expect(bloc.state.activePage.layers.any((l) => l.id == 'shp-1'), isFalse);

      // Move shp-1 back out to top-level
      bloc.add(const MoveLayerTreeEvent(
        layerId: 'shp-1',
        targetParentId: null,
        targetIndex: 0,
      ));
      await Future.delayed(Duration.zero);

      expect(bloc.state.activePage.layers.any((l) => l.id == 'shp-1'), isTrue);
      final finalAutoLayout = bloc.state.activePage.layers.firstWhere((l) => l is AutoLayoutLayer) as AutoLayoutLayer;
      expect(finalAutoLayout.children.length, 1);
    });

    test('EditorBloc renames project and page', () async {
      final bloc = EditorBloc(initialProject: project);

      bloc.add(const RenameProjectEvent('New Design System'));
      await Future.delayed(Duration.zero);
      expect(bloc.state.project.name, 'New Design System');

      bloc.add(const RenamePageEvent(0, 'Hero Screen'));
      await Future.delayed(Duration.zero);
      expect(bloc.state.project.pages[0].name, 'Hero Screen');
    });

    test('SnappingService calculates equal spacing and distance measurements', () {
      final pageWithItems = CanvasPage(
        id: 'page-spacing',
        name: 'Spacing Test Page',
        width: 1080,
        height: 1080,
        layers: [
          const ShapeLayer(
            id: 'item-1',
            name: 'Frame 2646',
            x: 100,
            y: 100,
            width: 200,
            height: 50,
          ),
          const ShapeLayer(
            id: 'item-2',
            name: 'Frame 2647',
            x: 100,
            y: 220, // gap = 220 - (100 + 50) = 70
            width: 200,
            height: 50,
          ),
        ],
      );

      // Target item dragged near equal gap (y around 340 => target gap around 70)
      final snap = SnappingService.calculateSnap(
        targetX: 100,
        targetY: 338, // 338 - 270 = 68, close to 70
        targetWidth: 200,
        targetHeight: 50,
        page: pageWithItems,
        excludeLayerIds: ['target-item'],
      );

      // Snapped to exact equal gap of 70
      expect(snap.snappedY, 340.0);
      expect(snap.spacingMeasurements.isNotEmpty, isTrue);
      expect(snap.spacingMeasurements.first.distance, 70.0);
    });

    test('EditorBloc selects multiple layers with SelectMultipleLayersEvent', () async {
      final bloc = EditorBloc(initialProject: project);
      expect(bloc.state.selectedLayerIds.isEmpty, isTrue);

      bloc.add(const SelectMultipleLayersEvent(['txt-1', 'shp-1']));
      await Future.delayed(Duration.zero);

      expect(bloc.state.selectedLayerIds.length, 2);
      expect(bloc.state.selectedLayerIds, containsAll(['txt-1', 'shp-1']));
    });

    test('EditorBloc supports Auto Layout Sizing Modes (hug, fill, fixed)', () async {
      const autoLayout = AutoLayoutLayer(
        id: 'al-test',
        name: 'Card Layout',
        x: 20,
        y: 20,
        width: 100,
        height: 100,
        horizontalSizing: AutoLayoutSizingMode.hug,
        verticalSizing: AutoLayoutSizingMode.hug,
        paddingHorizontal: 10,
        paddingVertical: 10,
        gap: 8,
        children: [
          ShapeLayer(id: 'c1', name: 'Child 1', x: 0, y: 0, width: 60, height: 30),
          ShapeLayer(id: 'c2', name: 'Child 2', x: 0, y: 0, width: 80, height: 40),
        ],
      );

      final customProject = project.copyWith(
        pages: [
          project.pages[0].copyWith(layers: [autoLayout]),
        ],
      );

      final bloc = EditorBloc(initialProject: customProject);

      // 1. Initial Hug sizing
      final initialLayout = bloc.state.activePage.layers.first as AutoLayoutLayer;
      expect(initialLayout.horizontalSizing, AutoLayoutSizingMode.hug);
      expect(initialLayout.verticalSizing, AutoLayoutSizingMode.hug);

      // 2. Change width sizing to fixed 320
      bloc.add(const UpdateAutoLayoutEvent(
        layerId: 'al-test',
        horizontalSizing: AutoLayoutSizingMode.fixed,
      ));
      await Future.delayed(Duration.zero);

      final fixedLayout = bloc.state.activePage.layers.first as AutoLayoutLayer;
      // 3. Change width sizing to fill (takes full page margin width: 1080 - 2 * 60 = 960)
      bloc.add(const UpdateAutoLayoutEvent(
        layerId: 'al-test',
        horizontalSizing: AutoLayoutSizingMode.fill,
      ));
      await Future.delayed(Duration.zero);

      final fillWLayout = bloc.state.activePage.layers.first as AutoLayoutLayer;
      expect(fillWLayout.horizontalSizing, AutoLayoutSizingMode.fill);
      final expectedWidth = bloc.state.activePage.width - bloc.state.activePage.horizontalPadding * 2;
      expect(fillWLayout.width, expectedWidth);
      expect(fillWLayout.x, bloc.state.activePage.horizontalPadding);

      // 4. Change height sizing to fill (takes full page margin height: 1920 - 2 * 60 = 1800)
      bloc.add(const UpdateAutoLayoutEvent(
        layerId: 'al-test',
        verticalSizing: AutoLayoutSizingMode.fill,
      ));
      await Future.delayed(Duration.zero);

      final fillHLayout = bloc.state.activePage.layers.first as AutoLayoutLayer;
      expect(fillHLayout.verticalSizing, AutoLayoutSizingMode.fill);
      final expectedHeight = bloc.state.activePage.height - bloc.state.activePage.verticalPadding * 2;
      expect(fillHLayout.height, expectedHeight);
      expect(fillHLayout.y, bloc.state.activePage.verticalPadding);
    });

    test('EditorBloc supports moving a layout inside another layout in the tree', () async {
      const parentLayout = AutoLayoutLayer(
        id: 'parent-layout',
        name: 'Vertical Main Layout',
        x: 40,
        y: 40,
        width: 300,
        height: 400,
        children: [
          ShapeLayer(id: 'header-icon', name: 'Icon', x: 0, y: 0, width: 24, height: 24),
        ],
      );

      const childLayout = AutoLayoutLayer(
        id: 'child-layout',
        name: 'Horizontal Row Layout',
        x: 40,
        y: 460,
        width: 200,
        height: 60,
        children: [
          ShapeLayer(id: 'row-icon', name: 'Check', x: 0, y: 0, width: 16, height: 16),
          TextLayer(id: 'row-text', name: 'Text', x: 0, y: 0, width: 80, height: 20, content: 'Item 1'),
        ],
      );

      final customProject = project.copyWith(
        pages: [
          project.pages[0].copyWith(layers: [parentLayout, childLayout]),
        ],
      );

      final bloc = EditorBloc(initialProject: customProject);
      expect(bloc.state.activePage.layers.length, 2);

      // Move childLayout inside parentLayout at index 1
      bloc.add(const MoveLayerTreeEvent(
        layerId: 'child-layout',
        targetParentId: 'parent-layout',
        targetIndex: 1,
      ));
      await Future.delayed(Duration.zero);

      // Top level should now have 1 layer (parentLayout), containing childLayout inside
      expect(bloc.state.activePage.layers.length, 1);
      final updatedParent = bloc.state.activePage.layers.first as AutoLayoutLayer;
      expect(updatedParent.children.length, 2);
      expect(updatedParent.children[1].id, 'child-layout');
      expect(updatedParent.children[1] is AutoLayoutLayer, isTrue);

      final nestedLayout = updatedParent.children[1] as AutoLayoutLayer;
      expect(nestedLayout.children.length, 2);
      expect(nestedLayout.children[0].id, 'row-icon');
      expect(nestedLayout.children[1].id, 'row-text');
    });

    test('EditorBloc supports updating page dimensions via UpdatePageDimensionsEvent', () async {
      final bloc = EditorBloc(initialProject: project);
      expect(bloc.state.activePage.width, 1080.0);
      expect(bloc.state.activePage.height, 1080.0);

      // Update to 9:16 Story preset
      bloc.add(const UpdatePageDimensionsEvent(width: 1080, height: 1920));
      await Future.delayed(Duration.zero);

      expect(bloc.state.activePage.width, 1080.0);
      expect(bloc.state.activePage.height, 1920.0);

      // Update to 16:9 Landscape preset
      bloc.add(const UpdatePageDimensionsEvent(width: 1920, height: 1080));
      await Future.delayed(Duration.zero);

      expect(bloc.state.activePage.width, 1920.0);
      expect(bloc.state.activePage.height, 1080.0);
    });

    test('EditorBloc supports adding/updating Auto Layout background color', () async {
      final bloc = EditorBloc(initialProject: project);

      final t1 = TextLayer(id: 't1', name: 'Text 1', x: 20, y: 20, width: 80, height: 30, content: 'Text 1');
      final t2 = TextLayer(id: 't2', name: 'Text 2', x: 120, y: 20, width: 80, height: 30, content: 'Text 2');
      bloc.add(AddLayerEvent(t1));
      bloc.add(AddLayerEvent(t2));
      await Future.delayed(Duration.zero);

      bloc.add(SelectLayerEvent(t1.id, isMultiSelect: false));
      bloc.add(SelectLayerEvent(t2.id, isMultiSelect: true));
      await Future.delayed(Duration.zero);

      bloc.add(const CreateAutoLayoutFromSelectionEvent());
      await Future.delayed(Duration.zero);

      final autoLayout = bloc.state.activePageLayers.whereType<AutoLayoutLayer>().first;
      expect(autoLayout.backgroundColor, isNull);

      // Add background color
      const newBg = Color(0xFF6C5CE7);
      bloc.add(UpdateAutoLayoutEvent(
        layerId: autoLayout.id,
        backgroundColor: newBg,
      ));
      await Future.delayed(Duration.zero);

      final updatedLayout = bloc.state.activePageLayers.whereType<AutoLayoutLayer>().first;
      expect(updatedLayout.backgroundColor, newBg);

      // Remove background color (None / Transparent)
      bloc.add(UpdateAutoLayoutEvent(
        layerId: autoLayout.id,
        backgroundColor: Colors.transparent,
      ));
      await Future.delayed(Duration.zero);

      final clearedLayout = bloc.state.activePageLayers.whereType<AutoLayoutLayer>().first;
      expect(clearedLayout.backgroundColor, isNull);
    });

    test('EditorBloc supports Auto Layout stroke settings (color, weight, position)', () async {
      final bloc = EditorBloc(initialProject: project);

      final t1 = TextLayer(id: 't1', name: 'Text 1', x: 20, y: 20, width: 80, height: 30, content: 'Text 1');
      bloc.add(AddLayerEvent(t1));
      await Future.delayed(Duration.zero);

      bloc.add(SelectLayerEvent(t1.id, isMultiSelect: false));
      await Future.delayed(Duration.zero);

      bloc.add(const CreateAutoLayoutFromSelectionEvent());
      await Future.delayed(Duration.zero);

      final autoLayout = bloc.state.activePageLayers.whereType<AutoLayoutLayer>().first;
      expect(autoLayout.strokeColor, isNull);
      expect(autoLayout.strokeWidth, 0.0);
      expect(autoLayout.strokePosition, StrokePosition.inside);

      // Add Stroke with color, weight 2.0, position outside
      const strokeColor = Color(0xFF0D99FF);
      bloc.add(UpdateAutoLayoutEvent(
        layerId: autoLayout.id,
        strokeColor: strokeColor,
        strokeWidth: 2.0,
        strokePosition: StrokePosition.outside,
      ));
      await Future.delayed(Duration.zero);

      final updatedLayout = bloc.state.activePageLayers.whereType<AutoLayoutLayer>().first;
      expect(updatedLayout.strokeColor, strokeColor);
      expect(updatedLayout.strokeWidth, 2.0);
      expect(updatedLayout.strokePosition, StrokePosition.outside);

      // Update position to center
      bloc.add(UpdateAutoLayoutEvent(
        layerId: autoLayout.id,
        strokePosition: StrokePosition.center,
      ));
      await Future.delayed(Duration.zero);

      final centerLayout = bloc.state.activePageLayers.whereType<AutoLayoutLayer>().first;
      expect(centerLayout.strokePosition, StrokePosition.center);

      // Clear stroke
      bloc.add(UpdateAutoLayoutEvent(
        layerId: autoLayout.id,
        strokeColor: Colors.transparent,
        strokeWidth: 0.0,
      ));
      await Future.delayed(Duration.zero);

      final clearedLayout = bloc.state.activePageLayers.whereType<AutoLayoutLayer>().first;
      expect(clearedLayout.strokeColor, isNull);
      expect(clearedLayout.strokeWidth, 0.0);
    });

    test('TextSpanParser parses multi-color text spans and applies word colors', () {
      const content = "I redesigned [color:#6C5CE7]Uber's Eats[/color] screen.";
      const baseStyle = TextStyle(color: Colors.white, fontSize: 48);

      final span = TextSpanParser.parseToTextSpan(content, baseStyle);
      expect(span.children, isNotNull);
      expect(span.children!.length, 3);
      expect((span.children![0] as TextSpan).text, 'I redesigned ');
      expect((span.children![0] as TextSpan).style?.color, Colors.white);
      expect((span.children![1] as TextSpan).text, "Uber's Eats");
      expect((span.children![1] as TextSpan).style?.color, const Color(0xFF6C5CE7));
      expect((span.children![2] as TextSpan).text, ' screen.');
      expect((span.children![2] as TextSpan).style?.color, Colors.white);

      // Strip tags
      expect(TextSpanParser.stripTags(content), "I redesigned Uber's Eats screen.");

      // Apply color to another word
      final updated = TextSpanParser.applyColorToWord(content, 'screen.', const Color(0xFFFF4757));
      expect(updated.contains('[color:#FF4757]screen.[/color]'), isTrue);

      // Clear color
      final cleared = TextSpanParser.applyColorToWord(updated, 'screen.', null);
      expect(cleared.contains('[color:#FF4757]'), isFalse);
    });

    test('EditorBloc supports ScaleLayerEvent proportionally scaling layers and nested AutoLayouts', () async {
      final text = TextLayer(
        id: 'txt-scale',
        name: 'Scale Text',
        x: 0,
        y: 0,
        width: 100,
        height: 40,
        fontSize: 20,
        content: 'Hello',
      );
      final shape = ShapeLayer(
        id: 'shp-scale',
        name: 'Scale Shape',
        x: 0,
        y: 0,
        width: 50,
        height: 50,
        cornerRadius: 10,
      );

      final autoLayout = AutoLayoutLayer(
        id: 'layout-scale',
        name: 'Scale Layout',
        x: 100,
        y: 100,
        width: 180,
        height: 70,
        gap: 10,
        paddingHorizontal: 10,
        paddingVertical: 10,
        children: [text, shape],
      );

      final customProject = project.copyWith(
        pages: [
          project.pages[0].copyWith(layers: [autoLayout]),
        ],
      );

      final bloc = EditorBloc(initialProject: customProject);

      // Scale the auto layout by 2.0x
      bloc.add(const ScaleLayerEvent(layerId: 'layout-scale', scaleFactor: 2.0));
      await Future.delayed(Duration.zero);

      final scaledLayout = bloc.state.activePageLayers.whereType<AutoLayoutLayer>().first;
      expect(scaledLayout.gap, 20.0);
      expect(scaledLayout.paddingHorizontal, 20.0);
      expect(scaledLayout.paddingVertical, 20.0);

      final scaledText = scaledLayout.children.whereType<TextLayer>().first;
      expect(scaledText.fontSize, 40.0); // 20 * 2.0

      final scaledShape = scaledLayout.children.whereType<ShapeLayer>().first;
      expect(scaledShape.width, 100.0); // 50 * 2.0
      expect(scaledShape.height, 100.0); // 50 * 2.0
      expect(scaledShape.cornerRadius, 20.0); // 10 * 2.0

      // Scale down by 0.5x
      bloc.add(const ScaleLayerEvent(layerId: 'layout-scale', scaleFactor: 0.5));
      await Future.delayed(Duration.zero);

      final halfLayout = bloc.state.activePageLayers.whereType<AutoLayoutLayer>().first;
      expect(halfLayout.gap, 10.0);

      final halfText = halfLayout.children.whereType<TextLayer>().first;
      expect(halfText.fontSize, 20.0);
    });
  });
}
