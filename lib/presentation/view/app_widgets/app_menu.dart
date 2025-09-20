import 'package:flutter/material.dart';

class AppMenu extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const AppMenu({super.key, required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onTap,
        backgroundColor: colorScheme.background,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
        selectedFontSize: 11.0,
        unselectedFontSize: 11.0,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: [
          _buildBottomNavItem(context, Icons.receipt, 'វិក្កយបត្រ', 0),
          _buildBottomNavItem(context, Icons.history, 'ទិន្នន័យចាស់', 1),
          _buildBottomNavItem(context, Icons.apartment, 'អគារ', 2),
          _buildBottomNavItem(context, Icons.person, 'អ្នកជួល', 3),
          // _buildBottomNavItem(context, Icons.settings, 'ការកំណត់', 4)
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
          const SizedBox(height: 2), // Less spacing
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10, // Smaller font
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
