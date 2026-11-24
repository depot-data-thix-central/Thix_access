import 'package:flutter_test/flutter_test.dart';
import 'package:thix_access/thix_access_app.dart';

void main() {
  testWidgets('renders the THIX ACCESS home screen', (tester) async {
    await tester.pumpWidget(const ThixAccessApp());
    expect(find.text('THIX ACCESS'), findsOneWidget);
    expect(find.text('Démarrer une conversation'), findsOneWidget);
  });
}
