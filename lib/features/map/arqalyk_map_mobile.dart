import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'presentation_map.dart';
import '../../core/services/hazard_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:yandex_maps_mapkit_lite/mapkit.dart' as yandex;
import 'package:yandex_maps_mapkit_lite/yandex_map.dart' as yandex_ui;

import '../../core/services/mapkit_initializer.dart';
import '../../core/theme/radii.dart';

/// Uses the official Yandex MapKit SDK on Android/iOS when its restricted
/// mobile key is supplied. OpenStreetMap remains a non-secret fallback for
/// local development and builds where MapKit was not configured.
class ArqalykMap extends StatefulWidget {
  const ArqalykMap({
    super.key,
    this.userLocation,
    this.routePoints = const [],
    this.routeSegments = const [],
    this.hazards = const [],
    this.onHazardSelected,
  });

  final LatLng? userLocation;
  final List<LatLng> routePoints;
  final List<List<LatLng>> routeSegments;
  final List<Hazard> hazards;
  final ValueChanged<Hazard>? onHazardSelected;

  @override
  State<ArqalykMap> createState() => _ArqalykMapState();
}

class _ArqalykMapState extends State<ArqalykMap> {
  static const _yandexArkalyk = yandex.Point(
    latitude: 50.2486,
    longitude: 66.9203,
  );

  yandex.MapWindow? _mapWindow;
  yandex.MapObjectCollection? _mapObjects;
  final _listeners = <_HazardTap>[];
  List<LatLng>? _fittedRoute;

  bool get _usesYandex => isMapkitReady;

  List<yandex.Point> get _yandexRoute => widget.routePoints
      .map(
        (point) =>
            yandex.Point(latitude: point.latitude, longitude: point.longitude),
      )
      .toList(growable: false);

  @override
  void didUpdateWidget(covariant ArqalykMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_usesYandex) {
      _updateYandexMap();
      return;
    }
  }

  void _onYandexMapCreated(yandex.MapWindow mapWindow) {
    mapWindow.map.nightModeEnabled = true;
    _mapWindow = mapWindow;
    _mapObjects = mapWindow.map.mapObjects.addCollection();
    _updateYandexMap();
  }

  void _updateYandexMap() {
    final mapWindow = _mapWindow;
    final objects = _mapObjects;
    if (mapWindow == null || objects == null) return;

    objects.clear();
    _listeners.clear();
    final route = _yandexRoute;
    if (route.length > 1) {
      final segments = widget.routeSegments.isEmpty
          ? [route]
          : widget.routeSegments
                .map(
                  (segment) => segment
                      .map(
                        (p) => yandex.Point(
                          latitude: p.latitude,
                          longitude: p.longitude,
                        ),
                      )
                      .toList(),
                )
                .toList();
      final polyline = yandex.Polyline(route);
      for (final segment in segments.where((s) => s.length > 1)) {
        final segmentPolyline = yandex.Polyline(segment);
        objects.addPolylineWithGeometry(segmentPolyline)
          ..style = const yandex.LineStyle(
            strokeWidth: 6,
            outlineWidth: 2,
            outlineColor: Color(0x990A3866),
          )
          ..setStrokeColor(const Color(0xFF0577E6));
      }
      if (_fittedRoute != widget.routePoints) {
        _fittedRoute = widget.routePoints;
        mapWindow.map.move(
          mapWindow.map.cameraPositionForGeometry(
            yandex.Geometry.fromPolyline(polyline),
          ),
          animation: const yandex.Animation(
            type: yandex.AnimationType.Smooth,
            duration: 0.4,
          ),
        );
      }
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

    for (final hazard in widget.hazards) {
      final listener = _HazardTap(() => widget.onHazardSelected?.call(hazard));
      _listeners.add(listener);
      objects.addCircle(
          yandex.Circle(
            yandex.Point(
              latitude: hazard.position.latitude,
              longitude: hazard.position.longitude,
            ),
            radius: hazard.accuracyMeters,
          ),
        )
        ..fillColor = hazard.demo
            ? const Color(0x669263EE)
            : const Color(0x66E6505F)
        ..strokeColor = hazard.demo
            ? const Color(0xFF9263EE)
            : const Color(0xFFE6505F)
        ..strokeWidth = 3
        ..addTapListener(listener);
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

  @override
  Widget build(BuildContext context) {
    if (_usesYandex) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFE9F0F6),
          borderRadius: BorderRadius.circular(SaqgoRadii.card),
        ),
        child: yandex_ui.YandexMap(onMapCreated: _onYandexMapCreated),
      );
    }
    if (HazardService.layers.value['demo'] == true) {
      return const PresentationMap();
    }
    final l = AppLocalizations.of(context)!;
    return ColoredBox(
      color: const Color(0xFF09111E),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l.yandexKeyRequired, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

class _HazardTap implements yandex.MapObjectTapListener {
  _HazardTap(this.callback);
  final VoidCallback callback;
  @override
  bool onMapObjectTap(yandex.MapObject object, yandex.Point point) {
    callback();
    return true;
  }
}
