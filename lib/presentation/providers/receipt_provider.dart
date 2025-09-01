import 'package:flutter/material.dart';
import 'package:receipts_v2/core/asyn_value.dart';
import 'package:receipts_v2/data/models/receipt.dart';
import 'package:receipts_v2/data/repositories/receipt_repository.dart';
class ReceiptProvider extends ChangeNotifier {
  final ReceiptRepository _repository = ReceiptRepository();

  AsyncValue<List<Receipt>> _receipts = const AsyncValue.success([]); // Start with empty list
  AsyncValue<List<Receipt>> get receipts => _receipts;

  Future<void> load() async {
    _receipts = const AsyncValue.loading();
    notifyListeners();

    try {
      // Attempt to load data, handle any initial secure storage issues
      await _repository.load();
      await _repository.deleteLastYearReceipts();
      final data = _repository.getAllReceipts();
      _receipts = AsyncValue.success(data.isNotEmpty ? data : []); // Ensure non-empty list
    } catch (e) {
      // Log the error for debugging (optional)
      print('Error loading receipts: $e');
      _receipts = const AsyncValue.success([]); // Fall back to empty list on error
    }
    notifyListeners();
  }

  Future<void> createReceipt(Receipt receipt) async {
    try {
      await _repository.createReceipt(receipt);
      await load();
    } catch (e) {
      _receipts = AsyncValue.error(e);
      notifyListeners();
    }
  }

  Future<void> updateReceipt(Receipt receipt) async {
    try {
      await _repository.updateReceipt(receipt);
      await load();
    } catch (e) {
      _receipts = AsyncValue.error(e);
      notifyListeners();
    }
  }

  Future<void> restoreReceipt(int index, Receipt receipt) async {
    try {
      await _repository.restoreReceipt(index, receipt);
      await load();
    } catch (e) {
      _receipts = AsyncValue.error(e);
      notifyListeners();
    }
  }

  Future<void> deleteReceipt(String receiptId) async {
    try {
      await _repository.deleteReceipt(receiptId);
      await load();
    } catch (e) {
      _receipts = AsyncValue.error(e);
      notifyListeners();
    }
  }

  List<Receipt> getReceiptsForCurrentMonth() {
    if (_receipts.hasData) {
      return _repository.getReceiptsForCurrentMonth();
    }
    return [];
  }
}