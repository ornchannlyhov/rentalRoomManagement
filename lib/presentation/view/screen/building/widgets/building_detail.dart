import 'package:flutter/material.dart';
import 'package:joul_v2/presentation/view/screen/building/widgets/screen_type.dart';
import 'package:provider/provider.dart';
import 'package:joul_v2/data/models/building.dart';
import 'package:joul_v2/data/models/enum/mode.dart';
import 'package:joul_v2/data/models/enum/room_status.dart';
import 'package:joul_v2/data/models/enum/report_status.dart';
import 'package:joul_v2/data/models/room.dart';
import 'package:joul_v2/data/models/service.dart';
import 'package:joul_v2/data/models/report.dart';
import 'package:joul_v2/presentation/providers/building_provider.dart';
import 'package:joul_v2/presentation/providers/room_provider.dart';
import 'package:joul_v2/presentation/providers/service_provider.dart';
import 'package:joul_v2/presentation/providers/tenant_provider.dart';
import 'package:joul_v2/presentation/providers/report_provider.dart';
import 'package:joul_v2/presentation/view/app_widgets/global_snackbar.dart';
import 'package:joul_v2/presentation/view/screen/building/widgets/building_card.dart';
import 'package:joul_v2/presentation/view/screen/building/widgets/building_form.dart';
import 'package:joul_v2/presentation/view/screen/building/widgets/switch_button.dart';
import 'package:joul_v2/presentation/view/screen/building/widgets/room/room_card.dart';
import 'package:joul_v2/presentation/view/screen/building/widgets/room/room_form.dart';
import 'package:joul_v2/presentation/view/screen/building/widgets/service/service_card.dart';
import 'package:joul_v2/presentation/view/screen/building/widgets/service/service_form.dart';
import 'package:joul_v2/presentation/view/screen/building/widgets/report/report_card.dart';

