import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConsentService {
  static const version = '1.3';
  static final recording = ValueNotifier(false);
  static final alerts = ValueNotifier(false);
  static Future<void> restore() async {
    final preferences = await SharedPreferences.getInstance();
    recording.value =
        preferences.getBool('saqgo_recording_consent_$version') ?? false;
    alerts.value =
        preferences.getBool('saqgo_alerts_consent_$version') ?? false;
  }

  static Future<void> setRecording(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('saqgo_recording_consent_$version', enabled);
    await preferences.setString(
      'saqgo_recording_consent_at',
      DateTime.now().toUtc().toIso8601String(),
    );
    recording.value = enabled;
  }

  static Future<void> setAlerts(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('saqgo_alerts_consent_$version', enabled);
    alerts.value = enabled;
  }
}
