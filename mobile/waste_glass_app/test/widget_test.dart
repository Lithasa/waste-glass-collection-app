import 'package:flutter_test/flutter_test.dart';
import 'package:waste_glass_app/main.dart';

void main() {
  testWidgets('WasteGlassApp loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const WasteGlassApp());

    expect(find.text('Waste Glass'), findsOneWidget);
  });
}
