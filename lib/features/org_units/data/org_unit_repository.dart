import '../../../core/network/api_client.dart';
import 'models/org_unit.dart';

/// أسماء الفروع.
///
/// الرحلات والمانيفستات لا تحمل إلا معرّفات الفروع، فنحمّل القائمة كاملة مرة
/// واحدة ونحتفظ بها: الفروع قليلة ونادرة التغيّر، وهكذا تعمل الترجمة حتى لو
/// انقطعت الشبكة لاحقًا.
class OrgUnitRepository {
  OrgUnitRepository(this._api);

  final ApiClient _api;

  final Map<String, OrgUnit> _cache = {};

  bool get isLoaded => _cache.isNotEmpty;

  Future<void> preload() async {
    if (isLoaded) return;

    String? cursor;
    // ترقيم بالمؤشّر هنا، لا بالصفحات كبقية النقاط.
    do {
      final response = await _api.get('/organization-units', query: {
        'limit': 100,
        if (cursor != null) 'cursor': cursor,
      });

      for (final json in response.asList) {
        final unit = OrgUnit.fromJson(json);
        _cache[unit.id] = unit;
      }

      cursor = response.meta?['hasNextPage'] == true
          ? (response.meta?['nextCursor'] as String?)
          : null;
    } while (cursor != null);
  }

  /// اسم الفرع، أو نصّ بديل قصير إن لم يُحمّل بعد — كي لا يرى السائق معرّفًا.
  String nameOf(String? id) {
    if (id == null) return '—';
    return _cache[id]?.name ?? 'فرع غير معروف';
  }
}
