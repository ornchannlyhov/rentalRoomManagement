import 'package:flutter/material.dart';
import 'package:receipts_v2/core/theme/app_theme.dart';
import 'package:receipts_v2/data/models/room.dart';

enum RoomMenuOption {
  edit,
  delete,
}

class RoomCard extends StatelessWidget {
  final Room room;
  final bool status;
  final VoidCallback onTap;
  final Function(RoomMenuOption)? onMenuSelected;

  const RoomCard({
    super.key,
    required this.room,
    required this.status,
    required this.onTap,
    this.onMenuSelected,
  });

  String _getMenuOptionText(RoomMenuOption option) {
    switch (option) {
      case RoomMenuOption.edit:
        return 'កែប្រែ';
      case RoomMenuOption.delete:
        return 'លុប';
    }
  }

  IconData _getMenuOptionIcon(RoomMenuOption option) {
    switch (option) {
      case RoomMenuOption.edit:
        return Icons.edit;
      case RoomMenuOption.delete:
        return Icons.delete;
    }
  }

  Color? _getMenuOptionColor(BuildContext context, RoomMenuOption option) {
    switch (option) {
      case RoomMenuOption.delete:
        return Theme.of(context).colorScheme.error;
      default:
        return null;
    }
  }

  void _showOptionsBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),

              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.meeting_room,
                        color: colorScheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'បន្ទប់ ${room.roomNumber}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.circle,
                                color: status
                                    ? AppTheme.dangerColor
                                    : AppTheme.success,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'ស្ថានភាព: ${status ? 'ជួលហើយ' : 'ទំនេរ'}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 14,
                                ),
                              ),
                            ],
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
                    RoomMenuOption.edit,
                  ),
                  _buildMenuOption(
                    context,
                    theme,
                    RoomMenuOption.delete,
                  ),
                ],
              ),

              // Safe area padding
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuOption(
    BuildContext context,
    ThemeData theme,
    RoomMenuOption option,
  ) {
    final color = _getMenuOptionColor(context, option);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: Icon(
        _getMenuOptionIcon(option),
        color: color ?? colorScheme.primary,
        size: 24,
      ),
      title: Text(
        _getMenuOptionText(option),
        style: theme.textTheme.bodyLarge?.copyWith(
          color: color ?? colorScheme.onSurface,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onMenuSelected?.call(option);
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      tileColor: colorScheme.surface,
      selectedTileColor: colorScheme.primary.withOpacity(0.1),
      splashColor: colorScheme.primary.withOpacity(0.2),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'បន្ទប់ ${room.roomNumber}',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    room.tenant?.name != null
                        ? 'ម្ចាស់បន្ទប់៖ ${room.tenant!.name}'
                        : 'ទំនេរ',
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
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  Icons.circle,
                  color: status ? AppTheme.dangerColor : AppTheme.success,
                  size: 18,
                ),
                if (onMenuSelected != null)
                  Padding(
                    padding: const EdgeInsets.only(
                        top:
                            10.0), 
                    child: GestureDetector(
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
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
