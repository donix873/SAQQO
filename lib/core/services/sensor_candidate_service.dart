import 'dart:math' as math;

/// A deliberately conservative, on-device heuristic.
/// It marks a vibration candidate; it never diagnoses a pothole, ice, or safety.
class SensorCandidateService {
  SensorCandidateService({this.threshold = 15.0, this.minSamples = 12});

  final double threshold;
  final int minSamples;
  final List<double> _window = [];

  void reset() => _window.clear();

  VibrationCandidate? addSample({
    required double x,
    required double y,
    required double z,
    required DateTime timestamp,
  }) {
    if (!x.isFinite || !y.isFinite || !z.isFinite) return null;
    final magnitude = math.sqrt(x * x + y * y + z * z);
    _window.add(magnitude);
    if (_window.length > 50) _window.removeAt(0);
    if (_window.length < minSamples) return null;
    final mean = _window.reduce((a, b) => a + b) / _window.length;
    final peak = _window.reduce(math.max);
    if (peak < threshold || peak - mean < 3) return null;
    final confidence = ((peak - threshold) / threshold)
        .clamp(0.0, 0.6)
        .toDouble();
    _window.clear();
    return VibrationCandidate(timestamp: timestamp, confidence: confidence);
  }
}

class VibrationCandidate {
  const VibrationCandidate({required this.timestamp, required this.confidence});
  final DateTime timestamp;
  final double confidence;
}
