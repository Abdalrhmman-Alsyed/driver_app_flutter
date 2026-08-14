import 'package:dio/dio.dart';

/// خطأ جاهز للعرض على السائق.
///
/// الباك يرد بالشكل `{success: false, message, error}`، ونحوّله هنا إلى رسالة
/// عربية واحدة بدل تسريب نص الاستثناء إلى الشاشة.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.isNetwork = false});

  final String message;
  final int? statusCode;

  /// الطلب لم يصل إلى الخادم أصلًا. الفرق جوهري: عطل الشبكة يعني «أعِد
  /// المحاولة لاحقًا»، أما ردّ الخادم برفض فيعني «لا تُعِدها إطلاقًا».
  final bool isNetwork;

  bool get isUnauthorized => statusCode == 401;

  factory ApiException.fromDio(DioException error) {
    final status = error.response?.statusCode;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          'انتهت مهلة الاتصال. تحقق من الشبكة.',
          isNetwork: true,
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          'تعذّر الوصول إلى الخادم. تحقق من الشبكة.',
          isNetwork: true,
        );
      case DioExceptionType.cancel:
        return const ApiException('أُلغي الطلب.');
      default:
        break;
    }

    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      final message = data['message'];
      return ApiException(
        message is List ? message.join('، ') : message.toString(),
        statusCode: status,
      );
    }

    // ردّ بلا حالة يعني أن الاتصال نفسه انقطع قبل أن يجيب الخادم.
    return ApiException(
      _defaultFor(status),
      statusCode: status,
      isNetwork: status == null,
    );
  }

  static String _defaultFor(int? status) => switch (status ?? 0) {
        400 => 'طلب غير صالح.',
        401 => 'انتهت الجلسة. سجّل الدخول من جديد.',
        403 => 'لا تملك صلاحية لهذا الإجراء.',
        404 => 'غير موجود.',
        409 => 'العملية تتعارض مع الحالة الحالية.',
        >= 500 => 'خلل في الخادم. حاول لاحقًا.',
        _ => 'حدث خطأ غير متوقع.',
      };

  @override
  String toString() => message;
}
