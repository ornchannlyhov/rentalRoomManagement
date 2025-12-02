import 'package:hive_flutter/hive_flutter.dart';

class DatabaseService {
  // Payment Config boxes
  static const String paymentConfigBoxName = 'payment_config';
  static const String pendingChangesBoxName = 'pending_changes';

  // Building boxes
  static const String buildingsBoxName = 'buildings';
  static const String buildingsPendingBoxName = 'buildings_pending';

  // Room boxes
  static const String roomsBoxName = 'rooms';
  static const String roomsPendingBoxName = 'rooms_pending';

  // Tenant boxes
  static const String tenantsBoxName = 'tenants';
  static const String tenantsPendingBoxName = 'tenants_pending';

  // Service boxes
  static const String servicesBoxName = 'services';
  static const String servicesPendingBoxName = 'services_pending';

  // Receipt boxes
  static const String receiptsBoxName = 'receipts';
  static const String receiptsPendingBoxName = 'receipts_pending';

  // Report boxes
  static const String reportsBoxName = 'reports';
  static const String reportsPendingBoxName = 'reports_pending';

  Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters if needed
    // Hive.registerAdapter(PaymentConfigAdapter());

    // Open all boxes
    await Hive.openBox<Map>(paymentConfigBoxName);
    await Hive.openBox<Map>(pendingChangesBoxName);
    await Hive.openBox<Map>(buildingsBoxName);
    await Hive.openBox<Map>(buildingsPendingBoxName);
    await Hive.openBox<Map>(roomsBoxName);
    await Hive.openBox<Map>(roomsPendingBoxName);
    await Hive.openBox<Map>(tenantsBoxName);
    await Hive.openBox<Map>(tenantsPendingBoxName);
    await Hive.openBox<Map>(servicesBoxName);
    await Hive.openBox<Map>(servicesPendingBoxName);
    await Hive.openBox<Map>(receiptsBoxName);
    await Hive.openBox<Map>(receiptsPendingBoxName);
    await Hive.openBox<Map>(reportsBoxName);
    await Hive.openBox<Map>(reportsPendingBoxName);
  }

  // Payment Config getters
  Box<Map> get paymentConfigBox => Hive.box<Map>(paymentConfigBoxName);
  Box<Map> get pendingChangesBox => Hive.box<Map>(pendingChangesBoxName);

  // Building getters
  Box<Map> get buildingsBox => Hive.box<Map>(buildingsBoxName);
  Box<Map> get buildingsPendingBox => Hive.box<Map>(buildingsPendingBoxName);

  // Room getters
  Box<Map> get roomsBox => Hive.box<Map>(roomsBoxName);
  Box<Map> get roomsPendingBox => Hive.box<Map>(roomsPendingBoxName);

  // Tenant getters
  Box<Map> get tenantsBox => Hive.box<Map>(tenantsBoxName);
  Box<Map> get tenantsPendingBox => Hive.box<Map>(tenantsPendingBoxName);

  // Service getters
  Box<Map> get servicesBox => Hive.box<Map>(servicesBoxName);
  Box<Map> get servicesPendingBox => Hive.box<Map>(servicesPendingBoxName);

  // Receipt getters
  Box<Map> get receiptsBox => Hive.box<Map>(receiptsBoxName);
  Box<Map> get receiptsPendingBox => Hive.box<Map>(receiptsPendingBoxName);

  // Report getters
  Box<Map> get reportsBox => Hive.box<Map>(reportsBoxName);
  Box<Map> get reportsPendingBox => Hive.box<Map>(reportsPendingBoxName);

  Future<void> clearAll() async {
    await paymentConfigBox.clear();
    await pendingChangesBox.clear();
    await buildingsBox.clear();
    await buildingsPendingBox.clear();
    await roomsBox.clear();
    await roomsPendingBox.clear();
    await tenantsBox.clear();
    await tenantsPendingBox.clear();
    await servicesBox.clear();
    await servicesPendingBox.clear();
    await receiptsBox.clear();
    await receiptsPendingBox.clear();
    await reportsBox.clear();
    await reportsPendingBox.clear();
  }
}
