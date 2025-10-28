import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:joul_v2/core/helpers/api_helper.dart';
import 'package:joul_v2/core/helpers/sync_operation_helper.dart';
import 'package:joul_v2/data/models/building.dart';
import 'package:joul_v2/data/dtos/building_dto.dart';

// Top-level functions for compute() isolation
List<Building> _parseBuildings(String jsonString) {
  final List<dynamic> jsonData = jsonDecode(jsonString);
  return jsonData
      .map((json) => BuildingDto.fromJson(json).toBuilding())
      .toList();
}

String _encodeBuildings(List<Building> buildings) {
  return jsonEncode(buildings
      .map((b) => BuildingDto(
            id: b.id,
            name: b.name,
            rentPrice: b.rentPrice,
            electricPrice: b.electricPrice,
            waterPrice: b.waterPrice,
          ).toJson())
      .toList());
}

List<Map<String, dynamic>> _parsePendingChanges(String jsonString) {
  return List<Map<String, dynamic>>.from(jsonDecode(jsonString));
}

class BuildingRepository {
  final String storageKey = 'building_secure_data';
  final String pendingChangesKey = 'building_pending_changes';
  final ApiHelper _apiHelper = ApiHelper.instance;
  final SyncOperationHelper _syncHelper = SyncOperationHelper();

  List<Building> _buildingCache = [];
  List<Map<String, dynamic>> _pendingChanges = [];

  BuildingRepository();

  Future<void> load() async {
    try {
      final jsonString = await _apiHelper.storage.read(key: storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        _buildingCache = await compute(_parseBuildings, jsonString);
      } else {
        _buildingCache = [];
      }

      final pendingString =
          await _apiHelper.storage.read(key: pendingChangesKey);
      if (pendingString != null && pendingString.isNotEmpty) {
        _pendingChanges = await compute(_parsePendingChanges, pendingString);
      } else {
        _pendingChanges = [];
      }
    } catch (e) {
      throw Exception('Failed to load building data: $e');
    }
  }

  Future<void> save() async {
    try {
      if (_buildingCache.isNotEmpty) {
        final jsonString = await compute(_encodeBuildings, _buildingCache);
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
      throw Exception('Failed to save building data: $e');
    }
  }

  Future<void> clear() async {
    await _apiHelper.storage.delete(key: storageKey);
    await _apiHelper.storage.delete(key: pendingChangesKey);
    _buildingCache.clear();
    _pendingChanges.clear();
  }

  Future<void> syncFromApi({bool skipHydration = false}) async {
    if (!await _apiHelper.hasNetwork()) {
      return;
    }

    await _syncPendingChanges();

    final result = await _syncHelper.fetch<Building>(
      endpoint: '/buildings',
      fromJsonList: (jsonList) => jsonList
          .map((json) => BuildingDto.fromJson(json).toBuilding())
          .toList(),
    );

    if (result.success && result.data != null) {
      _buildingCache = result.data!;
      if (!skipHydration) {
        await save();
      }
    }
  }

  Future<void> _syncPendingChanges() async {
    if (_pendingChanges.isEmpty) return;

    final successfulChanges = <int>[];

    for (int i = 0; i < _pendingChanges.length; i++) {
      final change = _pendingChanges[i];
      final success = await _syncHelper.applyPendingChange(change);
      if (success) {
        successfulChanges.add(i);
      }
    }

    for (int i = successfulChanges.length - 1; i >= 0; i--) {
      _pendingChanges.removeAt(successfulChanges[i]);
    }

    if (successfulChanges.isNotEmpty) {
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
    _pendingChanges.add({
      'type': type,
      'data': data,
      'endpoint': endpoint,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<Building> createBuilding(Building newBuilding) async {
    final requestData = {
      'name': newBuilding.name,
      'rentPrice': newBuilding.rentPrice,
      'electricPrice': newBuilding.electricPrice,
      'waterPrice': newBuilding.waterPrice,
    };

    final result = await _syncHelper.create<Building>(
      endpoint: '/buildings',
      data: requestData,
      fromJson: (json) => BuildingDto.fromJson(json).toBuilding(),
      addToCache: (building) async {
        _buildingCache.add(building);
      },
      addPendingChange: (type, data) => _addPendingChange(
        type,
        {...data, 'localId': newBuilding.id},
        '/buildings',
      ),
      offlineModel: newBuilding,
    );

    await save();
    return result.data ?? newBuilding;
  }

  Future<void> updateBuilding(Building updatedBuilding) async {
    final requestData = {
      'id': updatedBuilding.id,
      'name': updatedBuilding.name,
      'rentPrice': updatedBuilding.rentPrice,
      'electricPrice': updatedBuilding.electricPrice,
      'waterPrice': updatedBuilding.waterPrice,
    };

    await _syncHelper.update(
      endpoint: '/buildings/${updatedBuilding.id}',
      data: requestData,
      updateCache: () async {
        final index =
            _buildingCache.indexWhere((b) => b.id == updatedBuilding.id);
        if (index != -1) {
          // Preserve rooms list during update
          final oldRooms = _buildingCache[index].rooms;
          _buildingCache[index] = updatedBuilding;
          _buildingCache[index].rooms.clear();
          _buildingCache[index].rooms.addAll(oldRooms);
        } else {
          throw Exception('Building not found: ${updatedBuilding.id}');
        }
      },
      addPendingChange: (type, data) => _addPendingChange(
        type,
        data,
        '/buildings/${updatedBuilding.id}',
      ),
    );

    await save();
  }

  Future<void> deleteBuilding(String buildingId) async {
    await _syncHelper.delete(
      endpoint: '/buildings/$buildingId',
      id: buildingId,
      deleteFromCache: () async {
        _buildingCache.removeWhere((b) => b.id == buildingId);
      },
      addPendingChange: (type, data) => _addPendingChange(
        type,
        data,
        '/buildings/$buildingId',
      ),
    );

    await save();
  }

  Future<Building> restoreBuilding(int restoreIndex, Building building) async {
    _buildingCache.insert(restoreIndex, building);

    final requestData = {
      'name': building.name,
      'rentPrice': building.rentPrice,
      'electricPrice': building.electricPrice,
      'waterPrice': building.waterPrice,
    };

    final result = await _syncHelper.create<Building>(
      endpoint: '/buildings',
      data: requestData,
      fromJson: (json) => BuildingDto.fromJson(json).toBuilding(),
      addToCache: (createdBuilding) async {
        _buildingCache.removeAt(restoreIndex);
        _buildingCache.insert(restoreIndex, createdBuilding);
      },
      addPendingChange: (type, data) => _addPendingChange(
        type,
        {...data, 'localId': building.id},
        '/buildings',
      ),
      offlineModel: building,
    );

    await save();
    return result.data ?? building;
  }

  List<Building> getAllBuildings() {
    return List.unmodifiable(_buildingCache);
  }

  List<Building> searchBuildings(String query) {
    final lowerQuery = query.toLowerCase();
    return _buildingCache
        .where((b) => b.name.toLowerCase().contains(lowerQuery))
        .toList();
  }

  bool hasPendingChanges() => _pendingChanges.isNotEmpty;
  int getPendingChangesCount() => _pendingChanges.length;
}
