import 'package:flutter/material.dart';
import 'screen_type.dart';
import 'package:joul_v2/l10n/app_localizations.dart';  

class ScreenSwitchButton extends StatefulWidget {
  final Function(ScreenType) onScreenSelected;
  final ScreenType initialSelection;

  const ScreenSwitchButton({
    required this.onScreenSelected,
    this.initialSelection = ScreenType.room,
    super.key,
  });

  @override
  State<ScreenSwitchButton> createState() => _ScreenSwitchButtonState();
}

class _ScreenSwitchButtonState extends State<ScreenSwitchButton> {
  late ScreenType _selectedScreen;

  @override
  void initState() {
    super.initState();
    _selectedScreen = widget.initialSelection;
  }

  void _handleScreenTap(ScreenType screen) {
    if (_selectedScreen == screen) return;

    setState(() => _selectedScreen = screen);
    widget.onScreenSelected(screen);
  }

  Widget _buildSwitchOption(
    BuildContext context,
    ScreenType screen,
    String label,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isSelected = _selectedScreen == screen;
    final textTheme = theme.textTheme;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _handleScreenTap(screen),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            height: 26,
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(30),
              border: isSelected
                  ? null
                  : Border.all(
                      color: colorScheme.outline.withOpacity(0.2),
                      width: 1,
                    ),
            ),
            child: Center(
              child: Text(
                label,
                style: textTheme.labelLarge?.copyWith(
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;   // ← NEW

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildSwitchOption(context, ScreenType.room, l10n.rooms),
          _buildSwitchOption(context, ScreenType.service, l10n.services),
          _buildSwitchOption(context, ScreenType.report, l10n.reports),
        ],
      ),
    );
  }
}