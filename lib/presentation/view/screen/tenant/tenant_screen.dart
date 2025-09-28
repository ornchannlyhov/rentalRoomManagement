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
import 'package:receipts_v2/presentation/view/app_widgets/building_filter_dropdown.dart';
import 'package:receipts_v2/presentation/view/screen/tenant/widgets/room_change_dialog.dart';
import 'package:receipts_v2/presentation/view/screen/tenant/widgets/tenant_card.dart';
import 'package:receipts_v2/presentation/view/screen/tenant/widgets/tenant_detail_dialog.dart';
import 'package:receipts_v2/presentation/view/screen/tenant/widgets/tenant_form.dart';
import 'package:receipts_v2/presentation/view/screen/tenant/widgets/tenant_list.dart';
import 'package:receipts_v2/presentation/view/screen/tenant/widgets/tenant_state.dart';

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

  String? _selectedBuildingId; // State for the selected building filter

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

    // Load data after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Loads all necessary data (tenants, rooms, buildings) from providers.
  Future<void> _loadData() async {
    final tenantProvider = context.read<TenantProvider>();
    final roomProvider = context.read<RoomProvider>();
    final buildingProvider = context.read<BuildingProvider>();

    await Future.wait([
      tenantProvider.load(),
      roomProvider.load(),
      buildingProvider.load(),
    ]);
    _animationController.forward(); // Start animation after data is loaded
  }

  /// Shows a standardized SnackBar with customizable message, icon, and actions.
  void _showSnackBar({
    required BuildContext context,
    required String message,
    required IconData icon,
    bool isError = false,
    SnackBarAction? action,
  }) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar(); // Hide any active snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        margin: const EdgeInsets.only(
          bottom: kBottomNavigationBarHeight +
              12, // Position above bottom navigation
          left: 12,
          right: 12,
        ),
        duration: const Duration(seconds: 4),
        backgroundColor:
            isError ? theme.colorScheme.error : theme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Row(
          children: [
            Icon(
              icon,
              color: isError
                  ? theme.colorScheme.onError
                  : theme.colorScheme.onPrimary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isError
                      ? theme.colorScheme.onError
                      : theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        action: action,
      ),
    );
  }

  /// Handles the process of adding a new tenant.
  Future<void> _addTenant(BuildContext context) async {
    final newTenant = await Navigator.of(context).push<Tenant>(
      MaterialPageRoute(
        builder: (ctx) => TenantForm(
          mode: Mode.creating,
          selectedBuildingId: _selectedBuildingId,
        ),
      ),
    );

    if (newTenant != null) {
      final tenantProvider = context.read<TenantProvider>();
      final roomProvider = context.read<RoomProvider>();

      try {
        await tenantProvider.createTenant(newTenant);
        if (newTenant.room != null) {
          await roomProvider.addTenant(newTenant.room!.id, newTenant);
          await roomProvider.updateRoomStatus(
              newTenant.room!.id, RoomStatus.occupied);
        }
        _showSnackBar(
          context: context,
          message:
              'បានបន្ថែមអ្នកជួល ${newTenant.name} ដោយជោគជ័យ', // "Successfully added tenant"
          icon: Icons.person_add,
        );
      } catch (e) {
        _showSnackBar(
          context: context,
          message: 'មានបញ្ហាក្នុងការបន្ថែមអ្នកជួល', // "Error adding tenant"
          icon: Icons.error_outline,
          isError: true,
        );
      }
    }
  }

  /// Handles the process of editing an existing tenant.
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

      try {
        await tenantProvider.updateTenant(updatedTenant);

        // Handle room change logic
        if (updatedTenant.room?.id != tenant.room?.id) {
          if (tenant.room != null) {
            await roomProvider.removeTenant(tenant.room!.id);
            await roomProvider.updateRoomStatus(
                tenant.room!.id, RoomStatus.available);
          }
          if (updatedTenant.room != null) {
            await roomProvider.addTenant(updatedTenant.room!.id, updatedTenant);
            await roomProvider.updateRoomStatus(
                updatedTenant.room!.id, RoomStatus.occupied);
          }
        }
        _showSnackBar(
          context: context,
          message:
              'បានកែប្រែព័ត៌មានអ្នកជួល ${updatedTenant.name} ដោយជោគជ័យ', // "Successfully updated tenant"
          icon: Icons.edit,
        );
      } catch (e) {
        _showSnackBar(
          context: context,
          message: 'មានបញ្ហាក្នុងការកែប្រែព័ត៌មាន', // "Error updating tenant"
          icon: Icons.error_outline,
          isError: true,
        );
      }
    }
  }

  /// Shows a dialog with detailed information about a tenant.
  void _viewTenantDetails(BuildContext context, Tenant tenant) {
    showDialog(
      context: context,
      builder: (context) => TenantDetailDialog(tenant: tenant),
    );
  }

  /// Handles changing a tenant's room.
  void _changeRoom(BuildContext context, Tenant tenant) {
    showDialog(
      context: context,
      builder: (ctx) => RoomChangeDialog(
        tenant: tenant,
        onRoomChanged: (newRoom) {
          _showSnackBar(
            context: context,
            message:
                'បានផ្លាស់ប្តូរបន្ទប់សម្រាប់ ${tenant.name} ទៅបន្ទប់ ${newRoom.roomNumber}',
            icon: Icons.swap_horiz,
            action: SnackBarAction(
              label: 'មិនធ្វើវិញ', // "Undo"
              textColor: Theme.of(context).colorScheme.onPrimary,
              onPressed: () => _undoRoomChange(tenant, newRoom),
            ),
          );
        },
        onError: (message) {
          _showSnackBar(
            context: context,
            message: message,
            icon: Icons.error_outline,
            isError: true,
          );
        },
      ),
    );
  }

  /// Undoes a room change operation.
  Future<void> _undoRoomChange(Tenant originalTenant, newRoom) async {
    final tenantProvider = context.read<TenantProvider>();
    final roomProvider = context.read<RoomProvider>();
    try {
      final revertedTenant = originalTenant.copyWith(room: originalTenant.room);
      await tenantProvider.updateTenant(revertedTenant);

      await roomProvider.removeTenant(newRoom.id);
      await roomProvider.updateRoomStatus(newRoom.id, RoomStatus.available);

      if (originalTenant.room != null) {
        await roomProvider.addTenant(originalTenant.room!.id, revertedTenant);
        await roomProvider.updateRoomStatus(
            originalTenant.room!.id, RoomStatus.occupied);
      }
    } catch (e) {
      _showSnackBar(
        context: context,
        message: 'មានបញ្ហាក្នុងការត្រឡប់វិញ', // "Error undoing"
        icon: Icons.error_outline,
        isError: true,
      );
    }
  }

  /// Handles the process of deleting a tenant.
  Future<void> _deleteTenant(BuildContext context, Tenant tenant) async {
    final shouldDelete = await _showConfirmDeleteDialog(context, tenant.name);

    if (shouldDelete == true) {
      final tenantProvider = context.read<TenantProvider>();
      final roomProvider = context.read<RoomProvider>();
      final removedTenant = tenant; // Keep a copy for undo
      final originalRoomId = tenant.room?.id;

      try {
        await tenantProvider.deleteTenant(tenant.id);
        if (originalRoomId != null) {
          await roomProvider.removeTenant(originalRoomId);
          await roomProvider.updateRoomStatus(
              originalRoomId, RoomStatus.available);
        }

        _showSnackBar(
          context: context,
          message:
              'បានលុបអ្នកជួល ${tenant.name}', // "Deleted tenant ${tenant.name}"
          icon: Icons.delete_outline,
          action: SnackBarAction(
            label: 'មិនធ្វើវិញ', // "Undo"
            textColor: Theme.of(context).colorScheme.onPrimary,
            onPressed: () async {
              try {
                // Assuming restoreTenant can insert at the correct position or handle it internally
                await tenantProvider.restoreTenant(
                    0, removedTenant); // Adjust index if needed
                if (originalRoomId != null) {
                  await roomProvider.addTenant(originalRoomId, removedTenant);
                  await roomProvider.updateRoomStatus(
                      originalRoomId, RoomStatus.occupied);
                }
              } catch (e) {
                _showSnackBar(
                  context: context,
                  message:
                      'មានបញ្ហាក្នុងការត្រឡប់វិញ', // "Error restoring tenant"
                  icon: Icons.error_outline,
                  isError: true,
                );
              }
            },
          ),
        );
      } catch (e) {
        _showSnackBar(
          context: context,
          message: 'មានបញ្ហាក្នុងការលុបអ្នកជួល', // "Error deleting tenant"
          icon: Icons.error_outline,
          isError: true,
        );
      }
    }
  }

  /// Displays a confirmation dialog for deleting a tenant.
  Future<bool?> _showConfirmDeleteDialog(
      BuildContext context, String tenantName) {
    final theme = Theme.of(context);
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('បញ្ជាក់ការលុប', // "Confirm Delete"
            style: theme.textTheme.titleLarge),
        content: Text(
          'តើអ្នកពិតជាចង់លុបអ្នកជួល "$tenantName" មែនទេ?',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('បោះបង់',
                style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant)), // "Cancel"
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error),
            child: Text('លុប',
                style: TextStyle(color: theme.colorScheme.onError)), // "Delete"
          ),
        ],
      ),
    );
  }

  /// Handles actions selected from the tenant card's popup menu.
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
          // Building Filter Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BuildingFilterDropdown(
              buildingProvider: buildingProvider,
              selectedBuildingId: _selectedBuildingId,
              onChanged: (newValue) {
                setState(() {
                  _selectedBuildingId = newValue;
                });
              },
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: tenantProvider.tenants.when(
                loading: () => LoadingState(theme: theme),
                error: (error) =>
                    ErrorState(theme: theme, error: error, onRetry: _loadData),
                success: (allTenants) {
                  final filteredTenants = _selectedBuildingId == null
                      ? allTenants
                      : tenantProvider
                          .getTenantByBuilding(_selectedBuildingId!);

                  if (filteredTenants.isEmpty) {
                    return EmptyState(
                        theme: theme,
                        fadeAnimation: _fadeAnimation,
                        slideAnimation: _slideAnimation);
                  }
                  return TenantList(
                    tenants: filteredTenants,
                    theme: theme,
                    animationController: _animationController,
                    fadeAnimation: _fadeAnimation,
                    onRefresh: _loadData,
                    onDismissed: _handleTenantDismissed,
                    onTapTenant: _editTenant,
                    onMenuSelected: _handleMenuSelection,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Handles the dismissal of a tenant card (swipe to delete).
  Future<void> _handleTenantDismissed(
      Tenant tenant, int index, DismissDirection direction) async {
    final tenantProvider = context.read<TenantProvider>();
    final roomProvider = context.read<RoomProvider>();
    final removedTenant = tenant;
    final originalRoomId = tenant.room?.id;
    final theme = Theme.of(context);

    try {
      await tenantProvider.deleteTenant(tenant.id);
      if (originalRoomId != null) {
        await roomProvider.removeTenant(originalRoomId);
        await roomProvider.updateRoomStatus(
            originalRoomId, RoomStatus.available);
      }

      _showSnackBar(
        context: context,
        message:
            'បានលុបអ្នកជួល ${tenant.name}', // "Deleted tenant ${tenant.name}"
        icon: Icons.delete_outline,
        action: SnackBarAction(
          label: 'មិនធ្វើវិញ', // "Undo"
          textColor: theme.colorScheme.onPrimary,
          onPressed: () async {
            try {
              await tenantProvider.restoreTenant(index, removedTenant);
              if (originalRoomId != null) {
                await roomProvider.addTenant(originalRoomId, removedTenant);
                await roomProvider.updateRoomStatus(
                    originalRoomId, RoomStatus.occupied);
              }
            } catch (e) {
              _showSnackBar(
                context: context,
                message:
                    'មានបញ្ហាក្នុងការត្រឡប់វិញ', // "Error restoring tenant"
                icon: Icons.error_outline,
                isError: true,
              );
            }
          },
        ),
      );
    } catch (e) {
      _showSnackBar(
        context: context,
        message: 'មានបញ្ហាក្នុងការលុបអ្នកជួល', // "Error deleting tenant"
        icon: Icons.error_outline,
        isError: true,
      );
    }
  }
}
