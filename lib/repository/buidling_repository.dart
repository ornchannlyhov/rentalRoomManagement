import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:receipts_v2/model/room.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:receipts_v2/model/building.dart';

class BuildingRepository {
  final String filePath = 'data/buildings.json';
  final String storageKey = 'buildingData';

  List<Building> _buildingCache = [];

  Future<void> _loadFromAsset() async {
    try {
      final String jsonString =
          await rootBundle.loadString('data/buildings.json');
      final List<dynamic> jsonData = jsonDecode(jsonString);
      _buildingCache = jsonData
          .map((buildingJson) => Building.fromJson(buildingJson))
          .toList();
    } catch (e) {
      throw Exception('Failed to load building data from asset: $e');
    }
  }

  Future<void> _loadFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(storageKey);
      if (jsonString == null || jsonString.isEmpty) {
        _buildingCache = [];
        return;
      }
      final List<dynamic> jsonData = jsonDecode(jsonString);
      _buildingCache = jsonData
          .map((buildingJson) => Building.fromJson(buildingJson))
          .toList();
    } catch (e) {
      throw Exception(
          'Failed to load building data from SharedPreferences: $e');
    }
  }

  Future<void> _loadFromFile() async {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        final jsonString = await file.readAsString();
        final List<dynamic> jsonData = jsonDecode(jsonString);
        _buildingCache = jsonData
            .map((buildingJson) => Building.fromJson(buildingJson))
            .toList();
      } else {
        await _loadFromAsset();
        await save();
      }
    } catch (e) {
      throw Exception('Failed to load building data from file: $e');
    }
  }

  Future<void> _saveToFile() async {
    try {
      final file = File(filePath);
      final jsonString = jsonEncode(
          _buildingCache.map((building) => building.toJson()).toList());
      await file.writeAsString(jsonString);
    } catch (e) {
      throw Exception('Failed to save building data to file: $e');
    }
  }

  Future<void> _saveToSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      prefs.setString(
          storageKey,
          jsonEncode(
              _buildingCache.map((building) => building.toJson()).toList()));
    } catch (e) {
      throw Exception('Failed to save building data to SharedPreferences: $e');
    }
  }

  Future<void> save() async {
    if (kIsWeb) {
      await _saveToSharedPreferences();
    } else {
      await _saveToFile();
      await _saveToSharedPreferences();
    }
  }

  Future<void> load() async {
    if (kIsWeb) {
      await _loadFromSharedPreferences();
    } else {
      await _loadFromFile();
    }

    if (_buildingCache.isEmpty) {
      await _loadFromAsset();
      await save();
    }
  }

  Future<void> createBuilding(Building newBuilding) async {
    _buildingCache.add(newBuilding);
    await save();
  }

  Future<void> updateBuilding(Building updatedBuilding) async {
    final index = _buildingCache
        .indexWhere((building) => building.id == updatedBuilding.id);
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
    _buildingCache.removeWhere((building) => building.id == buildingId);
    await save();
  }


  Future<void> updateRoom(String buildingId, Room room) async {
    Building? building = _buildingCache.firstWhere(
      (building) => building.id == buildingId,
    );
    final index = building.rooms.indexWhere((r) => r.id == room.id);
    if (index != -1) {
      building.rooms[index] = room;
      await save();
    } else {
      throw Exception(
          'Room with ID ${room.id} not found in building $buildingId');
    }
  }

  List<Building> getAllBuildings() {
    return List.from(_buildingCache);
  }
}
