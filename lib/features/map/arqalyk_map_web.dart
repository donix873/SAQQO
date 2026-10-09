// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:async';
import 'dart:html';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/radii.dart';
import '../../core/services/hazard_service.dart';
import '../../l10n/app_localizations.dart';
import 'presentation_map.dart';

/// Browser map backed by the official Yandex JavaScript API.
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
  late final String _viewType;
  IFrameElement? _frame;
  StreamSubscription<MessageEvent>? _tapSubscription;

  @override
  void initState() {
    super.initState();
    _tapSubscription = window.onMessage.listen((event) {
      if (event.origin != window.location.origin ||
          event.source != _frame?.contentWindow) {
        return;
      }
      try {
        final data = jsonDecode(event.data as String) as Map<String, dynamic>;
        if (data['type'] != 'saqgo-hazard-tap') return;
        for (final hazard in widget.hazards) {
          if (hazard.id == data['id']) {
            widget.onHazardSelected?.call(hazard);
            break;
          }
        }
      } catch (_) {}
    });
    _viewType = 'saqgo-yandex-map-${identityHashCode(this)}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (_) {
      final frame = IFrameElement()
        ..src = 'yandex_map.html'
        ..title = AppLocalizations.of(context)!.map
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%';
      frame.onLoad.listen((_) => _sendConfiguration());
      _frame = frame;
      return frame;
    });
  }

  @override
  void didUpdateWidget(covariant ArqalykMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userLocation != oldWidget.userLocation ||
        widget.routePoints != oldWidget.routePoints) {
      _sendConfiguration();
    }
  }

  void _sendConfiguration() {
    final payload = jsonEncode({
      'type': 'saqgo-yandex-map',
      'locale': Localizations.localeOf(context).languageCode,
      'hazards': widget.hazards
          .map(
            (h) => {
              'id': h.id,
              'point': [h.position.latitude, h.position.longitude],
              'demo': h.demo,
              'confidence': h.confidence,
            },
          )
          .toList(),
      'apiKey': const String.fromEnvironment('YANDEX_JS_API_KEY'),
      'user': widget.userLocation == null
          ? null
          : [widget.userLocation!.latitude, widget.userLocation!.longitude],
      'segments': widget.routeSegments
          .map(
            (segment) => segment.map((p) => [p.latitude, p.longitude]).toList(),
          )
          .toList(),
      'route': widget.routePoints
          .map((point) => [point.latitude, point.longitude])
          .toList(growable: false),
    });
    _frame?.contentWindow?.postMessage(payload, window.location.origin);
  }

  @override
  void dispose() {
    _tapSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (const String.fromEnvironment('YANDEX_JS_API_KEY').isEmpty &&
        HazardService.layers.value['demo'] == true) {
      return const PresentationMap();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendConfiguration());
    return ClipRRect(
      borderRadius: BorderRadius.circular(SaqgoRadii.card),
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
