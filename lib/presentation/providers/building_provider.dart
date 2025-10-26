import 'package:flutter/material.dart';
import 'package:receipts_v2/data/models/building.dart';
import 'package:receipts_v2/data/repositories/building_repository.dart';
import 'package:receipts_v2/data/repositories/room_repository.dart';
import 'package:receipts_v2/core/helpers/repository_manager.dart';
import 'package:receipts_v2/core/helpers/asyn_value.dart';

class BuildingProvider with ChangeNotifier {
  final BuildingRepository _buildingRepository;
  final RoomRepository _roomRepository;
  final RepositoryManager? _repositoryManager;

  AsyncValue<List<Building>> _buildingsState = const AsyncValue.loading();

  BuildingProvider(
    this._buildingRepository,
    this._roomRepository, {
    RepositoryManager? repositoryManager,
  }) : _repositoryManager = repositoryManager;

  AsyncValue<List<Building>> get buildingsState => _buildingsState;

  // Convenience getters
  List<Building> get buildings => _buildingsState.when(
        loading: () => [],
        error: (_) => [],
        success: (data) => data,
      );

  bool get isLoading => _buildingsState.isLoading;
  bool get hasError => _buildingsState.hasError;
  Object? get error => _buildingsState.error;

  Future<void> load() async {
    try {
      // Keep previous data during loading
      _buildingsState = AsyncValue.loading(_buildingsState.data);
      notifyListeners();

      final buildings = _buildingRepository.getAllBuildings();
      _buildingsState = AsyncValue.success(buildings);
    } catch (e) {
      _buildingsState = AsyncValue.error(e, _buildingsState.data);
    }
    notifyListeners();
  }

  /// Create building with its rooms (cross-repository operation)
  Future<void> createBuilding(Building building) async {
    try {
      // Keep previous data during loading
      _buildingsState = AsyncValue.loading(_buildingsState.data);
      notifyListeners();

      // Step 1: Create building
      final createdBuilding =
          await _buildingRepository.createBuilding(building);

      // Step 2: Create rooms for this building
      final roomsToCreate = building.rooms;
      for (var room in roomsToCreate) {
        room.building = createdBuilding;
        await _roomRepository.createRoom(room);
      }

      // Step 3: Hydrate all relationships
      if (_repositoryManager != null) {
        await _repositoryManager.hydrateAllRelationships();
        await _repositoryManager.saveAll();
      }

      // Step 4: Reload and update state
      final buildings = _buildingRepository.getAllBuildings();
      _buildingsState = AsyncValue.success(buildings);
    } catch (e) {
      _buildingsState = AsyncValue.error(e, _buildingsState.data);
    }
    notifyListeners();
  }

  Future<void> updateBuilding(Building building) async {
    try {
      _buildingsState = AsyncValue.loading(_buildingsState.data);
      notifyListeners();

      await _buildingRepository.updateBuilding(building);

      // Hydrate relationships
      if (_repositoryManager != null) {
        await _repositoryManager.hydrateAllRelationships();
        await _repositoryManager.saveAll();
      }

      final buildings = _buildingRepository.getAllBuildings();
      _buildingsState = AsyncValue.success(buildings);
    } catch (e) {
      _buildingsState = AsyncValue.error(e, _buildingsState.data);
    }
    notifyListeners();
  }

  /// Delete building and its rooms (cross-repository operation)
  Future<void> deleteBuilding(String buildingId) async {
    try {
      _buildingsState = AsyncValue.loading(_buildingsState.data);
      notifyListeners();

      // Step 1: Get building's rooms
      final rooms = _roomRepository.getThisBuildingRooms(buildingId);

      // Step 2: Delete all rooms first
      for (var room in rooms) {
        await _roomRepository.deleteRoom(room.id);
      }

      // Step 3: Delete building
      await _buildingRepository.deleteBuilding(buildingId);

      // Step 4: Hydrate relationships
      if (_repositoryManager != null) {
        await _repositoryManager.hydrateAllRelationships();
        await _repositoryManager.saveAll();
      }

      final buildings = _buildingRepository.getAllBuildings();
      _buildingsState = AsyncValue.success(buildings);
    } catch (e) {
      _buildingsState = AsyncValue.error(e, _buildingsState.data);
    }
    notifyListeners();
  }

  /// Restore building with its rooms (cross-repository operation)
  Future<void> restoreBuilding(int index, Building building) async {
    try {
      _buildingsState = AsyncValue.loading(_buildingsState.data);
      notifyListeners();

      // Step 1: Restore building
      await _buildingRepository.restoreBuilding(index, building);

      // Step 2: Restore rooms
      for (var room in building.rooms) {
        room.building = building;
        await _roomRepository.createRoom(room);
      }

      // Step 3: Hydrate relationships
      if (_repositoryManager != null) {
        await _repositoryManager.hydrateAllRelationships();
        await _repositoryManager.saveAll();
      }

      final buildings = _buildingRepository.getAllBuildings();
      _buildingsState = AsyncValue.success(buildings);
    } catch (e) {
      _buildingsState = AsyncValue.error(e, _buildingsState.data);
    }
    notifyListeners();
  }

  List<Building> searchBuildings(String query) {
    return _buildingRepository.searchBuildings(query);
  }

  /// Clear error state
  void clearError() {
    if (_buildingsState.hasError && _buildingsState.data != null) {
      _buildingsState = AsyncValue.success(_buildingsState.data!);
      notifyListeners();
    }
  }
}
