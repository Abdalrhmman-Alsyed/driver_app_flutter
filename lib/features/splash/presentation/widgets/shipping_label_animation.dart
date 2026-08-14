import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// ملصق شحن يُطبع أمام المستخدم: الباركود يظهر خطًّا خطًّا، ثم رقم التتبع،
/// ثم رمز الـ QR، وأخيرًا ختم الجاهزية.
///
/// مرسوم بالكامل بـ CustomPainter وليس ملف Lottie: ملف الأنيميشن الجاهز
/// يحمل ألوانه بداخله فيظهر خاطئًا في الوضع الداكن، أما الرسم البرمجي
/// فيأخذ ألوان الثيم كما هي.
class ShippingLabelAnimation extends StatelessWidget {
  const ShippingLabelAnimation({super.key, required this.progress});

  final Animation<double> progress;

  static const cardSize = Size(264, 184);

  @override
  Widget build(BuildContext context) {
    final palette = context.colors;

    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        return CustomPaint(
          size: cardSize,
          painter: _LabelPainter(t: progress.value, palette: palette),
        );
      },
    );
  }
}

class _LabelPainter extends CustomPainter {
  _LabelPainter({required this.t, required this.palette});

  final double t;
  final AppPalette palette;

  /// عرض كل خط في الباركود. ثابتة كي لا يتغيّر الشكل بين إطار وآخر.
  static const _barWidths = <double>[
    2, 4, 2, 6, 3, 2, 5, 2, 3, 6, 2, 4, 2, 2, 5, 3, 6, 2, 4, 2, 3, 5, 2, 6, 3,
    2, 4, 2,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final card = _interval(0, 0.18);
    if (card <= 0) return;

    canvas.save();
    final eased = Curves.easeOutCubic.transform(card);
    final scale = 0.92 + 0.08 * eased;
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);
    canvas.translate(-size.width / 2, -size.height / 2);

    _paintCard(canvas, size, eased);
    _paintBarcode(canvas, size);
    _paintTrackingNumber(canvas);
    _paintQr(canvas);
    _paintStamp(canvas, size);

    canvas.restore();
  }

  void _paintCard(Canvas canvas, Size size, double opacity) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(16),
    );

    canvas.drawRRect(
      rect,
      Paint()..color = palette.surfaceElevated.withValues(alpha: opacity),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color = palette.border.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _paintBarcode(Canvas canvas, Size size) {
    const top = 26.0;
    const height = 52.0;
    const left = 20.0;

    final total = _barWidths.fold<double>(0, (sum, w) => sum + w);
    final gap = (size.width - left * 2 - total) / (_barWidths.length - 1);

    var x = left;
    for (var i = 0; i < _barWidths.length; i++) {
      final start = 0.18 + (i / _barWidths.length) * 0.30;
      final appear = _interval(start, start + 0.06);

      if (appear > 0) {
        final h = height * Curves.easeOutCubic.transform(appear);
        canvas.drawRect(
          Rect.fromLTWH(x, top + (height - h) / 2, _barWidths[i], h),
          Paint()..color = palette.textPrimary.withValues(alpha: appear),
        );
      }

      x += _barWidths[i] + gap;
    }
  }

  void _paintTrackingNumber(Canvas canvas) {
    final reveal = _interval(0.50, 0.68);
    if (reveal <= 0) return;

    final painter = TextPainter(
      text: TextSpan(
        text: 'TRK-8891',
        style: TextStyle(
          color: palette.textPrimary,
          fontSize: 15,
          letterSpacing: 2.4,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(20, 84, painter.width * reveal, painter.height),
    );
    painter.paint(canvas, const Offset(20, 84));
    canvas.restore();
  }

  void _paintQr(Canvas canvas) {
    const origin = Offset(20, 118);
    const cells = 7;
    const cell = 7.0;

    for (var r = 0; r < cells; r++) {
      for (var c = 0; c < cells; c++) {
        if (!_isQrCellFilled(r, c)) continue;

        final index = r * cells + c;
        final start = 0.58 + (index / (cells * cells)) * 0.20;
        final appear = _interval(start, start + 0.05);
        if (appear <= 0) continue;

        canvas.drawRect(
          Rect.fromLTWH(
            origin.dx + c * cell,
            origin.dy + r * cell,
            cell - 1,
            cell - 1,
          ),
          Paint()..color = palette.textPrimary.withValues(alpha: appear),
        );
      }
    }
  }

  /// نمط ثابت يشبه رمز QR: ثلاث مربعات تحديد في الزوايا وبقية الخلايا
  /// بدالة حسابية ثابتة كي لا يرقص الشكل بين الإطارات.
  bool _isQrCellFilled(int r, int c) {
    bool inFinder(int baseR, int baseC) {
      final dr = r - baseR;
      final dc = c - baseC;
      if (dr < 0 || dr > 2 || dc < 0 || dc > 2) return false;
      return dr == 0 || dr == 2 || dc == 0 || dc == 2;
    }

    if (inFinder(0, 0) || inFinder(0, 4) || inFinder(4, 0)) return true;
    if (r < 3 && c < 3) return false;
    if (r < 3 && c > 3) return false;
    if (r > 3 && c < 3) return false;

    return (r * 7 + c * 13 + r * c * 3) % 5 < 2;
  }

  void _paintStamp(Canvas canvas, Size size) {
    final pop = _interval(0.84, 1);
    if (pop <= 0) return;

    final scale = Curves.easeOutBack.transform(pop);
    final center = Offset(size.width - 44, size.height - 46);
    final radius = 19.0 * scale;

    canvas.drawCircle(center, radius, Paint()..color = palette.success);

    final check = Paint()
      ..color = palette.surfaceElevated
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(center.dx - 7 * scale, center.dy)
      ..lineTo(center.dx - 2 * scale, center.dy + 5.5 * scale)
      ..lineTo(center.dx + 7.5 * scale, center.dy - 5 * scale);

    canvas.drawPath(path, check);
  }

  /// يحوّل تقدّم الأنيميشن الكلي إلى تقدّم مرحلة واحدة بين 0 و1.
  double _interval(double begin, double end) {
    if (t <= begin) return 0;
    if (t >= end) return 1;
    return (t - begin) / (end - begin);
  }

  @override
  bool shouldRepaint(_LabelPainter old) =>
      old.t != t || old.palette != palette;
}
