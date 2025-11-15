import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:joul_v2/data/models/building.dart';
import 'package:joul_v2/data/models/enum/room_status.dart';
import 'package:joul_v2/data/models/room.dart';
import 'package:joul_v2/presentation/providers/room_provider.dart';
import 'package:joul_v2/l10n/app_localizations.dart';

class BuildingCard extends StatelessWidget {
  final Building building;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onViewDetails;

  const BuildingCard({
    super.key,
    required this.building,
    this.onTap,
    this.onLongPress,
    this.onEdit,
    this.onDelete,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final List<Room> rooms = context.select<RoomProvider, List<Room>>(
      (provider) => provider.getThisBuildingRooms(building.id),
    );

    return _AnimatedCardContent(
      building: building,
      rooms: rooms,
      onTap: onTap,
      onLongPress: onLongPress,
      onEdit: onEdit,
      onDelete: onDelete,
      onViewDetails: onViewDetails,
    );
  }
}

class _AnimatedCardContent extends StatelessWidget {
  final Building building;
  final List<Room> rooms;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onViewDetails;

  const _AnimatedCardContent({
    required this.building,
    required this.rooms,
    this.onTap,
    this.onLongPress,
    this.onEdit,
    this.onDelete,
    this.onViewDetails,
  });

  void _showMoreOptionsBottomSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
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
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Building info header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.apartment_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          building.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          l10n.rentPricePerMonth(building.rentPrice),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.7),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Options list
            if (onViewDetails != null)
              ListTile(
                leading: Icon(
                  Icons.visibility_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(l10n.viewDetails),
                onTap: () {
                  Navigator.pop(context);
                  onViewDetails?.call();
                },
              ),

            if (onEdit != null)
              ListTile(
                leading: Icon(
                  Icons.edit_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(l10n.edit),
                onTap: () {
                  Navigator.pop(context);
                  onEdit?.call();
                },
              ),

            if (onDelete != null)
              ListTile(
                leading: const Icon(
                  Icons.delete_rounded,
                  color: Colors.red,
                ),
                title: Text(l10n.delete),
                onTap: () {
                  Navigator.pop(context);
                  onDelete?.call();
                },
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final hasImages = building.buildingImages.isNotEmpty;

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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // ========================================
              // LEFT: Building Image/Icon Avatar
              // ========================================
              _BuildingAvatar(
                building: building,
                hasImages: hasImages,
              ),
              
              const SizedBox(width: 12),

              // ========================================
              // MIDDLE: Building Info (Original Layout)
              // ========================================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      building.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (building.passKey != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        l10n.passKey(building.passKey!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),

                    // Rent price
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.attach_money_rounded,
                            color: theme.colorScheme.primary,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "\$${building.rentPrice}",
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.perMonth,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Utility prices
                    Row(
                      children: [
                        _buildUtilityChip(
                          context,
                          Icons.flash_on_rounded,
                          "\$${building.electricPrice}",
                          Colors.amber,
                          l10n.electricity,
                        ),
                        const SizedBox(width: 8),
                        _buildUtilityChip(
                          context,
                          Icons.water_drop_rounded,
                          "\$${building.waterPrice}",
                          Colors.blue,
                          l10n.water,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ========================================
              // RIGHT: Circular indicator and options
              // ========================================
              Column(
                children: [
                  _CompactCircularIndicator(rooms: rooms),
                  const SizedBox(height: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _showMoreOptionsBottomSheet(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.more_horiz_rounded,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUtilityChip(
    BuildContext context,
    IconData icon,
    String price,
    Color color,
    String label,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                price,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color.withOpacity(0.8),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ========================================
// BUILDING AVATAR (Left side image/icon)
// ========================================
class _BuildingAvatar extends StatelessWidget {
  final Building building;
  final bool hasImages;

  const _BuildingAvatar({
    required this.building,
    required this.hasImages,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImages
          ? _BuildingImage(imagePath: building.buildingImages.first)
          : _BuildingIconPlaceholder(buildingName: building.name),
    );
  }
}

// ========================================
// BUILDING IMAGE
// ========================================
class _BuildingImage extends StatelessWidget {
  final String imagePath;

  const _BuildingImage({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final isLocalFile = !imagePath.startsWith('http');

    return isLocalFile
        ? Image.file(
            File(imagePath),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _BuildingIconPlaceholder(buildingName: 'Building');
            },
          )
        : Image.network(
            imagePath,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return _BuildingIconPlaceholder(buildingName: 'Building');
            },
          );
  }
}

// ========================================
// BUILDING ICON PLACEHOLDER
// ========================================
class _BuildingIconPlaceholder extends StatelessWidget {
  final String buildingName;

  const _BuildingIconPlaceholder({required this.buildingName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Generate a unique color based on building name
    final int hash = buildingName.hashCode;
    final List<Color> gradientColors = [
      Color((hash & 0xFF000000) | 0x00FF7043),
      Color((hash & 0xFF000000) | 0x00EF5350),
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.apartment_rounded,
          size: 40,
          color: Colors.white.withOpacity(0.9),
        ),
      ),
    );
  }
}

// ========================================
// COMPACT CIRCULAR INDICATOR (unchanged)
// ========================================
class _CompactCircularIndicator extends StatelessWidget {
  final List<Room> rooms;

  const _CompactCircularIndicator({required this.rooms});

  int get totalRooms => rooms.length;
  int get occupiedRooms =>
      rooms.where((room) => room.roomStatus == RoomStatus.occupied).length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final progress = totalRooms > 0 ? occupiedRooms / totalRooms : 0;
    final progressColor = progress == 0
        ? theme.colorScheme.outline
        : progress < 0.5
            ? Colors.orange
            : Colors.green;

    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(
              value: double.tryParse(progress.toString()),
              strokeWidth: 4,
              color: progressColor,
              backgroundColor: theme.colorScheme.outline.withOpacity(0.1),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "$occupiedRooms",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: progressColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                l10n.ofTotal(totalRooms),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}