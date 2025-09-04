import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:receipts_v2/data/repositories/buidling_repository.dart';
import 'package:receipts_v2/data/repositories/room_repository.dart'; 
import 'package:receipts_v2/presentation/providers/building_provider.dart';
import 'package:receipts_v2/presentation/providers/receipt_provider.dart';
import 'package:receipts_v2/presentation/providers/room_provider.dart';
import 'package:receipts_v2/presentation/providers/service_provider.dart';
import 'package:receipts_v2/presentation/providers/tenant_provider.dart';
import 'package:receipts_v2/presentation/view/app_widgets/app_menu.dart';
import 'package:receipts_v2/presentation/view/screen/building/building_screen.dart';
import 'package:receipts_v2/presentation/view/screen/history/history_screen.dart';
import 'package:receipts_v2/presentation/view/screen/receipt/receipt_screen.dart';
import 'package:receipts_v2/presentation/view/screen/tenant/tenant_screen.dart';
import 'core/app_theme.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // clearSecureStorage();
  await initializeDateFormatting();
  runApp(const MyApp());
}

Future<void> clearSecureStorage() async {
  const storage = FlutterSecureStorage();
  await storage.deleteAll();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final roomRepository = RoomRepository();
    final buildingRepository = BuildingRepository(roomRepository); 

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BuildingProvider(buildingRepository)..load()),
        ChangeNotifierProvider(create: (_) => TenantProvider()..load()),
        ChangeNotifierProvider(create: (_) => ServiceProvider()..load()),
        ChangeNotifierProvider(create: (_) => RoomProvider(roomRepository)..load()), 
        ChangeNotifierProvider(create: (_) => ReceiptProvider()..load()),
      ],
      child: MaterialApp(
        title: 'Receipts',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const MainScreen(),
      ),
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
    const TenantScreen(),
  ];

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: _screens[_currentIndex],
          ),
          AppMenu(
            selectedIndex: _currentIndex,
            onTap: _onTabSelected,
          ),
        ],
      ),
    );
  }
}