// ServiceProvider - With AsyncValue State Management

import 'package:flutter/material.dart';
import 'package:joul_v2/data/models/service.dart';
import 'package:joul_v2/data/repositories/service_repository.dart';
import 'package:joul_v2/core/helpers/repository_manager.dart';
import 'package:joul_v2/core/helpers/asyn_value.dart';

class ServiceProvider with ChangeNotifier {
  final ServiceRepository _serviceRepository;
  final RepositoryManager? _repositoryManager;

  AsyncValue<List<Service>> _servicesState = const AsyncValue.loading();

  ServiceProvider(
    this._serviceRepository, {
    RepositoryManager? repositoryManager,
  }) : _repositoryManager = repositoryManager;

  AsyncValue<List<Service>> get servicesState => _servicesState;

  // Convenience getters
  List<Service> get services => _servicesState.when(
        loading: () => [],
        error: (_) => [],
        success: (data) => data,
      );

  bool get isLoading => _servicesState.isLoading;
  bool get hasError => _servicesState.hasError;
  Object? get error => _servicesState.error;

  Future<void> load() async {
    try {
      _servicesState = AsyncValue.loading(_servicesState.data);
      notifyListeners();

      final services = _serviceRepository.getAllServices();
      _servicesState = AsyncValue.success(services);
    } catch (e) {
      _servicesState = AsyncValue.error(e, _servicesState.data);
    }
    notifyListeners();
  }

  Future<void> createService(Service service) async {
    try {
      _servicesState = AsyncValue.loading(_servicesState.data);
      notifyListeners();

      await _serviceRepository.createService(service);

      if (_repositoryManager != null) {
        await _repositoryManager.hydrateAllRelationships();
        await _repositoryManager.saveAll();
      }

      final services = _serviceRepository.getAllServices();
      _servicesState = AsyncValue.success(services);
    } catch (e) {
      _servicesState = AsyncValue.error(e, _servicesState.data);
    }
    notifyListeners();
  }

  Future<void> updateService(Service service) async {
    try {
      _servicesState = AsyncValue.loading(_servicesState.data);
      notifyListeners();

      await _serviceRepository.updateService(service);

      if (_repositoryManager != null) {
        await _repositoryManager.hydrateAllRelationships();
        await _repositoryManager.saveAll();
      }

      final services = _serviceRepository.getAllServices();
      _servicesState = AsyncValue.success(services);
    } catch (e) {
      _servicesState = AsyncValue.error(e, _servicesState.data);
    }
    notifyListeners();
  }

  Future<void> deleteService(String serviceId) async {
    try {
      _servicesState = AsyncValue.loading(_servicesState.data);
      notifyListeners();

      await _serviceRepository.deleteService(serviceId);

      if (_repositoryManager != null) {
        await _repositoryManager.hydrateAllRelationships();
        await _repositoryManager.saveAll();
      }

      final services = _serviceRepository.getAllServices();
      _servicesState = AsyncValue.success(services);
    } catch (e) {
      _servicesState = AsyncValue.error(e, _servicesState.data);
    }
    notifyListeners();
  }

  Future<void> restoreService(int index, Service service) async {
    try {
      _servicesState = AsyncValue.loading(_servicesState.data);
      notifyListeners();

      await _serviceRepository.restoreService(index, service);

      if (_repositoryManager != null) {
        await _repositoryManager.hydrateAllRelationships();
        await _repositoryManager.saveAll();
      }

      final services = _serviceRepository.getAllServices();
      _servicesState = AsyncValue.success(services);
    } catch (e) {
      _servicesState = AsyncValue.error(e, _servicesState.data);
    }
    notifyListeners();
  }

  List<Service> getServicesByBuilding(String buildingId) {
    return _serviceRepository.getServicesByBuilding(buildingId);
  }

  void clearError() {
    if (_servicesState.hasError && _servicesState.data != null) {
      _servicesState = AsyncValue.success(_servicesState.data!);
      notifyListeners();
    }
  }
}
