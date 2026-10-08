import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<LocationResult> requestCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const LocationResult.disabled();
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return const LocationResult.denied();
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      return LocationResult.available(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
      );
    } catch (_) {
      return const LocationResult.unavailable();
    }
  }
}

sealed class LocationResult {
  const LocationResult();
  const factory LocationResult.available({
    required double latitude,
    required double longitude,
    required double accuracyMeters,
  }) = LocationAvailable;
  const factory LocationResult.disabled() = LocationDisabled;
  const factory LocationResult.denied() = LocationDenied;
  const factory LocationResult.unavailable() = LocationUnavailable;
}

class LocationAvailable extends LocationResult {
  const LocationAvailable({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
  });
  final double latitude, longitude, accuracyMeters;
}

class LocationDisabled extends LocationResult {
  const LocationDisabled();
}

class LocationDenied extends LocationResult {
  const LocationDenied();
}

class LocationUnavailable extends LocationResult {
  const LocationUnavailable();
}
