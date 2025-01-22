import 'dart:async';
import 'package:flutter/material.dart';
import 'package:receipts_v2/model/receipt.dart';
import 'package:receipts_v2/repository/receipt_repository.dart';
import 'package:receipts_v2/view/screen/widget/history/filter_button.dart';
import 'package:receipts_v2/view/screen/widget/receipt/receipt_detail.dart';
import 'package:receipts_v2/view/screen/widget/receipt/receipt_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ReceiptRepository receiptRepository = ReceiptRepository();
  List<Receipt> receipts = [];
  int selectedMonth = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _loadReceipt();
  }

  Future<void> _loadReceipt() async {
    await receiptRepository.load();
    setState(() {
      receipts = receiptRepository.getAllReceipts();
    });
  }

  Future<void> _viewDetail(BuildContext context, Receipt receipt) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => ReceiptDetailScreen(receipt: receipt),
      ),
    );
  }

  List<Receipt> _filterReceiptsByMonth(int month) {
    return receipts.where((receipt) => receipt.date.month == month).toList();
  }

  @override
  Widget build(BuildContext context) {
    const Color cardColor = Color.fromARGB(255, 18, 13, 29);
    final filteredReceipts = _filterReceiptsByMonth(selectedMonth);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historys'),
        backgroundColor: const Color(0xFF1A0C2D),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: FilterByMonthButton(
                onMonthSelected: (month) {
                  setState(() {
                    selectedMonth = month;
                  });
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filteredReceipts.isEmpty
                  ? const Center(
                      child: Text(
                        'No Receipts Available',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredReceipts.length,
                      itemBuilder: (ctx, index) => ReceiptCard(
                        receipt: filteredReceipts[index],
                        ontap: () =>
                            _viewDetail(context, filteredReceipts[index]),
                        onLongPress: () {},
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
