import 'package:equatable/equatable.dart';

import '../../../../core/utils/jwt.dart';

/// هوية السائق أثناء الجلسة.
///
/// الاسم الكامل ورقم الهاتف غير متاحين: `GET /employees/:id` صلاحية
/// TENANT_ADMIN ولا يوجد endpoint للموظف عن نفسه. المتاح هو البريد من رد
/// تسجيل الدخول، والمركبة من داخل التوكن.
class DriverSession extends Equatable {
  const DriverSession({
    required this.userId,
    required this.driverId,
    required this.tenantId,
    this.vehicleId,
    this.email,
  });

  final String userId;
  final String driverId;
  final String tenantId;
  final String? vehicleId;
  final String? email;

  /// ما نعرضه كهوية للسائق.
  ///
  /// البريد كما هو، لا اسم مشتقّ منه: `driver@fastship.com` ليست دليلًا على
  /// أن اسم السائق "Driver". حين يتيح الخادم الاسم الحقيقي يحلّ محلّه هنا.
  String get identity => email ?? 'سائق';

  String get initials {
    final address = email;
    if (address == null || address.isEmpty) return 'س';
    return address[0].toUpperCase();
  }

  factory DriverSession.fromJwt(JwtPayload payload, {String? email}) =>
      DriverSession(
        userId: payload.userId,
        driverId: payload.driverId,
        tenantId: payload.tenantId,
        vehicleId: payload.vehicleId,
        email: email,
      );

  @override
  List<Object?> get props => [driverId, vehicleId, email];
}
