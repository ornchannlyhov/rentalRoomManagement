import 'package:flutter/material.dart';
import 'package:receipts_v2/core/asyn_value.dart';
import 'package:receipts_v2/data/models/building.dart';
import 'package:receipts_v2/data/models/room.dart';
import 'package:receipts_v2/data/repositories/buidling_repository.dart';

class BuildingProvider extends ChangeNotifier {
  final BuildingRepository _repository; // Modified to accept in constructor

  BuildingProvider(this._repository); // Constructor

  AsyncValue<List<Building>> _buildings = const AsyncValue.loading();
  AsyncValue<List<Building>> get buildings => _buildings;

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

  Future<void> createBuilding(Building building) async {
    try {
      await _repository.createBuilding(building);
      await load();
    } catch (e) {
      _buildings = AsyncValue.error(e);
      notifyListeners();
    }
  }

  Future<void> updateBuilding(Building building) async {
    try {
      await _repository.updateBuilding(building);
      await load();
    } catch (e) {
      _buildings = AsyncValue.error(e);
      notifyListeners();
    }
  }

  Future<void> restoreBuilding(int index, Building building) async {
    try {
      await _repository.restoreBuilding(index, building);
      await load();
    } catch (e) {
      _buildings = AsyncValue.error(e);
      notifyListeners();
    }
  }

  Future<void> deleteBuilding(String buildingId) async {
    try {
      await _repository.deleteBuilding(buildingId);
      await load();
    } catch (e) {
      _buildings = AsyncValue.error(e);
      notifyListeners();
    }
  }

  Future<void> updateRoom(String buildingId, Room room) async {
    try {
      await _repository.updateRoom(buildingId, room);
      await load();
    } catch (e) {
      _buildings = AsyncValue.error(e);
      notifyListeners();
    }
  }
}