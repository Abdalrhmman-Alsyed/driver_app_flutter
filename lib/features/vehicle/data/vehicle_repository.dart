import '../../../core/network/api_client.dart';
import 'models/vehicle.dart';

class VehicleRepository {
  VehicleRepository(this._api);

  final ApiClient _api;

  Future<Vehicle> details(String vehicleId) async {
    final response = await _api.get('/vehicles/$vehicleId');
    return Vehicle.fromJson(response.asMap);
  }
}
