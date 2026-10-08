import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saqgo/main.dart';

void main() {
  testWidgets('starts with the language selector when no locale is stored', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const SaqgoApp());
    await tester.pumpAndSettle();
    expect(find.text('Выберите язык'), findsOneWidget);
  });
}
