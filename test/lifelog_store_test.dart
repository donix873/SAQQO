import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:saqgo/core/services/lifelog_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test(
    'stores recorded trips with local tracks and restores newest first',
    () async {
      SharedPreferences.setMockInitialValues({});
      await LifeLogStore.clear();

      await LifeLogStore.add(
        TripRecord(
          id: 'older',
          startedAt: DateTime(2026, 10, 7),
          duration: const Duration(minutes: 3),
          candidateCount: 1,
          distanceMeters: 120,
          trackPointCount: 2,
          trackPoints: const [
            StoredTrackPoint(latitude: 50.2486, longitude: 66.9203),
            StoredTrackPoint(latitude: 50.2490, longitude: 66.9210),
          ],
        ),
      );
      await LifeLogStore.add(
        TripRecord(
          id: 'newer',
          startedAt: DateTime(2026, 10, 8),
          duration: const Duration(minutes: 7),
          candidateCount: 2,
          distanceMeters: 350,
          trackPointCount: 4,
        ),
      );

      await LifeLogStore.restore();

      expect(LifeLogStore.trips.value.map((trip) => trip.id), [
        'newer',
        'older',
      ]);
      expect(LifeLogStore.trips.value.first.candidateCount, 2);
      expect(LifeLogStore.trips.value.last.routePoints, hasLength(2));
      expect(LifeLogStore.trips.value.last.routePoints.last.longitude, 66.9210);

      await LifeLogStore.add(LifeLogStore.trips.value.first);
      expect(LifeLogStore.trips.value, hasLength(2));
    },
  );

  test('restores legacy trips that have no saved geometry', () {
    final trip = TripRecord.fromJson({
      'id': 'legacy',
      'startedAt': '2026-10-07T10:00:00.000',
      'durationSeconds': 90,
      'candidateCount': 0,
      'distanceMeters': 0,
      'trackPointCount': 3,
    });

    expect(trip.trackPointCount, 3);
    expect(trip.routePoints, isEmpty);
  });
}
