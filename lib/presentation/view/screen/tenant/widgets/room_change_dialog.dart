import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receipts_v2/data/models/enum/room_status.dart';
import 'package:receipts_v2/data/models/tenant.dart';
import 'package:receipts_v2/presentation/providers/room_provider.dart';
import 'package:receipts_v2/presentation/providers/tenant_provider.dart';

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
    final roomProvider = context.read<RoomProvider>();
    final originalRoom = tenant.room;

    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'ផ្លាស់ប្តូរបន្ទប់', // "Change Room"
        style: theme.textTheme.titleLarge,
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: roomProvider.roomsState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error) => Text(
            'Error loading rooms: $error',
            style: TextStyle(color: theme.colorScheme.error),
          ),
          success: (rooms) {
            final availableRooms = rooms
                .where((room) =>
                    room.roomStatus == RoomStatus.available ||
                    room.id == tenant.room?.id)
                .toList();

            if (availableRooms.isEmpty) {
              return Text(
                'មិនមានបន្ទប់ទំនេរ', // "No available rooms"
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              );
            }

            return SizedBox(
              height: 300, // Constrain height for scrollability
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
                      'បន្ទប់ ${room.roomNumber}', // "Room ${room.roomNumber}"
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
                        ? Text(
                            'បន្ទប់បច្ចុប្បន្ន', // "Current room"
                            style: TextStyle(
                                color: theme.colorScheme.primary, fontSize: 12),
                          )
                        : null,
                    onTap: isCurrentRoom
                        ? null
                        : () async {
                            Navigator.of(context).pop(); // Close dialog
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
                              onError(
                                  'មានបញ្ហាក្នុងការផ្លាស់ប្តូរបន្ទប់'); // "Error changing room"
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
            'បោះបង់', // "Cancel"
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}