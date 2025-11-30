import 'package:flutter/material.dart';
import 'package:joul_v2/data/models/report.dart';
import 'package:joul_v2/data/models/enum/report_status.dart';
import 'package:joul_v2/data/repositories/report_repository.dart';
import 'package:joul_v2/core/helpers/asyn_value.dart';
import 'package:joul_v2/core/helpers/repository_manager.dart';

class ReportProvider with ChangeNotifier {
  final ReportRepository _reportRepository;
  final RepositoryManager? _repositoryManager;

  AsyncValue<List<Report>> _reportsState = const AsyncValue.loading();

  ReportProvider(
    this._reportRepository, {
    RepositoryManager? repositoryManager,
  }) : _repositoryManager = repositoryManager;

  AsyncValue<List<Report>> get reportsState => _reportsState;

  // Convenience getters
  List<Report> get reports => _reportsState.bestData ?? [];
  bool get isLoading => _reportsState.isLoading;
  bool get hasError => _reportsState.hasError;
  Object? get error => _reportsState.error;

  Future<void> load() async {
    try {
      final reports = _reportRepository.getAllReports();
      _reportsState = AsyncValue.success(reports);
    } catch (e) {
      _reportsState = AsyncValue.error(e, _reportsState.bestData);
    } finally {
      notifyListeners();
    }
  }

  /// Sync reports from API
  Future<void> syncReports() async {
    _reportsState = AsyncValue.loading(_reportsState.bestData);
    notifyListeners();

    try {
      await _reportRepository.syncFromApi();

      // Hydrate relationships after sync
      if (_repositoryManager != null) {
        await _repositoryManager.hydrateAllRelationships();
        await _repositoryManager.saveAll();
      }

      await load();
    } catch (e) {
      _reportsState = AsyncValue.error(e, _reportsState.bestData);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateReportStatus(String reportId, String status) async {
    _reportsState = AsyncValue.loading(_reportsState.bestData);
    notifyListeners();

    try {
      await _reportRepository.updateReportStatus(reportId, status);

      if (_repositoryManager != null) {
        await _repositoryManager.hydrateAllRelationships();
        await _repositoryManager.saveAll();
      }

      await load();
    } catch (e) {
      _reportsState = AsyncValue.error(e, _reportsState.bestData);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteReport(String reportId) async {
    _reportsState = AsyncValue.loading(_reportsState.bestData);
    notifyListeners();

    try {
      await _reportRepository.deleteReport(reportId);

      if (_repositoryManager != null) {
        await _repositoryManager.hydrateAllRelationships();
        await _repositoryManager.saveAll();
      }

      await load();
    } catch (e) {
      _reportsState = AsyncValue.error(e, _reportsState.bestData);
      notifyListeners();
      rethrow;
    }
  }

  List<Report> getReportsByStatus(ReportStatus status) {
    return _reportRepository.getReportsByStatus(status);
  }

  List<Report> getReportsByBuilding(String buildingId) {
    return _reportRepository.getReportsByBuilding(buildingId);
  }

}