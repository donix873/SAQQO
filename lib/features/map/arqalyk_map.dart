import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/services/arqalyk_map_service.dart';
import '../../core/theme/radii.dart';
import '../../core/theme/typography.dart';
import '../../l10n/app_localizations.dart';

class ArqalykMap extends StatefulWidget {
  const ArqalykMap({super.key, this.userLocation, this.routePoints = const []});
  final LatLng? userLocation;
  final List<LatLng> routePoints;
  @override
  State<ArqalykMap> createState() => _ArqalykMapState();
}

class _ArqalykMapState extends State<ArqalykMap> {
  late final Future<LatLng?> _city = ArqalykMapService().resolveCity();
  final _mapController = MapController();

  @override
  void didUpdateWidget(covariant ArqalykMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userLocation != null &&
        widget.userLocation != oldWidget.userLocation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(widget.userLocation!, 16);
      });
    }
    if (widget.routePoints.length > 1 &&
        widget.routePoints != oldWidget.routePoints) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitRoute());
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
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return FutureBuilder<LatLng?>(
      future: _city,
      builder: (context, snapshot) {
        final city = snapshot.data;
        if (city == null) {
          return _Unavailable(message: l.mapUnavailable);
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(SaqgoRadii.card),
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.routePoints.isEmpty
                  ? city
                  : widget.routePoints.first,
              initialZoom: widget.routePoints.isEmpty ? 13 : 14,
              onMapReady: _fitRoute,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'kz.saqgo.app',
              ),
              if (widget.routePoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: widget.routePoints,
                      strokeWidth: 5,
                      color: const Color(0xFF4A90FF),
                    ),
                  ],
                ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('© OpenStreetMap contributors'),
                ],
              ),
              if (widget.userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: widget.userLocation!,
                      width: 42,
                      height: 42,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A90FF),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Colors.black38, blurRadius: 8),
                          ],
                        ),
                        child: const Icon(
                          Icons.my_location_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF0F1C2A),
      borderRadius: BorderRadius.circular(SaqgoRadii.card),
    ),
    alignment: Alignment.center,
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        message,
        style: SaqgoTypography.body,
        textAlign: TextAlign.center,
      ),
    ),
  );
}
