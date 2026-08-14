import '../../../core/network/api_client.dart';
import 'models/parcel.dart';

class ParcelRepository {
  ParcelRepository(this._api);

  final ApiClient _api;

  /// كل طرد يُقرأ مرة واحدة ثم يُحفظ: السائق يمسح الطرد نفسه أكثر من مرة
  /// أثناء التحميل والتفريغ، ولا داعي لطلب جديد في كل مسحة.
  final Map<String, Parcel> _byId = {};

  Parcel? cachedById(String parcelId) => _byId[parcelId];

  /// البحث برقم التتبع المقروء من الباركود.
  ///
  /// هذه هي النقطة الوحيدة التي يستطيع السائق قراءة بيانات طرد منها، ولذلك
  /// يقوم التطبيق على المسح لا على تصفّح قائمة.
  Future<Parcel> byTrackingNumber(String trackingNumber) async {
    final response = await _api.get('/parcels/track/$trackingNumber');
    final parcel = Parcel.fromJson(response.asMap);

    _byId[parcel.id] = parcel;
    return parcel;
  }
}
