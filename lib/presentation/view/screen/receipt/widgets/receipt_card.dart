import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:receipts_v2/data/models/receipt.dart';
import 'package:receipts_v2/data/models/enum/payment_status.dart';

class ReceiptCard extends StatefulWidget {
  final Receipt receipt;
  final VoidCallback ontap;
  final VoidCallback onLongPress;

  const ReceiptCard({
    required this.receipt,
    required this.ontap,
    required this.onLongPress,
    super.key,
  });

  @override
  State<ReceiptCard> createState() => _ReceiptCardState();
}

class _ReceiptCardState extends State<ReceiptCard> {
  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return Colors.green;
      case PaymentStatus.pending:
        return Colors.yellow;
      case PaymentStatus.overdue:
        return Colors.red;
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
          color: theme.colorScheme.surfaceVariant,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
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
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'បន្ទប់ ${room?.roomNumber ?? "N/A"}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'កាលបរិច្ឆេទផុតកំណត់: ${DateFormat.yMd().format(receipt.dueDate)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'អាគារ: ${building?.name ?? "N/A"}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '\$${receipt.totalPrice.toStringAsFixed(2)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
