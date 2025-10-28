import 'package:flutter/material.dart';

class GridItem extends StatelessWidget {
  final String label;
  final int amount;
  final IconData icon;
  final Color iconColor;
  final bool border;

  const GridItem({
    super.key,
    this.border = false,
    required this.label,
    required this.amount,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate dynamic sizing based on screen width
    final double baseSize = screenWidth < 400 ? 90.0 : 110.0;
    final double iconSize = screenWidth < 400 ? 16.0 : 20.0;
    final double fontSize = screenWidth < 400 ? 12.0 : 14.0;

    return SizedBox(
      width: baseSize,
      height: baseSize * 0.8, // Maintain aspect ratio
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: border
              ? Border.all(
                  color: colorScheme.onSurface.withOpacity(0.2),
                  width: 0.5,
                )
              : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: iconSize, color: iconColor),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '$amount',
              style: theme.textTheme.titleSmall?.copyWith(
                fontSize: fontSize + 2,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
