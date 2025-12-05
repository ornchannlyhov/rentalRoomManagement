import 'package:flutter/material.dart';
import 'package:joul_v2/data/models/tenant.dart';
import 'package:joul_v2/data/repositories/tenant_repository.dart';
import 'package:joul_v2/core/helpers/repository_manager.dart';
import 'package:joul_v2/core/helpers/asyn_value.dart';

class TenantProvider with ChangeNotifier {
  final TenantRepository _tenantRepository;
  final RepositoryManager? _repositoryManager;

  AsyncValue<List<Tenant>> _tenantsState = const AsyncValue.loading();

  TenantProvider(
    this._tenantRepository, {
    RepositoryManager? repositoryManager,
  }) : _repositoryManager = repositoryManager;

  AsyncValue<List<Tenant>> get tenantsState => _tenantsState;

  // Convenience getters
  List<Tenant> get tenants => _tenantsState.when(
        loading: () => [],
        error: (_) => [],
        success: (data) => data,
      );

  bool get isLoading => _tenantsState.isLoading;
  bool get hasError => _tenantsState.hasError;
  Object? get error => _tenantsState.error;

  Future<void> load() async {
    try {
      _tenantsState = AsyncValue.loading(_tenantsState.data);
      notifyListeners();

      final tenants = _tenantRepository.getAllTenants();
      _tenantsState = AsyncValue.success(tenants);
    } catch (e) {
      _tenantsState = AsyncValue.error(e, _tenantsState.data);
    }
    notifyListeners();
  }

  /// Sync tenants from API
  Future<void> syncTenants() async {
    // Only show loading state if we don't have data yet
    final hasData = _tenantsState.data != null;
    if (!hasData) {
      _tenantsState = AsyncValue.loading(_tenantsState.data);
      notifyListeners();
    }

    try {
      await _tenantRepository.syncFromApi();

      // Hydrate relationships after sync
      if (_repositoryManager != null) {
        await _repositoryManager.hydrateAllRelationships();
        await _repositoryManager.saveAll();
      }

      final tenants = _tenantRepository.getAllTenants();
      _tenantsState = AsyncValue.success(tenants);
      notifyListeners();
    } catch (e) {
      // Don't set error state - just rethrow and let the screen handle fallback
      // This prevents the error state flicker when falling back to local data
      rethrow;
    }
  }

  Future<void> createTenant(Tenant tenant) async {
    try {
      await _tenantRepository.createTenant(tenant);

      if (_repositoryManager != null) {
        await _repositoryManager.hydrateAllRelationships();
        await _repositoryManager.saveAll();
      }

      final tenants = _tenantRepository.getAllTenants();
      _tenantsState = AsyncValue.success(tenants);
      notifyListeners();
    } catch (e) {
      _tenantsState = AsyncValue.error(e, _tenantsState.data);
      notifyListeners();
      rethrow; // Propagate error to caller
    }
  }

  Future<void> updateTenant(Tenant tenant) async {
    try {
      await _tenantRepository.updateTenant(tenant);

      if (_repositoryManager != null) {
        await _repositoryManager.hydrateAllRelationships();
        await _repositoryManager.saveAll();
      }

      final tenants = _tenantRepository.getAllTenants();
      _tenantsState = AsyncValue.success(tenants);
      notifyListeners();
    } catch (e) {
      _tenantsState = AsyncValue.error(e, _tenantsState.data);
      notifyListeners();
      rethrow; // Propagate error to caller
    }
  }

  Future<void> deleteTenant(String tenantId) async {
    try {
      await _tenantRepository.deleteTenant(tenantId);

      if (_repositoryManager != null) {
        await _repositoryManager.hydrateAllRelationships();
        await _repositoryManager.saveAll();
      }

      final tenants = _tenantRepository.getAllTenants();
      _tenantsState = AsyncValue.success(tenants);
      notifyListeners();
    } catch (e) {
      _tenantsState = AsyncValue.error(e, _tenantsState.data);
      notifyListeners();
      rethrow; // Propagate error to caller
    }
  }

  Future<void> removeRoom(String tenantId) async {
    try {
      await _tenantRepository.removeRoom(tenantId);

      if (_repositoryManager != null) {
        await _repositoryManager.hydrateAllRelationships();
        await _repositoryManager.saveAll();
      }

      final tenants = _tenantRepository.getAllTenants();
      _tenantsState = AsyncValue.success(tenants);
      notifyListeners();
    } catch (e) {
      _tenantsState = AsyncValue.error(e, _tenantsState.data);
      notifyListeners();
    }
  }

  List<Tenant> getTenantsByBuilding(String buildingId) {
    return _tenantRepository.getTenantsByBuilding(buildingId);
  }

  List<Tenant> searchTenants(String query) {
    return _tenantRepository.searchTenants(query);
  }

  void clearError() {
    if (_tenantsState.hasError && _tenantsState.data != null) {
      _tenantsState = AsyncValue.success(_tenantsState.data!);
      notifyListeners();
    }
  }
}
