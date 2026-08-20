import 'package:flutter_test/flutter_test.dart';
import 'package:layerly/core/constants/app_colors.dart';
import 'package:layerly/features/editor/domain/entities/canvas_page.dart';
import 'package:layerly/features/editor/domain/entities/canvas_project.dart';
import 'package:layerly/features/editor/domain/entities/component_definition.dart';
import 'package:layerly/features/editor/domain/entities/component_instance_layer.dart';
import 'package:layerly/features/editor/domain/entities/text_layer.dart';
import 'package:layerly/features/editor/domain/entities/shape_layer.dart';
import 'package:layerly/features/editor/domain/services/snapping_service.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_bloc.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_event.dart';

void main() {
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
      expect(movedLayer.x, 100.0);
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
      expect(redoneLayer.x, 100.0);
      expect(redoneLayer.y, 150.0);
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
    });

    test('Component definition resolves in component instance layer', () {
      final bloc = EditorBloc(initialProject: project);
      final def = bloc.state.getComponentDefinition('comp-footer');
      expect(def, isNotNull);
      expect(def!.name, 'Profile Footer');
      expect(def.layers.first.name, 'Handle');
    });
  });
}
