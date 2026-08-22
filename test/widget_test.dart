import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:layerly/features/editor/domain/entities/auto_layout_layer.dart';
import 'package:layerly/features/editor/domain/entities/layer_enums.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_bloc.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_event.dart';
import 'package:layerly/core/widgets/more_rings_icon.dart';
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

  testWidgets('Layerly Studio - Frame Properties Card with 3 Controllers (Radius, Height, Width) and More Dialog', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const LayerlyApp());
    await tester.pumpAndSettle();

    final BuildContext context = tester.element(find.byType(SafeArea).first);
    final bloc = context.read<EditorBloc>();

    // Add a freeform Frame
    final frame = AutoLayoutLayer(
      id: 'test-frame-widget',
      name: 'Custom Frame',
      direction: AutoLayoutDirection.none,
      x: 120,
      y: 120,
      width: 340,
      height: 260,
      cornerRadius: 16,
      backgroundColor: const Color(0xFF1E1C2B),
    );
    bloc.add(AddLayerEvent(frame));
    await tester.pumpAndSettle();

    // Select the frame
    bloc.add(const SelectLayerEvent('test-frame-widget'));
    await tester.pumpAndSettle();

    // Verify Frame Properties Card is displayed (NOT Auto layout)
    expect(find.text('Frame'), findsWidgets);
    expect(find.text('Freeform (Frame)'), findsOneWidget);

    // Verify 3 Steppers are present (Radius 16, Height 260, Width 340)
    expect(find.text('16'), findsOneWidget);
    expect(find.text('260'), findsOneWidget);
    expect(find.text('340'), findsOneWidget);

    // Click the More button
    await tester.tap(find.byType(MoreRingsIcon).last);
    await tester.pumpAndSettle();

    // Verify Frame Properties Dialog opens with full settings
    expect(find.text('Frame Properties'), findsOneWidget);
    expect(find.text('Layout Mode'), findsOneWidget);
    expect(find.text('Dimensions (Width × Height)'), findsOneWidget);
    expect(find.text('Background Fill'), findsOneWidget);
    expect(find.text('Corner Radius'), findsOneWidget);
    expect(find.text('Stroke'), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);

    // Dismiss dialog
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });
}
