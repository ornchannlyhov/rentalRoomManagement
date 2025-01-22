import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FilterByMonthButton extends StatefulWidget {
  final Function(int) onMonthSelected;

  const FilterByMonthButton({required this.onMonthSelected, super.key});

  @override
  State<FilterByMonthButton> createState() => _FilterByMonthButtonState();
}

class _FilterByMonthButtonState extends State<FilterByMonthButton> {
  int _selectedMonth = DateTime.now().month;

  void _handleStatusTap(int month) {
    setState(() {
      _selectedMonth = month;
    });
    widget.onMonthSelected(month);
  }

  Widget _buildFilterOption(int month, String label) {
    final bool isSelected = _selectedMonth == month;

    return Expanded(
      child: GestureDetector(
        onTap: () => _handleStatusTap(month),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 20,
          margin: const EdgeInsets.symmetric(horizontal: 4),
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
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = [
      DateTime(now.year, now.month),
      DateTime(now.year, now.month - 1),
      DateTime(now.year, now.month - 2),
    ];

    return Container(
      padding: const EdgeInsets.all(3.0),
      decoration: BoxDecoration(
        color: const Color(0xFF120D1D),
        borderRadius: BorderRadius.circular(30.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: months.map((date) {
          final month = date.month;
          final label = DateFormat.MMMM().format(date);
          return _buildFilterOption(month, label);
        }).toList(),
      ),
    );
  }
}
