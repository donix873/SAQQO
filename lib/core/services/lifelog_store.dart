import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LifeLogStore {
  static const _key = 'saqgo_has_demo_trip';
  static final hasDemoTrip = ValueNotifier<bool>(false);

  static Future<void> restore() async {
    hasDemoTrip.value =
        (await SharedPreferences.getInstance()).getBool(_key) ?? false;
  }

  static Future<void> setDemoTrip(bool value) async {
    hasDemoTrip.value = value;
    await (await SharedPreferences.getInstance()).setBool(_key, value);
  }
}
