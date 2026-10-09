import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saqgo/main.dart';

void main() {
  testWidgets('boots the SaqQo application', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const SaqgoApp());

    expect(find.text('SaqQo'), findsOneWidget);
  });
}
