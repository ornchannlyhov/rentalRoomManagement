import 'package:flutter/material.dart';
import 'package:receipts_v2/model/enum/payment_status.dart';

class FilterByPaymentButton extends StatefulWidget {
  final Function(PaymentStatus) onStatusSelected;
  const FilterByPaymentButton({required this.onStatusSelected, super.key});

  @override
  State<FilterByPaymentButton> createState() => _FilterButtonState();
}

class _FilterButtonState extends State<FilterByPaymentButton> {
  PaymentStatus _selectedStatus = PaymentStatus.paid;

  void _handleStatusTap(PaymentStatus status) {
    setState(() {
      _selectedStatus = status;
    });
    widget.onStatusSelected(status);
  }

  Widget _buildFilterOption(PaymentStatus status, String label) {
    final bool isSelected = _selectedStatus == status;

    return Expanded(
      child: GestureDetector(
        onTap: () => _handleStatusTap(status),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 18,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF1A0C2D)
                : const Color.fromARGB(255, 18, 13, 29),
            borderRadius: BorderRadius.circular(30.0),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        color: const Color(0xFF120D1D),
        borderRadius: BorderRadius.circular(30.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildFilterOption(PaymentStatus.pending, 'Pending'),
          _buildFilterOption(PaymentStatus.paid, 'Paid'),
          _buildFilterOption(PaymentStatus.overdue, 'Overdue'),
        ],
      ),
    );
  }
}
