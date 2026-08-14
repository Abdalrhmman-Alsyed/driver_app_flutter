import 'package:equatable/equatable.dart';

/// المركبة المسندة للسائق الآن.
///
/// تأتي ضمن الملف الشخصي لا بطلب منفصل، وهذا يحلّ مشكلة قديمة: معرّف المركبة
/// داخل التوكن يبقى كما هو بعد تغيير الإسناد حتى يسجّل السائق دخولًا جديدًا،
/// أما هذه فتُقرأ من الإسناد الفعلي في كل مرة.
class ProfileVehicle extends Equatable {
  const ProfileVehicle({
    required this.id,
    required this.plateNumber,
    required this.status,
    this.type,
    this.capacityKg,
  });

  final String id;
  final String plateNumber;
  final String status;
  final String? type;
  final num? capacityKg;

  String get statusLabel => switch (status) {
        'ACTIVE' => 'جاهزة',
        'MAINTENANCE' || 'IN_MAINTENANCE' => 'في الصيانة',
        'INACTIVE' => 'متوقفة',
        _ => status,
      };

  bool get isReady => status == 'ACTIVE';

  factory ProfileVehicle.fromJson(Map<String, dynamic> json) => ProfileVehicle(
        id: json['id'] as String,
        plateNumber: json['plateNumber'] as String? ?? '',
        status: json['status'] as String? ?? '',
        type: json['type'] as String?,
        capacityKg: json['capacityKg'] as num?,
      );

  @override
  List<Object?> get props => [id, plateNumber, status];
}

class ProfileAssignment extends Equatable {
  const ProfileAssignment({
    required this.organizationUnitId,
    required this.organizationUnitName,
    this.organizationUnitType,
  });

  final String organizationUnitId;
  final String organizationUnitName;
  final String? organizationUnitType;

  factory ProfileAssignment.fromJson(Map<String, dynamic> json) =>
      ProfileAssignment(
        organizationUnitId: json['organizationUnitId'] as String? ?? '',
        organizationUnitName: json['organizationUnitName'] as String? ?? '',
        organizationUnitType: json['organizationUnitType'] as String?,
      );

  @override
  List<Object?> get props => [organizationUnitId, organizationUnitName];
}

/// هوية السائق كما يعرفها الخادم.
class MyProfile extends Equatable {
  const MyProfile({
    required this.id,
    required this.fullName,
    required this.employeeCode,
    required this.isDriver,
    this.email,
    this.phone,
    this.nationalId,
    this.assignments = const [],
    this.vehicle,
  });

  final String id;
  final String fullName;
  final String employeeCode;
  final bool isDriver;
  final String? email;
  final String? phone;
  final String? nationalId;
  final List<ProfileAssignment> assignments;
  final ProfileVehicle? vehicle;

  /// الفرع الذي يتبعه السائق. أوّل تعيين يكفي: السائق يتبع فرعًا واحدًا عمليًّا.
  String? get branchName =>
      assignments.isEmpty ? null : assignments.first.organizationUnitName;

  String get initials =>
      fullName.trim().isEmpty ? 'س' : fullName.trim()[0].toUpperCase();

  factory MyProfile.fromJson(Map<String, dynamic> json) => MyProfile(
        id: json['id'] as String,
        fullName: json['fullName'] as String? ?? '',
        employeeCode: json['employeeCode'] as String? ?? '',
        isDriver: json['isDriver'] as bool? ?? false,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        nationalId: json['nationalId'] as String?,
        assignments: (json['assignments'] as List? ?? [])
            .map((item) => ProfileAssignment.fromJson(
                  (item as Map).cast<String, dynamic>(),
                ))
            .toList(),
        vehicle: json['vehicle'] == null
            ? null
            : ProfileVehicle.fromJson(
                (json['vehicle'] as Map).cast<String, dynamic>(),
              ),
      );

  @override
  List<Object?> get props => [id, fullName, phone, vehicle, assignments];
}
