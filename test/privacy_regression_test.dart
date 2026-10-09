import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saqgo/core/services/lifelog_store.dart';
import 'package:saqgo/core/services/trip_track_service.dart';

TripRecord trip(String id, DateTime date) => TripRecord(
  id: id,
  startedAt: date,
  duration: const Duration(minutes: 2),
  candidateCount: 1,
  distanceMeters: 10,
  trackPointCount: 1,
  trackPoints: const [
    StoredTrackPoint(latitude: 50.250123, longitude: 66.922456),
  ],
  candidates: [
    StoredCandidate(
      timestamp: date,
      confidence: .4,
      accuracyMeters: 10,
      latitude: 50.250123,
      longitude: 66.922456,
    ),
  ],
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await LifeLogStore.clear();
  });
  test('sensitive track and candidates are encrypted and restored', () async {
    final record = trip('secret-session', DateTime(2026, 10, 9));
    await LifeLogStore.add(record);
    final stored = (await SharedPreferences.getInstance()).getString(
      'saqgo_trip_records_v2_encrypted',
    )!;
    expect(stored.contains('50.250123'), false);
    expect(stored.contains('secret-session'), false);
    LifeLogStore.trips.value = [];
    await LifeLogStore.restore();
    expect(LifeLogStore.trips.value.single.candidates.single.confidence, .4);
  });
  test(
    'migrates legacy plaintext only after encrypted save; delete day preserves others',
    () async {
      final first = trip('old', DateTime(2026, 10, 8));
      final other = trip('other', DateTime(2026, 10, 9));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'saqgo_trip_records_v1',
        jsonEncode([first.toJson()]),
      );
      await LifeLogStore.restore();
      expect(prefs.containsKey('saqgo_trip_records_v1'), false);
      await LifeLogStore.add(other);
      await LifeLogStore.removeDay(DateTime(2026, 10, 8));
      LifeLogStore.trips.value = [];
      await LifeLogStore.restore();
      expect(LifeLogStore.trips.value.single.id, 'other');
      await LifeLogStore.remove('other');
      expect(LifeLogStore.trips.value, isEmpty);
      await LifeLogStore.clear();
      expect(prefs.containsKey('saqgo_trip_records_v2_encrypted'), false);
    },
  );
  test('tampering never silently erases stored history', () async {
    await LifeLogStore.add(trip('a', DateTime(2026, 10, 9)));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saqgo_trip_records_v2_encrypted', 'bad-data');
    await expectLater(LifeLogStore.restore(), throwsA(isA<FormatException>()));
    expect(prefs.getString('saqgo_trip_records_v2_encrypted'), 'bad-data');
  });
  test('pause does not add unrecorded distance and point count is bounded', () {
    final track = TripTrackService();
    final now = DateTime.now();
    track.start();
    track.addSample(
      latitude: 50.25,
      longitude: 66.92,
      accuracyMeters: 10,
      recordedAt: now,
    );
    track.pause();
    track.resume();
    track.addSample(
      latitude: 50.35,
      longitude: 66.92,
      accuracyMeters: 10,
      recordedAt: now,
    );
    expect(track.stop().distanceMeters, 0);
    track.start();
    expect(track.stop().points, isEmpty);
  });
}
