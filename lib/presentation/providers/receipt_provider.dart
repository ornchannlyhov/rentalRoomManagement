import 'package:flutter/material.dart';
import 'package:receipts_v2/helpers/asyn_value.dart';
import 'package:receipts_v2/data/models/receipt.dart';
import 'package:receipts_v2/data/repositories/receipt_repository.dart';

class ReceiptProvider extends ChangeNotifier {
  final ReceiptRepository _repository;

  ReceiptProvider(this._repository);

  AsyncValue<List<Receipt>> _receipts = const AsyncValue.loading();
  AsyncValue<List<Receipt>> get receipts => _receipts;

  String? get errorMessage {
    return _receipts.when(
      loading: () => null,
      success: (_) => null,
      error: (error) => error.toString(),
    );
  }

  bool get isLoading => _receipts.isLoading;
  bool get hasData => _receipts.hasData;
  bool get hasError => _receipts.hasError;

  Future<void> load() async {
    _receipts = const AsyncValue.loading();
    notifyListeners();

    try {
      await _repository.load();
      final data = _repository.getAllReceipts();
      _receipts = AsyncValue.success(data);
    } catch (e) {
      _receipts = AsyncValue.error(e);
    }
    notifyListeners();
  }

  Future<void> syncFromApi() async {
    _receipts = const AsyncValue.loading();
    notifyListeners();

    try {
      await _repository.syncFromApi();
      final data = _repository.getAllReceipts();
      _receipts = AsyncValue.success(data);
    } catch (e) {
      _receipts = AsyncValue.error(e);
    }
    notifyListeners();
  }

  Future<Receipt> createReceipt(Receipt receipt) async {
    try {
      await _repository.createReceipt(receipt);
      final data = _repository.getAllReceipts();
      _receipts = AsyncValue.success(data);
      notifyListeners();
      return receipt;
    } catch (e) {
      _receipts = AsyncValue.error(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<Receipt> updateReceipt(Receipt receipt) async {
    try {
      await _repository.updateReceipt(receipt);
      final data = _repository.getAllReceipts();
      _receipts = AsyncValue.success(data);
      notifyListeners();
      return receipt;
    } catch (e) {
      _receipts = AsyncValue.error(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteReceipt(String receiptId) async {
    try {
      await _repository.deleteReceipt(receiptId);
      final data = _repository.getAllReceipts();
      _receipts = AsyncValue.success(data);
      notifyListeners();
    } catch (e) {
      _receipts = AsyncValue.error(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> restoreReceipt(int restoreIndex, Receipt receipt) async {
    try {
      await _repository.restoreReceipt(restoreIndex, receipt);
      final data = _repository.getAllReceipts();
      _receipts = AsyncValue.success(data);
      notifyListeners();
    } catch (e) {
      _receipts = AsyncValue.error(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteLastYearReceipts() async {
    try {
      await _repository.deleteLastYearReceipts();
      final data = _repository.getAllReceipts();
      _receipts = AsyncValue.success(data);
      notifyListeners();
    } catch (e) {
      _receipts = AsyncValue.error(e);
      notifyListeners();
      rethrow;
    }
  }

  List<Receipt> getReceiptsForCurrentMonth() {
    try {
      if (_receipts.hasData) {
        return _repository.getReceiptsForCurrentMonth();
      }
      return [];
    } catch (e) {
      _receipts = AsyncValue.error(e);
      notifyListeners();
      return [];
    }
  }

  List<Receipt> getReceiptsByMonth(int year, int month) {
    try {
      if (_receipts.hasData) {
        return _repository.getReceiptsByMonth(year, month);
      }
      return [];
    } catch (e) {
      _receipts = AsyncValue.error(e);
      notifyListeners();
      return [];
    }
  }

  List<Receipt> getReceiptsByBuilding(String buildingId) {
    try {
      if (_receipts.hasData) {
        return _repository.getReceiptsByBuilding(buildingId);
      }
      return [];
    } catch (e) {
      _receipts = AsyncValue.error(e);
      notifyListeners();
      return [];
    }
  }

  int get receiptCount {
    if (_receipts.hasData) {
      return _receipts.data!.length;
    }
    return 0;
  }

  Future<void> refresh() async {
    await syncFromApi();
  }

  void clearError() {
    if (_receipts.hasError) {
      _receipts = AsyncValue.success(_repository.getAllReceipts());
      notifyListeners();
    }
  }
}
