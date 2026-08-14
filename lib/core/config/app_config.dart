abstract final class AppConfig {
  const AppConfig._();

  /// عنوان الخادم. يمكن تبديله عند البناء:
  /// `flutter build apk --dart-define=API_BASE_URL=https://...`
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://saifkenani.me',
  );

  static const connectTimeout = Duration(seconds: 20);
  static const receiveTimeout = Duration(seconds: 30);
}
