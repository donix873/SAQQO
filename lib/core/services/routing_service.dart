import 'dart:convert';

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
  });

  final List<LatLng> points;
  final double distanceMeters;
  final Duration duration;
}

/// Public-map adapter for MVP routing. It sends a user-entered query only after
/// the person explicitly presses search; no locations are persisted remotely.
class RoutingService {
  static const _saqgoApiBaseUrl = String.fromEnvironment('SAQGO_API_BASE_URL');
  static const _headers = {
    'User-Agent': 'SAQGO-MVP/0.1 contact: repository-owner',
  };

  // Search is intentionally limited to Arkalyk. Without this restriction a
  // short street name can resolve to another city and produce a misleading
  // route hundreds of kilometres away.
  static const _arkalykViewBox = '66.45,50.48,67.38,50.05';

  Future<PlaceResult?> searchPlace(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return null;
    final serverResult = await _searchWithSaqgoApi(normalized);
    if (serverResult != null) return serverResult;
    final localQuery =
        normalized.toLowerCase().contains('аркалык') ||
            normalized.toLowerCase().contains('arkalyk')
        ? normalized
        : '$normalized, Аркалык, Казахстан';
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': localQuery,
      'format': 'jsonv2',
      'limit': '1',
      'countrycodes': 'kz',
      'viewbox': _arkalykViewBox,
      'bounded': '1',
    });
    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as List<dynamic>;
      if (data.isEmpty) return null;
      final item = data.first as Map<String, dynamic>;
      final latitude = double.tryParse(item['lat'] as String? ?? '');
      final longitude = double.tryParse(item['lon'] as String? ?? '');
      final name = item['display_name'] as String?;
      if (latitude == null || longitude == null || name == null) return null;
      return PlaceResult(name: name, position: LatLng(latitude, longitude));
    } catch (_) {
      return null;
    }
  }

  Future<PlaceResult?> _searchWithSaqgoApi(String query) async {
    if (_saqgoApiBaseUrl.isEmpty) return null;
    final base = Uri.tryParse(_saqgoApiBaseUrl);
    if (base == null || !base.hasScheme) return null;
    final uri = base.replace(
      path: '${base.path.replaceFirst(RegExp(r'/$'), '')}/v1/places',
      queryParameters: {'query': query},
    );
    try {
      final response = await http
          .get(uri, headers: _headers)
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
  }) async {
    final routes = await buildRoutes(from: from, to: to);
    return routes.isEmpty ? null : routes.first;
  }

  Future<List<RouteResult>> buildRoutes({
    required LatLng from,
    required LatLng to,
  }) async {
    final path =
        '/route/v1/driving/${from.longitude},${from.latitude};${to.longitude},${to.latitude}';
    final uri = Uri.https('router.project-osrm.org', path, {
      'overview': 'full',
      'geometries': 'geojson',
      'alternatives': 'true',
    });
    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return const [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return const [];
      return routes
          .map((rawRoute) {
            final route = rawRoute as Map<String, dynamic>;
            final coordinates =
                ((route['geometry'] as Map<String, dynamic>)['coordinates']
                        as List<dynamic>)
                    .cast<List<dynamic>>();
            final points = coordinates
                .map(
                  (coordinate) => LatLng(
                    (coordinate[1] as num).toDouble(),
                    (coordinate[0] as num).toDouble(),
                  ),
                )
                .toList(growable: false);
            return RouteResult(
              points: points,
              distanceMeters: (route['distance'] as num).toDouble(),
              duration: Duration(seconds: (route['duration'] as num).round()),
            );
          })
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }
}
