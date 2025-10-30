import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:joul_v2/data/repositories/report_repository.dart';
import 'package:joul_v2/core/helpers/api_helper.dart';
import 'package:joul_v2/core/helper_widgets/auth_wraper.dart';
import 'package:joul_v2/core/helpers/repository_manager.dart';
import 'package:joul_v2/data/repositories/auth_repository.dart';
import 'package:joul_v2/data/repositories/building_repository.dart';
import 'package:joul_v2/data/repositories/receipt_repository.dart';
import 'package:joul_v2/data/repositories/room_repository.dart';
import 'package:joul_v2/data/repositories/service_repository.dart';
import 'package:joul_v2/data/repositories/tenant_repository.dart';
import 'package:joul_v2/presentation/providers/auth_provider.dart';
import 'package:joul_v2/presentation/providers/building_provider.dart';
import 'package:joul_v2/presentation/providers/receipt_provider.dart';
import 'package:joul_v2/presentation/providers/report_provider.dart';
import 'package:joul_v2/presentation/providers/room_provider.dart';
import 'package:joul_v2/presentation/providers/service_provider.dart';
import 'package:joul_v2/presentation/providers/tenant_provider.dart';
import 'package:joul_v2/presentation/providers/theme_provider.dart';
import 'package:joul_v2/presentation/view/screen/auth/login_screen.dart';
import 'package:joul_v2/presentation/view/screen/auth/onboard_screen.dart';
import 'package:joul_v2/presentation/view/screen/auth/register_screen.dart';
import 'package:joul_v2/core/helper_widgets/splash_screen.dart';
import 'core/theme/app_theme.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:async';
import 'package:joul_v2/l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await initializeDateFormatting();
  // await SecureStorageService.clearAll();

  // NotificationService.initialize();

  // STEP 1: Create repositories
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

  // STEP 2: Create RepositoryManager
  final repositoryManager = RepositoryManager(
    buildingRepository: buildingRepository,
    roomRepository: roomRepository,
    tenantRepository: tenantRepository,
    receiptRepository: receiptRepository,
    serviceRepository: serviceRepository,
    reportRepository: reportRepository,
  );

  // STEP 3: Create AuthProvider with RepositoryManager
  final authProvider = AuthProvider(
    authRepository,
    repositoryManager: repositoryManager,
  );
  await authProvider.load();

  // STEP 4: Load data in background
  final loadDataFuture = _loadDataInBackground(
    repositoryManager: repositoryManager,
    authProvider: authProvider,
  );

  // STEP 5: Create providers WITH RepositoryManager
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

  // STEP 6: Load providers in background
  unawaited(_loadProvidersInBackground(
    roomProvider: roomProvider,
    serviceProvider: serviceProvider,
    tenantProvider: tenantProvider,
    receiptProvider: receiptProvider,
    reportProvider: reportProvider,
    buildingProvider: buildingProvider,
  ));

  runApp(MyApp(
    authProvider: authProvider,
    repositoryManager: repositoryManager,
    roomProvider: roomProvider,
    buildingProvider: buildingProvider,
    receiptProvider: receiptProvider,
    serviceProvider: serviceProvider,
    tenantProvider: tenantProvider,
    reportProvider: reportProvider,
    loadDataFuture: loadDataFuture,
  ));
}

Future<void> _loadDataInBackground({
  required RepositoryManager repositoryManager,
  required AuthProvider authProvider,
}) async {
  try {
    // Always load from storage first (works offline)
    await repositoryManager.loadAll();

    // Attempt to sync if authenticated and online
    if (authProvider.isAuthenticated()) {
      if (await ApiHelper.instance.hasNetwork()) {
        await repositoryManager.syncAll();
      }
    }
  } catch (e) {
    // Continue with cached data on error
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
  } catch (e) {
    // Handle errors gracefully
  }
}

class MyApp extends StatefulWidget {
  final AuthProvider authProvider;
  final RepositoryManager repositoryManager;
  final RoomProvider roomProvider;
  final BuildingProvider buildingProvider;
  final ReceiptProvider receiptProvider;
  final ServiceProvider serviceProvider;
  final TenantProvider tenantProvider;
  final ReportProvider reportProvider;
  final Future<void> loadDataFuture;

  const MyApp({
    super.key,
    required this.authProvider,
    required this.repositoryManager,
    required this.roomProvider,
    required this.buildingProvider,
    required this.receiptProvider,
    required this.serviceProvider,
    required this.tenantProvider,
    required this.reportProvider,
    required this.loadDataFuture,
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
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.authProvider),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider.value(value: widget.repositoryManager),
        ChangeNotifierProvider.value(value: widget.roomProvider),
        ChangeNotifierProvider.value(value: widget.serviceProvider),
        ChangeNotifierProvider.value(value: widget.tenantProvider),
        ChangeNotifierProvider.value(value: widget.buildingProvider),
        ChangeNotifierProvider.value(value: widget.receiptProvider),
        ChangeNotifierProvider.value(value: widget.reportProvider),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          // Wait for locale + theme to load before showing the app
          if (!themeProvider.isInitialized) {
            return const MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          return MaterialApp(
            title: 'Receipts',
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

  /// Wipes all securely stored data
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
