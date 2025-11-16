import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:joul_v2/core/helpers/api_helper.dart';
import 'package:joul_v2/core/helpers/sync_operation_helper.dart';
import 'package:joul_v2/data/models/room.dart';
import 'package:joul_v2/data/models/enum/room_status.dart';
import 'package:joul_v2/data/dtos/room_dto.dart';
import 'package:joul_v2/data/dtos/building_dto.dart';
import 'package:joul_v2/data/dtos/tenant_dto.dart';

// Top-level functions for compute() isolation
List<Room> _parseRooms(String jsonString) {
  final List<dynamic> jsonData = jsonDecode(jsonString);
  return jsonData.map((json) {
    final roomDto = RoomDto.fromJson(json);
    final room = roomDto.toRoom();

    if (roomDto.building != null) {
      room.building = roomDto.building!.toBuilding();
    }

    if (roomDto.tenant != null) {
      room.tenant = roomDto.tenant!.toTenant();
    }

    return room;
  }).toList();
}

String _encodeRooms(List<Room> rooms) {
  return jsonEncode(
    rooms
        .map(
          (room) => RoomDto(
            id: room.id,
            roomNumber: room.roomNumber,
            roomStatus: room.roomStatus == RoomStatus.occupied
                ? 'occupied'
                : 'available',
            price: room.price,
            buildingId: room.building?.id,
            building: room.building != null
                ? BuildingDto(
                    id: room.building!.id,
                    appUserId: room.building!.appUserId,
                    name: room.building!.name,
                    rentPrice: room.building!.rentPrice,
                    electricPrice: room.building!.electricPrice,
                    waterPrice: room.building!.waterPrice,
                    buildingImages: room.building!.buildingImages,
                    services: room.building!.services,
                    createdAt: room.building!.createdAt,
                    updatedAt: room.building!.updatedAt,
                    passKey: room.building!.passKey,
                  )
                : null,
            tenant: room.tenant != null
                ? TenantDto(
                    id: room.tenant!.id,
                    name: room.tenant!.name,
                    phoneNumber: room.tenant!.phoneNumber,
                    gender: room.tenant!.gender.toString().split('.').last,
                    chatId: room.tenant!.chatId,
                    language: room.tenant!.language,
                    lastInteractionDate: room.tenant!.lastInteractionDate,
                    nextReminderDate: room.tenant!.nextReminderDate,
                    isActive: room.tenant!.isActive,
                    deposit: room.tenant!.deposit,
                    tenantProfile: room.tenant!.tenantProfile,
                    createdAt: room.tenant!.createdAt,
                    updatedAt: room.tenant!.updatedAt,
                    roomId: room.id,
                  )
                : null,
          ).toJson(),
        )
        .toList(),
  );
}


List<Map<String, dynamic>> _parsePendingChanges(String jsonString) {
  return List<Map<String, dynamic>>.from(jsonDecode(jsonString));
}

class RoomRepository {
  final String storageKey = 'room_secure_data';
  final String pendingChangesKey = 'room_pending_changes';
  final ApiHelper _apiHelper = ApiHelper.instance;
  final SyncOperationHelper _syncHelper = SyncOperationHelper();

  List<Room> _roomCache = [];
  List<Map<String, dynamic>> _pendingChanges = [];

  RoomRepository();

  Future<void> load() async {
    try {
      final jsonString = await _apiHelper.storage.read(key: storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        _roomCache = await compute(_parseRooms, jsonString);
      } else {
        _roomCache = [];
      }

      final pendingString = await _apiHelper.storage.read(
        key: pendingChangesKey,
      );
      if (pendingString != null && pendingString.isNotEmpty) {
        _pendingChanges = await compute(_parsePendingChanges, pendingString);
      } else {
        _pendingChanges = [];
      }
    } catch (e) {
      throw Exception('Failed to load room data: $e');
    }
  }

  Future<void> save() async {
    try {
      if (_roomCache.isNotEmpty) {
        final jsonString = await compute(_encodeRooms, _roomCache);
        await _apiHelper.storage.write(key: storageKey, value: jsonString);
      }

      if (_pendingChanges.isNotEmpty) {
        final pendingJson = jsonEncode(_pendingChanges);
        await _apiHelper.storage.write(
          key: pendingChangesKey,
          value: pendingJson,
        );
      }
    } catch (e) {
      throw Exception('Failed to save room data: $e');
    }
  }

  Future<void> clear() async {
    await _apiHelper.storage.delete(key: storageKey);
    await _apiHelper.storage.delete(key: pendingChangesKey);
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
      await _apiHelper.storage.write(
        key: pendingChangesKey,
        value: jsonEncode(_pendingChanges),
      );
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
