import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:receipts_v2/core/api_helper.dart';
import 'package:receipts_v2/data/models/building.dart';
import 'package:receipts_v2/data/dtos/building_dto.dart';
import 'package:receipts_v2/data/models/room.dart';
import 'package:receipts_v2/data/repositories/room_repository.dart';
import 'package:logger/logger.dart';

class BuildingRepository {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String storageKey = 'building_secure_data';
  final ApiHelper _apiHelper = ApiHelper.instance;
  final Logger _logger = Logger();

  List<Building> _buildingCache = [];
  final RoomRepository _roomRepository;

  BuildingRepository(this._roomRepository);

  Future<void> load() async {
    try {
      _logger.i('Loading buildings from secure storage');
      final jsonString = await _secureStorage.read(key: storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonData = jsonDecode(jsonString);
        _buildingCache = jsonData
            .map((json) => BuildingDto.fromJson(json).toBuilding())
            .toList();

        // Restore room-building relationships
        await _linkRoomsToBuildings();

        _logger.i('Loaded ${_buildingCache.length} buildings from storage');
      } else {
        _buildingCache = [];
      }
    } catch (e) {
      _logger.e('Failed to load buildings from secure storage: $e');
      throw Exception('Failed to load building data from secure storage: $e');
    }
  }

  Future<void> _linkRoomsToBuildings() async {
    final allRooms = _roomRepository.getAllRooms();

    for (var building in _buildingCache) {
      final buildingRooms =
          allRooms.where((room) => room.building?.id == building.id).toList();

      // Update the building's rooms list
      building.rooms.clear();
      building.rooms.addAll(buildingRooms);

      // Ensure each room has proper building reference
      for (var room in buildingRooms) {
        room.building = building;
      }
    }
  }

  Future<void> save() async {
    try {
      final jsonString = jsonEncode(_buildingCache
          .map((b) => BuildingDto(
                id: b.id,
                name: b.name,
                rentPrice: b.rentPrice,
                electricPrice: b.electricPrice,
                waterPrice: b.waterPrice,
              ).toJson())
          .toList());
      await _secureStorage.write(key: storageKey, value: jsonString);
      _logger.d('Saved ${_buildingCache.length} buildings to storage');
    } catch (e) {
      _logger.e('Failed to save buildings to secure storage: $e');
      throw Exception('Failed to save building data to secure storage: $e');
    }
  }

