import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatting.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../manifests/data/models/manifest.dart';
import '../../../org_units/data/org_unit_repository.dart';
import '../../data/models/trip.dart';
import '../cubit/trip_details_cubit.dart';

class TripDetailsPage extends StatefulWidget {
  const TripDetailsPage({super.key});

  @override
  State<TripDetailsPage> createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends State<TripDetailsPage> {
  @override
  void initState() {
    super.initState();
    context.read<TripDetailsCubit>().load();
  }

  Future<void> _confirmAndRun({
    required String title,
    required String message,
    required String confirmLabel,
    required Future<bool> Function() action,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final ok = await action();
    if (!mounted) return;

    if (!ok) {
      final error = context.read<TripDetailsCubit>().state.error;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error ?? 'تعذّر إتمام العملية')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final orgUnits = context.read<OrgUnitRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الرحلة')),
      body: BlocBuilder<TripDetailsCubit, TripDetailsState>(
        builder: (context, state) {
          if (state.isLoading && state.trip == null) {
            return const SkeletonList(count: 3, lines: 3);
          }

          final trip = state.trip;
          if (trip == null) {
            return ErrorView(
              message: state.error ?? 'تعذّر تحميل الرحلة',
              onRetry: () => context.read<TripDetailsCubit>().load(),
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<TripDetailsCubit>().load(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _RouteCard(trip: trip, orgUnits: orgUnits),
                const SizedBox(height: 16),
                Text(
                  'كشوف الحمولة',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                if (state.manifests.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: p.border),
                    ),
                    child: Text(
                      'لا يوجد كشف حمولة على هذه الرحلة بعد.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: p.textSecondary),
                    ),
                  )
                else
                  for (final manifest in state.manifests) ...[
                    _ManifestTile(manifest: manifest, orgUnits: orgUnits),
                    const SizedBox(height: 8),
                  ],
                const SizedBox(height: 20),
                _Actions(
                  state: state,
                  onStart: () => _confirmAndRun(
                    title: 'بدء الرحلة',
                    message: 'سيتم تسجيل انطلاقك الآن. متابعة؟',
                    confirmLabel: 'ابدأ',
                    action: () => context.read<TripDetailsCubit>().start(),
                  ),
                  onComplete: () => _confirmAndRun(
                    title: 'إنهاء الرحلة',
                    message:
                        'تأكّد من تفريغ كل الطرود وإقفال كشوف الحمولة قبل '
                        'الإنهاء. متابعة؟',
                    confirmLabel: 'أنهِ',
                    action: () => context.read<TripDetailsCubit>().complete(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.trip, required this.orgUnits});

  final Trip trip;
  final OrgUnitRepository orgUnits;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;

    final tone = switch (trip.status) {
      TripStatus.inProgress => StatusTone.primary,
      TripStatus.completed => StatusTone.success,
      TripStatus.cancelled => StatusTone.danger,
      TripStatus.scheduled => StatusTone.neutral,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: StatusChip(label: trip.status.label, tone: tone),
          ),
          const SizedBox(height: 16),
          _point(context, orgUnits.nameOf(trip.originOrgUnitId), 'من',
              Icons.trip_origin),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 11),
            child: Container(width: 2, height: 22, color: p.border),
          ),
          _point(context, orgUnits.nameOf(trip.destinationOrgUnitId), 'إلى',
              Icons.place),
          const SizedBox(height: 16),
          Divider(color: p.border, height: 1),
          const SizedBox(height: 12),
          _row(context, 'موعد الانطلاق', Fmt.dateTime(trip.scheduledAt)),
          if (trip.startedAt != null)
            _row(context, 'الانطلاق الفعلي', Fmt.dateTime(trip.startedAt)),
          if (trip.endedAt != null)
            _row(context, 'الانتهاء', Fmt.dateTime(trip.endedAt)),
          if (trip.notes != null && trip.notes!.isNotEmpty)
            _row(context, 'ملاحظات', trip.notes!),
        ],
      ),
    );
  }

  Widget _point(
      BuildContext context, String name, String label, IconData icon) {
    final p = context.colors;
    final text = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(icon, size: 24, color: p.primary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: text.bodySmall?.copyWith(color: p.textMuted)),
            Text(name,
                style: text.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final p = context.colors;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: text.bodySmall?.copyWith(color: p.textSecondary)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.end, style: text.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _ManifestTile extends StatelessWidget {
  const _ManifestTile({required this.manifest, required this.orgUnits});

  final Manifest manifest;
  final OrgUnitRepository orgUnits;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final text = Theme.of(context).textTheme;

    final tone = switch (manifest.status) {
      ManifestStatus.completed => StatusTone.success,
      ManifestStatus.inTransit => StatusTone.primary,
      ManifestStatus.pending => StatusTone.neutral,
    };

    return InkWell(
      onTap: () => context.push('/manifests/${manifest.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: p.border),
        ),
        child: Row(
          children: [
            Icon(Icons.inventory_2_outlined, size: 22, color: p.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${orgUnits.nameOf(manifest.originOrgUnitId)}'
                    '  ←  '
                    '${orgUnits.nameOf(manifest.destinationOrgUnitId)}',
                    style: text.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${manifest.itemCount} طرد',
                    style: text.bodySmall?.copyWith(color: p.textSecondary),
                  ),
                ],
              ),
            ),
            StatusChip(label: manifest.status.label, tone: tone),
          ],
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.state,
    required this.onStart,
    required this.onComplete,
  });

  final TripDetailsState state;
  final VoidCallback onStart;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final trip = state.trip!;

    if (state.startBlockedByMissingManifest) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.dangerContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 20, color: p.onDangerContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'لا يمكن بدء الرحلة قبل إضافة كشف حمولة. راجع المكتب.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: p.onDangerContainer),
              ),
            ),
          ],
        ),
      );
    }

    if (state.canStart) {
      return FilledButton.icon(
        onPressed: state.isWorking ? null : onStart,
        icon: const Icon(Icons.play_arrow, size: 20),
        label: const Text('بدء الرحلة'),
      );
    }

    if (trip.canComplete) {
      return FilledButton.icon(
        onPressed: state.isWorking ? null : onComplete,
        icon: const Icon(Icons.flag_outlined, size: 20),
        label: const Text('إنهاء الرحلة'),
      );
    }

    return const SizedBox.shrink();
  }
}
