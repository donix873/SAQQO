import 'package:flutter_test/flutter_test.dart';
import 'package:saqgo/core/services/sensor_candidate_service.dart';

void main() {
  test('does not produce a candidate for stable gravity samples', () {
    final service = SensorCandidateService();
    VibrationCandidate? candidate;
    for (var i = 0; i < 20; i++) {
      candidate = service.addSample(
        x: 0,
        y: 0,
        z: 9.81,
        timestamp: DateTime(2026, 1, 1),
      );
    }
    expect(candidate, isNull);
  });

  test('marks a sharp vibration as an unconfirmed candidate', () {
    final service = SensorCandidateService();
    for (var i = 0; i < 12; i++) {
      service.addSample(x: 0, y: 0, z: 9.81, timestamp: DateTime(2026, 1, 1));
    }
    final candidate = service.addSample(
      x: 0,
      y: 0,
      z: 23,
      timestamp: DateTime(2026, 1, 1),
    );
    expect(candidate, isNotNull);
    expect(candidate!.confidence, lessThanOrEqualTo(0.6));
  });
}
