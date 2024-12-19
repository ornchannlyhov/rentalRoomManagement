import 'package:flutter/material.dart';
import 'package:receipts_v2/view/appComponent/app_menu.dart';
import 'package:receipts_v2/view/screen/building_screen.dart';
import 'package:receipts_v2/view/screen/history_screen.dart';
import 'package:receipts_v2/view/screen/receipt_screen.dart';
import 'package:receipts_v2/view/screen/client_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Receipts',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A0C2D),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ReceiptScreen(),
    const HistoryScreen(),
    const BuildingScreen(),
    const ClientScreen(),
  ];

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _screens[_currentIndex],
        ),
        AppMenu(
          selectedIndex: _currentIndex,
          onTap: _onTabSelected,
        ),
      ],
    );
  }
}
