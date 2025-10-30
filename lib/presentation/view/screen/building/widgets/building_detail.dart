// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:joul_v2/presentation/view/screen/building/widgets/screen_type.dart';
import 'package:provider/provider.dart';
import 'package:joul_v2/data/models/building.dart';
import 'package:joul_v2/data/models/enum/mode.dart';
import 'package:joul_v2/data/models/enum/room_status.dart';
import 'package:joul_v2/data/models/room.dart';
import 'package:joul_v2/data/models/service.dart';
import 'package:joul_v2/presentation/providers/building_provider.dart';
import 'package:joul_v2/presentation/providers/room_provider.dart';
import 'package:joul_v2/presentation/providers/service_provider.dart';
import 'package:joul_v2/presentation/providers/tenant_provider.dart';
import 'package:joul_v2/presentation/view/app_widgets/global_snackbar.dart';
import 'package:joul_v2/presentation/view/screen/building/widgets/building_card.dart';
import 'package:joul_v2/presentation/view/screen/building/widgets/building_form.dart';
import 'package:joul_v2/presentation/view/screen/building/widgets/switch_button.dart';
import 'package:joul_v2/presentation/view/screen/building/widgets/room/room_card.dart';
import 'package:joul_v2/presentation/view/screen/building/widgets/room/room_form.dart';
import 'package:joul_v2/presentation/view/screen/building/widgets/service/service_card.dart';
import 'package:joul_v2/presentation/view/screen/building/widgets/service/service_form.dart';
import 'package:joul_v2/l10n/app_localizations.dart';


class BuildingDetail extends StatefulWidget {
  final Building building;

  const BuildingDetail({
    super.key,
    required this.building,
  });

  @override
  State<BuildingDetail> createState() => _BuildingDetailState();
}

