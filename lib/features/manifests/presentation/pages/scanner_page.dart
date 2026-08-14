import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../core/audio/scan_feedback.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/manifest.dart';
import '../cubit/manifest_cubit.dart';
import '../widgets/manual_entry_sheet.dart';

/// شاشة المسح.
///
/// تبقى الكاميرا مفتوحة بين طرد وآخر: السائق يمسح عشرات الكراتين بالتتابع،
/// وإغلاق الشاشة بعد كل مسحة يضاعف الوقت بلا فائدة.
class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final MobileScannerController? _controller =
      kIsWeb ? null : MobileScannerController(formats: const []);

  ScanOutcome? _lastOutcome;
  bool _busy = false;

  /// آخر رمز عولج ووقته — الكاميرا تُطلق نفس الباركود عشرات المرات في الثانية.
  String? _lastCode;
  DateTime _lastCodeAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    // تحميل أربعين طردًا يستغرق دقائق واليد مشغولة بالكرتون، فإطفاء الشاشة
    // في منتصف العمل يعني فتح القفل بعد كل طرد.
    WakelockPlus.enable().ignore();
  }

  @override
  void dispose() {
    WakelockPlus.disable().ignore();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    final code = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .firstWhere((value) => value != null && value.isNotEmpty,
            orElse: () => null);

    if (code == null || _busy) return;

    final now = DateTime.now();
    final isRepeat = code == _lastCode &&
        now.difference(_lastCodeAt) < const Duration(seconds: 3);
    if (isRepeat) return;

    _lastCode = code;
    _lastCodeAt = now;

    await _process(code);
  }

  Future<void> _process(String code) async {
    setState(() => _busy = true);

    final outcome = await context.read<ManifestCubit>().handleScan(code);

    ScanFeedback.play(switch (outcome) {
      ScanAccepted() => ScanTone.accepted,
      ScanAlreadyDone() => ScanTone.duplicate,
      _ => ScanTone.rejected,
    }).ignore();

    if (!mounted) return;
    setState(() {
      _lastOutcome = outcome;
      _busy = false;
    });
  }

  Future<void> _enterManually() async {
    final code = await showManualEntrySheet(context);
    if (code != null && mounted) await _process(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('مسح الطرود'),
        actions: [
          if (_controller != null)
            IconButton(
              onPressed: () => _controller.toggleTorch(),
              icon: const Icon(Icons.flashlight_on_outlined),
              tooltip: 'الإضاءة',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_controller != null)
                  MobileScanner(controller: _controller, onDetect: _onDetect)
                else
                  const _CameraUnavailable(),
                const _ScanFrame(),
              ],
            ),
          ),
          _ResultPanel(
            outcome: _lastOutcome,
            busy: _busy,
            onManualEntry: _enterManually,
          ),
        ],
      ),
    );
  }
}

class _CameraUnavailable extends StatelessWidget {
  const _CameraUnavailable();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.no_photography_outlined,
                  size: 44, color: Colors.white54),
              SizedBox(height: 14),
              Text(
                'الكاميرا غير متاحة هنا.\nاستخدم الإدخال اليدوي بالأسفل.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 250,
        height: 160,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white70, width: 2.5),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.outcome,
    required this.busy,
    required this.onManualEntry,
  });

  final ScanOutcome? outcome;
  final bool busy;
  final VoidCallback onManualEntry;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final text = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      color: p.background,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BlocBuilder<ManifestCubit, ManifestState>(
              builder: (context, state) => Column(
                children: [
                  Text(
                    state.isUnloadingPhase ? 'التفريغ' : 'التحميل',
                    style: text.bodySmall?.copyWith(color: p.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${state.handled} من ${state.total}',
                    style: text.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (busy)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(),
              )
            else if (outcome != null)
              _OutcomeBanner(outcome: outcome!)
            else
              Text(
                'وجّه الكاميرا نحو الباركود',
                style: text.bodyMedium?.copyWith(color: p.textSecondary),
              ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onManualEntry,
              icon: const Icon(Icons.keyboard_alt_outlined, size: 18),
              label: const Text('إدخال الرقم يدويًا'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutcomeBanner extends StatelessWidget {
  const _OutcomeBanner({required this.outcome});

  final ScanOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final text = Theme.of(context).textTheme;

    final (background, foreground, icon, title, subtitle) = switch (outcome) {
      ScanAccepted(:final parcel, :final status, :final queued) => (
          p.successContainer,
          p.onSuccessContainer,
          queued ? Icons.cloud_off : Icons.check_circle,
          status == ManifestItemStatus.unloaded ? 'تم التفريغ' : 'تم التحميل',
          // النجاح مؤكَّد للسائق في الحالتين، لكنه يعرف أن الإرسال مؤجَّل.
          queued
              ? '${parcel.trackingNumber} · بانتظار الشبكة'
              : parcel.trackingNumber,
        ),
      ScanAlreadyDone(:final parcel) => (
          p.primaryContainer,
          p.onPrimaryContainer,
          Icons.done_all,
          'مُسجّل مسبقًا',
          parcel.trackingNumber,
        ),
      ScanNotOnManifest(:final parcel) => (
          p.dangerContainer,
          p.onDangerContainer,
          Icons.wrong_location_outlined,
          'ليس على هذه الشاحنة',
          parcel.trackingNumber,
        ),
      ScanFailed(:final message) => (
          p.dangerContainer,
          p.onDangerContainer,
          Icons.error_outline,
          'تعذّر المسح',
          message,
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: foreground, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: text.titleSmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: text.bodySmall?.copyWith(color: foreground),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
