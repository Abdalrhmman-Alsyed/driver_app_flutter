import 'package:equatable/equatable.dart';

enum TripStatus {
  scheduled('SCHEDULED', 'مجدولة'),
  inProgress('IN_PROGRESS', 'جارية'),
  completed('COMPLETED', 'منتهية'),
  cancelled('CANCELLED', 'ملغاة');

  const TripStatus(this.wire, this.label);

  final String wire;
  final String label;

  static TripStatus from(String? value) => TripStatus.values.firstWhere(
        (status) => status.wire == value,
        orElse: () => TripStatus.scheduled,
      );
}

class Trip extends Equatable {
  const Trip({
    required this.id,
    required this.driverId,
    required this.originOrgUnitId,
    required this.destinationOrgUnitId,
    required this.status,
    this.vehicleId,
    this.scheduledAt,
    this.startedAt,
    this.endedAt,
    this.notes,
  });

  final String id;
  final String driverId;
  final String? vehicleId;
  final String originOrgUnitId;
  final String destinationOrgUnitId;
  final TripStatus status;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String? notes;

  bool get canStart => status == TripStatus.scheduled;

  bool get canComplete => status == TripStatus.inProgress;

  bool get isActive =>
      status == TripStatus.scheduled || status == TripStatus.inProgress;

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
        id: json['id'] as String,
        driverId: json['driverId'] as String,
        vehicleId: json['vehicleId'] as String?,
        originOrgUnitId: json['originOrgUnitId'] as String,
        destinationOrgUnitId: json['destinationOrgUnitId'] as String,
        status: TripStatus.from(json['status'] as String?),
        scheduledAt: DateTime.tryParse(json['scheduledAt'] as String? ?? ''),
        startedAt: DateTime.tryParse(json['startedAt'] as String? ?? ''),
        endedAt: DateTime.tryParse(json['endedAt'] as String? ?? ''),
        notes: json['notes'] as String?,
      );

  @override
  List<Object?> get props => [id, status, startedAt, endedAt];
}
