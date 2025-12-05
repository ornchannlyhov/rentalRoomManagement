import 'package:flutter/foundation.dart';
import 'package:joul_v2/core/helpers/data_hydration_helper.dart';
import 'package:joul_v2/data/repositories/building_repository.dart';
import 'package:joul_v2/data/repositories/receipt_repository.dart';
import 'package:joul_v2/data/repositories/report_repository.dart';
import 'package:joul_v2/data/repositories/room_repository.dart';
import 'package:joul_v2/data/repositories/service_repository.dart';
import 'package:joul_v2/data/repositories/tenant_repository.dart';
import 'package:joul_v2/data/repositories/notification_repository.dart';
import 'package:joul_v2/data/repositories/payment_config_repository.dart';

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

  final NotificationRepository notificationRepository;
  final PaymentConfigRepository paymentConfigRepository;

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
    required this.notificationRepository,
    required this.paymentConfigRepository,
  });

  SyncStatus get syncStatus => _syncStatus;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get lastSyncError => _lastSyncError;

  Future<void> loadAll() async {
    try {
      if (kDebugMode) {
        print('📦 Loading all repositories in correct order...');
      }

      // STEP 1: Load independent entities (no dependencies)
      if (kDebugMode) {
        print('📦 Step 1: Loading buildings and services...');
      }
      await buildingRepository.loadWithoutHydration();
      await serviceRepository.loadWithoutHydration();

      // STEP 2: Load rooms (depends on buildings)
      if (kDebugMode) {
        print('📦 Step 2: Loading rooms...');
      }
      await roomRepository.loadWithoutHydration();

      // STEP 3: Load tenants (depends on rooms)
      if (kDebugMode) {
        print('📦 Step 3: Loading tenants...');
      }
      await tenantRepository.loadWithoutHydration();

      // STEP 4: Load receipts and reports WITHOUT hydration
      if (kDebugMode) {
        print('📦 Step 4: Loading receipts and reports...');
      }
      await receiptRepository.loadWithoutHydration();
      await reportRepository.loadWithoutHydration();

      // STEP 5: Hydrate ALL relationships centrally after everything is loaded
      if (kDebugMode) {
        print('📦 Step 5: Hydrating all relationships...');
      }
      await hydrateAllRelationships();

      // STEP 6: Update statuses that depend on hydrated data
      if (kDebugMode) {
        print('📦 Step 6: Updating derived statuses...');
      }
      await receiptRepository.updateStatusToOverdue();

      if (kDebugMode) {
        print('✅ All repositories loaded and hydrated successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading repositories: $e');
      }
      rethrow;
    }
  }

  Future<bool> syncAll({bool force = false}) async {
    if (_syncStatus == SyncStatus.syncing && !force) {
      return false;
    }

    _syncStatus = SyncStatus.syncing;
    final errors = <String>[];

    try {
      // Sync ALL independently - don't let one failure stop others
      // Use try-catch for each to isolate failures
      final results = await Future.wait<MapEntry<String, bool>>([
        _safeSyncRepo('buildings',
            () => buildingRepository.syncFromApi(skipHydration: true)),
        _safeSyncRepo('services',
            () => serviceRepository.syncFromApi(skipHydration: true)),
        _safeSyncRepo(
            'rooms', () => roomRepository.syncFromApi(skipHydration: true)),
        _safeSyncRepo(
            'tenants', () => tenantRepository.syncFromApi(skipHydration: true)),
        _safeSyncRepo('receipts',
            () => receiptRepository.syncFromApi(skipHydration: true)),
        _safeSyncRepo(
            'reports', () => reportRepository.syncFromApi(skipHydration: true)),
      ]);

      // Collect any errors
      for (final result in results) {
        if (!result.value) {
          errors.add(result.key);
        }
      }

      // Only hydrate and save if at least some syncs succeeded
      if (errors.length < results.length) {
        // Rebuild object references after API sync
        await hydrateAllRelationships();

        // Save hydrated data back to storage
        await saveAll();
      }

      _lastSyncTime = DateTime.now();

      if (errors.isEmpty) {
        _syncStatus = SyncStatus.success;
        _lastSyncError = null;
      } else if (errors.length == results.length) {
        // All failed
        _syncStatus = SyncStatus.error;
        _lastSyncError = 'All repositories failed to sync';
      } else {
        // Partial success
        _syncStatus = SyncStatus.success;
        _lastSyncError = 'Some repositories failed: ${errors.join(", ")}';
        if (kDebugMode) {
          print('⚠️ Partial sync: ${errors.join(", ")} failed');
        }
      }

      return errors.isEmpty;
    } catch (e) {
      _syncStatus = SyncStatus.error;
      _lastSyncError = e.toString();
      if (kDebugMode) {
        print('❌ Sync error: $e');
      }
      return false;
    }
  }

  /// Safely sync a repository and return success/failure
  Future<MapEntry<String, bool>> _safeSyncRepo(
      String name, Future<void> Function() syncFn) async {
    try {
      await syncFn();
      return MapEntry(name, true);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to sync $name: $e');
      }
      return MapEntry(name, false);
    }
  }

  /// Sync only pending changes without full sync
  Future<bool> syncPendingChanges() async {
    // Sync ALL independently - don't let one failure stop others
    final results = await Future.wait<MapEntry<String, bool>>([
      _safeSyncRepo('buildings',
          () => buildingRepository.syncFromApi(skipHydration: true)),
      _safeSyncRepo(
          'services', () => serviceRepository.syncFromApi(skipHydration: true)),
      _safeSyncRepo(
          'rooms', () => roomRepository.syncFromApi(skipHydration: true)),
      _safeSyncRepo(
          'tenants', () => tenantRepository.syncFromApi(skipHydration: true)),
      _safeSyncRepo(
          'receipts', () => receiptRepository.syncFromApi(skipHydration: true)),
      _safeSyncRepo(
          'reports', () => reportRepository.syncFromApi(skipHydration: true)),
    ]);

    final successCount = results.where((r) => r.value).length;

    // Only hydrate and save if at least some syncs succeeded
    if (successCount > 0) {
      try {
        await hydrateAllRelationships();
        await saveAll();
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Error during hydration/save: $e');
        }
      }
    }

    return successCount == results.length;
  }

  Future<void> hydrateAllRelationships() async {
    try {
      final buildings = buildingRepository.getAllBuildings();
      final rooms = roomRepository.getAllRooms();
      final tenants = tenantRepository.getAllTenants();
      final services = serviceRepository.getAllServices();
      final receipts = receiptRepository.getAllReceipts();
      final reports = reportRepository.getAllReports();

      if (kDebugMode) {
        print('🔗 Hydrating relationships:');
        print('   Buildings: ${buildings.length}');
        print('   Rooms: ${rooms.length}');
        print('   Tenants: ${tenants.length}');
        print('   Services: ${services.length}');
        print('   Receipts: ${receipts.length}');
        print('   Reports: ${reports.length}');
      }

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

      if (kDebugMode) {
        print('✅ All relationships hydrated');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error hydrating relationships: $e');
      }
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
        notificationRepository.clear(),
        paymentConfigRepository.clear(),
      ]);

      _syncStatus = SyncStatus.idle;
      _lastSyncTime = null;
      _lastSyncError = null;
    } catch (e) {
      rethrow;
    }
  }
}
