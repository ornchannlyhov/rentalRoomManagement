// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:receipts_v2/core/api_helper.dart';
import 'package:receipts_v2/data/repositories/auth_repository.dart';
import 'package:receipts_v2/data/repositories/buidling_repository.dart';
import 'package:receipts_v2/data/repositories/receipt_repository.dart';
import 'package:receipts_v2/data/repositories/room_repository.dart';
import 'package:receipts_v2/data/repositories/service_repository.dart';
import 'package:receipts_v2/data/repositories/tenant_repository.dart';
import 'package:receipts_v2/presentation/providers/auth_provider.dart';
import 'package:receipts_v2/presentation/providers/building_provider.dart';
import 'package:receipts_v2/presentation/providers/receipt_provider.dart';
import 'package:receipts_v2/presentation/providers/room_provider.dart';
import 'package:receipts_v2/presentation/providers/service_provider.dart';
import 'package:receipts_v2/presentation/providers/tenant_provider.dart';
import 'package:receipts_v2/presentation/providers/theme_provider.dart';
import 'package:receipts_v2/presentation/view/app_widgets/app_menu.dart';
import 'package:receipts_v2/presentation/view/screen/auth/login_screen.dart';
import 'package:receipts_v2/presentation/view/screen/auth/onboard_screen.dart';
import 'package:receipts_v2/presentation/view/screen/auth/register_screen.dart';
import 'package:receipts_v2/presentation/view/screen/building/building_screen.dart';
import 'package:receipts_v2/presentation/view/screen/history/history_screen.dart';
import 'package:receipts_v2/presentation/view/screen/receipt/receipt_screen.dart';
import 'package:receipts_v2/presentation/view/screen/setting/profile_screen.dart';
import 'package:receipts_v2/presentation/view/screen/tenant/tenant_screen.dart';
import 'core/app_theme.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await initializeDateFormatting();
  // await SecureStorageHelper.clearAll(); //uncomment incase of wanting to clean data (testing only)

  // Initialize repositories in correct order
  final authRepository = AuthRepository();
  final roomRepository = RoomRepository();
  final roomProvider = RoomProvider(roomRepository);
  final buildingRepository = BuildingRepository(roomRepository);
  final receiptRepository = ReceiptRepository();
  final serviceRepository = ServiceRepository();
  final tenantRepository = TenantRepository();

  // Initialize auth provider first
  final authProvider = AuthProvider(authRepository);
  await authProvider.load();

  await roomRepository.load();
  await buildingRepository.load();
  await serviceRepository.load();
  await tenantRepository.load();
  await receiptRepository.load();

  // Sync from API if authenticated and online
  if (authProvider.isAuthenticated()) {
    try {
      await buildingRepository.syncFromApi(); // Also syncs rooms
      await serviceRepository.syncFromApi();
      await tenantRepository.syncFromApi();
      await receiptRepository.syncFromApi();
    } catch (e) {
      // Sync errors are logged but don't prevent app startup
      print('Error syncing from API: $e');
    }
  }

  runApp(MyApp(
    authProvider: authProvider,
    roomRepository: roomRepository,
    buildingRepository: buildingRepository,
    receiptRepository: receiptRepository,
    serviceRepository: serviceRepository,
    tenantRepository: tenantRepository,
    roomProvider: roomProvider,
  ));
}

class SecureStorageHelper {
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}

class MyApp extends StatelessWidget {
  final AuthProvider authProvider;
  final RoomProvider roomProvider;
  final RoomRepository roomRepository;
  final BuildingRepository buildingRepository;
  final ReceiptRepository receiptRepository;
  final ServiceRepository serviceRepository;
  final TenantRepository tenantRepository;

  const MyApp({
    super.key,
    required this.authProvider,
    required this.roomRepository,
    required this.buildingRepository,
    required this.receiptRepository,
    required this.serviceRepository,
    required this.tenantRepository,
    required this.roomProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth provider (already initialized and loaded)
        ChangeNotifierProvider.value(value: authProvider),

        // Theme provider
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        // Room provider (already loaded in main)
        ChangeNotifierProvider(
          create: (_) => RoomProvider(roomRepository),
        ),

        // Service provider (already loaded in main)
        ChangeNotifierProvider(
          create: (_) => ServiceProvider(serviceRepository),
        ),

        // Tenant provider (already loaded in main)
        ChangeNotifierProvider(
          create: (_) => TenantProvider(tenantRepository),
        ),

        // Building provider (already loaded in main with rooms linked)
        ChangeNotifierProvider(
          create: (_) => BuildingProvider(buildingRepository, roomProvider),
        ),

        // Receipt provider (already loaded in main)
        ChangeNotifierProvider(
          create: (_) => ReceiptProvider(receiptRepository),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Receipts',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const AuthWrapper(),
            routes: {
              '/onboarding': (context) => const OnboardingScreen(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/home': (context) => const MainScreen(),
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();

    // Listen to API helper streams for network/auth events
    final apiHelper = ApiHelper.instance;

    // Listen for unauthenticated events (401 responses)
    apiHelper.onUnauthenticated.listen((_) {
      if (mounted) {
        _showSessionExpiredDialog();
      }
    });

    // Listen for network loss events
    apiHelper.onNoNetwork.listen((_) {
      if (mounted) {
        _showNetworkErrorDialog();
      }
    });

    // Listen for network status changes
    apiHelper.onNetworkStatusChanged.listen((hasNetwork) {
      if (mounted && hasNetwork) {
        // Network restored - attempt to sync
        _syncDataWhenNetworkRestored();
      }
    });

    // Check for existing session expiry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.sessionHasExpired) {
        _showSessionExpiredDialog();
      }
    });
  }

  Future<void> _syncDataWhenNetworkRestored() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isAuthenticated()) {
      final buildingProvider =
          Provider.of<BuildingProvider>(context, listen: false);
      final serviceProvider =
          Provider.of<ServiceProvider>(context, listen: false);
      final tenantProvider =
          Provider.of<TenantProvider>(context, listen: false);
      final receiptProvider =
          Provider.of<ReceiptProvider>(context, listen: false);

      try {
        // Sync all data when network is restored
        await buildingProvider.syncFromApi();
        await serviceProvider.syncFromApi();
        await tenantProvider.syncFromApi();
        await receiptProvider.syncFromApi();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data synced successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        // Silent fail - data remains cached
        print('Failed to sync after network restore: $e');
      }
    }
  }

  void _showSessionExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Session Expired'),
        content: const Text(
          'Your session has expired. Please log in again.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              await authProvider.logout();
              authProvider.acknowledgeSessionExpired();
              if (mounted) {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showNetworkErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Internet Connection'),
        content: const Text(
          'You are currently offline. Changes will be synced when connection is restored.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              authProvider.acknowledgeNetworkError();
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show network error if needed
        if (authProvider.showNetworkError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showNetworkErrorDialog();
          });
        }

        // Show session expired if needed
        if (authProvider.sessionHasExpired) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showSessionExpiredDialog();
          });
        }

        return authProvider.user.when(
          loading: () => const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
          success: (user) {
            if (user != null && authProvider.isAuthenticated()) {
              return const MainScreen();
            } else {
              return const OnboardingScreen();
            }
          },
          error: (error) => const OnboardingScreen(),
        );
      },
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
    const ProfileScreen(),
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
