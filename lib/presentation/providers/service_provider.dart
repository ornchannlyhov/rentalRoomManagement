import 'package:flutter/material.dart';
import 'package:receipts_v2/core/asyn_value.dart';
import 'package:receipts_v2/data/models/service.dart';
import 'package:receipts_v2/data/repositories/service_repository.dart';

class ServiceProvider extends ChangeNotifier {
  final ServiceRepository _repository;

  ServiceProvider(this._repository);

  AsyncValue<List<Service>> _services = const AsyncValue.loading();
  AsyncValue<List<Service>> get services => _services;

  String? get errorMessage {
    return _services.when(
      loading: () => null,
      success: (_) => null,
      error: (error) => error.toString(),
    );
  }

  bool get isLoading => _services.isLoading;
  bool get hasData => _services.hasData;
  bool get hasError => _services.hasError;

  Future<void> load() async {
    _services = const AsyncValue.loading();
    notifyListeners();

    try {
      await _repository.load();
      final data = _repository.getAllServices();
      _services = AsyncValue.success(data);
    } catch (e) {
      _services = AsyncValue.error(e);
    }
    notifyListeners();
  }

  Future<void> syncFromApi() async {
    _services = const AsyncValue.loading();
    notifyListeners();

    try {
      await _repository.syncFromApi();
      final data = _repository.getAllServices();
      _services = AsyncValue.success(data);
    } catch (e) {
      _services = AsyncValue.error(e);
    }
    notifyListeners();
  }

  Future<Service> createService(Service service) async {
    try {
      await _repository.createService(service);
      await load();
      return service;
    } catch (e) {
      _services = AsyncValue.error(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<Service> updateService(Service service) async {
    try {
      await _repository.updateService(service);
      await load();
      return service;
    } catch (e) {
      _services = AsyncValue.error(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteService(String serviceId) async {
    try {
      await _repository.deleteService(serviceId);
      await load();
    } catch (e) {
      _services = AsyncValue.error(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> restoreService(int restoreIndex, Service service) async {
    try {
      await _repository.restoreService(restoreIndex, service);
      final data = _repository.getAllServices();
      _services = AsyncValue.success(data);
      notifyListeners();
    } catch (e) {
      _services = AsyncValue.error(e);
      notifyListeners();
      rethrow;
    }
  }

  List<Service> getServicesByBuilding(String buildingId) {
    if (_services.hasData) {
      return _repository.getServicesByBuilding(buildingId);
    }
    return [];
  }

  int get serviceCount {
    if (_services.hasData) {
      return _services.data!.length;
    }
    return 0;
  }

  Future<void> refresh() async {
    await syncFromApi();
  }

  void clearError() {
    if (_services.hasError) {
      _services = AsyncValue.success(_repository.getAllServices());
      notifyListeners();
    }
  }
}
