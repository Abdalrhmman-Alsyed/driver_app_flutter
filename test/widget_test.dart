import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:driver_app/core/theme/app_colors.dart';
import 'package:driver_app/core/theme/app_theme.dart';

void main() {
  test('كل ثيم يحمل لوحة ألوانه', () {
    expect(
      AppTheme.light().extension<AppPalette>(),
      isNotNull,
      reason: 'context.colors تعتمد على وجود الامتداد',
    );
    expect(AppTheme.dark().extension<AppPalette>(), isNotNull);
  });

  test('الوضع الداكن يقلب الأدوار لا الدرجات', () {
    final light = AppColors.light;
    final dark = AppColors.dark;

    // الأساسي في الداكن أفتح من الخلفية، وفي الفاتح أغمق منها.
    expect(
      dark.primary.computeLuminance(),
      greaterThan(dark.background.computeLuminance()),
      reason: 'زر غامق على خلفية غامقة يختفي',
    );
    expect(
      light.primary.computeLuminance(),
      lessThan(light.background.computeLuminance()),
    );
  });

  testWidgets('لوحة الألوان تصل إلى الشجرة عبر context.colors',
      (tester) async {
    late AppPalette resolved;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) {
            resolved = context.colors;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(resolved.primary, AppColors.light.primary);
  });
}
