import 'dart:io';
import 'package:flutter/material.dart';
import 'package:joul_v2/data/models/tenant.dart';
import 'package:joul_v2/data/models/enum/gender.dart';
import 'package:joul_v2/l10n/app_localizations.dart';

class TenantDetail extends StatelessWidget {
  final Tenant tenant;

  const TenantDetail({
    super.key,
    required this.tenant,
  });

  String _getAvatar() {
    switch (tenant.gender) {
      case Gender.female:
        return 'assets/placeholder/female_avatar.png';
      case Gender.male:
        return 'assets/placeholder/male_avatar.png';
      case Gender.other:
        return 'assets/placeholder/lgbtq+_avatar.png';
    }
  }

  Widget _buildProfileImage(double radius) {
    // If tenant has a profile image, use it
    if (tenant.tenantProfile != null && tenant.tenantProfile!.isNotEmpty) {
      final isNetworkImage = tenant.tenantProfile!.startsWith('http');
      
      if (isNetworkImage) {
        // Network image from API
        return CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey[300],
          backgroundImage: NetworkImage(tenant.tenantProfile!),
          onBackgroundImageError: (exception, stackTrace) {
            // Will fallback to default avatar
          },
          child: ClipOval(
            child: Image.network(
              tenant.tenantProfile!,
              fit: BoxFit.cover,
              width: radius * 2,
              height: radius * 2,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  _getAvatar(),
                  fit: BoxFit.cover,
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
            ),
          ),
        );
      } else {
        // Local file image
        return CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey[300],
          backgroundImage: FileImage(File(tenant.tenantProfile!)),
          onBackgroundImageError: (exception, stackTrace) {
            // Will fallback to default avatar
          },
          child: ClipOval(
            child: Image.file(
              File(tenant.tenantProfile!),
              fit: BoxFit.cover,
              width: radius * 2,
              height: radius * 2,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  _getAvatar(),
                  fit: BoxFit.cover,
                );
              },
            ),
          ),
        );
      }
    }
    
    // Default avatar based on gender
    return CircleAvatar(
      radius: radius,
      backgroundImage: AssetImage(_getAvatar()),
    );
  }

  String _getGenderText(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    switch (tenant.gender) {
      case Gender.male:
        return localizations.male;
      case Gender.female:
        return localizations.female;
      case Gender.other:
        return localizations.other;
    }
  }

  String _getStatusText(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return tenant.isActive ? 'Active' : 'Inactive';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: Text(localizations.tenantInformation),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar and Name Section
            Center(
              child: Column(
                children: [
                  _buildProfileImage(60),
                  const SizedBox(height: 16),
                  Text(
                    tenant.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getGenderText(context),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: tenant.isActive
                              ? Colors.green.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              tenant.isActive
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              size: 14,
                              color: tenant.isActive
                                  ? Colors.green[700]
                                  : Colors.grey[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getStatusText(context),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: tenant.isActive
                                    ? Colors.green[700]
                                    : Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Contact Information Section
            _buildSectionHeader(theme, localizations.contactInformation),
            _buildInfoRow(theme, localizations.phoneNumber, tenant.phoneNumber),
            _buildInfoRow(theme, 'Language', tenant.language.toUpperCase()),

            const SizedBox(height: 8),
            _buildDivider(theme),
            const SizedBox(height: 8),

            // Room Information Section
            _buildSectionHeader(theme, localizations.roomInformation),
            _buildInfoRow(
              theme,
              localizations.building,
              tenant.room?.building?.name ?? localizations.notAvailable,
            ),
            _buildInfoRow(
              theme,
              'Room Number',
              tenant.room?.roomNumber ?? localizations.notAvailable,
            ),
            if (tenant.room?.price != null)
              _buildInfoRow(
                theme,
                localizations.rentalPrice,
                '\$${tenant.room!.price.toStringAsFixed(2)}',
              ),

            const SizedBox(height: 8),
            _buildDivider(theme),
            const SizedBox(height: 8),

            // Financial Information Section
            _buildSectionHeader(theme, 'Financial Information'),
            _buildInfoRow(
              theme,
              'Deposit',
              '\$${tenant.deposit.toStringAsFixed(2)}',
            ),

            const SizedBox(height: 8),
            _buildDivider(theme),
            const SizedBox(height: 8),

            // Account Information Section
            _buildSectionHeader(theme, 'Account Information'),
            _buildInfoRow(
              theme,
              'Created At',
              _formatDate(tenant.createdAt),
            ),
            _buildInfoRow(
              theme,
              'Last Updated',
              _formatDate(tenant.updatedAt),
            ),
            _buildInfoRow(
              theme,
              'Last Interaction',
              _formatDate(tenant.lastInteractionDate),
            ),
            if (tenant.nextReminderDate != null)
              _buildInfoRow(
                theme,
                'Next Reminder',
                _formatDate(tenant.nextReminderDate!),
              ),
            if (tenant.chatId != null)
              _buildInfoRow(
                theme,
                'Chat ID',
                tenant.chatId!,
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildDivider(ThemeData theme) {
    return Divider(
      height: 1,
      color: theme.colorScheme.onSurface.withOpacity(0.1),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}