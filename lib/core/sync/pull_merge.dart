import 'package:joul_v2/core/sync/outbox.dart';

/// Combines a fresh download with the local copy without losing changes
/// that are still waiting in the outbox.
///
/// - A record with a waiting change keeps its local version.
/// - A record created offline and not yet on the server is kept.
/// - A record with a waiting delete stays hidden.
/// - Everything else comes from the server.
List<T> mergePulled<T>({
  required List<T> server,
  required List<T> local,
  required String Function(T) idOf,
  Outbox? outbox,
}) {
  final box = outbox ?? Outbox.instance;
  final localById = {for (final item in local) idOf(item): item};
  final serverIds = <String>{};
  final merged = <T>[];

  for (final item in server) {
    final id = idOf(item);
    serverIds.add(id);
    if (box.isPendingDelete(id)) continue;
    final localItem = localById[id];
    merged.add(localItem != null && box.hasChangesFor(id) ? localItem : item);
  }

  for (final item in local) {
    final id = idOf(item);
    if (serverIds.contains(id)) continue;
    // Created offline (or edited while its create is waiting): keep it until
    // the server has it. The server id may already be known.
    if (box.hasChangesFor(id) && !serverIds.contains(box.resolveId(id))) {
      merged.add(item);
    }
  }

  return merged;
}
