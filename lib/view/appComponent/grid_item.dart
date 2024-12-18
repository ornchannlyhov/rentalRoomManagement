import 'package:flutter/material.dart';

class GridItem extends StatelessWidget {
  final Color gridColor;
  final String label;
  final int amount;
  final IconData icon;
  final Color iconColor;
  final bool border;

  const GridItem({
    super.key,
    this.border = false,
    required this.gridColor,
    required this.label,
    required this.amount,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.27,
      height: 80,
      decoration: BoxDecoration(
        color: gridColor,
        border: border ? Border.all(color: Colors.white, width: 0.1) : null,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$amount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
