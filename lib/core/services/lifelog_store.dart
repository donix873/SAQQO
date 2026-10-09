import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cryptography/cryptography.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StoredTrackPoint {
  const StoredTrackPoint({
    required this.latitude,
    required this.longitude,
    this.recordedAt,
    this.accuracyMeters,
    this.segmentStart = false,
  });

  final double latitude;
  final double longitude;

  final DateTime? recordedAt;
  final double? accuracyMeters;
  final bool segmentStart;

  Map<String, Object?> toJson() => {
    "recordedAt": recordedAt?.toUtc().toIso8601String(),
    "accuracyMeters": accuracyMeters,
    "segmentStart": segmentStart,
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
    return StoredTrackPoint(
      latitude: latitude,
      longitude: longitude,
      recordedAt: DateTime.tryParse(value['recordedAt'] as String? ?? ''),
      accuracyMeters: (value['accuracyMeters'] as num?)?.toDouble(),
      segmentStart: value['segmentStart'] == true,
    );
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
    this.candidates = const [],
    this.demo = false,
  });

  final String id;
  final DateTime startedAt;
  final Duration duration;
  final int candidateCount;
  final double distanceMeters;
  final int trackPointCount;
  final List<StoredTrackPoint> trackPoints;
  final List<StoredCandidate> candidates;
  final bool demo;

  List<LatLng> get routePoints => trackPoints
      .map((point) => LatLng(point.latitude, point.longitude))
      .toList(growable: false);

  List<List<LatLng>> get routeSegments {
    final segments = <List<LatLng>>[];
    for (final point in trackPoints) {
      if (segments.isEmpty || point.segmentStart) segments.add([]);
      segments.last.add(LatLng(point.latitude, point.longitude));
    }
    return segments;
  }

  Map<String, Object> toJson() => {
    'demo': demo,
    'candidates': candidates.map((event) => event.toJson()).toList(),
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
      demo: json['demo'] == true,
      startedAt: DateTime.parse(json['startedAt'] as String),
      duration: Duration(seconds: json['durationSeconds'] as int),
      candidateCount: json['candidateCount'] as int,
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ?? 0,
      trackPointCount: json['trackPointCount'] as int? ?? trackPoints.length,
      trackPoints: trackPoints,
      candidates: ((json['candidates'] as List?) ?? const [])
          .map(
            (entry) => StoredCandidate.fromJson(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList(),
    );
  }
}

class StoredCandidate {
  const StoredCandidate({
    required this.timestamp,
    required this.confidence,
    required this.accuracyMeters,
    required this.latitude,
    required this.longitude,
  });
  final DateTime timestamp;
  final double confidence, accuracyMeters, latitude, longitude;
  Map<String, Object> toJson() => {
    'timestamp': timestamp.toUtc().toIso8601String(),
    'confidence': confidence,
    'accuracyMeters': accuracyMeters,
    'latitude': latitude,
    'longitude': longitude,
  };
  factory StoredCandidate.fromJson(Map<String, dynamic> value) =>
      StoredCandidate(
        timestamp: DateTime.parse(value['timestamp'] as String),
        confidence: (value['confidence'] as num).toDouble(),
        accuracyMeters: (value['accuracyMeters'] as num).toDouble(),
        latitude: (value['latitude'] as num).toDouble(),
        longitude: (value['longitude'] as num).toDouble(),
      );
}

class LifeLogStore {
  static const _key = 'saqgo_trip_records_v2_encrypted';
  static const _legacyKey = 'saqgo_trip_records_v1';
  static const _secure = FlutterSecureStorage();
  static final _cipher = AesGcm.with256bits();
  static final trips = ValueNotifier<List<TripRecord>>([]);
  static Future<void> _pending = Future.value();
  static Future<void> _serialize(Future<void> Function() action) {
    final result = _pending.then((_) => action());
    _pending = result.catchError((Object _) {});
    return result;
  }

  static Future<SecretKey> _encryptionKey() async {
    final encoded = await _secure.read(key: 'saqgo_lifelog_key');
    if (encoded != null) return SecretKey(base64Decode(encoded));
    final key = await _cipher.newSecretKey();
    await _secure.write(
      key: 'saqgo_lifelog_key',
      value: base64Encode(await key.extractBytes()),
    );
    return key;
  }

  static Future<void> restore() => _serialize(() async {
    final preferences = await SharedPreferences.getInstance();
    final encrypted = preferences.getString(_key);
    final legacy = preferences.getString(_legacyKey);
    if (encrypted == null && legacy == null) return;
    final String saved;
    if (encrypted != null) {
      final key = await _secure.read(key: 'saqgo_lifelog_key');
      if (key == null) throw StateError('LifeLog encryption key unavailable');
      final box = jsonDecode(encrypted) as Map<String, dynamic>;
      saved = utf8.decode(
        await _cipher.decrypt(
          SecretBox(
            base64Decode(box['data'] as String),
            nonce: base64Decode(box['nonce'] as String),
            mac: Mac(base64Decode(box['mac'] as String)),
          ),
          secretKey: SecretKey(base64Decode(key)),
        ),
      );
    } else {
      saved = legacy!;
    }
    final decoded = jsonDecode(saved) as List<dynamic>;
    final restored =
        decoded
            .map((entry) => TripRecord.fromJson(entry as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    if (encrypted == null) await _persist(restored);
    await preferences.remove(_legacyKey);
    trips.value = restored;
  });
  static Future<void> add(TripRecord trip) => _serialize(() async {
    if (trips.value.any((saved) => saved.id == trip.id)) return;
    final updated = [trip, ...trips.value];
    await _persist(updated);
    trips.value = updated;
  });
  static Future<void> remove(String id) => _serialize(() async {
    final updated = trips.value.where((trip) => trip.id != id).toList();
    await _persist(updated);
    trips.value = updated;
  });
  static Future<void> removeDay(DateTime date) => _serialize(() async {
    final updated = trips.value
        .where(
          (trip) =>
              trip.startedAt.year != date.year ||
              trip.startedAt.month != date.month ||
              trip.startedAt.day != date.day,
        )
        .toList();
    await _persist(updated);
    trips.value = updated;
  });
  static Future<void> clear() => _serialize(() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_key);
    await preferences.remove(_legacyKey);
    await _secure.delete(key: 'saqgo_lifelog_key');
    trips.value = [];
  });
  static Future<void> _persist(List<TripRecord> records) async {
    final box = await _cipher.encrypt(
      utf8.encode(jsonEncode(records.map((trip) => trip.toJson()).toList())),
      secretKey: await _encryptionKey(),
    );
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _key,
      jsonEncode({
        'data': base64Encode(box.cipherText),
        'nonce': base64Encode(box.nonce),
        'mac': base64Encode(box.mac.bytes),
      }),
    );
    if (!saved) throw StateError('LifeLog save failed');
  }
}
