import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:joul_v2/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:joul_v2/data/models/receipt.dart';
import 'package:joul_v2/data/models/enum/mode.dart';
import 'package:joul_v2/data/models/enum/payment_status.dart';
import 'package:joul_v2/presentation/providers/receipt_provider.dart';
import 'package:joul_v2/presentation/providers/building_provider.dart';
import 'package:joul_v2/presentation/view/app_widgets/building_filter_dropdown.dart';
import 'package:joul_v2/presentation/view/app_widgets/global_snackbar.dart';
import 'package:joul_v2/presentation/view/app_widgets/search_bar_widget.dart';
import 'package:joul_v2/presentation/view/screen/history/widgets/history_state.dart';
import 'package:joul_v2/presentation/view/screen/receipt/widgets/receipt_detail.dart';
import 'package:joul_v2/presentation/view/screen/receipt/widgets/receipt_card.dart';
import 'package:joul_v2/presentation/view/screen/receipt/widgets/receipt_form.dart';

/// A widget for filtering receipts by month.
class MonthFilterChips extends StatelessWidget {
  const MonthFilterChips({
    super.key,
    required this.selectedMonth,
    required this.onMonthSelected,
  });

  final int selectedMonth;
  final ValueChanged<int> onMonthSelected;

  List<String> _getMonthNames(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthNames = _getMonthNames(context);

    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 12,
        itemBuilder: (context, index) {
          final month = index + 1;
          final isSelected = month == selectedMonth;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              onSelected: (selected) {
                if (selected) onMonthSelected(month);
              },
              label: Text(
                monthNames[index],
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              selectedColor: theme.colorScheme.primary,
              checkmarkColor: Colors.white,
              elevation: isSelected ? 4 : 0,
              shadowColor: theme.colorScheme.primary.withOpacity(0.3),
              side: BorderSide(
                color: isSelected
                    ? Colors.transparent
                    : theme.colorScheme.onSurface.withOpacity(0.4),
                width: 0.5,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The main screen for displaying historical receipts.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _selectedMonth = DateTime.now().month;
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedBuildingId;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
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
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    final receiptProvider = context.read<ReceiptProvider>();
    final buildingProvider = context.read<BuildingProvider>();

    try {
      await Future.wait([
        receiptProvider.syncReceipts(),
        buildingProvider.syncBuildings(),
      ]);
    } catch (e) {
      if (mounted) {
        await Future.wait([
          receiptProvider.load(),
          buildingProvider.load(),
        ]);
      }
    }

    if (mounted) {
      _animationController.forward();
    }
  }

  Future<void> _viewDetail(BuildContext context, Receipt receipt) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ReceiptDetailScreen(receipt: receipt),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
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

  Future<void> _deleteReceipt(Receipt receipt) async {
    final provider = context.read<ReceiptProvider>();
    await provider.deleteReceipt(receipt.id);

    if (mounted) {
      GlobalSnackBar.show(
        context: context,
        message: 'បានលុបវិក្កយបត្រជោគជ័យ',
      );
    }
  }

  Future<bool> _confirmDeleteReceipt(
      BuildContext context, Receipt receipt) async {
    final theme = Theme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
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
                  'លុបវិក្កយបត្រ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'តើអ្នកប្រាកដជាចង់លុបវិក្កយបត្រនេះមែនទេ?',
            style: TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'បោះបង់',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              child: const Text(
                'លុប',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
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
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBottomSheetHandle(theme),
                _buildListTile(
                  context,
                  theme,
                  Icons.visibility,
                  l10n.viewDetails,
                  () {
                    Navigator.pop(context);
                    _viewDetail(context, receipt);
                  },
                ),
                _buildListTile(
                  context,
                  theme,
                  Icons.share,
                  l10n.share,
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
                _buildListTile(
                  context,
                  theme,
                  Icons.edit,
                  l10n.edit,
                  () {
                    Navigator.pop(context);
                    _editReceipt(context, receipt, allReceipts);
                  },
                ),
                _buildListTile(
                  context,
                  theme,
                  Icons.delete_outline,
                  l10n.delete,
                  () async {
                    Navigator.pop(context);
                    final confirmed =
                        await _confirmDeleteReceipt(context, receipt);
                    if (confirmed) {
                      await _deleteReceipt(receipt);
                    }
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

  Widget _buildBottomSheetHandle(ThemeData theme) {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildListTile(BuildContext context, ThemeData theme, IconData icon,
      String title, VoidCallback onTap,
      {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon,
          color: isDestructive
              ? theme.colorScheme.error
              : theme.colorScheme.primary),
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

  List<Receipt> _filterReceipts(List<Receipt> receipts) {
    Iterable<Receipt> filtered = receipts;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((receipt) =>
          receipt.room!.building!.name
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          receipt.room!.roomNumber
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()));
    } else {
      // Apply Month Filter
      filtered =
          filtered.where((receipt) => receipt.date.month == _selectedMonth);

      // Apply Building Filter if selected
      if (_selectedBuildingId != null) {
        filtered = filtered.where(
            (receipt) => receipt.room?.building?.id == _selectedBuildingId);
      }
    }

    return filtered.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  String _translatePaymentStatus(PaymentStatus status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case PaymentStatus.paid:
        return l10n.paidStatus;
      case PaymentStatus.pending:
        return l10n.pendingStatus;
      case PaymentStatus.overdue:
        return l10n.overdueStatus;
    }
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

  Future<void> _handleReceiptDismissed(
      Receipt receipt, DismissDirection direction) async {
    final provider = context.read<ReceiptProvider>();
    final roomNumber =
        receipt.room?.roomNumber ?? AppLocalizations.of(context)!.noRoom;

    if (direction == DismissDirection.startToEnd) {
      _togglePaymentStatus(receipt, roomNumber, provider);
    } else if (direction == DismissDirection.endToStart) {
      // No need to show confirmation here - it's already shown in confirmDismiss
      await _deleteReceipt(receipt);
    }
  }

  void _togglePaymentStatus(
      Receipt receipt, String roomNumber, ReceiptProvider provider) {
    final originalStatus = receipt.paymentStatus;
    final newStatus = receipt.paymentStatus == PaymentStatus.paid
        ? PaymentStatus.pending
        : PaymentStatus.paid;

    provider.updateReceipt(receipt.copyWith(paymentStatus: newStatus));

    final l10n = AppLocalizations.of(context)!;
    GlobalSnackBar.show(
      context: context,
      message: "${l10n.room} $roomNumber ${_translatePaymentStatus(newStatus)}",
      onRestore: () {
        provider.updateReceipt(receipt.copyWith(paymentStatus: originalStatus));
      },
    );
  }

  Widget _buildDismissibleReceipt(Receipt receipt, int index) {
    final theme = Theme.of(context);

    return Dismissible(
      key: Key(receipt.id),
      background: _buildDismissStartBackground(receipt),
      secondaryBackground: _buildDismissEndBackground(theme),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Show confirmation for delete
          return await _confirmDeleteReceipt(context, receipt);
        }
        // Allow immediate dismissal for status toggle
        return true;
      },
      onDismissed: (direction) => _handleReceiptDismissed(receipt, direction),
      child: ReceiptCard(
        receipt: receipt,
        ontap: () => _viewDetail(context, receipt),
        onLongPress: () => HapticFeedback.mediumImpact(),
        onMenuPressed: () => _showMenuOptions(
          context,
          index,
          receipt,
          context.read<ReceiptProvider>().receipts,
        ),
      ),
    );
  }

  Widget _buildDismissStartBackground(Receipt receipt) {
    return Container(
      decoration: BoxDecoration(
        color: _getStatusColor(
          receipt.paymentStatus == PaymentStatus.paid
              ? PaymentStatus.pending
              : PaymentStatus.paid,
        ),
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
    );
  }

  Widget _buildDismissEndBackground(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
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
            l10n.delete,
            style: TextStyle(
              color: theme.colorScheme.onError,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptList(List<Receipt> filteredReceipts, ThemeData theme) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _loadData,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        color: theme.colorScheme.primary,
        child: ListView.separated(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: filteredReceipts.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (ctx, index) {
            final receipt = filteredReceipts[index];
            final double begin = (index * 0.05).clamp(0.0, 0.4);
            final double end = ((index * 0.05) + 0.6).clamp(0.0, 1.0);

            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(begin, end, curve: Curves.easeOutCubic),
                ),
              ),
              child: Hero(
                tag: 'receipt_${receipt.id}',
                child: _buildDismissibleReceipt(receipt, index),
              ),
            );
          },
        ),
      ),
    );
  }

  List<String> _getMonthNames() {
    final l10n = AppLocalizations.of(context)!;
    return [
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          l10n.oldDataTitle,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                  _selectedBuildingId = null;
                }
              });
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 2),
        child: Column(
          children: [
            SearchBarWidget(
              isSearching: _isSearching,
              searchController: _searchController,
              searchQuery: _searchQuery,
              hintText: l10n.searchReceiptHint,
              onSearchQueryChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  if (value.isNotEmpty) {
                    _selectedBuildingId = null;
                  }
                });
              },
              onClearSearch: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedBuildingId = null;
                });
              },
            ),
            MonthFilterChips(
              selectedMonth: _selectedMonth,
              onMonthSelected: (month) {
                setState(() {
                  _selectedMonth = month;
                  _selectedBuildingId = null;
                });
              },
            ),
            Transform.translate(
              offset: const Offset(0, -12),
              child: BuildingFilterDropdown(
                selectedBuildingId: _selectedBuildingId,
                onChanged: (newValue) {
                  setState(() {
                    _selectedBuildingId = newValue;
                    _searchQuery = '';
                    _searchController.clear();
                    _isSearching = false;
                  });
                },
                buildingProvider: Provider.of<BuildingProvider>(context),
              ),
            ),
            Expanded(
              child: Transform.translate(
                offset: const Offset(0, -12),
                child: Consumer<ReceiptProvider>(
                  builder: (context, receiptProvider, child) {
                    return receiptProvider.receiptsState.when(
                      loading: () => LoadingState(theme: theme),
                      error: (error) =>
                          ErrorState(error: error, onRetry: _loadData),
                      success: (receipts) {
                        final filteredReceipts = _filterReceipts(receipts);

                        if (filteredReceipts.isEmpty) {
                          return EmptyState(
                            slideAnimation: _slideAnimation,
                            fadeAnimation: _fadeAnimation,
                            searchQuery: _searchQuery,
                            selectedBuildingId: _selectedBuildingId,
                            khmerMonths: _getMonthNames(),
                            selectedMonth: _selectedMonth,
                            theme: theme,
                          );
                        }

                        return _buildReceiptList(filteredReceipts, theme);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
