import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/models/vehicle.dart';
import '../../data/vehicle_repository.dart';

/// شاشة قراءة فقط: السائق يرى مركبته ولا يعدّلها — التعديل صلاحية المكتب.
///
/// معرّف المركبة يأتي من التوكن مباشرة، فلا حاجة لطلب إضافي لمعرفته.
class VehiclePage extends StatefulWidget {
  const VehiclePage({super.key});

  @override
  State<VehiclePage> createState() => _VehiclePageState();
}

class _VehiclePageState extends State<VehiclePage> {
  late Future<Vehicle?> _future = _load();

  Future<Vehicle?> _load() async {
    final state = context.read<AuthCubit>().state;
    if (state is! AuthSignedIn) return null;

    final vehicleId = state.session.vehicleId;
    if (vehicleId == null) return null;

    return context.read<VehicleRepository>().details(vehicleId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مركبتي')),
      body: FutureBuilder<Vehicle?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final error = snapshot.error;
            return ErrorView(
              message: error is ApiException
                  ? error.message
                  : 'تعذّر تحميل بيانات المركبة',
              onRetry: () => setState(() => _future = _load()),
            );
          }

          final vehicle = snapshot.data;
          if (vehicle == null) {
            return const EmptyView(
              icon: Icons.no_transfer_outlined,
              title: 'لا توجد مركبة مسندة إليك',
              subtitle: 'راجع المكتب لإسناد مركبة',
            );
          }

          return _VehicleCard(vehicle: vehicle);
        },
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.vehicle});

  final Vehicle vehicle;

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
                tone: vehicle.status == 'ACTIVE'
                    ? StatusTone.success
                    : StatusTone.danger,
              ),
              const SizedBox(height: 20),
              Divider(color: p.border, height: 1),
              const SizedBox(height: 12),
              _row(context, 'النوع', vehicle.type ?? '—'),
              _row(
                context,
                'الحمولة القصوى',
                vehicle.capacityKg == null ? '—' : '${vehicle.capacityKg} كغ',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, String label, String value) {
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
              style: text.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
