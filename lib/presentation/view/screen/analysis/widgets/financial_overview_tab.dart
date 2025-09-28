import 'package:flutter/material.dart';
import 'package:receipts_v2/data/models/receipt.dart';
import 'package:receipts_v2/data/repositories/currency_repositoy.dart';
import 'package:receipts_v2/presentation/view/screen/analysis/widgets/month_filter_bar.dart';
import 'package:receipts_v2/presentation/view/screen/analysis/widgets/utility_analysis_card.dart';

class FinancialOverviewTab extends StatelessWidget {
  const FinancialOverviewTab({super.key, 
    required this.selectedMonth,
    required this.onMonthChanged,
    required this.filteredReceipts,
    required this.selectedCurrency,
    required this.onCurrencyChanged,
    required this.isLoadingRates,
    required this.formatCurrency,
    required this.monthNames,
    required this.getTotalExpectedRevenue,
    required this.getTotalPaidAmount,
    required this.getTotalPendingAmount,
    required this.getTotalOverdueAmount,
  });

  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthChanged;
  final List<Receipt> filteredReceipts;
  final String selectedCurrency;
  final ValueChanged<String?> onCurrencyChanged;
  final bool isLoadingRates;
  final String Function(double) formatCurrency;
  final List<String> monthNames;
  final double Function(List<Receipt>) getTotalExpectedRevenue;
  final double Function(List<Receipt>) getTotalPaidAmount;
  final double Function(List<Receipt>) getTotalPendingAmount;
  final double Function(List<Receipt>) getTotalOverdueAmount;

  @override
  Widget build(BuildContext context) {
    final totalExpected = getTotalExpectedRevenue(filteredReceipts);
    final totalPaid = getTotalPaidAmount(filteredReceipts);
    final totalPending = getTotalPendingAmount(filteredReceipts);
    final totalOverdue = getTotalOverdueAmount(filteredReceipts);
    final totalRemaining = totalPending + totalOverdue;
    final collectionRate =
        totalExpected > 0 ? (totalPaid / totalExpected) * 100 : 0.0;

    double totalWaterCost = 0;
    double totalElectricCost = 0;
    double totalRoomCost = 0;
    double totalServiceCost = 0;

    for (final receipt in filteredReceipts) {
      totalWaterCost += receipt.waterPrice;
      totalElectricCost += receipt.electricPrice;
      totalRoomCost += receipt.roomPrice;
      totalServiceCost += receipt.totalServicePrice;
    }

    final Map<String, double> overallUtilityData = {
      'water': totalWaterCost,
      'electric': totalElectricCost,
      'room': totalRoomCost,
      'service': totalServiceCost,
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          MonthFilterBar(
            selectedMonth: selectedMonth,
            onMonthChanged: onMonthChanged,
            monthNames: monthNames,
          ),
          const SizedBox(height: 16),
          _RevenueOverviewCard(
            totalExpected: totalExpected,
            collectionRate: collectionRate,
            selectedCurrency: selectedCurrency,
            onCurrencyChanged: onCurrencyChanged,
            isLoadingRates: isLoadingRates,
            formatCurrency: formatCurrency,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatusCard(
                  title: 'បានបង់ប្រាក់',
                  amount: totalPaid,
                  color: Theme.of(context).colorScheme.primary,
                  icon: Icons.check_circle,
                  formatCurrency: formatCurrency,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatusCard(
                  title: 'មិនទាន់បង់',
                  amount: totalPending,
                  color: Colors.orange,
                  icon: Icons.pending,
                  formatCurrency: formatCurrency,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatusCard(
                  title: 'ហួសកំណត់',
                  amount: totalOverdue,
                  color: Colors.red,
                  icon: Icons.warning,
                  formatCurrency: formatCurrency,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatusCard(
                  title: 'នៅសល់',
                  amount: totalRemaining,
                  color: Colors.blue,
                  icon: Icons.account_balance,
                  formatCurrency: formatCurrency,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          UtilityAnalysisCard(
            title: 'ការវិភាគតម្លៃ',
            icon: Icons.analytics,
            color: Colors.blue,
            utilityData: overallUtilityData,
            totalRevenue: totalExpected,
            formatCurrency: formatCurrency,
          ),
        ],
      ),
    );
  }
}
class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
    required this.formatCurrency,
  });

  final String title;
  final double amount;
  final Color color;
  final IconData icon;
  final String Function(double) formatCurrency;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            formatCurrency(amount),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}


class _RevenueOverviewCard extends StatelessWidget {
  const _RevenueOverviewCard({
    required this.totalExpected,
    required this.collectionRate,
    required this.selectedCurrency,
    required this.onCurrencyChanged,
    required this.isLoadingRates,
    required this.formatCurrency,
  });

  final double totalExpected;
  final double collectionRate;
  final String selectedCurrency;
  final ValueChanged<String?> onCurrencyChanged;
  final bool isLoadingRates;
  final String Function(double) formatCurrency;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ប្រាក់ចំណូលសរុប',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                isLoadingRates
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : DropdownButton<String>(
                        value: selectedCurrency,
                        underline: Container(),
                        items: CurrencyService.supportedCurrencies.keys
                            .map((currency) => DropdownMenuItem(
                                  value: currency,
                                  child: Text(currency),
                                ))
                            .toList(),
                        onChanged: onCurrencyChanged,
                      ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              formatCurrency(totalExpected),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: collectionRate / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 4),
            Text(
              'អត្រាប្រមូល: ${collectionRate.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}