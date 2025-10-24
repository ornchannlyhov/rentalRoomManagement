import 'package:receipts_v2/data/models/building.dart';
import 'package:receipts_v2/data/models/room.dart';
import 'package:receipts_v2/data/models/tenant.dart';
import 'package:receipts_v2/data/models/receipt.dart';
import 'package:receipts_v2/data/models/service.dart';
import 'package:receipts_v2/data/models/report.dart';
import 'package:collection/collection.dart';

/// Helper class to rebuild object references after API sync
///
/// SQL databases store relationships as IDs, but the app needs
/// actual object references. This helper reconstructs those references.
class DataHydrationHelper {
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
  void hydrateAll({
    List<Receipt>? receipts,
    List<Report>? reports,
  }) {
    // Order matters: dependencies first
    hydrateRoomsWithBuildings();
    hydrateBuildingsWithRooms();
    hydrateTenantsWithRooms();
    hydrateRoomsWithTenants();

    if (receipts != null && receipts.isNotEmpty) {
      hydrateReceipts(receipts);
    }

    if (reports != null && reports.isNotEmpty) {
      hydrateReports(reports);
    }
  }

  /// Step 1: Link rooms to their buildings
  void hydrateRoomsWithBuildings() {
    for (var room in rooms) {
      String? buildingId = room.building?.id;

      if (buildingId != null && buildingId.isNotEmpty) {
        final fullBuilding = buildings.firstWhereOrNull(
          (b) => b.id == buildingId,
        );

        if (fullBuilding != null) {
          room.building = fullBuilding;
        }
      } else {
        room.building = null;
      }
    }
  }

  /// Step 2: Link buildings to their rooms (bidirectional)
  void hydrateBuildingsWithRooms() {
    for (var building in buildings) {
      final buildingRooms =
          rooms.where((r) => r.building?.id == building.id).toList();

      building.rooms.clear();
      building.rooms.addAll(buildingRooms);

      for (var room in buildingRooms) {
        room.building = building;
      }
    }
  }

  /// Step 3: Link tenants to their rooms (and transitively to buildings)
  void hydrateTenantsWithRooms() {
    for (var tenant in tenants) {
      if (tenant.room?.id != null) {
        final roomId = tenant.room!.id;

        final fullRoom = rooms.firstWhereOrNull(
          (r) => r.id == roomId,
        );

        if (fullRoom != null) {
          tenant.room = fullRoom;
        } else {
          tenant.room = null;
        }
      } else {
        tenant.room = null;
      }
    }
  }

  /// Step 4: Link rooms back to their tenants (bidirectional)
  void hydrateRoomsWithTenants() {
    for (var room in rooms) {
      final tenant = tenants.firstWhereOrNull(
        (t) => t.room?.id == room.id,
      );

      room.tenant = tenant;

      if (tenant != null && tenant.room?.id != room.id) {
        tenant.room = room;
      }
    }
  }

  /// Step 5: Hydrate receipts with full object graphs
  void hydrateReceipts(List<Receipt> receipts) {
    for (var receipt in receipts) {
      // FIX: Look up the fully hydrated room from the master list
      // This room should already have building AND tenant attached
      if (receipt.room?.id != null) {
        final roomId = receipt.room!.id;

        final fullRoom = rooms.firstWhereOrNull(
          (r) => r.id == roomId,
        );

        if (fullRoom != null) {
          // Assign the FULLY hydrated room (with building and tenant)
          receipt.room = fullRoom;

          // DEBUG: Verify tenant is present
          if (fullRoom.tenant == null) {
            print(
                'WARNING: Room ${fullRoom.roomNumber} has no tenant after hydration');
          }
        } else {
          receipt.room = null;
        }
      } else {
        receipt.room = null;
      }

      // Hydrate services using serviceIds
      if (receipt.serviceIds.isNotEmpty) {
        final hydratedServices = <Service>[];

        for (var serviceId in receipt.serviceIds) {
          final fullService = services.firstWhereOrNull(
            (s) => s.id == serviceId,
          );
          if (fullService != null) {
            hydratedServices.add(fullService);
          }
        }

        receipt.services = hydratedServices;
      }
    }
  }

  /// Step 6: Hydrate reports with full object graphs
  void hydrateReports(List<Report> reports) {
    for (var report in reports) {
      // Hydrate tenant reference
      if (report.tenant?.id != null) {
        final tenantId = report.tenant!.id;

        final fullTenant = tenants.firstWhereOrNull(
          (t) => t.id == tenantId,
        );

        if (fullTenant != null) {
          report.tenant = fullTenant;
        } else {
          report.tenant = null;
        }
      }

      // Hydrate room reference
      if (report.room?.id != null) {
        final roomId = report.room!.id;

        final fullRoom = rooms.firstWhereOrNull(
          (r) => r.id == roomId,
        );

        if (fullRoom != null) {
          report.room = fullRoom;
        } else {
          report.room = null;
        }
      }
    }
  }
}
