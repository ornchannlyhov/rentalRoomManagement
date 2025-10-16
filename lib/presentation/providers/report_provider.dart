import 'package:flutter/material.dart';
import 'package:receipts_v2/helpers/asyn_value.dart';
import 'package:receipts_v2/data/models/report.dart';
import 'package:receipts_v2/data/models/enum/report_status.dart';
import 'package:receipts_v2/data/models/enum/report_priority.dart';
import 'package:receipts_v2/data/repositories/report_repository.dart';

class ReportProvider extends ChangeNotifier {
  final ReportRepository _repository;

  ReportProvider(this._repository);

  AsyncValue<List<Report>> _reports = const AsyncValue.loading();
  AsyncValue<List<Report>> get reports => _reports;

  String? get errorMessage {
    return _reports.when(
      loading: () => null,
      success: (_) => null,
      error: (error) => error.toString(),
    );
  }

  bool get isLoading => _reports.isLoading;
  bool get hasData => _reports.hasData;
  bool get hasError => _reports.hasError;

  Future<void> load() async {
    _reports = const AsyncValue.loading();
    notifyListeners();

    try {
      await _repository.load();
      final data = _repository.getAllReports();
      _reports = AsyncValue.success(data);
    } catch (e) {
      _reports = AsyncValue.error(e);
    }
    notifyListeners();
  }

  Future<void> syncFromApi() async {
    _reports = const AsyncValue.loading();
    notifyListeners();

    try {
      await _repository.syncFromApi();
      final data = _repository.getAllReports();
      _reports = AsyncValue.success(data);
    } catch (e) {
      _reports = AsyncValue.error(e);
    }
    notifyListeners();
  }

  Future<Report> createReport(Report report) async {
    try {
      final createdReport = await _repository.createReport(report);
      await load();
      return createdReport;
    } catch (e) {
      _reports = AsyncValue.error(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<Report> updateReport(Report report) async {
    try {
      final updatedReport = await _repository.updateReport(report);
      await load();
      return updatedReport;
    } catch (e) {
      _reports = AsyncValue.error(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateReportStatus(String reportId, ReportStatus status) async {
    try {
      await _repository.updateReportStatus(reportId, status.toApiString());
      await load();
    } catch (e) {
      _reports = AsyncValue.error(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteReport(String reportId) async {
    try {
      await _repository.deleteReport(reportId);
      await load();
    } catch (e) {
      _reports = AsyncValue.error(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> restoreReport(int restoreIndex, Report report) async {
    try {
      await _repository.restoreReport(restoreIndex, report);
      final data = _repository.getAllReports();
      _reports = AsyncValue.success(data);
      notifyListeners();
    } catch (e) {
      _reports = AsyncValue.error(e);
      notifyListeners();
      rethrow;
    }
  }

  // Filter methods
  List<Report> getReportsByTenant(String tenantId) {
    if (_reports.hasData) {
      return _repository.getReportsByTenant(tenantId);
    }
    return [];
  }

  List<Report> getReportsByRoom(String roomId) {
    if (_reports.hasData) {
      return _repository.getReportsByRoom(roomId);
    }
    return [];
  }

  List<Report> getReportsByStatus(ReportStatus status) {
    if (_reports.hasData) {
      return _repository.getReportsByStatus(status);
    }
    return [];
  }

  List<Report> getReportsByPriority(ReportPriority priority) {
    if (_reports.hasData) {
      return _repository.getReportsByPriority(priority);
    }
    return [];
  }

  List<Report> getReportsByBuilding(String buildingId) {
    if (_reports.hasData) {
      return _repository.getReportsByBuilding(buildingId);
    }
    return [];
  }

  Report? getReportById(String reportId) {
    if (_reports.hasData) {
      return _repository.getReportById(reportId);
    }
    return null;
  }

  // Statistics
  Map<ReportStatus, int> getReportCountsByStatus() {
    if (_reports.hasData) {
      return _repository.getReportCountsByStatus();
    }
    return {
      for (var status in ReportStatus.values) status: 0,
    };
  }

  Map<ReportPriority, int> getReportCountsByPriority() {
    if (_reports.hasData) {
      return _repository.getReportCountsByPriority();
    }
    return {
      for (var priority in ReportPriority.values) priority: 0,
    };
  }

  int get reportCount {
    if (_reports.hasData) {
      return _reports.data!.length;
    }
    return 0;
  }

  int get pendingReportCount {
    if (_reports.hasData) {
      return _repository.getReportsByStatus(ReportStatus.pending).length;
    }
    return 0;
  }

  int get urgentReportCount {
    if (_reports.hasData) {
      return _repository.getReportsByPriority(ReportPriority.urgent).length;
    }
    return 0;
  }

  Future<void> refresh() async {
    await syncFromApi();
  }

  void clearError() {
    if (_reports.hasError) {
      _reports = AsyncValue.success(_repository.getAllReports());
      notifyListeners();
    }
  }

  // Convenience methods for quick status updates
  Future<void> markAsInProgress(String reportId) async {
    await updateReportStatus(reportId, ReportStatus.inProgress);
  }

  Future<void> markAsResolved(String reportId) async {
    await updateReportStatus(reportId, ReportStatus.resolved);
  }

  Future<void> markAsClosed(String reportId) async {
    await updateReportStatus(reportId, ReportStatus.closed);
  }
}
