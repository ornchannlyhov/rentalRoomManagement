import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:joul_v2/data/models/receipt.dart';
import 'package:joul_v2/data/models/enum/payment_status.dart';
import 'package:joul_v2/l10n/app_localizations.dart';

class ReceiptCard extends StatefulWidget {
  final Receipt receipt;
  final VoidCallback ontap;
  final VoidCallback onLongPress;
  final VoidCallback onMenuPressed;

  const ReceiptCard({
    required this.receipt,
    required this.ontap,
    required this.onLongPress,
    required this.onMenuPressed,
    super.key,
  });

  @override
  State<ReceiptCard> createState() => _ReceiptCardState();
}

class _ReceiptCardState extends State<ReceiptCard> {
  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return const Color(0xFF10B981);
      case PaymentStatus.pending:
        return const Color(0xFFF59E0B);
      case PaymentStatus.overdue:
        return const Color(0xFFEF4444);
    }
  }

  IconData _getStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return Icons.check_circle;
      case PaymentStatus.pending:
        return Icons.hourglass_empty;
      case PaymentStatus.overdue:
        return Icons.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final receipt = widget.receipt;
    final room = receipt.room;
    final building = room?.building;

    return GestureDetector(
      onTap: widget.ontap,
      onLongPress: widget.onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          color: theme.colorScheme.surfaceContainerHighest,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Status Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getStatusColor(receipt.paymentStatus).withOpacity(0.2),
              ),
              child: Icon(
                _getStatusIcon(receipt.paymentStatus),
                color: _getStatusColor(receipt.paymentStatus),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Receipt Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.room} ${room?.roomNumber ?? l10n.notAvailable}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${l10n.dueDate}: ${DateFormat.yMd().format(receipt.dueDate)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${l10n.building}: ${building?.name ?? l10n.notAvailable}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            // Price and Menu Button
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${receipt.totalPrice.toStringAsFixed(2)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 20,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.more_horiz,
                    color: theme.colorScheme.onSurface,
                    size: 24,
                  ),
                  onPressed: widget.onMenuPressed,
                  tooltip: l10n.menu,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}