import '../../../core/network/api_client.dart';
import 'models/my_profile.dart';

class ProfileRepository {
  ProfileRepository(this._api);

  final ApiClient _api;

  /// ملف السائق الحالي.
  ///
  /// النقطة لا تأخذ معرّفًا: القارئ لا يستطيع أن يقرأ إلا نفسه، ولهذا يُسمح
  /// للسائق بها بينما تبقى بقية نقاط قراءة الموظفين مغلقة أمامه.
  Future<MyProfile> getMyProfile() async {
    final response = await _api.get('/me');
    return MyProfile.fromJson(response.asMap);
  }
}
