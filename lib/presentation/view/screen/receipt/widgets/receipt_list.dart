import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receipts_v2/data/models/enum/payment_status.dart';
import 'package:receipts_v2/data/models/receipt.dart';
import 'package:receipts_v2/presentation/providers/building_provider.dart';
import 'package:receipts_v2/presentation/providers/receipt_provider.dart';
import 'package:receipts_v2/presentation/view/app_widgets/building_filter_dropdown.dart';
import 'package:receipts_v2/presentation/view/screen/analysis/advanced_analysis.dart';
import 'package:receipts_v2/presentation/view/screen/receipt/widgets/filler_by_payment_button.dart';
import 'package:receipts_v2/presentation/view/screen/receipt/widgets/receipt_card.dart';
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
                _ReceiptSummaryCard(
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

class _ReceiptSummaryCard extends StatelessWidget {
  const _ReceiptSummaryCard({
    required this.receipts,
    required this.buildings,
    required this.selectedBuildingId,
    required this.onBuildingChanged,
    required this.getKhmerMonth,
    required this.getStatusColor,
    required this.onAdvancedAnalysisPressed,
  });

  final List<Receipt> receipts;
  final List<dynamic> buildings;
  final String? selectedBuildingId;
  final ValueChanged<String?> onBuildingChanged;
  final String Function(int) getKhmerMonth;
  final Color Function(PaymentStatus) getStatusColor;
  final VoidCallback onAdvancedAnalysisPressed;

  int _countRoomsInBuilding(dynamic building) {
    return building.rooms?.length ?? 0;
  }

  int _countTotalRooms(List<dynamic> buildings) {
    return buildings.fold(
        0, (sum, building) => sum + _countRoomsInBuilding(building));
  }

  int _countReceiptsByStatus(List<Receipt> receipts, PaymentStatus status) {
    return receipts.where((receipt) => receipt.paymentStatus == status).length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentMonth = DateTime.now().month;
    final thisMonth = getKhmerMonth(currentMonth);

    // Filter receipts by selected building if _selectedBuildingId is not null
    final filteredReceipts = selectedBuildingId != null
        ? receipts
            .where((r) => r.room?.building?.id == selectedBuildingId)
            .toList()
        : receipts;

    final totalRooms = selectedBuildingId != null
        ? _countRoomsInBuilding(
            buildings.firstWhere((b) => b.id == selectedBuildingId))
        : _countTotalRooms(buildings);
    final receiptCount = filteredReceipts.length;
    final progress = totalRooms > 0 ? receiptCount / totalRooms : 0.0;

    final paidCount =
        _countReceiptsByStatus(filteredReceipts, PaymentStatus.paid);
    final unpaidCount =
        _countReceiptsByStatus(filteredReceipts, PaymentStatus.pending);
    final overdueCount =
        _countReceiptsByStatus(filteredReceipts, PaymentStatus.overdue);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shadowColor: colorScheme.primary.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surface.withOpacity(0.95),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_month,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'ខែ $thisMonth',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onAdvancedAnalysisPressed,
                    icon: Icon(
                      Icons.analytics_rounded,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                    tooltip: 'ការវិភាគលម្អិត',
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.primary.withOpacity(0.1),
                      padding: const EdgeInsets.all(4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
              Transform.translate(
                offset: const Offset(0, -8),
                child: Consumer<BuildingProvider>(
                  builder: (context, buildingProvider, child) {
                    return BuildingFilterDropdown(
                      buildingProvider: buildingProvider,
                      selectedBuildingId: selectedBuildingId,
                      onChanged: onBuildingChanged,
                    );
                  },
                ),
              ),
              Transform.translate(
                  offset: const Offset(0, -8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _StatusCard(
                                    status: PaymentStatus.paid,
                                    count: paidCount,
                                    icon: Icons.check_circle_outline,
                                    theme: theme,
                                    colorScheme: colorScheme,
                                    getStatusColor: getStatusColor,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: _StatusCard(
                                    status: PaymentStatus.pending,
                                    count: unpaidCount,
                                    icon: Icons.pending_actions,
                                    theme: theme,
                                    colorScheme: colorScheme,
                                    getStatusColor: getStatusColor,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: _StatusCard(
                                    status: PaymentStatus.overdue,
                                    count: overdueCount,
                                    icon: Icons.cancel_outlined,
                                    theme: theme,
                                    colorScheme: colorScheme,
                                    getStatusColor: getStatusColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: CircularProgressIndicator(
                                    value: progress.clamp(0.0, 1.0),
                                    strokeWidth: 3,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      colorScheme.primary,
                                    ),
                                    strokeCap: StrokeCap.round,
                                  ),
                                ),
                                Text(
                                  '$receiptCount/$totalRooms',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'វិក្កយបត្រ/បន្ទប់',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                                fontSize: 9,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.status,
    required this.count,
    required this.icon,
    required this.theme,
    required this.colorScheme,
    required this.getStatusColor,
  });

  final PaymentStatus status;
  final int count;
  final IconData icon;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final Color Function(PaymentStatus) getStatusColor;

  String translatePaymentStatus(PaymentStatus status) {
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
    final statusColor = getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 16,
            color: statusColor,
          ),
          const SizedBox(height: 3),
          Text(
            '$count',
            style: theme.textTheme.titleSmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            translatePaymentStatus(status),
            style: theme.textTheme.bodySmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w500,
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
