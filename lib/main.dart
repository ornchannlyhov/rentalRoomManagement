// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:receipts_v2/data/repositories/report_repository.dart';
import 'package:receipts_v2/helpers/api_helper.dart';
import 'package:receipts_v2/helpers/auth_wraper.dart';
import 'package:receipts_v2/helpers/notification_service.dart';
import 'package:receipts_v2/helpers/receipt_image_generator.dart';
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
import 'package:receipts_v2/presentation/view/screen/auth/login_screen.dart';
import 'package:receipts_v2/presentation/view/screen/auth/onboard_screen.dart';
import 'package:receipts_v2/presentation/view/screen/auth/register_screen.dart';
import 'package:receipts_v2/presentation/view/screen/splash/splash_screen.dart';
import 'helpers/app_theme.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:async';
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == "generate-monthly-receipts") {
      try {
        NotificationService.initialize();

        final roomRepository = RoomRepository();
        final buildingRepository = BuildingRepository(roomRepository);
        final serviceRepository = ServiceRepository();
        final tenantRepository = TenantRepository();
        final receiptRepository = ReceiptRepository(serviceRepository,
            buildingRepository, roomRepository, tenantRepository);
        final reportRepository = ReportRepository();

        await serviceRepository.load();
        await roomRepository.load();
        await buildingRepository.load();
        await tenantRepository.load();
        await receiptRepository.load();
        await reportRepository.load();
        await receiptRepository.generateReceiptsFromUsage(
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

  final Logger logger = Logger();

  NotificationService.initialize();

  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );

  // Register the periodic task
  Workmanager().registerPeriodicTask(
    "generate-receipts-task",
    "generate-monthly-receipts",
    frequency: const Duration(days: 30),
    initialDelay: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
  );

  final roomRepository = RoomRepository();
  final buildingRepository = BuildingRepository(roomRepository);
  final serviceRepository = ServiceRepository();
  final tenantRepository = TenantRepository();
  final receiptRepository = ReceiptRepository(
      serviceRepository, buildingRepository, roomRepository, tenantRepository);
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
    await repositoryManager.loadAll();

    // Attempt to sync if authenticated and online
    if (authProvider.isAuthenticated()) {
      if (await ApiHelper.instance.hasNetwork()) {
        logger.i('User authenticated and online, syncing from API...');
        final syncSuccess = await repositoryManager.syncAll();

        if (syncSuccess) {
          final syncSummary = repositoryManager.getDataSummary();
          logger.i('Data synced from API: $syncSummary');
        }
      }
    } else {
      logger.i('User not authenticated, skipping sync');
    }
  } catch (e) {
    logger.e('Error during initialization: $e');
    // Continue with empty/cached data
  }

  final roomProvider = RoomProvider(roomRepository);
  final serviceProvider = ServiceProvider(serviceRepository);
  final tenantProvider = TenantProvider(tenantRepository, repositoryManager);
  final receiptProvider = ReceiptProvider(receiptRepository);
  final reportProvider = ReportProvider(reportRepository);
  final buildingProvider = BuildingProvider(buildingRepository, roomProvider);

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
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Show splash for a minimum of 1 second to ensure smooth transition
    Future.delayed(const Duration(seconds: 1), () {
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
          return MaterialApp(
            title: 'Receipts',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
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

class SecureStorageHelper {
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
