import 'package:flutter/material.dart';

/// ظهور متدرّج لعناصر القائمة.
///
/// كل عنصر يتأخّر قليلًا عن سابقه فتُقرأ القائمة كأنها تُبنى أمام العين بدل
/// أن تقفز دفعة واحدة. التأخير مسقوف كي لا ينتظر العنصر الأخير في قائمة
/// طويلة.
class Entrance extends StatelessWidget {
  const Entrance({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  static const _step = Duration(milliseconds: 45);
  static const _maxDelayed = 8;

  @override
  Widget build(BuildContext context) {
    final delay = _step * (index.clamp(0, _maxDelayed));

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320) + delay,
      curve: Interval(
        delay.inMilliseconds / (320 + delay.inMilliseconds),
        1,
        curve: Curves.easeOutCubic,
      ),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
