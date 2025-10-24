import 'package:receipts_v2/data/repositories/building_repository.dart';
import 'package:receipts_v2/data/repositories/report_repository.dart';
import 'package:receipts_v2/data/repositories/room_repository.dart';
import 'package:receipts_v2/data/repositories/tenant_repository.dart';
import 'package:receipts_v2/data/repositories/receipt_repository.dart';
import 'package:receipts_v2/data/repositories/service_repository.dart';
import 'package:receipts_v2/helpers/ata_hydration_helper.dart';

enum SyncStatus {
  idle,
  syncing,
  success,
  error,
  offline,
}

/// Central manager for all repositories with offline/online sync support
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

  /// Load all data from secure storage on app startup
  Future<void> loadAll() async {
    try {
      // Load in dependency order
      await buildingRepository.load();
      await serviceRepository.load();
      await roomRepository.load();
      await tenantRepository.load();
      await receiptRepository.load();
      await reportRepository.load();

      // Hydrate relationships after loading
      await hydrateAllRelationships();

      // Save back the hydrated data
      await saveAll();
    } catch (e) {
      rethrow;
    }
  }

  /// Sync all data from API with proper error handling
  Future<bool> syncAll({bool force = false}) async {
    if (_syncStatus == SyncStatus.syncing && !force) {
      return false;
    }

    _syncStatus = SyncStatus.syncing;

    try {
      // Sync in dependency order with skipHydration=true
      await buildingRepository.syncFromApi(skipHydration: true);
      await serviceRepository.syncFromApi(skipHydration: true);
      await roomRepository.syncFromApi(skipHydration: true);
      await tenantRepository.syncFromApi(skipHydration: true);
      await receiptRepository.syncFromApi(skipHydration: true);
      await reportRepository.syncFromApi(skipHydration: true);

      // Rebuild object references after API sync
      await hydrateAllRelationships();

      // Save hydrated data back to storage
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
      // Each repository should have its own pending changes sync
      await buildingRepository.syncFromApi(skipHydration: true);
      await serviceRepository.syncFromApi(skipHydration: true);
      await roomRepository.syncFromApi(skipHydration: true);
      await tenantRepository.syncFromApi(skipHydration: true);
      await receiptRepository.syncFromApi(skipHydration: true);
      await reportRepository.syncFromApi(skipHydration: true);

      await hydrateAllRelationships();
      await saveAll();

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Rebuild all object relationships
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

  /// Save all data to secure storage
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
      await buildingRepository.clear();
      await serviceRepository.clear();
      await roomRepository.clear();
      await tenantRepository.clear();
      await receiptRepository.clear();
      await reportRepository.clear();

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
    int count = 0;
    count += buildingRepository.getPendingChangesCount();
    count += roomRepository.getPendingChangesCount();
    count += serviceRepository.getPendingChangesCount();
    count += tenantRepository.getPendingChangesCount();
    count += receiptRepository.getPendingChangesCount();
    count += reportRepository.getPendingChangesCount();
    return count;
  }

  /// Get detailed pending changes summary
  Map<String, int> getPendingChangesSummary() {
    return {
      'buildings': buildingRepository.getPendingChangesCount(),
      'rooms': roomRepository.getPendingChangesCount(),
      'services': serviceRepository.getPendingChangesCount(),
      'tenants': tenantRepository.getPendingChangesCount(),
      'receipts': receiptRepository.getPendingChangesCount(),
      'reports': reportRepository.getPendingChangesCount(),
      'total': getPendingChangesCount(),
    };
  }

  /// Get summary of all data
  Map<String, int> getDataSummary() {
    return {
      'buildings': buildingRepository.getAllBuildings().length,
      'rooms': roomRepository.getAllRooms().length,
      'tenants': tenantRepository.getAllTenants().length,
      'receipts': receiptRepository.getAllReceipts().length,
      'services': serviceRepository.getAllServices().length,
      'reports': reportRepository.getAllReports().length,
    };
  }

  /// Validate all relationships (for debugging)
  Map<String, dynamic> validateRelationships() {
    final buildings = buildingRepository.getAllBuildings();
    final rooms = roomRepository.getAllRooms();
    final tenants = tenantRepository.getAllTenants();
    final receipts = receiptRepository.getAllReceipts();
    final reports = reportRepository.getAllReports();

    return {
      'total_buildings': buildings.length,
      'total_rooms': rooms.length,
      'rooms_with_buildings': rooms.where((r) => r.building != null).length,
      'rooms_without_buildings': rooms.where((r) => r.building == null).length,
      'total_tenants': tenants.length,
      'tenants_with_rooms': tenants.where((t) => t.room != null).length,
      'total_receipts': receipts.length,
      'receipts_with_rooms': receipts.where((r) => r.room != null).length,
      'receipts_with_buildings':
          receipts.where((r) => r.room?.building != null).length,
      'receipts_without_buildings': receipts
          .where((r) => r.room != null && r.room?.building == null)
          .length,
      'receipts_with_services':
          receipts.where((r) => r.services.isNotEmpty).length,
      'total_reports': reports.length,
      'reports_with_tenants': reports.where((r) => r.tenant != null).length,
      'reports_with_rooms': reports.where((r) => r.room != null).length,
    };
  }
}
