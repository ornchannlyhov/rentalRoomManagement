import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:joul_v2/core/services/encrypted_hive.dart';

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
  final Map<String, Box<dynamic>> _boxes = {};

  static const List<String> allBoxNames = [
    paymentConfigBoxName,
    pendingChangesBoxName,
    buildingsBoxName,
    buildingsPendingBoxName,
    roomsBoxName,
    roomsPendingBoxName,
    tenantsBoxName,
    tenantsPendingBoxName,
    servicesBoxName,
    servicesPendingBoxName,
    receiptsBoxName,
    receiptsPendingBoxName,
    reportsBoxName,
    reportsPendingBoxName,
    notificationsBoxName,
  ];

  /// [extraBoxNames] are boxes opened elsewhere (the outbox) that share the
  /// encryption key, so they are reset together if the key is lost.
  Future<void> init({List<String> extraBoxNames = const []}) async {
    if (_isInitialized) {
      if (kDebugMode) {
        print('DatabaseService already initialized');
      }
      return;
    }

    try {
      await Hive.initFlutter();

      // await Hive.deleteFromDisk(); // REMOVED: This wipes data on every app start!

      // Open all boxes with dynamic type to avoid type casting issues
      await EncryptedHive.init([...allBoxNames, ...extraBoxNames]);
      for (final name in allBoxNames) {
        _boxes[name] = await EncryptedHive.open(name);
      }

      _isInitialized = true;

      if (kDebugMode) {
        print('DatabaseService initialized successfully');
        print('Total boxes opened: ${_boxes.length}');
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

  /// Queues from app versions before the shared outbox, by data type.
  /// Their contents are moved into the outbox on first start.
  Map<String, Box<dynamic>> get legacyPendingBoxes => {
        'building': buildingsPendingBox,
        'room': roomsPendingBox,
        'tenant': tenantsPendingBox,
        'service': servicesPendingBox,
        'receipt': receiptsPendingBox,
        'report': reportsPendingBox,
        'paymentConfig': pendingChangesBox,
      };

  /// Stores [records] keyed by id and removes entries that are gone.
  /// Writes first, then deletes, so an interrupted save never loses data
  /// (older versions stored records under list positions; those keys are
  /// cleaned up here too).
  Future<void> writeRecords(
    Box<dynamic> box,
    Map<String, Map<String, dynamic>> records,
  ) async {
    await box.putAll(records);
    final stale = box.keys.where((key) => !records.containsKey(key)).toList();
    if (stale.isNotEmpty) await box.deleteAll(stale);
  }

  // Payment Config getters
  Box<dynamic> get paymentConfigBox {
    if (!_boxes.containsKey(paymentConfigBoxName)) {
      throw Exception('Payment config box is not open. Call init() first.');
    }
    return _boxes[paymentConfigBoxName]!;
  }

  Box<dynamic> get pendingChangesBox {
    if (!_boxes.containsKey(pendingChangesBoxName)) {
      throw Exception('Pending changes box is not open. Call init() first.');
    }
    return _boxes[pendingChangesBoxName]!;
  }

  // Building getters
  Box<dynamic> get buildingsBox {
    if (!_boxes.containsKey(buildingsBoxName)) {
      throw Exception('Buildings box is not open. Call init() first.');
    }
    return _boxes[buildingsBoxName]!;
  }

  Box<dynamic> get buildingsPendingBox {
    if (!_boxes.containsKey(buildingsPendingBoxName)) {
      throw Exception('Buildings pending box is not open. Call init() first.');
    }
    return _boxes[buildingsPendingBoxName]!;
  }

  // Room getters
  Box<dynamic> get roomsBox {
    if (!_boxes.containsKey(roomsBoxName)) {
      throw Exception('Rooms box is not open. Call init() first.');
    }
    return _boxes[roomsBoxName]!;
  }

  Box<dynamic> get roomsPendingBox {
    if (!_boxes.containsKey(roomsPendingBoxName)) {
      throw Exception('Rooms pending box is not open. Call init() first.');
    }
    return _boxes[roomsPendingBoxName]!;
  }

  // Tenant getters
  Box<dynamic> get tenantsBox {
    if (!_boxes.containsKey(tenantsBoxName)) {
      throw Exception('Tenants box is not open. Call init() first.');
    }
    return _boxes[tenantsBoxName]!;
  }

  Box<dynamic> get tenantsPendingBox {
    if (!_boxes.containsKey(tenantsPendingBoxName)) {
      throw Exception('Tenants pending box is not open. Call init() first.');
    }
    return _boxes[tenantsPendingBoxName]!;
  }

  // Service getters
  Box<dynamic> get servicesBox {
    if (!_boxes.containsKey(servicesBoxName)) {
      throw Exception('Services box is not open. Call init() first.');
    }
    return _boxes[servicesBoxName]!;
  }

  Box<dynamic> get servicesPendingBox {
    if (!_boxes.containsKey(servicesPendingBoxName)) {
      throw Exception('Services pending box is not open. Call init() first.');
    }
    return _boxes[servicesPendingBoxName]!;
  }

  // Receipt getters
  Box<dynamic> get receiptsBox {
    if (!_boxes.containsKey(receiptsBoxName)) {
      throw Exception('Receipts box is not open. Call init() first.');
    }
    return _boxes[receiptsBoxName]!;
  }

  Box<dynamic> get receiptsPendingBox {
    if (!_boxes.containsKey(receiptsPendingBoxName)) {
      throw Exception('Receipts pending box is not open. Call init() first.');
    }
    return _boxes[receiptsPendingBoxName]!;
  }

  // Report getters
  Box<dynamic> get reportsBox {
    if (!_boxes.containsKey(reportsBoxName)) {
      throw Exception('Reports box is not open. Call init() first.');
    }
    return _boxes[reportsBoxName]!;
  }

  Box<dynamic> get reportsPendingBox {
    if (!_boxes.containsKey(reportsPendingBoxName)) {
      throw Exception('Reports pending box is not open. Call init() first.');
    }
    return _boxes[reportsPendingBoxName]!;
  }

  // Notification getter
  Box<dynamic> get notificationsBox {
    if (!_boxes.containsKey(notificationsBoxName)) {
      throw Exception('Notifications box is not open. Call init() first.');
    }
    return _boxes[notificationsBoxName]!;
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
      _boxes.clear();
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
      _boxes.clear();
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
