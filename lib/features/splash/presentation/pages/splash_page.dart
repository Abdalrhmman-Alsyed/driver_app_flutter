import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/audio/startup_sound.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../widgets/shipping_label_animation.dart';

/// شاشة الافتتاح.
///
/// مدّة الأنيميشن ليست انتظارًا مصطنعًا: في نهايتها نقرأ الجلسة المحفوظة،
/// فيتكفّل الراوتر بالانتقال إلى الرئيسية أو إلى تسجيل الدخول.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  @override
  void initState() {
    super.initState();
    _play();
  }

  /// الأنيميشن وقراءة الجلسة يبدآن معًا لا بالتتابع: انتظار انتهاء الرسم
  /// قبل لمس الشبكة كان يضيف مدّة الأنيميشن كاملة إلى زمن الإقلاع.
  Future<void> _play() async {
    StartupSound.play();

    final restore = context.read<AuthCubit>().restore();
    final animation = _controller.forward().orCancel.catchError((_) => 0.0);

    await Future.wait([restore, animation]);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.colors;

    final nameFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.66, 0.92, curve: Curves.easeOut),
    );

    return Scaffold(
      backgroundColor: palette.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShippingLabelAnimation(progress: _controller),
            const SizedBox(height: 36),
            FadeTransition(
              opacity: nameFade,
              child: Column(
                children: [
                  Text(
                    'مسار',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                          letterSpacing: 1,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'نقل الشحنات بين الفروع',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: palette.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
