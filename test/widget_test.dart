import 'package:flutter_test/flutter_test.dart';
import 'package:tryprompt/main.dart';

void main() {
  testWidgets('Main Navigation Screen Smoke Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    
    // Let the stream builder resolve the mock stream
    await tester.pump();

    // Verify that the LoginScreen renders (contains 'Try Prompt' title)
    expect(find.text('Try Prompt'), findsWidgets);
  });
}
