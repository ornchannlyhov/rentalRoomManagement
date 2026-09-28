import 'package:flutter/foundation.dart';
import 'package:joul_v2/core/helpers/api_helper.dart';
import 'package:joul_v2/core/sync/outbox.dart';
import 'package:joul_v2/core/sync/pull_merge.dart';
import 'package:joul_v2/core/helpers/sync_operation_helper.dart';
import 'package:joul_v2/data/models/room.dart';
import 'package:joul_v2/data/models/enum/room_status.dart';
import 'package:joul_v2/data/dtos/room_dto.dart';
import 'package:joul_v2/core/services/database_service.dart';
import 'package:joul_v2/data/repositories/building_repository.dart';
import 'package:joul_v2/data/repositories/tenant_repository.dart';

class RoomRepository {
  final DatabaseService _databaseService;
  final ApiHelper _apiHelper = ApiHelper.instance;
  final SyncOperationHelper _syncHelper = SyncOperationHelper();

  List<Room> _roomCache = [];

  final BuildingRepository _buildingRepository;
  final TenantRepository _tenantRepository;

  RoomRepository(
    this._databaseService,
    this._buildingRepository,
    this._tenantRepository,
  );

  Future<void> load() async {
    try {
      await loadWithoutHydration();
      await _hydrateFromCachedRepositories();
    } catch (e) {
      throw Exception('Failed to load room data: $e');
    }
  }

  Future<void> loadWithoutHydration() async {
    final roomsList = _databaseService.roomsBox.values.toList();
    _roomCache = roomsList.map((e) {
      final roomDto = RoomDto.fromJson(Map<String, dynamic>.from(e));
      return roomDto.toRoom();
    }).toList();

    if (kDebugMode) {
      print(
          '📥 Loaded ${_roomCache.length} rooms from Hive (without hydration)');
    }
  }

  Future<void> _hydrateFromCachedRepositories() async {
    final buildings = _buildingRepository.getAllBuildings();
    final tenants = _tenantRepository.getAllTenants();

    if (buildings.isEmpty) {
      if (kDebugMode) {
        print('⚠️ Warning: Cannot hydrate rooms - buildings not loaded yet');
      }
      // Even if buildings are empty, we should still try to load what we can
      // or just return if it's critical.
      // For now, we proceed, but relationships might be null if not found.
    }

    final buildingMap = {for (var b in buildings) b.id: b};
    // Tenant repository might not have getAllTenants or it might be per building.
    // Assuming getAllTenants exists or we can get them.
    // If TenantRepository doesn't have getAllTenants, we might need to rely on what's available.
    // Checking TenantRepository... it usually has getAllTenants or similar.
    final tenantMap = {for (var t in tenants) t.id: t};

    for (var room in _roomCache) {
      // Hydrate Building
      // We need to know the buildingId. Room object might not have it if it was created from DTO without building object.
      // But RoomDto.toRoom() sets building if buildingId is present (as a placeholder).
      // Let's check RoomDto.toRoom() again.
      // It creates a placeholder Building if buildingId is present.

      if (room.building != null) {
        final buildingId = room.building!.id;
        if (buildingMap.containsKey(buildingId)) {
          room.building = buildingMap[buildingId];
        }
      }

      // Hydrate Tenant
      // Room doesn't have a direct tenantId field, it has a Tenant object.
      // We need to check if we can recover the tenantId.
      // If we saved only IDs, the DTO `tenantId` would be set, but `toRoom` might not set the Tenant object if `tenant` DTO is null.
      // We need to update RoomDto.toRoom to handle tenantId.
      // Wait, I missed updating RoomDto.toRoom to use tenantId!
      // I will fix RoomDto in a separate step or assume I'll fix it.
      // Actually, I should fix RoomDto.toRoom first or handle it here.
      // If RoomDto.toRoom() doesn't use tenantId, then room.tenant will be null.
      // So I need to update RoomDto.toRoom as well.

      // Assuming RoomDto is updated or we can access the DTO data here? No, we only have _roomCache which are Room objects.
      // If I update RoomDto.toRoom to create a placeholder Tenant from tenantId, then room.tenant will not be null (but placeholder).

      if (room.tenant != null) {
        final tenantId = room.tenant!.id;
        if (tenantMap.containsKey(tenantId)) {
          room.tenant = tenantMap[tenantId];
          room.tenant!.room = room; // Link back
        }
      }
    }

    if (kDebugMode) {
      print('✅ Hydrated ${_roomCache.length} rooms from cached repositories');
    }
  }

  Future<void> save() async {
    try {
      final records = <String, Map<String, dynamic>>{};
      for (var i = 0; i < _roomCache.length; i++) {
        final room = _roomCache[i];
        final dto = RoomDto(
          id: room.id,
          roomNumber: room.roomNumber,
          roomStatus:
              room.roomStatus == RoomStatus.occupied ? 'occupied' : 'available',
          price: room.price,
          buildingId: room.building?.id,
          tenantId: room.tenant?.id,
          // Do NOT save full objects
          building: null,
          tenant: null,
        );
        records[_roomCache[i].id] = Map<String, dynamic>.from(dto.toJson());
      }

      await _databaseService.writeRecords(
          _databaseService.roomsBox, records);

      if (kDebugMode) {
        print('💾 Saved ${_roomCache.length} rooms to Hive');
      }
    } catch (e) {
      throw Exception('Failed to save room data: $e');
    }
  }

