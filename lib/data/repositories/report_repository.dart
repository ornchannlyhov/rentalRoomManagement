import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:joul_v2/data/models/enum/report_status.dart';
import 'package:joul_v2/core/helpers/api_helper.dart';
import 'package:joul_v2/core/helpers/sync_operation_helper.dart';
import 'package:joul_v2/data/models/report.dart';
import 'package:joul_v2/data/dtos/report_dto.dart';
import 'package:joul_v2/core/services/database_service.dart';

class ReportRepository {
  final DatabaseService _databaseService;
  final ApiHelper _apiHelper = ApiHelper.instance;
  final SyncOperationHelper _syncHelper = SyncOperationHelper();

  List<Report> _reportCache = [];
  List<Map<String, dynamic>> _pendingChanges = [];

  ReportRepository(this._databaseService);

  Future<void> load() async {
    try {
      final reportsList = _databaseService.reportsBox.values.toList();
      _reportCache = reportsList
          .map((e) =>
              ReportDto.fromJson(Map<String, dynamic>.from(e)).toReport())
          .toList();

      final pendingList = _databaseService.reportsPendingBox.values.toList();
      _pendingChanges =
          pendingList.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      throw Exception('Failed to load report data: $e');
    }
  }

  Future<void> loadWithoutHydration() async {
    final reportsList = _databaseService.reportsBox.values.toList();
    _reportCache = reportsList
        .map((e) => ReportDto.fromJson(Map<String, dynamic>.from(e)).toReport())
        .toList();

    final pendingList = _databaseService.reportsPendingBox.values.toList();
    _pendingChanges =
        pendingList.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> save() async {
    try {
      await _databaseService.reportsBox.clear();
      for (var i = 0; i < _reportCache.length; i++) {
        final dto = ReportDto(
          id: _reportCache[i].id,
          tenantId: _reportCache[i].tenantId,
          roomId: _reportCache[i].roomId,
          problemDescription: _reportCache[i].problemDescription,
          status: _reportCache[i].status.toApiString(),
          language: _reportCache[i].language.toApiString(),
          notes: _reportCache[i].notes,
        );
        await _databaseService.reportsBox.put(i, dto.toJson());
      }

      await _databaseService.reportsPendingBox.clear();
      for (var i = 0; i < _pendingChanges.length; i++) {
        await _databaseService.reportsPendingBox.put(i, _pendingChanges[i]);
      }
    } catch (e) {
      throw Exception('Failed to save report data: $e');
    }
  }

  Future<void> clear() async {
    await _databaseService.reportsBox.clear();
    await _databaseService.reportsPendingBox.clear();
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
      await save();
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
