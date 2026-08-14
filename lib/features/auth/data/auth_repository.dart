import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/utils/jwt.dart';
import 'models/driver_session.dart';

class AuthRepository {
  AuthRepository({required ApiClient api, required TokenStorage storage})
      : _api = api,
        _storage = storage;

  final ApiClient _api;
  final TokenStorage _storage;

  /// تسجيل الدخول بصفة سائق.
  ///
  /// نرسل `type: DRIVER` كي يتخطّى الخادم شاشة اختيار البروفايل: الموظف الذي
  /// له مركبة مسندة يملك بروفايلَي EMPLOYEE و DRIVER معًا، ونحن نريد الثاني
  /// دائمًا. ومن لا يملك بروفايل سائق يُرفض بـ 401 من الخادم نفسه.
  Future<DriverSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post(
      '/auth/login',
      body: {
        'email': email.trim(),
        'password': password,
        'type': 'DRIVER',
      },
    );

    final data = response.asMap;
    final accessToken = data['accessToken'] as String?;
    final refreshToken = data['refreshToken'] as String?;

    if (accessToken == null || refreshToken == null) {
      throw const ApiException('هذا الحساب ليس حساب سائق.');
    }

    final payload = JwtPayload.tryParse(accessToken);
    if (payload == null) {
      throw const ApiException('تعذّر قراءة بيانات الجلسة.');
    }

    final user = data['user'];
    final resolvedEmail =
        (user is Map ? user['email'] as String? : null) ?? email.trim();

    await _storage.save(
      accessToken: accessToken,
      refreshToken: refreshToken,
      email: resolvedEmail,
    );

    return DriverSession.fromJwt(payload, email: resolvedEmail);
  }

  /// جلسة محفوظة من تشغيل سابق، أو null إن لم توجد.
  Future<DriverSession?> restoreSession() async {
    final token = await _storage.readAccessToken();
    if (token == null) return null;

    final payload = JwtPayload.tryParse(token);
    if (payload == null) return null;

    return DriverSession.fromJwt(payload, email: await _storage.readEmail());
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } on ApiException {
      // الجلسة قد تكون منتهية أصلًا؛ الخروج محليًّا يتم على أي حال.
    } finally {
      await _storage.clear();
    }
  }
}
