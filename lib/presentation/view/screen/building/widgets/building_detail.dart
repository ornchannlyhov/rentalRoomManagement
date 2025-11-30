import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:joul_v2/data/models/building.dart';
import 'package:joul_v2/data/models/enum/mode.dart';
import 'package:joul_v2/presentation/providers/building_provider.dart';
import 'package:joul_v2/presentation/providers/room_provider.dart';
import 'package:joul_v2/presentation/providers/service_provider.dart';
import 'package:joul_v2/presentation/providers/tenant_provider.dart';
import 'package:joul_v2/presentation/providers/report_provider.dart';
import 'package:joul_v2/presentation/view/app_widgets/global_snackbar.dart';
import 'package:joul_v2/presentation/view/screen/building/widgets/building_card.dart';
import 'package:joul_v2/presentation/view/screen/building/widgets/building_form.dart';
import 'package:joul_v2/presentation/view/screen/building/widgets/screen_type.dart';
import 'package:joul_v2/presentation/view/screen/building/widgets/switch_button.dart';
import 'package:joul_v2/presentation/view/screen/building/widgets/room/room_list_tab.dart';
import 'package:joul_v2/presentation/view/screen/building/widgets/service/service_list_tab.dart';
import 'package:joul_v2/presentation/view/screen/building/widgets/report/report_list_tab.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    try {
      await Future.wait([
        context.read<RoomProvider>().syncRooms(),
        context.read<ServiceProvider>().syncServices(),
        context.read<TenantProvider>().syncTenants(),
        context.read<ReportProvider>().syncReports(),
      ]);
    } catch (e) {
      if (mounted) {
        await Future.wait([
          context.read<RoomProvider>().load(),
          context.read<ServiceProvider>().load(),
          context.read<TenantProvider>().load(),
          context.read<ReportProvider>().load(),
        ]);

        GlobalSnackBar.show(
          context: context,
          message: "Currently offline, loaded data from device",
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
          // Building Card
          Padding(
            padding: const EdgeInsets.all(12),
            child: BuildingCard(
              building: widget.building,
              onEdit: _editBuilding,
              onDelete: _deleteBuilding,
              showImage: true,
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

          // Content area
          Expanded(
            child: _currentScreen == ScreenType.room
                ? RoomListTab(
                    building: widget.building,
                    onRefresh: _loadData,
                  )
                : _currentScreen == ScreenType.service
                    ? ServiceListTab(
                        building: widget.building,
                        onRefresh: _loadData,
                      )
                    : ReportListTab(
                        building: widget.building,
                        onRefresh: _loadData,
                      ),
          ),
        ],
      ),
    );
  }
}
