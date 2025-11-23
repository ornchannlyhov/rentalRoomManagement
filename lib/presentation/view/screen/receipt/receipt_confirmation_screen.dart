import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:joul_v2/data/models/receipt.dart';
import 'package:joul_v2/data/models/enum/mode.dart';
import 'package:joul_v2/data/models/enum/payment_status.dart';
import 'package:joul_v2/presentation/providers/receipt_provider.dart';
import 'package:joul_v2/presentation/view/app_widgets/global_snackbar.dart';
import 'package:joul_v2/presentation/view/screen/receipt/widgets/receipt_form.dart';
import 'package:joul_v2/l10n/app_localizations.dart';

class ReceiptConfirmationScreen extends StatefulWidget {
  final Receipt receipt;

  const ReceiptConfirmationScreen({super.key, required this.receipt});

  @override
  State<ReceiptConfirmationScreen> createState() =>
      _ReceiptConfirmationScreenState();
}

class _ReceiptConfirmationScreenState extends State<ReceiptConfirmationScreen> {
  bool _isConfirming = false;
  late Receipt _receipt;

  @override
  void initState() {
    super.initState();
    _receipt = widget.receipt;
  }

  Future<void> _handleConfirm() async {
    setState(() => _isConfirming = true);

    try {
      await context.read<ReceiptProvider>().confirmReceipt(_receipt.id);

      if (mounted) {
        GlobalSnackBar.show(
          context: context,
          message: 'Receipt confirmed and sent to tenant',
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        GlobalSnackBar.show(
          context: context,
          message: 'Failed to confirm receipt: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isConfirming = false);
      }
    }
  }

  Future<void> _handleEdit() async {
    final result = await Navigator.of(context).push<Receipt>(
      MaterialPageRoute(
        builder: (ctx) => ReceiptForm(
          mode: Mode.editing,
          receipt: _receipt,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _receipt = result;
      });
    }
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
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
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDividerSimple(ThemeData theme) {
    return Container(
      height: 1,
      color: theme.colorScheme.outline.withOpacity(0.2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final hasServices = _receipt.services.isNotEmpty;
    final hasWaterUsage = _receipt.thisWaterUsed > 0;
    final hasElectricUsage = _receipt.thisElectricUsed > 0;
    final tenant = _receipt.room?.tenant;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: const Text('Confirm Receipt'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          color: theme.colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Notification Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'New usage input received. Please review and confirm to send PDF to tenant.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Header
                Center(
                  child: Column(
                    children: [
                      Text(
                        l10n.receiptForRoom(
                          _receipt.room?.roomNumber ?? l10n.notAvailable,
                        ),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat.yMMMMd('km').format(_receipt.date),
                        style: theme.textTheme.titleSmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tenant Information
                if (tenant != null) ...[
                  _buildSectionHeader(theme, l10n.tenantInfo),
                  _buildInfoRow(theme, l10n.tenantNameLabel, tenant.name),
                  _buildInfoRow(theme, l10n.phoneNumber, tenant.phoneNumber),
                  const SizedBox(height: 8),
                  _buildDividerSimple(theme),
                  const SizedBox(height: 8),
                ],

                // Utility usage
                if (hasWaterUsage || hasElectricUsage) ...[
                  _buildSectionHeader(theme, l10n.utilityUsage),
                  if (hasWaterUsage) ...[
                    _buildInfoRow(theme, l10n.waterPreviousMonth,
                        '${_receipt.lastWaterUsed} m³'),
                    _buildInfoRow(theme, l10n.waterCurrentMonth,
                        '${_receipt.thisWaterUsed} m³'),
                  ],
                  if (hasElectricUsage) ...[
                    _buildInfoRow(theme, l10n.electricPreviousMonth,
                        '${_receipt.lastElectricUsed} kWh'),
                    _buildInfoRow(theme, l10n.electricCurrentMonth,
                        '${_receipt.thisElectricUsed} kWh'),
                  ],
                  const SizedBox(height: 8),
                  _buildDividerSimple(theme),
                  const SizedBox(height: 8),
                ],

                // Price details
                _buildSectionHeader(theme, 'Price Details'),
                _buildInfoRow(theme, l10n.roomRent,
                    '\$${_receipt.roomPrice.toStringAsFixed(2)}'),
                if (hasWaterUsage)
                  _buildInfoRow(theme, 'Water Price',
                      '\$${_receipt.waterPrice.toStringAsFixed(2)}'),
                if (hasElectricUsage)
                  _buildInfoRow(theme, 'Electricity Price',
                      '\$${_receipt.electricPrice.toStringAsFixed(2)}'),
                if (hasServices) ...[
                  const SizedBox(height: 8),
                  _buildDividerSimple(theme),
                  const SizedBox(height: 8),
                  _buildSectionHeader(theme, l10n.services),
                  ..._receipt.services.map((service) {
                    return _buildInfoRow(
                      theme,
                      service.name,
                      '\$${service.price.toStringAsFixed(2)}',
                    );
                  }),
                ],
                const SizedBox(height: 16),
                _buildDividerSimple(theme),
                const SizedBox(height: 16),

                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Price',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      '\$${_receipt.totalPrice.toStringAsFixed(2)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isConfirming ||
                                _receipt.paymentStatus != PaymentStatus.pending
                            ? null
                            : _handleEdit,
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isConfirming ||
                                _receipt.paymentStatus != PaymentStatus.pending
                            ? null
                            : _handleConfirm,
                        icon: _isConfirming
                            ? Container(
                                width: 20,
                                height: 20,
                                padding: const EdgeInsets.all(2),
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline),
                        label: Text(_isConfirming
                            ? 'Sending...'
                            : _receipt.paymentStatus != PaymentStatus.pending
                                ? 'Confirmed'
                                : 'Confirm & Send PDF'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
