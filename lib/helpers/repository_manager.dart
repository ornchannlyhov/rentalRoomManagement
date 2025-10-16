import 'package:receipts_v2/data/repositories/building_repository.dart';
import 'package:receipts_v2/data/repositories/report_repository.dart';
import 'package:receipts_v2/data/repositories/room_repository.dart';
import 'package:receipts_v2/data/repositories/tenant_repository.dart';
import 'package:receipts_v2/data/repositories/receipt_repository.dart';
import 'package:receipts_v2/data/repositories/service_repository.dart';
import 'package:logger/logger.dart';
import 'package:receipts_v2/helpers/ata_hydration_helper.dart';

/// Central manager for all repositories
///
/// Handles:
/// - Loading all data from secure storage
/// - Syncing all data from API
/// - Hydrating object references after sync
/// - Coordinating saves across repositories
class RepositoryManager {
  final BuildingRepository buildingRepository;
  final RoomRepository roomRepository;
  final TenantRepository tenantRepository;
  final ReceiptRepository receiptRepository;
  final ServiceRepository serviceRepository;
  final ReportRepository reportRepository;

  final Logger _logger = Logger();

  RepositoryManager({
    required this.buildingRepository,
    required this.roomRepository,
    required this.tenantRepository,
    required this.receiptRepository,
    required this.serviceRepository,
    required this.reportRepository,
  });

  /// Load all data from secure storage on app startup
  Future<void> loadAll() async {
    _logger.i('Loading all data from storage...');

    try {
      // Load in dependency order - MUST load buildings and services first
      await buildingRepository.load();
      await serviceRepository.load();
      await roomRepository.load();
      await tenantRepository.load();
      await receiptRepository.load();
      await reportRepository.load();

      _logger.i('Raw data loaded from storage');

      // Hydrate relationships after loading - THIS IS CRITICAL
      await hydrateAllRelationships();

      // Save back the hydrated data to ensure relationships persist
      await saveAll();

      _logger.i('All data loaded and hydrated successfully');
    } catch (e) {
      _logger.e('Error loading data: $e');
      rethrow;
    }
  }

  /// Sync all data from API and rebuild object relationships
  Future<void> syncAll() async {
    _logger.i('Syncing all data from API...');

    try {
      // Sync in dependency order (buildings before rooms, etc.)
      // Pass skipHydration=true to prevent individual saves during sync
      await buildingRepository.syncFromApi(skipHydration: true);
      await serviceRepository.syncFromApi(skipHydration: true);
      await roomRepository.syncFromApi(skipHydration: true);
      await tenantRepository.syncFromApi(skipHydration: true);
      await receiptRepository.syncFromApi(skipHydration: true);
      await reportRepository.syncFromApi(skipHydration: true);

      _logger.i('Raw data synced from API');

      // Critical: Rebuild object references after API sync
      await hydrateAllRelationships();

      // Save hydrated data back to storage
      await saveAll();

      _logger.i('All data synced and hydrated successfully');
    } catch (e) {
      _logger.e('Error syncing data: $e');
      // Don't rethrow - we have cached data as fallback
    }
  }

  /// Rebuild all object relationships
  Future<void> hydrateAllRelationships() async {
    _logger.i('Hydrating all relationships...');

    try {
      // Get all data from repositories
      final buildings = buildingRepository.getAllBuildings();
      final rooms = roomRepository.getAllRooms();
      final tenants = tenantRepository.getAllTenants();
      final services = serviceRepository.getAllServices();
      final receipts = receiptRepository.getAllReceipts();
      final reports = reportRepository.getAllReports();

      _logger.d(
          'Retrieved data: ${buildings.length} buildings, ${rooms.length} rooms, ${tenants.length} tenants, ${services.length} services, ${receipts.length} receipts, ${reports.length} reports');

      // Create hydrator
      final hydrator = DataHydrationHelper(
        buildings: buildings,
        rooms: rooms,
        tenants: tenants,
        services: services,
      );

      // Hydrate everything including receipts and reports
      hydrator.hydrateAll(
        receipts: receipts,
        reports: reports,
      );

      // Validate hydration results in debug mode
      final validation = hydrator.validate(
        receipts: receipts,
        reports: reports,
      );
      _logger.i('Hydration complete: $validation');

      // Check for issues
      if (validation['receipts_with_buildings'] != null &&
          validation['receipts_with_rooms'] != null &&
          validation['receipts_with_buildings'] <
              validation['receipts_with_rooms']) {
        _logger.w('WARNING: Some receipts have rooms but no buildings!');
        _logger.w('Receipts with rooms: ${validation['receipts_with_rooms']}');
        _logger.w(
            'Receipts with buildings: ${validation['receipts_with_buildings']}');
      }
    } catch (e) {
      _logger.e('Error during hydration: $e');
      rethrow;
    }
  }

  /// Save all data to secure storage
  Future<void> saveAll() async {
    _logger.i('Saving all data to storage...');

    try {
      // Save all repositories in parallel
      await Future.wait([
        buildingRepository.save(),
        serviceRepository.save(),
        roomRepository.save(),
        tenantRepository.save(),
        receiptRepository.save(),
        reportRepository.save(),
      ]);

      _logger.i('All data saved successfully');
    } catch (e) {
      _logger.e('Error saving data: $e');
      rethrow;
    }
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

    int roomsWithBuildings = rooms.where((r) => r.building != null).length;
    int roomsWithoutBuildings = rooms.where((r) => r.building == null).length;
    int tenantsWithRooms = tenants.where((t) => t.room != null).length;
    int receiptsWithRooms = receipts.where((r) => r.room != null).length;
    int receiptsWithBuildings =
        receipts.where((r) => r.room?.building != null).length;
    int receiptsWithServices =
        receipts.where((r) => r.services.isNotEmpty).length;
    int reportsWithTenants = reports.where((r) => r.tenant != null).length;
    int reportsWithRooms = reports.where((r) => r.room != null).length;

    return {
      'total_buildings': buildings.length,
      'total_rooms': rooms.length,
      'rooms_with_buildings': roomsWithBuildings,
      'rooms_without_buildings': roomsWithoutBuildings,
      'total_tenants': tenants.length,
      'tenants_with_rooms': tenantsWithRooms,
      'total_receipts': receipts.length,
      'receipts_with_rooms': receiptsWithRooms,
      'receipts_with_buildings': receiptsWithBuildings,
      'receipts_without_buildings': receiptsWithRooms - receiptsWithBuildings,
      'receipts_with_services': receiptsWithServices,
      'total_reports': reports.length,
      'reports_with_tenants': reportsWithTenants,
      'reports_with_rooms': reportsWithRooms,
    };
  }
}
