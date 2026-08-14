import 'package:equatable/equatable.dart';

/// تحديث حالة طرد على كشف حمولة، مؤجَّل حتى تعود الشبكة.
class PendingUpdate extends Equatable {
  const PendingUpdate({
    required this.manifestId,
    required this.itemId,
    required this.status,
    required this.createdAt,
  });

  final String manifestId;
  final String itemId;

  /// القيمة السلكية للحالة (LOADED / UNLOADED / MISSING) لا القيمة المعرّفة
  /// في Dart: الطابور يُحفظ على القرص وقد يُقرأ بعد ترقية التطبيق.
  final String status;

  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'manifestId': manifestId,
        'itemId': itemId,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
      };

  static PendingUpdate? tryFromJson(Map<String, dynamic> json) {
    final manifestId = json['manifestId'] as String?;
    final itemId = json['itemId'] as String?;
    final status = json['status'] as String?;

    if (manifestId == null || itemId == null || status == null) return null;

    return PendingUpdate(
      manifestId: manifestId,
      itemId: itemId,
      status: status,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
              DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [manifestId, itemId, status];
}
