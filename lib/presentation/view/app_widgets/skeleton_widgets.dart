import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:joul_v2/core/theme/app_theme.dart';

/// Skeleton for BuildingCard - matches the horizontal card layout
class BuildingCardSkeleton extends StatelessWidget {
  const BuildingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color:
          theme.brightness == Brightness.dark ? AppTheme.cardColorDark : null,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        height: 140,
        child: Row(
          children: [
            // Left side - Image placeholder (40% width)
            Expanded(
              flex: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: Bone.icon(size: 40),
                ),
              ),
            ),
            // Right side - Building info (60% width)
            Expanded(
              flex: 60,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Building name and passKey
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Bone.text(words: 2),
                        const SizedBox(height: 4),
                        Bone.text(words: 1, fontSize: 11),
                        const SizedBox(height: 8),
                        // Rent price chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Bone.text(words: 1, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        // Utility chips row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Bone.text(words: 1, fontSize: 11),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Bone.text(words: 1, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: const Bone(
                        height: 8,
                        width: double.infinity,
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for ReceiptCard - matches the receipt card layout
class ReceiptCardSkeleton extends StatelessWidget {
  const ReceiptCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        color: theme.brightness == Brightness.dark
            ? AppTheme.cardColorDark
            : theme.colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Status Icon circle
          const Bone.circle(size: 40),
          const SizedBox(width: 12),
          // Receipt Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Bone.text(words: 2),
                const SizedBox(height: 6),
                Bone.text(words: 3, fontSize: 12),
                const SizedBox(height: 4),
                Bone.text(words: 2, fontSize: 12),
              ],
            ),
          ),
          // Price and Menu
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Bone.text(words: 1, fontSize: 20),
              const SizedBox(height: 8),
              Bone.icon(size: 24),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton for TenantCard - matches the tenant card layout
class TenantCardSkeleton extends StatelessWidget {
  const TenantCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color:
          theme.brightness == Brightness.dark ? AppTheme.cardColorDark : null,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        height: 120,
        child: Row(
          children: [
            // Profile image
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Bone.square(
                size: 88,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            // Tenant details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Bone.text(words: 2),
                    const SizedBox(height: 8),
                    Bone.text(words: 3, fontSize: 12),
                    const SizedBox(height: 4),
                    Bone.text(words: 2, fontSize: 12),
                    const SizedBox(height: 4),
                    Bone.text(words: 2, fontSize: 12),
                  ],
                ),
              ),
            ),
            // Menu button
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Bone.icon(size: 24),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for NotificationCard - matches the notification card layout
class NotificationCardSkeleton extends StatelessWidget {
  const NotificationCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color:
          theme.brightness == Brightness.dark ? AppTheme.cardColorDark : null,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon container
            Bone.square(
              size: 52,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Bone.text(words: 3),
                  const SizedBox(height: 6),
                  Bone.text(words: 5, fontSize: 14),
                  const SizedBox(height: 6),
                  Bone.text(words: 4, fontSize: 12),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Bone.icon(size: 24),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for Receipt Summary Card
class ReceiptSummarySkeleton extends StatelessWidget {
  const ReceiptSummarySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color:
          theme.brightness == Brightness.dark ? AppTheme.cardColorDark : null,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Bone.text(words: 2),
                Bone.square(size: 32, borderRadius: BorderRadius.circular(8)),
              ],
            ),
            const SizedBox(height: 16),
            // Dropdown placeholder
            Bone(
              height: 48,
              width: double.infinity,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 16),
            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatSkeleton(),
                _buildStatSkeleton(),
                _buildStatSkeleton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatSkeleton() {
    return Column(
      children: [
        Bone.circle(size: 48),
        const SizedBox(height: 8),
        Bone.text(words: 1, fontSize: 12),
        const SizedBox(height: 4),
        Bone.text(words: 1, fontSize: 10),
      ],
    );
  }
}

/// Loading state widget that wraps a list of skeleton items
class SkeletonListLoading extends StatelessWidget {
  final Widget Function() skeletonBuilder;
  final int itemCount;
  final Widget? header;

