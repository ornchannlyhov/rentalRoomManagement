import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:joul_v2/data/models/notification_item.dart';
import 'package:joul_v2/presentation/providers/notification_provider.dart';
import 'package:joul_v2/presentation/view/screen/receipt/receipt_confirmation_screen.dart';
import 'package:joul_v2/presentation/view/screen/receipt/widgets/receipt_detail.dart';
import 'package:joul_v2/presentation/view/app_widgets/global_snackbar.dart';
import 'package:joul_v2/l10n/app_localizations.dart';
import 'package:joul_v2/core/theme/app_theme.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    // Mark all as read when opening notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().markAllAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(
            color: theme.brightness == Brightness.light
                ? Colors.white
                : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.brightness == Brightness.light
            ? theme.colorScheme.primary
            : theme.appBarTheme.backgroundColor,
        iconTheme: IconThemeData(
          color: theme.brightness == Brightness.light
              ? Colors.white
              : theme.colorScheme.onSurface,
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () => _showClearConfirmation(context),
            tooltip: 'Clear all',
          ),
        ],
      ),
      body: Builder(builder: (context) {
        return Stack(
          children: [
            if (theme.brightness == Brightness.light)
              _BackgroundGradient(
                height: _calculateBackgroundHeight(context),
                color: theme.colorScheme.primary,
              ),
            Consumer<NotificationProvider>(
              builder: (context, notificationProvider, child) {
                final notificationsAsync = notificationProvider.notifications;

                return notificationsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error) => _buildErrorState(context, error),
                  success: (notifications) {
                    if (notifications.isEmpty) {
                      return _buildEmptyState(context);
                    }

                    return ListView.builder(
                      itemCount: notifications.length,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return _NotificationCard(
                          notification: notification,
                          onTap: () => _handleNotificationTap(notification),
                          onDismiss: () {
                            notificationProvider
                                .deleteNotification(notification.id);
                            GlobalSnackBar.show(
                              message: l10n.notificationRemoved,
                              context: context,
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        );
      }),
    );
  }

  void _handleNotificationTap(NotificationItem notification) {
    final notificationProvider = context.read<NotificationProvider>();
    final receipt =
        notificationProvider.getReceiptForNotification(notification);

    if (receipt == null) {
      GlobalSnackBar.show(
        message: 'Receipt not found',
        context: context,
        isError: true,
      );
      return;
    }

    // Mark as read
    notificationProvider.markAsRead(notification.id);

    // Navigate based on notification type
    if (notification.type == 'NEW_USAGE_INPUT') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReceiptConfirmationScreen(receipt: receipt),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReceiptDetailScreen(receipt: receipt),
        ),
      );
    }
  }

  double _calculateBackgroundHeight(BuildContext context) {
    final appBarHeight = Scaffold.of(context).appBarMaxHeight ?? kToolbarHeight;
    const summaryCardHeight = 200.0;
    return appBarHeight + summaryCardHeight - 150;
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 48,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No notifications',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'New notifications will appear here',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: theme.colorScheme.error.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading notifications',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearConfirmation(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: theme.colorScheme.error,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Clear all notifications?',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: const Text(
          'This will remove all notification items. You can still view receipts in the Receipts tab.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              l10n.cancel,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              context.read<NotificationProvider>().clearAllNotifications();
              Navigator.pop(dialogContext);
              GlobalSnackBar.show(
                message: l10n.notificationsCleared,
                context: context,
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: const Text(
              'Clear',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundGradient extends StatelessWidget {
  const _BackgroundGradient({required this.height, required this.color});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, __) => Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color,
              color.withOpacity(0.0),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  IconData _getNotificationIcon() {
    switch (notification.type) {
      case 'PAYMENT_RECEIVED':
        return Icons.payments_rounded;
      case 'NEW_USAGE_INPUT':
        return Icons.edit_note_rounded;
      case 'NEW_RECEIPT':
      default:
        return Icons.receipt_long_rounded;
    }
  }

  Color _getIconColor(ThemeData theme) {
    switch (notification.type) {
      case 'PAYMENT_RECEIVED':
        return Colors.green;
      case 'NEW_USAGE_INPUT':
        return Colors.orange;
      case 'NEW_RECEIPT':
      default:
        return theme.colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormatter = DateFormat('MMM dd, yyyy • hh:mm a');

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: 28,
        ),
      ),
      onDismissed: (_) => onDismiss(),
      child: Card(
        color:
            theme.brightness == Brightness.dark ? AppTheme.cardColorDark : null,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getIconColor(theme).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getNotificationIcon(),
                    color: _getIconColor(theme),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateFormatter.format(notification.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
