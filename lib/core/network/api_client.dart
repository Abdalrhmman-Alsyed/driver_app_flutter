import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

/// ردّ الخادم بعد نزع الغلاف `{success, data, meta}`.
class ApiResponse {
  const ApiResponse(this.data, this.meta);

  final dynamic data;
  final Map<String, dynamic>? meta;

  Map<String, dynamic> get asMap => (data as Map).cast<String, dynamic>();

  List<Map<String, dynamic>> get asList => (data as List)
      .map((item) => (item as Map).cast<String, dynamic>())
      .toList();
}

/// عميل HTTP واحد لكل التطبيق.
///
/// يتكفّل بثلاثة أمور حتى لا تتكرر في كل مستودع: ترويسة التوكن، تجديده مرة
/// واحدة عند 401 ثم إعادة الطلب، وتحويل أخطاء Dio إلى [ApiException].
class ApiClient {
  ApiClient({required TokenStorage tokenStorage, Dio? dio})
      : _tokenStorage = tokenStorage,
        _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = AppConfig.apiBaseUrl
      ..connectTimeout = AppConfig.connectTimeout
      ..receiveTimeout = AppConfig.receiveTimeout
      ..headers['client-type'] = 'MOBILE'
      ..contentType = Headers.jsonContentType;

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _attachToken,
        onError: _refreshOnUnauthorized,
      ),
    );
  }

  final Dio _dio;
  final TokenStorage _tokenStorage;

  /// يُستدعى حين يفشل التجديد نهائيًا فتنتهي الجلسة.
  void Function()? onSessionExpired;

  Future<void> _attachToken(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isAuthEndpoint(options.path)) {
      final token = await _tokenStorage.readAccessToken();
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _refreshOnUnauthorized(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final options = error.requestOptions;

    final cannotRetry = error.response?.statusCode != 401 ||
        _isAuthEndpoint(options.path) ||
        options.extra['retried'] == true;

    if (cannotRetry) return handler.next(error);

    final refreshed = await _refreshToken();
    if (!refreshed) {
      onSessionExpired?.call();
      return handler.next(error);
    }

    try {
      options.extra['retried'] = true;
      final token = await _tokenStorage.readAccessToken();
      options.headers['Authorization'] = 'Bearer $token';
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<bool> _refreshToken() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null) return false;

    try {
      final response = await _dio.post<dynamic>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final data = (response.data as Map)['data'] as Map;

      await _tokenStorage.save(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      return true;
    } catch (_) {
      await _tokenStorage.clear();
      return false;
    }
  }

  /// نقاط المصادقة لا تحمل ترويسة توكن ولا تُعاد عند 401، وإلا دخلنا في حلقة.
  bool _isAuthEndpoint(String path) =>
      path.startsWith('/auth/login') || path.startsWith('/auth/refresh');

  Future<ApiResponse> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get<dynamic>(path, queryParameters: query));

  Future<ApiResponse> post(String path, {Object? body}) =>
      _send(() => _dio.post<dynamic>(path, data: body));

  Future<ApiResponse> patch(String path, {Object? body}) =>
      _send(() => _dio.patch<dynamic>(path, data: body));

  Future<ApiResponse> _send(Future<Response<dynamic>> Function() request) async {
    try {
      final response = await request();
      final body = response.data;

      if (body is Map) {
        return ApiResponse(
          body['data'],
          (body['meta'] as Map?)?.cast<String, dynamic>(),
        );
      }
      return ApiResponse(body, null);
    } on DioException catch (error) {
      debugPrint(
        'API ${error.requestOptions.method} ${error.requestOptions.path} '
        '→ ${error.type} ${error.response?.statusCode} ${error.message}',
      );
      throw ApiException.fromDio(error);
    } catch (error) {
      // شكل رد غير متوقّع أو خطأ في قناة منصّة: يصل إلى هنا لأنه ليس
      // DioException، وبدون هذا الفرع يتسرّب إلى الواجهة كانهيار.
      debugPrint('API unexpected error: $error');
      throw ApiException('تعذّر قراءة رد الخادم: $error');
    }
  }
}
