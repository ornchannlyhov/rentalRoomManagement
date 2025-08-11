import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:receipts_v2/data/models/tenant.dart';
import 'package:receipts_v2/data/models/enum/room_status.dart';
import 'package:receipts_v2/data/models/room.dart';

class RoomRepository {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String storageKey = 'room_secure_data';

  List<Room> _roomCache = [];

  Future<void> load() async {
    try {
      final jsonString = await _secureStorage.read(key: storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonData = jsonDecode(jsonString);
        _roomCache = jsonData.map((json) => Room.fromJson(json)).toList();
      } else {
        _roomCache = [];
      }
    } catch (e) {
      throw Exception('Failed to load room data from secure storage: $e');
    }
  }

  Future<void> save() async {
    try {
      final jsonString =
          jsonEncode(_roomCache.map((room) => room.toJson()).toList());
      await _secureStorage.write(key: storageKey, value: jsonString);
    } catch (e) {
      throw Exception('Failed to save room data to secure storage: $e');
    }
  }

  Future<void> createRoom(Room newRoom) async {
    _roomCache.add(newRoom);
    await save();
  }

  Future<void> updateRoom(Room updatedRoom) async {
    final index = _roomCache.indexWhere((room) => room.id == updatedRoom.id);
    if (index != -1) {
      _roomCache[index] = updatedRoom;
      await save();
    } else {
      throw Exception('Room not found: ${updatedRoom.id}');
    }
  }

  Future<void> deleteRoom(String roomId) async {
    _roomCache.removeWhere((room) => room.id == roomId);
    await save();
  }

  Future<void> restoreRoom(int restoreIndex, Room room) async {
    _roomCache.insert(restoreIndex, room);
    await save();
  }

Future<void> updateRoomStatus(String roomId, RoomStatus status) async {
  final room = _roomCache.firstWhere((room) => room.id == roomId);
  room.roomStatus = status;
  await updateRoom(room);
}

  Future<void> addTenant(String roomId, Tenant tenant) async {
    final room = _roomCache.firstWhere((room) => room.id == roomId);
    room.tenant = tenant;
    await updateRoom(room);
  }

  Future<void> removeTenant(String roomId) async {
    final room = _roomCache.firstWhere((room) => room.id == roomId);
    room.tenant = null;
    await updateRoom(room);
  }

  List<Room> getAllRooms() {
    return List.unmodifiable(_roomCache);
  }

  List<Room> getAvailableRooms() {
    return _roomCache
        .where((room) => room.roomStatus == RoomStatus.available)
        .toList();
  }

  List<Room> getThisBuildingRooms(String buildingId) {
    return _roomCache.where((room) => room.building?.id == buildingId).toList();
  }
}
