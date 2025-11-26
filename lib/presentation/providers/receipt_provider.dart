import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:joul_v2/data/models/receipt.dart';
import 'package:joul_v2/data/models/enum/payment_status.dart';
import 'package:joul_v2/data/repositories/receipt_repository.dart';
import 'package:joul_v2/core/helpers/asyn_value.dart';
import 'package:joul_v2/core/helpers/repository_manager.dart';

class ReceiptProvider with ChangeNotifier {
  final ReceiptRepository _receiptRepository;
  final RepositoryManager? _repositoryManager;

  AsyncValue<List<Receipt>> _receiptsState = const AsyncValue.loading();

  ReceiptProvider(
    this._receiptRepository, {
    RepositoryManager? repositoryManager,
  }) : _repositoryManager = repositoryManager;

  AsyncValue<List<Receipt>> get receiptsState => _receiptsState;

  // Convenience getters
  List<Receipt> get receipts => _receiptsState.bestData ?? [];
  bool get isLoading => _receiptsState.isLoading;
  bool get hasError => _receiptsState.hasError;
  Object? get error => _receiptsState.error;

  Future<void> load() async {
    try {
      final receipts = _receiptRepository.getAllReceipts();
      _receiptsState = AsyncValue.success(receipts);
    } catch (e) {
      _receiptsState = AsyncValue.error(e, _receiptsState.bestData);
    } finally {
      notifyListeners();
    }
  }

  Future<void> generateMonthlyReceipts({
    Future<Uint8List?> Function(Receipt)? createImage,
  }) async {
    try {
      _receiptsState = AsyncValue.loading(_receiptsState.data);
      notifyListeners();

      await _receiptRepository.generateReceiptsFromUsage(
        createImage: createImage,
      );

      if (_repositoryManager != null) {
        await _repositoryManager.hydrateAllRelationships();
        await _repositoryManager.saveAll();
      }

      final receipts = _receiptRepository.getAllReceipts();
      _receiptsState = AsyncValue.success(receipts);
    } catch (e) {
      _receiptsState = AsyncValue.error(e, _receiptsState.data);
    }
    notifyListeners();
  }

  Future<void> createReceipt(Receipt receipt, {Uint8List? receiptImage}) async {
    _receiptsState = AsyncValue.loading(_receiptsState.bestData);
    notifyListeners();

    try {
      await _receiptRepository.createReceipt(receipt,
          receiptImage: receiptImage);

      // Hydrate relationships
      if (_repositoryManager != null) {
        await _repositoryManager.hydrateAllRelationships();
        await _repositoryManager.saveAll();
      }

      await load();
    } catch (e) {
      _receiptsState = AsyncValue.error(e, _receiptsState.bestData);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateReceipt(Receipt receipt) async {
    _receiptsState = AsyncValue.loading(_receiptsState.bestData);
    notifyListeners();

    try {
      await _receiptRepository.updateReceipt(receipt);

      // Hydrate relationships
      if (_repositoryManager != null) {
        await _repositoryManager.hydrateAllRelationships();
        await _repositoryManager.saveAll();
      }

      await load();
    } catch (e) {
      _receiptsState = AsyncValue.error(e, _receiptsState.bestData);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteReceipt(String receiptId) async {
    _receiptsState = AsyncValue.loading(_receiptsState.bestData);
    notifyListeners();

    try {
      await _receiptRepository.deleteReceipt(receiptId);

      // Hydrate relationships
      if (_repositoryManager != null) {
        await _repositoryManager.hydrateAllRelationships();
        await _repositoryManager.saveAll();
      }

      await load();
    } catch (e) {
      _receiptsState = AsyncValue.error(e, _receiptsState.bestData);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteLastYearReceipts() async {
    _receiptsState = AsyncValue.loading(_receiptsState.bestData);
    notifyListeners();

    try {
      await _receiptRepository.deleteLastYearReceipts();

      // Hydrate relationships
      if (_repositoryManager != null) {
        await _repositoryManager.hydrateAllRelationships();
        await _repositoryManager.saveAll();
      }

      await load();
    } catch (e) {
      _receiptsState = AsyncValue.error(e, _receiptsState.bestData);
      notifyListeners();
      rethrow;
    }
  }

  /// Confirm receipt and trigger PDF generation/sending to tenant
  Future<void> confirmReceipt(String receiptId) async {
    try {
      await _receiptRepository.confirmReceipt(receiptId);

      // Optionally refresh receipts to get updated status
      await syncReceipts();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> syncReceipts({
    String? roomId,
    String? tenantId,
    String? buildingId,
    PaymentStatus? paymentStatus,
  }) async {
    _receiptsState = AsyncValue.loading(_receiptsState.bestData);
    notifyListeners();

    try {
      await _receiptRepository.syncFromApi(
        roomId: roomId,
        tenantId: tenantId,
        buildingId: buildingId,
        paymentStatus: paymentStatus,
      );

      // Hydrate relationships after sync
      if (_repositoryManager != null) {
        await _repositoryManager.hydrateAllRelationships();
        await _repositoryManager.saveAll();
      }

      await load();
    } catch (e) {
      _receiptsState = AsyncValue.error(e, _receiptsState.bestData);
      notifyListeners();
      rethrow;
    }
  }

  List<Receipt> getReceiptsForCurrentMonth() {
    return _receiptRepository.getReceiptsForCurrentMonth();
  }

  List<Receipt> getReceiptsByMonth(int year, int month) {
    return _receiptRepository.getReceiptsByMonth(year, month);
  }

  List<Receipt> getReceiptsByBuilding(String buildingId) {
    return _receiptRepository.getReceiptsByBuilding(buildingId);
  }
}
