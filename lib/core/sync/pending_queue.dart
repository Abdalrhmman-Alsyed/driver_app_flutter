import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_exception.dart';
import 'pending_update.dart';

typedef PendingSender = Future<void> Function(PendingUpdate update);

/// المسحات التي لم تصل إلى الخادم بعد.
///
/// المستودعات الخرسانية والطرق الخارجية تقطع الشبكة بانتظام. بدون هذا
/// الطابور تضيع مسحة السائق تمامًا، ويكتشف المكتب النقص بعد أن تكون الشاحنة
/// قد وصلت. مع الطابور: يُسجَّل محليًّا، ويُرسل وحده حين تعود الشبكة.
class PendingQueue extends ChangeNotifier {
  PendingQueue({SharedPreferences? preferences}) : _preferences = preferences;

  static const _storageKey = 'pending_updates';
  static const _retryInterval = Duration(seconds: 12);

  SharedPreferences? _preferences;
  PendingSender? sender;

  final List<PendingUpdate> _updates = [];
  Timer? _timer;
  bool _syncing = false;

  List<PendingUpdate> get updates => List.unmodifiable(_updates);

  int get length => _updates.length;

  bool get isEmpty => _updates.isEmpty;

  Future<void> load() async {
    _preferences ??= await SharedPreferences.getInstance();

    final raw = _preferences!.getStringList(_storageKey) ?? const [];
    _updates
      ..clear()
      ..addAll(
        raw
            .map((entry) {
              try {
                return PendingUpdate.tryFromJson(
                  jsonDecode(entry) as Map<String, dynamic>,
                );
              } catch (_) {
                return null;
              }
            })
            .whereType<PendingUpdate>(),
      );

    notifyListeners();
    _scheduleRetries();
  }

  /// حالة الطرد الواحد يحتفظ منها بالأحدث فقط: لو أشّره السائق محمّلًا ثم
  /// مفقودًا، فالمفقود هو ما يجب أن يصل، لا الاثنان بالترتيب.
  Future<void> enqueue(PendingUpdate update) async {
    _updates
      ..removeWhere((existing) =>
          existing.manifestId == update.manifestId &&
          existing.itemId == update.itemId)
      ..add(update);

    await _persist();
    notifyListeners();
    _scheduleRetries();
  }

  /// الحالة المؤجّلة لعناصر كشف بعينه، لتُعرض فوق ما جاء من الخادم.
  Map<String, String> statusesFor(String manifestId) => {
        for (final update in _updates)
          if (update.manifestId == manifestId) update.itemId: update.status,
      };

  Future<void> sync() async {
    if (_syncing || _updates.isEmpty || sender == null) return;
    _syncing = true;

    try {
      // نسخة ثابتة: الطابور قد يستقبل مسحات جديدة أثناء الإرسال.
      for (final update in List<PendingUpdate>.from(_updates)) {
        try {
          await sender!(update);
          _updates.remove(update);
        } on ApiException catch (error) {
          if (error.isNetwork) return; // الشبكة ما زالت مقطوعة

          // رفض من الخادم: إعادة المحاولة لن تنجح أبدًا، فنُسقط العنصر بدل
          // أن يبقى يدور في الطابور إلى الأبد.
          debugPrint('dropped pending update: ${error.message}');
          _updates.remove(update);
        }
      }
    } finally {
      _syncing = false;
      await _persist();
      notifyListeners();
      _scheduleRetries();
    }
  }

  void _scheduleRetries() {
    _timer?.cancel();
    if (_updates.isEmpty) return;

    _timer = Timer.periodic(_retryInterval, (_) => sync());
  }

  Future<void> _persist() async {
    await _preferences?.setStringList(
      _storageKey,
      _updates.map((update) => jsonEncode(update.toJson())).toList(),
    );
  }

  Future<void> clear() async {
    _updates.clear();
    await _persist();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
