import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:joul_v2/l10n/app_localizations.dart';
import 'package:joul_v2/presentation/view/app_widgets/skeleton_widgets.dart';

class LoadingState extends StatelessWidget {
  const LoadingState({
    super.key,
    required this.theme,
  });

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: 6,
        itemBuilder: (context, index) => const ReceiptCardSkeleton(),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required Animation<Offset> slideAnimation,
    required Animation<double> fadeAnimation,
    required String searchQuery,
    required String? selectedBuildingId,
    required List<String> khmerMonths,
    required int selectedMonth,
    required this.theme,
  })  : _slideAnimation = slideAnimation,
        _fadeAnimation = fadeAnimation,
        _searchQuery = searchQuery,
        _selectedBuildingId = selectedBuildingId,
        _khmerMonths = khmerMonths,
        _selectedMonth = selectedMonth;

  final Animation<Offset> _slideAnimation;
  final Animation<double> _fadeAnimation;
  final String _searchQuery;
  final String? _selectedBuildingId;
  final List<String> _khmerMonths;
  final int _selectedMonth;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                  color: theme.colorScheme.surfaceContainerHighest
                      .withOpacity(0.3),
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
                l10n.noReceipts,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getEmptyMessage(l10n),
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

  String _getEmptyMessage(AppLocalizations l10n) {
    if (_searchQuery.isNotEmpty) {
      return '${l10n.noBuildingsSearch} "$_searchQuery"';
    } else if (_selectedBuildingId != null) {
      return '${l10n.noReceipts} ${l10n.building.toLowerCase()}';
    } else {
      return '${l10n.noReceipts} ${_khmerMonths[_selectedMonth - 1]}';
    }
  }
}

class ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  final Object? error;

  const ErrorState({
    super.key,
    required this.onRetry,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

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
            l10n.errorLoadingData,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onErrorContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.tryAgain),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
