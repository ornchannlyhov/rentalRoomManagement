import 'package:get_it/get_it.dart';
import 'package:joul_v2/core/services/database_service.dart';
import 'package:joul_v2/data/repositories/payment_config_repository.dart';
import 'package:joul_v2/data/repositories/auth_repository.dart';
import 'package:joul_v2/data/repositories/building_repository.dart';
import 'package:joul_v2/data/repositories/receipt_repository.dart';
import 'package:joul_v2/data/repositories/room_repository.dart';
import 'package:joul_v2/data/repositories/service_repository.dart';
import 'package:joul_v2/data/repositories/tenant_repository.dart';
import 'package:joul_v2/data/repositories/report_repository.dart';
import 'package:joul_v2/core/helpers/repository_manager.dart';
import 'package:joul_v2/presentation/providers/auth_provider.dart';
import 'package:joul_v2/presentation/providers/building_provider.dart';
import 'package:joul_v2/presentation/providers/receipt_provider.dart';
import 'package:joul_v2/presentation/providers/room_provider.dart';
import 'package:joul_v2/presentation/providers/service_provider.dart';
import 'package:joul_v2/presentation/providers/tenant_provider.dart';
import 'package:joul_v2/presentation/providers/report_provider.dart';
import 'package:joul_v2/presentation/providers/payment_config_provider.dart';

final locator = GetIt.instance;

Future<void> setupLocator() async {
  // Services
  locator.registerSingleton<DatabaseService>(DatabaseService());
  await locator<DatabaseService>().init();

  // Repositories
  locator.registerLazySingleton(() => AuthRepository());
  locator
      .registerLazySingleton(() => RoomRepository(locator<DatabaseService>()));
  locator.registerLazySingleton(
      () => BuildingRepository(locator<DatabaseService>()));
  locator.registerLazySingleton(
      () => ServiceRepository(locator<DatabaseService>()));
  locator.registerLazySingleton(
      () => TenantRepository(locator<DatabaseService>()));
  locator.registerLazySingleton(
      () => ReportRepository(locator<DatabaseService>()));

  // Repositories with dependencies
  locator.registerLazySingleton(() => ReceiptRepository(
        locator<DatabaseService>(),
        locator<ServiceRepository>(),
        locator<BuildingRepository>(),
        locator<RoomRepository>(),
        locator<TenantRepository>(),
      ));

  locator.registerLazySingleton(() => PaymentConfigRepository(
        locator<DatabaseService>(),
      ));

  // Repository Manager
  locator.registerLazySingleton(() => RepositoryManager(
        buildingRepository: locator<BuildingRepository>(),
        roomRepository: locator<RoomRepository>(),
        tenantRepository: locator<TenantRepository>(),
        receiptRepository: locator<ReceiptRepository>(),
        serviceRepository: locator<ServiceRepository>(),
        reportRepository: locator<ReportRepository>(),
      ));

  // Providers (as singletons so they maintain state)
  locator.registerLazySingleton(() => AuthProvider(
        locator<AuthRepository>(),
        repositoryManager: locator<RepositoryManager>(),
      ));

  locator.registerLazySingleton(() => RoomProvider(
        locator<RoomRepository>(),
        locator<TenantRepository>(),
        repositoryManager: locator<RepositoryManager>(),
      ));

  locator.registerLazySingleton(() => ServiceProvider(
        locator<ServiceRepository>(),
        repositoryManager: locator<RepositoryManager>(),
      ));

  locator.registerLazySingleton(() => TenantProvider(
        locator<TenantRepository>(),
        repositoryManager: locator<RepositoryManager>(),
      ));

  locator.registerLazySingleton(() => ReceiptProvider(
        locator<ReceiptRepository>(),
        repositoryManager: locator<RepositoryManager>(),
      ));

  locator.registerLazySingleton(() => ReportProvider(
        locator<ReportRepository>(),
        repositoryManager: locator<RepositoryManager>(),
      ));

  locator.registerLazySingleton(() => BuildingProvider(
        locator<BuildingRepository>(),
        locator<RoomRepository>(),
        repositoryManager: locator<RepositoryManager>(),
      ));

  locator.registerLazySingleton(() => PaymentConfigProvider(
        locator<PaymentConfigRepository>(),
        repositoryManager: locator<RepositoryManager>(),
      ));
}
