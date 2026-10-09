import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saqgo/main.dart';

void main() {
  testWidgets('starts with the language selector when no locale is stored', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const SaqgoApp());
    await tester.pumpAndSettle();
    expect(find.text('Выберите язык'), findsOneWidget);
  });

  testWidgets('keeps onboarding continue action reachable on a short screen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SaqgoApp());
    await tester.tap(find.text('Продолжить'));
    await tester.pumpAndSettle();

    final continueWithoutLocation = find.text('Продолжить без геолокации');
    expect(continueWithoutLocation.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(continueWithoutLocation);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
