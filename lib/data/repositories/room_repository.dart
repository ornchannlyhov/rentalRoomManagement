import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:receipts_v2/helpers/api_helper.dart';
import 'package:receipts_v2/data/models/room.dart';
import 'package:receipts_v2/data/models/tenant.dart';
import 'package:receipts_v2/data/models/enum/room_status.dart';
import 'package:receipts_v2/data/dtos/room_dto.dart';
import 'package:receipts_v2/data/dtos/building_dto.dart';
import 'package:receipts_v2/data/dtos/tenant_dto.dart';
import 'package:logger/logger.dart';

class RoomRepository {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String storageKey = 'room_secure_data';
  final String pendingChangesKey = 'room_pending_changes';
  final ApiHelper _apiHelper = ApiHelper.instance;
  final Logger _logger = Logger();

  List<Room> _roomCache = [];
  List<Map<String, dynamic>> _pendingChanges = [];

  Future<void> load() async {
    try {
      _logger.i('Loading rooms from secure storage');

      // Load rooms
      final jsonString = await _secureStorage.read(key: storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonData = jsonDecode(jsonString);
        _roomCache = jsonData.map((json) {
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
        _logger.i('Loaded ${_roomCache.length} rooms from storage');
      } else {
        _roomCache = [];
      }

      // Load pending changes
      final pendingString = await _secureStorage.read(key: pendingChangesKey);
      if (pendingString != null && pendingString.isNotEmpty) {
        _pendingChanges =
            List<Map<String, dynamic>>.from(jsonDecode(pendingString));
        _logger.i('Loaded ${_pendingChanges.length} pending room changes');
      } else {
        _pendingChanges = [];
      }
    } catch (e) {
      _logger.e('Failed to load rooms from secure storage: $e');
      throw Exception('Failed to load room data from secure storage: $e');
    }
  }

  Future<void> save() async {
    try {
      final jsonString = jsonEncode(_roomCache.map((room) {
        final roomDto = RoomDto(
          id: room.id,
          roomNumber: room.roomNumber,
          roomStatus:
              room.roomStatus == RoomStatus.occupied ? 'occupied' : 'available',
          price: room.price,
          buildingId: room.building?.id,
          building: room.building != null
              ? BuildingDto(
                  id: room.building!.id,
                  name: room.building!.name,
                  rentPrice: room.building!.rentPrice,
                  electricPrice: room.building!.electricPrice,
                  waterPrice: room.building!.waterPrice,
                )
              : null,
          tenant: room.tenant != null
              ? TenantDto(
                  id: room.tenant!.id,
                  name: room.tenant!.name,
                  phoneNumber: room.tenant!.phoneNumber,
                  gender: room.tenant!.gender.toString().split('.').last,
                  roomId: room.id,
                )
              : null,
        );
        return roomDto.toJson();
      }).toList());
      await _secureStorage.write(key: storageKey, value: jsonString);

      // Save pending changes
      if (_pendingChanges.isNotEmpty) {
        await _secureStorage.write(
          key: pendingChangesKey,
          value: jsonEncode(_pendingChanges),
        );
      }

      _logger.d(
          'Saved ${_roomCache.length} rooms and ${_pendingChanges.length} pending changes to storage');
    } catch (e) {
      _logger.e('Failed to save rooms to secure storage: $e');
      throw Exception('Failed to save room data to secure storage: $e');
    }
  }

  Future<void> clear() async {
    await _secureStorage.delete(key: storageKey);
    await _secureStorage.delete(key: pendingChangesKey);
    _roomCache.clear();
    _pendingChanges.clear();
    _logger.i('Cleared room data from secure storage');
  }

  Future<void> _addPendingChange(String type, Map<String, dynamic> data) async {
    _pendingChanges.add({
      'type': type,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await save();
  }

  Future<void> _syncPendingChanges() async {
    if (_pendingChanges.isEmpty) return;

    _logger.i('Syncing ${_pendingChanges.length} pending room changes...');
    final successfulChanges = <int>[];

    for (int i = 0; i < _pendingChanges.length; i++) {
      final change = _pendingChanges[i];
      try {
        await _applyPendingChange(change);
        successfulChanges.add(i);
      } catch (e) {
        _logger.e('Failed to apply pending room change: $e');
      }
    }

    for (int i = successfulChanges.length - 1; i >= 0; i--) {
      _pendingChanges.removeAt(successfulChanges[i]);
    }

    if (successfulChanges.isNotEmpty) {
      await _secureStorage.write(
        key: pendingChangesKey,
        value: jsonEncode(_pendingChanges),
      );
      _logger.i(
          'Successfully synced ${successfulChanges.length} pending room changes');
    }
  }

  Future<void> _applyPendingChange(Map<String, dynamic> change) async {
    final token = await _secureStorage.read(key: 'auth_token');
    if (token == null) throw Exception('No auth token');

    final type = change['type'];
    final data = change['data'];

    switch (type) {
      case 'create':
        await _apiHelper.dio.post(
          '${_apiHelper.baseUrl}/rooms',
          data: data,
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        break;
      case 'update':
        await _apiHelper.dio.put(
          '${_apiHelper.baseUrl}/rooms/${data['id']}',
          data: data,
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        break;
      case 'delete':
        await _apiHelper.dio.delete(
          '${_apiHelper.baseUrl}/rooms/${data['id']}',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        break;
    }
  }

  Future<void> syncFromApi({bool skipHydration = false}) async {
    try {
      if (!await _apiHelper.hasNetwork()) {
        _logger.w('No network connection, skipping sync');
        return;
      }

      final token = await _secureStorage.read(key: 'auth_token');
      if (token == null) {
        _logger.w('No auth token found, skipping sync');
        return;
      }

      // Sync pending changes first
      await _syncPendingChanges();

      _logger.i('Syncing rooms from API');
      final response = await _apiHelper.dio.get(
        '${_apiHelper.baseUrl}/rooms',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        cancelToken: _apiHelper.cancelToken,
      );

      if (response.data['cancelled'] == true) {
        _logger.w('Request cancelled due to network loss');
        return;
      }

      if (response.statusCode == 200) {
        final List<dynamic> roomsJson = response.data['data'];
        _roomCache = roomsJson.map((json) {
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
        }).toList();

        if (!skipHydration) {
          await save();
        }
        _logger.i('Synced ${_roomCache.length} rooms from API');
      }
    } catch (e) {
      _logger.e('Failed to sync rooms from API: $e');
    }
  }

  Future<void> createRoom(Room newRoom) async {
    try {
      if (newRoom.building == null) {
        throw Exception('Room must have a building reference');
      }

      Room createdRoom = newRoom;
      bool syncedOnline = false;

      if (await _apiHelper.hasNetwork()) {
        final token = await _secureStorage.read(key: 'auth_token');
        if (token != null) {
          _logger.i('Creating room via API: ${newRoom.roomNumber}');

          try {
            final response = await _apiHelper.dio.post(
              '${_apiHelper.baseUrl}/rooms',
              data: {
                'buildingId': newRoom.building!.id,
                'roomNumber': newRoom.roomNumber,
                'price': newRoom.price,
                'roomStatus': newRoom.roomStatus == RoomStatus.occupied
                    ? 'occupied'
                    : 'available',
                if (newRoom.tenant != null)
                  'tenant': {
                    'id': newRoom.tenant!.id,
                    'name': newRoom.tenant!.name,
                    'phoneNumber': newRoom.tenant!.phoneNumber,
                    'gender': newRoom.tenant!.gender.toString().split('.').last,
                  },
              },
              options: Options(headers: {'Authorization': 'Bearer $token'}),
              cancelToken: _apiHelper.cancelToken,
            );

            if (response.data['cancelled'] != true &&
                response.statusCode == 201) {
              final roomDto = RoomDto.fromJson(response.data['data']);
              createdRoom = roomDto.toRoom();

              createdRoom.building = newRoom.building;
              createdRoom.tenant = newRoom.tenant;
              if (createdRoom.tenant != null) {
                createdRoom.tenant!.room = createdRoom;
              }

              syncedOnline = true;
              _logger.i('Room created successfully via API');
            }
          } catch (e) {
            _logger.w('Failed to create room online, will sync later: $e');
          }
        }
      }

      _roomCache.add(createdRoom);
      if (createdRoom.tenant != null) {
        createdRoom.tenant!.room = createdRoom;
      }

      if (!syncedOnline) {
        await _addPendingChange('create', {
          'buildingId': newRoom.building!.id,
          'roomNumber': newRoom.roomNumber,
          'price': newRoom.price,
          'roomStatus': newRoom.roomStatus == RoomStatus.occupied
              ? 'occupied'
              : 'available',
          'localId': newRoom.id,
        });
      }

      await save();
    } catch (e) {
      _logger.e('Failed to create room: $e');
      throw Exception('Failed to create room: $e');
    }
  }

  Future<void> updateRoom(Room updatedRoom) async {
    try {
      bool syncedOnline = false;

      if (await _apiHelper.hasNetwork()) {
        final token = await _secureStorage.read(key: 'auth_token');
        if (token != null) {
          _logger.i('Updating room via API: ${updatedRoom.id}');

          try {
            final response = await _apiHelper.dio.put(
              '${_apiHelper.baseUrl}/rooms/${updatedRoom.id}',
              data: {
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
                    'gender':
                        updatedRoom.tenant!.gender.toString().split('.').last,
                  },
              },
              options: Options(headers: {'Authorization': 'Bearer $token'}),
              cancelToken: _apiHelper.cancelToken,
            );

            if (response.data['cancelled'] != true &&
                response.statusCode == 200) {
              syncedOnline = true;
              _logger.i('Room updated successfully via API');
            }
          } catch (e) {
            _logger.w('Failed to update room online, will sync later: $e');
          }
        }
      }

      final index = _roomCache.indexWhere((room) => room.id == updatedRoom.id);
      if (index != -1) {
        if (updatedRoom.building == null &&
            _roomCache[index].building != null) {
          updatedRoom.building = _roomCache[index].building;
        }
        if (updatedRoom.tenant == null && _roomCache[index].tenant != null) {
          updatedRoom.tenant = _roomCache[index].tenant;
        }
        if (updatedRoom.tenant != null) {
          updatedRoom.tenant!.room = updatedRoom;
        }

        _roomCache[index] = updatedRoom;

        if (!syncedOnline) {
          await _addPendingChange('update', {
            'id': updatedRoom.id,
            'roomNumber': updatedRoom.roomNumber,
            'price': updatedRoom.price,
            'roomStatus': updatedRoom.roomStatus == RoomStatus.occupied
                ? 'occupied'
                : 'available',
          });
        }

        await save();
        _logger.i('Room updated in local cache');
      } else {
        throw Exception('Room not found: ${updatedRoom.id}');
      }
    } catch (e) {
      _logger.e('Failed to update room: $e');
      throw Exception('Failed to update room: $e');
    }
  }

  Future<void> deleteRoom(String roomId) async {
    try {
      bool syncedOnline = false;

      if (await _apiHelper.hasNetwork()) {
        final token = await _secureStorage.read(key: 'auth_token');
        if (token != null) {
          _logger.i('Deleting room via API: $roomId');

          try {
            final response = await _apiHelper.dio.delete(
              '${_apiHelper.baseUrl}/rooms/$roomId',
              options: Options(headers: {'Authorization': 'Bearer $token'}),
              cancelToken: _apiHelper.cancelToken,
            );

            if (response.data['cancelled'] != true &&
                response.statusCode == 200) {
              syncedOnline = true;
              _logger.i('Room deleted successfully via API');
            }
          } catch (e) {
            _logger.w('Failed to delete room online, will sync later: $e');
          }
        }
      }

      _roomCache.removeWhere((room) => room.id == roomId);

      if (!syncedOnline) {
        await _addPendingChange('delete', {'id': roomId});
      }

      await save();
      _logger.i('Room deleted from local cache');
    } catch (e) {
      _logger.e('Failed to delete room: $e');
      throw Exception('Failed to delete room: $e');
    }
  }

  Future<void> restoreRoom(int restoreIndex, Room room) async {
    _roomCache.insert(restoreIndex, room);
    await save();
  }

  Future<void> updateRoomStatus(String roomId, RoomStatus status) async {
    final room = _roomCache.firstWhere((room) => room.id == roomId);
    room.roomStatus = status;
    await updateRoom(room);
  }

  Future<void> addTenant(String roomId, Tenant tenant) async {
    final room = _roomCache.firstWhere((room) => room.id == roomId);
    room.tenant = tenant;
    await updateRoom(room);
  }

  Future<void> removeTenant(String roomId) async {
    final room = _roomCache.firstWhere((room) => room.id == roomId);
    room.tenant = null;
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

  bool hasPendingChanges() {
    return _pendingChanges.isNotEmpty;
  }

  int getPendingChangesCount() {
    return _pendingChanges.length;
  }
}
