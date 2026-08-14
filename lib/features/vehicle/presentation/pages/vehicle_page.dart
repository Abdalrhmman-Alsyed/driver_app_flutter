import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../profile/data/models/my_profile.dart';

/// شاشة قراءة فقط: السائق يرى مركبته ولا يعدّلها — التعديل صلاحية المكتب.
///
/// المركبة تأتي ضمن الملف الشخصي لا بطلب مستقلّ، فيوفّر ذلك رحلة شبكة
/// ويعرض الإسناد الحالي فعلًا: معرّف المركبة داخل التوكن يبقى قديمًا بعد أي
/// إعادة إسناد حتى يسجّل السائق دخولًا جديدًا.
class VehiclePage extends StatelessWidget {
  const VehiclePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state;
    final vehicle = auth is AuthSignedIn ? auth.profile?.vehicle : null;

    return Scaffold(
      appBar: AppBar(title: const Text('مركبتي')),
      body: RefreshIndicator(
        onRefresh: () => context.read<AuthCubit>().refreshProfile(),
        child: vehicle == null
            ? ListView(
                children: const [
                  SizedBox(height: 60),
                  EmptyView(
                    icon: Icons.no_transfer_outlined,
                    title: 'لا توجد مركبة مسندة إليك',
                    subtitle: 'راجع المكتب لإسناد مركبة، ثم اسحب للتحديث',
                  ),
                ],
              )
            : _VehicleCard(vehicle: vehicle),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.vehicle});

  final ProfileVehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final text = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: p.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.border),
          ),
          child: Column(
            children: [
              Icon(Icons.local_shipping, size: 52, color: p.primary),
              const SizedBox(height: 14),
              Text(
                vehicle.plateNumber,
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
              StatusChip(
                label: vehicle.statusLabel,
                tone:
                    vehicle.isReady ? StatusTone.success : StatusTone.danger,
              ),
              const SizedBox(height: 20),
              Divider(color: p.border, height: 1),
              const SizedBox(height: 12),
              _Row(label: 'النوع', value: vehicle.type ?? '—'),
              _Row(
                label: 'الحمولة القصوى',
                value: vehicle.capacityKg == null
                    ? '—'
                    : '${vehicle.capacityKg} كغ',
              ),
            ],
          ),
        ),
        if (!vehicle.isReady) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.dangerContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 20, color: p.onDangerContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'المركبة غير جاهزة للتشغيل. راجع المكتب قبل الانطلاق.',
                    style: text.bodyMedium
                        ?.copyWith(color: p.onDangerContainer),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Text(label,
              style: text.bodyMedium?.copyWith(color: p.textSecondary)),
          const Spacer(),
          Text(value,
              style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
