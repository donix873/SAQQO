// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/radii.dart';

/// Browser map backed by the official Yandex JavaScript API.
class ArqalykMap extends StatefulWidget {
  const ArqalykMap({super.key, this.userLocation, this.routePoints = const []});

  final LatLng? userLocation;
  final List<LatLng> routePoints;

  @override
  State<ArqalykMap> createState() => _ArqalykMapState();
}

class _ArqalykMapState extends State<ArqalykMap> {
  late final String _viewType;
  IFrameElement? _frame;

  @override
  void initState() {
    super.initState();
    _viewType = 'saqgo-yandex-map-${identityHashCode(this)}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (_) {
      final frame = IFrameElement()
        ..src = 'yandex_map.html'
        ..title = 'Карта Яндекса — Аркалык'
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
      'apiKey': const String.fromEnvironment('YANDEX_JS_API_KEY'),
      'user': widget.userLocation == null
          ? null
          : [widget.userLocation!.latitude, widget.userLocation!.longitude],
      'route': widget.routePoints
          .map((point) => [point.latitude, point.longitude])
          .toList(growable: false),
    });
    _frame?.contentWindow?.postMessage(payload, '*');
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendConfiguration());
    return ClipRRect(
      borderRadius: BorderRadius.circular(SaqgoRadii.card),
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
