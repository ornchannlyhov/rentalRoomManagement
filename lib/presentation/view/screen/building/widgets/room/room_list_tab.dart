import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:joul_v2/data/models/building.dart';
import 'package:joul_v2/data/models/enum/mode.dart';
import 'package:joul_v2/data/models/room.dart';
import 'package:joul_v2/data/models/enum/room_status.dart';
import 'package:joul_v2/presentation/providers/room_provider.dart';
import 'package:joul_v2/presentation/providers/tenant_provider.dart';
import 'package:joul_v2/presentation/view/app_widgets/global_snackbar.dart';
import 'package:joul_v2/presentation/view/screen/building/widgets/room/room_card.dart';
import 'package:joul_v2/presentation/view/screen/building/widgets/room/room_form.dart';
import 'package:joul_v2/l10n/app_localizations.dart';

class RoomListTab extends StatelessWidget {
  final Building building;
  final VoidCallback onRefresh;

  const RoomListTab({
    super.key,
    required this.building,
    required this.onRefresh,
  });

  Future<void> _addRoom(BuildContext context) async {
    final newRoom = await Navigator.push<Room>(
      context,
      MaterialPageRoute(
        builder: (context) => RoomForm(building: building),
      ),
    );
    if (newRoom != null && context.mounted) {
      await context.read<RoomProvider>().createRoom(newRoom);
      final l10n = AppLocalizations.of(context)!;
      GlobalSnackBar.show(
        context: context,
        message: l10n.roomAddedSuccess(newRoom.roomNumber),
      );
    }
  }

  Future<void> _editRoom(BuildContext context, Room room) async {
    final updatedRoom = await Navigator.push<Room>(
      context,
      MaterialPageRoute(
        builder: (context) => RoomForm(
          building: building,
          mode: Mode.editing,
          room: room,
        ),
      ),
    );
    if (updatedRoom != null && context.mounted) {
      await context.read<RoomProvider>().updateRoom(updatedRoom);
      final l10n = AppLocalizations.of(context)!;
      GlobalSnackBar.show(
        context: context,
        message: l10n.roomUpdatedSuccess(updatedRoom.roomNumber),
      );
    }
  }

  Future<void> _deleteRoom(BuildContext context, Room room) async {
    if (context.mounted) {
      final tenantProvider = context.read<TenantProvider>();
      final tenants = tenantProvider.getTenantsByBuilding(building.id);

      for (final tenant in tenants) {
        if (tenant.room!.id == room.id) {
          await tenantProvider.removeRoom(tenant.id);
        }
      }

      await context.read<RoomProvider>().deleteRoom(room.id);

      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        GlobalSnackBar.show(
          context: context,
          message: l10n.roomDeletedSuccess(room.roomNumber),
        );
      }
    }
  }

  Future<bool> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Text(
              content,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  l10n.cancel,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: Text(
                  l10n.delete,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onError,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildDismissBackground(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.only(right: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.delete_outline,
            color: Theme.of(context).colorScheme.onError,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.delete,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onError,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bed,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noRooms,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              l10n.noRoomsSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _addRoom(context),
            icon: const Icon(Icons.add),
            label: Text(l10n.addRoom),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.errorOccurred,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.tryAgain),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        // Header with title and add button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.rooms,
                style: theme.textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                onPressed: () => _addRoom(context),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                tooltip: l10n.addRoom,
              ),
            ],
          ),
        ),

        // Content area
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Selector<RoomProvider, dynamic>(
              selector: (_, provider) => provider.roomsState,
              builder: (context, roomsState, _) {
                return roomsState.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error) => RefreshIndicator(
                    onRefresh: () async => onRefresh(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: _buildErrorState(context, error),
                      ),
                    ),
                  ),
                  success: (rooms) {
                    final buildingRooms = rooms
                        .where((r) => r.building!.id == building.id)
                        .toList();

                    if (buildingRooms.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: () async => onRefresh(),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: _buildEmptyState(context),
                          ),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async => onRefresh(),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(8),
                        itemCount: buildingRooms.length,
                        itemBuilder: (context, index) {
                          final room = buildingRooms[index];
                          return Dismissible(
                            key: Key(room.id),
                            background: _buildDismissBackground(context),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) => _showConfirmDialog(
                              context,
                              title: l10n.deleteRoom,
                              content: l10n.deleteRoomConfirm(room.roomNumber),
                            ),
                            onDismissed: (_) => _deleteRoom(context, room),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: RoomCard(
                                room: room,
                                onTap: () => _editRoom(context, room),
                                status: room.roomStatus == RoomStatus.occupied,
                                onMenuSelected: (option) {
                                  if (option == RoomMenuOption.edit) {
                                    _editRoom(context, room);
                                  } else if (option == RoomMenuOption.delete) {
                                    _deleteRoom(context, room);
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
