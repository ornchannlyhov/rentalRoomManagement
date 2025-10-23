import 'package:flutter/material.dart';
import 'package:receipts_v2/data/models/tenant.dart';
import 'package:receipts_v2/presentation/view/screen/tenant/widgets/tenant_card.dart';

class TenantList extends StatelessWidget {
  const TenantList({
    super.key,
    required this.tenants,
    required this.theme,
    required this.animationController,
    required this.fadeAnimation,
    required this.onRefresh,
    required this.onDismissed,
    required this.onTapTenant,
    required this.onMenuSelected,
  });

  final List<Tenant> tenants;
  final ThemeData theme;
  final AnimationController animationController;
  final Animation<double> fadeAnimation;
  final Future<void> Function() onRefresh;
  final Future<void> Function(Tenant, int, DismissDirection) onDismissed;
  final Function(BuildContext, Tenant) onTapTenant;
  final Function(TenantMenuOption, Tenant) onMenuSelected;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: RefreshIndicator(
        onRefresh: onRefresh,
        backgroundColor: theme.colorScheme.surface,
        color: theme.colorScheme.primary,
        child: ListView.separated(
          padding: const EdgeInsets.all(0),
          itemCount: tenants.length,
          separatorBuilder: (context, index) => const SizedBox(height: 4),
          itemBuilder: (ctx, index) {
            final tenant = tenants[index];

            // Calculate staggered animation intervals with proper clamping
            final double begin = (index * 0.05).clamp(0.0, 0.4);
            final double end = ((index * 0.05) + 0.6).clamp(0.0, 1.0);

            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animationController,
                  curve: Interval(
                    begin,
                    end,
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ),
              child: Dismissible(
                key: ValueKey(tenant.id),
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
                  return await _showConfirmDeleteDialog(context, tenant.name);
                },
                onDismissed: (direction) =>
                    onDismissed(tenant, index, direction),
                child: TenantCard(
                  tenant: tenant,
                  onTap: () => onTapTenant(context, tenant),
                  onMenuSelected: (option) => onMenuSelected(option, tenant),
                ),
              ),
            );
          },
        ),
      ),
    );
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
}
