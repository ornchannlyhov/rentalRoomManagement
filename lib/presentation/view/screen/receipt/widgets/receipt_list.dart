import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receipts_v2/data/models/enum/payment_status.dart';
import 'package:receipts_v2/data/models/receipt.dart';
import 'package:receipts_v2/presentation/providers/building_provider.dart';
import 'package:receipts_v2/presentation/providers/receipt_provider.dart';
import 'package:receipts_v2/presentation/view/screen/analysis/advanced_analysis.dart';
import 'package:receipts_v2/presentation/view/screen/receipt/widgets/filler_by_payment_button.dart';
import 'package:receipts_v2/presentation/view/screen/receipt/widgets/receipt_card.dart';
import 'package:receipts_v2/presentation/view/screen/receipt/widgets/receipt_summary_card.dart';
import 'package:receipts_v2/presentation/view/screen/tenant/widgets/tenant_state.dart';

class ReceiptList extends StatelessWidget {
  const ReceiptList({super.key, 
    required this.receiptProvider,
    required this.buildingProvider,
    required this.selectedBuildingId,
    required this.selectedStatus,
    required this.animationController,
    required this.fadeAnimation,
    required this.slideAnimation,
    required this.onBuildingChanged,
    required this.onStatusChanged,
    required this.onEditReceipt,
    required this.onViewDetail,
    required this.onShowMenuOptions,
    required this.onRefresh,
    required this.onShowUndoSnackbar,
    required this.getStatusColor,
    required this.getKhmerMonth,
  });

  final ReceiptProvider receiptProvider;
  final BuildingProvider buildingProvider;
  final String? selectedBuildingId;
  final PaymentStatus selectedStatus;
  final AnimationController animationController;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;
  final ValueChanged<String?> onBuildingChanged;
  final ValueChanged<PaymentStatus> onStatusChanged;
  final Future<void> Function(Receipt, List<Receipt>) onEditReceipt;
  final Future<void> Function(Receipt) onViewDetail;
  final void Function(BuildContext, Receipt, List<Receipt>) onShowMenuOptions;
  final Future<void> Function() onRefresh;
  final void Function(BuildContext, String, VoidCallback) onShowUndoSnackbar;
  final Color Function(PaymentStatus) getStatusColor;
  final String Function(int) getKhmerMonth;

  String _translatePaymentStatus(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return 'បានបង់ប្រាក់';
      case PaymentStatus.pending:
        return 'មិនទាន់បង់ប្រាក់';
      case PaymentStatus.overdue:
        return 'ហួសកំណត់';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return receiptProvider.receipts.when(
      loading: () => LoadingState(theme: theme),
      error: (error) =>
          ErrorState(theme: theme, error: error, onRetry: onRefresh),
      success: (allReceipts) {
        return buildingProvider.buildings.when(
          loading: () => LoadingState(theme: theme),
          error: (error) =>
              ErrorState(theme: theme, error: error, onRetry: onRefresh),
          success: (buildings) {
            final receiptsForCurrentMonthOrBuilding = selectedBuildingId != null
                ? receiptProvider.getReceiptsByBuilding(selectedBuildingId!)
                : receiptProvider.getReceiptsForCurrentMonth();
            final filteredReceiptsByStatus = receiptsForCurrentMonthOrBuilding
                .where((receipt) => receipt.paymentStatus == selectedStatus)
                .toList();

            return Column(
              children: [
                ReceiptSummaryCard(
                  receipts: allReceipts, // Pass all receipts for analysis
                  buildings: buildings,
                  selectedBuildingId: selectedBuildingId,
                  onBuildingChanged: onBuildingChanged,
                  getKhmerMonth: getKhmerMonth,
                  getStatusColor: getStatusColor,
                  onAdvancedAnalysisPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdvancedAnalysisScreen(
                          receipts: allReceipts,
                          buildings: buildings,
                          selectedBuildingId: selectedBuildingId,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: FilterByPaymentButton(
                    onStatusSelected: onStatusChanged,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: filteredReceiptsByStatus.isEmpty
                      ? EmptyState(
                          theme: theme,
                          fadeAnimation: fadeAnimation,
                          slideAnimation: slideAnimation,
                        )
                      : FadeTransition(
                          opacity: fadeAnimation,
                          child: RefreshIndicator(
                            onRefresh: onRefresh,
                            backgroundColor: theme.colorScheme.surfaceVariant,
                            color: theme.colorScheme.primary,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(0),
                              itemCount: filteredReceiptsByStatus.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 2),
                              itemBuilder: (ctx, index) {
                                final receipt = filteredReceiptsByStatus[index];
                                return SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(1, 0),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: animationController,
                                      curve: Interval(
                                        index * 0.1,
                                        (index * 0.1) + 0.6,
                                        curve: Curves.easeOutCubic,
                                      ),
                                    ),
                                  ),
                                  child: Dismissible(
                                    key: Key(receipt.id),
                                    background: Container(
                                      decoration: BoxDecoration(
                                        color: getStatusColor(
                                            receipt.paymentStatus ==
                                                    PaymentStatus.paid
                                                ? PaymentStatus.pending
                                                : PaymentStatus.paid),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20),
                                      child: Icon(
                                        receipt.paymentStatus ==
                                                PaymentStatus.paid
                                            ? Icons.pending_actions
                                            : Icons.check,
                                        color: Colors.white,
                                      ),
                                    ),
                                    secondaryBackground: Container(
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.error,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.delete_outline,
                                            color: theme.colorScheme.onError,
                                            size: 24,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'លុប',
                                            style: TextStyle(
                                              color: theme.colorScheme.onError,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    direction: DismissDirection.horizontal,
                                    onDismissed: (direction) {
                                      final originStatus =
                                          receipt.paymentStatus;
                                      final provider =
                                          context.read<ReceiptProvider>();
                                      final roomNumber =
                                          receipt.room?.roomNumber ?? 'ទរទេ';

                                      if (direction ==
                                          DismissDirection.startToEnd) {
                                        final newStatus =
                                            receipt.paymentStatus ==
                                                    PaymentStatus.paid
                                                ? PaymentStatus.pending
                                                : PaymentStatus.paid;

                                        provider.updateReceipt(receipt.copyWith(
                                            paymentStatus: newStatus));

                                        onShowUndoSnackbar(
                                          context,
                                          "បន្ទប់ $roomNumber បានផ្លាស់ប្តូរទៅជា ${_translatePaymentStatus(newStatus)}",
                                          () {
                                            provider.updateReceipt(
                                                receipt.copyWith(
                                                    paymentStatus:
                                                        originStatus));
                                          },
                                        );
                                      } else if (direction ==
                                          DismissDirection.endToStart) {
                                        provider.deleteReceipt(receipt.id);
                                        
                                      }
                                    },
                                    child: ReceiptCard(
                                      receipt: receipt,
                                      ontap: () => onViewDetail(receipt),
                                      onLongPress: () =>
                                          onEditReceipt(receipt, allReceipts),
                                      onMenuPressed: () => onShowMenuOptions(
                                          context, receipt, allReceipts),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
