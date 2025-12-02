import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:joul_v2/presentation/providers/payment_config_provider.dart';
import 'package:joul_v2/presentation/view/screen/auth/login_screen.dart';
import 'package:joul_v2/presentation/view/screen/auth/onboard_screen.dart';
import 'package:joul_v2/presentation/view/screen/auth/register_screen.dart';
import 'package:provider/provider.dart';
import 'package:joul_v2/core/helper_widgets/auth_wraper.dart';
import 'package:joul_v2/core/helper_widgets/splash_screen.dart';
import 'package:joul_v2/presentation/providers/notification_provider.dart';
import 'package:joul_v2/data/repositories/receipt_repository.dart';
import 'package:joul_v2/data/repositories/payment_config_repository.dart';
import 'package:joul_v2/core/helpers/api_helper.dart';
import 'package:joul_v2/core/helpers/repository_manager.dart';
import 'package:joul_v2/presentation/providers/auth_provider.dart';
import 'package:joul_v2/presentation/providers/building_provider.dart';
import 'package:joul_v2/presentation/providers/receipt_provider.dart';
import 'package:joul_v2/presentation/providers/report_provider.dart';
import 'package:joul_v2/presentation/providers/room_provider.dart';
import 'package:joul_v2/presentation/providers/service_provider.dart';
import 'package:joul_v2/presentation/providers/tenant_provider.dart';
import 'package:joul_v2/presentation/providers/theme_provider.dart';
import 'package:joul_v2/core/theme/app_theme.dart';
import 'package:joul_v2/l10n/app_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:async';
import 'package:joul_v2/core/di/service_locator.dart';

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

  // --- Load Providers in Background ---
  unawaited(_loadProvidersInBackground());

  // --- Sync data in background ---
  final loadDataFuture = _syncDataInBackground();

  // Notification Provider (needs navigatorKey so instantiated manually for now, or could be refactored)
  // For now, we can keep it here or register it in locator with a setter for navigatorKey
  // Let's keep it manual for simplicity as it depends on navigatorKey
  final notificationProvider = NotificationProvider(
      locator<ReceiptRepository>(), navigatorKey,
      repositoryManager: repositoryManager);
  notificationProvider.setupListeners();
  await notificationProvider.loadNotifications();

  runApp(MyApp(
    navigatorKey: navigatorKey,
    loadDataFuture: loadDataFuture,
    notificationProvider: notificationProvider,
  ));
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
  final Future<void> loadDataFuture;
  final NotificationProvider notificationProvider;

  const MyApp({
    super.key,
    required this.navigatorKey,
    required this.loadDataFuture,
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
