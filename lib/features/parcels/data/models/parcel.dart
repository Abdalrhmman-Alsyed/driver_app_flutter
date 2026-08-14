import 'package:equatable/equatable.dart';

class Parcel extends Equatable {
  const Parcel({
    required this.id,
    required this.trackingNumber,
    required this.actualWeightKg,
    required this.isFragile,
    this.description,
    this.destinationOrgUnitId,
    this.requiresUprightHandling = false,
    this.temperatureSensitive = false,
  });

  final String id;
  final String trackingNumber;
  final double actualWeightKg;
  final bool isFragile;
  final String? description;
  final String? destinationOrgUnitId;
  final bool requiresUprightHandling;
  final bool temperatureSensitive;

  factory Parcel.fromJson(Map<String, dynamic> json) => Parcel(
        id: json['id'] as String,
        trackingNumber: json['trackingNumber'] as String,
        actualWeightKg: (json['actualWeightKg'] as num?)?.toDouble() ?? 0,
        isFragile: json['isFragile'] as bool? ?? false,
        description: json['description'] as String?,
        destinationOrgUnitId: json['destinationOrgUnitId'] as String?,
        requiresUprightHandling:
            json['requiresUprightHandling'] as bool? ?? false,
        temperatureSensitive: json['temperatureSensitive'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [id, trackingNumber];
}
