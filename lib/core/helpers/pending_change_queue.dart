import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Adds offline changes to a repository's pending-change list.
///
/// Unlike the old per-repository duplicate check, a later edit is never
/// dropped:
/// - create + update -> one create carrying the latest data, because the
///   record has no server id yet for the update to target
/// - create + delete -> both removed, the server never sees the record
/// - update + update -> both kept and sent in order, as they would have been
///   online (an exact repeat of the last update is skipped)
/// - update + delete -> one delete
class PendingChangeQueue {
  PendingChangeQueue._();

  /// [singleton] is for resources with one record per user (payment config),
  /// where create and update share the same endpoint and there is no id.
  static void add(
    List<Map<String, dynamic>> queue, {
    required String type,
    required String endpoint,
    required Map<String, dynamic> data,
    String? filePath,
    String? fileFieldName,
    bool singleton = false,
    String label = 'pending change',
  }) {
    final payload = Map<String, dynamic>.from(data);

    switch (type) {
      case 'create':
        _addCreate(queue, endpoint, payload, filePath, fileFieldName,
            singleton, label);
        break;
      case 'update':
        _addUpdate(queue, endpoint, payload, filePath, fileFieldName,
            singleton, label);
        break;
      case 'delete':
        _addDelete(queue, endpoint, payload, singleton, label);
        break;
      default:
        _append(queue, type, endpoint, payload, filePath, fileFieldName, label);
    }
  }

  static void _addCreate(
    List<Map<String, dynamic>> queue,
    String endpoint,
    Map<String, dynamic> payload,
    String? filePath,
    String? fileFieldName,
    bool singleton,
    String label,
  ) {
    final localId = payload['localId'];
    final index = queue.indexWhere((change) {
      if (change['type'] != 'create' || change['endpoint'] != endpoint) {
        return false;
      }
      if (singleton) return true;
      return localId != null && _dataOf(change)['localId'] == localId;
    });

    if (index != -1) {
      _mergeInto(queue[index], payload, filePath, fileFieldName);
      _log('Merged $label create into waiting create: $endpoint');
      return;
    }

    _append(queue, 'create', endpoint, payload, filePath, fileFieldName, label);
  }

  static void _addUpdate(
    List<Map<String, dynamic>> queue,
    String endpoint,
    Map<String, dynamic> payload,
    String? filePath,
    String? fileFieldName,
    bool singleton,
    String label,
  ) {
    // The record was created offline and hasn't reached the server yet:
    // fold the edit into the create so it is sent as one request.
    // Limitation: a field the update leaves out (for example roomId when a
    // tenant is taken out of a room) keeps the value from the create.
    final createIndex = _findCreateFor(queue, endpoint, singleton);
    if (createIndex != -1) {
      final fields = Map<String, dynamic>.from(payload)..remove('id');
      _mergeInto(queue[createIndex], fields, filePath, fileFieldName);
      _log('Merged $label update into waiting create: $endpoint');
      return;
    }

    final lastIndex =
        queue.lastIndexWhere((change) => change['endpoint'] == endpoint);
    if (lastIndex != -1) {
      final last = queue[lastIndex];
      final sameData = jsonEncode(_dataOf(last)) == jsonEncode(payload);
      if (_isUpdate(last['type']) && sameData && filePath == null) {
        _log('Skipped repeat of the last $label update: $endpoint');
        return;
      }
    }

    _append(queue, 'update', endpoint, payload, filePath, fileFieldName, label);
  }

  static void _addDelete(
    List<Map<String, dynamic>> queue,
    String endpoint,
    Map<String, dynamic> payload,
    bool singleton,
    String label,
  ) {
    final createIndex = _findCreateFor(queue, endpoint, singleton);
    if (createIndex != -1) {
      // Never reached the server: drop the create and everything after it.
      queue.removeAt(createIndex);
      queue.removeWhere((change) => _touches(change, endpoint));
      _log('Dropped $label created offline and deleted offline: $endpoint');
      return;
    }

    queue.removeWhere(
        (change) => change['type'] != 'delete' && _touches(change, endpoint));

    final alreadyQueued = queue.any((change) =>
        change['type'] == 'delete' && change['endpoint'] == endpoint);
    if (alreadyQueued) return;

    _append(queue, 'delete', endpoint, payload, null, null, label);
  }

  /// Finds the waiting create for the record at [endpoint], e.g. the create
  /// on `/buildings` with localId `abc` for `/buildings/abc`.
  static int _findCreateFor(
    List<Map<String, dynamic>> queue,
    String endpoint,
    bool singleton,
  ) {
    return queue.indexWhere((change) {
      if (change['type'] != 'create') return false;
      final createEndpoint = change['endpoint'];
      if (createEndpoint is! String) return false;
      if (singleton) return createEndpoint == endpoint;
      final localId = _dataOf(change)['localId'];
      return localId != null && endpoint == '$createEndpoint/$localId';
    });
  }

  static bool _touches(Map<String, dynamic> change, String endpoint) {
    final changeEndpoint = change['endpoint'];
    return changeEndpoint == endpoint ||
        (changeEndpoint is String && changeEndpoint.startsWith('$endpoint/'));
  }

  // Older app versions queued report status changes as 'updateStatus'.
  static bool _isUpdate(Object? type) =>
      type == 'update' || type == 'updateStatus';

  static Map<String, dynamic> _dataOf(Map<String, dynamic> change) {
    final data = change['data'];
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  static void _mergeInto(
    Map<String, dynamic> change,
    Map<String, dynamic> fields,
    String? filePath,
    String? fileFieldName,
  ) {
    change['data'] = _dataOf(change)..addAll(fields);
    if (filePath != null) {
      change['filePath'] = filePath;
      change['fileFieldName'] = fileFieldName;
    }
    change['timestamp'] = DateTime.now().toIso8601String();
    change['retryCount'] = 0;
  }

  static void _append(
    List<Map<String, dynamic>> queue,
    String type,
    String endpoint,
    Map<String, dynamic> payload,
    String? filePath,
    String? fileFieldName,
    String label,
  ) {
    queue.add({
      'type': type,
      'data': payload,
      'endpoint': endpoint,
      'timestamp': DateTime.now().toIso8601String(),
      'retryCount': 0,
      if (filePath != null) 'filePath': filePath,
      if (fileFieldName != null) 'fileFieldName': fileFieldName,
    });
    _log('Added $label: $type $endpoint${filePath != null ? ' with file' : ''}');
  }

  static void _log(String message) {
    if (kDebugMode) print(message);
  }
}
