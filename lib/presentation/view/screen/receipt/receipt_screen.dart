// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receipts_v2/data/models/enum/mode.dart';
import 'package:receipts_v2/data/models/enum/payment_status.dart';
import 'package:receipts_v2/data/models/receipt.dart';
import 'package:receipts_v2/presentation/providers/receipt_provider.dart';
import 'package:receipts_v2/presentation/providers/building_provider.dart';
import 'package:receipts_v2/presentation/view/screen/receipt/widgets/receipt_detail.dart';
import 'package:receipts_v2/presentation/view/screen/receipt/widgets/receipt_form.dart';
import 'package:receipts_v2/presentation/view/screen/receipt/widgets/receipt_list.dart';

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

  Future<void> _navigateToAddReceipt(List<Receipt> allReceipts) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (ctx) => ReceiptForm(
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
        builder: (ctx) => ReceiptForm(
          mode: Mode.editing,
          receipt: receipt,
          receipts: allReceipts,
        ),
      ),
    );
  }

  Future<void> _navigateToReceiptDetail(Receipt receipt) async {
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
                _buildMenuOption(
                  context,
                  Icons.visibility,
                  'មើលលម្អិត',
                  () {
                    Navigator.pop(context);
                    _navigateToReceiptDetail(receipt);
                  },
                ),
                _buildMenuOption(
                  context,
                  Icons.share,
                  'ចែករំលែក',
                  () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => ReceiptDetailScreen(
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
                  'កែប្រែ',
                  () {
                    Navigator.pop(context);
                    _navigateToEditReceipt(receipt, allReceipts);
                  },
                ),
                _buildMenuOption(
                  context,
                  Icons.delete_outline,
                  'លុប',
                  () {
                    Navigator.pop(context);
                    final provider = context.read<ReceiptProvider>();
                    provider.deleteReceipt(receipt.id);
                    
                  },
                  isDestructive: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuOption(
      BuildContext context, IconData icon, String title, VoidCallback onTap,
      {bool isDestructive = false}) {
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
      backgroundColor: theme.colorScheme.background,
      appBar: _ReceiptAppBar(
        onAddPressed: () {
          receiptProvider.receipts.when(
            success: (allReceipts) => _navigateToAddReceipt(allReceipts),
            loading: () {},
            error: (_) {},
          );
        },
      ),
      body: Stack(
        children: [
          if (theme.brightness == Brightness.light)
            _BackgroundGradient(
                height: _calculateBackgroundHeight(context),
                color: theme.colorScheme.primary),
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
              onBuildingChanged: (newValue) {
                setState(() {
                  _selectedBuildingId = newValue;
                });
              },
              onStatusChanged: (status) {
                setState(() {
                  _selectedStatus = status;
                });
              },
              onEditReceipt: _navigateToEditReceipt,
              onViewDetail: _navigateToReceiptDetail,
              onShowMenuOptions: _showMenuOptions,
              onRefresh: _loadData,
              onShowUndoSnackbar: _showUndoSnackbar,
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
    const summaryCardHeight =
        240.0; // Approximation for the summary card's height
    return appBarHeight + summaryCardHeight - 200;
  }
}

// Extracted Widgets below

class _ReceiptAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ReceiptAppBar({required this.onAddPressed});

  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final iconColor = isLight ? Colors.white : theme.colorScheme.onSurface;
    final backgroundColor =
        isLight ? theme.colorScheme.primary : theme.appBarTheme.backgroundColor;

    return AppBar(
      title: Text(
        'វិក្កយបត្រ',
        style: TextStyle(
          color: iconColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: backgroundColor,
      elevation: 0,
      iconTheme: IconThemeData(color: iconColor),
      actions: [
        IconButton(
          icon: Icon(Icons.add, color: iconColor),
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
      builder: (context, constraints) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: color,
          ),
        );
      },
    );
  }
}


