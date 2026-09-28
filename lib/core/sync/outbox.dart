import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:joul_v2/core/helpers/pending_change_queue.dart';
import 'package:joul_v2/core/services/encrypted_hive.dart';
import 'package:joul_v2/core/sync/outbox_files.dart';
import 'package:uuid/uuid.dart';

/// Status of a change waiting in the outbox.
class OutboxStatus {
  static const pending = 'pending';
  static const failed = 'failed';
}

/// One ordered queue of offline changes for every data type.
///
/// Each entry is a map with:
/// `opId`, `seq`, `entity`, `type` (create | update | delete), `endpoint`,
/// `data`, optional `filePath`/`fileFieldName`, `retryCount`, `timestamp`,
/// `status`, optional `lastError` and `nextTryAt`.
///
/// Changes are merged with [PendingChangeQueue] rules before being stored,
/// and are sent in `seq` order by the sync engine.
class Outbox {
  Outbox(this._box, this._meta);

  static const String boxName = 'outbox';
  static const String metaBoxName = 'sync_meta';
  static const String _idMapKey = 'idMap';

  static Outbox? _instance;

  /// The app-wide outbox, set by [init].
  static Outbox get instance {
    final outbox = _instance;
    if (outbox == null) {
      throw StateError('Outbox.init() has not been called');
    }
    return outbox;
  }

  /// Opens the outbox. [openBox] defaults to encrypted boxes; tests pass
  /// a plain opener.
  static Future<Outbox> init({
    Future<Box<dynamic>> Function(String name)? openBox,
  }) async {
    final open = openBox ?? EncryptedHive.open;
    final box = await open(boxName);
    final meta = await open(metaBoxName);
    final outbox = Outbox(box, meta);
    outbox._load();
    _instance = outbox;
    return outbox;
  }

  final Box<dynamic> _box;
  final Box<dynamic> _meta;

  /// Small key-value store for sync settings (see StorageSettings).
  Box<dynamic> get metaBox => _meta;
  final List<Map<String, dynamic>> _ops = [];
  final Map<String, String> _idMap = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();
  final Uuid _uuid = const Uuid();
  int _nextSeq = 0;
  String? _sendingOpId;

  /// Increases every time a new change is added (not when one is merged).
  int get addedCount => _nextSeq;

  /// Fires whenever an entry is added, changed or removed.
  Stream<void> get changes => _changes.stream;

  List<Map<String, dynamic>> get ops => List.unmodifiable(_ops);

  List<Map<String, dynamic>> get failedOps => _ops
      .where((op) => op['status'] == OutboxStatus.failed)
      .toList(growable: false);

  int get pendingCount =>
      _ops.where((op) => op['status'] != OutboxStatus.failed).length;

  int get failedCount => _ops.length - pendingCount;

  /// Every change not yet on the server, including failed ones.
  int get totalCount => _ops.length;

  bool get hasPending => pendingCount > 0;

  void _load() {
    _ops
      ..clear()
      ..addAll(_box.values.whereType<Map>().map(_normalize));
    _ops.sort((a, b) => (a['seq'] as int).compareTo(b['seq'] as int));
    _nextSeq = _ops.isEmpty ? 0 : (_ops.last['seq'] as int) + 1;

    final storedMap = _meta.get(_idMapKey);
    _idMap.clear();
    if (storedMap is Map) {
      storedMap.forEach((k, v) => _idMap[k.toString()] = v.toString());
    }
  }

  static Map<String, dynamic> _normalize(Map raw) {
    final op = Map<String, dynamic>.from(raw);
    final data = op['data'];
    op['data'] = data is Map ? _deepStringKeys(data) : <String, dynamic>{};
    op['seq'] = (op['seq'] as num?)?.toInt() ?? 0;
    op['retryCount'] = (op['retryCount'] as num?)?.toInt() ?? 0;
    op['status'] ??= OutboxStatus.pending;
    return op;
  }

  static Map<String, dynamic> _deepStringKeys(Map raw) {
    return raw.map((key, value) => MapEntry(
          key.toString(),
          value is Map
              ? _deepStringKeys(value)
              : value is List
                  ? value.map((e) => e is Map ? _deepStringKeys(e) : e).toList()
                  : value,
        ));
  }

