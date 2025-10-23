import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:receipts_v2/helpers/api_helper.dart';
import 'package:receipts_v2/data/models/building.dart';
import 'package:receipts_v2/data/dtos/building_dto.dart';
import 'package:receipts_v2/data/repositories/room_repository.dart';
import 'package:logger/logger.dart';

class BuildingRepository {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String storageKey = 'building_secure_data';
  final String pendingChangesKey = 'building_pending_changes';
  final ApiHelper _apiHelper = ApiHelper.instance;
  final Logger _logger = Logger();

  List<Building> _buildingCache = [];
  List<Map<String, dynamic>> _pendingChanges = [];
  final RoomRepository _roomRepository;

  BuildingRepository(this._roomRepository);

  Future<void> load() async {
    try {
      _logger.i('Loading buildings from secure storage');

      // Load buildings
      final jsonString = await _secureStorage.read(key: storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonData = jsonDecode(jsonString);
        _buildingCache = jsonData
            .map((json) => BuildingDto.fromJson(json).toBuilding())
            .toList();
        _logger.i('Loaded ${_buildingCache.length} buildings from storage');
      } else {
        _buildingCache = [];
      }

      // Load pending changes
      final pendingString = await _secureStorage.read(key: pendingChangesKey);
      if (pendingString != null && pendingString.isNotEmpty) {
        _pendingChanges =
            List<Map<String, dynamic>>.from(jsonDecode(pendingString));
        _logger.i('Loaded ${_pendingChanges.length} pending changes');
      } else {
        _pendingChanges = [];
      }
    } catch (e) {
      _logger.e('Failed to load buildings from secure storage: $e');
      throw Exception('Failed to load building data from secure storage: $e');
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

      // Save pending changes
      if (_pendingChanges.isNotEmpty) {
        await _secureStorage.write(
          key: pendingChangesKey,
          value: jsonEncode(_pendingChanges),
        );
      }

      _logger.d(
          'Saved ${_buildingCache.length} buildings and ${_pendingChanges.length} pending changes to storage');
    } catch (e) {
      _logger.e('Failed to save buildings to secure storage: $e');
      throw Exception('Failed to save building data to secure storage: $e');
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

      _logger.i('Syncing buildings from API');

      // First, sync pending changes to server
      await _syncPendingChanges();

      // Then fetch latest data from server
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

        if (!skipHydration) {
          await save();
        }

        _logger.i('Synced ${_buildingCache.length} buildings from API');
      }
    } catch (e) {
      _logger.e('Failed to sync buildings from API: $e');
    }
  }

  Future<void> _syncPendingChanges() async {
    if (_pendingChanges.isEmpty) return;

    _logger.i('Syncing ${_pendingChanges.length} pending changes...');
    final successfulChanges = <int>[];

    for (int i = 0; i < _pendingChanges.length; i++) {
      final change = _pendingChanges[i];
      try {
        await _applyPendingChange(change);
        successfulChanges.add(i);
      } catch (e) {
        _logger.e('Failed to apply pending change: $e');
        // Continue with other changes
      }
    }

    // Remove successfully synced changes
    for (int i = successfulChanges.length - 1; i >= 0; i--) {
      _pendingChanges.removeAt(successfulChanges[i]);
    }

    if (successfulChanges.isNotEmpty) {
      await _secureStorage.write(
        key: pendingChangesKey,
        value: jsonEncode(_pendingChanges),
      );
      _logger
          .i('Successfully synced ${successfulChanges.length} pending changes');
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
          '${_apiHelper.baseUrl}/buildings',
          data: data,
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        break;
      case 'update':
        await _apiHelper.dio.put(
          '${_apiHelper.baseUrl}/buildings/${data['id']}',
          data: data,
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        break;
      case 'delete':
        await _apiHelper.dio.delete(
          '${_apiHelper.baseUrl}/buildings/${data['id']}',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        break;
    }
  }

  Future<void> _addPendingChange(String type, Map<String, dynamic> data) async {
    _pendingChanges.add({
      'type': type,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await save();
  }

  Future<void> createBuilding(Building newBuilding) async {
    try {
      Building createdBuilding = newBuilding;

      if (await _apiHelper.hasNetwork()) {
        final token = await _secureStorage.read(key: 'auth_token');
        if (token != null) {
          _logger.i('Creating building via API: ${newBuilding.name}');

          try {
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
              throw Exception('Request cancelled');
            }

            if (response.statusCode == 201) {
              createdBuilding =
                  BuildingDto.fromJson(response.data['data']).toBuilding();
              createdBuilding.rooms.addAll(newBuilding.rooms);

              for (var room in createdBuilding.rooms) {
                room.building = createdBuilding;
                final existingRooms = _roomRepository.getAllRooms();
                if (!existingRooms.any((r) => r.id == room.id)) {
                  await _roomRepository.createRoom(room);
                }
              }

              _buildingCache.add(createdBuilding);
              _logger.i('Building created successfully via API');
              await save();
              return;
            }
          } catch (e) {
            _logger.w(
                'Failed to create building online, saving for later sync: $e');
            // Fall through to offline creation
          }
        }
      }

      // Offline creation or API failure
      _logger.i('Creating building offline: ${newBuilding.name}');
      _buildingCache.add(newBuilding);

      for (var room in newBuilding.rooms) {
        room.building = newBuilding;
        final existingRooms = _roomRepository.getAllRooms();
        if (!existingRooms.any((r) => r.id == room.id)) {
          await _roomRepository.createRoom(room);
        }
      }

      // Add to pending changes for later sync
      await _addPendingChange('create', {
        'name': newBuilding.name,
        'rentPrice': newBuilding.rentPrice,
        'electricPrice': newBuilding.electricPrice,
        'waterPrice': newBuilding.waterPrice,
        'localId': newBuilding.id,
      });

      await save();
    } catch (e) {
      _logger.e('Failed to create building: $e');
      throw Exception('Failed to create building: $e');
    }
  }

  Future<void> updateBuilding(Building updatedBuilding) async {
    try {
      bool syncedOnline = false;

      if (await _apiHelper.hasNetwork()) {
        final token = await _secureStorage.read(key: 'auth_token');
        if (token != null) {
          _logger.i('Updating building via API: ${updatedBuilding.id}');

          try {
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
                response.statusCode == 200) {
              syncedOnline = true;
              _logger.i('Building updated successfully via API');
            }
          } catch (e) {
            _logger.w('Failed to update building online, will sync later: $e');
          }
        }
      }

      // Update local cache
      final index =
          _buildingCache.indexWhere((b) => b.id == updatedBuilding.id);
      if (index != -1) {
        final oldRooms = _buildingCache[index].rooms;
        _buildingCache[index] = updatedBuilding;
        updatedBuilding.rooms.clear();
        updatedBuilding.rooms.addAll(oldRooms);

        for (var room in updatedBuilding.rooms) {
          room.building = updatedBuilding;
        }

        // Add to pending changes if not synced online
        if (!syncedOnline) {
          await _addPendingChange('update', {
            'id': updatedBuilding.id,
            'name': updatedBuilding.name,
            'rentPrice': updatedBuilding.rentPrice,
            'electricPrice': updatedBuilding.electricPrice,
            'waterPrice': updatedBuilding.waterPrice,
          });
        }

        await save();
        _logger.i('Building updated in local cache');
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
      bool syncedOnline = false;

      if (await _apiHelper.hasNetwork()) {
        final token = await _secureStorage.read(key: 'auth_token');
        if (token != null) {
          _logger.i('Deleting building via API: $buildingId');

          try {
            final response = await _apiHelper.dio.delete(
              '${_apiHelper.baseUrl}/buildings/$buildingId',
              options: Options(headers: {'Authorization': 'Bearer $token'}),
              cancelToken: _apiHelper.cancelToken,
            );

            if (response.data['cancelled'] != true &&
                response.statusCode == 200) {
              syncedOnline = true;
              _logger.i('Building deleted successfully via API');
            }
          } catch (e) {
            _logger.w('Failed to delete building online, will sync later: $e');
          }
        }
      }

      // Delete from local cache
      final buildingToDelete =
          _buildingCache.firstWhere((b) => b.id == buildingId);
      if (buildingToDelete.rooms.isNotEmpty) {
        for (var room in buildingToDelete.rooms) {
          await _roomRepository.deleteRoom(room.id);
        }
      }

      _buildingCache.removeWhere((b) => b.id == buildingId);

      // Add to pending changes if not synced online
      if (!syncedOnline) {
        await _addPendingChange('delete', {'id': buildingId});
      }

      await save();
      _logger.i('Building deleted from local cache');
    } catch (e) {
      _logger.e('Failed to delete building: $e');
      throw Exception('Failed to delete building: $e');
    }
  }

  Future<void> restoreBuilding(int restoreIndex, Building building) async {
    _buildingCache.insert(restoreIndex, building);

    if (building.rooms.isNotEmpty) {
      for (var room in building.rooms) {
        room.building = building;
        await _roomRepository.createRoom(room);
      }
    }

    await save();
  }

  List<Building> getAllBuildings() {
    return List.unmodifiable(_buildingCache);
  }

  bool hasPendingChanges() {
    return _pendingChanges.isNotEmpty;
  }

  int getPendingChangesCount() {
    return _pendingChanges.length;
  }
}
