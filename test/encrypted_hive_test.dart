import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:joul_v2/core/services/encrypted_hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('encrypted_hive_test');
    Hive.init(dir.path);
    FlutterSecureStorage.setMockInitialValues({});
    EncryptedHive.resetForTest();
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  Future<void> restart() async {
    await Hive.close();
    EncryptedHive.resetForTest();
    await EncryptedHive.init(['tenants']);
  }

  test('plain data is moved into an encrypted box', () async {
    final plain = await Hive.openBox<dynamic>('tenants');
    await plain.put('t1', {'name': 'Dara', 'phoneNumber': '012345678'});
    await Hive.close();

    await EncryptedHive.init(['tenants']);
    final box = await EncryptedHive.open('tenants');

    expect(box.name, 'tenants_e');
    expect(box.get('t1'), {'name': 'Dara', 'phoneNumber': '012345678'});
    expect(await Hive.boxExists('tenants'), isFalse);
  });

  test('the file on disk no longer contains the plain text', () async {
    await EncryptedHive.init(['tenants']);
    final box = await EncryptedHive.open('tenants');
    await box.put('t1', {'phoneNumber': '099887766'});
    await Hive.close();

    final bytes = await File('${dir.path}/tenants_e.hive').readAsBytes();
    expect(String.fromCharCodes(bytes).contains('099887766'), isFalse);
  });

  test('data survives a restart with the same key', () async {
    await EncryptedHive.init(['tenants']);
    await (await EncryptedHive.open('tenants')).put('t1', 'Dara');

    await restart();
    final box = await EncryptedHive.open('tenants');

    expect(box.get('t1'), 'Dara');
  });

  test('an interrupted copy runs again from the plain box', () async {
    final plain = await Hive.openBox<dynamic>('tenants');
    await plain.put('t1', 'Dara');
    await Hive.close();
    // A partial encrypted copy without the "done" mark.
    await EncryptedHive.init(['tenants']);
    await Hive.openBox<dynamic>('tenants_e');
    await Hive.close();

    EncryptedHive.resetForTest();
    await EncryptedHive.init(['tenants']);
    final box = await EncryptedHive.open('tenants');

    expect(box.get('t1'), 'Dara');
  });

  test('a lost key starts empty instead of reading garbage', () async {
    await EncryptedHive.init(['tenants']);
    await (await EncryptedHive.open('tenants')).put('t1', 'Dara');
    await Hive.close();

    FlutterSecureStorage.setMockInitialValues({});
    EncryptedHive.resetForTest();
    await EncryptedHive.init(['tenants']);
    final box = await EncryptedHive.open('tenants');

    expect(box.isEmpty, isTrue);
  });
}
