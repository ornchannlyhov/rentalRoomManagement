import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:receipts_v2/data/models/receipt.dart';

class ReceiptDetailScreen extends StatelessWidget {
  final Receipt receipt;

  const ReceiptDetailScreen({required this.receipt, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasServices = receipt.services.isNotEmpty;
    final hasWaterUsage = receipt.thisWaterUsed > 0;
    final hasElectricUsage = receipt.thisElectricUsed > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('វិក្កយបត្របន្ទប់ ${receipt.room?.roomNumber ?? "N/A"}'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  Text(
                    'វិក្កយបត្រជួលបន្ទប់',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat.yMMMMd('km').format(receipt.date),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Utility usage (only show if has usage)
            if (hasWaterUsage || hasElectricUsage) ...[
              _buildSectionHeader(theme, 'ការប្រើប្រាស់'),
              if (hasWaterUsage) ...[
                _buildInfoRow(
                    theme, 'ទឹកប្រើប្រាស់ខែមុន', '${receipt.lastWaterUsed} m³'),
                _buildInfoRow(
                    theme, 'ទឹកប្រើប្រាស់ខែនេះ', '${receipt.thisWaterUsed} m³'),
              ],
              if (hasElectricUsage) ...[
                _buildInfoRow(theme, 'ភ្លើងប្រើប្រាស់ខែមុន',
                    '${receipt.lastElectricUsed} kWh'),
                _buildInfoRow(theme, 'ភ្លើងប្រើប្រាស់ខែនេះ',
                    '${receipt.thisElectricUsed} kWh'),
              ],
              const SizedBox(height: 8),
              _buildDividerSimple(theme),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 16),

            // Utility usage (only show if has usage)
            if (hasWaterUsage || hasElectricUsage) ...[
              _buildSectionHeader(theme, 'ទូទាត់ការប្រើប្រាស់'),
              if (hasWaterUsage) ...[
                _buildInfoRow(
                    theme, 'ទឹកប្រើប្រាស់', '${receipt.waterUsage} m³'),
                _buildPriceRow(theme, 'ថ្លៃទឹកសរុប', receipt.waterPrice),
              ],
              if (hasElectricUsage) ...[
                _buildInfoRow(theme, 'ភ្លើងប្រើប្រាស់',
                    '${receipt.electricUsage} kWh'),
                _buildPriceRow(
                    theme, 'ថ្លៃភ្លើងសរុប', receipt.electricPrice),
              ],
              const SizedBox(height: 8),
              _buildDividerSimple(theme),
              const SizedBox(height: 8),
            ],

            // Services (only show if has services)
            if (hasServices) ...[
              _buildSectionHeader(theme, 'សេវាកម្មបន្ថែម'),
              Column(
                children: receipt.services
                    .map((service) =>
                        _buildServiceItem(theme, service.name, service.price))
                    .toList(),
              ),
              _buildPriceRow(
                  theme, 'សរុបសេវាកម្ម', receipt.totalServicePrice),
              const SizedBox(height: 8),
              _buildDividerSimple(theme),
              const SizedBox(height: 8),
            ],

            // Rent and total
            _buildPriceRow(
                theme, 'ថ្លៃជួលបន្ទប់', receipt.room?.building?.rentPrice ?? 0),

            const SizedBox(height: 8),
            _buildDividerThick(theme),
            const SizedBox(height: 8),

            // Grand total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'សរុបទឹកប្រាក់',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '฿${receipt.totalPrice.toStringAsFixed(2)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),

            // Footer note
            const SizedBox(height: 16),
            Center(
              child: Text(
                'សូមអរគុណសម្រាប់ការប្រើប្រាស់សេវាកម្មរបស់យើងខ្ញុំ!',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDividerSimple(ThemeData theme) {
    return Divider(
      height: 1,
      color: theme.colorScheme.onSurface.withOpacity(0.1),
    );
  }

  Widget _buildDividerThick(ThemeData theme) {
    return Divider(
      thickness: 2,
      color: theme.colorScheme.primary.withOpacity(0.2),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(ThemeData theme, String label, double price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
          Text(
            '฿${price.toStringAsFixed(2)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(ThemeData theme, String name, double price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              '• $name',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            '฿${price.toStringAsFixed(2)}',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
