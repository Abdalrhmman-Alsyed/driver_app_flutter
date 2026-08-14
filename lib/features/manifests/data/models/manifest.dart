import 'package:equatable/equatable.dart';

enum ManifestStatus {
  pending('PENDING', 'قيد التحميل'),
  inTransit('IN_TRANSIT', 'في الطريق'),
  completed('COMPLETED', 'مكتمل');

  const ManifestStatus(this.wire, this.label);

  final String wire;
  final String label;

  static ManifestStatus from(String? value) => ManifestStatus.values.firstWhere(
        (status) => status.wire == value,
        orElse: () => ManifestStatus.pending,
      );
}

/// حالة الطرد على الشاحنة — منفصلة عن حالة الطرد التجارية في النظام.
/// السائق يتحكّم بهذه وحدها.
enum ManifestItemStatus {
  pendingLoad('PENDING_LOAD', 'بانتظار التحميل'),
  loaded('LOADED', 'محمّل'),
  unloaded('UNLOADED', 'مُفرّغ'),
  missing('MISSING', 'مفقود');

  const ManifestItemStatus(this.wire, this.label);

  final String wire;
  final String label;

  static ManifestItemStatus from(String? value) =>
      ManifestItemStatus.values.firstWhere(
        (status) => status.wire == value,
        orElse: () => ManifestItemStatus.pendingLoad,
      );
}

class Manifest extends Equatable {
  const Manifest({
    required this.id,
    required this.tripId,
    required this.originOrgUnitId,
    required this.destinationOrgUnitId,
    required this.status,
    this.itemCount = 0,
    this.items = const [],
  });

  final String id;
  final String tripId;
  final String originOrgUnitId;
  final String destinationOrgUnitId;
  final ManifestStatus status;
  final int itemCount;
  final List<ManifestItem> items;

  bool get canComplete => status == ManifestStatus.inTransit;

  factory Manifest.fromJson(Map<String, dynamic> json) => Manifest(
        id: json['id'] as String,
        tripId: json['tripId'] as String,
        originOrgUnitId: json['originOrgUnitId'] as String,
        destinationOrgUnitId: json['destinationOrgUnitId'] as String,
        status: ManifestStatus.from(json['status'] as String?),
        itemCount: (json['itemCount'] as num?)?.toInt() ??
            (json['items'] as List?)?.length ??
            0,
        items: (json['items'] as List? ?? [])
            .map((item) =>
                ManifestItem.fromJson((item as Map).cast<String, dynamic>()))
            .toList(),
      );

  @override
  List<Object?> get props => [id, status, itemCount, items];
}

class ManifestItem extends Equatable {
  const ManifestItem({
    required this.id,
    required this.manifestId,
    required this.parcelId,
    required this.status,
    this.loadedAt,
    this.unloadedAt,
  });

  final String id;
  final String manifestId;
  final String parcelId;
  final ManifestItemStatus status;
  final DateTime? loadedAt;
  final DateTime? unloadedAt;

  bool get isHandled => status != ManifestItemStatus.pendingLoad;

  ManifestItem copyWith({ManifestItemStatus? status}) => ManifestItem(
        id: id,
        manifestId: manifestId,
        parcelId: parcelId,
        status: status ?? this.status,
        loadedAt: loadedAt,
        unloadedAt: unloadedAt,
      );

  factory ManifestItem.fromJson(Map<String, dynamic> json) => ManifestItem(
        id: json['id'] as String,
        manifestId: json['manifestId'] as String,
        parcelId: json['parcelId'] as String,
        status: ManifestItemStatus.from(json['status'] as String?),
        loadedAt: DateTime.tryParse(json['loadedAt'] as String? ?? ''),
        unloadedAt: DateTime.tryParse(json['unloadedAt'] as String? ?? ''),
      );

  @override
  List<Object?> get props => [id, status];
}
