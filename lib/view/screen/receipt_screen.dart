import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:receipts_v2/model/enum/mode.dart';
import 'package:receipts_v2/model/enum/payment_status.dart';
import 'package:receipts_v2/model/receipt.dart';
import 'package:receipts_v2/repository/receipt_repository.dart';
import 'package:receipts_v2/view/appComponent/app_bar.dart';
import 'package:receipts_v2/view/widget/receiptWidgets/filler_button.dart';
import 'package:receipts_v2/view/appComponent/grid_item.dart';
import 'package:receipts_v2/view/widget/receiptWidgets/receipt_detail.dart';
import 'package:receipts_v2/view/widget/receiptWidgets/receipt_card.dart';
import 'package:receipts_v2/view/widget/receiptWidgets/receipt_form.dart';

class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  final ReceiptRepository receiptRepository = ReceiptRepository();
  List<Receipt> receipts = [];
  List<Receipt> allReceipts = [];
  PaymentStatus selectedStatus = PaymentStatus.paid;

  @override
  void initState() {
    super.initState();
    _loadReceipt();

    Timer.periodic(const Duration(hours: 1), (timer) async {
      await receiptRepository.updateReceiptStatusToOverdue();
      setState(() {
        allReceipts = receiptRepository.getAllReceipts();
        receipts = receiptRepository.getReceiptsForCurrentMonth();
      });
    });
  }

  Future<void> _loadReceipt() async {
    await receiptRepository.load();
    setState(() {
      allReceipts = receiptRepository.getAllReceipts();
      receipts = receiptRepository.getReceiptsForCurrentMonth();
    });
  }

  Future<void> _addReceipt(
      BuildContext context, List<Receipt> allReceipts) async {
    final newReceipt = await Navigator.of(context).push<Receipt>(
      MaterialPageRoute(
        builder: (ctx) => ReceiptForm(
          receipts: allReceipts,
        ),
      ),
    );

    if (newReceipt != null) {
      await receiptRepository.createReceipt(newReceipt);
      _loadReceipt();
    }
  }

  Future<void> _editReceipt(BuildContext context, Receipt receipt) async {
    final updatedReceipt = await Navigator.of(context).push<Receipt>(
      MaterialPageRoute(
        builder: (ctx) => ReceiptForm(
          mode: Mode.editing,
          receipt: receipt,
          receipts: allReceipts,
        ),
      ),
    );
    if (updatedReceipt != null) {
      await receiptRepository.updateReceipt(updatedReceipt);
      _loadReceipt();
    }
  }

  Future<void> _viewDetail(BuildContext context, Receipt receipt) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => ReceiptDetailScreen(receipt: receipt),
      ),
    );
    _loadReceipt();
  }

  int countPaidReceipts() {
    return receipts
        .where((receipt) => receipt.paymentStatus == PaymentStatus.paid)
        .length;
  }

  int countPendingReceipts() {
    return receipts
        .where((receipt) => receipt.paymentStatus == PaymentStatus.pending)
        .length;
  }

  int countOverdueReceipts() {
    return receipts
        .where((receipt) => receipt.paymentStatus == PaymentStatus.overdue)
        .length;
  }

  List<Receipt> _filterReceiptsByStatus(PaymentStatus status) {
    return receipts
        .where((receipt) => receipt.paymentStatus == status)
        .toList();
  }

  void _showUndoSnackbar(
    BuildContext context,
    String content,
    VoidCallback onUndo,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(content),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: "Undo",
          onPressed: onUndo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final thisMonth = DateFormat.MMMM().format(DateTime.now());
    const Color cardColor = Color.fromARGB(255, 18, 13, 29);
    final filteredReceipts = _filterReceiptsByStatus(selectedStatus);

    return Scaffold(
      appBar: AppbarCustom(
        header: 'Receipts',
        onAddPressed: () => _addReceipt(context, allReceipts),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    thisMonth,
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GridItem(
                        gridColor: cardColor,
                        label: "Pending",
                        icon: Icons.hourglass_empty_sharp,
                        amount: receipts.isEmpty ? 0 : countPendingReceipts(),
                        iconColor: Colors.yellow,
                        border: true,
                      ),
                      GridItem(
                        gridColor: cardColor,
                        label: "Paid",
                        icon: Icons.check_circle,
                        amount: receipts.isEmpty ? 0 : countPaidReceipts(),
                        iconColor: Colors.greenAccent,
                        border: true,
                      ),
                      GridItem(
                        gridColor: cardColor,
                        label: "Overdue",
                        icon: Icons.error,
                        amount: receipts.isEmpty ? 0 : countOverdueReceipts(),
                        iconColor: Colors.red,
                        border: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: FilterByPaymentButton(
                onStatusSelected: (status) {
                  setState(() {
                    selectedStatus = status;
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
                        itemBuilder: (ctx, index) {
                          final receipt = filteredReceipts[index];
                          return Dismissible(
                            key: Key(receipt.id),
                            background: Container(
                              color: receipt.paymentStatus == PaymentStatus.paid
                                  ? Colors.yellow
                                  : Colors.greenAccent,
                              alignment: Alignment.centerLeft,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Icon(
                                receipt.paymentStatus == PaymentStatus.paid
                                    ? Icons.pending_actions
                                    : Icons.check,
                                color: Colors.white,
                              ),
                            ),
                            secondaryBackground: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child:
                                  const Icon(Icons.delete, color: Colors.white),
                            ),
                            direction: DismissDirection.horizontal,
                            onDismissed: (direction) {
                              final originStatus = receipt.paymentStatus;
                              if (direction == DismissDirection.startToEnd) {
                                setState(() {
                                  receipt.paymentStatus =
                                      receipt.paymentStatus ==
                                              PaymentStatus.paid
                                          ? PaymentStatus.pending
                                          : PaymentStatus.paid;
                                });
                                receiptRepository.save();
                                _showUndoSnackbar(
                                  context,
                                  "Room ${receipt.room!.roomNumber} Payment status updated to ${receipt.paymentStatus.name}",
                                  () {
                                    setState(() {
                                      receipt.paymentStatus = originStatus;
                                    });
                                    receiptRepository.save();
                                  },
                                );
                              } else if (direction ==
                                  DismissDirection.endToStart) {
                                receiptRepository.deleteReceipt(receipt.id);
                                _loadReceipt();
                                _showUndoSnackbar(
                                  context,
                                  'Room ${receipt.room!.roomNumber} deleted',
                                  () {
                                    receiptRepository.restoreReceipt(
                                        index, receipt);
                                    _loadReceipt();
                                  },
                                );
                              }
                            },
                            child: ReceiptCard(
                              receipt: receipt,
                              ontap: () => _viewDetail(context, receipt),
                              onLongPress: () => _editReceipt(context, receipt),
                            ),
                          );
                        },
                      )),
          ],
        ),
      ),
    );
  }
}
