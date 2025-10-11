import 'package:receipts_v2/helpers/ata_hydration_helper.dart';
import 'package:receipts_v2/data/repositories/buidling_repository.dart';
import 'package:receipts_v2/data/repositories/room_repository.dart';
import 'package:receipts_v2/data/repositories/tenant_repository.dart';
import 'package:receipts_v2/data/repositories/receipt_repository.dart';
import 'package:receipts_v2/data/repositories/service_repository.dart';
import 'package:logger/logger.dart';

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

  final Logger _logger = Logger();

  RepositoryManager({
    required this.buildingRepository,
    required this.roomRepository,
    required this.tenantRepository,
    required this.receiptRepository,
    required this.serviceRepository,
  });

  /// Load all data from secure storage on app startup
  Future<void> loadAll() async {
    _logger.i('Loading all data from storage...');

    try {
      // Load in dependency order
      await buildingRepository.load();
      await serviceRepository.load();
      await roomRepository.load();
      await tenantRepository.load();
      await receiptRepository.load();

      // Hydrate relationships after loading
      await hydrateAllRelationships();

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
      await buildingRepository.syncFromApi();
      await serviceRepository.syncFromApi();
      await roomRepository.syncFromApi();
      await tenantRepository.syncFromApi();
      await receiptRepository.syncFromApi();

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

    final hydrator = DataHydrationHelper(
      buildings: buildingRepository.getAllBuildings(),
      rooms: roomRepository.getAllRooms(),
      tenants: tenantRepository.getAllTenants(),
      services: serviceRepository.getAllServices(),
    );

    // Hydrate everything including receipts
    hydrator.hydrateAll(
      receipts: receiptRepository.getAllReceipts(),
    );

    // Optional: Validate hydration results
    if (Logger.level == Level.debug) {
      hydrator.validate(receipts: receiptRepository.getAllReceipts());
    }

    _logger.i('All relationships hydrated');
  }

  /// Save all data to secure storage
  Future<void> saveAll() async {
    _logger.i('Saving all data to storage...');

    try {
      await Future.wait([
        buildingRepository.save(),
        serviceRepository.save(),
        roomRepository.save(),
        tenantRepository.save(),
        receiptRepository.save(),
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
    };
  }
}
