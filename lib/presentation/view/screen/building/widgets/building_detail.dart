// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
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
    final newRoom = await Navigator.push<Room>(
      context,
      MaterialPageRoute(
          builder: (context) => RoomForm(building: widget.building)),
    );
    if (newRoom != null && mounted) {
      await context.read<RoomProvider>().createRoom(newRoom);
      _showSuccessMessage('បន្ថែមបន្ទប់ "${newRoom.roomNumber}" ដោយជោគជ័យ');
    }
  }

  Future<void> _editRoom(Room room) async {
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
      _showSuccessMessage('កែប្រែបន្ទប់ "${updatedRoom.roomNumber}" ដោយជោគជ័យ');
    }
  }

  Future<void> _deleteRoom(int index, Room room) async {
    final confirmed = await _showConfirmDialog(
      title: 'លុបបន្ទប់',
      content: 'តើអ្នកចង់លុបបន្ទប់ "${room.roomNumber}"?',
    );

    if (confirmed && mounted) {
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
          message: 'បានលុបបន្ទប់ "${room.roomNumber}" ជោគជ័យ',
          onRestore: () async {
            await context.read<RoomProvider>().restoreRoom(index, room);
            _showSuccessMessage('បានស្ដារបន្ទប់ "${room.roomNumber}" ជោគជ័យ');
          },
        );
      }
    }
  }

  Future<void> _addService() async {
    final newService = await Navigator.push<Service>(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceForm(building: widget.building),
      ),
    );

    if (newService != null && mounted) {
      assert(newService.buildingId == widget.building.id);
      await context.read<ServiceProvider>().createService(newService);
      _showSuccessMessage('បន្ថែមសេវា "${newService.name}" ដោយជោគជ័យ');
    }
  }

  Future<void> _editService(Service service) async {
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
      _showSuccessMessage('កែប្រែសេវា "${updatedService.name}" ដោយជោគជ័យ');
    }
  }

  Future<void> _deleteService(int index, Service service) async {
    final confirmed = await _showConfirmDialog(
      title: 'លុបសេវា',
      content: 'តើអ្នកចង់លុបសេវា "${service.name}"?',
    );

    if (confirmed && mounted) {
      final serviceData = service;

      await context.read<ServiceProvider>().deleteService(service.id);

      if (mounted) {
        GlobalSnackBar.show(
          context: context,
          message: 'បានលុបសេវា "${service.name}" ជោគជ័យ',
          onRestore: () async {
            await context
                .read<ServiceProvider>()
                .restoreService(index, serviceData);
            _showSuccessMessage('បានស្ដារសេវា "${service.name}" ជោគជ័យ');
          },
        );
      }
    }
  }

  Future<void> _editBuilding() async {
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
      _showSuccessMessage('កែប្រែអគារ "${updatedBuilding.name}" ដោយជោគជ័យ');
    }
  }

  Future<void> _deleteBuilding() async {
    final confirmed = await _showConfirmDialog(
      title: 'លុបអគារ',
      content: 'តើអ្នកចង់លុបអគារ "${widget.building.name}"?',
    );

    if (confirmed && mounted) {
      final tenantProvider = context.read<TenantProvider>();
      final roomProvider = context.read<RoomProvider>();
      final serviceProvider = context.read<ServiceProvider>();

      // Remove associated tenants
      final tenants = tenantProvider.getTenantsByBuilding(widget.building.id);
      for (final tenant in tenants) {
        await tenantProvider.removeRoom(tenant.id);
      }

      // Remove associated rooms
      final rooms = roomProvider.getThisBuildingRooms(widget.building.id);
      for (final room in rooms) {
        await roomProvider.deleteRoom(room.id);
      }

      // Remove associated services
      final services = serviceProvider.services
          .where((s) => s.buildingId == widget.building.id)
          .toList();
      for (final service in services) {
        await serviceProvider.deleteService(service.id);
      }

      // Delete the building
      await context.read<BuildingProvider>().deleteBuilding(widget.building.id);

      if (mounted) {
        GlobalSnackBar.show(
          context: context,
          message: 'បានលុបអគារ "${widget.building.name}" ជោគជ័យ',
        );
        Navigator.pop(context); // Return to previous screen
      }
    }
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String content,
  }) async {
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
                  'បោះបង់',
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
                  'លុប',
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
                title: 'គ្មានបន្ទប់',
                subtitle: 'ទាញចុះដើម្បីផ្ទុកទិន្នន័យឡើងវិញ',
                actionText: 'បន្ថែមបន្ទប់',
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
                title: 'គ្មានសេវា',
                subtitle: 'ទាញចុះដើម្បីផ្ទុកទិន្នន័យឡើងវិញ',
                actionText: 'បន្ថែមសេវា',
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
    return Dismissible(
      key: Key(room.id),
      background: _buildDismissBackground(),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _showConfirmDialog(
        title: 'លុបបន្ទប់',
        content: 'តើអ្នកចង់លុបបន្ទប់ "${room.roomNumber}"?',
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
    return Dismissible(
      key: Key(service.id),
      background: _buildDismissBackground(),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _showConfirmDialog(
        title: 'លុបសេវា',
        content: 'តើអ្នកចង់លុបសេវា "${service.name}"?',
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
            'លុប',
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
                  'មានកំហុស',
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
                  label: const Text('ព្យាយាមម្តងទៀត'),
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
                  _currentScreen == ScreenType.room ? 'បន្ទប់' : 'សេវា',
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
                      ? 'បន្ថែមបន្ទប់'
                      : 'បន្ថែមសេវា',
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
