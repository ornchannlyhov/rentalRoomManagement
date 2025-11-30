import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:joul_v2/data/models/enum/report_status.dart';
import 'package:joul_v2/core/helpers/api_helper.dart';
import 'package:joul_v2/core/helpers/sync_operation_helper.dart';
import 'package:joul_v2/data/models/report.dart';
import 'package:joul_v2/data/dtos/report_dto.dart';

// Top-level functions for compute() isolation
List<Report> _parseReports(String jsonString) {
  final List<dynamic> jsonData = jsonDecode(jsonString);
  return jsonData.map((json) => ReportDto.fromJson(json).toReport()).toList();
}

String _encodeReports(List<Report> reports) {
  return jsonEncode(reports
      .map((r) => ReportDto(
            id: r.id,
            tenantId: r.tenantId,
            roomId: r.roomId,
            problemDescription: r.problemDescription,
            status: r.status.toApiString(),
            language: r.language.toApiString(),
            notes: r.notes,
          ).toJson())
      .toList());
}

List<Map<String, dynamic>> _parsePendingChanges(String jsonString) {
  return List<Map<String, dynamic>>.from(jsonDecode(jsonString));
}

class ReportRepository {
  final String storageKey = 'report_secure_data';
  final String pendingChangesKey = 'report_pending_changes';
  final ApiHelper _apiHelper = ApiHelper.instance;
  final SyncOperationHelper _syncHelper = SyncOperationHelper();

  List<Report> _reportCache = [];
  List<Map<String, dynamic>> _pendingChanges = [];

  ReportRepository();

  Future<void> load() async {
    try {
      final jsonString = await _apiHelper.storage.read(key: storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        _reportCache = await compute(_parseReports, jsonString);
      } else {
        _reportCache = [];
      }

      final pendingString =
          await _apiHelper.storage.read(key: pendingChangesKey);
      if (pendingString != null && pendingString.isNotEmpty) {
        _pendingChanges = await compute(_parsePendingChanges, pendingString);
      } else {
        _pendingChanges = [];
      }
    } catch (e) {
      throw Exception('Failed to load report data: $e');
    }
  }

  Future<void> save() async {
    try {
      // Only save if there's actual data
      if (_reportCache.isNotEmpty) {
        final jsonString = await compute(_encodeReports, _reportCache);
        await _apiHelper.storage.write(key: storageKey, value: jsonString);
      }

      // Save pending changes
      if (_pendingChanges.isNotEmpty) {
        final pendingJson = jsonEncode(_pendingChanges);
        await _apiHelper.storage.write(
          key: pendingChangesKey,
          value: pendingJson,
        );
      }
    } catch (e) {
      throw Exception('Failed to save report data: $e');
    }
  }

  Future<void> clear() async {
    await _apiHelper.storage.delete(key: storageKey);
    await _apiHelper.storage.delete(key: pendingChangesKey);
    _reportCache.clear();
    _pendingChanges.clear();
  }

  Future<void> syncFromApi({bool skipHydration = false}) async {
    if (!await _apiHelper.hasNetwork()) {
      return;
    }

    await _syncPendingChanges();

    final result = await _syncHelper.fetch<Report>(
      endpoint: '/reports',
      fromJsonList: (jsonList) =>
          jsonList.map((json) => ReportDto.fromJson(json).toReport()).toList(),
    );

    if (result.success && result.data != null) {
      _reportCache = result.data!;
      if (!skipHydration) {
        await save();
      }
    }
  }

