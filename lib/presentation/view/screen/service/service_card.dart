import 'package:flutter/material.dart';
import 'package:receipts_v2/data/models/service.dart';

// Enum for menu options
enum ServiceMenuOption {
  edit,
  delete,
}

class ServiceCard extends StatelessWidget {
  final Service service;
  final VoidCallback onTap;
  final Function(ServiceMenuOption)? onMenuSelected;

  const ServiceCard({
    super.key,
    required this.service,
    required this.onTap,
    this.onMenuSelected,
  });

  String _getMenuOptionText(ServiceMenuOption option) {
    switch (option) {
      case ServiceMenuOption.edit:
        return 'កែប្រែ';
      case ServiceMenuOption.delete:
        return 'លុប';
    }
  }

  IconData _getMenuOptionIcon(ServiceMenuOption option) {
    switch (option) {
      case ServiceMenuOption.edit:
        return Icons.edit;
      case ServiceMenuOption.delete:
        return Icons.delete;
    }
  }

  Color? _getMenuOptionColor(BuildContext context, ServiceMenuOption option) {
    switch (option) {
      case ServiceMenuOption.delete:
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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.room_service,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'តម្លៃ: ${service.price}\$',
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
                    ServiceMenuOption.edit,
                  ),
                  _buildMenuOption(
                    context,
                    theme,
                    ServiceMenuOption.delete,
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
    ServiceMenuOption option,
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
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'តម្លៃសេវា: ${service.price}\$',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
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
                    color: colorScheme.surfaceVariant.withOpacity(0.5),
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
