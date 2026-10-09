import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StoredTrackPoint {
  const StoredTrackPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  Map<String, double> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };

  static StoredTrackPoint? tryFromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final latitude = (value['latitude'] as num?)?.toDouble();
    final longitude = (value['longitude'] as num?)?.toDouble();
    if (latitude == null ||
        longitude == null ||
        !latitude.isFinite ||
        !longitude.isFinite ||
        latitude.abs() > 90 ||
        longitude.abs() > 180) {
      return null;
    }
    return StoredTrackPoint(latitude: latitude, longitude: longitude);
  }
}

class TripRecord {
  const TripRecord({
    required this.id,
    required this.startedAt,
    required this.duration,
    required this.candidateCount,
    required this.distanceMeters,
    required this.trackPointCount,
    this.trackPoints = const [],
  });

  final String id;
  final DateTime startedAt;
  final Duration duration;
  final int candidateCount;
  final double distanceMeters;
  final int trackPointCount;
  final List<StoredTrackPoint> trackPoints;

  List<LatLng> get routePoints => trackPoints
      .map((point) => LatLng(point.latitude, point.longitude))
      .toList(growable: false);

  Map<String, Object> toJson() => {
    'id': id,
    'startedAt': startedAt.toIso8601String(),
    'durationSeconds': duration.inSeconds,
    'candidateCount': candidateCount,
    'distanceMeters': distanceMeters,
    'trackPointCount': trackPointCount,
    'trackPoints': trackPoints.map((point) => point.toJson()).toList(),
  };

  factory TripRecord.fromJson(Map<String, dynamic> json) {
    final trackPoints = ((json['trackPoints'] as List<dynamic>?) ?? const [])
        .map(StoredTrackPoint.tryFromJson)
        .whereType<StoredTrackPoint>()
        .toList(growable: false);
    return TripRecord(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      duration: Duration(seconds: json['durationSeconds'] as int),
      candidateCount: json['candidateCount'] as int,
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ?? 0,
      trackPointCount: json['trackPointCount'] as int? ?? trackPoints.length,
      trackPoints: trackPoints,
    );
  }
}

class LifeLogStore {
  static const _key = 'saqgo_trip_records_v1';
  static final trips = ValueNotifier<List<TripRecord>>([]);

  static Future<void> restore() async {
    final saved = (await SharedPreferences.getInstance()).getString(_key);
    if (saved == null) return;
    try {
      final decoded = jsonDecode(saved) as List<dynamic>;
      trips.value =
          decoded
              .map(
                (entry) => TripRecord.fromJson(entry as Map<String, dynamic>),
              )
              .toList()
            ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    } on Object {
      trips.value = [];
    }
  }

  static Future<void> add(TripRecord trip) async {
    if (trips.value.any((saved) => saved.id == trip.id)) return;
    trips.value = [trip, ...trips.value];
    await _persist();
  }

  static Future<void> clear() async {
    trips.value = [];
    await (await SharedPreferences.getInstance()).remove(_key);
  }

  static Future<void> _persist() => (SharedPreferences.getInstance()).then(
    (preferences) => preferences.setString(
      _key,
      jsonEncode(trips.value.map((trip) => trip.toJson()).toList()),
    ),
  );
}
