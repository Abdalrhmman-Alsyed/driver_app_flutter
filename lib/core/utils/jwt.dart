import 'dart:convert';

/// حمولة توكن السائق.
///
/// الباك يضع داخل التوكن هوية الموظف (`profileId`) والمركبة المسندة
/// (`vehicleId`)، فنقرأهما محليًا بدل طلب إضافي.
///
/// تنبيه: `vehicleId` يُنسخ كما هو عند تجديد التوكن، فإن غيّرت الإدارة مركبة
/// السائق لا تتحدّث القيمة إلا بتسجيل دخول جديد.
class JwtPayload {
  const JwtPayload({
    required this.userId,
    required this.driverId,
    required this.tenantId,
    this.vehicleId,
  });

  final String userId;
  final String driverId;
  final String tenantId;
  final String? vehicleId;

  static JwtPayload? tryParse(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final normalized = base64Url.normalize(parts[1]);
      final json = jsonDecode(utf8.decode(base64Url.decode(normalized)))
          as Map<String, dynamic>;

      final driverId = json['profileId'] as String?;
      final tenantId = json['tenantId'] as String?;
      if (driverId == null || tenantId == null) return null;

      return JwtPayload(
        userId: json['sub'] as String? ?? '',
        driverId: driverId,
        tenantId: tenantId,
        vehicleId: json['vehicleId'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}
