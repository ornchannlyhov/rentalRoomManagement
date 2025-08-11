import 'package:flutter/material.dart';
import 'package:receipts_v2/data/models/enum/payment_status.dart';

class FilterByPaymentButton extends StatefulWidget {
  final Function(PaymentStatus) onStatusSelected;
  final PaymentStatus initialStatus;

  const FilterByPaymentButton({
    required this.onStatusSelected,
    this.initialStatus = PaymentStatus.paid,
    super.key,
  });

  @override
  State<FilterByPaymentButton> createState() => _FilterButtonState();
}

class _FilterButtonState extends State<FilterByPaymentButton> {
  late PaymentStatus _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus;
  }

  void _handleStatusTap(PaymentStatus status) {
    if (_selectedStatus == status) return;

    setState(() => _selectedStatus = status);
    widget.onStatusSelected(status);
  }

  String _khmerLabel(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'កំពុងរងចាំ';
      case PaymentStatus.paid:
        return 'បានបង់';
      case PaymentStatus.overdue:
        return 'ហួសកំណត់';
    }
  }

  Color _statusColor(PaymentStatus status, ThemeData theme) {
    switch (status) {
      case PaymentStatus.pending:
        return Colors.amber;
      case PaymentStatus.paid:
        return Colors.green;
      case PaymentStatus.overdue:
        return Colors.red;
    }
  }

  Widget _buildFilterOption(
    BuildContext context,
    PaymentStatus status,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isSelected = _selectedStatus == status;
    final statusColor = _statusColor(status, theme);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _handleStatusTap(status),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            height: 28,
            decoration: BoxDecoration(
              color: isSelected
                  ? statusColor.withOpacity(0.9)
                  : colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? statusColor
                    : colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: statusColor.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                _khmerLabel(status),
                style: theme.textTheme.labelMedium?.copyWith(
                  color:
                      isSelected ? Colors.white : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildFilterOption(context, PaymentStatus.pending),
          _buildFilterOption(context, PaymentStatus.paid),
          _buildFilterOption(context, PaymentStatus.overdue),
        ],
      ),
    );
  }
}
