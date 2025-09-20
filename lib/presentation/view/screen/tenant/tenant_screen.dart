// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receipts_v2/data/models/enum/mode.dart';
import 'package:receipts_v2/data/models/enum/room_status.dart';
import 'package:receipts_v2/data/models/tenant.dart';
import 'package:receipts_v2/presentation/providers/building_provider.dart';
import 'package:receipts_v2/presentation/providers/room_provider.dart';
import 'package:receipts_v2/presentation/providers/tenant_provider.dart';
import 'package:receipts_v2/presentation/view/app_widgets/app_bar.dart';
import 'package:receipts_v2/presentation/view/screen/tenant/widgets/tenant_card.dart';
import 'package:receipts_v2/presentation/view/screen/tenant/widgets/tenant_form.dart';

class TenantScreen extends StatefulWidget {
  const TenantScreen({super.key});

  @override
  State<TenantScreen> createState() => _TenantScreenState();
}

class _TenantScreenState extends State<TenantScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String? _selectedBuildingId;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final tenantProvider = context.read<TenantProvider>();
    final roomProvider = context.read<RoomProvider>();
    final buildingProvider = context.read<BuildingProvider>();

    await Future.wait([
      tenantProvider.load(),
      roomProvider.load(),
      buildingProvider.load(),
    ]);
    _animationController.forward();
  }

  Future<void> _addTenant(BuildContext context) async {
    final newTenant = await Navigator.of(context).push<Tenant>(
      MaterialPageRoute(
        builder: (ctx) => TenantForm(
          mode: Mode.creating,
          selectedBuildingId:
              _selectedBuildingId, 
        ),
      ),
    );

    if (newTenant != null) {
      final tenantProvider = context.read<TenantProvider>();
      final roomProvider = context.read<RoomProvider>();

      await tenantProvider.createTenant(newTenant);
      if (newTenant.room != null) {
        await roomProvider.addTenant(newTenant.room!.id, newTenant);
        await roomProvider.updateRoomStatus(
            newTenant.room!.id, RoomStatus.occupied);
      }
    }
  }

  Future<void> _editTenant(BuildContext context, Tenant tenant) async {
    final updatedTenant = await Navigator.of(context).push<Tenant>(
      MaterialPageRoute(
        builder: (ctx) => TenantForm(
          mode: Mode.editing,
          tenant: tenant,
        ),
      ),
    );

    if (updatedTenant != null) {
      final tenantProvider = context.read<TenantProvider>();
      final roomProvider = context.read<RoomProvider>();

      await tenantProvider.updateTenant(updatedTenant);

      if (updatedTenant.room?.id != tenant.room?.id) {
        await roomProvider.removeTenant(tenant.room?.id ?? '');
        await roomProvider.addTenant(updatedTenant.room!.id, updatedTenant);
        await roomProvider.updateRoomStatus(
            tenant.room?.id ?? '', RoomStatus.available);
        await roomProvider.updateRoomStatus(
            updatedTenant.room!.id, RoomStatus.occupied);
      }
    }
  }

  void _viewTenantDetails(BuildContext context, Tenant tenant) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.person,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'ព័ត៌មានលម្អិត', // "Detailed Information"
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(theme, 'ឈ្មោះ', tenant.name), // "Name"
              _buildDetailRow(
                  theme, 'លេខទូរស័ព្ទ', tenant.phoneNumber), // "Phone Number"
              _buildDetailRow(
                  theme, 'ភេទ', _getGenderText(tenant.gender)), // "Gender"
              if (tenant.room != null) ...[
                _buildDetailRow(
                    theme, 'អគារ', tenant.room!.building!.name), // "Building"
                _buildDetailRow(theme, 'លេខបន្ទប់',
                    tenant.room!.roomNumber), // "Room Number"
              ] else
                _buildDetailRow(theme, 'បន្ទប់',
                    'មិនមានបន្ទប់'), // "Room" : "No room assigned"
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'បិទ', // "Close"
              style: TextStyle(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getGenderText(dynamic gender) {
    // Assuming Gender is an enum with values like Gender.male, Gender.female, Gender.other
    switch (gender.toString().split('.').last) {
      case 'male':
        return 'បុរស'; // "Male"
      case 'female':
        return 'ស្រី'; // "Female"
      case 'other':
        return 'ផ្សេងទៀត'; // "Other"
      default:
        return 'មិនបានបញ្ជាក់'; // "Not specified"
    }
  }

  void _changeRoom(BuildContext context, Tenant tenant) {
    final theme = Theme.of(context);
    final roomProvider = context.read<RoomProvider>();

    // Show room selection dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'ផ្លាស់ប្តូរបន្ទប់', // "Change Room"
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: roomProvider.rooms.when(
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
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
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
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
                        'បន្ទប់ ${room.roomNumber}', // "Room ${room.roomNumber}"
                        style: TextStyle(
                          fontWeight: isCurrentRoom
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        room.building?.name ?? '',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: isCurrentRoom
                          ? Text(
                              'បន្ទប់បច្ចុប្បន្ន', // "Current room"
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontSize: 12,
                              ),
                            )
                          : null,
                      onTap: isCurrentRoom
                          ? null
                          : () async {
                              Navigator.of(context).pop();

                              // Update tenant's room
                              final updatedTenant = tenant.copyWith(room: room);
                              final tenantProvider =
                                  context.read<TenantProvider>();

                              try {
                                // Update tenant
                                await tenantProvider
                                    .updateTenant(updatedTenant);

                                // Update room statuses
                                if (tenant.room != null) {
                                  await roomProvider
                                      .removeTenant(tenant.room!.id);
                                  await roomProvider.updateRoomStatus(
                                      tenant.room!.id, RoomStatus.available);
                                }

                                await roomProvider.addTenant(
                                    room.id, updatedTenant);
                                await roomProvider.updateRoomStatus(
                                    room.id, RoomStatus.occupied);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'បានផ្លាស់ប្តូរបន្ទប់សម្រាប់ ${tenant.name} ទៅបន្ទប់ ${room.roomNumber}',
                                      // "Room changed for ${tenant.name} to room ${room.roomNumber}"
                                    ),
                                    backgroundColor: theme.colorScheme.primary,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'មានបញ្ហាក្នុងការផ្លាស់ប្តូរបន្ទប់', // "Error changing room"
                                    ),
                                    backgroundColor: theme.colorScheme.error,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
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
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTenant(BuildContext context, Tenant tenant) async {
    final theme = Theme.of(context);

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'បញ្ជាក់ការលុប', // "Confirm Delete"
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'តើអ្នកពិតជាចង់លុបអ្នកជួល "${tenant.name}" មែនទេ?',
          // "Are you sure you want to delete tenant '${tenant.name}'?"
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'បោះបង់', // "Cancel"
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: Text(
              'លុប', // "Delete"
              style: TextStyle(
                color: theme.colorScheme.onError,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      final tenantProvider = context.read<TenantProvider>();
      final roomProvider = context.read<RoomProvider>();

      try {
        await tenantProvider.deleteTenant(tenant.id);
        if (tenant.room != null) {
          await roomProvider.removeTenant(tenant.room!.id);
          await roomProvider.updateRoomStatus(
              tenant.room!.id, RoomStatus.available);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'បានលុបអ្នកជួល ${tenant.name}'), // "Deleted tenant ${tenant.name}"
            backgroundColor: theme.colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('មានបញ្ហាក្នុងការលុបអ្នកជួល'), // "Error deleting tenant"
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _handleMenuSelection(TenantMenuOption option, Tenant tenant) {
    switch (option) {
      case TenantMenuOption.viewDetails:
        _viewTenantDetails(context, tenant);
        break;
      case TenantMenuOption.edit:
        _editTenant(context, tenant);
        break;
      case TenantMenuOption.changeRoom:
        _changeRoom(context, tenant);
        break;
      case TenantMenuOption.delete:
        _deleteTenant(context, tenant);
        break;
    }
  }

  void _showUndoSnackbar(
    BuildContext context,
    String content,
    VoidCallback onUndo,
  ) {
    final theme = Theme.of(context);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        margin: EdgeInsets.only(
          bottom: kBottomNavigationBarHeight + 12, // push above menu bar
          left: 12,
          right: 12,
        ),
        duration: const Duration(seconds: 4),
        backgroundColor: theme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Row(
          children: [
            Icon(
              Icons.delete_outline,
              color: theme.colorScheme.onPrimary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                content,
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'មិនធ្វើវិញ', // "Undo"
          textColor: theme.colorScheme.onPrimary,
          onPressed: onUndo,
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.people_alt_outlined,
                  size: 80,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'មិនមានអ្នកជួល', // "No tenants available"
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'សូមចុចប៊ូតុង + ដើម្បីបន្ថែមអ្នកជួលថ្មី', // "Tap + to add a new tenant"
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'កំពុងដំណើការ...', // "Loading..."
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'មានបញ្ហាក្នុងការផ្ទុកទិន្នន័យ', // "Error loading data"
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onErrorContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onErrorContainer.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('ព្យាយាមម្តងទៀត'), // "Try again"
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantsList(ThemeData theme, List<Tenant> tenants) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _loadData,
        backgroundColor: theme.colorScheme.surface,
        color: theme.colorScheme.primary,
        child: ListView.separated(
          padding: const EdgeInsets.all(0),
          itemCount: tenants.length,
          separatorBuilder: (context, index) => const SizedBox(height: 4),
          itemBuilder: (ctx, index) {
            final tenant = tenants[index];
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    index * 0.1,
                    (index * 0.1) + 0.6,
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ),
              child: Dismissible(
                key: Key(tenant.id),
                background: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.delete_outline,
                        color: theme.colorScheme.onError,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'លុប', // "Delete"
                        style: TextStyle(
                          color: theme.colorScheme.onError,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: theme.colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: Text(
                        'បញ្ជាក់ការលុប', // "Confirm Delete"
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      content: Text(
                        'តើអ្នកពិតជាចង់លុបអ្នកជួល "${tenant.name}" មែនទេ?', // "Are you sure you want to delete tenant?"
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(
                            'បោះបង់', // "Cancel"
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.error,
                          ),
                          child: Text(
                            'លុប', // "Delete"
                            style: TextStyle(
                              color: theme.colorScheme.onError,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (_) async {
                  final tenantProvider = context.read<TenantProvider>();
                  final roomProvider = context.read<RoomProvider>();
                  final removedTenant = tenant;

                  await tenantProvider.deleteTenant(tenant.id);
                  await roomProvider.removeTenant(tenant.room?.id ?? '');
                  await roomProvider.updateRoomStatus(
                      tenant.room?.id ?? '', RoomStatus.available);

                  _showUndoSnackbar(
                    context,
                    'បានលុបអ្នកជួល ${tenant.name}',
                    () async {
                      await tenantProvider.restoreTenant(index, removedTenant);
                      await roomProvider.addTenant(
                          removedTenant.room?.id ?? '', removedTenant);
                      await roomProvider.updateRoomStatus(
                          removedTenant.room?.id ?? '', RoomStatus.occupied);
                    },
                  );
                },
                child: TenantCard(
                  tenant: tenant,
                  onTap: () => _editTenant(context, tenant),
                  onMenuSelected: (option) =>
                      _handleMenuSelection(option, tenant),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tenantProvider = context.watch<TenantProvider>();
    final buildingProvider = context.watch<BuildingProvider>();

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppbarCustom(
        header: 'អ្នកជួល', // "Tenants"
        onAddPressed: () => _addTenant(context),
      ),
      body: Column(
        children: [
          // Filter Bar
          buildingProvider.buildings.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16.0),
              child: LinearProgressIndicator(),
            ),
            error: (error) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error loading buildings: $error',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
            success: (buildings) {
              final List<DropdownMenuItem<String?>> dropdownItems = [
                DropdownMenuItem(
                  value: null,
                  child: Text(
                    'ទាំងអស់', // "All"
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ...buildings.map((building) => DropdownMenuItem(
                      value: building.id,
                      child: Text(
                        building.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )),
              ];

              return Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                    width: 0.1,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    isExpanded: true,
                    value: _selectedBuildingId,
                    icon: Icon(
                      Icons.filter_list,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    dropdownColor: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedBuildingId = newValue;
                      });
                    },
                    items: dropdownItems,
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: tenantProvider.tenants.when(
                loading: () => _buildLoadingState(theme),
                error: (error) => _buildErrorState(theme, error),
                success: (allTenants) {
                  List<Tenant> filteredTenants = allTenants;
                  if (_selectedBuildingId != null) {
                    filteredTenants = tenantProvider
                        .getTenantByBuilding(_selectedBuildingId!);
                  }

                  if (filteredTenants.isEmpty) {
                    return _buildEmptyState(theme);
                  }
                  return _buildTenantsList(theme, filteredTenants);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
