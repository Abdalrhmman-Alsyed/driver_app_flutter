import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/sync/pending_queue.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/manifests/data/manifest_repository.dart';
import '../features/manifests/presentation/cubit/manifest_cubit.dart';
import '../features/manifests/presentation/pages/manifest_page.dart';
import '../features/parcels/data/parcel_repository.dart';
import '../features/splash/presentation/pages/splash_page.dart';
import '../features/trips/data/trip_repository.dart';
import '../features/trips/presentation/cubit/trip_details_cubit.dart';
import '../features/trips/presentation/pages/trip_details_page.dart';

GoRouter buildRouter(AuthCubit authCubit) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: _CubitListenable(authCubit.stream),
    redirect: (context, state) {
      final auth = authCubit.state;
      final path = state.matchedLocation;

      // ما دامت الجلسة مجهولة تبقى شاشة الافتتاح ظاهرة.
      if (auth is AuthUnknown) return path == '/' ? null : '/';

      if (auth is AuthSignedIn) {
        return (path == '/' || path == '/login') ? '/home' : null;
      }

      // AuthLoading يحدث داخل شاشة الدخول نفسها، فلا ننقل المستخدم عنها.
      if (auth is AuthLoading) return path == '/login' ? null : '/login';

      return path == '/login' ? null : '/login';
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/home', builder: (_, __) => const HomePage()),
      GoRoute(
        path: '/trips/:tripId',
        builder: (context, state) => BlocProvider(
          create: (context) => TripDetailsCubit(
            trips: context.read<TripRepository>(),
            manifests: context.read<ManifestRepository>(),
            tripId: state.pathParameters['tripId']!,
          ),
          child: const TripDetailsPage(),
        ),
      ),
      GoRoute(
        path: '/manifests/:manifestId',
        builder: (context, state) => BlocProvider(
          create: (context) => ManifestCubit(
            manifests: context.read<ManifestRepository>(),
            parcels: context.read<ParcelRepository>(),
            queue: context.read<PendingQueue>(),
            manifestId: state.pathParameters['manifestId']!,
          ),
          child: const ManifestPage(),
        ),
      ),
    ],
  );
}

/// يجعل الراوتر يعيد تقييم التوجيه عند كل تغيّر في حالة المصادقة.
class _CubitListenable extends ChangeNotifier {
  _CubitListenable(Stream<AuthState> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
