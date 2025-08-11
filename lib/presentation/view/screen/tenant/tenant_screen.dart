// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receipts_v2/data/models/enum/mode.dart';
import 'package:receipts_v2/data/models/enum/room_status.dart';
import 'package:receipts_v2/data/models/tenant.dart';
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

class _TenantScreenState extends State<TenantScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TenantProvider>().load();
      context.read<RoomProvider>().load();
    });
  }

  Future<void> _addTenant(BuildContext context) async {
    final newTenant = await Navigator.of(context).push<Tenant>(
      MaterialPageRoute(
        builder: (ctx) => const TenantForm(
          mode: Mode.creating,
        ),
      ),
    );

    if (newTenant != null) {
      final tenantProvider = context.read<TenantProvider>();
      final roomProvider = context.read<RoomProvider>();

      await tenantProvider.createTenant(newTenant);
      await roomProvider.addTenant(newTenant.room!.id, newTenant);
      await roomProvider.updateRoomStatus(
          newTenant.room!.id, RoomStatus.occupied);
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

  void _showUndoSnackbar(
    BuildContext context,
    String content,
    VoidCallback onUndo,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(content),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: "មិនធ្វើវិញ",
          onPressed: onUndo,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tenantProvider = context.watch<TenantProvider>();

    return Scaffold(
      appBar: AppbarCustom(
        header: 'អ្នកជួល',
        onAddPressed: () => _addTenant(context),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: tenantProvider.tenants.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('កំហុស: $error', style: theme.textTheme.bodyLarge),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => tenantProvider.load(),
                  child: const Text('ព្យាយាមម្តងទៀត'),
                ),
              ],
            ),
          ),
          success: (tenants) {
            if (tenants.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_alt_outlined,
                        size: 48,
                        color: colorScheme.onSurface.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    Text(
                      'មិនមានអ្នកជួល',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ចុច + ដើម្បីបន្ថែមអ្នកជួលថ្មី',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                await tenantProvider.load();
                await context.read<RoomProvider>().load();
              },
              child: ListView.separated(
                itemCount: tenants.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (ctx, index) {
                  final tenant = tenants[index];
                  return Dismissible(
                    key: Key(tenant.id),
                    background: Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (direction) async {
                      return await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('លុបអ្នកជួល'),
                          content: Text('តើអ្នកពិតជាចង់លុប ${tenant.name}?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('បោះបង់'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('លុប',
                                  style: TextStyle(color: Colors.red)),
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
                          await tenantProvider.restoreTenant(
                              index, removedTenant);
                          await roomProvider.addTenant(
                              removedTenant.room?.id ?? '', removedTenant);
                          await roomProvider.updateRoomStatus(
                              removedTenant.room?.id ?? '',
                              RoomStatus.occupied);
                        },
                      );
                    },
                    child: TenantCard(
                      tenant: tenant,
                      onTap: () => _editTenant(context, tenant),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
