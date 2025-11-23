import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:joul_v2/core/services/fcm_service.dart';
import 'package:joul_v2/core/services/local_notification_service.dart';
import 'package:joul_v2/presentation/view/screen/auth/login_screen.dart';
import 'package:joul_v2/presentation/view/screen/auth/onboard_screen.dart';
import 'package:joul_v2/presentation/view/screen/auth/register_screen.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:joul_v2/presentation/providers/notification_provider.dart';
import 'package:joul_v2/data/repositories/report_repository.dart';
import 'package:joul_v2/data/repositories/auth_repository.dart';
import 'package:joul_v2/data/repositories/building_repository.dart';
import 'package:joul_v2/data/repositories/receipt_repository.dart';
import 'package:joul_v2/data/repositories/room_repository.dart';
import 'package:joul_v2/data/repositories/service_repository.dart';
import 'package:joul_v2/data/repositories/tenant_repository.dart';
import 'package:joul_v2/core/helpers/api_helper.dart';
import 'package:joul_v2/core/helpers/repository_manager.dart';
import 'package:joul_v2/core/helper_widgets/auth_wraper.dart';
import 'package:joul_v2/core/helper_widgets/splash_screen.dart';
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
import 'package:joul_v2/core/globals.dart';
import 'firebase_options.dart';

// --- Firebase background handler ---
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('📱 Background message received: ${message.data}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await dotenv.load(fileName: ".env");
  await initializeDateFormatting();
  await _initializeFCMPermissions();
  await LocalNotificationService.initialize();
  // await FlutterSecureStorage().deleteAll();

  final navigatorKey = GlobalKey<NavigatorState>();

  // --- Repositories ---
  final roomRepository = RoomRepository();
  final buildingRepository = BuildingRepository();
  final serviceRepository = ServiceRepository();
  final tenantRepository = TenantRepository();
  final receiptRepository = ReceiptRepository(
    serviceRepository,
    buildingRepository,
    roomRepository,
    tenantRepository,
  );
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

  // --- AuthProvider ---
  final authProvider = AuthProvider(
    authRepository,
    repositoryManager: repositoryManager,
  );
  await authProvider.load();

  if (authProvider.isAuthenticated()) {
    _syncFCMTokenIfLoggedIn(authProvider);
  }

  // --- Load data in background ---
  final loadDataFuture = _loadDataInBackground(
    repositoryManager: repositoryManager,
    authProvider: authProvider,
  );

  // --- Other providers ---
  final roomProvider = RoomProvider(
    roomRepository,
    tenantRepository,
    repositoryManager: repositoryManager,
  );
  final serviceProvider = ServiceProvider(
    serviceRepository,
    repositoryManager: repositoryManager,
  );
  final tenantProvider = TenantProvider(
    tenantRepository,
    repositoryManager: repositoryManager,
  );
  final receiptProvider = ReceiptProvider(
    receiptRepository,
    repositoryManager: repositoryManager,
  );
  final reportProvider = ReportProvider(
    reportRepository,
    repositoryManager: repositoryManager,
  );
  final buildingProvider = BuildingProvider(
    buildingRepository,
    roomRepository,
    repositoryManager: repositoryManager,
  );

  // Load providers in background
  await _loadProvidersInBackground(
    roomProvider: roomProvider,
    serviceProvider: serviceProvider,
    tenantProvider: tenantProvider,
    receiptProvider: receiptProvider,
    reportProvider: reportProvider,
    buildingProvider: buildingProvider,
  );

  final notificationProvider = NotificationProvider(
      receiptRepository, navigatorKey,
      repositoryManager: repositoryManager);
  notificationProvider.setupListeners();

  // Load notifications AFTER receipt provider is loaded to ensure we can map IDs to objects
  await notificationProvider.loadNotifications();

  runApp(MyApp(
    navigatorKey: navigatorKey,
    authProvider: authProvider,
    repositoryManager: repositoryManager,
    roomProvider: roomProvider,
    buildingProvider: buildingProvider,
    receiptProvider: receiptProvider,
    serviceProvider: serviceProvider,
    tenantProvider: tenantProvider,
    reportProvider: reportProvider,
    loadDataFuture: loadDataFuture,
    notificationProvider: notificationProvider,
  ));
}

Future<void> _initializeFCMPermissions() async {
  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    FCMService.setupTokenRefreshListener();
  } else {
    debugPrint('⚠️ Notification permissions denied');
  }
}

/// If user is already logged in on app start, sync FCM token
void _syncFCMTokenIfLoggedIn(AuthProvider authProvider) {
  Future.delayed(const Duration(milliseconds: 500), () async {
    try {
      await FCMService.initialize();
    } catch (e) {
      debugPrint('❌ Failed to sync FCM token: $e');
    }
  });
}

Future<void> _loadDataInBackground({
  required RepositoryManager repositoryManager,
  required AuthProvider authProvider,
}) async {
  try {
    await repositoryManager.loadAll();
    if (authProvider.isAuthenticated()) {
      if (await ApiHelper.instance.hasNetwork()) {
        await repositoryManager.syncAll();
      }
    }
  } catch (_) {
    // Fail silently, continue with cached data
  }
}

Future<void> _loadProvidersInBackground({
  required RoomProvider roomProvider,
  required ServiceProvider serviceProvider,
  required TenantProvider tenantProvider,
  required ReceiptProvider receiptProvider,
  required ReportProvider reportProvider,
  required BuildingProvider buildingProvider,
}) async {
  try {
    await Future.wait([
      roomProvider.load(),
      serviceProvider.load(),
      tenantProvider.load(),
      receiptProvider.load(),
      reportProvider.load(),
      buildingProvider.load(),
    ]);
  } catch (_) {
    // Fail silently
  }
}

class MyApp extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final AuthProvider authProvider;
  final RepositoryManager repositoryManager;
  final RoomProvider roomProvider;
  final BuildingProvider buildingProvider;
  final ReceiptProvider receiptProvider;
  final ServiceProvider serviceProvider;
  final TenantProvider tenantProvider;
  final ReportProvider reportProvider;
  final Future<void> loadDataFuture;
  final NotificationProvider notificationProvider;

  const MyApp({
    super.key,
    required this.navigatorKey,
    required this.authProvider,
    required this.repositoryManager,
    required this.roomProvider,
    required this.buildingProvider,
    required this.receiptProvider,
    required this.serviceProvider,
    required this.tenantProvider,
    required this.reportProvider,
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
        ChangeNotifierProvider.value(value: widget.authProvider),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: widget.notificationProvider),
        Provider.value(value: widget.repositoryManager),
        ChangeNotifierProvider.value(value: widget.roomProvider),
        ChangeNotifierProvider.value(value: widget.serviceProvider),
        ChangeNotifierProvider.value(value: widget.tenantProvider),
        ChangeNotifierProvider.value(value: widget.buildingProvider),
        ChangeNotifierProvider.value(value: widget.receiptProvider),
        ChangeNotifierProvider.value(value: widget.reportProvider),
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
