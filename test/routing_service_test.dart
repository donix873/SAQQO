import 'package:flutter_test/flutter_test.dart';
import 'package:saqgo/core/services/routing_service.dart';

void main() {
  test('does not search an empty place query', () async {
    final result = await RoutingService().searchPlace('   ');
    expect(result, isNull);
  });
}
