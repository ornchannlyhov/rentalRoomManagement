// ignore_for_file: use_build_context_synchronously
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:joul_v2/presentation/providers/notification_provider.dart';
import 'package:joul_v2/data/models/enum/mode.dart';
import 'package:joul_v2/data/models/enum/payment_status.dart';
import 'package:joul_v2/data/models/receipt.dart';
import 'package:joul_v2/presentation/providers/receipt_provider.dart';
import 'package:joul_v2/presentation/providers/building_provider.dart';
import 'package:joul_v2/presentation/providers/room_provider.dart';
import 'package:joul_v2/presentation/providers/service_provider.dart';
import 'package:joul_v2/presentation/view/app_widgets/global_snackbar.dart';
import 'package:joul_v2/presentation/view/screen/receipt/widgets/receipt_detail.dart';
import 'package:joul_v2/presentation/view/screen/receipt/widgets/receipt_form.dart';
import 'package:joul_v2/presentation/view/screen/receipt/widgets/receipt_list.dart';
import 'package:joul_v2/presentation/view/screen/notification/notification_screen.dart';
import 'package:joul_v2/l10n/app_localizations.dart';

class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen>
    with SingleTickerProviderStateMixin {
  PaymentStatus _selectedStatus = PaymentStatus.paid;
  String? _selectedBuildingId;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
      // REMOVED: _setupNotificationListeners() - Now handled in main.dart
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final receiptProvider = context.read<ReceiptProvider>();
    final buildingProvider = context.read<BuildingProvider>();
    final roomProvider = context.read<RoomProvider>();
    final serviceProvider = context.read<ServiceProvider>();

    await Future.wait([
      receiptProvider.load(),
      buildingProvider.load(),
      roomProvider.load(),
      serviceProvider.load(),
    ]);

    if (mounted) _animationController.forward();
  }

  Future<void> _navigateToAddReceipt(List<Receipt> allReceipts) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ReceiptForm(
          receipts: allReceipts,
          selectedBuildingId: _selectedBuildingId,
        ),
      ),
    );
  }

  Future<void> _navigateToEditReceipt(
      Receipt receipt, List<Receipt> allReceipts) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ReceiptForm(
          mode: Mode.editing,
          receipt: receipt,
          receipts: allReceipts,
        ),
      ),
    );
  }

  Future<void> _navigateToReceiptDetail(Receipt receipt) async {
    final l10n = AppLocalizations.of(context)!;

    final freshReceipt = context
        .read<ReceiptProvider>()
        .receiptsState
        .data
        ?.firstWhereOrNull((r) => r.id == receipt.id);

    if (freshReceipt == null) {
      GlobalSnackBar.show(
        message: l10n.errorLoadingData,
        isError: true,
        context: context,
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReceiptDetailScreen(receipt: receipt),
      ),
    );
  }

  Future<bool> _confirmDeleteReceipt(
      BuildContext context, Receipt receipt) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: theme.colorScheme.error, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.confirmDelete,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: Text(
          l10n.deleteReceiptConfirmMsg(
              receipt.room?.roomNumber ?? l10n.unknown),
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(
              l10n.cancel,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: Text(
              l10n.delete,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _handleDeleteReceipt(Receipt receipt, int index) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _confirmDeleteReceipt(context, receipt);
    if (!confirmed || !mounted) return;

    final provider = context.read<ReceiptProvider>();
    await provider.deleteReceipt(receipt.id);

    if (mounted) {
      GlobalSnackBar.show(
        message: l10n.receiptDeleted,
        context: context,
      );
    }
  }

  void _showMenuOptions(BuildContext context, int index, Receipt receipt,
      List<Receipt> allReceipts) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _buildMenuOption(
                context,
                Icons.visibility,
                l10n.viewDetail,
                () {
                  Navigator.pop(context);
                  _navigateToReceiptDetail(receipt);
                },
              ),
              _buildMenuOption(
                context,
                Icons.share,
                l10n.share,
                () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReceiptDetailScreen(
                        receipt: receipt,
                        onShareRequested: () {},
                      ),
                    ),
                  );
                },
              ),
              _buildMenuOption(
                context,
                Icons.edit,
                l10n.edit,
                () {
                  Navigator.pop(context);
                  _navigateToEditReceipt(receipt, allReceipts);
                },
              ),
              _buildMenuOption(
                context,
                Icons.delete_outline,
                l10n.delete,
                () {
                  Navigator.pop(context);
                  _handleDeleteReceipt(receipt, index);
                },
                isDestructive: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOption(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final textColor =
        isDestructive ? theme.colorScheme.error : theme.colorScheme.primary;

    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: isDestructive ? theme.colorScheme.error : null,
        ),
      ),
      onTap: onTap,
    );
  }

  String getKhmerMonth(int month) {
    final l10n = AppLocalizations.of(context)!;
    final months = [
      l10n.january,
      l10n.february,
      l10n.march,
      l10n.april,
      l10n.may,
      l10n.june,
      l10n.july,
      l10n.august,
      l10n.september,
      l10n.october,
      l10n.november,
      l10n.december,
    ];
    return months[month - 1];
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return const Color(0xFF10B981);
      case PaymentStatus.pending:
        return const Color(0xFFF59E0B);
      case PaymentStatus.overdue:
        return const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final receiptProvider = context.watch<ReceiptProvider>();
    final buildingProvider = context.watch<BuildingProvider>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _ReceiptAppBar(
        onAddPressed: () => receiptProvider.receiptsState.when(
          success: (allReceipts) => _navigateToAddReceipt(allReceipts),
          loading: () {},
          error: (_) {},
        ),
      ),
      body: Stack(
        children: [
          if (theme.brightness == Brightness.light)
            _BackgroundGradient(
              height: _calculateBackgroundHeight(context),
              color: theme.colorScheme.primary,
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ReceiptList(
              receiptProvider: receiptProvider,
              buildingProvider: buildingProvider,
              selectedBuildingId: _selectedBuildingId,
              selectedStatus: _selectedStatus,
              animationController: _animationController,
              fadeAnimation: _fadeAnimation,
              slideAnimation: _slideAnimation,
              onBuildingChanged: (v) => setState(() => _selectedBuildingId = v),
              onStatusChanged: (s) => setState(() => _selectedStatus = s),
              onEditReceipt: _navigateToEditReceipt,
              onViewDetail: _navigateToReceiptDetail,
              onShowMenuOptions: _showMenuOptions,
              onRefresh: _loadData,
              onConfirmDelete: _confirmDeleteReceipt,
              onHandleDelete: _handleDeleteReceipt,
              getStatusColor: _getStatusColor,
              getKhmerMonth: getKhmerMonth,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateBackgroundHeight(BuildContext context) {
    final appBarHeight = Scaffold.of(context).appBarMaxHeight ?? kToolbarHeight;
    const summaryCardHeight = 240.0;
    return appBarHeight + summaryCardHeight - 200;
  }
}

class _ReceiptAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ReceiptAppBar({required this.onAddPressed});

  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isLight = theme.brightness == Brightness.light;
    final iconColor = isLight ? Colors.white : theme.colorScheme.onSurface;
    final backgroundColor =
        isLight ? theme.colorScheme.primary : theme.appBarTheme.backgroundColor;

    return AppBar(
      automaticallyImplyLeading: false,
      title: Text(
        l10n.receiptTitle,
        style: TextStyle(
          color: iconColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: backgroundColor,
      elevation: 0,
      iconTheme: IconThemeData(color: iconColor),
      actions: [
        // Notification button with badge
        Consumer<NotificationProvider>(
          builder: (context, notificationProvider, child) {
            final unreadCount = notificationProvider.unreadCount;

            return Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.notifications_outlined, color: iconColor),
                  tooltip: 'Notifications',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationScreen(),
                      ),
                    );
                  },
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: backgroundColor ?? Colors.white,
                          width: 1.5,
                        ),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        IconButton(
          icon: Icon(Icons.add, color: iconColor),
          tooltip: l10n.createNewReceipt,
          onPressed: onAddPressed,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
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
        decoration: BoxDecoration(color: color),
      ),
    );
  }
}
