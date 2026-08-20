import 'package:flutter_test/flutter_test.dart';
import 'package:layerly/main.dart';

void main() {
  testWidgets('Layerly Studio smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LayerlyApp());
    expect(find.text('LAYERLY'), findsOneWidget);
  });
}
