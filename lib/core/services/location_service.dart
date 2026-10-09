import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  static final latest = ValueNotifier<LocationAvailable?>(null);
  Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<LocationResult> requestCurrentLocation() async {
    try {
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
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      final result = LocationAvailable(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
      );
      latest.value = result;
      return result;
    } catch (_) {
      return const LocationResult.unavailable();
    }
  }

  Stream<LocationAvailable> positionUpdates() =>
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          // Browsers may have only network-based location (especially laptops).
          accuracy: kIsWeb ? LocationAccuracy.medium : LocationAccuracy.high,
          distanceFilter: 3,
        ),
      ).map(
        (position) => LocationAvailable(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracyMeters: position.accuracy,
        ),
      );
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
