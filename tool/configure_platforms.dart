import 'dart:io';

void main() {
  final android = File('android/app/src/main/AndroidManifest.xml');
  final ios = File('ios/Runner/Info.plist');
  if (!android.existsSync() || !ios.existsSync()) {
    stderr.writeln('Run flutter create before configuring Android and iOS.');
    exitCode = 1;
    return;
  }
  var manifest = android.readAsStringSync();
  for (final permission in const [
    'android.permission.INTERNET',
    'android.permission.ACCESS_FINE_LOCATION',
    'android.permission.ACCESS_COARSE_LOCATION',
  ]) {
    final tag = '<uses-permission android:name="$permission"/>';
    if (!manifest.contains(permission)) {
      manifest = manifest.replaceFirst(
        '<application',
        '$tag\n    <application',
      );
    }
  }
  manifest = manifest.replaceFirst(
    'android:label="saqgo"',
    'android:label="SAQGO"',
  );
  android.writeAsStringSync(manifest);

  var plist = ios.readAsStringSync();
  const values = {
    'NSLocationWhenInUseUsageDescription':
        'SAQGO uses your location only when you request a map location or start a voluntary session.',
    'NSMotionUsageDescription':
        'SAQGO reads motion sensors only during a session you explicitly start.',
  };
  for (final entry in values.entries) {
    if (!plist.contains('<key>${entry.key}</key>')) {
      plist = plist.replaceFirst(
        '</dict>',
        '  <key>${entry.key}</key>\n  <string>${entry.value}</string>\n</dict>',
      );
    }
  }
  ios.writeAsStringSync(plist);
}
