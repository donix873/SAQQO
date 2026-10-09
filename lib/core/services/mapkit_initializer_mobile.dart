import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:yandex_maps_mapkit_lite/mapkit_factory.dart' as mapkit_factory;

import 'package:yandex_maps_mapkit_lite/init.dart' as yandex_init;

const _apiKey = String.fromEnvironment('YANDEX_MAPKIT_API_KEY');
var _ready = false;

bool get isMapkitReady => _ready;

Future<void> initializeMapkit() async {
  if (_apiKey.isEmpty || (!Platform.isAndroid && !Platform.isIOS)) return;
  try {
    await yandex_init.initMapkit(apiKey: _apiKey);
    mapkit_factory.mapkit.onStart();
    WidgetsBinding.instance.addObserver(_lifecycle);
    _ready = true;
  } catch (_) {
    // A missing, invalid, or platform-restricted key must not prevent SAQGO
    // from starting. The map widget will use its non-secret fallback.
    _ready = false;
  }
}

final _lifecycle = _MapkitLifecycle();

class _MapkitLifecycle extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!isMapkitReady) return;
    if (state == AppLifecycleState.resumed) {
      mapkit_factory.mapkit.onStart();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      mapkit_factory.mapkit.onStop();
    }
  }
}
