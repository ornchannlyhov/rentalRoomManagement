// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:joul_v2/data/models/enum/mode.dart';
import 'package:joul_v2/data/models/enum/room_status.dart';
import 'package:joul_v2/data/models/tenant.dart';
import 'package:joul_v2/l10n/app_localizations.dart';
import 'package:joul_v2/presentation/providers/building_provider.dart';
import 'package:joul_v2/presentation/providers/room_provider.dart';
import 'package:joul_v2/presentation/providers/tenant_provider.dart';
import 'package:joul_v2/presentation/view/app_widgets/building_filter_dropdown.dart';
import 'package:joul_v2/presentation/view/app_widgets/global_snackbar.dart';
import 'package:joul_v2/presentation/view/screen/tenant/widgets/room_change_dialog.dart';
import 'package:joul_v2/presentation/view/screen/tenant/widgets/tenant_card.dart';
import 'package:joul_v2/presentation/view/screen/tenant/widgets/tenant_detail.dart';
import 'package:joul_v2/presentation/view/screen/tenant/widgets/tenant_form.dart';
import 'package:joul_v2/presentation/view/screen/tenant/widgets/tenant_list.dart';
import 'package:joul_v2/presentation/view/screen/tenant/widgets/tenant_search_bar.dart';
import 'package:joul_v2/presentation/view/screen/tenant/widgets/tenant_state.dart';

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
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

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
    _searchController.dispose();
    super.dispose();
  }

  /// Loads all necessary data (tenants, rooms, buildings) from providers.
  Future<void> _loadData() async {
    if (!mounted) return;

    final tenantProvider = context.read<TenantProvider>();
    final roomProvider = context.read<RoomProvider>();
    final buildingProvider = context.read<BuildingProvider>();

    try {
      await Future.wait([
        tenantProvider.syncTenants(),
        roomProvider.syncRooms(),
        buildingProvider.syncBuildings(),
      ]);
    } catch (e) {
      if (mounted) {
        await Future.wait([
          tenantProvider.load(),
          roomProvider.load(),
          buildingProvider.load(),
        ]);
      }
    }

    if (mounted) {
      _animationController.forward();
    }
  }

  /// Filters tenants based on search query or building selection
  List<Tenant> _filterTenants(List<Tenant> tenants) {
    if (_searchQuery.isNotEmpty) {
      return tenants.where((tenant) {
        final nameLower = tenant.name.toLowerCase();
        final phoneLower = tenant.phoneNumber.toLowerCase();
        final roomNumber = tenant.room?.roomNumber.toLowerCase() ?? '';
        final buildingName = tenant.room?.building?.name.toLowerCase() ?? '';
        final queryLower = _searchQuery.toLowerCase();

        return nameLower.contains(queryLower) ||
            phoneLower.contains(queryLower) ||
            roomNumber.contains(queryLower) ||
            buildingName.contains(queryLower);
      }).toList();
    } else if (_selectedBuildingId != null) {
      return context
          .read<TenantProvider>()
          .getTenantsByBuilding(_selectedBuildingId!);
    }
    return tenants;
  }

  /// Handles the process of adding a new tenant.
  Future<void> _addTenantToRoom(BuildContext context) async {
    final localizations = AppLocalizations.of(context)!;

    final newTenant = await Navigator.of(context).push<Tenant>(
      MaterialPageRoute(
        builder: (ctx) => TenantForm(
          mode: Mode.creating,
          selectedBuildingId: _selectedBuildingId,
        ),
      ),
    );

    if (newTenant != null && mounted) {
      final tenantProvider = context.read<TenantProvider>();
      final roomProvider = context.read<RoomProvider>();

      try {
        await tenantProvider.createTenant(newTenant);
        if (newTenant.room != null) {
          await roomProvider.addTenantToRoom(newTenant.room!.id, newTenant);
          await roomProvider.updateRoomStatus(
              newTenant.room!.id, RoomStatus.occupied);
        }

        if (mounted) {
          GlobalSnackBar.show(
            context: context,
            message: localizations.tenantAdded(newTenant.name),
          );
        }
      } catch (e) {
        if (mounted) {
          GlobalSnackBar.show(
            context: context,
            message: localizations.tenantAddFailed,
            isError: true,
          );
        }
      }
    }
  }

  /// Handles the process of editing an existing tenant.
  Future<void> _editTenant(BuildContext context, Tenant tenant) async {
    final localizations = AppLocalizations.of(context)!;

    final updatedTenant = await Navigator.of(context).push<Tenant>(
      MaterialPageRoute(
        builder: (ctx) => TenantForm(
          mode: Mode.editing,
          tenant: tenant,
        ),
      ),
    );

    if (updatedTenant != null && mounted) {
      final tenantProvider = context.read<TenantProvider>();
      final roomProvider = context.read<RoomProvider>();

      try {
        await tenantProvider.updateTenant(updatedTenant);

        // Handle room change logic
        if (updatedTenant.room?.id != tenant.room?.id) {
          if (tenant.room != null) {
            await roomProvider.removeTenantFromRoom(tenant.room!.id);
            await roomProvider.updateRoomStatus(
                tenant.room!.id, RoomStatus.available);
          }
          if (updatedTenant.room != null) {
            await roomProvider.addTenantToRoom(
                updatedTenant.room!.id, updatedTenant);
            await roomProvider.updateRoomStatus(
                updatedTenant.room!.id, RoomStatus.occupied);
          }
        }

        if (mounted) {
          GlobalSnackBar.show(
            context: context,
            message: localizations.tenantUpdated(updatedTenant.name),
          );
        }
      } catch (e) {
        if (mounted) {
          GlobalSnackBar.show(
            context: context,
            message: localizations.tenantUpdateFailed,
            isError: true,
          );
        }
      }
    }
  }

  /// Shows detailed information about a tenant.
  void _viewTenantDetails(BuildContext context, Tenant tenant) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => TenantDetail(tenant: tenant),
      ),
    );
  }

  /// Handles changing a tenant's room.
  void _changeRoom(BuildContext context, Tenant tenant) {
    final localizations = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) => RoomChangeDialog(
        tenant: tenant,
        onRoomChanged: (newRoom) {
          GlobalSnackBar.show(
            context: context,
            message: localizations.roomChanged(tenant.name, newRoom.roomNumber),
            onRestore: () => _undoRoomChange(tenant, newRoom),
          );
        },
        onError: (message) {
          GlobalSnackBar.show(
            context: context,
            message: message,
            isError: true,
          );
        },
      ),
    );
  }

  /// Undoes a room change operation.
  Future<void> _undoRoomChange(Tenant originalTenant, newRoom) async {
    final localizations = AppLocalizations.of(context)!;
    final tenantProvider = context.read<TenantProvider>();
    final roomProvider = context.read<RoomProvider>();

    try {
      final revertedTenant = originalTenant.copyWith(room: originalTenant.room);
      await tenantProvider.updateTenant(revertedTenant);

      await roomProvider.removeTenantFromRoom(newRoom.id);
      await roomProvider.updateRoomStatus(newRoom.id, RoomStatus.available);

      if (originalTenant.room != null) {
        await roomProvider.addTenantToRoom(
            originalTenant.room!.id, revertedTenant);
        await roomProvider.updateRoomStatus(
            originalTenant.room!.id, RoomStatus.occupied);
      }

      if (mounted) {
        GlobalSnackBar.show(
          context: context,
          message: localizations.undo,
        );
      }
    } catch (e) {
      if (mounted) {
        GlobalSnackBar.show(
          context: context,
          message: localizations.roomChangeFailed,
          isError: true,
        );
      }
    }
  }

  /// Handles the process of deleting a tenant.
  Future<void> _deleteTenant(
      BuildContext context, int index, Tenant tenant) async {
    final localizations = AppLocalizations.of(context)!;

    final shouldDelete = await _showConfirmDeleteDialog(context, tenant.name);

    if (shouldDelete == true && mounted) {
      final tenantProvider = context.read<TenantProvider>();
      final roomProvider = context.read<RoomProvider>();
      final originalRoomId = tenant.room?.id;

      try {
        await tenantProvider.deleteTenant(tenant.id);
        if (originalRoomId != null) {
          await roomProvider.removeTenantFromRoom(originalRoomId);
          await roomProvider.updateRoomStatus(
              originalRoomId, RoomStatus.available);
        }

        if (mounted) {
          GlobalSnackBar.show(
            context: context,
            message: 'បានលុបអ្នកជួល ${tenant.name}',
          );
        }
      } catch (e) {
        if (mounted) {
          GlobalSnackBar.show(
            context: context,
            message: localizations.tenantDeleteFailed,
            isError: true,
          );
        }
      }
    }
  }

  /// Displays a confirmation dialog for deleting a tenant.
  Future<bool?> _showConfirmDeleteDialog(
      BuildContext context, String tenantName) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          localizations.confirmDelete,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          localizations.deleteConfirmMsg(tenantName),
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              localizations.cancel,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error),
            child: Text(
              localizations.delete,
              style: TextStyle(color: theme.colorScheme.onError),
            ),
          ),
        ],
      ),
    );
  }

  /// Handles actions selected from the tenant card's popup menu.
  void _handleMenuSelection(TenantMenuOption option, int index, Tenant tenant) {
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
        _deleteTenant(context, index, tenant);
        break;
    }
  }

  /// Handles the dismissal of a tenant card (swipe to delete).
  Future<void> _handleTenantDismissed(
      Tenant tenant, int index, DismissDirection direction) async {
    final localizations = AppLocalizations.of(context)!;
    final tenantProvider = context.read<TenantProvider>();
    final roomProvider = context.read<RoomProvider>();
    final originalRoomId = tenant.room?.id;

    try {
      await tenantProvider.deleteTenant(tenant.id);
      if (originalRoomId != null) {
        await roomProvider.removeTenantFromRoom(originalRoomId);
        await roomProvider.updateRoomStatus(
            originalRoomId, RoomStatus.available);
      }

      if (mounted) {
        GlobalSnackBar.show(
          context: context,
          message: 'បានលុបអ្នកជួល ${tenant.name}',
        );
      }
    } catch (e) {
      if (mounted) {
        GlobalSnackBar.show(
          context: context,
          message: localizations.tenantDeleteFailed,
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    final tenantProvider = context.watch<TenantProvider>();
    final buildingProvider = context.watch<BuildingProvider>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          localizations.tenantsTitle,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
          IconButton(
            icon: Icon(
              Icons.add,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () => _addTenantToRoom(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TenantSearchBar(
              isSearching: _isSearching,
              searchController: _searchController,
              searchQuery: _searchQuery,
              onSearchQueryChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  if (value.isNotEmpty) {
                    _selectedBuildingId = null;
                  }
                });
              },
              onClearSearch: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
            ),
          ),
          // Building Filter Dropdown
          if (!_isSearching || _searchQuery.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: BuildingFilterDropdown(
                buildingProvider: buildingProvider,
                selectedBuildingId: _selectedBuildingId,
                onChanged: (newValue) {
                  setState(() {
                    _selectedBuildingId = newValue;
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: tenantProvider.tenantsState.when(
                loading: () => LoadingState(theme: theme),
                error: (error) =>
                    ErrorState(theme: theme, error: error, onRetry: _loadData),
                success: (allTenants) {
                  final filteredTenants = _filterTenants(allTenants);

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
                    onTapTenant: _viewTenantDetails,
                    onLongPress: _editTenant,
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
}
