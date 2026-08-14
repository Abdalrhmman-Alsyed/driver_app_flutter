import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('سيتم إنهاء جلستك على هذا الجهاز.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('خروج'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    await context.read<AuthCubit>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final text = Theme.of(context).textTheme;
    final mode = context.watch<ThemeCubit>().state;
    final auth = context.watch<AuthCubit>().state;
    final session = auth is AuthSignedIn ? auth.session : null;

    return Scaffold(
      appBar: AppBar(title: const Text('حسابي')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: p.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: p.border),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: p.primaryContainer,
                  child: Text(
                    session?.initials ?? '؟',
                    style: text.headlineSmall?.copyWith(
                      color: p.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  session?.identity ?? 'سائق',
                  style:
                      text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 18),
                Divider(color: p.border, height: 1),
                const SizedBox(height: 12),
                _Row(
                  icon: Icons.badge_outlined,
                  label: 'الصفة',
                  value: 'سائق',
                ),
                _Row(
                  icon: Icons.local_shipping_outlined,
                  label: 'المركبة المسندة',
                  value: session?.vehicleId == null ? 'لا توجد' : 'مسندة',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('المظهر', style: text.titleMedium),
          const SizedBox(height: 10),
          _ThemeToggle(mode: mode),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: () => _logout(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: p.danger,
              side: BorderSide(color: p.danger.withValues(alpha: 0.5)),
            ),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }

}

/// مبدّل المظهر: داكن أو فاتح فقط.
///
/// لا خيار "حسب النظام": التطبيق يبدأ داكنًا، ومن أراد الفاتح يختاره صراحةً.
class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle({required this.mode});

  final ThemeMode mode;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final isDark = mode != ThemeMode.light;

    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final half = (constraints.maxWidth - 8) / 2;

          return Stack(
            children: [
              AnimatedPositionedDirectional(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                start: isDark ? 0 : half,
                width: half,
                height: 44,
                child: Container(
                  decoration: BoxDecoration(
                    color: p.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                children: [
                  _option(context, 'داكن', Icons.dark_mode, isDark,
                      ThemeMode.dark),
                  _option(context, 'فاتح', Icons.light_mode, !isDark,
                      ThemeMode.light),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _option(
    BuildContext context,
    String label,
    IconData icon,
    bool selected,
    ThemeMode value,
  ) {
    final p = context.colors;
    final color = selected ? p.onPrimaryContainer : p.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: () => context.read<ThemeCubit>().setMode(value),
        borderRadius: BorderRadius.circular(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 18, color: p.textMuted),
          const SizedBox(width: 10),
          Text(label,
              style: text.bodyMedium?.copyWith(color: p.textSecondary)),
          const Spacer(),
          Text(value,
              style:
                  text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
