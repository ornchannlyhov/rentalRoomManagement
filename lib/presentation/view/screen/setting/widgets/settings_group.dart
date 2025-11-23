import 'package:flutter/material.dart';
import 'package:joul_v2/core/theme/app_theme.dart';

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({
    super.key,
    required this.items,
    required this.isDarkMode,
  });

  final List<Widget> items;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.cardColorDark : colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: items.map((item) {
          int index = items.indexOf(item);
          bool isLast = index == items.length - 1;

          return Column(
            children: [
              item,
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 60,
                  color: colorScheme.onSurface.withOpacity(0.1),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
