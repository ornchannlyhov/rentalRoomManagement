import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:receipts_v2/model/service.dart';

class ServiceRepository {
  final String filePath = 'data/services.json';
  final String storageKey = 'serviceData';

  List<Service> _serviceCache = [];

  Future<void> _loadFromAsset() async {
    try {
      final String jsonString =
          await rootBundle.loadString('data/services.json');
      final List<dynamic> jsonData = jsonDecode(jsonString);
      _serviceCache =
          jsonData.map((serviceJson) => Service.fromJson(serviceJson)).toList();
    } catch (e) {
      throw Exception('Failed to load service data from asset: $e');
    }
  }

  Future<void> _loadFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(storageKey);
      if (jsonString == null || jsonString.isEmpty) {
        _serviceCache = [];
        return;
      }
      final List<dynamic> jsonData = jsonDecode(jsonString);
      _serviceCache =
          jsonData.map((serviceJson) => Service.fromJson(serviceJson)).toList();
    } catch (e) {
      throw Exception('Failed to load service data from SharedPreferences: $e');
    }
  }

  Future<void> _loadFromFile() async {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        final jsonString = await file.readAsString();
        final List<dynamic> jsonData = jsonDecode(jsonString);
        _serviceCache = jsonData
            .map((serviceJson) => Service.fromJson(serviceJson))
            .toList();
      } else {
        await _loadFromAsset();
        await save();
      }
    } catch (e) {
      throw Exception('Failed to load service data from file: $e');
    }
  }

  Future<void> _saveToFile() async {
    try {
      final file = File(filePath);
      final jsonString =
          jsonEncode(_serviceCache.map((service) => service.toJson()).toList());
      await file.writeAsString(jsonString);
    } catch (e) {
      throw Exception('Failed to save service data to file: $e');
    }
  }

  Future<void> _saveToSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      prefs.setString(
          storageKey,
          jsonEncode(
              _serviceCache.map((service) => service.toJson()).toList()));
    } catch (e) {
      throw Exception('Failed to save service data to SharedPreferences: $e');
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

    if (_serviceCache.isEmpty) {
      await _loadFromAsset();
      await save();
    }
  }

  Future<void> createService(Service newService) async {
    _serviceCache.add(newService);
    await save();
  }

  Future<void> updateService(Service updatedService) async {
    final index =
        _serviceCache.indexWhere((service) => service.id == updatedService.id);
    if (index != -1) {
      _serviceCache[index] = updatedService;
      await save();
    } else {
      throw Exception('Service not found: ${updatedService.id}');
    }
  }

  Future<void> deleteService(String serviceId) async {
    _serviceCache.removeWhere((service) => service.id == serviceId);
    await save();
  }

  Future<void> restoreService(int restoreIndex, Service service) async {
    _serviceCache.insert(restoreIndex, service);
    await save();
  }

  List<Service> getAllServices() {
    return List.from(_serviceCache);
  }
}
