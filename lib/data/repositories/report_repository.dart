import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:receipts_v2/data/models/enum/report_priority.dart';
import 'package:receipts_v2/data/models/enum/report_status.dart';
import 'package:receipts_v2/helpers/api_helper.dart';
import 'package:receipts_v2/data/models/report.dart';
import 'package:receipts_v2/data/dtos/report_dto.dart';
import 'package:logger/logger.dart';

class ReportRepository {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String storageKey = 'report_secure_data';
  final String pendingChangesKey = 'report_pending_changes';
  final ApiHelper _apiHelper = ApiHelper.instance;
  final Logger _logger = Logger();

  List<Report> _reportCache = [];
  List<Map<String, dynamic>> _pendingChanges = [];

  Future<void> load() async {
    try {
      _logger.i('Loading reports from secure storage');

      // Load reports
      final jsonString = await _secureStorage.read(key: storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonData = jsonDecode(jsonString);
        _reportCache = jsonData
            .map((json) => ReportDto.fromJson(json).toReport())
            .toList();
        _logger.i('Loaded ${_reportCache.length} reports from storage');
      } else {
        _reportCache = [];
      }

      // Load pending changes
      final pendingString = await _secureStorage.read(key: pendingChangesKey);
      if (pendingString != null && pendingString.isNotEmpty) {
        _pendingChanges =
            List<Map<String, dynamic>>.from(jsonDecode(pendingString));
        _logger.i('Loaded ${_pendingChanges.length} pending report changes');
      } else {
        _pendingChanges = [];
      }
    } catch (e) {
      _logger.e('Failed to load reports from secure storage: $e');
      throw Exception('Failed to load report data from secure storage: $e');
    }
  }

