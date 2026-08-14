import '../../../core/network/api_client.dart';
import 'models/trip.dart';

class TripRepository {
  TripRepository(this._api);

  final ApiClient _api;

  /// رحلات السائق وحده.
  ///
  /// `GET /trips` يعيد رحلات كل سائقي الشركة، فالتصفية بـ `driverId` إلزامية
  /// وليست تحسينًا: بدونها يرى السائق رحلات زملائه.
  Future<List<Trip>> myTrips({
    required String driverId,
    TripStatus? status,
    int limit = 50,
  }) async {
    final response = await _api.get('/trips', query: {
      'driverId': driverId,
      'limit': limit,
      if (status != null) 'status': status.wire,
    });

    return response.asList.map(Trip.fromJson).toList();
  }

  Future<Trip> details(String tripId) async {
    final response = await _api.get('/trips/$tripId');
    return Trip.fromJson(response.asMap);
  }

  Future<void> start(String tripId) => _api.post('/trips/$tripId/start');

  Future<void> complete(String tripId) => _api.post('/trips/$tripId/complete');
}
