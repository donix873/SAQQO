import 'package:flutter/foundation.dart';

/// Browser deployments can serve the client and API from the same origin.
class ApiConfiguration {
  static String get baseUrl {
    const configured = String.fromEnvironment('SAQGO_API_BASE_URL');
    if (configured.isNotEmpty) return configured;
    return kIsWeb ? Uri.base.origin : '';
  }
}
