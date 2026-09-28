import 'package:joul_v2/data/models/enum/report_status.dart';
import 'package:joul_v2/core/helpers/api_helper.dart';
import 'package:joul_v2/core/sync/outbox.dart';
import 'package:joul_v2/core/sync/pull_merge.dart';
import 'package:joul_v2/core/helpers/sync_operation_helper.dart';
import 'package:joul_v2/data/models/report.dart';
import 'package:joul_v2/data/dtos/report_dto.dart';
import 'package:joul_v2/core/services/database_service.dart';

class ReportRepository {
  final DatabaseService _databaseService;
  final ApiHelper _apiHelper = ApiHelper.instance;
  final SyncOperationHelper _syncHelper = SyncOperationHelper();

  List<Report> _reportCache = [];

  ReportRepository(this._databaseService);

  Future<void> load() async {
    try {
      final reportsList = _databaseService.reportsBox.values.toList();
      _reportCache = reportsList
          .map((e) =>
              ReportDto.fromJson(Map<String, dynamic>.from(e)).toReport())
          .toList();
    } catch (e) {
      throw Exception('Failed to load report data: $e');
    }
  }

  Future<void> loadWithoutHydration() async {
    final reportsList = _databaseService.reportsBox.values.toList();
    _reportCache = reportsList
        .map((e) => ReportDto.fromJson(Map<String, dynamic>.from(e)).toReport())
        .toList();
  }

  Future<void> save() async {
    try {
      final records = <String, Map<String, dynamic>>{};
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
        records[_reportCache[i].id] = Map<String, dynamic>.from(dto.toJson());
      }

      await _databaseService.writeRecords(
          _databaseService.reportsBox, records);
    } catch (e) {
      throw Exception('Failed to save report data: $e');
    }
  }

  Future<void> clear() async {
    await _databaseService.reportsBox.clear();
    _reportCache.clear();
  }

  Future<void> syncFromApi({bool skipHydration = false}) async {
    if (!await _apiHelper.hasNetwork()) {
      return;
    }

    final result = await _syncHelper.fetch<Report>(
      endpoint: '/reports',
      fromJsonList: (jsonList) =>
          jsonList.map((json) => ReportDto.fromJson(json).toReport()).toList(),
    );

    if (result.success && result.data != null) {
      _reportCache = mergePulled(
        server: result.data!,
        local: _reportCache,
        idOf: (item) => item.id,
      );
      if (!skipHydration) {
        await save();
      }
    }
  }

  Future<void> _addPendingChange(
    String type,
    Map<String, dynamic> data,
    String endpoint,
  ) async {
    await Outbox.instance.enqueue(
      entity: 'report',
      type: type,
      endpoint: endpoint,
      data: data,
    );
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
        type,
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

}
