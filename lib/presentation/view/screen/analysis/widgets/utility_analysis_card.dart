import 'package:flutter/material.dart';
import 'package:joul_v2/l10n/app_localizations.dart';
import 'package:joul_v2/core/theme/app_theme.dart';

class UtilityAnalysisCard extends StatelessWidget {
  const UtilityAnalysisCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.utilityData,
    required this.totalRevenue,
    required this.formatCurrency,
    this.isBuildingSpecific = false,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Map<String, double> utilityData;
  final double totalRevenue;
  final String Function(double) formatCurrency;
  final bool isBuildingSpecific;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Card(
      color: Theme.of(context).brightness == Brightness.dark
          ? AppTheme.cardColorDark
          : null,
      margin: isBuildingSpecific ? const EdgeInsets.only(top: 8) : null,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: isBuildingSpecific ? 20 : 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: isBuildingSpecific
                      ? Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)
                      : Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            SizedBox(height: isBuildingSpecific ? 12 : 16),
            _UtilityRow(
              title: localizations.water,
              amount: utilityData['water']!,
              icon: Icons.water_drop,
              color: Colors.lightBlue.shade400,
              totalRevenue: totalRevenue,
              formatCurrency: formatCurrency,
              isBuildingSpecific: isBuildingSpecific,
            ),
            _UtilityRow(
              title: localizations.electricity,
              amount: utilityData['electric']!,
              icon: Icons.electrical_services,
              color: Colors.amber.shade600,
              totalRevenue: totalRevenue,
              formatCurrency: formatCurrency,
              isBuildingSpecific: isBuildingSpecific,
            ),
            _UtilityRow(
              title: localizations.room,
              amount: utilityData['room']!,
              icon: Icons.home,
              color: Colors.teal.shade400,
              totalRevenue: totalRevenue,
              formatCurrency: formatCurrency,
              isBuildingSpecific: isBuildingSpecific,
            ),
            _UtilityRow(
              title: localizations.service,
              amount: utilityData['service']!,
              icon: Icons.miscellaneous_services,
              color: Colors.deepPurple.shade400,
              totalRevenue: totalRevenue,
              formatCurrency: formatCurrency,
              isBuildingSpecific: isBuildingSpecific,
            ),
          ],
        ),
      ),
    );
  }
}

class _UtilityRow extends StatelessWidget {
  const _UtilityRow({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    required this.totalRevenue,
    required this.formatCurrency,
    this.isBuildingSpecific = false,
  });

  final String title;
  final double amount;
  final IconData icon;
  final Color color;
  final double totalRevenue;
  final String Function(double) formatCurrency;
  final bool isBuildingSpecific;

  @override
  Widget build(BuildContext context) {
    final percentage = totalRevenue > 0 ? (amount / totalRevenue) * 100 : 0.0;
    final textStyle = isBuildingSpecific
        ? Theme.of(context).textTheme.bodyMedium
        : Theme.of(context).textTheme.bodyLarge;
    final iconSize = isBuildingSpecific ? 18.0 : 20.0;
    final amountFontSize = isBuildingSpecific ? 12.0 : null;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isBuildingSpecific ? 6 : 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: iconSize),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(title, style: textStyle),
          ),
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor:
                    Theme.of(context).colorScheme.outline.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              formatCurrency(amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: amountFontSize,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
