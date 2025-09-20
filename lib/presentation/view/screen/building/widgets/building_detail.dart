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
      _showSnackBar(
        message: 'ទិន្នន័យ​ត្រូវបានកែប្រែ',
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: Icons.refresh,
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
                child: Text(
                  'លុប',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
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
      _showSnackBar(
        message: 'បានលុបបន្ទប់ "${room.roomNumber}" ជោគជ័យ',
        backgroundColor: Theme.of(context).colorScheme.error,
        icon: Icons.delete,
      );
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
                child: Text(
                  'លុប',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed && mounted) {
      await context.read<ServiceProvider>().deleteService(service.id);
      _showSnackBar(
        message: 'បានលុបសេវា "${service.name}" ជោគជ័យ',
        backgroundColor: Theme.of(context).colorScheme.error,
        icon: Icons.delete,
      );
    }
  }

  void _showSuccessMessage(String message) {
    _showSnackBar(
      message: message,
      backgroundColor: Colors.green.shade600,
      icon: Icons.check_circle,
    );
  }

  void _showSnackBar({
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 6,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'បិទ',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Widget _buildRoomContent() {
    return Consumer<RoomProvider>(
      builder: (context, provider, _) {
        return provider.rooms.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error) => RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: Center(child: Text('មានកំហុស: $error')),
              ),
            ),
          ),
          success: (rooms) {
            final buildingRooms = rooms
                .where((r) => r.building!.id == widget.building.id)
                .toList();
            return buildingRooms.isEmpty
                ? RefreshIndicator(
                    onRefresh: _refreshData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: _buildEmptyState(
                          icon: Icons.bed,
                          title: 'គ្មានបន្ទប់',
                          subtitle: 'ទាញចុះដើម្បីផ្ទុកទិន្នន័យឡើងវិញ',
                          actionText: 'បន្ថែមបន្ទប់',
                          onAction: _addRoom,
                        ),
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _refreshData,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(8),
                      itemCount: buildingRooms.length,
                      itemBuilder: (context, index) {
                        final room = buildingRooms[index];
                        return Dismissible(
                          key: Key(room.id),
                          background: Container(
                            alignment: Alignment.centerRight,
                            decoration: BoxDecoration(
                              color: Colors.red.shade600,
                              borderRadius: BorderRadius.circular(12),
                            ),
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
          error: (error) => RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: Center(child: Text('មានកំហុស: $error')),
              ),
            ),
          ),
          success: (services) {
            final buildingServices = services.toList();
            return buildingServices.isEmpty
                ? RefreshIndicator(
                    onRefresh: _refreshData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: _buildEmptyState(
                          icon: Icons.room_service,
                          title: 'គ្មានសេវា',
                          subtitle: 'ទាញចុះដើម្បីផ្ទុកទិន្នន័យឡើងវិញ',
                          actionText: 'បន្ថែមសេវា',
                          onAction: _addService,
                        ),
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _refreshData,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(8),
                      itemCount: buildingServices.length,
                      itemBuilder: (context, index) {
                        final service = buildingServices[index];
                        return Dismissible(
                          key: Key(service.id),
                          background: Container(
                            alignment: Alignment.centerRight,
                            decoration: BoxDecoration(
                              color: Colors.red.shade600,
                              borderRadius: BorderRadius.circular(12),
                            ),
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(widget.building.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'ផ្ទុកទិន្នន័យឡើងវិញ',
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
                  style: theme.textTheme.titleLarge,
                ),
                IconButton(
                  icon: Icon(
                    Icons.add,
                    size: 20,
                  ),
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
