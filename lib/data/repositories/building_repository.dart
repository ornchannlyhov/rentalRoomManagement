import 'package:flutter/foundation.dart';
import 'package:joul_v2/core/helpers/api_helper.dart';
import 'package:joul_v2/core/sync/outbox.dart';
import 'package:joul_v2/core/sync/pull_merge.dart';
import 'package:joul_v2/core/helpers/sync_operation_helper.dart';
import 'package:joul_v2/data/models/building.dart';
import 'package:joul_v2/data/dtos/building_dto.dart';
import 'package:joul_v2/core/services/database_service.dart';

class BuildingRepository {
  final DatabaseService _databaseService;
  final ApiHelper _apiHelper = ApiHelper.instance;
  final SyncOperationHelper _syncHelper = SyncOperationHelper();

  List<Building> _buildingCache = [];

  BuildingRepository(this._databaseService);

  Future<void> load() async {
    try {
      final buildingsList = _databaseService.buildingsBox.values.toList();
      _buildingCache = buildingsList.map((e) {
        // Convert dynamic map to Map<String, dynamic> safely
        final Map<String, dynamic> jsonMap;
        if (e is Map<String, dynamic>) {
          jsonMap = e;
        } else {
          jsonMap = Map<String, dynamic>.from(e);
        }

        return BuildingDto.fromJson(jsonMap).toBuilding();
      }).toList();

      if (kDebugMode) {
        print(
            'Loaded ${_buildingCache.length} buildings');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading building data: $e');
      }
      // Don't throw, initialize with empty data instead
      _buildingCache = [];
    }
  }

  Future<void> loadWithoutHydration() async {
    final buildingsList = _databaseService.buildingsBox.values.toList();
    _buildingCache = buildingsList
        .map((e) =>
            BuildingDto.fromJson(Map<String, dynamic>.from(e)).toBuilding())
        .toList();
  }

  Future<void> save() async {
    try {
      // Clear and save buildings
      final records = <String, Map<String, dynamic>>{};
      for (var i = 0; i < _buildingCache.length; i++) {
        final dto = BuildingDto(
          id: _buildingCache[i].id,
          appUserId: _buildingCache[i].appUserId,
          name: _buildingCache[i].name,
          rentPrice: _buildingCache[i].rentPrice,
          electricPrice: _buildingCache[i].electricPrice,
          waterPrice: _buildingCache[i].waterPrice,
          buildingImage: _buildingCache[i].buildingImage,
          services: _buildingCache[i].services,
          passKey: _buildingCache[i].passKey,
          rooms:
              null, // Don't save rooms in building - they're saved separately
        );

        // Convert to JSON and ensure it's a proper Map<String, dynamic>
        final jsonData = dto.toJson();
        final Map<String, dynamic> mapData =
            Map<String, dynamic>.from(jsonData);

        records[_buildingCache[i].id] = Map<String, dynamic>.from(mapData);
      }

      await _databaseService.writeRecords(
          _databaseService.buildingsBox, records);

      if (kDebugMode) {
        print(
            'Saved ${_buildingCache.length} buildings');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving building data: $e');
      }
      throw Exception('Failed to save building data: $e');
    }
  }

  Future<void> clear() async {
    await _databaseService.buildingsBox.clear();
    _buildingCache.clear();
  }

  Future<void> syncFromApi({bool skipHydration = false}) async {
    if (!await _apiHelper.hasNetwork()) {
      if (kDebugMode) {
        print('No network available for sync');
      }
      return;
    }

    final result = await _syncHelper.fetch<Building>(
      endpoint: '/buildings',
      fromJsonList: (jsonList) => jsonList
          .map((json) => BuildingDto.fromJson(json).toBuilding())
          .toList(),
    );

    if (result.success && result.data != null) {
      _buildingCache = mergePulled(
        server: result.data!,
        local: _buildingCache,
        idOf: (item) => item.id,
      );
      if (!skipHydration) {
        await save();
      }
      if (kDebugMode) {
        print('Synced ${_buildingCache.length} buildings from API');
      }
    }
  }

  Future<void> _addPendingChange(
    String type,
    Map<String, dynamic> data,
    String endpoint, {
    String? filePath,
    String? fileFieldName,
  }) async {
    await Outbox.instance.enqueue(
      entity: 'building',
      type: type,
      endpoint: endpoint,
      data: data,
      filePath: filePath,
      fileFieldName: fileFieldName,
    );
  }

  Future<Building> createBuilding(Building newBuilding) async {
    final requestData = {
      'name': newBuilding.name,
      'rentPrice': newBuilding.rentPrice.toString(),
      'electricPrice': newBuilding.electricPrice.toString(),
      'waterPrice': newBuilding.waterPrice.toString(),
    };

    final result = await _syncHelper.create<Building>(
      endpoint: '/buildings',
      data: requestData,
      fromJson: (json) => BuildingDto.fromJson(json).toBuilding(),
      addToCache: (building) async {
        _buildingCache.add(building);
      },
      addPendingChange: (type, endpoint, data) => _addPendingChange(
        type,
        {...data, 'localId': newBuilding.id},
        endpoint,
        filePath: newBuilding.imageFile?.path,
        fileFieldName: 'buildingImage',
      ),
      offlineModel: newBuilding,
      file: newBuilding.imageFile,
      fileFieldName: 'buildingImage',
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
      addPendingChange: (type, endpoint, data) => _addPendingChange(
        type,
        data,
        endpoint,
        filePath: updatedBuilding.imageFile?.path,
        fileFieldName: 'buildingImage',
      ),
      file: updatedBuilding.imageFile,
      fileFieldName: 'buildingImage',
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
      addPendingChange: (type, endpoint, data) => _addPendingChange(
        type,
        data,
        endpoint,
      ),
    );

    await save();
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

}
