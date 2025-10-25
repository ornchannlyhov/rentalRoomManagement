import 'package:receipts_v2/data/repositories/building_repository.dart';
import 'package:receipts_v2/data/repositories/report_repository.dart';
import 'package:receipts_v2/data/repositories/room_repository.dart';
import 'package:receipts_v2/data/repositories/tenant_repository.dart';
import 'package:receipts_v2/data/repositories/receipt_repository.dart';
import 'package:receipts_v2/data/repositories/service_repository.dart';
import 'package:receipts_v2/helpers/data_hydration_helper.dart';

enum SyncStatus {
  idle,
  syncing,
  success,
  error,
  offline,
}

class RepositoryManager {
  final BuildingRepository buildingRepository;
  final RoomRepository roomRepository;
  final TenantRepository tenantRepository;
  final ReceiptRepository receiptRepository;
  final ServiceRepository serviceRepository;
  final ReportRepository reportRepository;

  SyncStatus _syncStatus = SyncStatus.idle;
  DateTime? _lastSyncTime;
  String? _lastSyncError;

  RepositoryManager({
    required this.buildingRepository,
    required this.roomRepository,
    required this.tenantRepository,
    required this.receiptRepository,
    required this.serviceRepository,
    required this.reportRepository,
  });

  SyncStatus get syncStatus => _syncStatus;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get lastSyncError => _lastSyncError;

  Future<void> loadAll() async {
    try {
      // Load ALL repositories in parallel
      await Future.wait([
        buildingRepository.load(),
        serviceRepository.load(),
        roomRepository.load(),
        tenantRepository.load(),
        receiptRepository.load(),
        reportRepository.load(),
      ]);

      // Hydrate relationships after loading
      await hydrateAllRelationships();

    } catch (e) {
      rethrow;
    }
  }

  Future<bool> syncAll({bool force = false}) async {
    if (_syncStatus == SyncStatus.syncing && !force) {
      return false;
    }

    _syncStatus = SyncStatus.syncing;

    try {
      // Sync ALL in parallel with skipHydration=true
      await Future.wait([
        buildingRepository.syncFromApi(skipHydration: true),
        serviceRepository.syncFromApi(skipHydration: true),
        roomRepository.syncFromApi(skipHydration: true),
        tenantRepository.syncFromApi(skipHydration: true),
        receiptRepository.syncFromApi(skipHydration: true),
        reportRepository.syncFromApi(skipHydration: true),
      ]);

      // Rebuild object references after API sync
      await hydrateAllRelationships();

      // Save hydrated data back to storage (in parallel)
      await saveAll();

      _lastSyncTime = DateTime.now();
      _syncStatus = SyncStatus.success;
      _lastSyncError = null;

      return true;
    } catch (e) {
      _syncStatus = SyncStatus.error;
      _lastSyncError = e.toString();
      return false;
    }
  }

  /// Sync only pending changes without full sync
  Future<bool> syncPendingChanges() async {
    try {
      // Sync in parallel
      await Future.wait([
        buildingRepository.syncFromApi(skipHydration: true),
        serviceRepository.syncFromApi(skipHydration: true),
        roomRepository.syncFromApi(skipHydration: true),
        tenantRepository.syncFromApi(skipHydration: true),
        receiptRepository.syncFromApi(skipHydration: true),
        reportRepository.syncFromApi(skipHydration: true),
      ]);

      await hydrateAllRelationships();
      await saveAll();

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> hydrateAllRelationships() async {
    try {
      final buildings = buildingRepository.getAllBuildings();
      final rooms = roomRepository.getAllRooms();
      final tenants = tenantRepository.getAllTenants();
      final services = serviceRepository.getAllServices();
      final receipts = receiptRepository.getAllReceipts();
      final reports = reportRepository.getAllReports();

      final hydrator = DataHydrationHelper(
        buildings: buildings,
        rooms: rooms,
        tenants: tenants,
        services: services,
      );

      hydrator.hydrateAll(
        receipts: receipts,
        reports: reports,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveAll() async {
    try {
      await Future.wait([
        buildingRepository.save(),
        serviceRepository.save(),
        roomRepository.save(),
        tenantRepository.save(),
        receiptRepository.save(),
        reportRepository.save(),
      ]);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> clearAll() async {
    try {
      // Clear in parallel
      await Future.wait([
        buildingRepository.clear(),
        serviceRepository.clear(),
        roomRepository.clear(),
        tenantRepository.clear(),
        receiptRepository.clear(),
        reportRepository.clear(),
      ]);

      _syncStatus = SyncStatus.idle;
      _lastSyncTime = null;
      _lastSyncError = null;
    } catch (e) {
      rethrow;
    }
  }

  /// Check if any repository has pending changes
  bool hasPendingChanges() {
    return buildingRepository.hasPendingChanges() ||
        roomRepository.hasPendingChanges() ||
        serviceRepository.hasPendingChanges() ||
        tenantRepository.hasPendingChanges() ||
        receiptRepository.hasPendingChanges() ||
        reportRepository.hasPendingChanges();
  }

  /// Get count of pending changes across all repositories
  int getPendingChangesCount() {
    return buildingRepository.getPendingChangesCount() +
        roomRepository.getPendingChangesCount() +
        serviceRepository.getPendingChangesCount() +
        tenantRepository.getPendingChangesCount() +
        receiptRepository.getPendingChangesCount() +
        reportRepository.getPendingChangesCount();
  }

}
