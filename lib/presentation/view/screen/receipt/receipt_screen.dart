// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receipts_v2/data/models/enum/mode.dart';
import 'package:receipts_v2/data/models/enum/payment_status.dart';
import 'package:receipts_v2/data/models/receipt.dart';
import 'package:receipts_v2/presentation/providers/receipt_provider.dart';
import 'package:receipts_v2/presentation/view/app_widgets/app_bar.dart';
import 'package:receipts_v2/presentation/view/screen/receipt/widgets/filler_by_payment_button.dart';
import 'package:receipts_v2/presentation/view/app_widgets/grid_item.dart';
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
  int selectedMonth = DateTime.now().month; 
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
    await receiptProvider.load();
    _animationController.forward();
  }

  Future<void> _addReceipt(
      BuildContext context, List<Receipt> allReceipts) async {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (ctx) => ReceiptForm(
          receipts: allReceipts,
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
        duration: const Duration(seconds: 4),
        backgroundColor: theme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Row(
          children: [
            Icon(
              Icons.delete_outline,
              color: theme.colorScheme.onError,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                content,
                style: TextStyle(
                  color: theme.colorScheme.onError,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'មិនធ្វើវិញ', // "Undo"
          textColor: theme.colorScheme.onError,
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

  List<DropdownMenuItem<int>> _buildMonthItems() {
    final currentMonth = DateTime.now().month;
    final List<DropdownMenuItem<int>> items = [];

    for (int month = 1; month <= currentMonth; month++) {
      items.add(
        DropdownMenuItem<int>(
          value: month,
          child: Text(
            getKhmerMonth(month),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    return items;
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
                'មិនមានវិក្កយបត្រ', // "No receipts available"
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'សូមចុចប៊ូតុង + ដើម្បីបន្ថែមវិក្កយបត្រថ្មី', // "Tap + to add a new receipt"
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
            'កំពុងដំណើការ...', // "Loading..."
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
            'មានបញ្ហាក្នុងការផ្ទុកទិន្នន័យ', // "Error loading data"
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
            label: const Text('ព្យាយាមម្តងទៀត'), // "Try again"
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
                    color: receipt.paymentStatus == PaymentStatus.paid
                        ? Colors.amber
                        : Colors.green,
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
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final receiptProvider = context.watch<ReceiptProvider>();
    final currentYear = DateTime.now().year;
    final thisMonth = getKhmerMonth(selectedMonth);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppbarCustom(
        header: 'វិក្កយបត្រ', // "Receipts"
        onAddPressed: () {
          receiptProvider.receipts.when(
            success: (allReceipts) => _addReceipt(context, allReceipts),
            loading: () {},
            error: (_) {},
          );
        },
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: receiptProvider.receipts.when(
          loading: () => _buildLoadingState(theme),
          error: (error) => _buildErrorState(theme, error),
          success: (allReceipts) {
            final receipts =
                receiptProvider.getReceiptsByMonth(currentYear, selectedMonth);
            final filteredReceipts =
                _filterReceiptsByStatus(receipts, selectedStatus);

            return Column(
              children: [
                Card(
                  margin: EdgeInsets.zero,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.calendar_month,
                                    size: 20, color: colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'ខែ $thisMonth',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            PopupMenuButton<int>(
                              icon: Icon(Icons.filter_list,
                                  color: colorScheme.primary),
                              tooltip: 'ជ្រើសរើសខែ',
                              onSelected: (int newValue) {
                                setState(() {
                                  selectedMonth = newValue;
                                });
                              },
                              itemBuilder: (BuildContext context) =>
                                  _buildMonthItems().map((item) {
                                return PopupMenuItem<int>(
                                  value: item.value,
                                  child: item.child,
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final availableWidth = constraints.maxWidth;
                            final itemWidth = (availableWidth - 32) / 3;

                            return SizedBox(
                              height: itemWidth * 0.8,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    width: itemWidth,
                                    child: GridItem(
                                      label: "កំពុងរង់ចាំ",
                                      icon: Icons.hourglass_empty_sharp,
                                      amount: _countReceiptsByStatus(
                                          receipts, PaymentStatus.pending),
                                      iconColor: Colors.amber,
                                      border: true,
                                    ),
                                  ),
                                  SizedBox(
                                    width: itemWidth,
                                    child: GridItem(
                                      label: "បានបង់",
                                      icon: Icons.check_circle,
                                      amount: _countReceiptsByStatus(
                                          receipts, PaymentStatus.paid),
                                      iconColor: Colors.green,
                                      border: true,
                                    ),
                                  ),
                                  SizedBox(
                                    width: itemWidth,
                                    child: GridItem(
                                      label: "ហួសកំណត់",
                                      icon: Icons.error,
                                      amount: _countReceiptsByStatus(
                                          receipts, PaymentStatus.overdue),
                                      iconColor: Colors.red,
                                      border: true,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
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
        ),
      ),
    );
  }

  String translatePaymentStatus(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return 'បានបង់ប្រាក់';
      case PaymentStatus.pending:
        return 'មិនទាន់បង់ប្រាក់';
      default:
        return status.name;
    }
  }
}
