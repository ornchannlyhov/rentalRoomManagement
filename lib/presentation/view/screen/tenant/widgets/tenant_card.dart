import 'package:flutter/material.dart';
import 'package:joul_v2/data/models/tenant.dart';
import 'package:joul_v2/data/models/enum/gender.dart';

// Enum for menu options
enum TenantMenuOption {
  edit,
  delete,
  viewDetails,
  changeRoom,
}

class TenantCard extends StatelessWidget {
  final Tenant tenant;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Function(TenantMenuOption)? onMenuSelected;

  const TenantCard({
    super.key,
    required this.tenant,
    required this.onTap,
    required this.onLongPress,
    this.onMenuSelected,
  });

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

  String _getMenuOptionText(TenantMenuOption option) {
    switch (option) {
      case TenantMenuOption.edit:
        return 'កែប្រែ';
      case TenantMenuOption.delete:
        return 'លុប';
      case TenantMenuOption.viewDetails:
        return 'មើលព័ត៌មានលម្អិត';
      case TenantMenuOption.changeRoom:
        return 'ផ្លាស់ប្តូរបន្ទប់';
    }
  }

  IconData _getMenuOptionIcon(TenantMenuOption option) {
    switch (option) {
      case TenantMenuOption.edit:
        return Icons.edit;
      case TenantMenuOption.delete:
        return Icons.delete;
      case TenantMenuOption.viewDetails:
        return Icons.info;
      case TenantMenuOption.changeRoom:
        return Icons.swap_horiz;
    }
  }

  Color? _getMenuOptionColor(BuildContext context, TenantMenuOption option) {
    switch (option) {
      case TenantMenuOption.delete:
        return Theme.of(context).colorScheme.error;
      default:
        return null;
    }
  }

  void _showOptionsBottomSheet(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        getAvatar(),
                        height: 40,
                        width: 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tenant.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'បន្ទប់: ${tenant.room?.roomNumber ?? "មិនមានបន្ទប់"}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Menu options
              ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildMenuOption(
                    context,
                    theme,
                    TenantMenuOption.viewDetails,
                  ),
                  _buildMenuOption(
                    context,
                    theme,
                    TenantMenuOption.edit,
                  ),
                  _buildMenuOption(
                    context,
                    theme,
                    TenantMenuOption.changeRoom,
                  ),
                  _buildMenuOption(
                    context,
                    theme,
                    TenantMenuOption.delete,
                  ),
                ],
              ),

              // Safe area padding
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuOption(
    BuildContext context,
    ThemeData theme,
    TenantMenuOption option,
  ) {
    final color = _getMenuOptionColor(context, option);

    return ListTile(
      leading: Icon(
        _getMenuOptionIcon(option),
        color: color ?? theme.colorScheme.primary,
        size: 20,
      ),
      title: Text(
        _getMenuOptionText(option),
        style: theme.textTheme.titleMedium?.copyWith(
          color: color ?? theme.colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onMenuSelected?.call(option);
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress, // FIXED: Added onLongPress here
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
                    'អគារ: ${tenant.room?.building?.name ?? "មិនស្គាល់បន្ទប់"}',
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
            if (onMenuSelected != null)
              GestureDetector(
                onTap: () => _showOptionsBottomSheet(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.more_horiz,
                    color: colorScheme.onSurface.withOpacity(0.6),
                    size: 24,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
