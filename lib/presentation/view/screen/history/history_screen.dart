import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:receipts_v2/data/models/receipt.dart';
import 'package:receipts_v2/presentation/providers/receipt_provider.dart';
import 'package:receipts_v2/presentation/view/screen/receipt/widgets/receipt_detail.dart';
import 'package:receipts_v2/presentation/view/screen/receipt/widgets/receipt_card.dart';

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
    await receiptProvider.load();
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
      filtered = filtered.where((receipt) => receipt.date.month == selectedMonth);
    }

    return filtered.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  Widget _buildSearchBar(ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isSearching ? 56 : 0,
      child: _isSearching
          ? Container(
              margin: const EdgeInsets.only(bottom: 16),
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
                    height: 0.5
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
      margin: const EdgeInsets.only(bottom: 16),
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
                });
              },
              label: Text(
                _khmerMonths[index],
                style: TextStyle(
                  color: isSelected
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              backgroundColor: theme.colorScheme.surfaceVariant,
              selectedColor: theme.colorScheme.primary,
              checkmarkColor: theme.colorScheme.onSurface,
              elevation: isSelected ? 4 : 0,
              shadowColor: theme.colorScheme.primary.withOpacity(0.3),
            ),
          );
        },
      ),
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
                child: ReceiptCard(
                  receipt: receipt,
                  ontap: () => _viewDetail(context, receipt),
                  onLongPress: () {
                    HapticFeedback.mediumImpact();
                  },
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
        backgroundColor: theme.appBarTheme.backgroundColor,
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
                }
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSearchBar(theme),
            _buildMonthFilter(theme),
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