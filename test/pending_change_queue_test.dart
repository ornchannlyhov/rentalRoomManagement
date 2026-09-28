import 'package:flutter_test/flutter_test.dart';
import 'package:joul_v2/core/helpers/pending_change_queue.dart';

void main() {
  late List<Map<String, dynamic>> queue;

  setUp(() => queue = []);

  void add(String type, String endpoint, Map<String, dynamic> data,
      {bool singleton = false, String? filePath}) {
    PendingChangeQueue.add(
      queue,
      type: type,
      endpoint: endpoint,
      data: data,
      singleton: singleton,
      filePath: filePath,
      fileFieldName: filePath != null ? 'buildingImage' : null,
    );
  }

  group('updates', () {
    test('a second update to the same record is kept, not dropped', () {
      add('update', '/buildings/b1', {'id': 'b1', 'name': 'A', 'rentPrice': 1});
      add('update', '/buildings/b1', {'id': 'b1', 'name': 'B', 'rentPrice': 1});

      expect(queue, hasLength(2));
      expect(queue.last['data'], {'id': 'b1', 'name': 'B', 'rentPrice': 1});
    });

    test('updates are replayed in order, so a cleared field stays cleared', () {
      add('update', '/tenants/t1', {'name': 'T', 'roomId': 'r1'});
      add('update', '/tenants/t1', {'name': 'T'});

      expect(queue.map((c) => c['data']), [
        {'name': 'T', 'roomId': 'r1'},
        {'name': 'T'},
      ]);
    });

    test('an exact repeat of the last update is skipped', () {
      add('update', '/rooms/r1', {'price': 10});
      add('update', '/rooms/r1', {'price': 10});

      expect(queue, hasLength(1));
    });

    test('a repeat with a new image is kept', () {
      add('update', '/buildings/b1', {'id': 'b1'});
      add('update', '/buildings/b1', {'id': 'b1'}, filePath: '/new.jpg');

      expect(queue, hasLength(2));
    });

    test('returning to an earlier value is kept', () {
      add('update', '/rooms/r1', {'price': 10});
      add('update', '/rooms/r1', {'price': 20});
      add('update', '/rooms/r1', {'price': 10});

      expect(queue.map((c) => c['data']['price']), [10, 20, 10]);
    });
  });

  group('records created offline', () {
    test('an update is folded into the waiting create', () {
      add('create', '/buildings', {'name': 'A', 'localId': 'b1'});
      add('update', '/buildings/b1', {'id': 'b1', 'name': 'B', 'waterPrice': 2});

      expect(queue, hasLength(1));
      expect(queue.single['type'], 'create');
      expect(queue.single['endpoint'], '/buildings');
      expect(queue.single['data'],
          {'name': 'B', 'localId': 'b1', 'waterPrice': 2});
    });

    test('a new image on the update replaces the one on the create', () {
      add('create', '/buildings', {'localId': 'b1'}, filePath: '/old.jpg');
      add('update', '/buildings/b1', {'id': 'b1'}, filePath: '/new.jpg');

      expect(queue.single['filePath'], '/new.jpg');
      expect(queue.single['fileFieldName'], 'buildingImage');
    });

    test('create then delete removes both', () {
      add('create', '/tenants', {'name': 'T', 'localId': 't1'});
      add('delete', '/tenants/t1', {'id': 't1'});

      expect(queue, isEmpty);
    });

    test('create then delete also drops separately queued edits', () {
      add('create', '/reports', {'localId': 'p1'});
      queue.add({
        'type': 'update',
        'endpoint': '/reports/p1/status',
        'data': {'status': 'resolved'},
      });
      add('delete', '/reports/p1', {'id': 'p1'});

      expect(queue, isEmpty);
    });

    test('a repeated create with the same localId is merged', () {
      add('create', '/rooms', {'roomNumber': '1', 'localId': 'r1'});
      add('create', '/rooms', {'roomNumber': '2', 'localId': 'r1'});

      expect(queue, hasLength(1));
      expect(queue.single['data']['roomNumber'], '2');
    });

    test('creates with different localIds stay separate', () {
      add('create', '/rooms', {'roomNumber': '1', 'localId': 'r1'});
      add('create', '/rooms', {'roomNumber': '1', 'localId': 'r2'});

      expect(queue, hasLength(2));
    });
  });

  group('deletes', () {
    test('update then delete leaves only the delete', () {
      add('update', '/services/s1', {'name': 'Water'});
      add('delete', '/services/s1', {'id': 's1'});

      expect(queue, hasLength(1));
      expect(queue.single['type'], 'delete');
    });

    test('deleting twice queues one delete', () {
      add('delete', '/receipts/c1', {'id': 'c1'});
      add('delete', '/receipts/c1', {'id': 'c1'});

      expect(queue, hasLength(1));
    });

    test('deleting a record keeps changes for other records', () {
      add('update', '/services/s2', {'name': 'Trash'});
      add('delete', '/services/s1', {'id': 's1'});

      expect(queue.map((c) => c['endpoint']),
          ['/services/s2', '/services/s1']);
    });
  });

  group('singleton resource', () {
    test('an update is folded into a waiting create on the same endpoint', () {
      add('create', '/landlord/payment-config', {'bankName': 'ABA'},
          singleton: true);
      add('update', '/landlord/payment-config', {'bankAccountNumber': '123'},
          singleton: true);

      expect(queue, hasLength(1));
      expect(queue.single['type'], 'create');
      expect(queue.single['data'],
          {'bankName': 'ABA', 'bankAccountNumber': '123'});
    });

    test('two updates are both kept', () {
      add('update', '/landlord/payment-config', {'bankName': 'ABA'},
          singleton: true);
      add('update', '/landlord/payment-config', {'bankName': 'ACLEDA'},
          singleton: true);

      expect(queue.map((c) => c['data']['bankName']), ['ABA', 'ACLEDA']);
    });
  });

  test('maps read back from Hive with dynamic keys are merged safely', () {
    queue.add({
      'type': 'create',
      'endpoint': '/rooms',
      'data': <dynamic, dynamic>{'price': 10, 'localId': 'r1'},
    });
    add('update', '/rooms/r1', {'roomNumber': '2'});

    expect(queue.single['data'],
        {'price': 10, 'localId': 'r1', 'roomNumber': '2'});
  });
}
