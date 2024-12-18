import 'package:flutter/material.dart';

class AppMenu extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const AppMenu({super.key, required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 85,
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: onTap,
          backgroundColor: const Color.fromARGB(255, 18, 13, 29),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12.0,
          unselectedFontSize: 12.0,
          items: [
            BottomNavigationBarItem(
              icon: _buildMenuItem(Icons.receipt, 'Receipts', 0),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: _buildMenuItem(Icons.history, 'History', 1),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: _buildMenuItem(Icons.apartment, 'Buildings', 2),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: _buildMenuItem(Icons.person, 'Clients', 3),
              label: '',
            ),
          ],
        ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, int index) {
    final bool isSelected = selectedIndex == index;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.white : Colors.grey,
          ),
          const SizedBox(height: 2.0),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
