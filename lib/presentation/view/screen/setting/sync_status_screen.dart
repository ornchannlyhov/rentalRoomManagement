import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:joul_v2/core/di/service_locator.dart';
import 'package:joul_v2/core/sync/outbox.dart';
import 'package:joul_v2/core/sync/sync_engine.dart';
import 'package:joul_v2/l10n/app_localizations.dart';

/// Shows whether everything is uploaded, lets the user sync by hand, and
/// lists changes the server rejected with Retry and Discard.
class SyncStatusScreen extends StatelessWidget {
  const SyncStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final engine = locator<SyncEngine>();
    final outbox = locator<Outbox>();

    return Scaffold(
      appBar: AppBar(title: Text(localizations.syncTitle)),
      body: ValueListenableBuilder<SyncState>(
        valueListenable: engine.state,
        builder: (context, sync, _) {
          final failed = outbox.failedOps;
          final waiting = outbox.ops
              .where((op) => op['status'] != OutboxStatus.failed)
              .toList();

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              _StatusCard(sync: sync),
              if (failed.isNotEmpty) ...[
                _SectionHeader(
                  title: localizations.syncFailedTitle,
                  action: failed.length > 1
                      ? TextButton(
                          onPressed: engine.retryAllFailed,
                          child: Text(localizations.syncRetryAll),
                        )
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(
                    localizations.syncFailedHelp,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                for (final op in failed) _FailedChangeTile(op: op),
              ],
              if (waiting.isNotEmpty) ...[
                _SectionHeader(title: localizations.syncWaitingTitle),
                for (final op in waiting) _ChangeTile(op: op),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.sync});

  final SyncState sync;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final engine = locator<SyncEngine>();
    final syncing = sync.phase == SyncPhase.syncing;
    final total = sync.pendingCount + sync.failedCount;

    final String headline = total == 0
        ? localizations.syncAllUploaded
        : localizations.changesWaiting(total);

    final String? hint = switch (sync.phase) {
      SyncPhase.offline => localizations.syncOfflineHint,
      SyncPhase.sessionExpired => localizations.syncSessionExpiredHint,
      SyncPhase.error => localizations.syncErrorHint,
      _ => null,
    };

    final lastSync = sync.lastSyncAt;
    final String lastSyncText = lastSync == null
        ? localizations.syncNeverSynced
        : localizations.syncLastSynced(
            DateFormat.yMMMd(localizations.localeName)
                .add_Hm()
                .format(lastSync));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  total == 0
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_upload_outlined,
                  color: total == 0 ? Colors.green : colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    headline,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(lastSyncText, style: Theme.of(context).textTheme.bodySmall),
            if (hint != null) ...[
              const SizedBox(height: 8),
              Text(hint, style: TextStyle(color: colorScheme.error)),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: syncing ? null : () => engine.syncNow(),
                icon: syncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                label: Text(syncing
                    ? localizations.syncInProgress
                    : localizations.syncNow),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// Human-readable name for what a change is about.
String _describe(AppLocalizations l, Map<String, dynamic> op) {
  final entity = switch (op['entity']) {
    'building' => l.syncEntityBuilding,
    'room' => l.syncEntityRoom,
    'tenant' => l.syncEntityTenant,
    'service' => l.syncEntityService,
    'receipt' => l.syncEntityReceipt,
    'report' => l.syncEntityReport,
    'paymentConfig' => l.syncEntityPaymentConfig,
    _ => op['entity']?.toString() ?? '',
  };
  final data = op['data'] as Map? ?? const {};
  final label = data['name'] ?? data['roomNumber'];
  return label == null ? entity : '$entity · $label';
}

String _typeLabel(AppLocalizations l, Object? type) => switch (type) {
      'create' => l.syncTypeCreate,
      'delete' => l.syncTypeDelete,
      _ => l.syncTypeUpdate,
    };

class _ChangeTile extends StatelessWidget {
  const _ChangeTile({required this.op});

  final Map<String, dynamic> op;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: const Icon(Icons.schedule_outlined),
      title: Text(_describe(l, op)),
      subtitle: Text(_typeLabel(l, op['type'])),
    );
  }
}

class _FailedChangeTile extends StatelessWidget {
  const _FailedChangeTile({required this.op});

  final Map<String, dynamic> op;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final engine = locator<SyncEngine>();
    final opId = op['opId'] as String;
    final error = op['lastError']?.toString();

    return ListTile(
      contentPadding: const EdgeInsets.only(left: 20, right: 8),
      leading:
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
      title: Text(_describe(l, op)),
      subtitle: Text(
        error == null
            ? _typeLabel(l, op['type'])
            : '${_typeLabel(l, op['type'])} · $error',
      ),
      isThreeLine: error != null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () => engine.retry(opId),
            child: Text(l.syncRetry),
          ),
          TextButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: Text(l.syncDiscardTitle),
                  content: Text(l.syncDiscardMessage),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: Text(l.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: Text(
                        l.syncDiscard,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
              if (confirmed == true) await engine.discard(opId);
            },
            child: Text(
              l.syncDiscard,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
