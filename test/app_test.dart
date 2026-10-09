import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:saqgo/l10n/app_localizations.dart';
import 'package:saqgo/core/services/lifelog_store.dart';

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

  testWidgets('choosing a language does not mark onboarding complete', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const SaqgoApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Қазақша'));
    await tester.pumpAndSettle();
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('saqgo_locale'), 'kk');
    expect(preferences.getBool('saqgo_onboarding_complete'), isNot(true));
  });
  testWidgets('result with candidates does not claim there were no events', (
    tester,
  ) async {
    final record = TripRecord(
      id: 'candidate',
      startedAt: DateTime(2026, 10, 9),
      duration: const Duration(seconds: 10),
      candidateCount: 2,
      distanceMeters: 0,
      trackPointCount: 0,
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ru'), Locale('kk')],
        locale: const Locale('ru'),
        home: Scaffold(body: CandidateSummary(record: record)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Кандидаты: 2'), findsOneWidget);
    expect(find.textContaining('не зафиксированы'), findsNothing);
  });
}