  Future<void> save() async {
    try {
      final jsonString = jsonEncode(_reportCache
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
      await _secureStorage.write(key: storageKey, value: jsonString);

      // Save pending changes
      if (_pendingChanges.isNotEmpty) {
        await _secureStorage.write(
          key: pendingChangesKey,
          value: jsonEncode(_pendingChanges),
        );
      }

      _logger.d(
          'Saved ${_reportCache.length} reports and ${_pendingChanges.length} pending changes to storage');
    } catch (e) {
      _logger.e('Failed to save reports to secure storage: $e');
      throw Exception('Failed to save report data to secure storage: $e');
    }
  }

  Future<void> _addPendingChange(String type, Map<String, dynamic> data) async {
    _pendingChanges.add({
      'type': type,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await save();
  }

  Future<void> _syncPendingChanges() async {
    if (_pendingChanges.isEmpty) return;

    _logger.i('Syncing ${_pendingChanges.length} pending report changes...');
    final successfulChanges = <int>[];

    for (int i = 0; i < _pendingChanges.length; i++) {
      final change = _pendingChanges[i];
      try {
        await _applyPendingChange(change);
        successfulChanges.add(i);
      } catch (e) {
        _logger.e('Failed to apply pending report change: $e');
      }
    }

    for (int i = successfulChanges.length - 1; i >= 0; i--) {
      _pendingChanges.removeAt(successfulChanges[i]);
    }

    if (successfulChanges.isNotEmpty) {
      await _secureStorage.write(
        key: pendingChangesKey,
        value: jsonEncode(_pendingChanges),
      );
      _logger.i(
          'Successfully synced ${successfulChanges.length} pending report changes');
    }
  }

  Future<void> _applyPendingChange(Map<String, dynamic> change) async {
    final token = await _secureStorage.read(key: 'auth_token');
    if (token == null) throw Exception('No auth token');

    final type = change['type'];
    final data = change['data'];

    switch (type) {
      case 'create':
        await _apiHelper.dio.post(
          '${_apiHelper.baseUrl}/reports',
          data: data,
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        break;
      case 'update':
        final reportId = data['id'];
        final updateData = Map<String, dynamic>.from(data);
        updateData.remove('id');
        await _apiHelper.dio.put(
          '${_apiHelper.baseUrl}/reports/$reportId',
          data: updateData,
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        break;
      case 'updateStatus':
        await _apiHelper.dio.patch(
          '${_apiHelper.baseUrl}/reports/${data['id']}/status',
          data: {'status': data['status']},
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        break;
      case 'delete':
        await _apiHelper.dio.delete(
          '${_apiHelper.baseUrl}/reports/${data['id']}',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        break;
    }
  }

  Future<void> syncFromApi({bool skipHydration = false}) async {
    try {
      if (!await _apiHelper.hasNetwork()) {
        _logger.w('No network connection, skipping sync');
        return;
      }

      final token = await _secureStorage.read(key: 'auth_token');
      if (token == null) {
        _logger.w('No auth token found, skipping sync');
        return;
      }

      // Sync pending changes first
      await _syncPendingChanges();

      _logger.i('Syncing reports from API');
      final response = await _apiHelper.dio.get(
        '${_apiHelper.baseUrl}/reports',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        cancelToken: _apiHelper.cancelToken,
      );

      if (response.data['cancelled'] == true) {
        _logger.w('Request cancelled due to network loss');
        return;
      }

      if (response.statusCode == 200) {
        final List<dynamic> reportsJson = response.data['data'];
        _reportCache = reportsJson
            .map((json) => ReportDto.fromJson(json).toReport())
            .toList();

        if (!skipHydration) {
          await save();
        }
        _logger.i('Synced ${_reportCache.length} reports from API');
      }
    } catch (e) {
      _logger.e('Failed to sync reports from API: $e');
    }
  }

  Future<Report> createReport(Report newReport) async {
    try {
      if (newReport.tenant == null) {
        throw Exception('Report must have a valid tenant');
      }

      Report createdReport = newReport;
      bool syncedOnline = false;

      if (await _apiHelper.hasNetwork()) {
        final token = await _secureStorage.read(key: 'auth_token');
        if (token != null) {
          _logger
              .i('Creating report via API for tenant: ${newReport.tenant!.id}');

          try {
            final requestData = ReportDto(
              id: newReport.id,
              tenantId: newReport.tenant!.id,
              roomId: newReport.room?.id,
              problemDescription: newReport.problemDescription,
              status: newReport.status.toApiString(),
              priority: newReport.priority.toApiString(),
              language: newReport.language.toApiString(),
              notes: newReport.notes,
            ).toRequestJson();

            final response = await _apiHelper.dio.post(
              '${_apiHelper.baseUrl}/reports',
              data: requestData,
              options: Options(headers: {'Authorization': 'Bearer $token'}),
              cancelToken: _apiHelper.cancelToken,
            );

            if (response.data['cancelled'] != true &&
                response.statusCode == 201) {
              final reportDto = ReportDto.fromJson(response.data['data']);
              createdReport = reportDto.toReport();

              createdReport.tenant = newReport.tenant;
              createdReport.room = newReport.room;

              syncedOnline = true;
              _logger.i('Report created successfully via API');
            }
          } catch (e) {
            _logger.w('Failed to create report online, will sync later: $e');
          }
        }
      }

      _reportCache.add(createdReport);

      if (!syncedOnline) {
        await _addPendingChange('create', {
          'tenantId': newReport.tenant!.id,
          if (newReport.room?.id != null) 'roomId': newReport.room!.id,
          'problemDescription': newReport.problemDescription,
          'status': newReport.status.toApiString(),
          'priority': newReport.priority.toApiString(),
          'language': newReport.language.toApiString(),
          if (newReport.notes != null) 'notes': newReport.notes,
          'localId': newReport.id,
        });
      }

      await save();
      return createdReport;
    } catch (e) {
      _logger.e('Failed to create report: $e');
      throw Exception('Failed to create report: $e');
    }
  }

  Future<Report> updateReport(Report updatedReport) async {
    try {
      if (updatedReport.tenant == null) {
        throw Exception('Report must have a valid tenant');
      }

      bool syncedOnline = false;

      if (await _apiHelper.hasNetwork()) {
        final token = await _secureStorage.read(key: 'auth_token');
        if (token != null) {
          _logger.i('Updating report via API: ${updatedReport.id}');

          try {
            final requestData = {
              'problemDescription': updatedReport.problemDescription,
              'status': updatedReport.status.toApiString(),
              'priority': updatedReport.priority.toApiString(),
              if (updatedReport.notes != null) 'notes': updatedReport.notes,
              if (updatedReport.room?.id != null)
                'roomId': updatedReport.room!.id,
            };

            final response = await _apiHelper.dio.put(
              '${_apiHelper.baseUrl}/reports/${updatedReport.id}',
              data: requestData,
              options: Options(headers: {'Authorization': 'Bearer $token'}),
              cancelToken: _apiHelper.cancelToken,
            );

            if (response.data['cancelled'] != true &&
                response.statusCode == 200) {
              syncedOnline = true;
              _logger.i('Report updated successfully via API');
            }
          } catch (e) {
            _logger.w('Failed to update report online, will sync later: $e');
          }
        }
      }

      final index = _reportCache.indexWhere((r) => r.id == updatedReport.id);
      if (index != -1) {
        _reportCache[index] = updatedReport;

        if (!syncedOnline) {
          await _addPendingChange('update', {
            'id': updatedReport.id,
            'problemDescription': updatedReport.problemDescription,
            'status': updatedReport.status.toApiString(),
            'priority': updatedReport.priority.toApiString(),
            if (updatedReport.notes != null) 'notes': updatedReport.notes,
            if (updatedReport.room?.id != null)
              'roomId': updatedReport.room!.id,
          });
        }

        await save();
        _logger.i('Report updated in local cache');
      } else {
        throw Exception('Report not found: ${updatedReport.id}');
      }

      return updatedReport;
    } catch (e) {
      _logger.e('Failed to update report: $e');
      throw Exception('Failed to update report: $e');
    }
  }

  Future<void> updateReportStatus(String reportId, String status) async {
    try {
      bool syncedOnline = false;

      if (await _apiHelper.hasNetwork()) {
        final token = await _secureStorage.read(key: 'auth_token');
        if (token != null) {
          _logger.i('Updating report status via API: $reportId -> $status');

          try {
            final response = await _apiHelper.dio.patch(
              '${_apiHelper.baseUrl}/reports/$reportId/status',
              data: {'status': status},
              options: Options(headers: {'Authorization': 'Bearer $token'}),
              cancelToken: _apiHelper.cancelToken,
            );

            if (response.data['cancelled'] != true &&
                response.statusCode == 200) {
              syncedOnline = true;
              _logger.i('Report status updated successfully via API');
            }
          } catch (e) {
            _logger.w(
                'Failed to update report status online, will sync later: $e');
          }
        }
      }

      final index = _reportCache.indexWhere((r) => r.id == reportId);
      if (index != -1) {
        _reportCache[index] = _reportCache[index].copyWith(
          status: ReportStatus.fromApiString(status),
        );

        if (!syncedOnline) {
          await _addPendingChange('updateStatus', {
            'id': reportId,
            'status': status,
          });
        }

        await save();
        _logger.i('Report status updated in local cache');
      }
    } catch (e) {
      _logger.e('Failed to update report status: $e');
      throw Exception('Failed to update report status: $e');
    }
  }

  Future<void> deleteReport(String reportId) async {
    try {
      bool syncedOnline = false;

      if (await _apiHelper.hasNetwork()) {
        final token = await _secureStorage.read(key: 'auth_token');
        if (token != null) {
          _logger.i('Deleting report via API: $reportId');

          try {
            final response = await _apiHelper.dio.delete(
              '${_apiHelper.baseUrl}/reports/$reportId',
              options: Options(headers: {'Authorization': 'Bearer $token'}),
              cancelToken: _apiHelper.cancelToken,
            );

            if (response.data['cancelled'] != true &&
                response.statusCode == 200) {
              syncedOnline = true;
              _logger.i('Report deleted successfully via API');
            }
          } catch (e) {
            _logger.w('Failed to delete report online, will sync later: $e');
          }
        }
      }

      _reportCache.removeWhere((r) => r.id == reportId);

      if (!syncedOnline) {
        await _addPendingChange('delete', {'id': reportId});
      }

      await save();
      _logger.i('Report deleted from local cache');
    } catch (e) {
      _logger.e('Failed to delete report: $e');
      throw Exception('Failed to delete report: $e');
    }
  }

  Future<void> restoreReport(int restoreIndex, Report report) async {
    _reportCache.insert(restoreIndex, report);
    await save();
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

  bool hasPendingChanges() {
    return _pendingChanges.isNotEmpty;
  }

  int getPendingChangesCount() {
    return _pendingChanges.length;
  }
}
