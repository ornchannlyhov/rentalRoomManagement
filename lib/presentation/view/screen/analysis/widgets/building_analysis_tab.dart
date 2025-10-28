
import 'package:flutter/material.dart';
import 'package:joul_v2/data/models/receipt.dart';
import 'package:joul_v2/presentation/view/screen/analysis/widgets/month_filter_bar.dart';
import 'package:joul_v2/presentation/view/screen/analysis/widgets/utility_analysis_card.dart';

class BuildingAnalysisTab extends StatelessWidget {
  const BuildingAnalysisTab({super.key, 
    required this.selectedMonth,
    required this.onMonthChanged,
    required this.buildings,
    required this.filteredReceipts,
    required this.expandedBuildings,
    required this.onToggleExpand,
    required this.getBuildingFinancialAnalysis,
    required this.getBuildingUtilityAnalysis,
    required this.formatCurrency,
    required this.monthNames,
    required this.getTotalExpectedRevenue,
  });

  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthChanged;
  final List<dynamic> buildings;
  final List<Receipt> filteredReceipts;
  final Set<String> expandedBuildings;
  final ValueChanged<String> onToggleExpand;
  final Map<String, double> Function(String) getBuildingFinancialAnalysis;
  final Map<String, double> Function(String) getBuildingUtilityAnalysis;
  final String Function(double) formatCurrency;
  final List<String> monthNames;
  final double Function(List<Receipt>) getTotalExpectedRevenue;

  @override
  Widget build(BuildContext context) {
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
          ...buildings.map((building) {
            final analysis = getBuildingFinancialAnalysis(building.id);
            final collectionRate = analysis['total']! > 0
                ? (analysis['paid']! / analysis['total']!) * 100
                : 0.0;
            final isExpanded = expandedBuildings.contains(building.id);
            final buildingReceipts = filteredReceipts
                .where((receipt) => receipt.room?.building?.id == building.id)
                .toList();
            final totalBuildingRevenue =
                getTotalExpectedRevenue(buildingReceipts);

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  InkWell(
                    onTap: () => onToggleExpand(building.id),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.apartment,
                                  color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  building.name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              Text(
                                '${analysis['receiptsCount']!.toInt()} វិក្កយបត្រ',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                isExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _BuildingSummaryRow(
                            label: 'ប្រាក់ចំណូលសរុប:',
                            amount: analysis['total']!,
                            formatCurrency: formatCurrency,
                          ),
                          _BuildingSummaryRow(
                            label: 'បានបង់ប្រាក់:',
                            amount: analysis['paid']!,
                            formatCurrency: formatCurrency,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          _BuildingSummaryRow(
                            label: 'នៅសល់:',
                            amount: analysis['pending']! + analysis['overdue']!,
                            formatCurrency: formatCurrency,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: collectionRate / 100,
                            backgroundColor:  Theme.of(context).colorScheme.outline.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'អត្រាប្រមូល: ${collectionRate.toStringAsFixed(1)}%',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                'ចុចដើម្បីមើលលម្អិត',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isExpanded)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: UtilityAnalysisCard(
                        title: 'ការវិភាគតម្លៃ',
                        icon: Icons.analytics,
                        color: Colors.blue,
                        utilityData: getBuildingUtilityAnalysis(building.id),
                        totalRevenue: totalBuildingRevenue,
                        formatCurrency: formatCurrency,
                        isBuildingSpecific: true,
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _BuildingSummaryRow extends StatelessWidget {
  const _BuildingSummaryRow({
    required this.label,
    required this.amount,
    required this.formatCurrency,
    this.color,
  });

  final String label;
  final double amount;
  final String Function(double) formatCurrency;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            formatCurrency(amount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
