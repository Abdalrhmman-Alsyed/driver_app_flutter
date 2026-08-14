import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// هيكل تحميل يتموّج.
///
/// يحل محل الدوّارة لأنه يرسم شكل المحتوى القادم: الشاشة تبدو ممتلئة فورًا
/// فيُقرأ الانتظار أقصر، والانتقال إلى البيانات الحقيقية لا يقفز.
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    required this.height,
    this.width,
    this.radius = 8,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.colors;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: Color.lerp(p.surface, p.border, _controller.value),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}

/// بطاقة هيكلية بأبعاد بطاقة الرحلة أو كشف الحمولة.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.lines = 2});

  final int lines;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Skeleton(height: 16)),
              const SizedBox(width: 12),
              Skeleton(height: 22, width: 64, radius: 999),
            ],
          ),
          for (var i = 0; i < lines; i++) ...[
            const SizedBox(height: 12),
            Skeleton(height: 12, width: i.isEven ? 180 : 120),
          ],
        ],
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 4, this.lines = 2});

  final int count;
  final int lines;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => SkeletonCard(lines: lines),
    );
  }
}
