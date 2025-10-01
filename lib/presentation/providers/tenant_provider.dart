import 'package:flutter/material.dart';
import 'package:receipts_v2/core/asyn_value.dart';
import 'package:receipts_v2/data/models/tenant.dart';
import 'package:receipts_v2/data/repositories/tenant_repository.dart';

class TenantProvider extends ChangeNotifier {
  final TenantRepository _repository;

  TenantProvider(this._repository);

  AsyncValue<List<Tenant>> _tenants = const AsyncValue.loading();
  AsyncValue<List<Tenant>> get tenants => _tenants;

  String? get errorMessage {
    return _tenants.when(
      loading: () => null,
      success: (_) => null,
      error: (error) => error.toString(),
    );
  }

  bool get isLoading => _tenants.isLoading;
  bool get hasData => _tenants.hasData;
  bool get hasError => _tenants.hasError;

  Future<void> load({String? roomId, String? search}) async {
    _tenants = const AsyncValue.loading();
    notifyListeners();

    try {
      await _repository.load(roomId: roomId, search: search);
      final data = _repository.getAllTenant();
      _tenants = AsyncValue.success(data);
    } catch (e) {
      _tenants = AsyncValue.error(e);
    }
    notifyListeners();
  }

  Future<Tenant> createTenant(Tenant tenant) async {
    try {
      final created = await _repository.createTenant(tenant);
      await load();
      return created;
    } catch (e) {
      _tenants = AsyncValue.error(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<Tenant> updateTenant(Tenant tenant) async {
    try {
      final updated = await _repository.updateTenant(tenant);
      await load();
      return updated;
    } catch (e) {
      _tenants = AsyncValue.error(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> removeRoom(String tenantId) async {
    try {
      await _repository.removeRoom(tenantId);
      await load();
    } catch (e) {
      _tenants = AsyncValue.error(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteTenant(String tenantId) async {
    try {
      await _repository.deleteTenant(tenantId);
      await load();
    } catch (e) {
      _tenants = AsyncValue.error(e);
      notifyListeners();
      rethrow;
    }
  }

  Tenant? getTenantById(String tenantId) {
    if (_tenants.hasData) {
      return _repository.getTenantById(tenantId);
    }
    return null;
  }

  List<Tenant> getTenantsByBuilding(String buildingId) {
    if (_tenants.hasData) {
      return _repository.getTenantsByBuilding(buildingId);
    }
    return [];
  }

  List<Tenant> getTenantsByRoom(String roomId) {
    if (_tenants.hasData) {
      return _repository.getTenantsByRoom(roomId);
    }
    return [];
  }

  List<Tenant> searchTenants(String query) {
    if (_tenants.hasData) {
      return _repository.searchTenants(query);
    }
    return [];
  }

  int get tenantCount {
    if (_tenants.hasData) {
      return _tenants.data!.length;
    }
    return 0;
  }

  Future<void> refresh({String? roomId, String? search}) async {
    await load(roomId: roomId, search: search);
  }

  void clearError() {
    if (_tenants.hasError) {
      _tenants = AsyncValue.success(_repository.getAllTenant());
      notifyListeners();
    }
  }
}
