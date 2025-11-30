import 'package:joul_v2/data/models/building.dart';
import 'package:joul_v2/data/models/receipt.dart';
import 'package:joul_v2/data/models/report.dart';
import 'package:joul_v2/data/models/room.dart';
import 'package:joul_v2/data/models/service.dart';
import 'package:joul_v2/data/models/tenant.dart';

/// Helper class to rebuild object references after API sync
class DataHydrationHelper {
  // Raw lists
  List<Building> buildings;
  List<Room> rooms;
  List<Tenant> tenants;
  List<Service> services;

  // O(1) lookup maps - computed once, reused many times
  late final Map<String, Building> _buildingMap;
  late final Map<String, Room> _roomMap;
  late final Map<String, Tenant> _tenantMap;
  late final Map<String, Service> _serviceMap;

  DataHydrationHelper({
    required this.buildings,
    required this.rooms,
    required this.tenants,
    required this.services,
  }) {
    // Build lookup maps once during construction
    _buildingMap = {for (var b in buildings) b.id: b};
    _roomMap = {for (var r in rooms) r.id: r};
    _tenantMap = {for (var t in tenants) t.id: t};
    _serviceMap = {for (var s in services) s.id: s};
  }

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
      final buildingId = room.building?.id;

      if (buildingId != null && buildingId.isNotEmpty) {
        final fullBuilding = _buildingMap[buildingId];
        room.building = fullBuilding;
      } else {
        room.building = null;
      }
    }
  }

  /// Step 2: Link buildings to their rooms (bidirectional)
  void hydrateBuildingsWithRooms() {
    // Group rooms by building ID
    final roomsByBuilding = <String, List<Room>>{};
    for (var room in rooms) {
      final buildingId = room.building?.id;
      if (buildingId != null) {
        roomsByBuilding.putIfAbsent(buildingId, () => []).add(room);
      }
    }

    // Assign rooms to buildings
    for (var building in buildings) {
      final buildingRooms = roomsByBuilding[building.id] ?? [];

      building.rooms.clear();
      building.rooms.addAll(buildingRooms);

      // Ensure bidirectional link
      for (var room in buildingRooms) {
        room.building = building;
      }
    }
  }

  /// Step 3: Link tenants to their rooms
  void hydrateTenantsWithRooms() {
    for (var tenant in tenants) {
      final roomId = tenant.room?.id;

      if (roomId != null && roomId.isNotEmpty) {
        final fullRoom = _roomMap[roomId];
        tenant.room = fullRoom;
      } else {
        tenant.room = null;
      }
    }
  }

  /// Step 4: Link rooms back to their tenants (bidirectional)
  void hydrateRoomsWithTenants() {
    // Build tenant-by-room map
    final tenantByRoom = <String, Tenant>{};
    for (var tenant in tenants) {
      final roomId = tenant.room?.id;
      if (roomId != null) {
        tenantByRoom[roomId] = tenant;
      }
    }

    // Assign tenants to rooms
    for (var room in rooms) {
      final tenant = tenantByRoom[room.id];
      room.tenant = tenant;

      // Ensure bidirectional link
      if (tenant != null && tenant.room?.id != room.id) {
        tenant.room = room;
      }
    }
  }

  /// Step 5: Hydrate receipts with full object graphs
  void hydrateReceipts(List<Receipt> receipts) {
    for (var receipt in receipts) {
      final roomId = receipt.room?.id;

      if (roomId != null && roomId.isNotEmpty) {
        final fullRoom = _roomMap[roomId];
        receipt.room = fullRoom;
      } else {
        receipt.room = null;
      }

      // Hydrate services using serviceIds
      if (receipt.serviceIds.isNotEmpty) {
        final hydratedServices = <Service>[];

        for (var serviceId in receipt.serviceIds) {
          final fullService = _serviceMap[serviceId];
          if (fullService != null) {
            hydratedServices.add(fullService);
          }
        }

        receipt.services = hydratedServices;
      }
    }
  }

  /// Step 6: Hydrate reports with full object graphs
  /// Step 6: Hydrate reports with full object graphs
  void hydrateReports(List<Report> reports) {
    for (var report in reports) {
      // Hydrate room relationship
      final roomId = report.roomId;
      if (roomId != null && roomId.isNotEmpty) {
        final fullRoom = _roomMap[roomId];
        if (fullRoom != null) {
          report.room = fullRoom;
        }
      }

      // Hydrate tenant relationship intelligently
      final tenantId = report.tenantId;
      if (tenantId.isNotEmpty) {
        final cachedTenant = _tenantMap[tenantId];
        final apiTenant = report.tenant;

        if (cachedTenant != null && apiTenant != null) {
          if (cachedTenant.room != null) {
            apiTenant.room = cachedTenant.room;
          }
          report.tenant = apiTenant;
        } else if (cachedTenant != null) {
          report.tenant = cachedTenant;
        } else if (apiTenant != null) {
          report.tenant = apiTenant;
        } else {
          report.tenant = null;
        }
      }
    }
  }
}
