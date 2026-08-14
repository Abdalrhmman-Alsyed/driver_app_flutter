import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/app_bottom_bar.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../trips/data/trip_repository.dart';
import '../../../trips/presentation/cubit/trips_cubit.dart';
import '../../../trips/presentation/pages/trips_page.dart';
import '../../../vehicle/presentation/pages/vehicle_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  static const _items = [
    BottomBarItem(
      icon: Icons.route_outlined,
      activeIcon: Icons.route,
      label: 'رحلاتي',
    ),
    BottomBarItem(
      icon: Icons.local_shipping_outlined,
      activeIcon: Icons.local_shipping,
      label: 'مركبتي',
    ),
    BottomBarItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'حسابي',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state;
    if (auth is! AuthSignedIn) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return BlocProvider(
      create: (context) => TripsCubit(
        repository: context.read<TripRepository>(),
        driverId: auth.session.driverId,
      )..load(),
      child: Scaffold(
        body: _FadeThrough(
          index: _index,
          children: const [TripsPage(), VehiclePage(), ProfilePage()],
        ),
        bottomNavigationBar: AppBottomBar(
          items: _items,
          currentIndex: _index,
          onChanged: (index) => setState(() => _index = index),
        ),
      ),
    );
  }
}

/// انتقال بالتلاشي بين التبويبات مع إبقاء حالة كل واحد حيّة، فلا يُعاد تحميل
/// الرحلات كلما رجع السائق إلى تبويبها.
class _FadeThrough extends StatelessWidget {
  const _FadeThrough({required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (var i = 0; i < children.length; i++)
          AnimatedOpacity(
            opacity: i == index ? 1 : 0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: IgnorePointer(
              ignoring: i != index,
              child: TickerMode(
                enabled: i == index,
                child: children[i],
              ),
            ),
          ),
      ],
    );
  }
}
