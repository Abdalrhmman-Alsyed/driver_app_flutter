import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum StatusTone { neutral, primary, success, danger }

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.tone = StatusTone.neutral,
    this.icon,
  });

  final String label;
  final StatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;

    final (background, foreground) = switch (tone) {
      StatusTone.primary => (p.primaryContainer, p.onPrimaryContainer),
      StatusTone.success => (p.successContainer, p.onSuccessContainer),
      StatusTone.danger => (p.dangerContainer, p.onDangerContainer),
      StatusTone.neutral => (p.surface, p.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: foreground, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