  Future<void> syncFromApi() async {
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

      _logger.i('Syncing buildings from API');
      final response = await _apiHelper.dio.get(
        '${_apiHelper.baseUrl}/buildings',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        cancelToken: _apiHelper.cancelToken,
      );

      if (response.data['cancelled'] == true) {
        _logger.w('Request cancelled due to network loss');
        return;
      }

      if (response.statusCode == 200) {
        final List<dynamic> buildingsJson = response.data['data'];
        _buildingCache = buildingsJson
            .map((json) => BuildingDto.fromJson(json).toBuilding())
            .toList();

        // Sync rooms separately and link them
        await _roomRepository.syncFromApi();
        await _linkRoomsToBuildings();

        await save();
        _logger.i('Synced ${_buildingCache.length} buildings from API');
      }
    } catch (e) {
      _logger.e('Failed to sync buildings from API: $e');
      // Don't throw - fallback to cached data
    }
  }

  Future<void> createBuilding(Building newBuilding) async {
    try {
      if (await _apiHelper.hasNetwork()) {
        final token = await _secureStorage.read(key: 'auth_token');
        if (token != null) {
          _logger.i('Creating building via API: ${newBuilding.name}');

          final response = await _apiHelper.dio.post(
            '${_apiHelper.baseUrl}/buildings',
            data: {
              'name': newBuilding.name,
              'rentPrice': newBuilding.rentPrice,
              'electricPrice': newBuilding.electricPrice,
              'waterPrice': newBuilding.waterPrice,
            },
            options: Options(headers: {'Authorization': 'Bearer $token'}),
            cancelToken: _apiHelper.cancelToken,
          );

          if (response.data['cancelled'] == true) {
            _logger.w('Request cancelled, saving locally');
            _buildingCache.add(newBuilding);
            await save();
            return;
          }

          if (response.statusCode == 201) {
            final createdBuilding =
                BuildingDto.fromJson(response.data['data']).toBuilding();

            // Transfer rooms from newBuilding to createdBuilding
            createdBuilding.rooms.addAll(newBuilding.rooms);
            _buildingCache.add(createdBuilding);

            // Save rooms with proper building reference
            if (createdBuilding.rooms.isNotEmpty) {
              for (var room in createdBuilding.rooms) {
                room.building = createdBuilding;
                await _roomRepository.createRoom(room);
              }
            }

            _logger.i('Building created successfully via API');
          }
        } else {
          _buildingCache.add(newBuilding);
        }
      } else {
        _buildingCache.add(newBuilding);
      }

      // Save rooms to RoomRepository if not online
      if (newBuilding.rooms.isNotEmpty) {
        for (var room in newBuilding.rooms) {
          room.building = newBuilding;
          // Check if room already exists in repository
          final existingRooms = _roomRepository.getAllRooms();
          if (!existingRooms.any((r) => r.id == room.id)) {
            await _roomRepository.createRoom(room);
          }
        }
      }

      await save();
    } catch (e) {
      _logger.e('Failed to create building: $e');
      throw Exception('Failed to create building: $e');
    }
  }

  Future<void> updateBuilding(Building updatedBuilding) async {
    try {
      if (await _apiHelper.hasNetwork()) {
        final token = await _secureStorage.read(key: 'auth_token');
        if (token != null) {
          _logger.i('Updating building via API: ${updatedBuilding.id}');

          final response = await _apiHelper.dio.put(
            '${_apiHelper.baseUrl}/buildings/${updatedBuilding.id}',
            data: {
              'name': updatedBuilding.name,
              'rentPrice': updatedBuilding.rentPrice,
              'electricPrice': updatedBuilding.electricPrice,
              'waterPrice': updatedBuilding.waterPrice,
            },
            options: Options(headers: {'Authorization': 'Bearer $token'}),
            cancelToken: _apiHelper.cancelToken,
          );

          if (response.data['cancelled'] != true &&
              response.statusCode != 200) {
            throw Exception('Failed to update building via API');
          }
        }
      }

      final index =
          _buildingCache.indexWhere((b) => b.id == updatedBuilding.id);
      if (index != -1) {
        // Preserve room relationships
        final oldRooms = _buildingCache[index].rooms;
        _buildingCache[index] = updatedBuilding;
        updatedBuilding.rooms.clear();
        updatedBuilding.rooms.addAll(oldRooms);

        // Update building reference in rooms
        for (var room in updatedBuilding.rooms) {
          room.building = updatedBuilding;
          await _roomRepository.updateRoom(room);
        }

        await save();
        _logger.i('Building updated successfully');
      } else {
        throw Exception('Building not found: ${updatedBuilding.id}');
      }
    } catch (e) {
      _logger.e('Failed to update building: $e');
      throw Exception('Failed to update building: $e');
    }
  }

  Future<void> deleteBuilding(String buildingId) async {
    try {
      if (await _apiHelper.hasNetwork()) {
        final token = await _secureStorage.read(key: 'auth_token');
        if (token != null) {
          _logger.i('Deleting building via API: $buildingId');

          final response = await _apiHelper.dio.delete(
            '${_apiHelper.baseUrl}/buildings/$buildingId',
            options: Options(headers: {'Authorization': 'Bearer $token'}),
            cancelToken: _apiHelper.cancelToken,
          );

          if (response.data['cancelled'] != true &&
              response.statusCode != 200) {
            throw Exception('Failed to delete building via API');
          }
        }
      }

      final buildingToDelete =
          _buildingCache.firstWhere((b) => b.id == buildingId);
      if (buildingToDelete.rooms.isNotEmpty) {
        for (var room in buildingToDelete.rooms) {
          await _roomRepository.deleteRoom(room.id);
        }
      }

      _buildingCache.removeWhere((b) => b.id == buildingId);
      await save();
      _logger.i('Building deleted successfully');
    } catch (e) {
      _logger.e('Failed to delete building: $e');
      throw Exception('Failed to delete building: $e');
    }
  }

  Future<void> restoreBuilding(int restoreIndex, Building building) async {
    _buildingCache.insert(restoreIndex, building);

    // Restore rooms
    if (building.rooms.isNotEmpty) {
      for (var room in building.rooms) {
        room.building = building;
        await _roomRepository.createRoom(room);
      }
    }

    await save();
  }

  Future<void> updateRoom(String buildingId, Room room) async {
    final building = _buildingCache.firstWhere(
      (b) => b.id == buildingId,
      orElse: () => throw Exception('Building not found'),
    );
    final roomIndex = building.rooms.indexWhere((r) => r.id == room.id);
    if (roomIndex != -1) {
      building.rooms[roomIndex] = room;
      room.building = building;
      await save();
      await _roomRepository.updateRoom(room);
    } else {
      throw Exception('Room not found in building: ${room.id}');
    }
  }

  List<Building> getAllBuildings() {
    return List.unmodifiable(_buildingCache);
  }
}