  /// Adds a change, merging it with anything already waiting for the same
  /// record. Picked images are copied into app storage first, because the
  /// picker's temporary files can be deleted before the upload runs.
  Future<void> enqueue({
    required String entity,
    required String type,
    required String endpoint,
    required Map<String, dynamic> data,
    String? filePath,
    String? fileFieldName,
    bool singleton = false,
  }) async {
    final keptFile = filePath != null ? await OutboxFiles.keep(filePath) : null;

    final before = {for (final op in _ops) op['opId'] as String: op};

    // The change being uploaded right now must not absorb this one: it is
    // removed once the upload finishes. Queue behind it instead; offline ids
    // are rewritten if the upload was a create.
    final sendingIndex = _ops.indexWhere((op) => op['opId'] == _sendingOpId);
    final sending = sendingIndex == -1 ? null : _ops.removeAt(sendingIndex);

    PendingChangeQueue.add(
      _ops,
      type: type,
      endpoint: remapIds(endpoint) as String,
      data: remapIds(data) as Map<String, dynamic>,
      filePath: keptFile,
      fileFieldName: keptFile != null ? fileFieldName : null,
      singleton: singleton,
      label: '$entity change',
    );
    if (sending != null) {
      _ops.insert(sendingIndex.clamp(0, _ops.length), sending);
    }

    for (final op in _ops) {
      if (op['opId'] == null) {
        op['opId'] = _uuid.v4();
        op['seq'] = _nextSeq++;
        op['entity'] = entity;
      }
      op['status'] ??= OutboxStatus.pending;
    }

    final removedIds =
        before.keys.where((id) => !_ops.any((op) => op['opId'] == id));
    for (final id in removedIds) {
      await _deleteFileIfUnused(before[id]!['filePath'] as String?);
    }
    await _persist(removedIds);
  }

  /// The oldest change that is ready to send and not waiting on a failed one.
  Map<String, dynamic>? nextReady(DateTime now) {
    final blockers = _ops
        .where((op) => op['status'] == OutboxStatus.failed)
        .toList(growable: false);

    for (final op in _ops) {
      if (op['status'] == OutboxStatus.failed) continue;

      final nextTry = DateTime.tryParse(op['nextTryAt'] as String? ?? '');
      if (nextTry != null && nextTry.isAfter(now)) {
        // Keep the order: nothing after a change that is backing off.
        return null;
      }

      if (blockers.any((failed) => _dependsOn(op, failed))) continue;
      return op;
    }
    return null;
  }

  /// Whether a change to [endpoint] can go straight to the API: nothing is
  /// waiting to upload, and no failed change it depends on is held back.
  bool canSendDirectly(String endpoint, Map<String, dynamic> data) {
    if (hasPending) return false;
    final candidate = {'endpoint': remapIds(endpoint), 'data': data};
    return !_ops.any((failed) =>
        _dependsOn(candidate, failed) ||
        _dependsOn({'endpoint': failed['endpoint'], 'data': failed['data']},
            {'type': 'update', 'endpoint': endpoint}));
  }

  /// Whether [op] has to wait for [failed]: it touches the same record, or
  /// refers to a record that [failed] was supposed to create.
  static bool _dependsOn(Map<String, dynamic> op, Map<String, dynamic> failed) {
    final endpoint = op['endpoint'] as String? ?? '';
    final failedEndpoint = failed['endpoint'] as String? ?? '';

    if (failed['type'] == 'create') {
      final localId = (failed['data'] as Map?)?['localId']?.toString();
      if (localId == null || localId.isEmpty) return false;
      return endpoint.contains(localId) || _containsString(op['data'], localId);
    }

    return endpoint == failedEndpoint ||
        endpoint.startsWith('$failedEndpoint/');
  }

  static bool _containsString(Object? value, String needle) {
    if (value is String) return value.contains(needle);
    if (value is Map) {
      return value.values.any((v) => _containsString(v, needle));
    }
    if (value is List) return value.any((v) => _containsString(v, needle));
    return false;
  }

  /// Marks the change being uploaded, so edits made meanwhile queue behind
  /// it instead of merging into it.
  void markSending(String? opId) => _sendingOpId = opId;

  Future<void> markDone(String opId) async {
    if (_sendingOpId == opId) _sendingOpId = null;
    final op = _find(opId);
    if (op == null) return;
    _ops.remove(op);
    await _deleteFileIfUnused(op['filePath'] as String?);
    await _persist([opId]);
  }

  /// A temporary failure: try again later, keeping the order.
  Future<void> markRetry(String opId, String error) async {
    if (_sendingOpId == opId) _sendingOpId = null;
    final op = _find(opId);
    if (op == null) return;
    final attempts = (op['retryCount'] as int) + 1;
    op['retryCount'] = attempts;
    op['lastError'] = error;
    op['nextTryAt'] =
        DateTime.now().add(backoffFor(attempts)).toIso8601String();
    await _persist(const []);
  }

  /// A failure retrying won't fix. It waits for the user to retry or discard.
  Future<void> markFailed(String opId, String error) async {
    if (_sendingOpId == opId) _sendingOpId = null;
    final op = _find(opId);
    if (op == null) return;
    op['status'] = OutboxStatus.failed;
    op['lastError'] = error;
    op.remove('nextTryAt');
    await _persist(const []);
  }

  Future<void> retry(String opId) async {
    final op = _find(opId);
    if (op == null) return;
    op['status'] = OutboxStatus.pending;
    op['retryCount'] = 0;
    op.remove('nextTryAt');
    op.remove('lastError');
    await _persist(const []);
  }

  Future<void> retryAllFailed() async {
    for (final op in _ops) {
      if (op['status'] == OutboxStatus.failed) {
        op['status'] = OutboxStatus.pending;
        op['retryCount'] = 0;
        op.remove('lastError');
      }
    }
    await _persist(const []);
  }

