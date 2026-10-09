import 'api_configuration.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Hazard {
  const Hazard({
    required this.id,
    required this.position,
    required this.category,
    required this.status,
    required this.source,
    required this.confidence,
    required this.accuracyMeters,
    required this.demo,
    this.updatedAt,
    this.expiresAt,
  });
  final String id, category, status, source;
  final LatLng position;
  final double confidence, accuracyMeters;
  final bool demo;
  final DateTime? updatedAt, expiresAt;
  bool get active =>
      demo ||
      (status == 'verified' &&
          expiresAt != null &&
          expiresAt!.isAfter(DateTime.now()));
  factory Hazard.fromFeature(Map<String, dynamic> feature) {
    final properties = feature['properties'] as Map<String, dynamic>;
    final coordinates =
        (feature['geometry'] as Map<String, dynamic>)['coordinates'] as List;
    DateTime? date(Object? value) => value is num
        ? DateTime.fromMillisecondsSinceEpoch((value * 1000).round())
        : null;
    return Hazard(
      id: feature['id'] as String,
      position: LatLng(
        (coordinates[1] as num).toDouble(),
        (coordinates[0] as num).toDouble(),
      ),
      category: properties['category'] as String,
      status: properties['status'] as String,
      source: properties['source'] as String,
      confidence: (properties['confidence'] as num).toDouble(),
      accuracyMeters: (properties['accuracy_meters'] as num).toDouble(),
      demo: properties['demo'] == true,
      updatedAt: date(properties['updated_at']),
      expiresAt: date(properties['expires_at']),
    );
  }
}

class HazardService {
  static String get apiBase => ApiConfiguration.baseUrl;
  static final items = ValueNotifier<List<Hazard>>([]);
  static final layers = ValueNotifier<Map<String, bool>>({
    'road_bump': true,
    'ice': false,
    'closure': true,
    'sidewalk': false,
    'demo': const bool.fromEnvironment('SAQGO_DEMO_MODE'),
    'onlyVerified': true,
  });
  static const presentationHazards = [
    Hazard(
      id: 'demo-road-bump',
      position: LatLng(50.250, 66.922),
      category: 'road_bump',
      status: 'unverified',
      source: 'synthetic_fixture',
      confidence: 0.4,
      accuracyMeters: 100,
      demo: true,
    ),
    Hazard(
      id: 'demo-sidewalk',
      position: LatLng(50.247, 66.918),
      category: 'closure',
      status: 'unverified',
      source: 'synthetic_fixture',
      confidence: 0.5,
      accuracyMeters: 100,
      demo: true,
    ),
  ];
  static Future<void> restorePreferences() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString('saqgo_layers');
    if (encoded != null) {
      try {
        final stored = jsonDecode(encoded) as Map<String, dynamic>;
        layers.value = {
          ...layers.value,
          for (final entry in stored.entries)
            if (layers.value.containsKey(entry.key) && entry.value is bool)
              entry.key: entry.value as bool,
        };
      } catch (_) {}
    }
    final ids = preferences.getStringList('saqgo_hidden_risks');
    if (ids != null) hidden.value = ids.toSet();
    await refresh();
  }

  static final unavailable = ValueNotifier(false);
  static final hidden = ValueNotifier<Set<String>>({});
  static Uri? uri(String endpoint, [Map<String, String>? query]) {
    final base = Uri.tryParse(apiBase);
    if (base == null ||
        !['http', 'https'].contains(base.scheme) ||
        base.host.isEmpty) {
      return null;
    }
    return base.replace(
      path: '${base.path.replaceFirst(RegExp(r'/$'), '')}$endpoint',
      queryParameters: query,
    );
  }

  static List<Hazard> get visible => items.value
      .where(
        (h) =>
            h.active &&
            !hidden.value.contains(h.id) &&
            (layers.value[h.category] ?? false) &&
            (h.demo
                ? layers.value['demo'] == true
                : (!(layers.value['onlyVerified'] ?? true) ||
                      h.status == 'verified')),
      )
      .toList();
  static Future<void> refresh() async {
    final endpoint = uri('/v1/hazards');
    if (endpoint == null) {
      items.value = layers.value['demo'] == true
          ? List.of(presentationHazards)
          : [];
      unavailable.value = true;
      return;
    }
    try {
      final live = await http
          .get(endpoint)
          .timeout(const Duration(seconds: 10));
      if (live.statusCode != 200) throw StateError('Hazards unavailable');
      final features =
          (jsonDecode(live.body) as Map<String, dynamic>)['features'] as List;
      items.value = features
          .map((f) => Hazard.fromFeature(f as Map<String, dynamic>))
          .where((h) => h.active)
          .toList();
      if (layers.value['demo'] == true) {
        items.value = [...items.value, ...presentationHazards];
      }
      unavailable.value = false;
    } catch (_) {
      unavailable.value = true;
      items.value = [
        ...items.value.where((h) => !h.demo && h.active),
        if (layers.value['demo'] == true) ...presentationHazards,
      ];
    }
  }

  static void toggle(String key, bool value) {
    layers.value = {...layers.value, key: value};
    SharedPreferences.getInstance().then(
      (preferences) =>
          preferences.setString('saqgo_layers', jsonEncode(layers.value)),
    );
    if (key == 'demo') {
      refresh();
    }
  }

  static void hide(String id) {
    hidden.value = {...hidden.value, id};
    SharedPreferences.getInstance().then(
      (preferences) => preferences.setStringList(
        'saqgo_hidden_risks',
        hidden.value.toList(),
      ),
    );
  }
}

class HazardAlertService {
  final _lastAlert = <String, DateTime>{};
  LatLng? _previous;
  List<Hazard> update(
    LatLng point,
    double accuracy,
    DateTime now,
    List<Hazard> hazards,
  ) {
    const distance = Distance();
    if (!accuracy.isFinite || accuracy < 0 || accuracy > 65) return [];
    final found = <Hazard>[];
    for (final hazard in hazards) {
      if (hazard.demo || !hazard.active || hazard.status != 'verified') {
        continue;
      }
      final current = distance(point, hazard.position);
      final prior = _previous == null
          ? double.infinity
          : distance(_previous!, hazard.position);
      if (current > 100 ||
          current > prior ||
          (_lastAlert[hazard.id] != null &&
              now.difference(_lastAlert[hazard.id]!).inSeconds < 300)) {
        continue;
      }
      _lastAlert[hazard.id] = now;
      found.add(hazard);
    }
    _previous = point;
    return found;
  }
}
