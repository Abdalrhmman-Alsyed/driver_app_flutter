import 'package:equatable/equatable.dart';

class Vehicle extends Equatable {
  const Vehicle({
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
        'IN_MAINTENANCE' => 'في الصيانة',
        'INACTIVE' => 'متوقفة',
        _ => status,
      };

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'] as String,
        plateNumber: json['plateNumber'] as String? ?? '',
        status: json['status'] as String? ?? '',
        type: json['type'] as String?,
        capacityKg: json['capacityKg'] as num?,
      );

  @override
  List<Object?> get props => [id, plateNumber, status];
}
