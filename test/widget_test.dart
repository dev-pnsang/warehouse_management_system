import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swift_keep/main.dart';

void main() {
  testWidgets('SwiftKeep app loads and shows greeting', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SwiftKeepApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Hello'), findsOneWidget);
  });
}
