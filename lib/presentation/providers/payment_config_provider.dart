import 'package:flutter/material.dart';
import 'package:joul_v2/data/models/payment_config.dart';
import 'package:joul_v2/data/repositories/payment_config_repository.dart';
import 'package:joul_v2/core/helpers/asyn_value.dart';
import 'package:joul_v2/core/helpers/repository_manager.dart';

class PaymentConfigProvider with ChangeNotifier {
  final PaymentConfigRepository _paymentConfigRepository;
  final RepositoryManager? _repositoryManager;

  AsyncValue<PaymentConfig?> _configState = const AsyncValue.loading();

  PaymentConfigProvider(
    this._paymentConfigRepository, {
    RepositoryManager? repositoryManager,
  }) : _repositoryManager = repositoryManager;

  AsyncValue<PaymentConfig?> get configState => _configState;

  // Convenience getters
  PaymentConfig? get config => _configState.bestData;
  bool get isLoading => _configState.isLoading;
  bool get hasError => _configState.hasError;
  Object? get error => _configState.error;
  bool get hasConfig => _paymentConfigRepository.hasPaymentConfig();

  Future<void> load() async {
    try {
      final config = _paymentConfigRepository.getPaymentConfig();
      _configState = AsyncValue.success(config);
    } catch (e) {
      _configState = AsyncValue.error(e, _configState.bestData);
    } finally {
      notifyListeners();
    }
  }

  /// Sync payment config from API
  Future<void> syncPaymentConfig() async {
    _configState = AsyncValue.loading(_configState.bestData);
    notifyListeners();

    try {
      await _paymentConfigRepository.syncFromApi();

      if (_repositoryManager != null) {
        await _repositoryManager.hydrateAllRelationships();
        await _repositoryManager.saveAll();
      }

      await load();
    } catch (e) {
      _configState = AsyncValue.error(e, _configState.bestData);
      notifyListeners();
      rethrow;
    }
  }

  /// Setup initial payment configuration
  Future<void> setupPaymentConfig({
    required String paymentMethod,
    String? bankName,
    String? bankAccountNumber,
    String? bankAccountName,
    bool enableKhqr = false,
    bool enableAbaPayWay = false,
  }) async {
    _configState = AsyncValue.loading(_configState.bestData);
    notifyListeners();

    try {
      final configData = {
        'paymentMethod': paymentMethod,
        if (bankName != null) 'bankName': bankName,
        if (bankAccountNumber != null) 'bankAccountNumber': bankAccountNumber,
        if (bankAccountName != null) 'bankAccountName': bankAccountName,
        'enableKhqr': enableKhqr,
        'enableAbaPayWay': enableAbaPayWay,
      };

      await _paymentConfigRepository.setupPaymentConfig(configData);

      if (_repositoryManager != null) {
        await _repositoryManager.hydrateAllRelationships();
        await _repositoryManager.saveAll();
      }

      await load();
    } catch (e) {
      _configState = AsyncValue.error(e, _configState.bestData);
      notifyListeners();
      rethrow;
    }
  }

  /// Update existing payment configuration
  Future<void> updatePaymentConfig({
    String? paymentMethod,
    String? bankName,
    String? bankAccountNumber,
    String? bankAccountName,
    bool? enableKhqr,
    bool? enableAbaPayWay,
  }) async {
    _configState = AsyncValue.loading(_configState.bestData);
    notifyListeners();

    try {
      final configData = <String, dynamic>{};
      
      if (paymentMethod != null) configData['paymentMethod'] = paymentMethod;
      if (bankName != null) configData['bankName'] = bankName;
      if (bankAccountNumber != null) {
        configData['bankAccountNumber'] = bankAccountNumber;
      }
      if (bankAccountName != null) {
        configData['bankAccountName'] = bankAccountName;
      }
      if (enableKhqr != null) configData['enableKhqr'] = enableKhqr;
      if (enableAbaPayWay != null) {
        configData['enableAbaPayWay'] = enableAbaPayWay;
      }

      await _paymentConfigRepository.updatePaymentConfig(configData);

      if (_repositoryManager != null) {
        await _repositoryManager.hydrateAllRelationships();
        await _repositoryManager.saveAll();
      }

      await load();
    } catch (e) {
      _configState = AsyncValue.error(e, _configState.bestData);
      notifyListeners();
      rethrow;
    }
  }
}