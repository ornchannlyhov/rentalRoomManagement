import 'package:receipts_v2/data/models/building.dart';
import 'package:receipts_v2/data/models/room.dart';
import 'package:receipts_v2/data/models/tenant.dart';
import 'package:receipts_v2/data/models/receipt.dart';
import 'package:receipts_v2/data/models/service.dart';
import 'package:receipts_v2/data/models/report.dart';
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
  void hydrateAll({
    List<Receipt>? receipts,
    List<Report>? reports,
  }) {
    _logger.i('Starting data hydration...');
    _logger.d(
        'Input: ${buildings.length} buildings, ${rooms.length} rooms, ${tenants.length} tenants, ${services.length} services, ${receipts?.length ?? 0} receipts, ${reports?.length ?? 0} reports');

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

    _logger.i('Data hydration complete');
  }

  /// Step 1: Link rooms to their buildings
  void hydrateRoomsWithBuildings() {
    _logger.d('Hydrating rooms with buildings...');
    int hydrated = 0;
    int failed = 0;

    for (var room in rooms) {
      String? buildingId = room.building?.id;

      if (buildingId != null && buildingId.isNotEmpty) {
        final fullBuilding = buildings.firstWhereOrNull(
          (b) => b.id == buildingId,
        );

        if (fullBuilding != null) {
          room.building = fullBuilding;
          hydrated++;
          _logger.d('Room ${room.roomNumber} -> Building ${fullBuilding.name}');
        } else {
          _logger.w(
              'Building not found for room ${room.roomNumber} (buildingId: $buildingId)');
          room.building = null;
          failed++;
        }
      } else {
        _logger.d('Room ${room.roomNumber} has no building ID');
        room.building = null;
      }
    }

    _logger.d('Hydrated $hydrated rooms with buildings, $failed failed');
  }

  /// Step 2: Link buildings to their rooms (bidirectional)
  void hydrateBuildingsWithRooms() {
    _logger.d('Hydrating buildings with rooms...');

    for (var building in buildings) {
      final buildingRooms =
          rooms.where((r) => r.building?.id == building.id).toList();

      building.rooms.clear();
      building.rooms.addAll(buildingRooms);

      for (var room in buildingRooms) {
        room.building = building;
      }

      _logger.d('Building ${building.name} has ${buildingRooms.length} rooms');
    }

    _logger.d('Hydrated ${buildings.length} buildings with rooms');
  }

  /// Step 3: Link tenants to their rooms (and transitively to buildings)
  void hydrateTenantsWithRooms() {
    _logger.d('Hydrating tenants with rooms...');
    int hydrated = 0;

    for (var tenant in tenants) {
      if (tenant.room?.id != null) {
        final roomId = tenant.room!.id;

        final fullRoom = rooms.firstWhereOrNull(
          (r) => r.id == roomId,
        );

        if (fullRoom != null) {
          tenant.room = fullRoom;
          hydrated++;
        } else {
          _logger
              .w('Room not found for tenant ${tenant.name} (roomId: $roomId)');
          tenant.room = null;
        }
      } else {
        tenant.room = null;
      }
    }

    _logger.d('Hydrated $hydrated tenants with rooms');
  }

  /// Step 4: Link rooms back to their tenants (bidirectional)
  void hydrateRoomsWithTenants() {
    _logger.d('Hydrating rooms with tenants...');

    for (var room in rooms) {
      final tenant = tenants.firstWhereOrNull(
        (t) => t.room?.id == room.id,
      );

      room.tenant = tenant;

      if (tenant != null && tenant.room?.id != room.id) {
        tenant.room = room;
      }
    }

    _logger.d('Hydrated rooms with their tenants');
  }

  /// Step 5: Hydrate receipts with full object graphs
  void hydrateReceipts(List<Receipt> receipts) {
    _logger.d('Hydrating receipts...');
    int receiptsWithRooms = 0;
    int receiptsWithBuildings = 0;
    int receiptsWithServices = 0;

    for (var receipt in receipts) {
      // Hydrate room reference WITH FULL BUILDING
      if (receipt.room?.id != null) {
        final roomId = receipt.room!.id;

        final fullRoom = rooms.firstWhereOrNull(
          (r) => r.id == roomId,
        );

        if (fullRoom != null) {
          receipt.room = fullRoom;
          receiptsWithRooms++;

          if (fullRoom.building != null) {
            receiptsWithBuildings++;
            _logger.d(
                'Receipt ${receipt.id} -> Room ${fullRoom.roomNumber} -> Building ${fullRoom.building!.name}');
          } else {
            _logger.w(
                'Receipt ${receipt.id} has room ${fullRoom.roomNumber} but NO BUILDING!');
          }
        } else {
          _logger
              .w('Room not found for receipt ${receipt.id} (roomId: $roomId)');
          receipt.room = null;
        }
      } else {
        _logger.d('Receipt ${receipt.id} has no room ID');
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
          } else {
            _logger.w(
                'Service not found for receipt ${receipt.id} (serviceId: $serviceId)');
          }
        }

        receipt.services = hydratedServices;
        if (hydratedServices.isNotEmpty) {
          receiptsWithServices++;
        }
      }
    }

    _logger.d('Hydrated ${receipts.length} receipts:');
    _logger.d('  - With rooms: $receiptsWithRooms');
    _logger.d('  - With buildings: $receiptsWithBuildings');
    _logger.d('  - With services: $receiptsWithServices');
  }

  /// Step 6: Hydrate reports with full object graphs
  void hydrateReports(List<Report> reports) {
    _logger.d('Hydrating reports...');
    int reportsWithTenants = 0;
    int reportsWithRooms = 0;

    for (var report in reports) {
      // Hydrate tenant reference
      if (report.tenant?.id != null) {
        final tenantId = report.tenant!.id;

        final fullTenant = tenants.firstWhereOrNull(
          (t) => t.id == tenantId,
        );

        if (fullTenant != null) {
          report.tenant = fullTenant;
          reportsWithTenants++;
        } else {
          _logger.w(
              'Tenant not found for report ${report.id} (tenantId: $tenantId)');
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
          reportsWithRooms++;
        } else {
          _logger.w('Room not found for report ${report.id} (roomId: $roomId)');
          report.room = null;
        }
      }
    }

    _logger.d('Hydrated ${reports.length} reports:');
    _logger.d('  - With tenants: $reportsWithTenants');
    _logger.d('  - With rooms: $reportsWithRooms');
  }

  /// Validate hydration results (for debugging)
  Map<String, dynamic> validate({
    List<Receipt>? receipts,
    List<Report>? reports,
  }) {
    int roomsWithBuildings = rooms.where((r) => r.building != null).length;
    int roomsWithoutBuildings = rooms.where((r) => r.building == null).length;
    int buildingsWithRooms = buildings.where((b) => b.rooms.isNotEmpty).length;
    int tenantsWithRooms = tenants.where((t) => t.room != null).length;
    int receiptsWithRooms = receipts?.where((r) => r.room != null).length ?? 0;
    int receiptsWithBuildings =
        receipts?.where((r) => r.room?.building != null).length ?? 0;
    int receiptsWithServices =
        receipts?.where((r) => r.services.isNotEmpty).length ?? 0;
    int reportsWithTenants =
        reports?.where((r) => r.tenant != null).length ?? 0;
    int reportsWithRooms = reports?.where((r) => r.room != null).length ?? 0;

    final results = {
      'total_rooms': rooms.length,
      'rooms_with_buildings': roomsWithBuildings,
      'rooms_without_buildings': roomsWithoutBuildings,
      'total_buildings': buildings.length,
      'buildings_with_rooms': buildingsWithRooms,
      'total_tenants': tenants.length,
      'tenants_with_rooms': tenantsWithRooms,
      'total_receipts': receipts?.length ?? 0,
      'receipts_with_rooms': receiptsWithRooms,
      'receipts_with_buildings': receiptsWithBuildings,
      'receipts_missing_buildings': receiptsWithRooms - receiptsWithBuildings,
      'receipts_with_services': receiptsWithServices,
      'total_reports': reports?.length ?? 0,
      'reports_with_tenants': reportsWithTenants,
      'reports_with_rooms': reportsWithRooms,
    };

    _logger.i('Hydration validation: $results');

    // Log warnings for receipts without buildings
    if (receipts != null) {
      for (var receipt in receipts) {
        if (receipt.room != null && receipt.room!.building == null) {
          _logger.w(
              '⚠️ Receipt ${receipt.id} has room ${receipt.room!.roomNumber} (${receipt.room!.id}) but NO BUILDING!');

          final possibleBuilding = buildings.firstWhereOrNull(
              (b) => b.rooms.any((r) => r.id == receipt.room!.id));
          if (possibleBuilding != null) {
            _logger.w(
                '   -> Building ${possibleBuilding.name} contains this room ID');
          }
        }
      }
    }

    // Log warnings for rooms without buildings
    for (var room in rooms) {
      if (room.building == null) {
        _logger.w(
            '⚠️ Room ${room.roomNumber} (${room.id}) has NO BUILDING reference!');
      }
    }

    return results;
  }
}
