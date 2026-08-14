import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// وضع العرض المختار.
///
/// يبدأ داكنًا لا تابعًا للنظام: السائق يعمل ليلًا وفي كابينة، والشاشة الداكنة
/// أرفق بالعين على مدى وردية كاملة. يستطيع تغييره من حسابه.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.dark);

  void setMode(ThemeMode mode) => emit(mode);

  void toggle() => emit(
        state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
      );
}
