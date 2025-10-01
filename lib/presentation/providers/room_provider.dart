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

  String? get errorMessage {
    return _rooms.when(
      loading: () => null,
      success: (_) => null,
      error: (error) => error.toString(),
    );
  }

  bool get isLoading => _rooms.isLoading;
  bool get hasData => _rooms.hasData;
  bool get hasError => _rooms.hasError;

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

  Future<Room> createRoom(Room room) async {
    try {
      final created = await _repository.createRoom(room);
      await load();
      return created;
    } catch (e) {
      _rooms = AsyncValue.error(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<Room> updateRoom(Room room) async {
    try {
      final updated = await _repository.updateRoom(room);
      await load();
      return updated;
    } catch (e) {
      _rooms = AsyncValue.error(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteRoom(String roomId) async {
    try {
      await _repository.deleteRoom(roomId);
      await load();
    } catch (e) {
      _rooms = AsyncValue.error(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateRoomStatus(String roomId, RoomStatus status) async {
    try {
      await _repository.updateRoomStatus(roomId, status);
      await load();
    } catch (e) {
      _rooms = AsyncValue.error(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addTenant(String roomId, Tenant tenant) async {
    try {
      await _repository.addTenant(roomId, tenant);
      await load();
    } catch (e) {
      _rooms = AsyncValue.error(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> removeTenant(String roomId) async {
    try {
      await _repository.removeTenant(roomId);
      await load();
    } catch (e) {
      _rooms = AsyncValue.error(e);
      notifyListeners();
      rethrow;
    }
  }

  Room? getRoomById(String roomId) {
    if (_rooms.hasData) {
      return _repository.getRoomById(roomId);
    }
    return null;
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

  int get roomCount {
    if (_rooms.hasData) {
      return _repository.getRoomCount();
    }
    return 0;
  }

  int getAvailableRoomCount() {
    return getAvailableRooms().length;
  }

  Future<void> refresh() async {
    await load();
  }

  void clearError() {
    if (_rooms.hasError) {
      _rooms = AsyncValue.success(_repository.getAllRooms());
      notifyListeners();
    }
  }
}
