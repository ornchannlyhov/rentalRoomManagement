import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
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

  // Initialize auth repository and provider
  final authRepository = AuthRepository();
  final authProvider = AuthProvider(authRepository);
  await authProvider.load();

  runApp(MyApp(
    authProvider: authProvider,
    authRepository: authRepository,
  ));
}

class MyApp extends StatelessWidget {
  final AuthProvider authProvider;
  final AuthRepository authRepository;

  const MyApp({
    super.key,
    required this.authProvider,
    required this.authRepository,
  });

  @override
  Widget build(BuildContext context) {
    // Create all repositories with proper dependencies
    final roomRepository = RoomRepository(authRepository);
    final buildingRepository = BuildingRepository(roomRepository, authRepository);
    final receiptRepository = ReceiptRepository(authRepository);
    final serviceRepository = ServiceRepository(authRepository);
    final tenantRepository = TenantRepository(authRepository);

    return MultiProvider(
      providers: [
        // Auth provider (already initialized)
        ChangeNotifierProvider.value(value: authProvider),
        
        // Theme provider
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        
        // Building provider
        ChangeNotifierProvider(
          create: (_) => BuildingProvider(buildingRepository)..load(),
        ),
        
        // Room provider
        ChangeNotifierProvider(
          create: (_) => RoomProvider(roomRepository)..load(),
        ),
        
        // Receipt provider
        ChangeNotifierProvider(
          create: (_) => ReceiptProvider(receiptRepository)..load(),
        ),
        
        // Service provider
        ChangeNotifierProvider(
          create: (_) => ServiceProvider(serviceRepository)..load(),
        ),
        
        // Tenant provider
        ChangeNotifierProvider(
          create: (_) => TenantProvider(tenantRepository)..load(),
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
    // Listen for session expiry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Show session expired dialog if needed
      if (authProvider.sessionHasExpired) {
        _showSessionExpiredDialog();
      }
    });
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
            onPressed: () {
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              authProvider.acknowledgeSessionExpired();
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/login');
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
          'Please check your internet connection and try again.',
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