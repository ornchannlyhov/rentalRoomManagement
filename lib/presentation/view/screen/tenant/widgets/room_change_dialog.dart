import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:joul_v2/data/models/enum/room_status.dart';
import 'package:joul_v2/data/models/tenant.dart';
import 'package:joul_v2/l10n/app_localizations.dart';
import 'package:joul_v2/presentation/providers/room_provider.dart';
import 'package:joul_v2/presentation/providers/tenant_provider.dart';

class RoomChangeDialog extends StatelessWidget {
  const RoomChangeDialog({
    super.key,
    required this.tenant,
    required this.onRoomChanged,
    required this.onError,
  });

  final Tenant tenant;
  final Function(dynamic room) onRoomChanged;
  final Function(String message) onError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    final roomProvider = context.read<RoomProvider>();
    final originalRoom = tenant.room;

    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        localizations.roomChanged(tenant.name, '').split(' ')[0], // Gets "Change Room" text
        style: theme.textTheme.titleLarge,
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: roomProvider.roomsState.when(
          loading: () => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 8),
                Text(
                  localizations.loading,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          error: (error) => Text(
            '${localizations.errorLoadingBuildings}: $error',
            style: TextStyle(color: theme.colorScheme.error),
          ),
          success: (rooms) {
            final availableRooms = rooms
                .where((room) =>
                    room.roomStatus == RoomStatus.available ||
                    room.id == tenant.room?.id)
                .toList();

            if (availableRooms.isEmpty) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.meeting_room_outlined,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localizations.noBuildings, // Using as "No available rooms"
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 16,
                    ),
                  ),
                ],
              );
            }

            return SizedBox(
              height: 300,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: availableRooms.length,
                itemBuilder: (context, index) {
                  final room = availableRooms[index];
                  final isCurrentRoom = room.id == tenant.room?.id;

                  return ListTile(
                    leading: Icon(
                      isCurrentRoom ? Icons.check_circle : Icons.meeting_room,
                      color: isCurrentRoom
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    title: Text(
                      '${localizations.room} ${room.roomNumber}',
                      style: TextStyle(
                        fontWeight:
                            isCurrentRoom ? FontWeight.w600 : FontWeight.normal,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      room.building?.name ?? '',
                      style:
                          TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    trailing: isCurrentRoom
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              localizations.paidStatus, // Using as "Current"
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : null,
                    onTap: isCurrentRoom
                        ? null
                        : () async {
                            Navigator.of(context).pop();
                            try {
                              final updatedTenant = tenant.copyWith(room: room);
                              await context
                                  .read<TenantProvider>()
                                  .updateTenant(updatedTenant);

                              if (originalRoom != null) {
                                await roomProvider
                                    .removeTenantFromRoom(originalRoom.id);
                                await roomProvider.updateRoomStatus(
                                    originalRoom.id, RoomStatus.available);
                              }
                              await roomProvider.addTenantToRoom(
                                  room.id, updatedTenant);
                              await roomProvider.updateRoomStatus(
                                  room.id, RoomStatus.occupied);
                              onRoomChanged(room);
                            } catch (e) {
                              onError(localizations.roomChangeFailed);
                            }
                          },
                  );
                },
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            localizations.cancel,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}