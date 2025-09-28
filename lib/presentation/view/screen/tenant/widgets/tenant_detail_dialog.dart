import 'package:flutter/material.dart';
import 'package:receipts_v2/data/models/tenant.dart';

/// A dialog to display detailed information about a tenant.
class TenantDetailDialog extends StatelessWidget {
  const TenantDetailDialog({super.key, required this.tenant});

  final Tenant tenant;

  String _getGenderText(dynamic gender) {
    switch (gender.toString().split('.').last) {
      case 'male':
        return 'បុរស'; // "Male"
      case 'female':
        return 'ស្រី'; // "Female"
      case 'other':
        return 'ផ្សេងទៀត'; // "Other"
      default:
        return 'មិនបានបញ្ជាក់'; // "Not specified"
    }
  }

  Widget _buildDetailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.person, color: theme.colorScheme.primary, size: 24),
          const SizedBox(width: 8),
          Text(
            'ព័ត៌មានលម្អិត', // "Detailed Information"
            style: theme.textTheme.titleLarge,
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow(theme, 'ឈ្មោះ', tenant.name), // "Name"
            _buildDetailRow(
                theme, 'លេខទូរស័ព្ទ', tenant.phoneNumber), // "Phone Number"
            _buildDetailRow(
                theme, 'ភេទ', _getGenderText(tenant.gender)), // "Gender"
            if (tenant.room != null) ...[
              _buildDetailRow(
                  theme, 'អគារ', tenant.room!.building!.name), // "Building"
              _buildDetailRow(
                  theme, 'លេខបន្ទប់', tenant.room!.roomNumber), // "Room Number"
            ] else
              _buildDetailRow(theme, 'បន្ទប់',
                  'មិនមានបន្ទប់'), // "Room" : "No room assigned"
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'បិទ', // "Close"
            style: TextStyle(color: theme.colorScheme.primary),
          ),
        ),
      ],
    );
  }
}
