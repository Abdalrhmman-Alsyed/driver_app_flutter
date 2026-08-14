import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../org_units/data/org_unit_repository.dart';
import '../../data/auth_repository.dart';
import '../../data/models/driver_session.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// قبل أن نعرف إن كانت هناك جلسة محفوظة — تُعرض شاشة الافتتاح خلالها.
class AuthUnknown extends AuthState {
  const AuthUnknown();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthSignedIn extends AuthState {
  const AuthSignedIn(this.session);

  final DriverSession session;

  @override
  List<Object?> get props => [session];
}

class AuthSignedOut extends AuthState {
  const AuthSignedOut({this.error});

  final String? error;

  @override
  List<Object?> get props => [error];
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required AuthRepository authRepository,
    required OrgUnitRepository orgUnits,
  })  : _auth = authRepository,
        _orgUnits = orgUnits,
        super(const AuthUnknown());

  final AuthRepository _auth;
  final OrgUnitRepository _orgUnits;

  Future<void> restore() async {
    // الطلبان مستقلّان: قراءة الجلسة محلية، وأسماء الفروع تعتمد على التوكن
    // المخزّن مسبقًا. تشغيلهما بالتوازي يوفّر رحلة شبكة كاملة عند الإقلاع.
    final sessionFuture = _auth.restoreSession();
    final orgUnitsFuture = _preloadOrgUnits();

    final session = await sessionFuture;

    if (session == null) {
      emit(const AuthSignedOut());
      return;
    }

    await orgUnitsFuture;
    emit(AuthSignedIn(session));
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());

    try {
      final session = await _auth.login(email: email, password: password);
      await _preloadOrgUnits();
      emit(AuthSignedIn(session));
    } on ApiException catch (error) {
      emit(AuthSignedOut(error: error.message));
    }
  }

  Future<void> logout() async {
    await _auth.logout();
    emit(const AuthSignedOut());
  }

  /// انتهت الجلسة أثناء الاستخدام ولم ينجح التجديد.
  void expire() {
    if (state is AuthSignedIn) {
      emit(const AuthSignedOut(error: 'انتهت الجلسة. سجّل الدخول من جديد.'));
    }
  }

  /// فشل تحميل أسماء الفروع لا يمنع الدخول: التطبيق يعمل بأسماء بديلة،
  /// وحجب السائق عن رحلاته بسبب قائمة فروع أسوأ من عرض اسم ناقص.
  Future<void> _preloadOrgUnits() async {
    try {
      await _orgUnits.preload();
    } on ApiException {
      return;
    }
  }
}
