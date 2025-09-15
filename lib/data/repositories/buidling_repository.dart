import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:receipts_v2/data/models/building.dart';
import 'package:receipts_v2/data/models/room.dart';
import 'package:receipts_v2/data/repositories/room_repository.dart';

class BuildingRepository {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String storageKey = 'building_secure_data';
  List<Building> _buildingCache = [];

  // Add a dependency on RoomRepository
  final RoomRepository _roomRepository;

  BuildingRepository(this._roomRepository);

  Future<void> load() async {
    try {
      final jsonString = await _secureStorage.read(key: storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonData = jsonDecode(jsonString);
        _buildingCache =
            jsonData.map((json) => Building.fromJson(json)).toList();
      } else {
        _buildingCache = [];
      }
    } catch (e) {
      throw Exception('Failed to load building data from secure storage: $e');
    }
  }

  Future<void> save() async {
    try {
      final jsonString =
          jsonEncode(_buildingCache.map((b) => b.toJson()).toList());
      await _secureStorage.write(key: storageKey, value: jsonString);
    } catch (e) {
      throw Exception('Failed to save building data to secure storage: $e');
    }
  }

  Future<void> createBuilding(Building newBuilding) async {
    _buildingCache.add(newBuilding);

    // If newBuilding has rooms, save them to the RoomRepository
    if (newBuilding.rooms.isNotEmpty) {
      for (Room room in newBuilding.rooms) {
        // Ensure the room's building reference is set to the newly created building
        final roomWithBuildingRef = Room(
          id: room.id,
          roomNumber: room.roomNumber,
          roomStatus: room.roomStatus,
          price: room.price,
          building: Building(
            // Create a new Building object with just the necessary info
            id: newBuilding.id,
            name: newBuilding.name,
            rentPrice: newBuilding.rentPrice,
            electricPrice: newBuilding.electricPrice,
            waterPrice: newBuilding.waterPrice,
          ),
          tenant: room.tenant,
        );
        await _roomRepository.createRoom(roomWithBuildingRef);
      }
    }
    await save();
  }

  Future<void> updateBuilding(Building updatedBuilding) async {
    final index = _buildingCache.indexWhere((b) => b.id == updatedBuilding.id);
    if (index != -1) {
      _buildingCache[index] = updatedBuilding;
      await save();
    } else {
      throw Exception('Building not found: ${updatedBuilding.id}');
    }
  }

  Future<void> restoreBuilding(int restoreIndex, Building building) async {
    _buildingCache.insert(restoreIndex, building);
    await save();
  }

  Future<void> deleteBuilding(String buildingId) async {
    // Optionally, also delete associated rooms from RoomRepository
    final buildingToDelete =
        _buildingCache.firstWhere((b) => b.id == buildingId);
    if (buildingToDelete.rooms.isNotEmpty) {
      for (Room room in buildingToDelete.rooms) {
        await _roomRepository.deleteRoom(room.id);
      }
    }

    _buildingCache.removeWhere((b) => b.id == buildingId);
    await save();
  }

  Future<void> updateRoom(String buildingId, Room room) async {
    final building = _buildingCache.firstWhere(
      (b) => b.id == buildingId,
      orElse: () => throw Exception('Building not found'),
    );
    final roomIndex = building.rooms.indexWhere((r) => r.id == room.id);
    if (roomIndex != -1) {
      building.rooms[roomIndex] = room;
      await save();
      // Also update the room in the RoomRepository
      await _roomRepository.updateRoom(room);
    } else {
      throw Exception('Room not found in building: ${room.id}');
    }
  }

  List<Building> getAllBuildings() {
    return List.unmodifiable(_buildingCache);
  }

  bool isBuildingEmpty(String buildingId) {
    final building = _buildingCache.firstWhere(
      (b) => b.id == buildingId,
      orElse: () => throw Exception('Building not found'),
    );
    return building.rooms.isEmpty;
  }
}
