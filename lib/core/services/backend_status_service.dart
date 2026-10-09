import 'dart:convert';

import 'package:http/http.dart' as http;

class BackendStatus {
  const BackendStatus({
    required this.configured,
    required this.reachable,
    required this.geocoding,
    required this.routing,
    required this.distanceMatrix,
  });

  final bool configured;
  final bool reachable;
  final bool geocoding;
  final bool routing;
  final bool distanceMatrix;
}

/// Reads only the server's public capability flags. No keys, coordinates, or
/// addresses are returned by this endpoint or stored by the client.
class BackendStatusService {
  static const _apiBaseUrl = String.fromEnvironment('SAQGO_API_BASE_URL');

  Future<BackendStatus> check() async {
    final base = Uri.tryParse(_apiBaseUrl);
    if (_apiBaseUrl.isEmpty || base == null || !base.hasScheme) {
      return const BackendStatus(
        configured: false,
        reachable: false,
        geocoding: false,
        routing: false,
        distanceMatrix: false,
      );
    }

    final root = base.path.replaceFirst(RegExp(r'/$'), '');
    final uri = base.replace(path: '$root/v1/capabilities');
    try {
      final response = await http
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        return const BackendStatus(
          configured: true,
          reachable: false,
          geocoding: false,
          routing: false,
          distanceMatrix: false,
        );
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return BackendStatus(
        configured: true,
        reachable: true,
        geocoding: data['geocoding'] == true,
        routing: data['routing'] == true,
        distanceMatrix: data['distance_matrix'] == true,
      );
    } catch (_) {
      return const BackendStatus(
        configured: true,
        reachable: false,
        geocoding: false,
        routing: false,
        distanceMatrix: false,
      );
    }
  }
}
