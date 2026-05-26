import 'package:flutter_test/flutter_test.dart';
import 'package:weight_nest/app.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const WeightNestApp());
    expect(find.text('WeightNest'), findsWidgets);
  });
}
