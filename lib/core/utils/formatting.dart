/// تنسيق التاريخ والأرقام.
///
/// الأرقام تبقى لاتينية دائمًا حتى في الواجهة العربية: رقم التتبع مطبوع
/// باللاتينية على الكرتونة، ولو عرضناه بالأرقام العربية لتعذّرت المطابقة.
abstract final class Fmt {
  const Fmt._();

  static const _months = [
    'كانون الثاني', 'شباط', 'آذار', 'نيسان', 'أيار', 'حزيران',
    'تموز', 'آب', 'أيلول', 'تشرين الأول', 'تشرين الثاني', 'كانون الأول',
  ];

  static String dateTime(DateTime? value) {
    if (value == null) return '—';
    final local = value.toLocal();
    return '${local.day} ${_months[local.month - 1]} · ${time(local)}';
  }

  static String time(DateTime? value) {
    if (value == null) return '—';
    final local = value.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  static String weight(double kg) {
    final rounded = kg.toStringAsFixed(kg % 1 == 0 ? 0 : 1);
    return '$rounded كغ';
  }
}
