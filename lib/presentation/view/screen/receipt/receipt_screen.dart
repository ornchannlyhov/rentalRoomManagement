// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receipts_v2/data/models/enum/mode.dart';
import 'package:receipts_v2/data/models/enum/payment_status.dart';
import 'package:receipts_v2/data/models/receipt.dart';
import 'package:receipts_v2/presentation/providers/receipt_provider.dart';
import 'package:receipts_v2/presentation/providers/building_provider.dart';
import 'package:receipts_v2/presentation/view/screen/receipt/widgets/advanced_analysis.dart';
import 'package:receipts_v2/presentation/view/screen/receipt/widgets/filler_by_payment_button.dart';
import 'package:receipts_v2/presentation/view/screen/receipt/widgets/receipt_card.dart';
import 'package:receipts_v2/presentation/view/screen/receipt/widgets/receipt_detail.dart';
import 'package:receipts_v2/presentation/view/screen/receipt/widgets/receipt_form.dart';

class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen>
    with SingleTickerProviderStateMixin {
  PaymentStatus selectedStatus = PaymentStatus.paid;
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
    await Future.wait([
      receiptProvider.load(),
      buildingProvider.load(),
    ]);
    _animationController.forward();
  }

  Future<void> _addReceipt(
      BuildContext context, List<Receipt> allReceipts) async {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (ctx) => ReceiptForm(
          receipts: allReceipts,
          selectedBuildingId:
              _selectedBuildingId, 
        ),
      ),
    );
  }

  Future<void> _editReceipt(
      BuildContext context, Receipt receipt, List<Receipt> allReceipts) async {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (ctx) => ReceiptForm(
          mode: Mode.editing,
          receipt: receipt,
          receipts: allReceipts,
        ),
      ),
    );
  }

  Future<void> _viewDetail(BuildContext context, Receipt receipt) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => ReceiptDetailScreen(receipt: receipt),
      ),
    );
  }

  void _showMenuOptions(
      BuildContext context, Receipt receipt, List<Receipt> allReceipts) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading:
                      Icon(Icons.visibility, color: theme.colorScheme.primary),
                  title: Text(
                    'មើលលម្អិត',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _viewDetail(context, receipt);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.share, color: theme.colorScheme.primary),
                  title: Text(
                    'ចែករំលែក',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (ctx) => ReceiptDetailScreen(
                              receipt: receipt,
                              onShareRequested: () {},
                            ),
                          ),
                        )
                        .then((_) {});
                  },
                ),
                ListTile(
                  leading: Icon(Icons.edit, color: theme.colorScheme.primary),
                  title: Text(
                    'កែប្រែ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _editReceipt(context, receipt, allReceipts);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete_outline,
                      color: theme.colorScheme.error),
                  title: Text(
                    'លុប',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.error,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    final provider = context.read<ReceiptProvider>();
                    final roomNumber = receipt.room?.roomNumber ?? 'ទរទេ';
                    provider.deleteReceipt(receipt.id);
                    _showUndoSnackbar(
                      context,
                      'បានលុបវិក្កយបត្របន្ទប់ $roomNumber',
                      () => provider.restoreReceipt(
                          allReceipts.indexOf(receipt), receipt),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int _countReceiptsByStatus(List<Receipt> receipts, PaymentStatus status) {
    return receipts.where((receipt) => receipt.paymentStatus == status).length;
  }

  List<Receipt> _filterReceiptsByStatus(
      List<Receipt> receipts, PaymentStatus status) {
    return receipts
        .where((receipt) => receipt.paymentStatus == status)
        .toList();
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
          bottom: kBottomNavigationBarHeight +
              MediaQuery.of(context).padding.bottom -
              12,
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

  String getKhmerMonth(int month) {
    const months = [
      'មករា',
      'កុម្ភៈ',
      'មីនា',
      'មេសា',
      'ឧសភា',
      'មិថុនា',
      'កក្កដា',
      'សីហា',
      'កញ្ញា',
      'តុលា',
      'វិច្ឆិកា',
      'ធ្នូ'
    ];
    return months[month - 1];
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
                  Icons.receipt_long_outlined,
                  size: 80,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'មិនមានវិក្កយបត្រ',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'សូមចុចប៊ូតុង + ដើម្បីបន្ថែមវិក្កយបត្រថ្មី',
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
            'កំពុងដំណើការ...',
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
            'មានបញ្ហាក្នុងការផ្ទុកទិន្នន័យ',
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
            label: const Text('ព្យាយាមម្តងទៀត'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptsList(ThemeData theme, List<Receipt> receipts) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _loadData,
        backgroundColor: theme.colorScheme.surfaceVariant,
        color: theme.colorScheme.primary,
        child: ListView.separated(
          padding: const EdgeInsets.all(0),
          itemCount: receipts.length,
          separatorBuilder: (context, index) => const SizedBox(height: 2),
          itemBuilder: (ctx, index) {
            final receipt = receipts[index];
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
                key: Key(receipt.id),
                background: Container(
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                        receipt.paymentStatus == PaymentStatus.paid
                            ? PaymentStatus.pending
                            : PaymentStatus.paid),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Icon(
                    receipt.paymentStatus == PaymentStatus.paid
                        ? Icons.pending_actions
                        : Icons.check,
                    color: Colors.white,
                  ),
                ),
                secondaryBackground: Container(
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
                        'លុប',
                        style: TextStyle(
                          color: theme.colorScheme.onError,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                direction: DismissDirection.horizontal,
                onDismissed: (direction) {
                  final originStatus = receipt.paymentStatus;
                  final provider = context.read<ReceiptProvider>();
                  final roomNumber = receipt.room?.roomNumber ?? 'ទរទេ';

                  if (direction == DismissDirection.startToEnd) {
                    final newStatus =
                        receipt.paymentStatus == PaymentStatus.paid
                            ? PaymentStatus.pending
                            : PaymentStatus.paid;

                    provider.updateReceipt(
                        receipt.copyWith(paymentStatus: newStatus));

                    _showUndoSnackbar(
                      context,
                      "បន្ទប់ $roomNumber បានផ្លាស់ប្តូរទៅជា ${translatePaymentStatus(newStatus)}",
                      () {
                        provider.updateReceipt(
                            receipt.copyWith(paymentStatus: originStatus));
                      },
                    );
                  } else if (direction == DismissDirection.endToStart) {
                    provider.deleteReceipt(receipt.id);
                    _showUndoSnackbar(
                      context,
                      'បានលុបវិក្កយបត្របន្ទប់ $roomNumber',
                      () => provider.restoreReceipt(index, receipt),
                    );
                  }
                },
                child: ReceiptCard(
                  receipt: receipt,
                  ontap: () => _viewDetail(context, receipt),
                  onLongPress: () => _editReceipt(context, receipt, receipts),
                  onMenuPressed: () =>
                      _showMenuOptions(context, receipt, receipts),
                ),
              ),
            );
          },
        ),
      ),
    );
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

  int _countRoomsInBuilding(dynamic building) {
    // Assuming building has a rooms property (List or count)
    return building.rooms?.length ?? 0;
  }

  int _countTotalRooms(List<dynamic> buildings) {
    return buildings.fold(
        0, (sum, building) => sum + _countRoomsInBuilding(building));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final receiptProvider = context.watch<ReceiptProvider>();
    final buildingProvider = context.watch<BuildingProvider>();
    final currentMonth = DateTime.now().month;
    final thisMonth = getKhmerMonth(currentMonth);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(
          'វិក្កយបត្រ',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.light
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.white
              : Theme.of(context).colorScheme.onSurface,
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add,
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () {
              receiptProvider.receipts.when(
                success: (allReceipts) => _addReceipt(context, allReceipts),
                loading: () {},
                error: (_) {},
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          if (theme.brightness == Brightness.light)
            LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  height: _calculateBackgroundHeight(context),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                  ),
                );
              },
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: receiptProvider.receipts.when(
              loading: () => _buildLoadingState(theme),
              error: (error) => _buildErrorState(theme, error),
              success: (allReceipts) {
                return buildingProvider.buildings.when(
                  loading: () => _buildLoadingState(theme),
                  error: (error) => _buildErrorState(theme, error),
                  success: (buildings) {
                    // Filter receipts by building or current month
                    final receipts = _selectedBuildingId != null
                        ? receiptProvider
                            .getReceiptByBuilding(_selectedBuildingId!)
                        : receiptProvider.getReceiptsForCurrentMonth();
                    final filteredReceipts =
                        _filterReceiptsByStatus(receipts, selectedStatus);

                    // Get building name and room counts
                    final totalRooms = _selectedBuildingId != null
                        ? _countRoomsInBuilding(buildings
                            .firstWhere((b) => b.id == _selectedBuildingId))
                        : _countTotalRooms(buildings);
                    final receiptCount = receipts.length;
                    _countReceiptsByStatus(receipts, selectedStatus);
                    final progress =
                        totalRooms > 0 ? receiptCount / totalRooms : 0.0;

                    // Define counts for each payment status
                    final paidCount =
                        _countReceiptsByStatus(receipts, PaymentStatus.paid);
                    final unpaidCount =
                        _countReceiptsByStatus(receipts, PaymentStatus.pending);
                    final partialCount =
                        _countReceiptsByStatus(receipts, PaymentStatus.overdue);

                    return Column(
                      children: [
                        Card(
                          margin: EdgeInsets.zero,
                          elevation: 2,
                          shadowColor: colorScheme.primary.withOpacity(0.15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  colorScheme.surface,
                                  colorScheme.surface.withOpacity(0.95),
                                ],
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primaryContainer,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.calendar_month,
                                              size: 14,
                                              color: colorScheme
                                                  .onPrimaryContainer,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'ខែ $thisMonth',
                                              style: theme.textTheme.titleSmall
                                                  ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme
                                                    .onPrimaryContainer,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  AdvancedAnalysisScreen(
                                                receipts: allReceipts,
                                                buildings: buildings,
                                                selectedBuildingId:
                                                    _selectedBuildingId,
                                              ),
                                            ),
                                          );
                                        },
                                        icon: Icon(
                                          Icons.analytics_rounded,
                                          color: colorScheme.primary,
                                          size: 24,
                                        ),
                                        tooltip: 'ការវិភាគលម្អិត',
                                        style: IconButton.styleFrom(
                                          backgroundColor: colorScheme.primary
                                              .withOpacity(0.1),
                                          padding: const EdgeInsets.all(4),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceVariant,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: colorScheme.shadow
                                              .withOpacity(0.1),
                                          blurRadius: 6,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: colorScheme.onSurface
                                            .withOpacity(0.3),
                                        width: 0.1,
                                      ),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String?>(
                                        isExpanded: true,
                                        value: _selectedBuildingId,
                                        icon: Icon(
                                          Icons.filter_list,
                                          color: colorScheme.primary,
                                          size: 20,
                                        ),
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                          color: colorScheme.onSurface,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        dropdownColor: colorScheme.surface,
                                        borderRadius: BorderRadius.circular(10),
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            _selectedBuildingId = newValue;
                                          });
                                        },
                                        items: [
                                          DropdownMenuItem(
                                            value: null,
                                            child: Text(
                                              'ទាំងអស់',
                                              style: theme.textTheme.titleSmall
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          ...buildings.map((building) =>
                                              DropdownMenuItem(
                                                value: building.id,
                                                child: Text(
                                                  building.name,
                                                  style: theme
                                                      .textTheme.titleSmall
                                                      ?.copyWith(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              )),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Status Cards and Progress Indicator in Same Row
                                  Row(
                                    children: [
                                      // Status Cards Column (takes up most space)
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          children: [
                                            // Status Grid Row
                                            Row(
                                              children: [
                                                // Paid Status
                                                Expanded(
                                                  child: _buildStatusCard(
                                                    PaymentStatus.paid,
                                                    paidCount,
                                                    Icons.check_circle_outline,
                                                    theme,
                                                    colorScheme,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                // Unpaid Status
                                                Expanded(
                                                  child: _buildStatusCard(
                                                    PaymentStatus.pending,
                                                    unpaidCount,
                                                    Icons.pending_actions,
                                                    theme,
                                                    colorScheme,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                // Partial Status
                                                Expanded(
                                                  child: _buildStatusCard(
                                                    PaymentStatus.overdue,
                                                    partialCount,
                                                    Icons.cancel_outlined,
                                                    theme,
                                                    colorScheme,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Progress Indicator (takes up remaining space)
                                      Expanded(
                                        flex: 1,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                SizedBox(
                                                  width: 80,
                                                  height: 80,
                                                  child:
                                                      CircularProgressIndicator(
                                                    value: progress.clamp(
                                                        0.0, 1.0),
                                                    strokeWidth: 3,
                                                    backgroundColor:
                                                        Colors.grey.shade200,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                            Color>(
                                                      colorScheme.primary,
                                                    ),
                                                    strokeCap: StrokeCap.round,
                                                  ),
                                                ),
                                                Text(
                                                  '$receiptCount/$totalRooms',
                                                  style: theme
                                                      .textTheme.bodySmall
                                                      ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: colorScheme.primary,
                                                    fontSize: 9,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'វិក្កយបត្រ/បន្ទប់',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 9,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: FilterByPaymentButton(
                            onStatusSelected: (status) {
                              setState(() {
                                selectedStatus = status;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: filteredReceipts.isEmpty
                              ? _buildEmptyState(theme)
                              : _buildReceiptsList(theme, filteredReceipts),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    PaymentStatus status,
    int count,
    IconData icon,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final statusColor = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 16,
            color: statusColor,
          ),
          const SizedBox(height: 3),
          Text(
            '$count',
            style: theme.textTheme.titleSmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            translatePaymentStatus(status),
            style: theme.textTheme.bodySmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w500,
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  double _calculateBackgroundHeight(BuildContext context) {
    final appBarHeight = Scaffold.of(context).appBarMaxHeight ?? 56.0;
    const paddingTop = 16.0;
    const cardTopMargin = 0.0;
    const cardPaddingTop = 16.0;
    const monthTextHeight = 32.0;
    const buildingRowHeight = 24.0;
    const spacing = 8.0;
    const statusAndProgressHeight = 60.0;

    return appBarHeight +
        paddingTop +
        cardTopMargin +
        cardPaddingTop +
        monthTextHeight +
        buildingRowHeight +
        spacing +
        statusAndProgressHeight -
        160;
  }

  String translatePaymentStatus(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return 'បានបង់ប្រាក់';
      case PaymentStatus.pending:
        return 'មិនទាន់បង់ប្រាក់';
      case PaymentStatus.overdue:
        return 'ហួសកំណត់';
    }
  }
}
