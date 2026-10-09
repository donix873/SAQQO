import 'yandex_web_gateway_stub.dart'
    if (dart.library.js_interop) 'yandex_web_gateway.dart';
import 'api_configuration.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class PlaceResult {
  const PlaceResult({required this.name, required this.position});

  final String name;
  final LatLng position;
}

class RouteResult {
  const RouteResult({
    required this.points,
    required this.distanceMeters,
    required this.duration,
    this.demo = false,
  });

  final List<LatLng> points;
  final double distanceMeters;
  final Duration duration;
  final bool demo;
}

/// Yandex-only routing through the private SAQGO gateway.
///
/// Address and coordinate requests are sent only after an explicit user action.
/// Provider keys stay on the server and no query is persisted by this client.
class RoutingService {
  static String get _saqgoApiBaseUrl => ApiConfiguration.baseUrl;
  Future<PlaceResult?> searchPlace(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return null;
    final serverResult = await _searchWithSaqgoApi(normalized);
    if (serverResult != null) return serverResult;
    final payload = await browserGeocode(normalized);
    final results = payload?['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) return null;
    final result = results.first as Map<String, dynamic>;
    final point = result['point'] as Map<String, dynamic>;
    return PlaceResult(
      name: result['name'] as String,
      position: LatLng(
        (point['latitude'] as num).toDouble(),
        (point['longitude'] as num).toDouble(),
      ),
    );
  }

  Future<PlaceResult?> _searchWithSaqgoApi(String query) async {
    final uri = _serverUri('/v1/places', queryParameters: {'query': query});
    if (uri == null) return null;
    try {
      final response = await http
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final results = payload['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;
      final result = results.first as Map<String, dynamic>;
      final point = result['point'] as Map<String, dynamic>?;
      final latitude = (point?['latitude'] as num?)?.toDouble();
      final longitude = (point?['longitude'] as num?)?.toDouble();
      final name = result['name'] as String?;
      if (latitude == null || longitude == null || name == null) return null;
      return PlaceResult(name: name, position: LatLng(latitude, longitude));
    } catch (_) {
      return null;
    }
  }

  Future<RouteResult?> buildRoute({
    required LatLng from,
    required LatLng to,
    String mode = 'driving',
  }) async {
    final routes = await buildRoutes(from: from, to: to, mode: mode);
    return routes.isEmpty ? null : routes.first;
  }

  Future<List<RouteResult>> buildRoutes({
    required LatLng from,
    required LatLng to,
    String mode = 'driving',
  }) async {
    final serverRoutes = await _buildWithSaqgoApi(
      from: from,
      to: to,
      mode: mode,
    );
    if (serverRoutes.isNotEmpty) return serverRoutes;
    final payload = await browserRoutes(
      [from.latitude, from.longitude],
      [to.latitude, to.longitude],
      mode,
    );
    return payload == null ? const [] : parseSaqgoRoutePayload(payload);
  }

  Future<List<RouteResult>> _buildWithSaqgoApi({
    required LatLng from,
    required LatLng to,
    required String mode,
  }) async {
    final uri = _serverUri('/v1/routes');
    if (uri == null) return const [];
    try {
      final response = await http
          .post(
            uri,
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'origin': {
                'latitude': from.latitude,
                'longitude': from.longitude,
              },
              'destination': {
                'latitude': to.latitude,
                'longitude': to.longitude,
              },
              'mode': mode,
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return const [];
      return parseSaqgoRoutePayload(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } catch (_) {
      return const [];
    }
  }

  Uri? _serverUri(String endpoint, {Map<String, String>? queryParameters}) {
    if (_saqgoApiBaseUrl.isEmpty) return null;
    final base = Uri.tryParse(_saqgoApiBaseUrl);
    if (base == null || !base.hasScheme) return null;
    final root = base.path.replaceFirst(RegExp(r'/$'), '');
    return base.replace(
      path: '$root$endpoint',
      queryParameters: queryParameters,
    );
  }

  @visibleForTesting
  static List<RouteResult> parseSaqgoRoutePayload(
    Map<String, dynamic> payload,
  ) {
    final candidates = <Object?>[];
    if (payload['route'] != null) candidates.add(payload['route']);
    final alternativeRoutes = payload['routes'];
    if (alternativeRoutes is List<dynamic>) {
      candidates.addAll(alternativeRoutes);
    }

    final parsed = <RouteResult>[];
    for (final candidate in candidates) {
      if (candidate is! Map<String, dynamic>) continue;
      final legs = candidate['legs'];
      if (legs is! List<dynamic>) continue;
      final points = <LatLng>[];
      var distanceMeters = 0.0;
      var durationSeconds = 0.0;
      var valid = true;
      for (final rawLeg in legs) {
        if (rawLeg is! Map<String, dynamic> || rawLeg['status'] != 'OK') {
          valid = false;
          break;
        }
        final steps = rawLeg['steps'];
        if (steps is! List<dynamic>) continue;
        for (final rawStep in steps) {
          if (rawStep is! Map<String, dynamic>) continue;
          distanceMeters += (rawStep['length'] as num?)?.toDouble() ?? 0;
          durationSeconds += (rawStep['duration'] as num?)?.toDouble() ?? 0;
          final polyline = rawStep['polyline'];
          if (polyline is! Map<String, dynamic>) continue;
          final rawPoints = polyline['points'];
          if (rawPoints is! List<dynamic>) continue;
          for (final rawPoint in rawPoints) {
            if (rawPoint is! List<dynamic> || rawPoint.length < 2) continue;
            final rawLatitude = rawPoint[0];
            final rawLongitude = rawPoint[1];
            if (rawLatitude is! num || rawLongitude is! num) continue;
            final latitude = rawLatitude.toDouble();
            final longitude = rawLongitude.toDouble();
            if (!latitude.isFinite ||
                !longitude.isFinite ||
                latitude.abs() > 90 ||
                longitude.abs() > 180) {
              continue;
            }
            final point = LatLng(latitude, longitude);
            if (points.isEmpty ||
                points.last.latitude != point.latitude ||
                points.last.longitude != point.longitude) {
              points.add(point);
            }
          }
        }
      }
      if (valid && points.length >= 2) {
        parsed.add(
          RouteResult(
            points: List.unmodifiable(points),
            distanceMeters: distanceMeters,
            duration: Duration(seconds: durationSeconds.round()),
          ),
        );
      }
    }
    return List.unmodifiable(parsed);
  }
}
