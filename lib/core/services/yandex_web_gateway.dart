import 'dart:convert';
import 'dart:js_interop';

@JS('saqgoYandexGeocode')
external JSPromise<JSString> _geocode(JSString key, JSString query);
@JS('saqgoYandexRoutes')
external JSPromise<JSString> _routes(
  JSString key,
  JSString from,
  JSString to,
  JSString mode,
);
const _key = String.fromEnvironment('YANDEX_JS_API_KEY');
Future<Map<String, dynamic>?> browserGeocode(String query) async {
  if (_key.isEmpty) return null;
  try {
    return jsonDecode((await _geocode(_key.toJS, query.toJS).toDart).toDart)
        as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

Future<Map<String, dynamic>?> browserRoutes(
  List<double> from,
  List<double> to,
  String mode,
) async {
  if (_key.isEmpty) return null;
  try {
    return jsonDecode(
          (await _routes(
            _key.toJS,
            jsonEncode(from).toJS,
            jsonEncode(to).toJS,
            mode.toJS,
          ).toDart).toDart,
        )
        as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}
