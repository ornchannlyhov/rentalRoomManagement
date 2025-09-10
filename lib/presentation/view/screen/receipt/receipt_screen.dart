// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receipts_v2/data/models/enum/mode.dart';
import 'package:receipts_v2/data/models/enum/payment_status.dart';
import 'package:receipts_v2/data/models/receipt.dart';
import 'package:receipts_v2/presentation/providers/receipt_provider.dart';
import 'package:receipts_v2/presentation/view/app_widgets/app_bar.dart';
import 'package:receipts_v2/presentation/view/screen/receipt/widgets/filler_by_payment_button.dart';
import 'package:receipts_v2/presentation/view/app_widgets/grid_item.dart';
import 'package:receipts_v2/presentation/view/screen/receipt/widgets/receipt_detail.dart';
import 'package:receipts_v2/presentation/view/screen/receipt/widgets/receipt_card.dart';
import 'package:receipts_v2/presentation/view/screen/receipt/widgets/receipt_form.dart';

class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  PaymentStatus selectedStatus = PaymentStatus.paid;
  int selectedMonth = DateTime.now().month; // Initialize with current month

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReceiptProvider>().load();
    });
  }

  Future<void> _addReceipt(
      BuildContext context, List<Receipt> allReceipts) async {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (ctx) => ReceiptForm(
          receipts: allReceipts,
        ),
      ),
    );
  }

  Future<void> _editReceipt(
      BuildContext context, Receipt receipt, List<Receipt> allReceipts) async {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (ctx) => ReceiptForm(
          mode: Mode.editing,
          receipt: receipt,
          receipts: allReceipts,
        ),
      ),
    );
  }

  Future<void> _viewDetail(BuildContext context, Receipt receipt) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => ReceiptDetailScreen(receipt: receipt),
      ),
    );
  }

  int _countReceiptsByStatus(List<Receipt> receipts, PaymentStatus status) {
    return receipts.where((receipt) => receipt.paymentStatus == status).length;
  }

  List<Receipt> _filterReceiptsByStatus(
      List<Receipt> receipts, PaymentStatus status) {
    return receipts
        .where((receipt) => receipt.paymentStatus == status)
        .toList();
  }

  void _showUndoSnackbar(
    BuildContext context,
    String content,
    VoidCallback onUndo,
  ) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(content),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: "មិនធ្វើវិញ",
          textColor: primaryColor,
          onPressed: onUndo,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  String getKhmerMonth(int month) {
    final months = [
      'មករា',
      'កុម្ភៈ',
      'មីនា',
      'មេសា',
      'ឧសភា',
      'មិថុនា',
      'កក្កដា',
      'សីហា',
      'កញ្ញា',
      'តុលា',
      'វិច្ឆិកា',
      'ធ្នូ'
    ];
    return months[month - 1];
  }

  List<DropdownMenuItem<int>> _buildMonthItems() {
    final currentMonth = DateTime.now().month;
    final List<DropdownMenuItem<int>> items = [];

    for (int month = 1; month <= currentMonth; month++) {
      items.add(
        DropdownMenuItem<int>(
          value: month,
          child: Text(
            getKhmerMonth(month),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final receiptProvider = context.watch<ReceiptProvider>();
    final currentYear = DateTime.now().year;
    final thisMonth = getKhmerMonth(selectedMonth);

    return Scaffold(
      appBar: AppbarCustom(
        header: 'វិក្កយបត្រ',
        onAddPressed: () {
          receiptProvider.receipts.when(
            success: (allReceipts) => _addReceipt(context, allReceipts),
            loading: () {},
            error: (_) {},
          );
        },
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: receiptProvider.receipts.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('កំហុស: $error', style: theme.textTheme.bodyLarge),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => receiptProvider.load(),
                  child: const Text('ព្យាយាមម្តងទៀត'),
                ),
              ],
            ),
          ),
          success: (allReceipts) {
            final receipts =
                receiptProvider.getReceiptsByMonth(currentYear, selectedMonth);
            final filteredReceipts =
                _filterReceiptsByStatus(receipts, selectedStatus);

            return Column(
              children: [
                Card(
                  margin: EdgeInsets.zero,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Month header row with filter button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.calendar_month,
                                    size: 20, color: colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'ខែ $thisMonth',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            PopupMenuButton<int>(
                              icon: Icon(Icons.filter_list,
                                  color: colorScheme.primary),
                              tooltip: 'ជ្រើសរើសខែ',
                              onSelected: (int newValue) {
                                setState(() {
                                  selectedMonth = newValue;
                                });
                              },
                              itemBuilder: (BuildContext context) =>
                                  _buildMonthItems().map((item) {
                                return PopupMenuItem<int>(
                                  value: item.value,
                                  child: item.child,
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // GridItems row with equal sizing
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final availableWidth = constraints.maxWidth;
                            final itemWidth = (availableWidth - 32) / 3;

                            return SizedBox(
                              height: itemWidth * 0.8,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    width: itemWidth,
                                    child: GridItem(
                                      label: "កំពុងរង់ចាំ",
                                      icon: Icons.hourglass_empty_sharp,
                                      amount: _countReceiptsByStatus(
                                          receipts, PaymentStatus.pending),
                                      iconColor: Colors.amber,
                                      border: true,
                                    ),
                                  ),
                                  SizedBox(
                                    width: itemWidth,
                                    child: GridItem(
                                      label: "បានបង់",
                                      icon: Icons.check_circle,
                                      amount: _countReceiptsByStatus(
                                          receipts, PaymentStatus.paid),
                                      iconColor: Colors.green,
                                      border: true,
                                    ),
                                  ),
                                  SizedBox(
                                    width: itemWidth,
                                    child: GridItem(
                                      label: "ហួសកំណត់",
                                      icon: Icons.error,
                                      amount: _countReceiptsByStatus(
                                          receipts, PaymentStatus.overdue),
                                      iconColor: Colors.red,
                                      border: true,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Filter Button
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: FilterByPaymentButton(
                    onStatusSelected: (status) {
                      setState(() {
                        selectedStatus = status;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Receipts List
                Expanded(
                  child: filteredReceipts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long,
                                  size: 48, color: colorScheme.onSurface),
                              const SizedBox(height: 16),
                              Text(
                                'មិនមានវិក្កយបត្រ',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => receiptProvider.load(),
                          child: ListView.separated(
                            itemCount: filteredReceipts.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemBuilder: (ctx, index) {
                              final receipt = filteredReceipts[index];
                              return Dismissible(
                                key: Key(receipt.id),
                                background: Container(
                                  decoration: BoxDecoration(
                                    color: receipt.paymentStatus ==
                                            PaymentStatus.paid
                                        ? Colors.amber
                                        : Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Icon(
                                    receipt.paymentStatus == PaymentStatus.paid
                                        ? Icons.pending_actions
                                        : Icons.check,
                                    color: Colors.white,
                                  ),
                                ),
                                secondaryBackground: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: const Icon(Icons.delete,
                                      color: Colors.white),
                                ),
                                direction: DismissDirection.horizontal,
                                onDismissed: (direction) {
                                  final originStatus = receipt.paymentStatus;
                                  final provider =
                                      context.read<ReceiptProvider>();
                                  final roomNumber =
                                      receipt.room?.roomNumber ?? 'ទរទេ';

                                  if (direction ==
                                      DismissDirection.startToEnd) {
                                    final newStatus = receipt.paymentStatus ==
                                            PaymentStatus.paid
                                        ? PaymentStatus.pending
                                        : PaymentStatus.paid;

                                    provider.updateReceipt(receipt.copyWith(
                                        paymentStatus: newStatus));

                                    _showUndoSnackbar(
                                      context,
                                      "បន្ទប់ $roomNumber បានផ្លាស់ប្តូរទៅជា ${translatePaymentStatus(newStatus)}",
                                      () {
                                        provider.updateReceipt(receipt.copyWith(
                                            paymentStatus: originStatus));
                                      },
                                    );
                                  } else if (direction ==
                                      DismissDirection.endToStart) {
                                    provider.deleteReceipt(receipt.id);
                                    _showUndoSnackbar(
                                      context,
                                      'បានលុបវិក្កយបត្របន្ទប់ $roomNumber',
                                      () => provider.restoreReceipt(
                                          index, receipt),
                                    );
                                  }
                                },
                                child: ReceiptCard(
                                  receipt: receipt,
                                  ontap: () => _viewDetail(context, receipt),
                                  onLongPress: () => _editReceipt(
                                      context, receipt, allReceipts),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String translatePaymentStatus(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return 'បានបង់ប្រាក់';
      case PaymentStatus.pending:
        return 'មិនទាន់បង់ប្រាក់';
      default:
        return status.name;
    }
  }
}
