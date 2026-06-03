import 'package:flutter_test/flutter_test.dart';
import 'package:tryprompt/main.dart';

void main() {
  testWidgets('Main Navigation Screen Smoke Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    
    // Wait for splash screen animations and navigation to complete
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // Verify that the MainScreen renders (contains 'Try Prompt AI Image' title)
    expect(find.text('Try Prompt AI Image'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });
}
