import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receipts_v2/data/models/building.dart';
import 'package:receipts_v2/data/models/enum/mode.dart';
import 'package:receipts_v2/data/models/enum/room_status.dart';
import 'package:receipts_v2/data/models/room.dart';
import 'package:receipts_v2/data/models/service.dart';
import 'package:receipts_v2/presentation/providers/room_provider.dart';
import 'package:receipts_v2/presentation/providers/service_provider.dart';
import 'package:receipts_v2/presentation/providers/tenant_provider.dart';
import 'package:receipts_v2/presentation/view/screen/building/widgets/building_card.dart';
import 'package:receipts_v2/presentation/view/screen/building/widgets/switch_button.dart';
import 'package:receipts_v2/presentation/view/screen/room/room_card.dart';
import 'package:receipts_v2/presentation/view/screen/room/room_form.dart';
import 'package:receipts_v2/presentation/view/screen/service/service_card.dart';
import 'package:receipts_v2/presentation/view/screen/service/service_form.dart';

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

  Future<void> _loadData() async {
    if (!mounted) return;
    await Future.wait([
      context.read<RoomProvider>().load(),
      context.read<ServiceProvider>().load(),
      context.read<TenantProvider>().load(),
    ]);
  }

  Future<void> _refreshData() async {
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('ទិន្នន័យ​ត្រូវបានកែប្រែ'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
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

  Future<void> _deleteRoom(Room room) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('លុបបន្ទប់'),
            content: Text('តើអ្នកចង់លុបបន្ទប់ "${room.roomNumber}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('បោះបង់'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('លុប'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed && mounted) {
      // Get tenants associated with the room's building
      final tenantProvider = context.read<TenantProvider>();
      final tenants = tenantProvider.getTenantByBuilding(widget.building.id);

      for (final tenant in tenants) {
        if (tenant.room!.id == room.id) {
          await tenantProvider.removeRoom(tenant.id);
        }
      }

      // Delete the room from RoomProvider
      await context.read<RoomProvider>().deleteRoom(room.id);
      _showSuccessMessage('បានលុបបន្ទប់ "${room.roomNumber}" ជោគជ័យ');
    }
  }

  Future<void> _deleteService(Service service) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('លុបសេវា'),
            content: Text('តើ​អ្នកចង់លុបសេវា "${service.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('បោះបង់'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('លុប'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed && mounted) {
      await context.read<ServiceProvider>().deleteService(service.id);
      _showSuccessMessage('បានលុបសេវា "${service.name}" ជោគជ័យ');
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildRoomContent() {
    return Consumer<RoomProvider>(
      builder: (context, provider, _) {
        return provider.rooms.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error) => Center(child: Text('មានកំហុស: $error')),
          success: (rooms) {
            final buildingRooms = rooms
                .where((r) => r.building!.id == widget.building.id)
                .toList();
            return buildingRooms.isEmpty
                ? _buildEmptyState(
                    icon: Icons.bed,
                    title: 'គ្មានបន្ទប់',
                    actionText: 'បន្ថែមបន្ទប់',
                    onAction: _addRoom,
                  )
                : RefreshIndicator(
                    onRefresh: _refreshData,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: buildingRooms.length,
                      itemBuilder: (context, index) {
                        final room = buildingRooms[index];
                        return Dismissible(
                          key: Key(room.id),
                          background: Container(
                            alignment: Alignment.centerRight,
                            color: Colors.red,
                            child: const Padding(
                              padding: EdgeInsets.only(right: 20),
                              child: Icon(Icons.delete, color: Colors.white),
                            ),
                          ),
                          onDismissed: (_) => _deleteRoom(room),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: RoomCard(
                              room: room,
                              onTap: () => _editRoom(room),
                              status: room.roomStatus == RoomStatus.occupied,
                            ),
                          ),
                        );
                      },
                    ),
                  );
          },
        );
      },
    );
  }

  Widget _buildServiceContent() {
    return Consumer<ServiceProvider>(
      builder: (context, provider, _) {
        return provider.services.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error) => Center(child: Text('មានកំហុស: $error')),
          success: (services) {
            final buildingServices = services
                .where((s) => s.buildingId == widget.building.id)
                .toList();
            return buildingServices.isEmpty
                ? _buildEmptyState(
                    icon: Icons.room_service,
                    title: 'គ្មានសេវា',
                    actionText: 'បន្ថែមសេវា',
                    onAction: _addService,
                  )
                : RefreshIndicator(
                    onRefresh: _refreshData,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: buildingServices.length,
                      itemBuilder: (context, index) {
                        final service = buildingServices[index];
                        return Dismissible(
                          key: Key(service.id),
                          background: Container(
                            alignment: Alignment.centerRight,
                            color: Colors.red,
                            child: const Padding(
                              padding: EdgeInsets.only(right: 20),
                              child: Icon(Icons.delete, color: Colors.white),
                            ),
                          ),
                          onDismissed: (_) => _deleteService(service),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ServiceCard(
                              service: service,
                              onTap: () => _editService(service),
                            ),
                          ),
                        );
                      },
                    ),
                  );
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onAction,
            child: Text(actionText),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.building.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: BuildingCard(building: widget.building),
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
                  style: theme.textTheme.titleMedium,
                ),
                IconButton(
                  icon: Icon(
                    _currentScreen == ScreenType.room ? Icons.add : Icons.add,
                    size: 20,
                  ),
                  onPressed: _currentScreen == ScreenType.room
                      ? _addRoom
                      : _addService,
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
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