  const SkeletonListLoading({
    super.key,
    required this.skeletonBuilder,
    this.itemCount = 5,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: itemCount + (header != null ? 1 : 0),
        itemBuilder: (context, index) {
          if (header != null && index == 0) {
            return header!;
          }
          return skeletonBuilder();
        },
      ),
    );
  }
}

/// Loading state widget for a single column layout
class SkeletonColumnLoading extends StatelessWidget {
  final List<Widget> children;

  const SkeletonColumnLoading({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

/// Skeleton for Profile Screen - matches the profile screen layout
class ProfileScreenSkeleton extends StatelessWidget {
  const ProfileScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile header skeleton
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Avatar
                Bone.circle(size: 100),
                const SizedBox(height: 16),
                // Name
                Bone.text(words: 2),
                const SizedBox(height: 8),
                // Phone
                Bone.text(words: 2, fontSize: 14),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Settings groups
          _buildSettingsGroupSkeleton(theme, 3),
          const SizedBox(height: 16),
          _buildSettingsGroupSkeleton(theme, 2),
          const SizedBox(height: 16),
          _buildSettingsGroupSkeleton(theme, 2),
          const SizedBox(height: 32),
          // Logout button skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Bone(
              height: 48,
              width: double.infinity,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroupSkeleton(ThemeData theme, int itemCount) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? AppTheme.cardColorDark
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: List.generate(
          itemCount,
          (index) => Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Bone.circle(size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Bone.text(words: 2),
                      const SizedBox(height: 4),
                      Bone.text(words: 3, fontSize: 12),
                    ],
                  ),
                ),
                Bone.icon(size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton for Payment Config Screen
class PaymentConfigSkeleton extends StatelessWidget {
  const PaymentConfigSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Bone.text(words: 2, fontSize: 14),
          const SizedBox(height: 16),
          // KHQR toggle card skeleton
          _buildToggleCardSkeleton(theme),
          const SizedBox(height: 12),
          // ABA PayWay toggle card skeleton
          _buildToggleCardSkeleton(theme),
          const SizedBox(height: 32),
          // Bank details section header
          Bone.text(words: 2, fontSize: 14),
          const SizedBox(height: 16),
          // Bank name field
          _buildTextFieldSkeleton(theme),
          const SizedBox(height: 16),
          // Account number field
          _buildTextFieldSkeleton(theme),
          const SizedBox(height: 16),
          // Account holder name field
          _buildTextFieldSkeleton(theme),
          const SizedBox(height: 32),
          // Save button
          Bone(
            height: 48,
            width: double.infinity,
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleCardSkeleton(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Bone.square(size: 48, borderRadius: BorderRadius.circular(12)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Bone.text(words: 1),
                const SizedBox(height: 4),
                Bone.text(words: 4, fontSize: 13),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Bone(
            width: 50,
            height: 30,
            borderRadius: BorderRadius.circular(15),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFieldSkeleton(ThemeData theme) {
    return Bone(
      height: 56,
      width: double.infinity,
      borderRadius: BorderRadius.circular(12),
    );
  }
}

/// Skeleton for Analysis Screen
class AnalysisSkeleton extends StatelessWidget {
  const AnalysisSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month selector skeleton
          Container(
            height: 48,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          // Currency selector skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Bone(
                width: 100,
                height: 36,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Summary cards skeleton
          Row(
            children: [
              Expanded(child: _buildSummaryCardSkeleton(theme)),
              const SizedBox(width: 12),
              Expanded(child: _buildSummaryCardSkeleton(theme)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildSummaryCardSkeleton(theme)),
              const SizedBox(width: 12),
              Expanded(child: _buildSummaryCardSkeleton(theme)),
            ],
          ),
          const SizedBox(height: 24),
          // Chart placeholder
          Bone(
            height: 200,
            width: double.infinity,
            borderRadius: BorderRadius.circular(16),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCardSkeleton(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? AppTheme.cardColorDark
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Bone.text(words: 2, fontSize: 12),
          const SizedBox(height: 8),
          Bone.text(words: 1, fontSize: 20),
        ],
      ),
    );
  }
}
