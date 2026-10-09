import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/radii.dart';

/// Stable native fallback while the browser uses the Yandex JavaScript map.
class ArqalykMap extends StatefulWidget {
  const ArqalykMap({super.key, this.userLocation, this.routePoints = const []});

  final LatLng? userLocation;
  final List<LatLng> routePoints;

  @override
  State<ArqalykMap> createState() => _ArqalykMapState();
}

class _ArqalykMapState extends State<ArqalykMap> {
  static const _arkalyk = LatLng(50.2486, 66.9203);
  final _mapController = MapController();

  @override
  void didUpdateWidget(covariant ArqalykMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.routePoints.length > 1 &&
        widget.routePoints != oldWidget.routePoints) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitRoute());
    } else if (widget.userLocation != null &&
        widget.userLocation != oldWidget.userLocation) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _mapController.move(widget.userLocation!, 16),
      );
    }
  }

  void _fitRoute() {
    if (widget.routePoints.length < 2) return;
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(widget.routePoints),
        padding: const EdgeInsets.all(42),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFFE9F0F6),
      borderRadius: BorderRadius.circular(SaqgoRadii.card),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(SaqgoRadii.card),
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: widget.routePoints.isNotEmpty
              ? widget.routePoints.first
              : (widget.userLocation ?? _arkalyk),
          initialZoom: widget.routePoints.isNotEmpty ? 14 : 13,
          onMapReady: _fitRoute,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'kz.saqgo.saqgo',
          ),
          if (widget.routePoints.length > 1)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: widget.routePoints,
                  strokeWidth: 6,
                  color: const Color(0xFF0577E6),
                  borderColor: const Color(0x990A3866),
                  borderStrokeWidth: 2,
                ),
              ],
            ),
          if (widget.userLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: widget.userLocation!,
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
