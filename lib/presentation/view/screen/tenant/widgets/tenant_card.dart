import 'dart:io';
import 'package:flutter/material.dart';
import 'package:joul_v2/data/models/tenant.dart';
import 'package:joul_v2/data/models/enum/gender.dart';
import 'package:joul_v2/l10n/app_localizations.dart';

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
        return 'assets/placeholder/female_avatar.png';
      case Gender.male:
        return 'assets/placeholder/male_avatar.png';
      case Gender.other:
        return 'assets/placeholder/lgbtq+_avatar.png';
    }
  }

  Widget _buildProfileImage({
    required double size,
    required BorderRadius borderRadius,
  }) {
    // If tenant has a profile image, use it
    if (tenant.tenantProfile != null && tenant.tenantProfile!.isNotEmpty) {
      final isNetworkImage = tenant.tenantProfile!.startsWith('http');

      if (isNetworkImage) {
        // Network image from API
        return ClipRRect(
          borderRadius: borderRadius,
          child: Image.network(
            tenant.tenantProfile!,
            height: size,
            width: size,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: size,
                width: size,
                color: Colors.grey[300],
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              // Fallback to default avatar on error
              return Image.asset(
                getAvatar(),
                height: size,
                width: size,
                fit: BoxFit.cover,
              );
            },
          ),
        );
      } else {
        // Local file image
        return ClipRRect(
          borderRadius: borderRadius,
          child: Image.file(
            File(tenant.tenantProfile!),
            height: size,
            width: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to default avatar on error
              return Image.asset(
                getAvatar(),
                height: size,
                width: size,
                fit: BoxFit.cover,
              );
            },
          ),
        );
      }
    }

    // Default avatar based on gender
    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.asset(
        getAvatar(),
        height: size,
        width: size,
        fit: BoxFit.cover,
      ),
    );
  }

  String _getMenuOptionText(BuildContext context, TenantMenuOption option) {
    final localizations = AppLocalizations.of(context)!;
    switch (option) {
      case TenantMenuOption.edit:
        return localizations.edit;
      case TenantMenuOption.delete:
        return localizations.deleteOption;
      case TenantMenuOption.viewDetails:
        return localizations.viewDetails;
      case TenantMenuOption.changeRoom:
        return localizations.changeRoom;
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
    final localizations = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.background,
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
                    _buildProfileImage(
                      size: 40,
                      borderRadius: BorderRadius.circular(8),
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
                            '${localizations.room}: ${tenant.room?.roomNumber ?? localizations.noRoom}',
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
        _getMenuOptionText(context, option),
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
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        onLongPress: onLongPress,
        child: SizedBox(
          height: 120,
          child: Row(
            children: [
              // Profile image on the left
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: _buildProfileImage(
                  size: 88,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),

              // Tenant details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        tenant.name,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        context,
                        // Assumes 'building' key exists in your localizations
                        'Building',
                        tenant.room?.building?.name ??
                            localizations.unknownRoom,
                      ),
                      const SizedBox(height: 4),
                      _buildInfoRow(
                        context,
                        localizations.room,
                        tenant.room?.roomNumber ?? localizations.notAvailable,
                      ),
                      const SizedBox(height: 4),
                      _buildInfoRow(
                        context,
                        // Assumes 'phone' key exists in your localizations
                        'Phone',
                        tenant.phoneNumber,
                      ),
                    ],
                  ),
                ),
              ),

              // Menu button
              if (onMenuSelected != null)
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded),
                  color: colorScheme.onSurfaceVariant,
                  onPressed: () => _showOptionsBottomSheet(context),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Updated to use text labels instead of icons
  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.9),
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
