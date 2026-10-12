import 'package:flutter_test/flutter_test.dart';
import 'package:reswave/main.dart';

void main() {
  testWidgets('ResWave onboarding screen appears', (WidgetTester tester) async {
    await tester.pumpWidget(const ResWaveApp());

    expect(find.text('ResWave'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
