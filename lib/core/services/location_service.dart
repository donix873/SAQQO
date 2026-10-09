import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

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
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      return LocationResult.available(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
      );
    } catch (_) {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        return LocationResult.available(
          latitude: lastKnown.latitude,
          longitude: lastKnown.longitude,
          accuracyMeters: lastKnown.accuracy,
        );
      }
      return const LocationResult.unavailable();
    }
  }

  Stream<LocationAvailable> positionUpdates() =>
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
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
