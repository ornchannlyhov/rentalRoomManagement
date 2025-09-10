import 'package:flutter/material.dart';
import 'package:receipts_v2/core/asyn_value.dart';
import 'package:receipts_v2/data/models/tenant.dart';
import 'package:receipts_v2/data/repositories/tenant_repository.dart';

class TenantProvider extends ChangeNotifier {
  final TenantRepository _repository = TenantRepository();

  AsyncValue<List<Tenant>> _tenants = const AsyncValue.loading();
  AsyncValue<List<Tenant>> get tenants => _tenants;

  Future<void> load() async {
    _tenants = const AsyncValue.loading();
    notifyListeners();

    try {
      await _repository.load();
      final data = _repository.getAllTenant();
      _tenants = AsyncValue.success(data);
    } catch (e) {
      _tenants = AsyncValue.error(e);
    }
    notifyListeners();
  }

  List<Tenant> getTenantByBuilding(String buildingId) {
    if (_tenants.hasData) {
      return _repository.getTenantsByBuilding(buildingId);
    }
    return [];
  }

  Future<void> createTenant(Tenant tenant) async {
    try {
      await _repository.createTenant(tenant);
      await load();
    } catch (e) {
      _tenants = AsyncValue.error(e);
      notifyListeners();
    }
  }

  Future<void> updateTenant(Tenant tenant) async {
    try {
      await _repository.updateTenant(tenant);
      await load();
    } catch (e) {
      _tenants = AsyncValue.error(e);
      notifyListeners();
    }
  }

  Future<void> restoreTenant(int index, Tenant tenant) async {
    try {
      await _repository.restoreTenant(index, tenant);
      await load();
    } catch (e) {
      _tenants = AsyncValue.error(e);
      notifyListeners();
    }
  }

  Future<void> removeRoom(String tenantId) async {
    try {
      await _repository.removeRoom(tenantId);
      await load();
    } catch (e) {
      _tenants = AsyncValue.error(e);
      notifyListeners();
    }
  }

  Future<void> deleteTenant(String tenantId) async {
    try {
      await _repository.deleteTenant(tenantId);
      await load();
    } catch (e) {
      _tenants = AsyncValue.error(e);
      notifyListeners();
    }
  }
}