  /// Makes every waiting change eligible to send right away, e.g. when the
  /// user taps Sync now or the connection comes back.
  Future<void> clearBackoff() async {
    var changed = false;
    for (final op in _ops) {
      if (op.remove('nextTryAt') != null) changed = true;
    }
    if (changed) await _persist(const []);
  }

  Future<void> discard(String opId) async {
    await markDone(opId);
  }

  /// Retry delays: 5 s, 30 s, 2 min, 10 min, then every 30 min.
  static Duration backoffFor(int attempts) {
    const steps = [
      Duration(seconds: 5),
      Duration(seconds: 30),
      Duration(minutes: 2),
      Duration(minutes: 10),
    ];
    return attempts <= steps.length
        ? steps[attempts - 1]
        : const Duration(minutes: 30);
  }

  /// Records that the server gave [serverId] to the record created offline
  /// as [localId], and rewrites every waiting change that refers to it.
  Future<void> applyIdMapping(String localId, String serverId) async {
    if (localId.isEmpty || serverId.isEmpty || localId == serverId) return;
    _idMap[localId] = serverId;
    await _meta.put(_idMapKey, Map<String, String>.from(_idMap));

    for (final op in _ops) {
      op['endpoint'] = _replaceIn(op['endpoint'], localId, serverId);
      op['data'] = _replaceIn(op['data'], localId, serverId);
    }
    await _persist(const []);
  }

  /// The server id for a record created offline, or [id] itself.
  String resolveId(String id) => _idMap[id] ?? id;

  /// Replaces offline ids that already have a server id.
  Object? remapIds(Object? value) {
    if (_idMap.isEmpty) return value;
    var result = value;
    _idMap.forEach((localId, serverId) {
      result = _replaceIn(result, localId, serverId);
    });
    return result;
  }

  static Object? _replaceIn(Object? value, String from, String to) {
    if (value is String) return value.replaceAll(from, to);
    if (value is Map) {
      return value
          .map((k, v) => MapEntry(k.toString(), _replaceIn(v, from, to)));
    }
    if (value is List) {
      return value.map((v) => _replaceIn(v, from, to)).toList();
    }
    return value;
  }

  /// Whether a change for the record [id] is still waiting (sent or not).
  bool hasChangesFor(String id) {
    if (id.isEmpty) return false;
    return _ops.any((op) {
      final endpoint = op['endpoint'] as String? ?? '';
      final segments = endpoint.split('/');
      return segments.contains(id) ||
          (op['data'] as Map?)?['localId']?.toString() == id;
    });
  }

  /// Whether the record [id] has a waiting delete.
  bool isPendingDelete(String id) => _ops.any((op) =>
      op['type'] == 'delete' &&
      (op['endpoint'] as String? ?? '').split('/').contains(id));

  /// Whether anything is waiting for [endpoint] (single-record resources).
  bool hasChangesForEndpoint(String endpoint) =>
      _ops.any((op) => op['endpoint'] == endpoint);

  /// Removes every waiting change, e.g. on sign-out.
  Future<void> clear() async {
    for (final op in _ops) {
      await _deleteFileIfUnused(op['filePath'] as String?, ignoreOps: true);
    }
    _ops.clear();
    _idMap.clear();
    _sendingOpId = null;
    await _box.clear();
    await _meta.delete(_idMapKey);
    _changes.add(null);
  }

  /// Moves changes queued by older app versions (one box per data type)
  /// into the outbox, keeping the order they were made in.
  Future<int> importLegacy(Map<String, Box<dynamic>> boxesByEntity) async {
    final legacy = <Map<String, dynamic>>[];
    boxesByEntity.forEach((entity, box) {
      for (final raw in box.values.whereType<Map>()) {
        final op = _normalize(raw);
        if (op['endpoint'] is! String || op['type'] is! String) continue;
        op['entity'] = entity;
        legacy.add(op);
      }
    });
    if (legacy.isEmpty) return 0;

    legacy.sort((a, b) => (a['timestamp'] as String? ?? '')
        .compareTo(b['timestamp'] as String? ?? ''));
    for (final op in legacy) {
      op['opId'] = _uuid.v4();
      op['seq'] = _nextSeq++;
      op['status'] = OutboxStatus.pending;
      op['retryCount'] = 0;
      _ops.add(op);
    }
    await _persist(const []);
    for (final box in boxesByEntity.values) {
      await box.clear();
    }
    if (kDebugMode) {
      print('📦 Moved ${legacy.length} queued changes into the outbox');
    }
    return legacy.length;
  }

  Map<String, dynamic>? _find(String opId) {
    for (final op in _ops) {
      if (op['opId'] == opId) return op;
    }
    return null;
  }

  Future<void> _deleteFileIfUnused(String? path,
      {bool ignoreOps = false}) async {
    if (path == null) return;
    if (!ignoreOps && _ops.any((op) => op['filePath'] == path)) return;
    await OutboxFiles.release(path);
  }

  Future<void> _persist(Iterable<String> removedIds) async {
    await _box.putAll({for (final op in _ops) op['opId'] as String: op});
    final removed = removedIds.toList();
    if (removed.isNotEmpty) await _box.deleteAll(removed);
    _changes.add(null);
  }
}
