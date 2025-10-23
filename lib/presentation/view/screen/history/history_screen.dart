// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:receipts_v2/data/models/receipt.dart';
import 'package:receipts_v2/data/models/enum/mode.dart';
import 'package:receipts_v2/data/models/enum/payment_status.dart';
import 'package:receipts_v2/presentation/providers/receipt_provider.dart';
import 'package:receipts_v2/presentation/providers/building_provider.dart';
import 'package:receipts_v2/presentation/view/app_widgets/building_filter_dropdown.dart';
import 'package:receipts_v2/presentation/view/screen/history/widgets/history_state.dart';
import 'package:receipts_v2/presentation/view/screen/receipt/widgets/receipt_detail.dart';
import 'package:receipts_v2/presentation/view/screen/receipt/widgets/receipt_card.dart';
import 'package:receipts_v2/presentation/view/screen/receipt/widgets/receipt_form.dart';

class ReceiptSearchBar extends StatelessWidget {
  const ReceiptSearchBar({
    super.key,
    required this.isSearching,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchQueryChanged,
    required this.onClearSearch,
  });

  final bool isSearching;
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchQueryChanged;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isSearching ? 56 : 0,
      child: isSearching
          ? Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'ស្វែងរកបង្កាន់ដៃ...',
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          onPressed: onClearSearch,
                        )
                      : null,
                  border: InputBorder.none,
                  isDense: true, // reduce default height
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12, // controls vertical centering
                    horizontal: 16,
                  ),
                ),
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onChanged: onSearchQueryChanged,
              ))
          : const SizedBox.shrink(),
    );
  }
}

/// A widget for filtering receipts by month.
class MonthFilterChips extends StatelessWidget {
  const MonthFilterChips({
    super.key,
    required this.selectedMonth,
    required this.onMonthSelected,
  });

  final int selectedMonth;
  final ValueChanged<int> onMonthSelected;

  static const List<String> _khmerMonths = [
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                _khmerMonths[index],
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              backgroundColor: theme.colorScheme.surfaceVariant,
              selectedColor: theme.colorScheme.primary,
              checkmarkColor: Colors.white,
              elevation: isSelected ? 4 : 0,
              shadowColor: theme.colorScheme.primary.withOpacity(0.3),
              side: BorderSide(
                color: isSelected
                    ? Colors.transparent
                    : theme.colorScheme.onSurface.withOpacity(0.4),
                width: 0.1,
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

  static const List<String> _khmerMonths = [
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
    final receiptProvider = context.read<ReceiptProvider>();
    final buildingProvider = context.read<BuildingProvider>();
    await Future.wait([
      receiptProvider.load(),
      buildingProvider.load(),
    ]);
    _animationController.forward();
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
                _buildBottomSheetHandle(theme),
                _buildListTile(
                  context,
                  theme,
                  Icons.visibility,
                  'មើលលម្អិត',
                  () {
                    Navigator.pop(context);
                    _viewDetail(context, receipt);
                  },
                ),
                _buildListTile(
                  context,
                  theme,
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
                _buildListTile(
                  context,
                  theme,
                  Icons.edit,
                  'កែប្រែ',
                  () {
                    Navigator.pop(context);
                    _editReceipt(context, receipt, allReceipts);
                  },
                ),
                _buildListTile(
                  context,
                  theme,
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

  Widget _buildBottomSheetHandle(ThemeData theme) {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.dividerColor,
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
    } else if (_selectedBuildingId != null) {
      filtered = filtered.where(
          (receipt) => receipt.room?.building?.id == _selectedBuildingId);
    } else {
      filtered =
          filtered.where((receipt) => receipt.date.month == _selectedMonth);
    }

    return filtered.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  String _translatePaymentStatus(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return 'បានបង់ប្រាក់';
      case PaymentStatus.pending:
        return 'មិនទាន់បង់ប្រាក់';
      case PaymentStatus.overdue:
        return 'ហួសកំណត់';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(
          'ទិន្នន័យចាស់',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.colorScheme.background,
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
            ReceiptSearchBar(
              isSearching: _isSearching,
              searchController: _searchController,
              searchQuery: _searchQuery,
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
                    return receiptProvider.receipts.when(
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
                              khmerMonths: _khmerMonths,
                              selectedMonth: _selectedMonth,
                              theme: theme);
                        }

                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: RefreshIndicator(
                            onRefresh: _loadData,
                            backgroundColor: theme.colorScheme.surfaceVariant,
                            color: theme.colorScheme.primary,
                            child: ListView.separated(
                              padding: const EdgeInsets.only(bottom: 16),
                              itemCount: filteredReceipts.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (ctx, index) {
                                final receipt = filteredReceipts[index];

                                // Calculate staggered animation intervals with proper clamping
                                final double begin =
                                    (index * 0.05).clamp(0.0, 0.4);
                                final double end =
                                    ((index * 0.05) + 0.6).clamp(0.0, 1.0);

                                return SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(1, 0),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: _animationController,
                                      curve: Interval(
                                        begin,
                                        end,
                                        curve: Curves.easeOutCubic,
                                      ),
                                    ),
                                  ),
                                  child: Hero(
                                    tag: 'receipt_${receipt.id}',
                                    child: Dismissible(
                                      key: Key(receipt.id),
                                      background: Container(
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(
                                              receipt.paymentStatus ==
                                                      PaymentStatus.paid
                                                  ? PaymentStatus.pending
                                                  : PaymentStatus.paid),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        alignment: Alignment.centerLeft,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20),
                                        child: Icon(
                                          receipt.paymentStatus ==
                                                  PaymentStatus.paid
                                              ? Icons.pending_actions
                                              : Icons.check,
                                          color: Colors.white,
                                        ),
                                      ),
                                      secondaryBackground: Container(
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.error,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
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
                                                color:
                                                    theme.colorScheme.onError,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      direction: DismissDirection.horizontal,
                                      onDismissed: (direction) {
                                        final originStatus =
                                            receipt.paymentStatus;
                                        final provider =
                                            context.read<ReceiptProvider>();
                                        final roomNumber =
                                            receipt.room?.roomNumber ?? 'ទរទេ';

                                        if (direction ==
                                            DismissDirection.startToEnd) {
                                          final newStatus =
                                              receipt.paymentStatus ==
                                                      PaymentStatus.paid
                                                  ? PaymentStatus.pending
                                                  : PaymentStatus.paid;

                                          provider.updateReceipt(
                                              receipt.copyWith(
                                                  paymentStatus: newStatus));

                                          _showUndoSnackbar(
                                            context,
                                            "បន្ទប់ $roomNumber បានផ្លាស់ប្តូរទៅជា ${_translatePaymentStatus(newStatus)}",
                                            () {
                                              provider.updateReceipt(
                                                  receipt.copyWith(
                                                      paymentStatus:
                                                          originStatus));
                                            },
                                          );
                                        } else if (direction ==
                                            DismissDirection.endToStart) {
                                          provider.deleteReceipt(receipt.id);
                                        }
                                      },
                                      child: ReceiptCard(
                                        receipt: receipt,
                                        ontap: () =>
                                            _viewDetail(context, receipt),
                                        onLongPress: () {
                                          HapticFeedback.mediumImpact();
                                        },
                                        onMenuPressed: () => _showMenuOptions(
                                            context, receipt, receipts),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
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
