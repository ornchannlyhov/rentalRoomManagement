import 'package:flutter/material.dart';
import 'package:receipts_v2/data/models/tenant.dart';
import 'package:receipts_v2/data/models/enum/gender.dart';

class TenantCard extends StatelessWidget {
  final Tenant tenant;
  final VoidCallback onTap;

  const TenantCard({super.key, required this.tenant, required this.onTap});

  String getAvatar() {
    switch (tenant.gender) {
      case Gender.female:
        return 'assets/avatar/female_avatar.png';
      case Gender.male:
        return 'assets/avatar/male_avatar.png';
      case Gender.other:
        return 'assets/avatar/lgbtq+_avatar.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                getAvatar(),
                height: 70,
                width: 70,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tenant.name,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'អគារ: ${tenant.room!.building!.name}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'លេខបន្ទប់: ${tenant.room?.roomNumber ?? "មិនមានបន្ទប់"}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'លេខទូរស័ព្ទ: ${tenant.phoneNumber}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
