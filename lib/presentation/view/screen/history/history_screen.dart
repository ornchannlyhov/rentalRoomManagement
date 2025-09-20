// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:receipts_v2/data/models/receipt.dart';
import 'package:receipts_v2/data/models/enum/mode.dart';
import 'package:receipts_v2/data/models/enum/payment_status.dart';
import 'package:receipts_v2/presentation/providers/receipt_provider.dart';
import 'package:receipts_v2/presentation/providers/building_provider.dart'; // Add BuildingProvider
import 'package:receipts_v2/presentation/view/screen/receipt/widgets/receipt_detail.dart';
import 'package:receipts_v2/presentation/view/screen/receipt/widgets/receipt_card.dart';
import 'package:receipts_v2/presentation/view/screen/receipt/widgets/receipt_form.dart';

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

  int selectedMonth = DateTime.now().month;
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
    final buildingProvider =
        context.read<BuildingProvider>(); // Add BuildingProvider
    await Future.wait([
      receiptProvider.load(),
      buildingProvider.load(), // Load buildings
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
          label: 'មិនធ្វើវិញ',
          textColor: theme.colorScheme.onError,
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
      filtered = context
          .read<ReceiptProvider>()
          .getReceiptByBuilding(_selectedBuildingId!);
    } else {
      filtered =
          filtered.where((receipt) => receipt.date.month == selectedMonth);
    }

    return filtered.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  String _translatePaymentStatus(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return 'បានបង់ប្រាក់';
      case PaymentStatus.pending:
        return 'មិនទាន់បង់ប្រាក់';
      default:
        return status.name;
    }
  }

  Widget _buildSearchBar(ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isSearching ? 56 : 0,
      child: _isSearching
          ? Container(
              margin: const EdgeInsets.only(bottom: 8), // Reduced from 16 to 8
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
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'ស្វែងរកបង្កាន់ដៃ...',
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                    height: 0.5,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _selectedBuildingId = null;
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    if (value.isNotEmpty) {
                      _selectedBuildingId = null;
                    }
                  });
                },
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildMonthFilter(ThemeData theme) {
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
                setState(() {
                  selectedMonth = month;
                  _selectedBuildingId = null;
                });
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

  Widget _buildBuildingFilter(ThemeData theme) {
    return Consumer<BuildingProvider>(
      builder: (context, buildingProvider, child) {
        return buildingProvider.buildings.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(8.0), 
            child: LinearProgressIndicator(),
          ),
          error: (error) => Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'មានបញ្ហាក្នុងការផ្ទុកអគារ: $error',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
          success: (buildings) {
            final List<DropdownMenuItem<String?>> dropdownItems = [
              DropdownMenuItem(
                value: null,
                child: Text(
                  'ទាំងអស់',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ...buildings.map((building) => DropdownMenuItem(
                    value: building.id,
                    child: Text(
                      building.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )),
            ];

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              margin: const EdgeInsets.only(bottom: 8),
              height: 48,
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                  width: 0.1,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  isExpanded: true,
                  value: _selectedBuildingId,
                  icon: Icon(
                    Icons.filter_list,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  dropdownColor: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedBuildingId = newValue;
                      _searchQuery = '';
                      _searchController.clear();
                      _isSearching = false;
                    });
                  },
                  items: dropdownItems,
                ),
              ),
            );
          },
        );
      },
    );
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
                'មិនមានបង្កាន់ដៃ',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty
                    ? 'មិនមានលទ្ធផលស្វែងរក "$_searchQuery"'
                    : _selectedBuildingId != null
                        ? 'មិនមានបង្កាន់ដៃសម្រាប់អគារ'
                        : 'មិនមានបង្កាន់ដៃសម្រាប់ខែ ${_khmerMonths[selectedMonth - 1]}',
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

  Widget _buildReceiptsList(ThemeData theme, List<Receipt> receipts) {
    final filteredReceipts = _filterReceipts(receipts);

    if (filteredReceipts.isEmpty) {
      return _buildEmptyState(theme);
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
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (ctx, index) {
            final receipt = filteredReceipts[index];
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    index * 0.05,
                    (index * 0.05) + 0.6,
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
                        "បន្ទប់ $roomNumber បានផ្លាស់ប្តូរទៅជា ${_translatePaymentStatus(newStatus)}",
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
                    onLongPress: () {
                      HapticFeedback.mediumImpact();
                    },
                    onMenuPressed: () =>
                        _showMenuOptions(context, receipt, receipts),
                  ),
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
            _buildSearchBar(theme),
            _buildMonthFilter(theme),
            _buildBuildingFilter(theme),
            Expanded(
              child: Consumer<ReceiptProvider>(
                builder: (context, receiptProvider, child) {
                  return receiptProvider.receipts.when(
                    loading: () => _buildLoadingState(theme),
                    error: (error) => _buildErrorState(theme, error),
                    success: (receipts) => _buildReceiptsList(theme, receipts),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
