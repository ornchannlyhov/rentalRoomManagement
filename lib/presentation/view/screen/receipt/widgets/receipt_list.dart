import 'package:flutter/material.dart';
import 'package:joul_v2/presentation/view/app_widgets/global_snackbar.dart';
import 'package:provider/provider.dart';
import 'package:joul_v2/data/models/enum/payment_status.dart';
import 'package:joul_v2/data/models/receipt.dart';
import 'package:joul_v2/presentation/providers/building_provider.dart';
import 'package:joul_v2/presentation/providers/receipt_provider.dart';
import 'package:joul_v2/presentation/view/screen/analysis/advanced_analysis.dart';
import 'package:joul_v2/presentation/view/screen/receipt/widgets/filler_by_payment_button.dart';
import 'package:joul_v2/presentation/view/screen/receipt/widgets/receipt_card.dart';
import 'package:joul_v2/presentation/view/screen/receipt/widgets/receipt_summary_card.dart';
import 'package:joul_v2/presentation/view/screen/tenant/widgets/tenant_state.dart';

class ReceiptList extends StatelessWidget {
  const ReceiptList({
    super.key,
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
    required this.onConfirmDelete,
    required this.onHandleDelete,
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
  final void Function(BuildContext, int index, Receipt, List<Receipt>)
      onShowMenuOptions;
  final Future<void> Function() onRefresh;
  final Future<bool> Function(BuildContext, Receipt) onConfirmDelete;
  final Future<void> Function(Receipt, int) onHandleDelete;
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

    return receiptProvider.receiptsState.when(
      loading: () => LoadingState(theme: theme),
      error: (error) =>
          ErrorState(theme: theme, error: error, onRetry: onRefresh),
      success: (allReceipts) {
        return buildingProvider.buildingsState.when(
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
                    color: theme.colorScheme.surfaceContainerHighest,
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
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            color: theme.colorScheme.primary,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(0),
                              itemCount: filteredReceiptsByStatus.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 2),
                              itemBuilder: (ctx, index) {
                                final receipt = filteredReceiptsByStatus[index];

                                // Calculate staggered animation intervals with proper clamping
                                final double begin =
                                    (index * 0.05).clamp(0.0, 0.4);
                                final double end =
                                    ((index * 0.05) + 0.6).clamp(0.0, 1.0);

                                return SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(1, 0),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: animationController,
                                      curve: Interval(
                                        begin,
                                        end,
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
                                    confirmDismiss: (direction) async {
                                      if (direction ==
                                          DismissDirection.endToStart) {
                                        // Show confirmation dialog for delete
                                        return await onConfirmDelete(
                                            context, receipt);
                                      }
                                      // Allow status change without confirmation
                                      return true;
                                    },
                                    onDismissed: (direction) async {
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

                                        await provider.updateReceipt(
                                            receipt.copyWith(
                                                paymentStatus: newStatus));

                                        GlobalSnackBar.show(
                                          // ignore: use_build_context_synchronously
                                          context: context,
                                          message:
                                              "បន្ទប់ $roomNumber បានផ្លាស់ប្តូរទៅជា ${_translatePaymentStatus(newStatus)}",
                                        );
                                      } else if (direction ==
                                          DismissDirection.endToStart) {
                                        // Delete with undo snackbar
                                        await provider
                                            .deleteReceipt(receipt.id);
                                      }
                                    },
                                    child: ReceiptCard(
                                      receipt: receipt,
                                      ontap: () => onViewDetail(receipt),
                                      onLongPress: () =>
                                          onEditReceipt(receipt, allReceipts),
                                      onMenuPressed: () => onShowMenuOptions(
                                          context, index, receipt, allReceipts),
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
