import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:joul_v2/core/theme/app_theme.dart';

/// Skeleton loader matching the exact BuildingCard layout (horizontal card with image)
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
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                  ),
                  // Menu button placeholder
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Bone.circle(size: 36),
                  ),
                ],
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
                    // Building info
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Building name
                        Bone.text(words: 2),
                        const SizedBox(height: 4),
                        // PassKey
                        Bone.text(words: 2, fontSize: 11),
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Bone.icon(size: 12),
                              const SizedBox(width: 2),
                              Bone.text(words: 1, fontSize: 13),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Utility chips row
                        Row(
                          children: [
                            // Electric chip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Bone.icon(size: 11),
                                  const SizedBox(width: 3),
                                  Bone.text(words: 1, fontSize: 11),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Water chip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Bone.icon(size: 11),
                                  const SizedBox(width: 3),
                                  Bone.text(words: 1, fontSize: 11),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Progress bar placeholder
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

/// Loading state for building screen using Skeletonizer
class BuildingListSkeleton extends StatelessWidget {
  final int itemCount;

  const BuildingListSkeleton({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: itemCount,
        separatorBuilder: (context, index) => const SizedBox(height: 2),
        itemBuilder: (context, index) => const BuildingCardSkeleton(),
      ),
    );
  }
}
