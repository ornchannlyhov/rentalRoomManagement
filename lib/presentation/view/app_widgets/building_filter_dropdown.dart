import 'package:flutter/material.dart';
import 'package:receipts_v2/presentation/providers/building_provider.dart';

class BuildingFilterDropdown extends StatelessWidget {
  const BuildingFilterDropdown({
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
    return buildingProvider.buildings.when(
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
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
              value: selectedBuildingId,
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
              onChanged: onChanged,
              items: dropdownItems,
            ),
          ),
        );
      },
    );
  }
}
