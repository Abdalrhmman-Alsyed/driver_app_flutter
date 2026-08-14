import 'package:flutter/material.dart';

/// علامة التطبيق: طرد بخطوط حركة خلفه.
///
/// مرسومة برمجيًا لا كصورة، فتأخذ لون الثيم تلقائيًا وتبقى حادّة على أي
/// كثافة شاشة.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 56, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _LogoPainter(
        color: color ?? Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 56;

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4 * u
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final box = RRect.fromRectAndRadius(
      Rect.fromLTWH(18 * u, 12 * u, 32 * u, 32 * u),
      Radius.circular(8 * u),
    );
    canvas.drawRRect(box, stroke);

    final bar = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4 * u
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(27 * u, 21 * u), Offset(27 * u, 35 * u), bar);
    canvas.drawLine(Offset(34 * u, 21 * u), Offset(34 * u, 31 * u), bar);
    canvas.drawLine(Offset(41 * u, 21 * u), Offset(41 * u, 35 * u), bar);

    final trail = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4 * u
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(2 * u, 20 * u), Offset(11 * u, 20 * u), trail);
    canvas.drawLine(Offset(6 * u, 28 * u), Offset(11 * u, 28 * u), trail);
    canvas.drawLine(Offset(2 * u, 36 * u), Offset(11 * u, 36 * u), trail);
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.color != color;
}
