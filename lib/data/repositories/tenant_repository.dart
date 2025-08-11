import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:receipts_v2/data/models/tenant.dart';

class TenantRepository {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String storageKey = 'tenant_secure_data';

  List<Tenant> _tenantCache = [];

  Future<void> load() async {
    try {
      final jsonString = await _secureStorage.read(key: storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonData = jsonDecode(jsonString);
        _tenantCache = jsonData.map((json) => Tenant.fromJson(json)).toList();
      } else {
        _tenantCache = [];
      }
    } catch (e) {
      throw Exception('Failed to load tenant data from secure storage: $e');
    }
  }

  Future<void> save() async {
    try {
      final jsonString = jsonEncode(
        _tenantCache.map((tenant) => tenant.toJson()).toList(),
      );
      await _secureStorage.write(key: storageKey, value: jsonString);
    } catch (e) {
      throw Exception('Failed to save tenant data to secure storage: $e');
    }
  }

  Future<void> createTenant(Tenant newTenant) async {
    _tenantCache.add(newTenant);
    await save();
  }

  Future<void> updateTenant(Tenant updateTenant) async {
    final index = _tenantCache.indexWhere((t) => t.id == updateTenant.id);
    if (index != -1) {
      _tenantCache[index] = updateTenant;
      await save();
    } else {
      throw Exception('Tenant not found: ${updateTenant.id}');
    }
  }

  Future<void> restoreTenant(int restoreIndex, Tenant tenant) async {
    _tenantCache.insert(restoreIndex, tenant);
    await save();
  }

  Future<void> removeRoom(String tenantId) async {
    final tenant = _tenantCache.firstWhere(
      (tenant) => tenant.id == tenantId,
      orElse: () => throw Exception('Tenant not found: $tenantId'),
    );
    tenant.room = null;
    await updateTenant(tenant);
  }

  Future<void> deleteTenant(String tenantId) async {
    _tenantCache.removeWhere((tenant) => tenant.id == tenantId);
    await save();
  }

  List<Tenant> getAllTenant() {
    return List.unmodifiable(_tenantCache);
  }
}
