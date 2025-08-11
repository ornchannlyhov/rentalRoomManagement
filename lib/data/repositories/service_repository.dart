import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:receipts_v2/data/models/service.dart';

class ServiceRepository {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String storageKey = 'service_secure_data';

  List<Service> _serviceCache = [];

  Future<void> load() async {
    try {
      final jsonString = await _secureStorage.read(key: storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonData = jsonDecode(jsonString);
        _serviceCache = jsonData.map((e) => Service.fromJson(e)).toList();
      } else {
        _serviceCache = [];
      }
    } catch (e) {
      throw Exception('Failed to load service data from secure storage: $e');
    }
  }

  Future<void> save() async {
    try {
      final jsonString =
          jsonEncode(_serviceCache.map((s) => s.toJson()).toList());
      await _secureStorage.write(key: storageKey, value: jsonString);
    } catch (e) {
      throw Exception('Failed to save service data to secure storage: $e');
    }
  }

  Future<void> createService(Service newService) async {
    _serviceCache.add(newService);
    await save();
  }

  Future<void> updateService(Service updatedService) async {
    final index = _serviceCache.indexWhere((s) => s.id == updatedService.id);
    if (index != -1) {
      _serviceCache[index] = updatedService;
      await save();
    } else {
      throw Exception('Service not found: ${updatedService.id}');
    }
  }

  Future<void> deleteService(String serviceId) async {
    _serviceCache.removeWhere((s) => s.id == serviceId);
    await save();
  }

  Future<void> restoreService(int restoreIndex, Service service) async {
    _serviceCache.insert(restoreIndex, service);
    await save();
  }

  List<Service> getAllServices() {
    return List.unmodifiable(_serviceCache);
  }
}
