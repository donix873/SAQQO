import 'package:shared_preferences/shared_preferences.dart';

class LifeLogStore {
  static const _key = 'saqgo_has_demo_trip';
  Future<bool> hasDemoTrip() async => (await SharedPreferences.getInstance()).getBool(_key) ?? false;
  Future<void> setHasDemoTrip(bool value) async => (await SharedPreferences.getInstance()).setBool(_key, value);
}
