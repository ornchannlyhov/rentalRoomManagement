import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:joul_v2/core/sync/outbox.dart';
import 'package:joul_v2/core/sync/outbox_pusher.dart';
import 'package:joul_v2/core/sync/pull_merge.dart';

void main() {
  late Directory dir;
  late Outbox outbox;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('outbox_test');
    Hive.init(dir.path);
    outbox = await Outbox.init();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    await dir.delete(recursive: true);
  });

  Future<void> create(
          String entity, String endpoint, Map<String, dynamic> data) =>
      outbox.enqueue(
          entity: entity, type: 'create', endpoint: endpoint, data: data);

  group('storing changes', () {
    test('changes keep their order after the app restarts', () async {
      await create('building', '/buildings', {'name': 'A', 'localId': 'b1'});
      await create('room', '/rooms', {'buildingId': 'b1', 'localId': 'r1'});
      await outbox.enqueue(
          entity: 'service',
          type: 'update',
          endpoint: '/services/s1',
          data: {'price': 2});

      await Hive.close();
      final reopened = await Outbox.init();

      expect(reopened.ops.map((op) => op['endpoint']),
          ['/buildings', '/rooms', '/services/s1']);
      expect(reopened.ops.map((op) => op['entity']),
          ['building', 'room', 'service']);
      expect(reopened.pendingCount, 3);
    });

    test('an edit to a record created offline joins its create', () async {
      await create('building', '/buildings', {'name': 'A', 'localId': 'b1'});
      await outbox.enqueue(
          entity: 'building',
          type: 'update',
          endpoint: '/buildings/b1',
          data: {'id': 'b1', 'name': 'B'});

      expect(outbox.ops, hasLength(1));
      expect(outbox.ops.single['data'], {'name': 'B', 'localId': 'b1'});
    });

    test('an edit made while its create is uploading is not lost', () async {
      await create('building', '/buildings', {'name': 'A', 'localId': 'b1'});
      final createId = outbox.ops.single['opId'] as String;
      outbox.markSending(createId);

      await outbox.enqueue(
          entity: 'building',
          type: 'update',
          endpoint: '/buildings/b1',
          data: {'id': 'b1', 'name': 'B'});
      await outbox.markDone(createId);
      await outbox.applyIdMapping('b1', 'srv-1');

      expect(outbox.ops.single['endpoint'], '/buildings/srv-1');
      expect(outbox.ops.single['data']['name'], 'B');
    });

    test('clear removes everything', () async {
      await create('building', '/buildings', {'localId': 'b1'});
      await outbox.clear();

      expect(outbox.totalCount, 0);
    });
  });

  group('sending order', () {
    test('the oldest change is sent first', () async {
      await create('building', '/buildings', {'localId': 'b1'});
      await create('room', '/rooms', {'localId': 'r1', 'buildingId': 'b1'});

      expect(outbox.nextReady(DateTime.now())!['endpoint'], '/buildings');
    });

    test('nothing is sent while the oldest change is backing off', () async {
      await create('building', '/buildings', {'localId': 'b1'});
      await create('service', '/services', {'localId': 's1'});
      await outbox.markRetry(outbox.ops.first['opId'] as String, 'timeout');

      expect(outbox.nextReady(DateTime.now()), isNull);
      expect(outbox.nextReady(DateTime.now().add(const Duration(minutes: 1))),
          isNotNull);
    });

    test('changes that need a failed create wait, others go ahead', () async {
      await create('building', '/buildings', {'localId': 'b1'});
      await create('room', '/rooms', {'localId': 'r1', 'buildingId': 'b1'});
      await create('service', '/services', {'localId': 's1', 'name': 'Water'});
      await outbox.markFailed(outbox.ops.first['opId'] as String, 'Invalid');

      final next = outbox.nextReady(DateTime.now())!;
      expect(next['endpoint'], '/services');
    });

    test('a later edit to a failed record waits for it', () async {
      await outbox.enqueue(
          entity: 'room',
          type: 'update',
          endpoint: '/rooms/r1',
          data: {'a': 1});
      await outbox.markFailed(outbox.ops.first['opId'] as String, 'Invalid');
      await outbox.enqueue(
          entity: 'room',
          type: 'update',
          endpoint: '/rooms/r1',
          data: {'a': 2});

      expect(outbox.ops, hasLength(2));
      expect(outbox.nextReady(DateTime.now()), isNull);
    });

    test('a delete replaces a failed edit to the same record', () async {
      await outbox.enqueue(
          entity: 'room',
          type: 'update',
          endpoint: '/rooms/r1',
          data: {'a': 1});
      await outbox.markFailed(outbox.ops.first['opId'] as String, 'Invalid');
      await outbox.enqueue(
          entity: 'room',
          type: 'delete',
          endpoint: '/rooms/r1',
          data: {'id': 'r1'});

      expect(outbox.failedCount, 0);
      expect(outbox.nextReady(DateTime.now())!['type'], 'delete');
    });

    test('retry makes a failed change ready again', () async {
      await create('building', '/buildings', {'localId': 'b1'});
      final opId = outbox.ops.first['opId'] as String;
      await outbox.markFailed(opId, 'Invalid');
      expect(outbox.nextReady(DateTime.now()), isNull);

      await outbox.retry(opId);
      expect(outbox.nextReady(DateTime.now())!['opId'], opId);
    });

    test('backoff grows and levels off at 30 minutes', () {
      expect(Outbox.backoffFor(1), const Duration(seconds: 5));
      expect(Outbox.backoffFor(4), const Duration(minutes: 10));
      expect(Outbox.backoffFor(9), const Duration(minutes: 30));
    });
  });

  group('server ids for records created offline', () {
    test('waiting changes are pointed at the server id', () async {
      await create('building', '/buildings', {'localId': 'b1'});
      await create('room', '/rooms', {'localId': 'r1', 'buildingId': 'b1'});
      await outbox.markDone(outbox.ops.first['opId'] as String);

      await outbox.applyIdMapping('b1', 'srv-9');

      expect(outbox.ops.single['data']['buildingId'], 'srv-9');
    });

    test('changes queued later use the server id too', () async {
      await outbox.applyIdMapping('b1', 'srv-9');
      await outbox.enqueue(
          entity: 'building',
          type: 'update',
          endpoint: '/buildings/b1',
          data: {'id': 'b1'});

      expect(outbox.ops.single['endpoint'], '/buildings/srv-9');
      expect(outbox.resolveId('b1'), 'srv-9');
    });
  });

  group('sending directly', () {
    test('allowed when nothing is waiting', () {
      expect(outbox.canSendDirectly('/buildings/b1', const {}), isTrue);
    });

    test('not allowed while anything is waiting', () async {
      await create('service', '/services', {'localId': 's1'});
      expect(outbox.canSendDirectly('/buildings/b1', const {}), isFalse);
    });

    test('not allowed for a record whose change failed', () async {
      await outbox.enqueue(
          entity: 'room',
          type: 'update',
          endpoint: '/rooms/r1',
          data: {'a': 1});
      await outbox.markFailed(outbox.ops.first['opId'] as String, 'Invalid');

      expect(outbox.canSendDirectly('/rooms/r1', const {}), isFalse);
      expect(outbox.canSendDirectly('/rooms/r2', const {}), isTrue);
    });
  });

  test('changes queued by older app versions are moved in, oldest first',
      () async {
    final rooms = await Hive.openBox<dynamic>('rooms_pending');
    final buildings = await Hive.openBox<dynamic>('buildings_pending');
    await rooms.put(0, {
      'type': 'create',
      'endpoint': '/rooms',
      'data': {'localId': 'r1', 'buildingId': 'b1'},
      'timestamp': '2025-12-01T10:00:02.000',
    });
    await buildings.put(0, {
      'type': 'create',
      'endpoint': '/buildings',
      'data': {'localId': 'b1'},
      'timestamp': '2025-12-01T10:00:01.000',
    });

    final moved =
        await outbox.importLegacy({'room': rooms, 'building': buildings});

    expect(moved, 2);
    expect(outbox.ops.map((op) => op['entity']), ['building', 'room']);
    expect(rooms.isEmpty && buildings.isEmpty, isTrue);
  });

  group('download merge', () {
    List<Map<String, String>> merge(List<Map<String, String>> server,
            List<Map<String, String>> local) =>
        mergePulled<Map<String, String>>(
          server: server,
          local: local,
          idOf: (item) => item['id']!,
          outbox: outbox,
        );

    test('server data replaces local data with nothing waiting', () {
      final result = merge([
        {'id': 'b1', 'name': 'server'}
      ], [
        {'id': 'b1', 'name': 'local'}
      ]);
      expect(result.single['name'], 'server');
    });

    test('a record with a waiting edit keeps the local version', () async {
      await outbox.enqueue(
          entity: 'building',
          type: 'update',
          endpoint: '/buildings/b1',
          data: {'name': 'local'});
      final result = merge([
        {'id': 'b1', 'name': 'server'}
      ], [
        {'id': 'b1', 'name': 'local'}
      ]);
      expect(result.single['name'], 'local');
    });

    test('a record created offline stays until the server has it', () async {
      await create('building', '/buildings', {'localId': 'new1'});
      final result = merge([
        {'id': 'b1', 'name': 'server'}
      ], [
        {'id': 'new1', 'name': 'offline'}
      ]);
      expect(result.map((r) => r['id']), ['b1', 'new1']);
    });

    test('a record with a waiting delete stays hidden', () async {
      await outbox.enqueue(
          entity: 'building',
          type: 'delete',
          endpoint: '/buildings/b1',
          data: {'id': 'b1'});
      final result = merge([
        {'id': 'b1'},
        {'id': 'b2'}
      ], []);
      expect(result.map((r) => r['id']), ['b2']);
    });

    test('a local record the server deleted goes away', () {
      final result = merge([], [
        {'id': 'b1'}
      ]);
      expect(result, isEmpty);
    });
  });

  group('server replies', () {
    SendResult classify(String type, int? status, [Object? body]) =>
        OutboxPusher.classify(type, status, body).result;

    test('success codes and already-done cases count as sent', () {
      expect(classify('update', 200), SendResult.success);
      expect(classify('create', 201), SendResult.success);
      expect(classify('create', 409), SendResult.success);
      expect(classify('delete', 404), SendResult.success);
    });

    test('a 404 on an update is a failure, not success', () {
      expect(classify('update', 404), SendResult.failed);
    });

    test('temporary problems are retried', () {
      expect(classify('update', null), SendResult.retry);
      expect(classify('update', 500), SendResult.retry);
      expect(classify('update', 503), SendResult.retry);
      expect(classify('update', 429), SendResult.retry);
      expect(classify('update', 408), SendResult.retry);
    });

    test('rejections are failed with the server message', () {
      final sent = OutboxPusher.classify(
          'create', 422, {'message': 'Room number already used'});
      expect(sent.result, SendResult.failed);
      expect(sent.error, 'Room number already used');
    });

    test('401 stops the run without failing the change', () {
      expect(classify('update', 401), SendResult.unauthorized);
    });
  });
}