import '../../../../../l10n/app_localizations.dart';

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
  ReportStatus? _statusFilter;

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
      context.read<ReportProvider>().load(),
    ]);
  }

  // ==================== ROOM METHODS ====================
  Future<void> _addRoom() async {
    final newRoom = await Navigator.push<Room>(
      context,
      MaterialPageRoute(
          builder: (context) => RoomForm(building: widget.building)),
    );
    if (newRoom != null && mounted) {
      await context.read<RoomProvider>().createRoom(newRoom);
      final l10n = AppLocalizations.of(context)!;
      _showSuccessMessage(l10n.roomAddedSuccess(newRoom.roomNumber));
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
      final l10n = AppLocalizations.of(context)!;
      _showSuccessMessage(l10n.roomUpdatedSuccess(updatedRoom.roomNumber));
    }
  }

  Future<void> _deleteRoom(int index, Room room) async {
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
        final l10n = AppLocalizations.of(context)!;
        GlobalSnackBar.show(
          context: context,
          message: l10n.roomDeletedSuccess(room.roomNumber),
        );
      }
    }
  }

  // ==================== SERVICE METHODS ====================
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
      final l10n = AppLocalizations.of(context)!;
      _showSuccessMessage(l10n.serviceAddedSuccess(newService.name));
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
      final l10n = AppLocalizations.of(context)!;
      _showSuccessMessage(l10n.serviceUpdatedSuccess(updatedService.name));
    }
  }

  Future<void> _deleteService(int index, Service service) async {
    if (mounted) {
      await context.read<ServiceProvider>().deleteService(service.id);

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        GlobalSnackBar.show(
          context: context,
          message: l10n.serviceDeletedSuccess(service.name),
        );
      }
    }
  }

  // ==================== REPORT METHODS ====================
  Future<void> _deleteReport(int index, Report report) async {
    if (mounted) {
      await context.read<ReportProvider>().deleteReport(report.id);

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        GlobalSnackBar.show(
          context: context,
          message: l10n.reportDeletedSuccess,
        );
      }
    }
  }

  Future<void> _changeReportStatus(Report report) async {
    final l10n = AppLocalizations.of(context)!;
    final newStatus = await showDialog<ReportStatus>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          l10n.changeStatus,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ReportStatus.values.map((status) {
            return ListTile(
              title: Text(_getStatusLabel(status)),
              leading: Icon(
                _getStatusIcon(status),
                color: _getStatusColor(context, status),
              ),
              selected: report.status == status,
              selectedTileColor: _getStatusColor(context, status).withOpacity(0.1),
              onTap: () => Navigator.pop(context, status),
            );
          }).toList(),
        ),
      ),
    );

    if (newStatus != null && newStatus != report.status && mounted) {
      try {
        await context.read<ReportProvider>().updateReportStatus(
          report.id,
          newStatus.toApiString(),
        );
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          GlobalSnackBar.show(
            context: context,
            message: l10n.reportStatusUpdated(_getStatusLabel(newStatus)),
          );
        }
      } catch (e) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          GlobalSnackBar.show(
            context: context,
            message: l10n.reportStatusUpdateFailed,
          );
        }
      }
    }
  }



  // ==================== REPORT HELPER METHODS ====================
  Color _getStatusColor(BuildContext context, ReportStatus status) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (status) {
      case ReportStatus.pending:
        return Colors.orange;
      case ReportStatus.inProgress:
        return Colors.blue;
      case ReportStatus.resolved:
        return Colors.green;
      case ReportStatus.closed:
        return colorScheme.outline;
    }
  }

  IconData _getStatusIcon(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Icons.pending_outlined;
      case ReportStatus.inProgress:
        return Icons.autorenew;
      case ReportStatus.resolved:
        return Icons.check_circle_outline;
      case ReportStatus.closed:
        return Icons.cancel_outlined;
    }
  }

  String _getStatusLabel(ReportStatus status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case ReportStatus.pending:
        return l10n.reportStatusPending;
      case ReportStatus.inProgress:
        return l10n.reportStatusInProgress;
      case ReportStatus.resolved:
        return l10n.reportStatusResolved;
      case ReportStatus.closed:
        return l10n.reportStatusClosed;
    }
  }

  // ==================== BUILDING METHODS ====================
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
      final l10n = AppLocalizations.of(context)!;
      _showSuccessMessage(l10n.buildingUpdatedSuccess(updatedBuilding.name));
    }
  }

  Future<void> _deleteBuilding() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _showConfirmDialog(
      title: l10n.deleteBuilding,
      content: l10n.deleteBuildingWarning(widget.building.name),
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
        final l10n = AppLocalizations.of(context)!;
        GlobalSnackBar.show(
          context: context,
          message: l10n.buildingDeletedSuccess(widget.building.name),
        );
        Navigator.pop(context);
      }
    }
  }

  // ==================== DIALOG METHODS ====================
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

  // ==================== BUILD CONTENT METHODS ====================
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
              final l10n = AppLocalizations.of(context)!;
              return _buildEmptyStateWithRefresh(
                icon: Icons.bed,
                title: l10n.noRooms,
                subtitle: l10n.noRoomsSubtitle,
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
              final l10n = AppLocalizations.of(context)!;
              return _buildEmptyStateWithRefresh(
                icon: Icons.room_service,
                title: l10n.noServices,
                subtitle: l10n.noServicesSubtitle,
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

  Widget _buildReportContent() {
    return Selector<ReportProvider, dynamic>(
      selector: (_, provider) => provider.reportsState,
      builder: (context, reportsState, _) {
        return reportsState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error) => _buildErrorState(error, _loadData),
          success: (reports) {
            final l10n = AppLocalizations.of(context)!;
            
            // Filter by building
            var buildingReports = reports
                .where((r) => r.room?.building?.id == widget.building.id)
                .toList();

            // Apply status filter
            if (_statusFilter != null) {
              buildingReports = buildingReports
                  .where((r) => r.status == _statusFilter)
                  .toList();
            }

            if (buildingReports.isEmpty) {
              return _buildEmptyStateWithRefresh(
                icon: Icons.report_outlined,
                title: _statusFilter != null 
                    ? l10n.noFilteredReports(_getStatusLabel(_statusFilter!))
                    : l10n.noReports,
                subtitle: _statusFilter != null
                    ? l10n.noFilteredReportsSubtitle
                    : l10n.noReportsSubtitle,
                actionText: _statusFilter != null 
                    ? l10n.clearFilter
                    : l10n.refresh,
                onAction: _statusFilter != null
                    ? () => setState(() => _statusFilter = null)
                    : _loadData,
              );
            }

            return RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(8),
                itemCount: buildingReports.length,
                itemBuilder: (context, index) {
                  final report = buildingReports[index];
                  return _buildDismissibleReportCard(index, report);
                },
              ),
            );
          },
        );
      },
    );
  }

  // ==================== BUILD CARD METHODS ====================
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

  Widget _buildDismissibleReportCard(int index, Report report) {
    final l10n = AppLocalizations.of(context)!;
    return Dismissible(
      key: Key(report.id),
      background: _buildDismissBackground(),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _showConfirmDialog(
        title: l10n.deleteReport,
        content: l10n.deleteReportConfirmFrom(report.tenant?.name ?? l10n.unknownTenant),
      ),
      onDismissed: (_) => _deleteReport(index, report),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ReportCard(
          report: report,
          onMenuSelected: (option) {
            if (option == ReportMenuOption.changeStatus) {
              _changeReportStatus(report);
            } else if (option == ReportMenuOption.delete) {
              _deleteReport(index, report);
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

  // ==================== STATE WIDGETS ====================
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAction,
            icon: Icon(_statusFilter != null ? Icons.clear : Icons.add),
            label: Text(actionText),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== BUILD METHOD ====================
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
          // Building Card
          Padding(
            padding: const EdgeInsets.all(12),
            child: BuildingCard(
              building: widget.building,
              onEdit: _editBuilding,
              onDelete: _deleteBuilding,
            ),
          ),

          // Screen Switch Button (Room/Service/Report)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ScreenSwitchButton(
              onScreenSelected: (screen) =>
                  setState(() => _currentScreen = screen),
            ),
          ),

          // Header with title and action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _currentScreen == ScreenType.room
                      ? l10n.rooms
                      : _currentScreen == ScreenType.service
                          ? l10n.services
                          : l10n.reports,
                  style: theme.textTheme.titleLarge,
                ),
                Row(
                  children: [
                    // Filter button (only for reports)
      if (_currentScreen == ScreenType.report)
  Padding(
    padding: const EdgeInsets.only(right: 8),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<ReportStatus?>(
        value: _statusFilter,
        icon: Icon(
          Icons.filter_alt,
          size: 20,
          color: Colors.black, // BLACK ICON ALWAYS
        ),
        dropdownColor: theme.colorScheme.surface,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: 14,
        ),
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        isDense: true,
        hint: Text(
          l10n.allReports,
          style: TextStyle(
            color: _statusFilter == null
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.onSurface,
          ),
        ),
        // FULL CONTROL — NO GREY, LOCALIZED TEXT
        selectedItemBuilder: (BuildContext context) {
          return [
            // "All Reports" — null
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.clear_all, size: 18, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(l10n.allReports),
              ],
            ),
            // Each status — localized
            ...ReportStatus.values.map((status) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getStatusIcon(status),
                    size: 18,
                    color: _getStatusColor(context, status),
                  ),
                  const SizedBox(width: 8),
                  Text(_getStatusLabel(status)),
                ],
              );
            }),
          ];
        },
        items: [
          DropdownMenuItem<ReportStatus?>(
            value: null,
            child: Row(
              children: [
                const Icon(Icons.clear_all, size: 18),
                const SizedBox(width: 8),
                Text(l10n.allReports),
              ],
            ),
          ),
          ...ReportStatus.values.map((status) => DropdownMenuItem(
                value: status,
                child: Row(
                  children: [
                    Icon(
                      _getStatusIcon(status),
                      size: 18,
                      color: _getStatusColor(context, status),
                    ),
                    const SizedBox(width: 8),
                    Text(_getStatusLabel(status)),
                  ],
                ),
              )),
        ],
        onChanged: (ReportStatus? newValue) {
          setState(() {
            _statusFilter = newValue;
          });
        },
      ),
    ),
  ),

                    // Add button (only for rooms and services, not reports)
                    if (_currentScreen != ScreenType.report)
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
              ],
            ),
          ),

          // Content area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _currentScreen == ScreenType.room
                  ? _buildRoomContent()
                  : _currentScreen == ScreenType.service
                      ? _buildServiceContent()
                      : _buildReportContent(),
            ),
          ),
        ],
      ),
    );
  }
}