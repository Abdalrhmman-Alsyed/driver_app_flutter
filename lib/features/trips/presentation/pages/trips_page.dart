import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatting.dart';
import '../../../../core/widgets/entrance.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../org_units/data/org_unit_repository.dart';
import '../../data/models/trip.dart';
import '../cubit/trips_cubit.dart';

class TripsPage extends StatelessWidget {
  const TripsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<TripsCubit, TripsState>(
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: () => context.read<TripsCubit>().refresh(),
              child: Column(
                children: [
                  const _Greeting(),
                  _FilterBar(current: state.filter),
                  Expanded(child: _Body(state: state)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final TripsState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.trips.isEmpty) {
      return const SkeletonList();
    }

    if (state.error != null && state.trips.isEmpty) {
      return ErrorView(
        message: state.error!,
        onRetry: () => context.read<TripsCubit>().refresh(),
      );
    }

    if (state.trips.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 60),
          EmptyView(
            icon: Icons.local_shipping_outlined,
            title: 'لا توجد رحلات',
            subtitle: 'ستظهر هنا الرحلات المسندة إليك',
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: state.trips.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => Entrance(
        index: index,
        child: _TripCard(trip: state.trips[index]),
      ),
    );
  }
}

/// ترويسة تحمل اسم السائق ونظرة سريعة على رحلته الجارية.
class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final text = Theme.of(context).textTheme;
    final auth = context.watch<AuthCubit>().state;
    final identity = auth is AuthSignedIn ? auth.session.identity : '';

    final hour = DateTime.now().hour;
    final greeting = switch (hour) {
      >= 5 && < 12 => 'صباح الخير',
      >= 12 && < 17 => 'مساء الخير',
      _ => 'مساء الخير',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: p.primaryContainer,
            child: Text(
              auth is AuthSignedIn ? auth.session.initials : '؟',
              style: text.titleMedium?.copyWith(
                color: p.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: text.bodySmall?.copyWith(color: p.textSecondary),
                ),
                Text(
                  identity,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          BlocBuilder<TripsCubit, TripsState>(
            builder: (context, state) {
              if (state.activeTrip == null) return const SizedBox.shrink();
              return const StatusChip(
                label: 'رحلة جارية',
                tone: StatusTone.primary,
                icon: Icons.navigation,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({this.current});

  final TripStatus? current;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _chip(context, label: 'الكل', value: null),
          for (final status in TripStatus.values)
            _chip(context, label: status.label, value: status),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required TripStatus? value,
  }) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: current == value,
        showCheckmark: false,
        onSelected: (_) => context
            .read<TripsCubit>()
            .load(filter: value, replaceFilter: true),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final text = Theme.of(context).textTheme;
    final orgUnits = context.read<OrgUnitRepository>();
    final isActive = trip.status == TripStatus.inProgress;

    final tone = switch (trip.status) {
      TripStatus.inProgress => StatusTone.primary,
      TripStatus.completed => StatusTone.success,
      TripStatus.cancelled => StatusTone.danger,
      TripStatus.scheduled => StatusTone.neutral,
    };

    return Material(
      color: p.surfaceElevated,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.push('/trips/${trip.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? p.primary : p.border,
              width: isActive ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _Route(
                      from: orgUnits.nameOf(trip.originOrgUnitId),
                      to: orgUnits.nameOf(trip.destinationOrgUnitId),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusChip(label: trip.status.label, tone: tone),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.schedule, size: 15, color: p.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    Fmt.dateTime(trip.startedAt ?? trip.scheduledAt),
                    style: text.bodySmall?.copyWith(color: p.textSecondary),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_left, size: 20, color: p.textMuted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Route extends StatelessWidget {
  const _Route({required this.from, required this.to});

  final String from;
  final String to;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final text = Theme.of(context).textTheme;

    final style = text.titleSmall?.copyWith(fontWeight: FontWeight.w600);

    return Row(
      children: [
        Flexible(
          child: Text(from,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.arrow_back, size: 16, color: p.primary),
        ),
        Flexible(
          child: Text(to,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
        ),
      ],
    );
  }
}
