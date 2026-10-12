import 'package:flutter_application_1/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Launcher shows title and Lecturer/Student buttons', (WidgetTester tester) async {
    await tester.pumpWidget(const EcoStudySyncApp());

    expect(find.text('EcoStudy Sync'), findsOneWidget);
    expect(find.text('Lecturer'), findsOneWidget);
    expect(find.text('Student'), findsOneWidget);
  });
}