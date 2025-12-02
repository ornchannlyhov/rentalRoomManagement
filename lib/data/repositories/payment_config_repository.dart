import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:joul_v2/core/helpers/api_helper.dart';
import 'package:joul_v2/core/helpers/sync_operation_helper.dart';
import 'package:joul_v2/data/models/payment_config.dart';
import 'package:joul_v2/data/dtos/payment_config_dto.dart';
import 'package:joul_v2/core/services/database_service.dart';

// Top-level functions for compute() isolation

class PaymentConfigRepository {
  final DatabaseService _databaseService;
  final ApiHelper _apiHelper = ApiHelper.instance;
  final SyncOperationHelper _syncHelper = SyncOperationHelper();

  PaymentConfig? _configCache;
  List<Map<String, dynamic>> _pendingChanges = [];

  PaymentConfigRepository(this._databaseService);

  Future<void> load() async {
    try {
      final configMap = _databaseService.paymentConfigBox.get('config');
      if (configMap != null) {
        _configCache =
            PaymentConfigDto.fromJson(Map<String, dynamic>.from(configMap))
                .toPaymentConfig();
      } else {
        _configCache = null;
      }

      final pendingList = _databaseService.pendingChangesBox.values.toList();
      _pendingChanges =
          pendingList.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      throw Exception('Failed to load payment config data: $e');
    }
  }

  Future<void> save() async {
    try {
      if (_configCache != null) {
        final configDto = PaymentConfigDto(
          id: _configCache!.id,
          landlordId: _configCache!.landlordId,
          paymentMethod: _configCache!.paymentMethod,
          bankName: _configCache!.bankName,
          bankAccountNumber: _configCache!.bankAccountNumber,
          bankAccountName: _configCache!.bankAccountName,
          enableKhqr: _configCache!.enableKhqr,
          enableAbaPayWay: _configCache!.enableAbaPayWay,
        );
        await _databaseService.paymentConfigBox
            .put('config', configDto.toJson());
      }

      if (_pendingChanges.isNotEmpty) {
        await _databaseService.pendingChangesBox.clear();
        for (var i = 0; i < _pendingChanges.length; i++) {
          await _databaseService.pendingChangesBox.put(i, _pendingChanges[i]);
        }
      }
    } catch (e) {
      throw Exception('Failed to save payment config data: $e');
    }
  }

  Future<void> clear() async {
    await _databaseService.paymentConfigBox.clear();
    await _databaseService.pendingChangesBox.clear();
    _configCache = null;
    _pendingChanges.clear();
  }

  Future<void> syncFromApi({bool skipHydration = false}) async {
    if (!await _apiHelper.hasNetwork()) {
      return;
    }

    await _syncPendingChanges();

    final result = await _syncHelper.fetch<PaymentConfig>(
      endpoint: '/landlord/payment-config',
      fromJsonList: (jsonList) {
        // Handle both single object response and empty response
        if (jsonList.isEmpty) return [];

        // If API returns single object instead of array
        if (jsonList.first is Map) {
          return [PaymentConfigDto.fromJson(jsonList.first).toPaymentConfig()];
        }

        // If API returns array
        return jsonList
            .map((json) => PaymentConfigDto.fromJson(json).toPaymentConfig())
            .toList();
      },
    );

    if (result.success && result.data != null) {
      _configCache = result.data!.isNotEmpty ? result.data!.first : null;
      if (!skipHydration) {
        await save();
      }
    }
  }

  Future<void> _syncPendingChanges() async {
    if (_pendingChanges.isEmpty) return;

    final successfulChanges = <int>[];
    final failedChanges = <int>[];

    for (int i = 0; i < _pendingChanges.length; i++) {
      final change = _pendingChanges[i];
      final retryCount = change['retryCount'] ?? 0;

      if (retryCount >= 5) {
        failedChanges.add(i);
        if (kDebugMode) {
          print(
              'Payment config pending change exceeded retry limit: ${change['type']} ${change['endpoint']}');
        }
        continue;
      }

      final success = await _syncHelper.applyPendingChange(change);

      if (success) {
        successfulChanges.add(i);
        if (kDebugMode) {
          print(
              'Successfully synced payment config pending change: ${change['type']} ${change['endpoint']}');
        }
      } else {
        _pendingChanges[i]['retryCount'] = retryCount + 1;
        if (kDebugMode) {
          print(
              'Failed to sync payment config pending change (retry ${retryCount + 1}/5): ${change['type']} ${change['endpoint']}');
        }
      }
    }

    final toRemove = [...successfulChanges, ...failedChanges]
      ..sort((a, b) => b.compareTo(a));
    for (final index in toRemove) {
      _pendingChanges.removeAt(index);
    }

    if (successfulChanges.isNotEmpty || failedChanges.isNotEmpty) {
      await save();
    }
  }

  Future<void> _addPendingChange(
    String type,
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final isDuplicate = _pendingChanges.any((change) {
      return change['type'] == type &&
          change['endpoint'] == endpoint &&
          jsonEncode(change['data']) == jsonEncode(data);
    });

    if (isDuplicate) {
      if (kDebugMode) {
        print(
            'Skipping duplicate payment config pending change: $type $endpoint');
      }
      return;
    }

    _pendingChanges.add({
      'type': type,
      'data': data,
      'endpoint': endpoint,
      'timestamp': DateTime.now().toIso8601String(),
      'retryCount': 0,
    });

    if (kDebugMode) {
      print('Added payment config pending change: $type $endpoint');
    }
  }

  Future<void> setupPaymentConfig(Map<String, dynamic> configData) async {
    final endpoint = '/landlord/payment-config';

    // Create offline model for immediate cache update
    final offlineConfig = PaymentConfig(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      landlordId: configData['landlordId'] ?? '',
      paymentMethod: configData['paymentMethod'] ?? 'none',
      bankName: configData['bankName'],
      bankAccountNumber: configData['bankAccountNumber'],
      bankAccountName: configData['bankAccountName'],
      enableKhqr: configData['enableKhqr'] ?? false,
      enableAbaPayWay: configData['enableAbaPayWay'] ?? false,
    );

    await _syncHelper.create<PaymentConfig>(
      endpoint: endpoint,
      data: configData,
      fromJson: (json) => PaymentConfigDto.fromJson(json).toPaymentConfig(),
      addToCache: (createdConfig) async {
        _configCache = createdConfig;
      },
      addPendingChange: _addPendingChange,
      offlineModel: offlineConfig,
    );

    await save();
  }

  Future<void> updatePaymentConfig(Map<String, dynamic> configData) async {
    final endpoint = '/landlord/payment-config';

    await _syncHelper.update(
      endpoint: endpoint,
      data: configData,
      updateCache: () async {
        if (_configCache != null) {
          _configCache = _configCache!.copyWith(
            paymentMethod: configData['paymentMethod'] as String?,
            bankName: configData['bankName'] as String?,
            bankAccountNumber: configData['bankAccountNumber'] as String?,
            bankAccountName: configData['bankAccountName'] as String?,
            enableKhqr: configData['enableKhqr'] as bool?,
            enableAbaPayWay: configData['enableAbaPayWay'] as bool?,
            updatedAt: DateTime.now(),
          );
        }
      },
      addPendingChange: _addPendingChange,
    );

    await save();
  }

  PaymentConfig? getPaymentConfig() {
    return _configCache;
  }

  bool hasPaymentConfig() => _configCache != null;
  bool hasPendingChanges() => _pendingChanges.isNotEmpty;
  int getPendingChangesCount() => _pendingChanges.length;
}
