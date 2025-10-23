import 'package:flutter/material.dart';
import 'package:receipts_v2/helpers/asyn_value.dart';
import 'package:receipts_v2/data/models/tenant.dart';
import 'package:receipts_v2/data/repositories/tenant_repository.dart';

class TenantProvider extends ChangeNotifier {
  final TenantRepository _repository;

  TenantProvider(this._repository);

  AsyncValue<List<Tenant>> _tenants = const AsyncValue.loading();
  AsyncValue<List<Tenant>> get tenants => _tenants;

  String? get errorMessage => _tenants.when(
        loading: () => null,
        success: (_) => null,
        error: (error) => error.toString(),
      );

  bool get isLoading => _tenants.isLoading;
  bool get hasData => _tenants.hasData;
  bool get hasError => _tenants.hasError;

  Future<void> load() async {
    _tenants = const AsyncValue.loading();
    notifyListeners();

    try {
      await _repository.load();
      final data = _repository.getAllTenants();
      _tenants = AsyncValue.success(data);
    } catch (e) {
      _tenants = AsyncValue.error(e);
    }
    notifyListeners();
  }

  Future<void> syncFromApi({String? roomId, String? search}) async {
    _tenants = const AsyncValue.loading();
    notifyListeners();

    try {
      await _repository.syncFromApi(roomId: roomId, search: search);
      final data = _repository.getAllTenants();
      _tenants = AsyncValue.success(data);
    } catch (e) {
      _tenants = AsyncValue.error(e);
    }
    notifyListeners();
  }

  Future<Tenant> createTenant(Tenant tenant) async {
    try {
      final created = await _repository.createTenant(
        name: tenant.name,
        phoneNumber: tenant.phoneNumber,
        gender: tenant.gender,
        roomId: tenant.room?.id,
      );
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
      final updated = await _repository.updateTenant(
        id: tenant.id,
        name: tenant.name,
        phoneNumber: tenant.phoneNumber,
        gender: tenant.gender,
        roomId: tenant.room?.id,
      );
      await load();
      return updated;
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

  Future<void> restoreTenant(int restoreIndex, Tenant tenant) async {
    try {
      await _repository.restoreTenant(restoreIndex, tenant);
      final data = _repository.getAllTenants();
      _tenants = AsyncValue.success(data);
      notifyListeners();
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

  List<Tenant> getTenantsByRoom(String roomId) {
    if (_tenants.hasData) {
      return _repository.getTenantsByRoom(roomId);
    }
    return [];
  }

  List<Tenant> getTenantsByBuilding(String buildingId) {
    if (_tenants.hasData) {
      return _repository.getTenantsByBuilding(buildingId);
    }
    return [];
  }

  int get tenantCount => _tenants.hasData ? _tenants.data!.length : 0;

  Future<void> refresh({String? roomId, String? search}) async {
    await syncFromApi(roomId: roomId, search: search);
  }

  List<Tenant> searchTenants(String query) {
    if (_tenants.hasData) {
      return _repository.searchTenants(query);
    }
    return [];
  }

  void clearError() {
    if (_tenants.hasError) {
      _tenants = AsyncValue.success(_repository.getAllTenants());
      notifyListeners();
    }
  }
}
