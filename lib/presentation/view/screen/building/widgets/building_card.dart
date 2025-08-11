import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receipts_v2/data/models/building.dart';
import 'package:receipts_v2/data/models/enum/room_status.dart';
import 'package:receipts_v2/data/models/room.dart';
import 'package:receipts_v2/presentation/providers/room_provider.dart';

class BuildingCard extends StatelessWidget {
  final Building building;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const BuildingCard({
    super.key,
    required this.building,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final List<Room> rooms = context.select<RoomProvider, List<Room>>(
      (provider) => provider.getRoomsByBuilding(building.id),
    );

    return _AnimatedCardContent(
      building: building,
      rooms: rooms,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}

class _AnimatedCardContent extends StatelessWidget {
  final Building building;
  final List<Room> rooms;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _AnimatedCardContent({
    required this.building,
    required this.rooms,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Building name with icon
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.apartment_rounded,
                            color: theme.colorScheme.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            building.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Rent price
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
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
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${building.rentPrice}฿",
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "/ខែ",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Utility prices
                    Row(
                      children: [
                        _buildUtilityChip(
                          context,
                          Icons.flash_on_rounded,
                          "អគ្គិសនី",
                          "${building.electricPrice}\$",
                          Colors.amber,
                        ),
                        const SizedBox(width: 8),
                        _buildUtilityChip(
                          context,
                          Icons.water_drop_rounded,
                          "ទឹក",
                          "${building.waterPrice}\$",
                          Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Compact circular indicator
              _CompactCircularIndicator(rooms: rooms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUtilityChip(
    BuildContext context,
    IconData icon,
    String label,
    String price,
    Color color,
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
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              Text(
                price,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactCircularIndicator extends StatelessWidget {
  final List<Room> rooms;

  const _CompactCircularIndicator({required this.rooms});

  int get totalRooms => rooms.length;
  int get occupiedRooms =>
      rooms.where((room) => room.roomStatus == RoomStatus.occupied).length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                "/$totalRooms",
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
