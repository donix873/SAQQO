import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Resolves the default city from OpenStreetMap's Nominatim service.
/// No fallback coordinates are used: a failed lookup must remain visibly unavailable.
class ArqalykMapService {
  static final _uri = Uri.https('nominatim.openstreetmap.org', '/search', {
    'city': 'Arkalyk',
    'country': 'Kazakhstan',
    'format': 'jsonv2',
    'limit': '1',
  });

  Future<LatLng?> resolveCity() async {
    final response = await http
        .get(
          _uri,
          headers: const {
            'User-Agent': 'SAQGO-MVP/0.1 contact: repository-owner',
          },
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body) as List<dynamic>;
    if (data.isEmpty) return null;
    final item = data.first as Map<String, dynamic>;
    final latitude = double.tryParse(item['lat'] as String? ?? '');
    final longitude = double.tryParse(item['lon'] as String? ?? '');
    if (latitude == null || longitude == null) return null;
    return LatLng(latitude, longitude);
  }
}
