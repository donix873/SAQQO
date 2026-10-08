import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart';
import 'sensor_candidate_service.dart';

class SensorSessionService {
  SensorSessionService({SensorCandidateService? candidateService})
    : _candidateService = candidateService ?? SensorCandidateService();

  final SensorCandidateService _candidateService;
  StreamSubscription<AccelerometerEvent>? _subscription;
  final _candidates = StreamController<VibrationCandidate>.broadcast();
  Stream<VibrationCandidate> get candidates => _candidates.stream;
  bool get isRecording => _subscription != null;

  Future<void> start() async {
    if (isRecording) return;
    _subscription =
        accelerometerEventStream(
          samplingPeriod: const Duration(milliseconds: 40),
        ).listen((event) {
          final candidate = _candidateService.addSample(
            x: event.x,
            y: event.y,
            z: event.z,
            timestamp: DateTime.now(),
          );
          if (candidate != null) _candidates.add(candidate);
        });
  }

  Future<void> pause() => stop();

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> dispose() async {
    await stop();
    await _candidates.close();
  }
}
