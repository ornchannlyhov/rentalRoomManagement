import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, 
    required this.theme,
    required this.fadeAnimation,
    required this.slideAnimation,
  });

  final ThemeData theme;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
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
                  Icons.people_alt_outlined,
                  size: 80,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'មិនមានអ្នកជួល', // "No tenants available"
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'សូមចុចប៊ូតុង + ដើម្បីបន្ថែមអ្នកជួលថ្មី', // "Tap + to add a new tenant"
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

/// Widget to display when data is loading.
class LoadingState extends StatelessWidget {
  const LoadingState({super.key, required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
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
}

/// Widget to display when an error occurs during data loading.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, 
    required this.theme,
    required this.error,
    required this.onRetry,
  });

  final ThemeData theme;
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
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
            onPressed: onRetry,
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
}

