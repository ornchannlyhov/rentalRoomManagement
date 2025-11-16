import 'package:flutter/material.dart';
import 'package:joul_v2/data/models/room.dart';
import 'package:joul_v2/data/models/tenant.dart';
import 'package:joul_v2/data/models/enum/room_status.dart';
import 'package:joul_v2/data/repositories/room_repository.dart';
import 'package:joul_v2/data/repositories/tenant_repository.dart';
import 'package:joul_v2/core/helpers/repository_manager.dart';
import 'package:joul_v2/core/helpers/asyn_value.dart';

class RoomProvider with ChangeNotifier {
  final RoomRepository _roomRepository;
  final TenantRepository _tenantRepository;
  final RepositoryManager? _repositoryManager;

  AsyncValue<List<Room>> _roomsState = const AsyncValue.loading();

  RoomProvider(
    this._roomRepository,
    this._tenantRepository, {
    RepositoryManager? repositoryManager,
  }) : _repositoryManager = repositoryManager;

  AsyncValue<List<Room>> get roomsState => _roomsState;

  // Convenience getters
  List<Room> get rooms => _roomsState.when(
        loading: () => [],
        error: (_) => [],
        success: (data) => data,
      );

  bool get isLoading => _roomsState.isLoading;
  bool get hasError => _roomsState.hasError;
  Object? get error => _roomsState.error;

  Future<void> load() async {
    try {
      _roomsState = AsyncValue.loading(_roomsState.data);
      notifyListeners();

      final rooms = _roomRepository.getAllRooms();
      _roomsState = AsyncValue.success(rooms);
    } catch (e) {
      _roomsState = AsyncValue.error(e, _roomsState.data);
    }
    notifyListeners();
  }

  /// Sync rooms from API
  Future<void> syncRooms() async {
    _roomsState = AsyncValue.loading(_roomsState.data);
    notifyListeners();

    try {
      await _roomRepository.syncFromApi();

      // Hydrate relationships after sync
      if (_repositoryManager != null) {
        await _repositoryManager.hydrateAllRelationships();
        await _repositoryManager.saveAll();
      }

      await load();
    } catch (e) {
      _roomsState = AsyncValue.error(e, _roomsState.data);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> createRoom(Room room) async {
    try {
      _roomsState = AsyncValue.loading(_roomsState.data);
      notifyListeners();

      await _roomRepository.createRoom(room);

      if (_repositoryManager != null) {
        await _repositoryManager.hydrateAllRelationships();
        await _repositoryManager.saveAll();
      }

      final rooms = _roomRepository.getAllRooms();
      _roomsState = AsyncValue.success(rooms);
    } catch (e) {
      _roomsState = AsyncValue.error(e, _roomsState.data);
    }
    notifyListeners();
  }

  Future<void> updateRoom(Room room) async {
    try {
      _roomsState = AsyncValue.loading(_roomsState.data);
      notifyListeners();

      await _roomRepository.updateRoom(room);

      if (_repositoryManager != null) {
        await _repositoryManager.hydrateAllRelationships();
        await _repositoryManager.saveAll();
      }

      final rooms = _roomRepository.getAllRooms();
      _roomsState = AsyncValue.success(rooms);
    } catch (e) {
      _roomsState = AsyncValue.error(e, _roomsState.data);
    }
    notifyListeners();
  }

  Future<void> deleteRoom(String roomId) async {
    try {
      _roomsState = AsyncValue.loading(_roomsState.data);
      notifyListeners();

      await _roomRepository.deleteRoom(roomId);

      if (_repositoryManager != null) {
        await _repositoryManager.hydrateAllRelationships();
        await _repositoryManager.saveAll();
      }

      final rooms = _roomRepository.getAllRooms();
      _roomsState = AsyncValue.success(rooms);
    } catch (e) {
      _roomsState = AsyncValue.error(e, _roomsState.data);
    }
    notifyListeners();
  }

  /// Add tenant to room (cross-repository operation)
  Future<void> addTenantToRoom(String roomId, Tenant tenant) async {
    try {
      _roomsState = AsyncValue.loading(_roomsState.data);
      notifyListeners();

      final room = rooms.firstWhere((r) => r.id == roomId);

      tenant.room = room;
      await _tenantRepository.updateTenant(tenant);

      room.tenant = tenant;
      room.roomStatus = RoomStatus.occupied;
      await _roomRepository.updateRoom(room);

      if (_repositoryManager != null) {
        await _repositoryManager.hydrateAllRelationships();
        await _repositoryManager.saveAll();
      }

      final updatedRooms = _roomRepository.getAllRooms();
      _roomsState = AsyncValue.success(updatedRooms);
    } catch (e) {
      _roomsState = AsyncValue.error(e, _roomsState.data);
    }
    notifyListeners();
  }

  /// Remove tenant from room (cross-repository operation)
  Future<void> removeTenantFromRoom(String roomId) async {
    try {
      _roomsState = AsyncValue.loading(_roomsState.data);
      notifyListeners();

      final room = rooms.firstWhere((r) => r.id == roomId);
      final tenant = room.tenant;

      if (tenant != null) {
        await _tenantRepository.removeRoom(tenant.id);

        room.tenant = null;
        room.roomStatus = RoomStatus.available;
        await _roomRepository.updateRoom(room);

        if (_repositoryManager != null) {
          await _repositoryManager.hydrateAllRelationships();
          await _repositoryManager.saveAll();
        }
      }

      final updatedRooms = _roomRepository.getAllRooms();
      _roomsState = AsyncValue.success(updatedRooms);
    } catch (e) {
      _roomsState = AsyncValue.error(e, _roomsState.data);
    }
    notifyListeners();
  }

  Future<void> updateRoomStatus(String roomId, RoomStatus status) async {
    try {
      _roomsState = AsyncValue.loading(_roomsState.data);
      notifyListeners();

      await _roomRepository.updateRoomStatus(roomId, status);

      if (_repositoryManager != null) {
        await _repositoryManager.hydrateAllRelationships();
        await _repositoryManager.saveAll();
      }

      final updatedRooms = _roomRepository.getAllRooms();
      _roomsState = AsyncValue.success(updatedRooms);
    } catch (e) {
      _roomsState = AsyncValue.error(e, _roomsState.data);
    }
    notifyListeners();
  }

  List<Room> getAvailableRooms() {
    return _roomRepository.getAvailableRooms();
  }

  List<Room> getThisBuildingRooms(String buildingId) {
    return _roomRepository.getThisBuildingRooms(buildingId);
  }

  void clearError() {
    if (_roomsState.hasError && _roomsState.data != null) {
      _roomsState = AsyncValue.success(_roomsState.data!);
      notifyListeners();
    }
  }
}
