import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:joul_v2/data/models/enum/report_priority.dart';
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
            tenantId: r.tenant?.id ?? '',
            roomId: r.room?.id,
            problemDescription: r.problemDescription,
            status: r.status.toApiString(),
            priority: r.priority.toApiString(),
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

    for (int i = 0; i < _pendingChanges.length; i++) {
      final change = _pendingChanges[i];
      final success = await _syncHelper.applyPendingChange(change);
      if (success) {
        successfulChanges.add(i);
      }
    }

    for (int i = successfulChanges.length - 1; i >= 0; i--) {
      _pendingChanges.removeAt(successfulChanges[i]);
    }

    if (successfulChanges.isNotEmpty) {
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
    _pendingChanges.add({
      'type': type,
      'data': data,
      'endpoint': endpoint,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<Report> createReport(Report newReport) async {
    if (newReport.tenant == null) {
      throw Exception('Report must have a valid tenant');
    }

    final requestData = {
      'id': newReport.id,
      'tenantId': newReport.tenant!.id,
      if (newReport.room?.id != null) 'roomId': newReport.room!.id,
      'problemDescription': newReport.problemDescription,
      'status': newReport.status.toApiString(),
      'priority': newReport.priority.toApiString(),
      'language': newReport.language.toApiString(),
      if (newReport.notes != null) 'notes': newReport.notes,
    };

    final result = await _syncHelper.create<Report>(
      endpoint: '/reports',
      data: requestData,
      fromJson: (json) => ReportDto.fromJson(json).toReport(),
      addToCache: (report) async {
        report.tenant = newReport.tenant;
        report.room = newReport.room;
        _reportCache.add(report);
      },
      addPendingChange: (type, data) => _addPendingChange(
        type,
        data,
        '/reports',
      ),
      offlineModel: newReport,
    );

    if (!result.success) {
      throw Exception('Failed to create report');
    }

    await save();
    return result.data ?? newReport;
  }

  Future<Report> updateReport(Report updatedReport) async {
    if (updatedReport.tenant == null) {
      throw Exception('Report must have a valid tenant');
    }

    final requestData = {
      'problemDescription': updatedReport.problemDescription,
      'status': updatedReport.status.toApiString(),
      'priority': updatedReport.priority.toApiString(),
      if (updatedReport.notes != null) 'notes': updatedReport.notes,
      if (updatedReport.room?.id != null) 'roomId': updatedReport.room!.id,
    };

    await _syncHelper.update(
      endpoint: '/reports/${updatedReport.id}',
      data: requestData,
      updateCache: () async {
        final index = _reportCache.indexWhere((r) => r.id == updatedReport.id);
        if (index != -1) {
          _reportCache[index] = updatedReport;
        } else {
          throw Exception('Report not found: ${updatedReport.id}');
        }
      },
      addPendingChange: (type, data) => _addPendingChange(
        type,
        data,
        '/reports/${updatedReport.id}',
      ),
    );

    await save();
    return updatedReport;
  }

  Future<void> updateReportStatus(String reportId, String status) async {
    final endpoint = '/reports/$reportId/status';
    final data = {'status': status};

    bool syncedOnline = false;

    if (await _apiHelper.hasNetwork()) {
      final token = await _apiHelper.storage.read(key: 'auth_token');
      if (token != null) {
        try {
          final response = await _apiHelper.dio.patch(
            '${_apiHelper.baseUrl}$endpoint',
            data: data,
            options: Options(headers: {'Authorization': 'Bearer $token'}),
            cancelToken: _apiHelper.cancelToken,
          );

          if (response.data['cancelled'] != true &&
              response.statusCode == 200) {
            syncedOnline = true;
          }
        } catch (e) {
          // Fall through to offline handling
        }
      }
    }

    // Update local cache
    final index = _reportCache.indexWhere((r) => r.id == reportId);
    if (index != -1) {
      _reportCache[index] = _reportCache[index].copyWith(
        status: ReportStatus.fromApiString(status),
      );
    } else {
      throw Exception('Report not found: $reportId');
    }

    // Add to pending changes if not synced online
    if (!syncedOnline) {
      await _addPendingChange('updateStatus', data, endpoint);
    }

    await save();
  }

  Future<void> deleteReport(String reportId) async {
    await _syncHelper.delete(
      endpoint: '/reports/$reportId',
      id: reportId,
      deleteFromCache: () async {
        _reportCache.removeWhere((r) => r.id == reportId);
      },
      addPendingChange: (type, data) => _addPendingChange(
        type,
        data,
        '/reports/$reportId',
      ),
    );

    await save();
  }

  Future<Report> restoreReport(int restoreIndex, Report report) async {
    _reportCache.insert(restoreIndex, report);

    final requestData = {
      'problemDescription': report.problemDescription,
      'status': report.status.name,
      'priority': report.priority.name,
      'language': report.language.name,
      'notes': report.notes,
      'tenantId': report.tenant?.id,
      'roomId': report.room?.id,
    };

    final result = await _syncHelper.create<Report>(
      endpoint: '/reports',
      data: requestData,
      fromJson: (json) => ReportDto.fromJson(json).toReport(),
      addToCache: (createdReport) async {
        _reportCache.removeAt(restoreIndex);
        _reportCache.insert(restoreIndex, createdReport);
      },
      addPendingChange: (type, data) => _addPendingChange(
        type,
        {...data, 'localId': report.id},
        '/reports',
      ),
      offlineModel: report,
    );

    await save();
    return result.data ?? report;
  }

  List<Report> getAllReports() {
    return List.unmodifiable(_reportCache);
  }

  List<Report> getReportsByTenant(String tenantId) {
    return _reportCache.where((r) => r.tenant?.id == tenantId).toList();
  }

  List<Report> getReportsByRoom(String roomId) {
    return _reportCache.where((r) => r.room?.id == roomId).toList();
  }

  List<Report> getReportsByStatus(ReportStatus status) {
    return _reportCache.where((r) => r.status == status).toList();
  }

  List<Report> getReportsByPriority(ReportPriority priority) {
    return _reportCache.where((r) => r.priority == priority).toList();
  }

  List<Report> getReportsByBuilding(String buildingId) {
    return _reportCache
        .where((r) => r.room?.building?.id == buildingId)
        .toList();
  }

  Report? getReportById(String reportId) {
    try {
      return _reportCache.firstWhere((r) => r.id == reportId);
    } catch (e) {
      return null;
    }
  }

  Map<ReportStatus, int> getReportCountsByStatus() {
    final counts = <ReportStatus, int>{};
    for (var status in ReportStatus.values) {
      counts[status] = _reportCache.where((r) => r.status == status).length;
    }
    return counts;
  }

  Map<ReportPriority, int> getReportCountsByPriority() {
    final counts = <ReportPriority, int>{};
    for (var priority in ReportPriority.values) {
      counts[priority] =
          _reportCache.where((r) => r.priority == priority).length;
    }
    return counts;
  }

  bool hasPendingChanges() => _pendingChanges.isNotEmpty;
  int getPendingChangesCount() => _pendingChanges.length;
}
