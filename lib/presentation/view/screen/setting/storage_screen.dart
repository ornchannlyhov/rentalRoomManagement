import 'package:flutter/material.dart';
import 'package:joul_v2/core/di/service_locator.dart';
import 'package:joul_v2/core/services/database_service.dart';
import 'package:joul_v2/core/sync/storage_settings.dart';
import 'package:joul_v2/core/sync/sync_engine.dart';
import 'package:joul_v2/data/repositories/receipt_repository.dart';
import 'package:joul_v2/l10n/app_localizations.dart';
import 'package:joul_v2/presentation/providers/receipt_provider.dart';

/// Lets the user choose how much receipt history stays on the phone and
/// remove older history. Removed receipts stay on the server.
class StorageScreen extends StatefulWidget {
  const StorageScreen({super.key});

  @override
  State<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen> {
  final StorageSettings _settings = StorageSettings.fromHive();
  final ReceiptRepository _receipts = locator<ReceiptRepository>();
  bool _working = false;

  int get _receiptCount => _receipts.getAllReceipts().length;

  Future<void> _applyWindow(int months) async {
    await _settings.setHistoryMonths(months);
    await _removeOutsideWindow(showResult: months != 0);
    // A longer window brings older receipts back on the next download.
    locator<SyncEngine>().requestSync(immediate: true);
  }

  Future<void> _removeAllHistory() async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.storageRemoveAllTitle),
        content: Text(l.storageRemoveAllMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.storageRemove,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final now = DateTime.now();
    await _settings.setHistoryFrom(DateTime(now.year, now.month, 1));
    await _removeOutsideWindow(showResult: true);
  }

  Future<void> _removeOutsideWindow({required bool showResult}) async {
    setState(() => _working = true);
    final removed = _receipts.applyHistoryWindow();
    if (removed > 0) {
      await _receipts.save();
      await locator<DatabaseService>().receiptsBox.compact();
      await locator<ReceiptProvider>().load();
    }
    if (!mounted) return;
    setState(() => _working = false);
    if (showResult) {
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.storageRemoved(removed))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final selected = _settings.historyMonths;

    return Scaffold(
      appBar: AppBar(title: Text(l.storageTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: const Icon(Icons.receipt_long_outlined),
            title: Text(l.storageReceiptsOnPhone(_receiptCount)),
          ),
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child:
                Text(l.storageHistoryTitle, style: theme.textTheme.titleSmall),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(l.storageHistoryHelp, style: theme.textTheme.bodySmall),
          ),
          for (final months in StorageSettings.historyMonthOptions)
            RadioListTile<int>(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              value: months,
              groupValue: selected,
              title: Text(
                  months == 0 ? l.storageKeepAll : l.storageKeepMonths(months)),
              onChanged: _working
                  ? null
                  : (value) {
                      if (value != null) _applyWindow(value);
                    },
            ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: OutlinedButton.icon(
              onPressed: _working ? null : _removeAllHistory,
              icon: const Icon(Icons.delete_sweep_outlined),
              label: Text(l.storageRemoveAll),
            ),
          ),
        ],
      ),
    );
  }
}
