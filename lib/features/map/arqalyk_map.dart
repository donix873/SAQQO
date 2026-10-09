import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import '../../core/theme/radii.dart';

/// The shared live map. Route coordinates use [LatLng] in the rest of the
/// application and are converted here for the native Yandex MapKit view.
class ArqalykMap extends StatefulWidget {
  const ArqalykMap({super.key, this.userLocation, this.routePoints = const []});

  final LatLng? userLocation;
  final List<LatLng> routePoints;

  @override
  State<ArqalykMap> createState() => _ArqalykMapState();
}

class _ArqalykMapState extends State<ArqalykMap> {
  // A stable initial view means the map remains useful before GPS is allowed.
  static const _arkalyk = Point(latitude: 50.2486, longitude: 66.9203);
  YandexMapController? _controller;

  List<Point> get _route => widget.routePoints
      .map(
        (point) => Point(latitude: point.latitude, longitude: point.longitude),
      )
      .toList(growable: false);

  @override
  void didUpdateWidget(covariant ArqalykMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.routePoints.length > 1 &&
        widget.routePoints != oldWidget.routePoints) {
      _fitRoute();
    } else if (widget.userLocation != null &&
        widget.userLocation != oldWidget.userLocation) {
      _focusUser();
    }
  }

  Future<void> _onMapCreated(YandexMapController controller) async {
    _controller = controller;
    await controller.toggleUserLayer(
      visible: true,
      headingEnabled: true,
      autoZoomEnabled: false,
    );
    if (widget.routePoints.length > 1) {
      await _fitRoute();
    } else if (widget.userLocation != null) {
      await _focusUser();
    } else {
      await controller.moveCamera(
        CameraUpdate.newCameraPosition(
          const CameraPosition(target: _arkalyk, zoom: 13),
        ),
      );
    }
  }

  Future<void> _focusUser() async {
    final location = widget.userLocation;
    final controller = _controller;
    if (location == null || controller == null) return;
    await controller.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: Point(
            latitude: location.latitude,
            longitude: location.longitude,
          ),
          zoom: 16,
        ),
      ),
      animation: const MapAnimation(duration: 0.35),
    );
  }

  Future<void> _fitRoute() async {
    final controller = _controller;
    if (controller == null || _route.length < 2) return;
    await controller.moveCamera(
      CameraUpdate.newGeometry(Geometry.fromPolyline(Polyline(points: _route))),
      animation: const MapAnimation(duration: 0.4),
    );
    await controller.moveCamera(
      CameraUpdate.zoomOut(),
      animation: const MapAnimation(duration: 0.2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final route = _route;
    return ClipRRect(
      borderRadius: BorderRadius.circular(SaqgoRadii.card),
      child: YandexMap(
        nightModeEnabled: true,
        mapType: MapType.vector,
        logoPadding: const MapPadding(horizontal: 10, vertical: 10),
        onMapCreated: _onMapCreated,
        mapObjects: [
          if (route.length > 1)
            PolylineMapObject(
              mapId: const MapObjectId('selected-route'),
              polyline: Polyline(points: route),
              zIndex: 3,
              strokeColor: const Color(0xFF57B8FF),
              strokeWidth: 6,
              outlineColor: const Color(0x99102136),
              outlineWidth: 2,
              isInnerOutlineEnabled: true,
            ),
        ],
      ),
    );
  }
}
