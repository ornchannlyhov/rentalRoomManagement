import 'package:flutter/material.dart';

class UtilityAnalysisCard extends StatelessWidget {
  const UtilityAnalysisCard({
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
    return Card(
      margin: isBuildingSpecific ? const EdgeInsets.only(top: 8) : null,
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
              title: 'ទឹក',
              amount: utilityData['water']!,
              icon: Icons.water_drop,
              color: Colors.blue,
              totalRevenue: totalRevenue,
              formatCurrency: formatCurrency,
              isBuildingSpecific: isBuildingSpecific,
            ),
            _UtilityRow(
              title: 'អគ្គិសនី',
              amount: utilityData['electric']!,
              icon: Icons.electrical_services,
              color: Colors.yellow[700]!,
              totalRevenue: totalRevenue,
              formatCurrency: formatCurrency,
              isBuildingSpecific: isBuildingSpecific,
            ),
            _UtilityRow(
              title: 'បន្ទប់',
              amount: utilityData['room']!,
              icon: Icons.home,
              color: Colors.brown,
              totalRevenue: totalRevenue,
              formatCurrency: formatCurrency,
              isBuildingSpecific: isBuildingSpecific,
            ),
            _UtilityRow(
              title: 'សេវាកម្ម',
              amount: utilityData['service']!,
              icon: Icons.miscellaneous_services,
              color: Colors.purple,
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
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
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
