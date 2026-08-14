import 'package:equatable/equatable.dart';

/// فرع أو مركز. الرحلات والمانيفستات تشير إليه بالمعرّف فقط، فنحمّل قائمة
/// الفروع مرة واحدة ونترجم المعرّفات إلى أسماء محليًا.
class OrgUnit extends Equatable {
  const OrgUnit({required this.id, required this.name, this.orgType});

  final String id;
  final String name;
  final String? orgType;

  factory OrgUnit.fromJson(Map<String, dynamic> json) => OrgUnit(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        orgType: json['orgType'] as String?,
      );

  @override
  List<Object?> get props => [id, name];
}
