import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum ScanTone { accepted, duplicate, rejected }

/// ردّ فعل مسموع وملموس لكل مسحة.
///
/// السائق يمسح وهو ماسك كرتونة داخل مستودع فيه ضجيج، فلا يستطيع النظر إلى
/// الشاشة بعد كل طرد. الصوت والاهتزاز هما القناة الفعلية للنتيجة، والشاشة
/// تأكيد لاحق.
class ScanFeedback {
  ScanFeedback._();

  /// مشغّل مستقلّ لكل نغمة: إعادة استخدام مشغّل واحد تقطع النغمة السابقة حين
  /// يمسح السائق طردين متتاليين بسرعة.
  static final _players = <ScanTone, AudioPlayer>{};

  static const _assets = {
    ScanTone.accepted: 'sounds/scan_ok.wav',
    ScanTone.duplicate: 'sounds/scan_dup.wav',
    ScanTone.rejected: 'sounds/scan_bad.wav',
  };

  static Future<void> play(ScanTone tone) async {
    _vibrate(tone);

    try {
      final player = _players.putIfAbsent(tone, AudioPlayer.new);
      await player.stop();
      await player.play(AssetSource(_assets[tone]!), volume: 1);
    } catch (error) {
      debugPrint('scan tone skipped: $error');
    }
  }

  static void _vibrate(ScanTone tone) {
    switch (tone) {
      case ScanTone.accepted:
        HapticFeedback.mediumImpact();
      case ScanTone.duplicate:
        HapticFeedback.selectionClick();
      case ScanTone.rejected:
        // نبضتان متتاليتان: الاهتزاز الواحد يلتبس بالقبول داخل جيب أو قفّاز.
        HapticFeedback.heavyImpact();
        Future.delayed(
          const Duration(milliseconds: 160),
          HapticFeedback.heavyImpact,
        );
    }
  }

  static Future<void> dispose() async {
    for (final player in _players.values) {
      await player.dispose();
    }
    _players.clear();
  }
}
