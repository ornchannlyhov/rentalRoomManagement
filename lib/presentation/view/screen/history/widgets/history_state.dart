import 'package:flutter/material.dart';

class LoadingState extends StatelessWidget {
  const LoadingState({
    super.key,
    required this.theme,
  });

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
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
                        : 'មិនមានបង្កាន់ដៃសម្រាប់ខែ ${_khmerMonths[_selectedMonth - 1]}',
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
            onPressed: onRetry,
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
}