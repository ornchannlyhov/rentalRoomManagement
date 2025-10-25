import 'package:receipts_v2/data/models/building.dart';
import 'package:receipts_v2/data/models/room.dart';
import 'package:receipts_v2/data/models/tenant.dart';
import 'package:receipts_v2/data/models/receipt.dart';
import 'package:receipts_v2/data/models/service.dart';
import 'package:receipts_v2/data/models/report.dart';

/// Helper class to rebuild object references after API sync
///
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

  /// Step 1: Link rooms to their buildings - O(n) instead of O(n²)
  void hydrateRoomsWithBuildings() {
    for (var room in rooms) {
      final buildingId = room.building?.id;

      if (buildingId != null && buildingId.isNotEmpty) {
        final fullBuilding = _buildingMap[buildingId]; // O(1) lookup
        room.building = fullBuilding;
      } else {
        room.building = null;
      }
    }
  }

  /// Step 2: Link buildings to their rooms (bidirectional)
  void hydrateBuildingsWithRooms() {
    // Group rooms by building ID - O(n)
    final roomsByBuilding = <String, List<Room>>{};
    for (var room in rooms) {
      final buildingId = room.building?.id;
      if (buildingId != null) {
        roomsByBuilding.putIfAbsent(buildingId, () => []).add(room);
      }
    }

    // Assign rooms to buildings - O(n)
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

  /// Step 3: Link tenants to their rooms - O(n) instead of O(n²)
  void hydrateTenantsWithRooms() {
    for (var tenant in tenants) {
      final roomId = tenant.room?.id;

      if (roomId != null && roomId.isNotEmpty) {
        final fullRoom = _roomMap[roomId]; // O(1) lookup
        tenant.room = fullRoom;
      } else {
        tenant.room = null;
      }
    }
  }

  /// Step 4: Link rooms back to their tenants (bidirectional)
  void hydrateRoomsWithTenants() {
    // Build tenant-by-room map - O(n)
    final tenantByRoom = <String, Tenant>{};
    for (var tenant in tenants) {
      final roomId = tenant.room?.id;
      if (roomId != null) {
        tenantByRoom[roomId] = tenant;
      }
    }

    // Assign tenants to rooms - O(n)
    for (var room in rooms) {
      final tenant = tenantByRoom[room.id];
      room.tenant = tenant;

      // Ensure bidirectional link
      if (tenant != null && tenant.room?.id != room.id) {
        tenant.room = room;
      }
    }
  }

  /// Step 5: Hydrate receipts with full object graphs - O(n*m) where m is avg services
  void hydrateReceipts(List<Receipt> receipts) {
    for (var receipt in receipts) {
      final roomId = receipt.room?.id;

      if (roomId != null && roomId.isNotEmpty) {
        final fullRoom = _roomMap[roomId]; // O(1) lookup
        receipt.room = fullRoom;
      } else {
        receipt.room = null;
      }

      // Hydrate services using serviceIds - O(k) where k is number of services
      if (receipt.serviceIds.isNotEmpty) {
        final hydratedServices = <Service>[];

        for (var serviceId in receipt.serviceIds) {
          final fullService = _serviceMap[serviceId]; // O(1) lookup
          if (fullService != null) {
            hydratedServices.add(fullService);
          }
        }

        receipt.services = hydratedServices;
      }
    }
  }

  /// Step 6: Hydrate reports with full object graphs - O(n)
  void hydrateReports(List<Report> reports) {
    for (var report in reports) {
      final tenantId = report.tenant?.id;
      if (tenantId != null && tenantId.isNotEmpty) {
        final fullTenant = _tenantMap[tenantId]; // O(1) lookup
        report.tenant = fullTenant;
      } else {
        report.tenant = null;
      }

      final roomId = report.room?.id;
      if (roomId != null && roomId.isNotEmpty) {
        final fullRoom = _roomMap[roomId]; // O(1) lookup
        report.room = fullRoom;
      } else {
        report.room = null;
      }
    }
  }
}
