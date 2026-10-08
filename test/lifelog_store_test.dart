import 'package:flutter_test/flutter_test.dart';
import 'package:saqgo/core/services/lifelog_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('stores recorded trips locally and restores newest first', () async {
    SharedPreferences.setMockInitialValues({});
    await LifeLogStore.clear();

    await LifeLogStore.add(
      TripRecord(
        id: 'older',
        startedAt: DateTime(2026, 10, 7),
        duration: const Duration(minutes: 3),
        candidateCount: 1,
      ),
    );
    await LifeLogStore.add(
      TripRecord(
        id: 'newer',
        startedAt: DateTime(2026, 10, 8),
        duration: const Duration(minutes: 7),
        candidateCount: 2,
      ),
    );

    await LifeLogStore.restore();

    expect(LifeLogStore.trips.value.map((trip) => trip.id), ['newer', 'older']);
    expect(LifeLogStore.trips.value.first.candidateCount, 2);
  });
}
