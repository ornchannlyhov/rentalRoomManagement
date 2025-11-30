import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:joul_v2/data/models/building.dart';
import 'package:joul_v2/data/models/enum/mode.dart';
import 'package:joul_v2/data/models/service.dart';
import 'package:joul_v2/presentation/providers/service_provider.dart';
import 'package:joul_v2/presentation/view/app_widgets/global_snackbar.dart';
import 'package:joul_v2/presentation/view/screen/building/widgets/service/service_card.dart';
import 'package:joul_v2/presentation/view/screen/building/widgets/service/service_form.dart';
import 'package:joul_v2/l10n/app_localizations.dart';

class ServiceListTab extends StatelessWidget {
  final Building building;
  final VoidCallback onRefresh;

  const ServiceListTab({
    super.key,
    required this.building,
    required this.onRefresh,
  });

  Future<void> _addService(BuildContext context) async {
    final newService = await Navigator.push<Service>(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceForm(building: building),
      ),
    );

    if (newService != null && context.mounted) {
      assert(newService.buildingId == building.id);
      await context.read<ServiceProvider>().createService(newService);
      final l10n = AppLocalizations.of(context)!;
      GlobalSnackBar.show(
        context: context,
        message: l10n.serviceAddedSuccess(newService.name),
      );
    }
  }

  Future<void> _editService(BuildContext context, Service service) async {
    final updatedService = await Navigator.push<Service>(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceForm(
          building: building,
          mode: Mode.editing,
          service: service,
        ),
      ),
    );
    if (updatedService != null && context.mounted) {
      await context.read<ServiceProvider>().updateService(updatedService);
      final l10n = AppLocalizations.of(context)!;
      GlobalSnackBar.show(
        context: context,
        message: l10n.serviceUpdatedSuccess(updatedService.name),
      );
    }
  }

  Future<void> _deleteService(BuildContext context, Service service) async {
    if (context.mounted) {
      await context.read<ServiceProvider>().deleteService(service.id);

      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        GlobalSnackBar.show(
          context: context,
          message: l10n.serviceDeletedSuccess(service.name),
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
            Icons.room_service,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noServices,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              l10n.noServicesSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _addService(context),
            icon: const Icon(Icons.add),
            label: Text(l10n.addService),
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
                l10n.services,
                style: theme.textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                onPressed: () => _addService(context),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                tooltip: l10n.addService,
              ),
            ],
          ),
        ),

        // Content area
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Selector<ServiceProvider, dynamic>(
              selector: (_, provider) => provider.servicesState,
              builder: (context, servicesState, _) {
                return servicesState.when(
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
                  success: (services) {
                    final buildingServices = services
                        .where((s) => s.buildingId == building.id)
                        .toList();

                    if (buildingServices.isEmpty) {
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
                        itemCount: buildingServices.length,
                        itemBuilder: (context, index) {
                          final service = buildingServices[index];
                          return Dismissible(
                            key: Key(service.id),
                            background: _buildDismissBackground(context),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) => _showConfirmDialog(
                              context,
                              title: l10n.deleteService,
                              content: l10n.deleteServiceConfirm(service.name),
                            ),
                            onDismissed: (_) =>
                                _deleteService(context, service),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ServiceCard(
                                service: service,
                                onTap: () => _editService(context, service),
                                onMenuSelected: (option) {
                                  if (option == ServiceMenuOption.edit) {
                                    _editService(context, service);
                                  } else if (option ==
                                      ServiceMenuOption.delete) {
                                    _deleteService(context, service);
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
