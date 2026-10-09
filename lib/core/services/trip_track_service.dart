import 'dart:math' as math;

class TrackPoint {
  const TrackPoint({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.recordedAt,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final DateTime recordedAt;
}

class TripTrackSnapshot {
  const TripTrackSnapshot({required this.points, required this.distanceMeters});

  final List<TrackPoint> points;
  final double distanceMeters;
}

/// Keeps a local, quality-filtered GPS track for one explicitly started trip.
/// The service deliberately does not upload or classify location data.
class TripTrackService {
  TripTrackService({
    this.maximumAccuracyMeters = 65,
    this.minimumPointDistanceMeters = 4,
  });

  final double maximumAccuracyMeters;
  final double minimumPointDistanceMeters;
  final List<TrackPoint> _points = [];
  var _distanceMeters = 0.0;
  var _isRecording = false;

  bool get isRecording => _isRecording;

  void start() => _isRecording = true;

  void pause() => _isRecording = false;

  void resume() => _isRecording = true;

  /// Returns true only when a valid point was retained in the local track.
  bool addSample({
    required double latitude,
    required double longitude,
    required double accuracyMeters,
    required DateTime recordedAt,
  }) {
    if (!_isRecording ||
        !latitude.isFinite ||
        !longitude.isFinite ||
        !accuracyMeters.isFinite ||
        latitude.abs() > 90 ||
        longitude.abs() > 180 ||
        accuracyMeters < 0 ||
        accuracyMeters > maximumAccuracyMeters) {
      return false;
    }

    final point = TrackPoint(
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: accuracyMeters,
      recordedAt: recordedAt,
    );
    if (_points.isNotEmpty) {
      final distance = _haversineMeters(_points.last, point);
      if (distance < minimumPointDistanceMeters) return false;
      _distanceMeters += distance;
    }
    _points.add(point);
    return true;
  }

  TripTrackSnapshot stop() {
    _isRecording = false;
    return TripTrackSnapshot(
      points: List.unmodifiable(_points),
      distanceMeters: _distanceMeters,
    );
  }

  static double _haversineMeters(TrackPoint first, TrackPoint second) {
    const earthRadiusMeters = 6371000.0;
    final latitudeDelta = _radians(second.latitude - first.latitude);
    final longitudeDelta = _radians(second.longitude - first.longitude);
    final a =
        math.pow(math.sin(latitudeDelta / 2), 2) +
        math.cos(_radians(first.latitude)) *
            math.cos(_radians(second.latitude)) *
            math.pow(math.sin(longitudeDelta / 2), 2);
    return 2 * earthRadiusMeters * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _radians(double degrees) => degrees * math.pi / 180;
}
