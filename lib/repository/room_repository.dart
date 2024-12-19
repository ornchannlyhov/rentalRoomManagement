import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:receipts_v2/model/client.dart';
import 'package:receipts_v2/model/enum/room_status.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:receipts_v2/model/room.dart';

class RoomRepository {
  final String filePath = 'data/rooms.json';
  final String storageKey = 'roomData';

  List<Room> _roomCache = [];

  Future<void> _loadFromAsset() async {
    try {
      final String jsonString = await rootBundle.loadString('data/rooms.json');
      final List<dynamic> jsonData = jsonDecode(jsonString);
      _roomCache = jsonData.map((roomJson) => Room.fromJson(roomJson)).toList();
    } catch (e) {
      throw Exception('Failed to load room data from asset: $e');
    }
  }

  Future<void> _loadFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(storageKey);
      if (jsonString == null || jsonString.isEmpty) {
        _roomCache = [];
        return;
      }
      final List<dynamic> jsonData = jsonDecode(jsonString);
      _roomCache = jsonData.map((roomJson) => Room.fromJson(roomJson)).toList();
    } catch (e) {
      throw Exception('Failed to load room data from SharedPreferences: $e');
    }
  }

  Future<void> _loadFromFile() async {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        final jsonString = await file.readAsString();
        final List<dynamic> jsonData = jsonDecode(jsonString);
        _roomCache =
            jsonData.map((roomJson) => Room.fromJson(roomJson)).toList();
      } else {
        await _loadFromAsset();
        await save();
      }
    } catch (e) {
      throw Exception('Failed to load room data from file: $e');
    }
  }

  Future<void> _saveToFile() async {
    try {
      final file = File(filePath);
      final jsonString =
          jsonEncode(_roomCache.map((room) => room.toJson()).toList());
      await file.writeAsString(jsonString);
    } catch (e) {
      throw Exception('Failed to save room data to file: $e');
    }
  }

  Future<void> _saveToSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      prefs.setString(storageKey,
          jsonEncode(_roomCache.map((room) => room.toJson()).toList()));
    } catch (e) {
      throw Exception('Failed to save room data to SharedPreferences: $e');
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
    if (_roomCache.isEmpty) {
      await _loadFromAsset();
      await save();
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

  Future<void> updateToOccupied(String roomId) async {
    final room = _roomCache.firstWhere((room) => room.id == roomId);
    room.roomStatus = RoomStatus.occupied;
    updateRoom(room);
  }

  Future<void> updateToAvailable(String roomId) async {
    final room = _roomCache.firstWhere((room) => room.id == roomId);
    room.roomStatus = RoomStatus.available;
    updateRoom(room);
  }

  Future<void> addClient(String roomId, Client client) async {
    final room = _roomCache.firstWhere((room) => room.id == roomId);
    room.client = client;
    updateRoom(room);
  }

  Future<void> removeClient(String roomId) async {
    final room = _roomCache.firstWhere((room) => room.id == roomId);
    room.client = null;
    updateRoom(room);
  }

  List<Room> getAllRooms() {
    return List.from(_roomCache);
  }

  List<Room> getAvailableRooms() {
    final availableRooms =
        _roomCache.where((room) => room.roomStatus == RoomStatus.available);
    return List.from(availableRooms);
  }

  List<Room> getThisBuildingRooms(String buildingId) {
    final rooms = _roomCache.where((room) => room.building!.id == buildingId);
    return List.from(rooms);
  }
}
