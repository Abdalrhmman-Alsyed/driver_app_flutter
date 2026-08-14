import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

class BottomBarItem {
  const BottomBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// شريط تنقّل عائم.
///
/// العنصر النشط يتمدّد إلى حبّة تجمع الأيقونة والنص جنبًا إلى جنب، وغير
/// النشط يبقى أيقونة وحدها. التمدّد نفسه هو المؤشّر، فلا حاجة إلى خط أو نقطة
/// إضافية تحته.
///
/// الأيقونات كبيرة (26) وارتفاع الشريط 72: السائق ينقر بقفّاز وأحيانًا
/// والشاحنة تتحرّك، فالهدف الصغير هنا خطأ وظيفي لا ذوقي.
class AppBottomBar extends StatelessWidget {
  const AppBottomBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onChanged,
  });

  final List<BottomBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onChanged;

  static const _duration = Duration(milliseconds: 340);
  static const _curve = Curves.easeOutCubic;

  /// نصيب العنصر النشط من عرض الشريط. الباقي يُقسَّم على البقية.
  static const _activeShare = 0.42;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: p.surfaceElevated,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: p.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.42 : 0.10),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final activeWidth = width * _activeShare;
            final restWidth = (width - activeWidth) / (items.length - 1);

            return Row(
              children: [
                for (var index = 0; index < items.length; index++)
                  _Item(
                    item: items[index],
                    selected: index == currentIndex,
                    width: index == currentIndex ? activeWidth : restWidth,
                    onTap: () {
                      if (index == currentIndex) return;
                      HapticFeedback.selectionClick();
                      onChanged(index);
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.item,
    required this.selected,
    required this.width,
    required this.onTap,
  });

  final BottomBarItem item;
  final bool selected;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;

    return AnimatedContainer(
      duration: AppBottomBar._duration,
      curve: AppBottomBar._curve,
      width: width,
      height: 52,
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: selected ? p.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: selected ? 1 : 0),
            duration: AppBottomBar._duration,
            curve: AppBottomBar._curve,
            builder: (context, t, _) {
              final color = Color.lerp(p.textMuted, p.onPrimaryContainer, t)!;

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // الظل أسفل الأيقونة يرفعها عن سطح الحبّة، ويشتدّ مع
                  // الاختيار فتبدو نافرة لا مطبوعة. الكبر الطفيف يكمل الإيحاء.
                  Transform.translate(
                    offset: Offset(0, -1.5 * t),
                    child: Transform.scale(
                      scale: 1 + 0.10 * t,
                      child: Icon(
                        selected ? item.activeIcon : item.icon,
                        size: 26,
                        color: color,
                        shadows: [
                          Shadow(
                            color: Colors.black
                                .withValues(alpha: 0.20 + 0.30 * t),
                            blurRadius: 5 + 5 * t,
                            offset: Offset(0, 2 + 1.5 * t),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // النص يفتح عرضه مع التمدّد بدل أن يظهر فجأة، فلا يقفز
                  // المحتوى داخل الحبّة.
                  ClipRect(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: t,
                      child: Opacity(
                        opacity: t,
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(start: 8),
                          child: Text(
                            item.label,
                            maxLines: 1,
                            softWrap: false,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
