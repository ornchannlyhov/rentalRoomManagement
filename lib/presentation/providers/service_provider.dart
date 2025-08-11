import 'package:flutter/material.dart';
import 'package:receipts_v2/core/asyn_value.dart';
import 'package:receipts_v2/data/models/service.dart';
import 'package:receipts_v2/data/repositories/service_repository.dart';

class ServiceProvider extends ChangeNotifier {
  final ServiceRepository _repository = ServiceRepository();

  AsyncValue<List<Service>> _services = const AsyncValue.loading();
  AsyncValue<List<Service>> get services => _services;

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

  Future<void> createService(Service service) async {
    try {
      await _repository.createService(service);
      await load();
    } catch (e) {
      _services = AsyncValue.error(e);
      notifyListeners();
    }
  }

  Future<void> updateService(Service service) async {
    try {
      await _repository.updateService(service);
      await load();
    } catch (e) {
      _services = AsyncValue.error(e);
      notifyListeners();
    }
  }

  Future<void> deleteService(String serviceId) async {
    try {
      await _repository.deleteService(serviceId);
      await load();
    } catch (e) {
      _services = AsyncValue.error(e);
      notifyListeners();
    }
  }

  Future<void> restoreService(int index, Service service) async {
    try {
      await _repository.restoreService(index, service);
      await load();
    } catch (e) {
      _services = AsyncValue.error(e);
      notifyListeners();
    }
  }
}
