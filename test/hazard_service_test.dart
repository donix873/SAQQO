import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import 'package:saqgo/core/services/hazard_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  test('demo markers never produce real alerts; inaccurate GPS suppressed', () {
    final now = DateTime.now();
    final verified = Hazard(
      id: 'verified',
      position: const LatLng(50.25, 66.92),
      category: 'road_bump',
      status: 'verified',
      source: 'inspection',
      confidence: .8,
      accuracyMeters: 15,
      demo: false,
      expiresAt: now.add(const Duration(hours: 1)),
    );
    final alerts = HazardAlertService();
    expect(
      alerts.update(const LatLng(50.25, 66.92), 90, now, [verified]),
      isEmpty,
    );
    expect(
      alerts.update(
        const LatLng(50.25, 66.92),
        10,
        now,
        HazardService.presentationHazards,
      ),
      isEmpty,
    );
    expect(
      alerts.update(const LatLng(50.25, 66.92), 10, now, [verified]),
      hasLength(1),
    );
    expect(
      alerts.update(
        const LatLng(50.25, 66.92),
        10,
        now.add(const Duration(seconds: 1)),
        [verified],
      ),
      isEmpty,
    );
    expect(
      alerts.update(
        const LatLng(50.25, 66.92),
        10,
        now.add(const Duration(minutes: 6)),
        [verified],
      ),
      hasLength(1),
    );
  });
  test('layers and hidden markers filter the map; demo is explicit', () {
    HazardService.layers.value = {
      'road_bump': true,
      'demo': false,
      'onlyVerified': true,
    };
    HazardService.items.value = List.of(HazardService.presentationHazards);
    HazardService.hidden.value = {};
    expect(HazardService.visible, isEmpty);
    HazardService.layers.value = {...HazardService.layers.value, 'demo': true};
    expect(HazardService.visible, hasLength(1));
    HazardService.hide('demo-road-bump');
    expect(HazardService.visible, isEmpty);
    HazardService.layers.value = {};
    HazardService.items.value = [];
    HazardService.hidden.value = {};
  });
}
