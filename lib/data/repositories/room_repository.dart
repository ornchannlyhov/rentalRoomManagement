import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:joul_v2/core/helpers/api_helper.dart';
import 'package:joul_v2/core/helpers/sync_operation_helper.dart';
import 'package:joul_v2/data/models/room.dart';
import 'package:joul_v2/data/models/enum/room_status.dart';
import 'package:joul_v2/data/dtos/room_dto.dart';
import 'package:joul_v2/data/dtos/building_dto.dart';
import 'package:joul_v2/data/dtos/tenant_dto.dart';
import 'package:joul_v2/core/services/database_service.dart';

class RoomRepository {
  final DatabaseService _databaseService;
  final ApiHelper _apiHelper = ApiHelper.instance;
  final SyncOperationHelper _syncHelper = SyncOperationHelper();

  List<Room> _roomCache = [];
  List<Map<String, dynamic>> _pendingChanges = [];

  RoomRepository(this._databaseService);

  Future<void> load() async {
    try {
      final roomsList = _databaseService.roomsBox.values.toList();
      _roomCache = roomsList.map((e) {
        final roomDto = RoomDto.fromJson(Map<String, dynamic>.from(e));
        final room = roomDto.toRoom();
        if (roomDto.building != null) {
          room.building = roomDto.building!.toBuilding();
        }
        if (roomDto.tenant != null) {
          room.tenant = roomDto.tenant!.toTenant();
        }
        return room;
      }).toList();

      final pendingList = _databaseService.roomsPendingBox.values.toList();
      _pendingChanges =
          pendingList.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      throw Exception('Failed to load room data: $e');
    }
  }

  Future<void> save() async {
    try {
      await _databaseService.roomsBox.clear();
      for (var i = 0; i < _roomCache.length; i++) {
        final dto = RoomDto(
          id: _roomCache[i].id,
          roomNumber: _roomCache[i].roomNumber,
          roomStatus: _roomCache[i].roomStatus == RoomStatus.occupied
              ? 'occupied'
              : 'available',
          price: _roomCache[i].price,
          buildingId: _roomCache[i].building?.id,
          building: _roomCache[i].building != null
              ? BuildingDto(
                  id: _roomCache[i].building!.id,
                  appUserId: _roomCache[i].building!.appUserId,
                  name: _roomCache[i].building!.name,
                  rentPrice: _roomCache[i].building!.rentPrice,
                  electricPrice: _roomCache[i].building!.electricPrice,
                  waterPrice: _roomCache[i].building!.waterPrice,
                  buildingImage: _roomCache[i].building!.buildingImage,
                  services: _roomCache[i].building!.services,
                  passKey: _roomCache[i].building!.passKey,
                )
              : null,
          tenant: _roomCache[i].tenant != null
              ? TenantDto(
                  id: _roomCache[i].tenant!.id,
                  name: _roomCache[i].tenant!.name,
                  phoneNumber: _roomCache[i].tenant!.phoneNumber,
                  gender:
                      _roomCache[i].tenant!.gender.toString().split('.').last,
                  chatId: _roomCache[i].tenant!.chatId,
                  language: _roomCache[i].tenant!.language,
                  deposit: _roomCache[i].tenant!.deposit,
                  tenantProfile: _roomCache[i].tenant!.tenantProfile,
                  roomId: _roomCache[i].id,
                )
              : null,
        );
        await _databaseService.roomsBox.put(i, dto.toJson());
      }

      await _databaseService.roomsPendingBox.clear();
      for (var i = 0; i < _pendingChanges.length; i++) {
        await _databaseService.roomsPendingBox.put(i, _pendingChanges[i]);
      }
    } catch (e) {
      throw Exception('Failed to save room data: $e');
    }
  }

  Future<void> clear() async {
    await _databaseService.roomsBox.clear();
    await _databaseService.roomsPendingBox.clear();
    _roomCache.clear();
    _pendingChanges.clear();
  }

  Future<void> syncFromApi({bool skipHydration = false}) async {
    if (!await _apiHelper.hasNetwork()) {
      return;
    }

    await _syncPendingChanges();

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
      _roomCache = result.data!;
      if (!skipHydration) {
        await save();
      }
    }
  }

  Future<void> _syncPendingChanges() async {
    if (_pendingChanges.isEmpty) return;

    final successfulChanges = <int>[];
    final failedChanges = <int>[];

    for (int i = 0; i < _pendingChanges.length; i++) {
      final change = _pendingChanges[i];
      final retryCount = change['retryCount'] ?? 0;

      // Max 5 retries for failed changes
      if (retryCount >= 5) {
        failedChanges.add(i);
        if (kDebugMode) {
          print(
              'Room pending change exceeded retry limit: ${change['type']} ${change['endpoint']}');
        }
        continue;
      }

      final success = await _syncHelper.applyPendingChange(change);

      if (success) {
        successfulChanges.add(i);
        if (kDebugMode) {
          print(
              'Successfully synced room pending change: ${change['type']} ${change['endpoint']}');
        }
      } else {
        // Increment retry count
        _pendingChanges[i]['retryCount'] = retryCount + 1;
        if (kDebugMode) {
          print(
              'Failed to sync room pending change (retry ${retryCount + 1}/5): ${change['type']} ${change['endpoint']}');
        }
      }
    }

    // Remove successful and permanently failed changes (reverse order)
    final toRemove = [...successfulChanges, ...failedChanges]
      ..sort((a, b) => b.compareTo(a));
    for (final index in toRemove) {
      _pendingChanges.removeAt(index);
    }

    if (successfulChanges.isNotEmpty || failedChanges.isNotEmpty) {
      await save();
    }
  }

  Future<void> _addPendingChange(
    String type,
    Map<String, dynamic> data,
    String endpoint,
  ) async {
    // Check for duplicate pending changes
    final isDuplicate = _pendingChanges.any((change) {
      if (change['type'] != type || change['endpoint'] != endpoint) {
        return false;
      }

      // For creates with localId, check if localId matches
      if (type == 'create' && data['localId'] != null) {
        return change['data']['localId'] == data['localId'];
      }

      // For updates/deletes, check if id matches
      if (data['id'] != null) {
        return change['data']['id'] == data['id'];
      }

      // For rooms, also check by buildingId + roomNumber combination
      if (type == 'create' &&
          data['buildingId'] != null &&
          data['roomNumber'] != null) {
        return change['data']['buildingId'] == data['buildingId'] &&
            change['data']['roomNumber'] == data['roomNumber'];
      }

      // Fallback: compare full data
      return jsonEncode(change['data']) == jsonEncode(data);
    });

    if (isDuplicate) {
      if (kDebugMode) {
        print('Skipping duplicate room pending change: $type $endpoint');
      }
      return;
    }

    _pendingChanges.add({
      'type': type,
      'data': data,
      'endpoint': endpoint,
      'timestamp': DateTime.now().toIso8601String(),
      'retryCount': 0,
    });

    if (kDebugMode) {
      print('Added room pending change: $type $endpoint');
    }
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

  bool hasPendingChanges() => _pendingChanges.isNotEmpty;
  int getPendingChangesCount() => _pendingChanges.length;

  /// Get list of pending changes for debugging/display
  List<Map<String, dynamic>> getPendingChanges() {
    return List.unmodifiable(_pendingChanges);
  }
}
