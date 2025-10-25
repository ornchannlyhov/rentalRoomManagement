import 'package:flutter/material.dart';
import 'package:receipts_v2/presentation/providers/building_provider.dart';

class BuildingFilterDropdown extends StatelessWidget {
  const BuildingFilterDropdown({
    super.key,
    required this.buildingProvider,
    required this.selectedBuildingId,
    required this.onChanged,
  });

  final BuildingProvider buildingProvider;
  final String? selectedBuildingId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Fix 1: Access buildingsState instead of buildings
    return buildingProvider.buildingsState.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16.0),
        child: LinearProgressIndicator(),
      ),
      error: (error) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Error loading buildings: $error',
          style: TextStyle(color: theme.colorScheme.error),
        ),
      ),
      success: (buildings) {
        final List<DropdownMenuItem<String?>> dropdownItems = [
          DropdownMenuItem(
            value: null,
            child: Text(
              'ទាំងអស់', // "All"
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
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
          padding: const EdgeInsets.only(left: 8, right: 16, top: 2, bottom: 2),
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 1),
              ),
            ],
            border: Border.all(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
              width: 0.2,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              isExpanded: true,
              value: selectedBuildingId,
              // Fix 2: Use neutral icon color to prevent glitching
              icon: Icon(
                Icons.filter_list,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                size: 24,
              ),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              dropdownColor: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              onChanged: onChanged,
              items: dropdownItems,
              selectedItemBuilder: (context) {
                return dropdownItems.map((item) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: item.child,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        );
      },
    );
  }
}
