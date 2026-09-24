import 'package:flutter_test/flutter_test.dart';
import 'package:plaza/main.dart';

void main() {
  testWidgets('PlazaApp smoke test - verifies branding and navigation tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const PlazaApp());
    await tester.pump(const Duration(milliseconds: 200));

    // Verify PLAZA branding text is present
    expect(find.text('PLAZA'), findsOneWidget);
    expect(find.text('•  Your city. Your plans.'), findsOneWidget);

    // Verify navigation tabs
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Bookings'), findsOneWidget);
    expect(find.text('Plans'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
