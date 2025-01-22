import 'package:flutter/material.dart';

enum ScreenType { service, room }

class ScreenSwitchButton extends StatefulWidget {
  final Function(ScreenType) onScreenSelected;
  const ScreenSwitchButton({required this.onScreenSelected, super.key});

  @override
  State<ScreenSwitchButton> createState() => _ScreenSwitchButtonState();
}

class _ScreenSwitchButtonState extends State<ScreenSwitchButton> {
  ScreenType _selectedScreen = ScreenType.room;

  void _handleScreenTap(ScreenType screen) {
    setState(() {
      _selectedScreen = screen;
    });
    widget.onScreenSelected(screen);
  }

  Widget _buildSwitchOption(ScreenType screen, String label) {
    final bool isSelected = _selectedScreen == screen;

    return Expanded(
      child: GestureDetector(
        onTap: () => _handleScreenTap(screen),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 18,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF1A0C2D)
                : const Color.fromARGB(255, 18, 13, 29),
            borderRadius: BorderRadius.circular(30.0),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2,vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF120D1D),
        borderRadius: BorderRadius.circular(30.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSwitchOption(ScreenType.room, 'Room'),
          _buildSwitchOption(ScreenType.service, 'Service'),
        ],
      ),
    );
  }
}