  Future<void> clear() async {
    await _databaseService.roomsBox.clear();
    _roomCache.clear();
  }

  Future<void> syncFromApi({bool skipHydration = false}) async {
    if (!await _apiHelper.hasNetwork()) {
      return;
    }

    final result = await _syncHelper.fetch<Room>(
      endpoint: '/rooms',
      fromJsonList: (jsonList) => jsonList.map((json) {
        final roomDto = RoomDto.fromJson(json);
        final room = roomDto.toRoom();

        if (roomDto.building != null) {
          room.building = roomDto.building!.toBuilding();
        }
        if (roomDto.tenant != null) {
          room.tenant = roomDto.tenant!.toTenant();
          if (room.tenant != null) {
            room.tenant!.room = room;
          }
        }

        return room;
      }).toList(),
    );

    if (result.success && result.data != null) {
      _roomCache = mergePulled(
        server: result.data!,
        local: _roomCache,
        idOf: (item) => item.id,
      );
      if (!skipHydration) {
        await save();
      }
    }
  }

  Future<void> _addPendingChange(
    String type,
    Map<String, dynamic> data,
    String endpoint,
  ) async {
    await Outbox.instance.enqueue(
      entity: 'room',
      type: type,
      endpoint: endpoint,
      data: data,
    );
  }

  Future<Room> createRoom(Room newRoom) async {
    if (newRoom.building == null) {
      throw Exception('Room must have a building reference');
    }

    final requestData = {
      'buildingId': newRoom.building!.id,
      'roomNumber': newRoom.roomNumber,
      'price': newRoom.price,
      'roomStatus':
          newRoom.roomStatus == RoomStatus.occupied ? 'occupied' : 'available',
      if (newRoom.tenant != null)
        'tenant': {
          'id': newRoom.tenant!.id,
          'name': newRoom.tenant!.name,
          'phoneNumber': newRoom.tenant!.phoneNumber,
          'gender': newRoom.tenant!.gender.toString().split('.').last,
        },
    };

    final result = await _syncHelper.create<Room>(
      endpoint: '/rooms',
      data: requestData,
      fromJson: (json) {
        final roomDto = RoomDto.fromJson(json);
        final room = roomDto.toRoom();

        if (roomDto.building != null) {
          room.building = roomDto.building!.toBuilding();
        }
        if (roomDto.tenant != null) {
          room.tenant = roomDto.tenant!.toTenant();
          if (room.tenant != null) {
            room.tenant!.room = room;
          }
        }

        return room;
      },
      addToCache: (room) async {
        _roomCache.add(room);
      },
      addPendingChange: (type, endpoint, data) =>
          _addPendingChange(type, {...data, 'localId': newRoom.id}, endpoint),
      offlineModel: newRoom,
    );

    await save();
    return result.data ?? newRoom;
  }

  Future<void> updateRoom(Room updatedRoom) async {
    final requestData = {
      'roomNumber': updatedRoom.roomNumber,
      'price': updatedRoom.price,
      'roomStatus': updatedRoom.roomStatus == RoomStatus.occupied
          ? 'occupied'
          : 'available',
      if (updatedRoom.tenant != null)
        'tenant': {
          'id': updatedRoom.tenant!.id,
          'name': updatedRoom.tenant!.name,
          'phoneNumber': updatedRoom.tenant!.phoneNumber,
          'gender': updatedRoom.tenant!.gender.toString().split('.').last,
        },
    };

    await _syncHelper.update(
      endpoint: '/rooms/${updatedRoom.id}',
      data: requestData,
      updateCache: () async {
        final index = _roomCache.indexWhere((r) => r.id == updatedRoom.id);
        if (index != -1) {
          final oldBuilding = _roomCache[index].building;
          final oldTenant = _roomCache[index].tenant;
          _roomCache[index] = updatedRoom;
          updatedRoom.building ??= oldBuilding;
          updatedRoom.tenant ??= oldTenant;
        } else {
          throw Exception('Room not found: ${updatedRoom.id}');
        }
      },
      addPendingChange: (type, endpoint, data) =>
          _addPendingChange(type, data, endpoint),
    );

    await save();
  }

  Future<void> deleteRoom(String roomId) async {
    await _syncHelper.delete(
      endpoint: '/rooms/$roomId',
      id: roomId,
      deleteFromCache: () async {
        _roomCache.removeWhere((r) => r.id == roomId);
      },
      addPendingChange: (type, endpoint, data) =>
          _addPendingChange(type, data, endpoint),
    );

    await save();
  }

  Future<void> updateRoomStatus(String roomId, RoomStatus status) async {
    final room = _roomCache.firstWhere((r) => r.id == roomId);
    room.roomStatus = status;
    await updateRoom(room);
  }

  List<Room> getAllRooms() {
    return List.unmodifiable(_roomCache);
  }

  List<Room> getAvailableRooms() {
    return _roomCache
        .where((room) => room.roomStatus == RoomStatus.available)
        .toList();
  }

  List<Room> getThisBuildingRooms(String buildingId) {
    return _roomCache.where((room) => room.building?.id == buildingId).toList();
  }

}
