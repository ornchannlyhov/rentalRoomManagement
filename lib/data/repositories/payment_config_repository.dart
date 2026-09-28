import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:joul_v2/core/helpers/api_helper.dart';
import 'package:joul_v2/core/sync/outbox.dart';
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
      } else {
        await _databaseService.paymentConfigBox.delete('config');
      }
    } catch (e) {
      throw Exception('Failed to save payment config data: $e');
    }
  }

  Future<void> clear() async {
    await _databaseService.paymentConfigBox.clear();
    _configCache = null;
  }

  Future<void> syncFromApi({bool skipHydration = false}) async {
    if (!await _apiHelper.hasNetwork()) {
      return;
    }

    // GET /api/landlord/payment-config returns single object, not array
    // Response format: { "success": true, "data": { ... } }
    try {
      final token = await _apiHelper.storage.read(key: 'auth_token');
      if (token == null) {
        return;
      }

      final response = await _apiHelper.dio.get(
        '${_apiHelper.baseUrl}/landlord/payment-config',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
        cancelToken: _apiHelper.cancelToken,
      );

      if (response.statusCode == 200) {
        // A change still waiting to upload is newer than the server copy.
        if (Outbox.instance
            .hasChangesForEndpoint('/landlord/payment-config')) {
          return;
        }
        final data = response.data['data'];

        // Handle case where data might be null (no config yet)
        if (data != null && data is Map<String, dynamic>) {
          _configCache = PaymentConfigDto.fromJson(data).toPaymentConfig();
        } else {
          _configCache = null;
        }

        if (!skipHydration) {
          await save();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing payment config from API: $e');
      }
      // Don't throw, just keep existing cache
    }
  }

  Future<void> _addPendingChange(
    String type,
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    await Outbox.instance.enqueue(
      entity: 'paymentConfig',
      type: type,
      endpoint: endpoint,
      data: data,
      singleton: true,
    );
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
}