  Future<void> _syncPendingChanges() async {
    if (_pendingChanges.isEmpty) return;

    final successfulChanges = <int>[];
    final failedChanges = <int>[];

    for (int i = 0; i < _pendingChanges.length; i++) {
      final change = _pendingChanges[i];
      final retryCount = change['retryCount'] ?? 0;

      // Max 5 retries for failed changes
      if (retryCount >= 5) {
        failedChanges.add(i);
        if (kDebugMode) {
          print(
              'Report pending change exceeded retry limit: ${change['type']} ${change['endpoint']}');
        }
        continue;
      }

      final success = await _syncHelper.applyPendingChange(change);

      if (success) {
        successfulChanges.add(i);
        if (kDebugMode) {
          print(
              'Successfully synced report pending change: ${change['type']} ${change['endpoint']}');
        }
      } else {
        // Increment retry count
        _pendingChanges[i]['retryCount'] = retryCount + 1;
        if (kDebugMode) {
          print(
              'Failed to sync report pending change (retry ${retryCount + 1}/5): ${change['type']} ${change['endpoint']}');
        }
      }
    }

    // Remove successful and permanently failed changes (reverse order)
    final toRemove = [...successfulChanges, ...failedChanges]
      ..sort((a, b) => b.compareTo(a));
    for (final index in toRemove) {
      _pendingChanges.removeAt(index);
    }

    if (successfulChanges.isNotEmpty || failedChanges.isNotEmpty) {
      await _apiHelper.storage.write(
        key: pendingChangesKey,
        value: jsonEncode(_pendingChanges),
      );
    }
  }

  Future<void> _addPendingChange(
    String type,
    Map<String, dynamic> data,
    String endpoint,
  ) async {
    // Check for duplicate pending changes
    final isDuplicate = _pendingChanges.any((change) {
      if (change['type'] != type || change['endpoint'] != endpoint) {
        return false;
      }

      // For updates/deletes, check if id matches
      if (data['id'] != null) {
        return change['data']['id'] == data['id'];
      }

      // For status updates, check endpoint (already has id in it)
      if (type == 'updateStatus') {
        return true; // Endpoint already contains the id
      }

      // Fallback: compare full data
      return jsonEncode(change['data']) == jsonEncode(data);
    });

    if (isDuplicate) {
      if (kDebugMode) {
        print('Skipping duplicate report pending change: $type $endpoint');
      }
      return;
    }

    _pendingChanges.add({
      'type': type,
      'data': data,
      'endpoint': endpoint,
      'timestamp': DateTime.now().toIso8601String(),
      'retryCount': 0,
    });

    if (kDebugMode) {
      print('Added report pending change: $type $endpoint');
    }
  }

  Future<void> updateReportStatus(String reportId, String status) async {
    final endpoint = '/reports/$reportId/status'; // ✅ Use status endpoint
    final requestData = {'status': status};

    await _syncHelper.update(
      endpoint: endpoint,
      data: requestData,
      updateCache: () async {
        final index = _reportCache.indexWhere((r) => r.id == reportId);
        if (index != -1) {
          _reportCache[index] = _reportCache[index].copyWith(
            status: ReportStatus.fromApiString(status),
          );
        } else {
          throw Exception('Report not found: $reportId');
        }
      },
      addPendingChange: (type, endpoint, data) => _addPendingChange(
        'updateStatus',
        data,
        endpoint,
      ),
    );

    await save();
  }

  Future<void> deleteReport(String reportId) async {
    await _syncHelper.delete(
      endpoint: '/reports/$reportId',
      id: reportId,
      deleteFromCache: () async {
        _reportCache.removeWhere((r) => r.id == reportId);
      },
      addPendingChange: (type, endpoint, data) => _addPendingChange(
        type,
        data,
        endpoint,
      ),
    );

    await save();
  }

  List<Report> getAllReports() {
    return List.unmodifiable(_reportCache);
  }

  List<Report> getReportsByStatus(ReportStatus status) {
    return _reportCache.where((r) => r.status == status).toList();
  }

  List<Report> getReportsByBuilding(String buildingId) {
    return _reportCache
        .where((r) => r.room?.building?.id == buildingId)
        .toList();
  }

  bool hasPendingChanges() => _pendingChanges.isNotEmpty;
  int getPendingChangesCount() => _pendingChanges.length;
}
