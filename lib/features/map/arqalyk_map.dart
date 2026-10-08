import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/services/arqalyk_map_service.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radii.dart';
import '../../core/theme/typography.dart';
import '../../l10n/app_localizations.dart';

class ArqalykMap extends StatefulWidget {
  const ArqalykMap({super.key});
  @override
  State<ArqalykMap> createState() => _ArqalykMapState();
}

class _ArqalykMapState extends State<ArqalykMap> {
  late final Future<LatLng?> _city = ArqalykMapService().resolveCity();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return FutureBuilder<LatLng?>(
      future: _city,
      builder: (context, snapshot) {
        final city = snapshot.data;
        if (city == null) return _Unavailable(message: snapshot.connectionState == ConnectionState.waiting ? l.mapUnavailable : l.mapUnavailable);
        return ClipRRect(
          borderRadius: BorderRadius.circular(SaqgoRadii.card),
          child: FlutterMap(
            options: MapOptions(initialCenter: city, initialZoom: 13),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'kz.saqgo.app',
              ),
              RichAttributionWidget(
                attributions: [TextSourceAttribution('© OpenStreetMap contributors')],
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
    decoration: BoxDecoration(color: const Color(0xFF0F1C2A), borderRadius: BorderRadius.circular(SaqgoRadii.card)),
    alignment: Alignment.center,
    child: Padding(padding: const EdgeInsets.all(32), child: Text(message, style: SaqgoTypography.body, textAlign: TextAlign.center)),
  );
}
