import '../../../core/network/api_client.dart';
import 'models/manifest.dart';

class ManifestRepository {
  ManifestRepository(this._api);

  final ApiClient _api;

  Future<List<Manifest>> forTrip(String tripId) async {
    final response = await _api.get('/manifests', query: {
      'tripId': tripId,
      'limit': 50,
    });

    return response.asList.map(Manifest.fromJson).toList();
  }

  Future<Manifest> details(String manifestId) async {
    final response = await _api.get('/manifests/$manifestId');
    return Manifest.fromJson(response.asMap);
  }

  Future<List<ManifestItem>> items(String manifestId) async {
    final response = await _api.get('/manifests/$manifestId/items');
    return response.asList.map(ManifestItem.fromJson).toList();
  }

  Future<void> updateItemStatus({
    required String manifestId,
    required String itemId,
    required ManifestItemStatus status,
  }) =>
      _api.patch(
        '/manifests/$manifestId/items/$itemId',
        body: {'status': status.wire},
      );

  Future<void> complete(String manifestId) =>
      _api.post('/manifests/$manifestId/complete');
}
