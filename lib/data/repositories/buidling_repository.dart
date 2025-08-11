import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:receipts_v2/data/models/building.dart';
import 'package:receipts_v2/data/models/room.dart';

class BuildingRepository {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String storageKey = 'building_secure_data';

  List<Building> _buildingCache = [];

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
      final jsonString = jsonEncode(
        _buildingCache.map((b) => b.toJson()).toList(),
      );
      await _secureStorage.write(key: storageKey, value: jsonString);
    } catch (e) {
      throw Exception('Failed to save building data to secure storage: $e');
    }
  }

  Future<void> createBuilding(Building newBuilding) async {
    _buildingCache.add(newBuilding);
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
    _buildingCache.removeWhere((b) => b.id == buildingId);
    await save();
  }

  Future<void> updateRoom(String buildingId, Room room) async {
    final building = _buildingCache.firstWhere((b) => b.id == buildingId,
        orElse: () => throw Exception('Building not found'));
    final roomIndex = building.rooms.indexWhere((r) => r.id == room.id);
    if (roomIndex != -1) {
      building.rooms[roomIndex] = room;
      await save();
    } else {
      throw Exception('Room not found in building: ${room.id}');
    }
  }

  List<Building> getAllBuildings() {
    return List.unmodifiable(_buildingCache);
  }
}
