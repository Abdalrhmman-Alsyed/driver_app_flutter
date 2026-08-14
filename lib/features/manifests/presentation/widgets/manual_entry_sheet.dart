import 'package:flutter/material.dart';

/// إدخال رقم التتبع يدويًّا.
///
/// ليس بديلًا احتياطيًّا فحسب: الملصقات تتّسخ وتتمزّق في المستودع، ومن غير
/// هذا المخرج يعلق السائق أمام طرد لا يُقرأ باركوده.
Future<String?> showManualEntrySheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => const _ManualEntrySheet(),
  );
}

class _ManualEntrySheet extends StatefulWidget {
  const _ManualEntrySheet();

  @override
  State<_ManualEntrySheet> createState() => _ManualEntrySheetState();
}

class _ManualEntrySheetState extends State<_ManualEntrySheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'رقم التتبع',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            // الأرقام لاتينية دائمًا: هكذا هي مطبوعة على الملصق.
            style: const TextStyle(letterSpacing: 1.5),
            decoration: const InputDecoration(hintText: 'TRK-2026-0002'),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _submit, child: const Text('تأكيد')),
        ],
      ),
    );
  }
}
