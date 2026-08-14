import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'app/router.dart';
import 'core/network/api_client.dart';
import 'core/storage/token_storage.dart';
import 'core/sync/pending_queue.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/manifests/data/manifest_repository.dart';
import 'features/manifests/data/models/manifest.dart';
import 'features/org_units/data/org_unit_repository.dart';
import 'features/parcels/data/parcel_repository.dart';
import 'features/trips/data/trip_repository.dart';
import 'features/vehicle/data/vehicle_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(tokenStorage: tokenStorage);

  final queue = PendingQueue();
  queue.sender = (update) => ManifestRepository(apiClient).updateItemStatus(
        manifestId: update.manifestId,
        itemId: update.itemId,
        status: ManifestItemStatus.from(update.status),
      );
  await queue.load();

  runApp(DriverApp(
    tokenStorage: tokenStorage,
    apiClient: apiClient,
    queue: queue,
  ));
}

class DriverApp extends StatefulWidget {
  const DriverApp({
    super.key,
    required this.tokenStorage,
    required this.apiClient,
    required this.queue,
  });

  final TokenStorage tokenStorage;
  final ApiClient apiClient;
  final PendingQueue queue;

  @override
  State<DriverApp> createState() => _DriverAppState();
}

class _DriverAppState extends State<DriverApp> with WidgetsBindingObserver {
  late final _orgUnits = OrgUnitRepository(widget.apiClient);
  late final _trips = TripRepository(widget.apiClient);
  late final _manifests = ManifestRepository(widget.apiClient);
  late final _parcels = ParcelRepository(widget.apiClient);
  late final _vehicles = VehicleRepository(widget.apiClient);

  late final _authCubit = AuthCubit(
    authRepository: AuthRepository(
      api: widget.apiClient,
      storage: widget.tokenStorage,
    ),
    orgUnits: _orgUnits,
  );

  late final GoRouter _router = buildRouter(_authCubit);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // فشل تجديد التوكن ينهي الجلسة، فيعيدنا الراوتر إلى شاشة الدخول.
    widget.apiClient.onSessionExpired = _authCubit.expire;
  }

  /// العودة إلى التطبيق أقوى مؤشّر على أن الشبكة قد تكون رجعت — السائق خرج
  /// من المستودع أو أنهى مكالمة — فنحاول المزامنة فورًا بدل انتظار الدورة.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) widget.queue.sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _orgUnits),
        RepositoryProvider.value(value: _trips),
        RepositoryProvider.value(value: _manifests),
        RepositoryProvider.value(value: _parcels),
        RepositoryProvider.value(value: _vehicles),
        RepositoryProvider.value(value: widget.queue),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _authCubit),
          BlocProvider(create: (_) => ThemeCubit()),
        ],
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, mode) {
            return MaterialApp.router(
              title: 'مسار',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: mode,
              routerConfig: _router,
              // التطبيق عربي فقط، فالاتجاه RTL دائمًا.
              locale: const Locale('ar'),
              supportedLocales: const [Locale('ar')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
            );
          },
        ),
      ),
    );
  }
}
