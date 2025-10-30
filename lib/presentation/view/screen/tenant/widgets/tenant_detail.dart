import 'package:flutter/material.dart';
import 'package:joul_v2/data/models/tenant.dart';
import 'package:joul_v2/data/models/enum/gender.dart';

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

  String _getGenderText() {
    switch (tenant.gender) {
      case Gender.male:
        return 'បុរស';
      case Gender.female:
        return 'នារី';
      case Gender.other:
        return 'ផ្សេងៗ';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: const Text('ព័ត៌មានអ្នកជួល'),
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
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage(_getAvatar()),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tenant.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          theme.colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getGenderText(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Information Section
            _buildSectionHeader(theme, 'ព័ត៌មានទំនាក់ទំនង'),
            _buildInfoRow(theme, 'លេខទូរស័ព្ទ', tenant.phoneNumber),

            const SizedBox(height: 8),
            _buildDivider(theme),
            const SizedBox(height: 8),

            _buildSectionHeader(theme, 'ព័ត៌មានបន្ទប់'),
            _buildInfoRow(
              theme,
              'អគារ',
              tenant.room?.building?.name ?? 'មិនមាន',
            ),
            _buildInfoRow(
              theme,
              'លេខបន្ទប់',
              tenant.room?.roomNumber ?? 'មិនមាន',
            ),
            if (tenant.room?.price != null)
              _buildInfoRow(
                theme,
                'ថ្លៃជួល',
                '\$${tenant.room!.price.toStringAsFixed(2)}',
              ),
          ],
        ),
      ),
    );
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
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
