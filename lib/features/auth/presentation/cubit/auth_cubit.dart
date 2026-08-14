import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../org_units/data/org_unit_repository.dart';
import '../../../profile/data/models/my_profile.dart';
import '../../../profile/data/profile_repository.dart';
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
  const AuthSignedIn(this.session, {this.profile});

  /// ما يُقرأ من التوكن: هوية السائق ومستأجره. متاح دائمًا.
  final DriverSession session;

  /// ما يأتي من الخادم: الاسم والهاتف والفرع والمركبة. قد يكون null إن تعذّر
  /// جلبه، فتعود الشاشات إلى البريد كهوية بديلة.
  final MyProfile? profile;

  String get displayName => profile?.fullName ?? session.identity;

  String get initials => profile?.initials ?? session.initials;

  AuthSignedIn copyWith({MyProfile? profile}) =>
      AuthSignedIn(session, profile: profile ?? this.profile);

  @override
  List<Object?> get props => [session, profile];
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
    required ProfileRepository profiles,
  })  : _auth = authRepository,
        _orgUnits = orgUnits,
        _profiles = profiles,
        super(const AuthUnknown());

  final AuthRepository _auth;
  final OrgUnitRepository _orgUnits;
  final ProfileRepository _profiles;

  Future<void> restore() async {
    // الثلاثة مستقلّة: قراءة الجلسة محلية، والفروع والملف الشخصي يعتمدان على
    // التوكن المخزّن مسبقًا. تشغيلها معًا يوفّر رحلتَي شبكة عند الإقلاع.
    final sessionFuture = _auth.restoreSession();
    final orgUnitsFuture = _preloadOrgUnits();
    final profileFuture = _loadProfile();

    final session = await sessionFuture;

    if (session == null) {
      emit(const AuthSignedOut());
      return;
    }

    await orgUnitsFuture;
    emit(AuthSignedIn(session, profile: await profileFuture));
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());

    try {
      final session = await _auth.login(email: email, password: password);

      final results = await Future.wait([_preloadOrgUnits(), _loadProfile()]);

      emit(AuthSignedIn(session, profile: results[1] as MyProfile?));
    } on ApiException catch (error) {
      emit(AuthSignedOut(error: error.message));
    }
  }

  /// إعادة قراءة الملف الشخصي — تستعملها شاشة المركبة عند السحب للتحديث،
  /// فإسناد مركبة جديدة يظهر دون تسجيل خروج.
  Future<void> refreshProfile() async {
    final current = state;
    if (current is! AuthSignedIn) return;

    final profile = await _loadProfile();
    if (profile != null) emit(current.copyWith(profile: profile));
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

  /// فشل جلب الملف الشخصي لا يمنع الدخول: التطبيق يعمل بالبريد كهوية بديلة،
  /// وحجب السائق عن رحلاته بسبب اسم ناقص أسوأ من عرض بريده.
  Future<MyProfile?> _loadProfile() async {
    try {
      return await _profiles.getMyProfile();
    } on ApiException {
      return null;
    }
  }

  /// وكذلك أسماء الفروع: تظهر بأسماء بديلة بدل أن تُغلق الشاشة.
  Future<void> _preloadOrgUnits() async {
    try {
      await _orgUnits.preload();
    } on ApiException {
      return;
    }
  }
}
