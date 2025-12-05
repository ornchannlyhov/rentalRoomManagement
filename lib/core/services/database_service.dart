import 'package:flutter/foundation.dart';
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

  // Notification box
  static const String notificationsBoxName = 'notifications';

  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) {
      if (kDebugMode) {
        print('DatabaseService already initialized');
      }
      return;
    }

    try {
      await Hive.initFlutter();

      // await Hive.deleteFromDisk(); // REMOVED: This wipes data on every app start!

      // TODO:
      // Register Adapters
      // Example: Hive.registerAdapter(PaymentConfigAdapter());

      // Open all boxes with dynamic type to avoid type casting issues
      await Future.wait([
        Hive.openBox<dynamic>(paymentConfigBoxName),
        Hive.openBox<dynamic>(pendingChangesBoxName),
        Hive.openBox<dynamic>(buildingsBoxName),
        Hive.openBox<dynamic>(buildingsPendingBoxName),
        Hive.openBox<dynamic>(roomsBoxName),
        Hive.openBox<dynamic>(roomsPendingBoxName),
        Hive.openBox<dynamic>(tenantsBoxName),
        Hive.openBox<dynamic>(tenantsPendingBoxName),
        Hive.openBox<dynamic>(servicesBoxName),
        Hive.openBox<dynamic>(servicesPendingBoxName),
        Hive.openBox<dynamic>(receiptsBoxName),
        Hive.openBox<dynamic>(receiptsPendingBoxName),
        Hive.openBox<dynamic>(reportsBoxName),
        Hive.openBox<dynamic>(reportsPendingBoxName),
        Hive.openBox<dynamic>(notificationsBoxName),
      ]);

      _isInitialized = true;

      if (kDebugMode) {
        print('DatabaseService initialized successfully');
        print('Total boxes opened: ${Hive.box(buildingsBoxName).length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing DatabaseService: $e');
      }
      rethrow;
    }
  }

  // Check if initialized
  bool get isInitialized => _isInitialized;

  // Payment Config getters
  Box<dynamic> get paymentConfigBox {
    if (!Hive.isBoxOpen(paymentConfigBoxName)) {
      throw Exception('Payment config box is not open. Call init() first.');
    }
    return Hive.box<dynamic>(paymentConfigBoxName);
  }

  Box<dynamic> get pendingChangesBox {
    if (!Hive.isBoxOpen(pendingChangesBoxName)) {
      throw Exception('Pending changes box is not open. Call init() first.');
    }
    return Hive.box<dynamic>(pendingChangesBoxName);
  }

  // Building getters
  Box<dynamic> get buildingsBox {
    if (!Hive.isBoxOpen(buildingsBoxName)) {
      throw Exception('Buildings box is not open. Call init() first.');
    }
    return Hive.box<dynamic>(buildingsBoxName);
  }

  Box<dynamic> get buildingsPendingBox {
    if (!Hive.isBoxOpen(buildingsPendingBoxName)) {
      throw Exception('Buildings pending box is not open. Call init() first.');
    }
    return Hive.box<dynamic>(buildingsPendingBoxName);
  }

  // Room getters
  Box<dynamic> get roomsBox {
    if (!Hive.isBoxOpen(roomsBoxName)) {
      throw Exception('Rooms box is not open. Call init() first.');
    }
    return Hive.box<dynamic>(roomsBoxName);
  }

  Box<dynamic> get roomsPendingBox {
    if (!Hive.isBoxOpen(roomsPendingBoxName)) {
      throw Exception('Rooms pending box is not open. Call init() first.');
    }
    return Hive.box<dynamic>(roomsPendingBoxName);
  }

  // Tenant getters
  Box<dynamic> get tenantsBox {
    if (!Hive.isBoxOpen(tenantsBoxName)) {
      throw Exception('Tenants box is not open. Call init() first.');
    }
    return Hive.box<dynamic>(tenantsBoxName);
  }

  Box<dynamic> get tenantsPendingBox {
    if (!Hive.isBoxOpen(tenantsPendingBoxName)) {
      throw Exception('Tenants pending box is not open. Call init() first.');
    }
    return Hive.box<dynamic>(tenantsPendingBoxName);
  }

  // Service getters
  Box<dynamic> get servicesBox {
    if (!Hive.isBoxOpen(servicesBoxName)) {
      throw Exception('Services box is not open. Call init() first.');
    }
    return Hive.box<dynamic>(servicesBoxName);
  }

  Box<dynamic> get servicesPendingBox {
    if (!Hive.isBoxOpen(servicesPendingBoxName)) {
      throw Exception('Services pending box is not open. Call init() first.');
    }
    return Hive.box<dynamic>(servicesPendingBoxName);
  }

  // Receipt getters
  Box<dynamic> get receiptsBox {
    if (!Hive.isBoxOpen(receiptsBoxName)) {
      throw Exception('Receipts box is not open. Call init() first.');
    }
    return Hive.box<dynamic>(receiptsBoxName);
  }

  Box<dynamic> get receiptsPendingBox {
    if (!Hive.isBoxOpen(receiptsPendingBoxName)) {
      throw Exception('Receipts pending box is not open. Call init() first.');
    }
    return Hive.box<dynamic>(receiptsPendingBoxName);
  }

  // Report getters
  Box<dynamic> get reportsBox {
    if (!Hive.isBoxOpen(reportsBoxName)) {
      throw Exception('Reports box is not open. Call init() first.');
    }
    return Hive.box<dynamic>(reportsBoxName);
  }

  Box<dynamic> get reportsPendingBox {
    if (!Hive.isBoxOpen(reportsPendingBoxName)) {
      throw Exception('Reports pending box is not open. Call init() first.');
    }
    return Hive.box<dynamic>(reportsPendingBoxName);
  }

  // Notification getter
  Box<dynamic> get notificationsBox {
    if (!Hive.isBoxOpen(notificationsBoxName)) {
      throw Exception('Notifications box is not open. Call init() first.');
    }
    return Hive.box<dynamic>(notificationsBoxName);
  }

  // Clear all data from all boxes
  Future<void> clearAll() async {
    try {
      await Future.wait([
        paymentConfigBox.clear(),
        pendingChangesBox.clear(),
        buildingsBox.clear(),
        buildingsPendingBox.clear(),
        roomsBox.clear(),
        roomsPendingBox.clear(),
        tenantsBox.clear(),
        tenantsPendingBox.clear(),
        servicesBox.clear(),
        servicesPendingBox.clear(),
        receiptsBox.clear(),
        receiptsPendingBox.clear(),
        reportsBox.clear(),
        reportsPendingBox.clear(),
        notificationsBox.clear(),
      ]);

      if (kDebugMode) {
        print('All boxes cleared successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing boxes: $e');
      }
      rethrow;
    }
  }

  // Clear specific entity data
  Future<void> clearBuildings() async {
    await buildingsBox.clear();
    await buildingsPendingBox.clear();
    if (kDebugMode) {
      print('Buildings data cleared');
    }
  }

  Future<void> clearRooms() async {
    await roomsBox.clear();
    await roomsPendingBox.clear();
    if (kDebugMode) {
      print('Rooms data cleared');
    }
  }

  Future<void> clearTenants() async {
    await tenantsBox.clear();
    await tenantsPendingBox.clear();
    if (kDebugMode) {
      print('Tenants data cleared');
    }
  }

  Future<void> clearServices() async {
    await servicesBox.clear();
    await servicesPendingBox.clear();
    if (kDebugMode) {
      print('Services data cleared');
    }
  }

  Future<void> clearReceipts() async {
    await receiptsBox.clear();
    await receiptsPendingBox.clear();
    if (kDebugMode) {
      print('Receipts data cleared');
    }
  }

  Future<void> clearReports() async {
    await reportsBox.clear();
    await reportsPendingBox.clear();
    if (kDebugMode) {
      print('Reports data cleared');
    }
  }

  // Get storage statistics
  Map<String, int> getStorageStats() {
    return {
      'paymentConfig': paymentConfigBox.length,
      'pendingChanges': pendingChangesBox.length,
      'buildings': buildingsBox.length,
      'buildingsPending': buildingsPendingBox.length,
      'rooms': roomsBox.length,
      'roomsPending': roomsPendingBox.length,
      'tenants': tenantsBox.length,
      'tenantsPending': tenantsPendingBox.length,
      'services': servicesBox.length,
      'servicesPending': servicesPendingBox.length,
      'receipts': receiptsBox.length,
      'receiptsPending': receiptsPendingBox.length,
      'reports': reportsBox.length,
      'reportsPending': reportsPendingBox.length,
      'notifications': notificationsBox.length,
    };
  }

  // Compact all boxes (optimizes storage)
  Future<void> compactAll() async {
    if (kDebugMode) {
      print('Compacting all Hive boxes...');
    }

    await Future.wait([
      paymentConfigBox.compact(),
      pendingChangesBox.compact(),
      buildingsBox.compact(),
      buildingsPendingBox.compact(),
      roomsBox.compact(),
      roomsPendingBox.compact(),
      tenantsBox.compact(),
      tenantsPendingBox.compact(),
      servicesBox.compact(),
      servicesPendingBox.compact(),
      receiptsBox.compact(),
      receiptsPendingBox.compact(),
      reportsBox.compact(),
      reportsPendingBox.compact(),
      notificationsBox.compact(),
    ]);

    if (kDebugMode) {
      print('All boxes compacted successfully');
    }
  }

  // Close all boxes and clean up
  Future<void> dispose() async {
    try {
      await Hive.close();
      _isInitialized = false;

      if (kDebugMode) {
        print('DatabaseService disposed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error disposing DatabaseService: $e');
      }
    }
  }

  // Delete all Hive data (use with caution!)
  Future<void> deleteAllData() async {
    try {
      await clearAll();
      await Hive.deleteFromDisk();
      _isInitialized = false;

      if (kDebugMode) {
        print('All Hive data deleted from disk');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting Hive data: $e');
      }
      rethrow;
    }
  }
}