class _BuildingDetailState extends State<BuildingDetail> {
  ScreenType _currentScreen = ScreenType.room;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    await Future.wait([
      context.read<RoomProvider>().load(),
      context.read<ServiceProvider>().load(),
      context.read<TenantProvider>().load(),
    ]);
  }

  Future<void> _addRoom() async {
    final l10n = AppLocalizations.of(context)!;
    final newRoom = await Navigator.push<Room>(
      context,
      MaterialPageRoute(
          builder: (context) => RoomForm(building: widget.building)),
    );
    if (newRoom != null && mounted) {
      await context.read<RoomProvider>().createRoom(newRoom);
      _showSuccessMessage(l10n.roomAddedSuccess(newRoom.roomNumber));
    }
  }

  Future<void> _editRoom(Room room) async {
    final l10n = AppLocalizations.of(context)!;
    final updatedRoom = await Navigator.push<Room>(
      context,
      MaterialPageRoute(
        builder: (context) => RoomForm(
          building: widget.building,
          mode: Mode.editing,
          room: room,
        ),
      ),
    );
    if (updatedRoom != null && mounted) {
      await context.read<RoomProvider>().updateRoom(updatedRoom);
      _showSuccessMessage(l10n.roomUpdatedSuccess(updatedRoom.roomNumber));
    }
  }

  Future<void> _deleteRoom(int index, Room room) async {
    final l10n = AppLocalizations.of(context)!;
    if (mounted) {
      final tenantProvider = context.read<TenantProvider>();
      final tenants = tenantProvider.getTenantsByBuilding(widget.building.id);

      for (final tenant in tenants) {
        if (tenant.room!.id == room.id) {
          await tenantProvider.removeRoom(tenant.id);
        }
      }

      await context.read<RoomProvider>().deleteRoom(room.id);

      if (mounted) {
        GlobalSnackBar.show(
          context: context,
          message: l10n.roomDeletedSuccess(room.roomNumber),
        );
      }
    }
  }

  Future<void> _addService() async {
    final l10n = AppLocalizations.of(context)!;
    final newService = await Navigator.push<Service>(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceForm(building: widget.building),
      ),
    );

    if (newService != null && mounted) {
      assert(newService.buildingId == widget.building.id);
      await context.read<ServiceProvider>().createService(newService);
      _showSuccessMessage(l10n.serviceAddedSuccess(newService.name));
    }
  }

  Future<void> _editService(Service service) async {
    final l10n = AppLocalizations.of(context)!;
    final updatedService = await Navigator.push<Service>(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceForm(
          building: widget.building,
          mode: Mode.editing,
          service: service,
        ),
      ),
    );
    if (updatedService != null && mounted) {
      await context.read<ServiceProvider>().updateService(updatedService);
      _showSuccessMessage(l10n.serviceUpdatedSuccess(updatedService.name));
    }
  }

  Future<void> _deleteService(int index, Service service) async {
    final l10n = AppLocalizations.of(context)!;
    if (mounted) {
      await context.read<ServiceProvider>().deleteService(service.id);

      if (mounted) {
        GlobalSnackBar.show(
          context: context,
          message: l10n.serviceDeletedSuccess(service.name),
        );
      }
    }
  }

  Future<void> _editBuilding() async {
    final l10n = AppLocalizations.of(context)!;
    final updatedBuilding = await Navigator.push<Building>(
      context,
      MaterialPageRoute(
        builder: (context) => BuildingForm(
          building: widget.building,
          mode: Mode.editing,
        ),
      ),
    );
    if (updatedBuilding != null && mounted) {
      await context.read<BuildingProvider>().updateBuilding(updatedBuilding);
      _showSuccessMessage(l10n.buildingUpdatedSuccess(updatedBuilding.name));
    }
  }

  Future<void> _deleteBuilding() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _showConfirmDialog(
      title: l10n.deleteBuilding,
      content: l10n.deleteBuildingConfirm(widget.building.name),
    );

    if (confirmed && mounted) {
      final tenantProvider = context.read<TenantProvider>();
      final roomProvider = context.read<RoomProvider>();
      final serviceProvider = context.read<ServiceProvider>();

      final tenants = tenantProvider.getTenantsByBuilding(widget.building.id);
      for (final tenant in tenants) {
        await tenantProvider.removeRoom(tenant.id);
      }

      final rooms = roomProvider.getThisBuildingRooms(widget.building.id);
      for (final room in rooms) {
        await roomProvider.deleteRoom(room.id);
      }

      final services = serviceProvider.services
          .where((s) => s.buildingId == widget.building.id)
          .toList();
      for (final service in services) {
        await serviceProvider.deleteService(service.id);
      }

      await context.read<BuildingProvider>().deleteBuilding(widget.building.id);

      if (mounted) {
        GlobalSnackBar.show(
          context: context,
          message: l10n.buildingDeletedSuccess(widget.building.name),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<bool> _showConfirmDialog({
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

  void _showSuccessMessage(String message) {
    GlobalSnackBar.show(
      context: context,
      message: message,
    );
  }

  Widget _buildRoomContent() {
    final l10n = AppLocalizations.of(context)!;
    return Selector<RoomProvider, dynamic>(
      selector: (_, provider) => provider.roomsState,
      builder: (context, roomsState, _) {
        return roomsState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error) => _buildErrorState(error, _loadData),
          success: (rooms) {
            final buildingRooms = rooms
                .where((r) => r.building!.id == widget.building.id)
                .toList();

            if (buildingRooms.isEmpty) {
              return _buildEmptyStateWithRefresh(
                icon: Icons.bed,
                title: l10n.noRooms,
                subtitle: l10n.pullToRefresh,
                actionText: l10n.addRoom,
                onAction: _addRoom,
              );
            }

            return RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(8),
                itemCount: buildingRooms.length,
                itemBuilder: (context, index) {
                  final room = buildingRooms[index];
                  return _buildDismissibleRoomCard(index, room);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildServiceContent() {
    final l10n = AppLocalizations.of(context)!;
    return Selector<ServiceProvider, dynamic>(
      selector: (_, provider) => provider.servicesState,
      builder: (context, servicesState, _) {
        return servicesState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error) => _buildErrorState(error, _loadData),
          success: (services) {
            final buildingServices = services
                .where((s) => s.buildingId == widget.building.id)
                .toList();

            if (buildingServices.isEmpty) {
              return _buildEmptyStateWithRefresh(
                icon: Icons.room_service,
                title: l10n.noServices,
                subtitle: l10n.pullToRefresh,
                actionText: l10n.addService,
                onAction: _addService,
              );
            }

            return RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(8),
                itemCount: buildingServices.length,
                itemBuilder: (context, index) {
                  final service = buildingServices[index];
                  return _buildDismissibleServiceCard(index, service);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDismissibleRoomCard(int index, Room room) {
    final l10n = AppLocalizations.of(context)!;
    return Dismissible(
      key: Key(room.id),
      background: _buildDismissBackground(),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _showConfirmDialog(
        title: l10n.deleteRoom,
        content: l10n.deleteRoomConfirm(room.roomNumber),
      ),
      onDismissed: (_) => _deleteRoom(index, room),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: RoomCard(
          room: room,
          onTap: () => _editRoom(room),
          status: room.roomStatus == RoomStatus.occupied,
          onMenuSelected: (option) {
            if (option == RoomMenuOption.edit) {
              _editRoom(room);
            } else if (option == RoomMenuOption.delete) {
              _deleteRoom(index, room);
            }
          },
        ),
      ),
    );
  }

  Widget _buildDismissibleServiceCard(int index, Service service) {
    final l10n = AppLocalizations.of(context)!;
    return Dismissible(
      key: Key(service.id),
      background: _buildDismissBackground(),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _showConfirmDialog(
        title: l10n.deleteService,
        content: l10n.deleteServiceConfirm(service.name),
      ),
      onDismissed: (_) => _deleteService(index, service),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ServiceCard(
          service: service,
          onTap: () => _editService(service),
          onMenuSelected: (option) {
            if (option == ServiceMenuOption.edit) {
              _editService(service);
            } else if (option == ServiceMenuOption.delete) {
              _deleteService(index, service);
            }
          },
        ),
      ),
    );
  }

  Widget _buildDismissBackground() {
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

  Widget _buildErrorState(Object error, VoidCallback onRetry) {
    final l10n = AppLocalizations.of(context)!;
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Center(
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
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.tryAgain),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyStateWithRefresh({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: _buildEmptyState(
            icon: icon,
            title: title,
            subtitle: subtitle,
            actionText: actionText,
            onAction: onAction,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add),
            label: Text(actionText),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: Text(widget.building.name),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: BuildingCard(
              building: widget.building,
              onEdit: _editBuilding,
              onDelete: _deleteBuilding,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ScreenSwitchButton(
              onScreenSelected: (screen) =>
                  setState(() => _currentScreen = screen),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _currentScreen == ScreenType.room ? l10n.rooms : l10n.services,
                  style: theme.textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: _currentScreen == ScreenType.room
                      ? _addRoom
                      : _addService,
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  tooltip: _currentScreen == ScreenType.room
                      ? l10n.addRoom
                      : l10n.addService,
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _currentScreen == ScreenType.room
                  ? _buildRoomContent()
                  : _buildServiceContent(),
            ),
          ),
        ],
      ),
    );
  }
}