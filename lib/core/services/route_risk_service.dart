import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import 'hazard_service.dart';

/// Counts current known hazards near a route; missing coverage remains unknown.
class RouteRiskService {
  static int knownRisks(List<LatLng> route, List<Hazard> hazards) {
    return hazards
        .where(
          (hazard) =>
              !hazard.demo &&
              hazard.active &&
              hazard.status == 'verified' &&
              distanceToRoute(hazard.position, route) <=
                  math.max(30, hazard.accuracyMeters),
        )
        .length;
  }

  static double distanceToRoute(LatLng point, List<LatLng> route) {
    if (route.isEmpty) return double.infinity;
    const distance = Distance();
    if (route.length == 1) return distance(point, route.single);
    double minimum = double.infinity;
    final scaleX = 111320 * math.cos(point.latitude * math.pi / 180);
    const scaleY = 111320.0;
    for (var i = 1; i < route.length; i++) {
      final ax = (route[i - 1].longitude - point.longitude) * scaleX;
      final ay = (route[i - 1].latitude - point.latitude) * scaleY;
      final bx = (route[i].longitude - point.longitude) * scaleX;
      final by = (route[i].latitude - point.latitude) * scaleY;
      final dx = bx - ax, dy = by - ay;
      final length = dx * dx + dy * dy;
      final t = length == 0
          ? 0.0
          : (-(ax * dx + ay * dy) / length).clamp(0.0, 1.0);
      minimum = math.min(
        minimum,
        math.sqrt(math.pow(ax + t * dx, 2) + math.pow(ay + t * dy, 2)),
      );
    }
    return minimum;
  }
}
