import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';

// Repositories
import 'package:receipts_v2/data/repositories/auth_repository.dart';
import 'package:receipts_v2/data/repositories/building_repository.dart';
import 'package:receipts_v2/data/repositories/receipt_repository.dart';
import 'package:receipts_v2/data/repositories/report_repository.dart';
import 'package:receipts_v2/data/repositories/room_repository.dart';
import 'package:receipts_v2/data/repositories/service_repository.dart';
import 'package:receipts_v2/data/repositories/tenant_repository.dart';

// Helpers
import 'package:receipts_v2/helpers/api_helper.dart';
import 'package:receipts_v2/helpers/auth_wraper.dart';
import 'package:receipts_v2/helpers/notification_service.dart';
import 'package:receipts_v2/helpers/receipt_image_generator.dart';
import 'package:receipts_v2/helpers/repository_manager.dart';
import 'package:receipts_v2/helpers/app_theme.dart';

// Providers
import 'package:receipts_v2/presentation/providers/auth_provider.dart';
import 'package:receipts_v2/presentation/providers/building_provider.dart';
import 'package:receipts_v2/presentation/providers/receipt_provider.dart';
import 'package:receipts_v2/presentation/providers/report_provider.dart';
import 'package:receipts_v2/presentation/providers/room_provider.dart';
import 'package:receipts_v2/presentation/providers/service_provider.dart';
import 'package:receipts_v2/presentation/providers/tenant_provider.dart';
import 'package:receipts_v2/presentation/providers/theme_provider.dart';

// Screens
import 'package:receipts_v2/presentation/view/screen/auth/login_screen.dart';
import 'package:receipts_v2/presentation/view/screen/auth/onboard_screen.dart';
import 'package:receipts_v2/presentation/view/screen/auth/register_screen.dart';
import 'package:receipts_v2/presentation/view/screen/splash/splash_screen.dart';

// Localization
import 'package:receipts_v2/l10n/app_localizations.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == "generate-monthly-receipts") {
      try {
        NotificationService.initialize();
        final roomRepo = RoomRepository();
        final buildingRepo = BuildingRepository(roomRepo);
        final serviceRepo = ServiceRepository();
        final tenantRepo = TenantRepository();
        final receiptRepo = ReceiptRepository(serviceRepo, buildingRepo, roomRepo, tenantRepo);
        final reportRepo = ReportRepository();

        await Future.wait([
          serviceRepo.load(),
          roomRepo.load(),
          buildingRepo.load(),
          tenantRepo.load(),
          receiptRepo.load(),
          reportRepo.load(),
        ]);

        await receiptRepo.generateReceiptsFromUsage(
          createImage: ReceiptImageGenerator.generateReceiptImage,
        );

        await NotificationService.showNotification(
          'Receipts Generated',
          'New monthly receipts have been successfully created.',
        );

        return Future.value(true);
      } catch (e) {
        await NotificationService.showNotification(
          'Receipt Generation Failed',
          'There was an error creating new receipts.',
        );
        return Future.value(false);
      }
    }
    return Future.value(true);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await initializeDateFormatting();
  final logger = Logger();

  NotificationService.initialize();

  // WorkManager initialization
  if (Platform.isAndroid || Platform.isIOS) {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    Workmanager().registerPeriodicTask(
      "generate-receipts-task",
      "generate-monthly-receipts",
      frequency: const Duration(days: 30),
      initialDelay: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
    );
  } else {
    logger.i('Workmanager not supported on ${Platform.operatingSystem}');
  }

  // Repositories
  final roomRepo = RoomRepository();
  final buildingRepo = BuildingRepository(roomRepo);
  final serviceRepo = ServiceRepository();
  final tenantRepo = TenantRepository();
  final receiptRepo = ReceiptRepository(serviceRepo, buildingRepo, roomRepo, tenantRepo);
  final authRepo = AuthRepository();
  final reportRepo = ReportRepository();

  final repositoryManager = RepositoryManager(
    buildingRepository: buildingRepo,
    roomRepository: roomRepo,
    tenantRepository: tenantRepo,
    receiptRepository: receiptRepo,
    serviceRepository: serviceRepo,
    reportRepository: reportRepo,
  );

  // Auth + Theme
  final authProvider = AuthProvider(authRepo, repositoryManager: repositoryManager);
  final themeProvider = ThemeProvider();

  await authProvider.load();

  try {
    await repositoryManager.loadAll();
    if (authProvider.isAuthenticated() && await ApiHelper.instance.hasNetwork()) {
      logger.i('Syncing data from API...');
      await repositoryManager.syncAll();
    }
  } catch (e) {
    logger.e('Error during initialization: $e');
  }

  // Providers
  final roomProvider = RoomProvider(roomRepo);
  final serviceProvider = ServiceProvider(serviceRepo);
  final tenantProvider = TenantProvider(tenantRepo, repositoryManager);
  final receiptProvider = ReceiptProvider(receiptRepo);
  final reportProvider = ReportProvider(reportRepo);
  final buildingProvider = BuildingProvider(buildingRepo, roomProvider);

  await Future.wait([
    roomProvider.load(),
    serviceProvider.load(),
    tenantProvider.load(),
    receiptProvider.load(),
    reportProvider.load(),
    buildingProvider.load(),
  ]);

  runApp(MyApp(
    authProvider: authProvider,
    repositoryManager: repositoryManager,
    roomProvider: roomProvider,
    buildingProvider: buildingProvider,
    receiptProvider: receiptProvider,
    serviceProvider: serviceProvider,
    tenantProvider: tenantProvider,
    reportProvider: reportProvider,
    themeProvider: themeProvider,
  ));
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
  final ThemeProvider themeProvider;

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
    required this.themeProvider,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
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
        ChangeNotifierProvider.value(value: widget.themeProvider),
        Provider.value(value: widget.repositoryManager),
        ChangeNotifierProvider.value(value: widget.roomProvider),
        ChangeNotifierProvider.value(value: widget.buildingProvider),
        ChangeNotifierProvider.value(value: widget.receiptProvider),
        ChangeNotifierProvider.value(value: widget.serviceProvider),
        ChangeNotifierProvider.value(value: widget.tenantProvider),
        ChangeNotifierProvider.value(value: widget.reportProvider),
      ],
     child: Consumer<ThemeProvider>(
  builder: (context, themeProvider, _) {
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
        '/home': (context) => const MainScreen(),
      },
    );
  },
),

    );
  }
}
