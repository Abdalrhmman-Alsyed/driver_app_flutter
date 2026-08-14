import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// نغمة الترحيب عند فتح التطبيق.
///
/// تُشغَّل مرة واحدة في العمر لا في كل مرة يُعاد فيها بناء شاشة الافتتاح،
/// وفشلها لا يوقف الإقلاع: صوت مفقود لا يستحق أن يمنع السائق من رحلاته.
class StartupSound {
  StartupSound._();

  static final _player = AudioPlayer();
  static var _played = false;

  static Future<void> play() async {
    if (_played) return;
    _played = true;

    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.play(
        AssetSource('sounds/startup.wav'),
        volume: 0.7,
      );
    } catch (error) {
      debugPrint('startup sound skipped: $error');
    }
  }

  static Future<void> dispose() => _player.dispose();
}
