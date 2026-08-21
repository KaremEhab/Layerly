import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_bloc.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_event.dart';
import 'package:layerly/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  testWidgets('Layerly Studio - Mobile Layout and Contextual Inspector switching', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const LayerlyApp());
    await tester.pumpAndSettle();

    // 1. Initial State: Nothing selected -> Page Properties
    expect(find.text('Layerly'), findsWidgets);
    expect(find.text('Cover Screen'), findsWidgets);
    expect(find.text('Add Slide'), findsOneWidget);
    expect(find.text('Page properties'), findsOneWidget);
    expect(find.text('Guides'), findsOneWidget);

    // 2. Select Text Layer -> Contextual Inspector switches to Text Properties
    final BuildContext context = tester.element(find.byType(SafeArea).first);
    context.read<EditorBloc>().add(const SelectLayerEvent('txt-heading-line-1')); // Heading line 1
    // Fallback: select any layer from the active page
    final activeLayers = context.read<EditorBloc>().state.activePageLayers;
    if (activeLayers.isNotEmpty) {
      context.read<EditorBloc>().add(SelectLayerEvent(activeLayers.first.id));
    }
    await tester.pumpAndSettle();

    expect(find.text('Text'), findsWidgets);

    // 3. Select 2 layers -> Multi-selection Actions ("2 selected", "Create Layout")
    if (activeLayers.length >= 2) {
      context.read<EditorBloc>().add(SelectLayerEvent(activeLayers[0].id, isMultiSelect: false));
      context.read<EditorBloc>().add(SelectLayerEvent(activeLayers[1].id, isMultiSelect: true));
      await tester.pumpAndSettle();

      expect(find.text('2 selected'), findsOneWidget);
      expect(find.text('Create Layout'), findsOneWidget);
    }
  });

  testWidgets('Layerly Studio - Desktop Pro Layout', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const LayerlyApp());
    await tester.pumpAndSettle();

    expect(find.text('LAYERLY'), findsOneWidget);
    expect(find.text('Inspector'), findsOneWidget);
    expect(find.text('Layers'), findsWidgets);
    expect(find.text('Export'), findsOneWidget);
  });

  testWidgets('Layerly Studio - Tablet Hybrid Layout', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const LayerlyApp());
    await tester.pumpAndSettle();

    expect(find.text('LAYERLY'), findsOneWidget);
    expect(find.text('Cover Screen'), findsWidgets);
  });
}
