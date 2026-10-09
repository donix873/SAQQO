import 'dart:io';

import 'package:yandex_maps_mapkit_lite/init.dart' as yandex_init;

const _apiKey = String.fromEnvironment('YANDEX_MAPKIT_API_KEY');

Future<void> initializeMapkit() async {
  if (_apiKey.isEmpty || (!Platform.isAndroid && !Platform.isIOS)) return;
  await yandex_init.initMapkit(apiKey: _apiKey);
}
