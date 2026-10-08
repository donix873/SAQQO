import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TripRecord {
  const TripRecord({
    required this.id,
    required this.startedAt,
    required this.duration,
    required this.candidateCount,
  });

  final String id;
  final DateTime startedAt;
  final Duration duration;
  final int candidateCount;

  Map<String, Object> toJson() => {
    'id': id,
    'startedAt': startedAt.toIso8601String(),
    'durationSeconds': duration.inSeconds,
    'candidateCount': candidateCount,
  };

  factory TripRecord.fromJson(Map<String, dynamic> json) => TripRecord(
    id: json['id'] as String,
    startedAt: DateTime.parse(json['startedAt'] as String),
    duration: Duration(seconds: json['durationSeconds'] as int),
    candidateCount: json['candidateCount'] as int,
  );
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
    } on FormatException {
      trips.value = [];
    }
  }

  static Future<void> add(TripRecord trip) async {
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
