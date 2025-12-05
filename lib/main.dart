import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:joul_v2/presentation/providers/payment_config_provider.dart';
import 'package:joul_v2/presentation/view/screen/auth/login_screen.dart';
import 'package:joul_v2/presentation/view/screen/auth/onboard_screen.dart';
import 'package:joul_v2/presentation/view/screen/auth/register_screen.dart';
import 'package:joul_v2/presentation/view/screen/maintenance/maintenance_screen.dart';
import 'package:provider/provider.dart';
import 'package:joul_v2/core/helper_widgets/auth_wraper.dart';
import 'package:joul_v2/core/helper_widgets/splash_screen.dart';
import 'package:joul_v2/presentation/providers/notification_provider.dart';
import 'package:joul_v2/presentation/providers/network_status_provider.dart';
import 'package:joul_v2/data/repositories/receipt_repository.dart';
import 'package:joul_v2/data/repositories/payment_config_repository.dart';
import 'package:joul_v2/core/helpers/api_helper.dart';
import 'package:joul_v2/core/helpers/repository_manager.dart';
import 'package:joul_v2/data/repositories/notification_repository.dart';
import 'package:joul_v2/presentation/providers/auth_provider.dart';
import 'package:joul_v2/presentation/providers/building_provider.dart';
import 'package:joul_v2/presentation/providers/receipt_provider.dart';
import 'package:joul_v2/presentation/providers/report_provider.dart';
import 'package:joul_v2/presentation/providers/room_provider.dart';
import 'package:joul_v2/presentation/providers/service_provider.dart';
import 'package:joul_v2/presentation/providers/tenant_provider.dart';
import 'package:joul_v2/presentation/providers/theme_provider.dart';
import 'package:joul_v2/presentation/view/app_widgets/offline_banner.dart';
import 'package:joul_v2/core/theme/app_theme.dart';
import 'package:joul_v2/l10n/app_localizations.dart';
import 'package:joul_v2/core/services/health_check_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:async';
import 'package:joul_v2/core/di/service_locator.dart';
import 'package:joul_v2/core/services/local_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await initializeDateFormatting();
  await Firebase.initializeApp();

  // Setup Service Locator (GetIt)
  await setupLocator();

  final navigatorKey = GlobalKey<NavigatorState>();

  // --- Load local data ---
  final repositoryManager = locator<RepositoryManager>();
  final paymentConfigRepository = locator<PaymentConfigRepository>();
  final authProvider = locator<AuthProvider>();

  await repositoryManager.loadAll();
  await paymentConfigRepository.load();
  await authProvider.load();

  // --- Initialize Local Notifications ---
  await LocalNotificationService.initialize();

  // --- Health Check: Verify backend is running ---
  final isBackendHealthy = await HealthCheckService.checkBackendHealth();

  // Start the app (pass health status to determine if we should show maintenance)
  runApp(JoulApp(
    navigatorKey: navigatorKey,
    repositoryManager: repositoryManager,
    isBackendHealthy: isBackendHealthy,
  ));
}

/// Main App wrapper that handles maintenance mode
class JoulApp extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final RepositoryManager repositoryManager;
  final bool isBackendHealthy;

  const JoulApp({
    super.key,
    required this.navigatorKey,
    required this.repositoryManager,
    required this.isBackendHealthy,
  });

  @override
  State<JoulApp> createState() => _JoulAppState();
}

class _JoulAppState extends State<JoulApp> {
  late bool _showMaintenance;
  NotificationProvider? _notificationProvider;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _showMaintenance = !widget.isBackendHealthy;
    if (!_showMaintenance) {
      _initializeApp();
    }
  }

  Future<void> _initializeApp() async {
    // --- Load Providers in Background ---
    unawaited(_loadProvidersInBackground());

    // --- Sync data in background ---
    unawaited(_syncDataInBackground());

    // Notification Provider
    _notificationProvider = NotificationProvider(
      locator<ReceiptRepository>(),
      locator<NotificationRepository>(),
      widget.navigatorKey,
      repositoryManager: widget.repositoryManager,
    );
    _notificationProvider!.setupListeners();
    await _notificationProvider!.loadNotifications();

    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  Future<void> _retryHealthCheck() async {
    final isHealthy = await HealthCheckService.checkBackendHealth();
    if (isHealthy) {
      setState(() => _showMaintenance = false);
      _initializeApp();
    }
  }

  void _useOfflineMode() {
    setState(() => _showMaintenance = false);
    _initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    if (_showMaintenance) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: MaintenanceScreen(
          onRetry: _retryHealthCheck,
          onUseOffline: _useOfflineMode,
        ),
      );
    }

    if (!_initialized || _notificationProvider == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MyApp(
      navigatorKey: widget.navigatorKey,
      notificationProvider: _notificationProvider!,
    );
  }
}

Future<void> _syncDataInBackground() async {
  try {
    final authProvider = locator<AuthProvider>();
    if (authProvider.isAuthenticated()) {
      if (await ApiHelper.instance.hasNetwork()) {
        await locator<RepositoryManager>().syncAll();
        await locator<PaymentConfigRepository>().syncFromApi();
      }
    }
  } catch (_) {
    // Fail silently, continue with cached data
  }
}

Future<void> _loadProvidersInBackground() async {
  try {
    await Future.wait([
      locator<RoomProvider>().load(),
      locator<ServiceProvider>().load(),
      locator<TenantProvider>().load(),
      locator<ReceiptProvider>().load(),
      locator<ReportProvider>().load(),
      locator<BuildingProvider>().load(),
      locator<PaymentConfigProvider>().load(),
    ]);
  } catch (_) {
    // Fail silently
  }
}

class MyApp extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final NotificationProvider notificationProvider;

  const MyApp({
    super.key,
    required this.navigatorKey,
    required this.notificationProvider,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _showSplash = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => locator<AuthProvider>()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NetworkStatusProvider()),
        ChangeNotifierProvider.value(value: widget.notificationProvider),
        Provider(create: (_) => locator<RepositoryManager>()),
        ChangeNotifierProvider(create: (_) => locator<RoomProvider>()),
        ChangeNotifierProvider(create: (_) => locator<ServiceProvider>()),
        ChangeNotifierProvider(create: (_) => locator<TenantProvider>()),
        ChangeNotifierProvider(create: (_) => locator<BuildingProvider>()),
        ChangeNotifierProvider(create: (_) => locator<ReceiptProvider>()),
        ChangeNotifierProvider(create: (_) => locator<ReportProvider>()),
        ChangeNotifierProvider(create: (_) => locator<PaymentConfigProvider>()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          if (!themeProvider.isInitialized) {
            return const MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          return MaterialApp(
            scaffoldMessengerKey: rootScaffoldMessengerKey,
            navigatorKey: widget.navigatorKey,
            title: 'JOUL',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            locale: themeProvider.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              return Stack(
                children: [
                  // Main app content
                  child ?? const SizedBox.shrink(),
                  // Offline banner positioned above bottom nav
                  Consumer<NetworkStatusProvider>(
                    builder: (context, networkStatus, _) {
                      if (networkStatus.hasChecked && !networkStatus.isOnline) {
                        return const OfflineBanner();
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              );
            },
            home: _showSplash ? const SplashScreen() : const AuthWrapper(),
            routes: {
              '/onboarding': (context) => const OnboardingScreen(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
            },
          );
        },
      ),
    );
  }
}

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
