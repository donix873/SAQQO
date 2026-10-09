import 'package:latlong2/latlong.dart';
import 'routing_service.dart';

class ArqalykMapService {
  Future<LatLng?> resolveCity() async =>
      (await RoutingService().searchPlace('Аркалык'))?.position;
}
