import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/sync/pending_queue.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatting.dart';
import '../../../../core/widgets/entrance.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../org_units/data/org_unit_repository.dart';
import '../../../parcels/data/models/parcel.dart';
import '../../data/models/manifest.dart';
import '../cubit/manifest_cubit.dart';
import 'scanner_page.dart';

class ManifestPage extends StatefulWidget {
  const ManifestPage({super.key});

  @override
  State<ManifestPage> createState() => _ManifestPageState();
}

class _ManifestPageState extends State<ManifestPage> {
  @override
  void initState() {
    super.initState();
    context.read<ManifestCubit>().load();
  }

  void _openScanner() {
    final cubit = context.read<ManifestCubit>();

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: const ScannerPage(),
        ),
      ),
    );
  }

  Future<bool> _confirm(String title, String message, String confirmLabel) async {
    final result = await showDialog<bool>(
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
    return result ?? false;
  }

  Future<void> _markRemainingMissing(int count) async {
    final ok = await _confirm(
      'تأشير الطرود المفقودة',
      'سيُسجَّل $count طرد كمفقود. هذا الإجراء يُوثَّق باسمك ولا يمكن التراجع '
          'عنه من التطبيق.',
      'تأكيد',
    );
    if (!ok || !mounted) return;

    await context.read<ManifestCubit>().markRemainingMissing();
  }

  Future<void> _complete() async {
    final ok = await _confirm(
      'إقفال كشف الحمولة',
      'تأكّد من تفريغ كل الطرود. متابعة؟',
      'أقفل',
    );
    if (!ok || !mounted) return;

    final done = await context.read<ManifestCubit>().completeManifest();
    if (!mounted) return;

    if (done) {
      Navigator.of(context).pop();
    } else {
      final error = context.read<ManifestCubit>().state.error;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error ?? 'تعذّر الإقفال')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('كشف الحمولة')),
      body: BlocBuilder<ManifestCubit, ManifestState>(
        builder: (context, state) {
          if (state.isLoading && state.manifest == null) {
            return const SkeletonList(count: 5, lines: 2);
          }

          final manifest = state.manifest;
          if (manifest == null) {
            return ErrorView(
              message: state.error ?? 'تعذّر تحميل كشف الحمولة',
              onRetry: () => context.read<ManifestCubit>().load(),
            );
          }

          final isClosed = manifest.status == ManifestStatus.completed;

          return RefreshIndicator(
            onRefresh: () => context.read<ManifestCubit>().load(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _HeaderCard(state: state, manifest: manifest),
                const _PendingSyncBanner(),
                const SizedBox(height: 16),
                if (!isClosed) ...[
                  FilledButton.icon(
                    onPressed: state.isWorking ? null : _openScanner,
                    icon: const Icon(Icons.qr_code_scanner, size: 22),
                    label: Text(
                      state.isUnloadingPhase ? 'امسح للتفريغ' : 'امسح للتحميل',
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (state.pending.isNotEmpty && !isClosed) ...[
                  _PendingAlert(
                    count: state.pending.length,
                    isWorking: state.isWorking,
                    onMarkMissing: () =>
                        _markRemainingMissing(state.pending.length),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  'الطرود (${state.total})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                if (state.items.isEmpty)
                  const EmptyView(
                    icon: Icons.inbox_outlined,
                    title: 'لا طرود على هذا الكشف',
                  )
                else
                  for (final (index, item)
                      in state.itemsForDisplay.indexed) ...[
                    Entrance(
                      index: index,
                      child: _ItemTile(
                        item: item,
                        parcel: state.parcels[item.parcelId],
                        position: state.positionOf(item),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                if (manifest.canComplete) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: state.isWorking ? null : _complete,
                    icon: const Icon(Icons.lock_outline, size: 18),
                    label: const Text('إقفال كشف الحمولة'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.state, required this.manifest});

  final ManifestState state;
  final Manifest manifest;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final text = Theme.of(context).textTheme;
    final orgUnits = context.read<OrgUnitRepository>();

    final tone = switch (manifest.status) {
      ManifestStatus.completed => StatusTone.success,
      ManifestStatus.inTransit => StatusTone.primary,
      ManifestStatus.pending => StatusTone.neutral,
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
          Row(
            children: [
              Expanded(
                child: Text(
                  '${orgUnits.nameOf(manifest.originOrgUnitId)}'
                  '  ←  '
                  '${orgUnits.nameOf(manifest.destinationOrgUnitId)}',
                  style: text.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(label: manifest.status.label, tone: tone),
            ],
          ),
          const SizedBox(height: 14),
          // شريط متحرّك: بعد كل مسحة يزحف التقدّم بدل أن يقفز، فيرى السائق
          // أن مسحته سُجّلت.
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: state.progress),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: p.primaryContainer,
                valueColor: AlwaysStoppedAnimation(p.primary),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${state.handled} من ${state.total} '
                '${state.isUnloadingPhase ? "مُفرّغ" : "محمّل"}',
                style: text.bodySmall?.copyWith(color: p.textSecondary),
              ),
              const Spacer(),
              if (state.missing > 0)
                Text(
                  '${state.missing} مفقود',
                  style: text.bodySmall?.copyWith(
                    color: p.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// مؤشّر المسحات التي لم تصل الخادم بعد.
///
/// وجوده ضروري لا تجميلي: بدونه لا يعرف السائق أن عمله ما زال على جهازه
/// وحده، فيغلق التطبيق أو يسلّم الشاحنة وهو يظن أن كل شيء سُجّل.
class _PendingSyncBanner extends StatelessWidget {
  const _PendingSyncBanner();

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final queue = context.read<PendingQueue>();

    return ListenableBuilder(
      listenable: queue,
      builder: (context, _) {
        if (queue.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.border),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: p.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${queue.length} مسحة بانتظار المزامنة',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: p.textSecondary),
                  ),
                ),
                TextButton(
                  onPressed: queue.sync,
                  child: const Text('زامن الآن'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PendingAlert extends StatelessWidget {
  const _PendingAlert({
    required this.count,
    required this.isWorking,
    required this.onMarkMissing,
  });

  final int count;
  final bool isWorking;
  final VoidCallback onMarkMissing;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.dangerContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.danger.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, size: 20, color: p.onDangerContainer),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$count طرد لم يُمسح بعد',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: p.onDangerContainer,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: isWorking ? null : onMarkMissing,
              style: OutlinedButton.styleFrom(
                foregroundColor: p.onDangerContainer,
                side: BorderSide(color: p.danger.withValues(alpha: 0.5)),
                minimumSize: const Size.fromHeight(44),
              ),
              child: const Text('تأشيرها كمفقودة'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.item,
    required this.parcel,
    required this.position,
  });

  final ManifestItem item;
  final Parcel? parcel;
  final int position;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final text = Theme.of(context).textTheme;
    final orgUnits = context.read<OrgUnitRepository>();

    final tone = switch (item.status) {
      ManifestItemStatus.loaded => StatusTone.success,
      ManifestItemStatus.unloaded => StatusTone.success,
      ManifestItemStatus.missing => StatusTone.danger,
      ManifestItemStatus.pendingLoad => StatusTone.neutral,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  // الطرد الذي لم يُمسح بعد لا نعرف رقمه: بيانات الطرود لا
                  // تصل إلا عبر البحث برقم التتبع.
                  parcel?.trackingNumber ?? 'طرد رقم $position',
                  style: text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: parcel != null ? 1.2 : 0,
                    color: parcel != null ? p.textPrimary : p.textMuted,
                  ),
                ),
              ),
              StatusChip(label: item.status.label, tone: tone),
            ],
          ),
          if (parcel != null) ...[
            const SizedBox(height: 6),
            Text(
              [
                if (parcel!.description != null &&
                    parcel!.description!.isNotEmpty)
                  parcel!.description!,
                Fmt.weight(parcel!.actualWeightKg),
                orgUnits.nameOf(parcel!.destinationOrgUnitId),
              ].join(' · '),
              style: text.bodySmall?.copyWith(color: p.textSecondary),
            ),
            if (parcel!.isFragile ||
                parcel!.temperatureSensitive ||
                parcel!.requiresUprightHandling) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (parcel!.isFragile)
                    const StatusChip(
                      label: 'قابل للكسر',
                      tone: StatusTone.danger,
                      icon: Icons.warning_amber_rounded,
                    ),
                  if (parcel!.temperatureSensitive)
                    const StatusChip(
                      label: 'حسّاس للحرارة',
                      tone: StatusTone.danger,
                      icon: Icons.thermostat,
                    ),
                  if (parcel!.requiresUprightHandling)
                    const StatusChip(
                      label: 'يُحفظ قائمًا',
                      tone: StatusTone.danger,
                      icon: Icons.vertical_align_top,
                    ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}
