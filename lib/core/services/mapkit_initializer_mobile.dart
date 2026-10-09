import 'dart:io';

import 'package:yandex_maps_mapkit_lite/init.dart' as yandex_init;

const _apiKey = String.fromEnvironment('YANDEX_MAPKIT_API_KEY');
var _ready = false;

bool get isMapkitReady => _ready;

Future<void> initializeMapkit() async {
  if (_apiKey.isEmpty || (!Platform.isAndroid && !Platform.isIOS)) return;
  try {
    await yandex_init.initMapkit(apiKey: _apiKey);
    _ready = true;
  } catch (_) {
    // A missing, invalid, or platform-restricted key must not prevent SAQGO
    // from starting. The map widget will use its non-secret fallback.
    _ready = false;
  }
}
