import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// تخزين التوكنات في مخزن الجهاز المشفّر — لا في SharedPreferences، فتلك
/// تُقرأ نصًّا صريحًا على جهاز مكسور الحماية.
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _emailKey = 'email';

  Future<void> save({
    required String accessToken,
    required String refreshToken,
    String? email,
  }) async {
    await Future.wait([
      _storage.write(key: _accessKey, value: accessToken),
      _storage.write(key: _refreshKey, value: refreshToken),
      if (email != null) _storage.write(key: _emailKey, value: email),
    ]);
  }

  Future<String?> readAccessToken() => _storage.read(key: _accessKey);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshKey);

  /// البريد لا يوجد داخل التوكن، فنحفظه لتبقى هوية السائق ظاهرة بعد إعادة
  /// فتح التطبيق دون طلب جديد.
  Future<String?> readEmail() => _storage.read(key: _emailKey);

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _accessKey),
      _storage.delete(key: _refreshKey),
      _storage.delete(key: _emailKey),
    ]);
  }
}
