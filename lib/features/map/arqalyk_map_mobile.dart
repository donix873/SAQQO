import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:yandex_maps_mapkit_lite/mapkit.dart' as yandex;
import 'package:yandex_maps_mapkit_lite/yandex_map.dart' as yandex_ui;

import '../../core/services/mapkit_initializer.dart';
import '../../core/theme/radii.dart';

/// Uses the official Yandex MapKit SDK on Android/iOS when its restricted
/// mobile key is supplied. OpenStreetMap remains a non-secret fallback for
/// local development and builds where MapKit was not configured.
class ArqalykMap extends StatefulWidget {
  const ArqalykMap({super.key, this.userLocation, this.routePoints = const []});

  final LatLng? userLocation;
  final List<LatLng> routePoints;

  @override
  State<ArqalykMap> createState() => _ArqalykMapState();
}

class _ArqalykMapState extends State<ArqalykMap> {
  static const _arkalyk = LatLng(50.2486, 66.9203);
  static const _yandexArkalyk = yandex.Point(
    latitude: 50.2486,
    longitude: 66.9203,
  );

  final _fallbackController = MapController();
  yandex.MapWindow? _mapWindow;
  yandex.MapObjectCollection? _mapObjects;

  bool get _usesYandex => isMapkitReady;

  List<yandex.Point> get _yandexRoute => widget.routePoints
      .map(
        (point) => yandex.Point(
          latitude: point.latitude,
          longitude: point.longitude,
        ),
      )
      .toList(growable: false);

  @override
  void didUpdateWidget(covariant ArqalykMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_usesYandex) {
      _updateYandexMap();
      return;
    }
    if (widget.routePoints.length > 1 &&
        widget.routePoints != oldWidget.routePoints) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitFallbackRoute());
    } else if (widget.userLocation != null &&
        widget.userLocation != oldWidget.userLocation) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _fallbackController.move(widget.userLocation!, 16),
      );
    }
  }

  void _onYandexMapCreated(yandex.MapWindow mapWindow) {
    _mapWindow = mapWindow;
    _mapObjects = mapWindow.map.mapObjects.addCollection();
    _updateYandexMap();
  }

  void _updateYandexMap() {
    final mapWindow = _mapWindow;
    final objects = _mapObjects;
    if (mapWindow == null || objects == null) return;

    objects.clear();
    final route = _yandexRoute;
    if (route.length > 1) {
      final polyline = yandex.Polyline(route);
      objects.addPolylineWithGeometry(polyline)
        ..style = const yandex.LineStyle(
          strokeWidth: 6,
          outlineWidth: 2,
          outlineColor: Color(0x990A3866),
        )
        ..setStrokeColor(const Color(0xFF0577E6));
      mapWindow.map.move(
        mapWindow.map.cameraPositionForGeometry(
          yandex.Geometry.fromPolyline(polyline),
        ),
        animation: const yandex.Animation(
          type: yandex.AnimationType.Smooth,
          duration: 0.4,
        ),
      );
    } else {
      final location = widget.userLocation;
      final target = location == null
          ? _yandexArkalyk
          : yandex.Point(
              latitude: location.latitude,
              longitude: location.longitude,
            );
      mapWindow.map.move(
        yandex.CameraPosition(
          target,
          zoom: location == null ? 13 : 16,
          azimuth: 0,
          tilt: 0,
        ),
        animation: const yandex.Animation(
          type: yandex.AnimationType.Smooth,
          duration: 0.35,
        ),
      );
    }

    final location = widget.userLocation;
    if (location != null) {
      objects.addCircle(
        yandex.Circle(
          yandex.Point(
            latitude: location.latitude,
            longitude: location.longitude,
          ),
          radius: 12,
        ),
      )
        ..fillColor = const Color(0xFF0577E6)
        ..strokeColor = Colors.white
        ..strokeWidth = 4;
    }
  }

  void _fitFallbackRoute() {
    if (widget.routePoints.length < 2) return;
    _fallbackController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(widget.routePoints),
        padding: const EdgeInsets.all(42),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_usesYandex) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFE9F0F6),
          borderRadius: BorderRadius.circular(SaqgoRadii.card),
        ),
        child: yandex_ui.YandexMap(
          onMapCreated: _onYandexMapCreated,
        ),
      );
    }
    return _OpenStreetMap(
      mapController: _fallbackController,
      userLocation: widget.userLocation,
      routePoints: widget.routePoints,
      onMapReady: _fitFallbackRoute,
    );
  }
}

class _OpenStreetMap extends StatelessWidget {
  const _OpenStreetMap({
    required this.mapController,
    required this.userLocation,
    required this.routePoints,
    required this.onMapReady,
  });

  final MapController mapController;
  final LatLng? userLocation;
  final List<LatLng> routePoints;
  final VoidCallback onMapReady;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFFE9F0F6),
      borderRadius: BorderRadius.circular(SaqgoRadii.card),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(SaqgoRadii.card),
      child: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          initialCenter: routePoints.isNotEmpty
              ? routePoints.first
              : (userLocation ?? _ArqalykMapState._arkalyk),
          initialZoom: routePoints.isNotEmpty ? 14 : 13,
          onMapReady: onMapReady,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'kz.saqgo.saqgo',
          ),
          if (routePoints.length > 1)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: routePoints,
                  strokeWidth: 6,
                  color: const Color(0xFF0577E6),
                  borderColor: const Color(0x990A3866),
                  borderStrokeWidth: 2,
                ),
              ],
            ),
          if (userLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: userLocation!,
                  width: 46,
                  height: 46,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0577E6),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: const [
                        BoxShadow(color: Colors.black38, blurRadius: 10),
                      ],
                    ),
                    child: const Icon(
                      Icons.navigation_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          RichAttributionWidget(
            attributions: const [
              TextSourceAttribution('© OpenStreetMap contributors'),
            ],
          ),
        ],
      ),
    ),
  );
}
