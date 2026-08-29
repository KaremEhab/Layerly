import 'package:flutter_test/flutter_test.dart';
import 'package:layerly/features/ai_agent/data/intelligent_synthesis_engine.dart';
import 'package:layerly/features/ai_agent/domain/entities/design_recipe.dart';
import 'package:layerly/features/editor/domain/entities/auto_layout_layer.dart';
import 'package:layerly/features/editor/domain/entities/canvas_page.dart';
import 'package:layerly/features/editor/domain/entities/canvas_project.dart';
import 'package:layerly/features/editor/domain/entities/layer_enums.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_bloc.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_event.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Layerly AI Design Agent - Synthesis Engine Tests', () {
    test('parses prompt for 1:1 pharma graphic design into valid DesignRecipe', () {
      const prompt =
          'create me a new graphic design with 1:1 ratio and with gradient bg and featuring pharma stuff';

      final recipe = IntelligentSynthesisEngine.parsePromptToRecipe(prompt);

      expect(recipe.aspectRatio, '1:1');
      expect(recipe.domain, DesignDomain.pharma);
      expect(recipe.badgeText, contains('PHARMA'));
      expect(recipe.gradientColors.length, greaterThanOrEqualTo(2));
      expect(recipe.features.length, greaterThanOrEqualTo(2));
      expect(recipe.features.any((f) => f.title.toLowerCase().contains('efficacy') || f.title.toLowerCase().contains('clinical')), isTrue);
    });

    test('synthesizes mathematically balanced CanvasPage from DesignRecipe', () {
      const prompt =
          'create me a new graphic design with 1:1 ratio and with gradient bg and featuring pharma stuff';
      final recipe = IntelligentSynthesisEngine.parsePromptToRecipe(prompt);
      final page = IntelligentSynthesisEngine.synthesizeCanvasPage(recipe);

      expect(page.width, 1080.0);
      expect(page.height, 1080.0);
      expect(page.backgroundType, BackgroundType.gradient);
      expect(page.backgroundGradient, isNotNull);

      // Verify layer hierarchy
      expect(page.layers.isNotEmpty, isTrue);

      // Verify presence of AutoLayoutLayers for responsiveness
      final autoLayoutLayers = page.layers.whereType<AutoLayoutLayer>().toList();
      expect(autoLayoutLayers.isNotEmpty, isTrue);

      // Verify header section exists
      final header = autoLayoutLayers.firstWhere((l) => l.name == 'Header Section');
      expect(header.children.length, greaterThanOrEqualTo(2));

      // Verify features group exists
      final features = autoLayoutLayers.firstWhere((l) => l.name == 'Features Group');
      expect(features.children.length, greaterThanOrEqualTo(2));
    });

    test('EditorBloc applies AI generated design with full Undo/Redo capability', () async {
      final initialPage = const CanvasPage(id: 'initial', name: 'Initial Slide');
      final project = CanvasProject(
        id: 'test-proj',
        name: 'Test Project',
        pages: [initialPage],
        activePageIndex: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final bloc = EditorBloc(initialProject: project);

      // 1. Generate an AI design
      final recipe = IntelligentSynthesisEngine.parsePromptToRecipe('1:1 pharma design');
      final aiPage = IntelligentSynthesisEngine.synthesizeCanvasPage(recipe);

      // 2. Apply as new slide
      bloc.add(ApplyAiDesignEvent(aiPage, asNewPage: true));
      await Future.delayed(Duration.zero);
      expect(bloc.state.project.pages.length, 2);
      expect(bloc.state.project.activePageIndex, 1);
      expect(bloc.state.activePage.name, contains('PHARMA'));
      expect(bloc.state.canUndo, isTrue);

      // 3. Undo AI action
      bloc.add(const UndoEvent());
      await Future.delayed(Duration.zero);
      expect(bloc.state.project.pages.length, 1);
      expect(bloc.state.canRedo, isTrue);

      // 4. Redo AI action
      bloc.add(const RedoEvent());
      await Future.delayed(Duration.zero);
      expect(bloc.state.project.pages.length, 2);
      expect(bloc.state.activePage.name, contains('PHARMA'));
    });
  });
}
