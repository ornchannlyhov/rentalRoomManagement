import 'package:flutter/material.dart';
import 'package:joul_v2/core/theme/app_theme.dart';

/// Skeleton loader matching the exact BuildingCard layout
class BuildingCardSkeleton extends StatelessWidget {
  const BuildingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color:
          theme.brightness == Brightness.dark ? AppTheme.cardColorDark : null,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side - Building info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Building name
                  _SkeletonBox(
                    width: 140,
                    height: 22,
                    borderRadius: 6,
                  ),
                  const SizedBox(height: 8),

                  // Key label
                  _SkeletonBox(
                    width: 110,
                    height: 14,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 20),

                  // Rent price with icon
                  Row(
                    children: [
                      _SkeletonBox(
                        width: 16,
                        height: 16,
                        borderRadius: 4,
                      ),
                      const SizedBox(width: 6),
                      _SkeletonBox(
                        width: 100,
                        height: 24,
                        borderRadius: 6,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Utility prices row
                  Row(
                    children: [
                      // Electric price
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _SkeletonBox(
                                    width: 14,
                                    height: 14,
                                    borderRadius: 3,
                                  ),
                                  const SizedBox(width: 4),
                                  _SkeletonBox(
                                    width: 40,
                                    height: 16,
                                    borderRadius: 4,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              _SkeletonBox(
                                width: 32,
                                height: 12,
                                borderRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Water price
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _SkeletonBox(
                                    width: 14,
                                    height: 14,
                                    borderRadius: 3,
                                  ),
                                  const SizedBox(width: 4),
                                  _SkeletonBox(
                                    width: 40,
                                    height: 16,
                                    borderRadius: 4,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              _SkeletonBox(
                                width: 28,
                                height: 12,
                                borderRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Right side - Circle and menu
            Column(
              children: [
                // Circular progress
                _SkeletonCircle(size: 100),
                const SizedBox(height: 12),

                // Three dots menu
                _SkeletonBox(
                  width: 32,
                  height: 32,
                  borderRadius: 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Grey skeleton box with darker shade
class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withOpacity(0.15),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Grey skeleton circle with darker shade
class _SkeletonCircle extends StatelessWidget {
  final double size;

  const _SkeletonCircle({required this.size});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: _SkeletonBox(
          width: 24,
          height: 20,
          borderRadius: 4,
        ),
      ),
    );
  }
}
