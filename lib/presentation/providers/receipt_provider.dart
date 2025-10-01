import 'package:flutter/material.dart';
import 'package:receipts_v2/core/asyn_value.dart';
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

  Future<Receipt> createReceipt(Receipt receipt) async {
    try {
      final created = await _repository.createReceipt(receipt);
      await load();
      return created;
    } catch (e) {
      _receipts = AsyncValue.error(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<Receipt> updateReceipt(Receipt receipt) async {
    try {
      final updated = await _repository.updateReceipt(receipt);
      await load();
      return updated;
    } catch (e) {
      _receipts = AsyncValue.error(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteReceipt(String receiptId) async {
    try {
      await _repository.deleteReceipt(receiptId);
      await load();
    } catch (e) {
      _receipts = AsyncValue.error(e);
      notifyListeners();
      rethrow;
    }
  }

  Receipt? getReceiptById(String receiptId) {
    if (_receipts.hasData) {
      return _repository.getReceiptById(receiptId);
    }
    return null;
  }

  List<Receipt> getReceiptsForCurrentMonth() {
    if (_receipts.hasData) {
      return _repository.getReceiptsForCurrentMonth();
    }
    return [];
  }

  List<Receipt> getReceiptsByMonth(int year, int month) {
    if (_receipts.hasData) {
      return _repository.getReceiptsByMonth(year, month);
    }
    return [];
  }

  List<Receipt> getReceiptsByBuilding(String buildingId) {
    if (_receipts.hasData) {
      return _repository.getReceiptsByBuilding(buildingId);
    }
    return [];
  }

  int get receiptCount {
    if (_receipts.hasData) {
      return _receipts.data!.length;
    }
    return 0;
  }

  Future<void> refresh() async {
    await load();
  }

  void clearError() {
    if (_receipts.hasError) {
      _receipts = AsyncValue.success(_repository.getAllReceipts());
      notifyListeners();
    }
  }
}
