import 'package:flutter_test/flutter_test.dart';
import 'package:saqgo/core/services/routing_service.dart';

void main() {
  test('does not search an empty place query', () async {
    final result = await RoutingService().searchPlace('   ');
    expect(result, isNull);
  });

  test('parses a Yandex route payload and removes joined duplicates', () {
    final routes = RoutingService.parseSaqgoRoutePayload({
      'route': {
        'legs': [
          {
            'status': 'OK',
            'steps': [
              {
                'length': 120.5,
                'duration': 15.2,
                'polyline': {
                  'points': [
                    [50.2486, 66.9203],
                    [50.2490, 66.9210],
                  ],
                },
              },
              {
                'length': 80,
                'duration': 10,
                'polyline': {
                  'points': [
                    [50.2490, 66.9210],
                    [50.2500, 66.9220],
                  ],
                },
              },
            ],
          },
        ],
      },
    });

    expect(routes, hasLength(1));
    expect(routes.single.points, hasLength(3));
    expect(routes.single.points.first.latitude, 50.2486);
    expect(routes.single.points.last.longitude, 66.9220);
    expect(routes.single.distanceMeters, 200.5);
    expect(routes.single.duration, const Duration(seconds: 25));
  });

  test('rejects failed or geometry-free Yandex routes', () {
    expect(
      RoutingService.parseSaqgoRoutePayload({
        'route': {
          'legs': [
            {'status': 'FAIL', 'steps': <Object>[]},
          ],
        },
      }),
      isEmpty,
    );
  });
}
