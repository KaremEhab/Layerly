import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:defer_pointer/defer_pointer.dart';
import 'package:layerly/features/editor/domain/entities/auto_layout_layer.dart';
import 'package:layerly/features/editor/domain/entities/icon_layer.dart';
import 'package:layerly/features/editor/domain/entities/layer_enums.dart';
import 'package:layerly/features/editor/domain/entities/text_layer.dart';
import 'package:layerly/features/editor/presentation/widgets/canvas/layer_view.dart';

void main() {
  testWidgets('auto-layout children are selectable on double-tap when container is selected', (tester) async {
    String? selectedId;
    final checklist = AutoLayoutLayer(
      id: 'checklist',
      name: 'Checklist item',
      x: 0,
      y: 0,
      width: 220,
      height: 40,
      direction: AutoLayoutDirection.horizontal,
      gap: 12,
      paddingHorizontal: 0,
      paddingVertical: 0,
      alignment: AutoLayoutAlignment.center,
      horizontalSizing: AutoLayoutSizingMode.fixed,
      verticalSizing: AutoLayoutSizingMode.fixed,
      children: [
        IconLayer(
          id: 'check-icon',
          name: 'Check icon',
          x: 0,
          y: 0,
          width: 36,
          height: 36,
          icon: Icons.check_circle_outline,
        ),
        TextLayer(
          id: 'check-label',
          name: 'Check label',
          x: 0,
          y: 0,
          width: 120,
          height: 28,
          content: 'Direct selection',
          fontSize: 16,
        ),
      ],
    );

    // 1. When container is NOT selected, double-tap should NOT dive into child
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeferredPointerHandler(
            child: SizedBox(
              width: 220,
              height: 40,
              child: LayerView(
                layer: checklist,
                selectedLayerIds: const [],
                onSelectLayer: (id, _) => selectedId = id,
              ),
            ),
          ),
        ),
      ),
    );

    await _doubleTapAt(tester, const Offset(18, 20));
    expect(selectedId, isNull);

    // 2. When container IS selected, double-tap dives into the direct child
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeferredPointerHandler(
            child: SizedBox(
              width: 220,
              height: 40,
              child: LayerView(
                layer: checklist,
                selectedLayerIds: const ['checklist'],
                onSelectLayer: (id, _) => selectedId = id,
              ),
            ),
          ),
        ),
      ),
    );

    await _doubleTapAt(tester, const Offset(18, 20));
    expect(selectedId, 'check-icon');

    await _doubleTapAt(tester, const Offset(95, 20));
    expect(selectedId, 'check-label');
  });

  testWidgets('nested auto-layout requires selecting parent first before diving into child',
      (tester) async {
    String? selectedId;
    final footer = AutoLayoutLayer(
      id: 'footer',
      name: 'Footer',
      x: 0,
      y: 0,
      width: 220,
      height: 48,
      direction: AutoLayoutDirection.vertical,
      paddingHorizontal: 0,
      paddingVertical: 0,
      horizontalSizing: AutoLayoutSizingMode.fixed,
      verticalSizing: AutoLayoutSizingMode.fixed,
      children: [
        AutoLayoutLayer(
          id: 'footer-actions',
          name: 'Footer actions',
          x: 0,
          y: 0,
          width: 220,
          height: 48,
          direction: AutoLayoutDirection.horizontal,
          paddingHorizontal: 0,
          paddingVertical: 0,
          horizontalSizing: AutoLayoutSizingMode.fixed,
          verticalSizing: AutoLayoutSizingMode.fixed,
          children: [
            IconLayer(
              id: 'footer-icon',
              name: 'Footer icon',
              x: 0,
              y: 0,
              width: 36,
              height: 36,
              icon: Icons.home_outlined,
            ),
          ],
        ),
      ],
    );

    // 1. When outer footer is selected, double tapping selects immediate child 'footer-actions' (not innermost icon)
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeferredPointerHandler(
            child: SizedBox(
              width: 220,
              height: 48,
              child: LayerView(
                layer: footer,
                selectedLayerIds: const ['footer'],
                onSelectLayer: (id, _) => selectedId = id,
              ),
            ),
          ),
        ),
      ),
    );

    await _doubleTapAt(tester, const Offset(18, 24));
    expect(selectedId, 'footer-actions');

    // 2. When 'footer-actions' is selected, double tapping selects 'footer-icon'
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeferredPointerHandler(
            child: SizedBox(
              width: 220,
              height: 48,
              child: LayerView(
                layer: footer,
                selectedLayerIds: const ['footer-actions'],
                onSelectLayer: (id, _) => selectedId = id,
              ),
            ),
          ),
        ),
      ),
    );

    await _doubleTapAt(tester, const Offset(18, 24));
    expect(selectedId, 'footer-icon');
  });
}

Future<void> _doubleTapAt(WidgetTester tester, Offset position) async {
  await tester.tapAt(position);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tapAt(position);
  await tester.pumpAndSettle();
}

