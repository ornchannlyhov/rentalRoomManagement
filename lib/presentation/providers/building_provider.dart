import 'package:flutter/material.dart';
import 'package:receipts_v2/helpers/asyn_value.dart';
import 'package:receipts_v2/data/models/building.dart';
import 'package:receipts_v2/data/repositories/building_repository.dart';
import 'package:receipts_v2/presentation/providers/room_provider.dart';

class BuildingProvider extends ChangeNotifier {
  final BuildingRepository _repository;
  final RoomProvider _roomProvider;

  BuildingProvider(this._repository, this._roomProvider);

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

  Future<void> syncFromApi() async {
    _buildings = const AsyncValue.loading();
    notifyListeners();

    try {
      await _repository.syncFromApi();
      final data = _repository.getAllBuildings();
      _buildings = AsyncValue.success(data);
    } catch (e) {
      _buildings = AsyncValue.error(e);
    }
    notifyListeners();
  }

  Future<void> createBuilding(Building building) async {
    _buildings = const AsyncValue.loading();
    notifyListeners();

    try {
      await _repository.createBuilding(building);
      await _roomProvider.load();
      final data = _repository.getAllBuildings();
      _buildings = AsyncValue.success(data);
    } catch (e) {
      _buildings = AsyncValue.error(e);
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> updateBuilding(Building building) async {
    _buildings = const AsyncValue.loading();
    notifyListeners();

    try {
      await _repository.updateBuilding(building);
      final data = _repository.getAllBuildings();
      _buildings = AsyncValue.success(data);
    } catch (e) {
      _buildings = AsyncValue.error(e);
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> deleteBuilding(String buildingId) async {
    _buildings = const AsyncValue.loading();
    notifyListeners();

    try {
      await _repository.deleteBuilding(buildingId);
      final data = _repository.getAllBuildings();
      _buildings = AsyncValue.success(data);
    } catch (e) {
      _buildings = AsyncValue.error(e);
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> restoreBuilding(int restoreIndex, Building building) async {
    _buildings = const AsyncValue.loading();
    notifyListeners();

    try {
      await _repository.restoreBuilding(restoreIndex, building);
      final data = _repository.getAllBuildings();
      _buildings = AsyncValue.success(data);
    } catch (e) {
      _buildings = AsyncValue.error(e);
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  bool isBuildingEmpty(String buildingId) {
    if (_buildings.hasData && _roomProvider.hasData) {
      final rooms = _roomProvider.getRoomsByBuilding(buildingId);
      return rooms.isEmpty;
    }
    return true;
  }

  int get buildingCount {
    return _buildings.hasData ? _repository.getAllBuildings().length : 0;
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
