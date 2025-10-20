// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:receipts_v2/data/repositories/report_repository.dart';
import 'package:receipts_v2/helpers/api_helper.dart';
import 'package:receipts_v2/helpers/repository_manager.dart';
import 'package:receipts_v2/data/repositories/auth_repository.dart';
import 'package:receipts_v2/data/repositories/building_repository.dart';
import 'package:receipts_v2/data/repositories/receipt_repository.dart';
import 'package:receipts_v2/data/repositories/room_repository.dart';
import 'package:receipts_v2/data/repositories/service_repository.dart';
import 'package:receipts_v2/data/repositories/tenant_repository.dart';
import 'package:receipts_v2/presentation/providers/auth_provider.dart';
import 'package:receipts_v2/presentation/providers/building_provider.dart';
import 'package:receipts_v2/presentation/providers/receipt_provider.dart';
import 'package:receipts_v2/presentation/providers/report_provider.dart';
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
import 'helpers/app_theme.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logger/logger.dart';
import 'dart:async';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await initializeDateFormatting();

  final Logger logger = Logger();

  // Initialize repositories
  final roomRepository = RoomRepository();
  final buildingRepository = BuildingRepository(roomRepository);
  final receiptRepository = ReceiptRepository();
  final serviceRepository = ServiceRepository();
  final tenantRepository = TenantRepository();
  final authRepository = AuthRepository();
  final reportRepository = ReportRepository();

  final repositoryManager = RepositoryManager(
    buildingRepository: buildingRepository,
    roomRepository: roomRepository,
    tenantRepository: tenantRepository,
    receiptRepository: receiptRepository,
    serviceRepository: serviceRepository,
    reportRepository: reportRepository,
  );

  // Initialize auth provider
  final authProvider = AuthProvider(authRepository);
  await authProvider.load();

  try {
    // Always load from storage first (works offline)
    logger.i('Loading all data from storage...');
    await repositoryManager.loadAll();

    final loadSummary = repositoryManager.getDataSummary();
    logger.i('Data loaded from storage: $loadSummary');

    // Attempt to sync if authenticated and online
    if (authProvider.isAuthenticated()) {
      if (await ApiHelper.instance.hasNetwork()) {
        logger.i('User authenticated and online, syncing from API...');
        final syncSuccess = await repositoryManager.syncAll();

        if (syncSuccess) {
          final syncSummary = repositoryManager.getDataSummary();
          logger.i('Data synced from API: $syncSummary');
        } else {
          logger.w('Sync failed, using cached data');
        }
      } else {
        logger.i('No network, using cached data');
      }
    } else {
      logger.i('User not authenticated, skipping sync');
    }
  } catch (e) {
    logger.e('Error during initialization: $e');
    // Continue with empty/cached data
  }

  final roomProvider = RoomProvider(roomRepository);

  runApp(MyApp(
    authProvider: authProvider,
    repositoryManager: repositoryManager,
    roomRepository: roomRepository,
    buildingRepository: buildingRepository,
    receiptRepository: receiptRepository,
    serviceRepository: serviceRepository,
    tenantRepository: tenantRepository,
    roomProvider: roomProvider,
    reportRepository: reportRepository,
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
  final RepositoryManager repositoryManager;
  final RoomProvider roomProvider;
  final RoomRepository roomRepository;
  final BuildingRepository buildingRepository;
  final ReceiptRepository receiptRepository;
  final ServiceRepository serviceRepository;
  final TenantRepository tenantRepository;
  final ReportRepository reportRepository;

  const MyApp({
    super.key,
    required this.authProvider,
    required this.repositoryManager,
    required this.roomRepository,
    required this.buildingRepository,
    required this.receiptRepository,
    required this.serviceRepository,
    required this.tenantRepository,
    required this.roomProvider,
    required this.reportRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider.value(value: repositoryManager),
        ChangeNotifierProvider(create: (_) => RoomProvider(roomRepository)),
        ChangeNotifierProvider(
            create: (_) => ServiceProvider(serviceRepository)),
        ChangeNotifierProvider(create: (_) => TenantProvider(tenantRepository)),
        ChangeNotifierProvider(
            create: (_) => BuildingProvider(buildingRepository, roomProvider)),
        ChangeNotifierProvider(
            create: (_) => ReceiptProvider(receiptRepository)),
        ChangeNotifierProvider(create: (_) => ReportProvider(reportRepository)),
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
  final Logger _logger = Logger();
  Timer? _syncTimer;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _setupNetworkListeners();
    _startPeriodicSync();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  void _setupNetworkListeners() {
    final apiHelper = ApiHelper.instance;

    // Listen for unauthenticated events
    apiHelper.onUnauthenticated.listen((_) {
      if (mounted) {
        _showSessionExpiredDialog();
      }
    });

    // Listen for network loss
    apiHelper.onNoNetwork.listen((_) {
      if (mounted) {
        _showNetworkErrorDialog();
      }
    });

    // Listen for network restoration
    apiHelper.onNetworkStatusChanged.listen((hasNetwork) {
      if (mounted && hasNetwork) {
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

  void _startPeriodicSync() {
    // Sync every 5 minutes if authenticated and online
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _performBackgroundSync();
    });
  }

  Future<void> _performBackgroundSync() async {
    if (_isSyncing) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final repositoryManager =
        Provider.of<RepositoryManager>(context, listen: false);

    if (!authProvider.isAuthenticated()) return;
    if (!await ApiHelper.instance.hasNetwork()) return;

    _isSyncing = true;
    try {
      _logger.i('Performing background sync...');
      await repositoryManager.syncAll();
      _logger.i('Background sync completed');
    } catch (e) {
      _logger.e('Background sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncDataWhenNetworkRestored() async {
    if (_isSyncing) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final repositoryManager =
        Provider.of<RepositoryManager>(context, listen: false);

    if (!authProvider.isAuthenticated()) return;

    _isSyncing = true;
    try {
      _logger.i('Network restored, syncing all data...');

      final success = await repositoryManager.syncAll();

      if (success && mounted) {
        // Refresh all providers
        Provider.of<BuildingProvider>(context, listen: false).load();
        Provider.of<ServiceProvider>(context, listen: false).load();
        Provider.of<TenantProvider>(context, listen: false).load();
        Provider.of<ReceiptProvider>(context, listen: false).load();
        Provider.of<ReportProvider>(context, listen: false).load();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data synced successfully'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );

        _logger.i('All data synced after network restoration');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync completed with some errors'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      _logger.e('Failed to sync after network restore: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync failed, using cached data'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _isSyncing = false;
    }
  }

  void _showSessionExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Session Expired'),
        content: const Text('Your session has expired. Please log in again.'),
        actions: [
          TextButton(
            onPressed: () async {
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
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
          'You are currently offline. Changes will be saved locally and synced when connection is restored.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
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
        // Show dialogs if needed
        if (authProvider.showNetworkError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showNetworkErrorDialog();
          });
        }

        if (authProvider.sessionHasExpired) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showSessionExpiredDialog();
          });
        }

        // Check authentication
        if (authProvider.isAuthenticated()) {
          return const MainScreen();
        }

        return authProvider.user.when(
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          success: (user) {
            if (user != null) {
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
          Expanded(child: _screens[_currentIndex]),
          AppMenu(
            selectedIndex: _currentIndex,
            onTap: _onTabSelected,
          ),
        ],
      ),
    );
  }
}
