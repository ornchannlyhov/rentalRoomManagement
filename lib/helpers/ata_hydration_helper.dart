import 'package:receipts_v2/data/models/building.dart';
import 'package:receipts_v2/data/models/room.dart';
import 'package:receipts_v2/data/models/tenant.dart';
import 'package:receipts_v2/data/models/receipt.dart';
import 'package:receipts_v2/data/models/service.dart';
import 'package:logger/logger.dart';
import 'package:collection/collection.dart';

/// Helper class to rebuild object references after API sync
///
/// SQL databases store relationships as IDs, but the app needs
/// actual object references. This helper reconstructs those references.
class DataHydrationHelper {
  final Logger _logger = Logger();

  List<Building> buildings;
  List<Room> rooms;
  List<Tenant> tenants;
  List<Service> services;

  DataHydrationHelper({
    required this.buildings,
    required this.rooms,
    required this.tenants,
    required this.services,
  });

  /// Main method: Hydrate all relationships in correct order
  void hydrateAll({List<Receipt>? receipts}) {
    _logger.i('Starting data hydration...');

    // Order matters: dependencies first
    hydrateRoomsWithBuildings();
    hydrateBuildingsWithRooms();
    hydrateTenantsWithRooms();
    hydrateRoomsWithTenants();

    if (receipts != null) {
      hydrateReceipts(receipts);
    }

    _logger.i('Data hydration complete');
  }

  /// Step 1: Link rooms to their buildings
  void hydrateRoomsWithBuildings() {
    _logger.d('Hydrating rooms with buildings...');

    for (var room in rooms) {
      // If room has a building ID or a partial building object
      if (room.building?.id != null) {
        final buildingId = room.building!.id;

        // Find the full building object, or keep the existing partial/null one if not found
        final fullBuilding = buildings.firstWhereOrNull(
          (b) => b.id == buildingId,
        );

        // Assign the found building, or null if not found
        room.building = fullBuilding;
      } else {
        // If there's no building ID, ensure the building reference is null
        room.building = null;
      }
    }

    _logger.d('Hydrated ${rooms.length} rooms with buildings');
  }

  /// Step 2: Link buildings to their rooms (bidirectional)
  void hydrateBuildingsWithRooms() {
    _logger.d('Hydrating buildings with rooms...');

    for (var building in buildings) {
      // Find all rooms belonging to this building
      final buildingRooms =
          rooms.where((r) => r.building?.id == building.id).toList();

      // Clear and repopulate the rooms list
      building.rooms.clear();
      building.rooms.addAll(buildingRooms);

      // Ensure each room has proper building reference
      for (var room in buildingRooms) {
        room.building = building;
      }
    }

    _logger.d('Hydrated ${buildings.length} buildings with rooms');
  }

  /// Step 3: Link tenants to their rooms (and transitively to buildings)
  void hydrateTenantsWithRooms() {
    _logger.d('Hydrating tenants with rooms...');

    for (var tenant in tenants) {
      // If tenant has a room ID or a partial room object
      if (tenant.room?.id != null) {
        final roomId = tenant.room!.id;

        // Find the full room object (which already has building reference),
        // or keep the existing partial/null one if not found
        final fullRoom = rooms.firstWhereOrNull(
          (r) => r.id == roomId,
        );

        // Assign the found room, or null if not found
        tenant.room = fullRoom;
      } else {
        // If there's no room ID, ensure the room reference is null
        tenant.room = null;
      }
    }

    _logger.d('Hydrated ${tenants.length} tenants with rooms');
  }

  /// Step 4: Link rooms back to their tenants (bidirectional)
  void hydrateRoomsWithTenants() {
    _logger.d('Hydrating rooms with tenants...');

    for (var room in rooms) {
      // Find tenant assigned to this room, safely handling null room references
      final tenant = tenants.firstWhereOrNull(
        (t) => t.room?.id == room.id,
      );

      // Assign the found tenant, or null if not found
      room.tenant = tenant;
      // Ensure the tenant's room reference also points back to this room if assigned
      if (tenant != null && tenant.room?.id != room.id) {
        tenant.room =
            room; // This might be redundant if hydrateTenantsWithRooms ran first
      }
    }

    _logger.d('Hydrated rooms with their tenants');
  }

  /// Step 5: Hydrate receipts with full object graphs
  void hydrateReceipts(List<Receipt> receipts) {
    _logger.d('Hydrating receipts...');

    for (var receipt in receipts) {
      // Hydrate room reference
      if (receipt.room?.id != null) {
        final roomId = receipt.room!.id;

        // Find the full room object (already has building and tenant),
        // or keep the existing partial/null one if not found
        final fullRoom = rooms.firstWhereOrNull(
          (r) => r.id == roomId,
        );

        receipt.room = fullRoom;
      } else {
        receipt.room = null;
      }

      // Hydrate services references
      if (receipt.services.isNotEmpty) {
        final hydratedServices = <Service>[];

        for (var service in receipt.services) {
          final fullService = services.firstWhereOrNull(
            (s) => s.id == service.id,
          );
          if (fullService != null) {
            hydratedServices.add(fullService);
          } else {
            // If service not found in main list, keep the partial one from receipt
            hydratedServices.add(service);
          }
        }

        receipt.services = hydratedServices;
      }
    }

    _logger.d('Hydrated ${receipts.length} receipts');
  }

  /// Validate hydration results (optional debugging)
  Map<String, dynamic> validate({List<Receipt>? receipts}) {
    int roomsWithBuildings = rooms.where((r) => r.building != null).length;
    int buildingsWithRooms = buildings.where((b) => b.rooms.isNotEmpty).length;
    int tenantsWithRooms = tenants.where((t) => t.room != null).length;
    int receiptsWithRooms = receipts?.where((r) => r.room != null).length ?? 0;

    final results = {
      'total_rooms': rooms.length,
      'rooms_with_buildings': roomsWithBuildings,
      'total_buildings': buildings.length,
      'buildings_with_rooms': buildingsWithRooms,
      'total_tenants': tenants.length,
      'tenants_with_rooms': tenantsWithRooms,
      'total_receipts': receipts?.length ?? 0,
      'receipts_with_rooms': receiptsWithRooms,
    };

    _logger.i('Hydration validation: $results');
    return results;
  }
}
