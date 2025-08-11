import 'package:flutter/material.dart';
import 'package:receipts_v2/core/app_theme.dart';
import 'package:receipts_v2/data/models/room.dart';

class RoomCard extends StatelessWidget {
  final Room room;
  final bool status;
  final VoidCallback onTap;

  const RoomCard({
    super.key,
    required this.room,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius:
              BorderRadius.circular(12), // match your cardTheme radius
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'បន្ទប់ ${room.roomNumber}', // "Room" in Khmer
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                Icon(
                  Icons.circle,
                  color: status ? AppTheme.dangerColor : AppTheme.success,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'ម្ចាស់បន្ទប់៖ ${room.tenant?.name ?? 'មិនស្គាល់'}',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
            Text(
              'តម្លៃជួល៖ ${room.price}\$',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
