import 'package:flutter/material.dart';
import 'package:joul_v2/l10n/app_localizations.dart'; // Import localizations

class AppMenu extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const AppMenu({super.key, required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final localizations = AppLocalizations.of(context)!; // Get localizations

    return SizedBox(
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onTap,
        backgroundColor: colorScheme.surface,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
        selectedFontSize: 11.0,
        unselectedFontSize: 11.0,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: [
          // Use localized strings
          _buildBottomNavItem(
              context, Icons.receipt, localizations.receiptTab, 0),
          _buildBottomNavItem(context, Icons.history, localizations.historyTab, 1),
          _buildBottomNavItem(
              context, Icons.apartment, localizations.buildingTab, 2),
          _buildBottomNavItem(context, Icons.person, localizations.tenantTab, 3),
          _buildBottomNavItem(
              context, Icons.settings, localizations.settings, 4)
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildBottomNavItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isSelected = selectedIndex == index;

    return BottomNavigationBarItem(
      icon: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: isSelected
                ? colorScheme.primary
                : colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurface.withOpacity(0.6),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      label: '',
    );
  }
}
