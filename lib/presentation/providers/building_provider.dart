import 'package:flutter/material.dart';
import 'package:receipts_v2/core/asyn_value.dart';
import 'package:receipts_v2/data/models/building.dart';
import 'package:receipts_v2/data/models/room.dart';
import 'package:receipts_v2/data/repositories/buidling_repository.dart';

class BuildingProvider extends ChangeNotifier {
  final BuildingRepository _repository;

  BuildingProvider(this._repository);

  AsyncValue<List<Building>> _buildings = const AsyncValue.loading();
  AsyncValue<List<Building>> get buildings => _buildings;

  String? get errorMessage {
    return _buildings.when(
      loading: () => null,
      success: (_) => null,
      error: (error) => error.toString(),
    );
  }

  bool get isLoading => _buildings.isLoading;
  bool get hasData => _buildings.hasData;
  bool get hasError => _buildings.hasError;

  Future<void> load() async {
    _buildings = const AsyncValue.loading();
    notifyListeners();

    try {
      await _repository.load();
      final data = _repository.getAllBuildings();
      _buildings = AsyncValue.success(data);
    } catch (e) {
      _buildings = AsyncValue.error(e);
    }
    notifyListeners();
  }

  Future<Building> createBuilding(Building building) async {
    try {
      final created = await _repository.createBuilding(building);
      await load(); // Reload to sync with server
      return created;
    } catch (e) {
      _buildings = AsyncValue.error(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<Building> updateBuilding(Building building) async {
    try {
      final updated = await _repository.updateBuilding(building);
      await load(); // Reload to sync with server
      return updated;
    } catch (e) {
      _buildings = AsyncValue.error(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteBuilding(String buildingId) async {
    try {
      await _repository.deleteBuilding(buildingId);
      await load(); // Reload to sync with server
    } catch (e) {
      _buildings = AsyncValue.error(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateRoom(String buildingId, Room room) async {
    try {
      await _repository.updateRoom(buildingId, room);
      await load();
    } catch (e) {
      _buildings = AsyncValue.error(e);
      notifyListeners();
      rethrow;
    }
  }

  Building? getBuildingById(String buildingId) {
    if (_buildings.hasData) {
      return _repository.getBuildingById(buildingId);
    }
    return null;
  }

  bool isBuildingEmpty(String buildingId) {
    try {
      return _repository.isBuildingEmpty(buildingId);
    } catch (e) {
      return true;
    }
  }

  int get buildingCount {
    if (_buildings.hasData) {
      return _repository.getBuildingCount();
    }
    return 0;
  }

  Future<void> refresh() async {
    await load();
  }

  void clearError() {
    if (_buildings.hasError) {
      _buildings = AsyncValue.success(_repository.getAllBuildings());
      notifyListeners();
    }
  }
}
