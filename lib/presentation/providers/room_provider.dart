import 'package:flutter/material.dart';
import 'package:receipts_v2/core/asyn_value.dart';
import 'package:receipts_v2/data/models/enum/room_status.dart';
import 'package:receipts_v2/data/models/room.dart';
import 'package:receipts_v2/data/models/tenant.dart';
import 'package:receipts_v2/data/repositories/room_repository.dart';

class RoomProvider extends ChangeNotifier {
  final RoomRepository _repository;

  RoomProvider(this._repository);

  AsyncValue<List<Room>> _rooms = const AsyncValue.loading();

  AsyncValue<List<Room>> get rooms => _rooms;

  Future<void> load() async {
    _rooms = const AsyncValue.loading();
    notifyListeners();

    try {
      await _repository.load();
      final data = _repository.getAllRooms();
      _rooms = AsyncValue.success(data);
    } catch (e) {
      _rooms = AsyncValue.error(e);
    }
    notifyListeners();
  }

  Future<void> createRoom(Room room) async {
    try {
      await _repository.createRoom(room);
      await load();
    } catch (e) {
      _rooms = AsyncValue.error(e);
      notifyListeners();
    }
  }

  Future<void> updateRoom(Room room) async {
    try {
      await _repository.updateRoom(room);
      await load();
    } catch (e) {
      _rooms = AsyncValue.error(e);
      notifyListeners();
    }
  }

  Future<void> deleteRoom(String roomId) async {
    try {
      await _repository.deleteRoom(roomId);
      await load();
    } catch (e) {
      _rooms = AsyncValue.error(e);
      notifyListeners();
    }
  }

  Future<void> restoreRoom(int index, Room room) async {
    try {
      await _repository.restoreRoom(index, room);
      await load();
    } catch (e) {
      _rooms = AsyncValue.error(e);
      notifyListeners();
    }
  }

  Future<void> updateRoomStatus(String roomId, RoomStatus status) async {
    try {
      await _repository.updateRoomStatus(roomId, status);
      await load();
    } catch (e) {
      _rooms = AsyncValue.error(e);
      notifyListeners();
    }
  }

  Future<void> addTenant(String roomId, Tenant tenant) async {
    try {
      await _repository.addTenant(roomId, tenant);
      await load();
    } catch (e) {
      _rooms = AsyncValue.error(e);
      notifyListeners();
    }
  }

  Future<void> removeTenant(String roomId) async {
    try {
      await _repository.removeTenant(roomId);
      await load();
    } catch (e) {
      _rooms = AsyncValue.error(e);
      notifyListeners();
    }
  }

  List<Room> getAvailableRooms() {
    if (_rooms.hasData) {
      return _repository.getAvailableRooms();
    }
    return [];
  }

  List<Room> getRoomsByBuilding(String buildingId) {
    if (_rooms.hasData) {
      return _repository.getThisBuildingRooms(buildingId);
    }
    return [];
  }
}