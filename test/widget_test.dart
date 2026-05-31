import 'package:flutter_test/flutter_test.dart';
import 'package:tryprompt/main.dart';

void main() {
  testWidgets('Main Navigation Screen Smoke Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    debugDumpApp();

    // Verify that the MainScreen renders with custom bottom navigation bar
    expect(find.text('GoPrompt AI Image'), findsOneWidget);
    expect(find.text('Welcome App'), findsOneWidget);

    // Verify that the bottom nav bar items are present
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Daily'), findsOneWidget);
    expect(find.text('Favorite'), findsOneWidget);
    expect(find.text('Menu'), findsOneWidget);
  });
}
