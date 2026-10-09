import 'package:flutter_test/flutter_test.dart';
import 'package:saqgo/core/services/trip_track_service.dart';

void main() {
  test('keeps only accurate, distinct samples and measures distance', () {
    final track = TripTrackService();
    final now = DateTime(2026, 10, 9, 12);
    track.start();

    expect(
      track.addSample(
        latitude: 50.25,
        longitude: 66.92,
        accuracyMeters: 12,
        recordedAt: now,
      ),
      isTrue,
    );
    expect(
      track.addSample(
        latitude: 50.250001,
        longitude: 66.920001,
        accuracyMeters: 12,
        recordedAt: now.add(const Duration(seconds: 1)),
      ),
      isFalse,
    );
    expect(
      track.addSample(
        latitude: 50.251,
        longitude: 66.921,
        accuracyMeters: 12,
        recordedAt: now.add(const Duration(seconds: 10)),
      ),
      isTrue,
    );
    expect(
      track.addSample(
        latitude: 50.252,
        longitude: 66.922,
        accuracyMeters: 80,
        recordedAt: now.add(const Duration(seconds: 20)),
      ),
      isFalse,
    );

    final snapshot = track.stop();
    expect(snapshot.points, hasLength(2));
    expect(snapshot.distanceMeters, greaterThan(100));
    expect(
      track.addSample(
        latitude: 50.253,
        longitude: 66.923,
        accuracyMeters: 10,
        recordedAt: now.add(const Duration(seconds: 30)),
      ),
      isFalse,
    );
  });
}
