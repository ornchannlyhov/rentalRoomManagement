import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Opens Hive boxes encrypted with a key kept in secure storage (Keychain
/// on iOS, Keystore-backed storage on Android). Tenant names and phone
/// numbers are no longer stored in plain text.
///
/// Encrypted boxes are stored under `<name>_e`. Data from the older plain
/// boxes is copied in on first open, and the plain box is deleted only
/// after the copy is recorded as complete, so an interrupted upgrade just
/// runs again.
class EncryptedHive {
  EncryptedHive._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _keyName = 'hive_encryption_key';
  static const String _migratedPrefix = 'hive_encrypted_';

  static HiveAesCipher? _cipher;

  static String physicalName(String name) => '${name}_e';

  /// Forgets the loaded key, as if the app restarted.
  @visibleForTesting
  static void resetForTest() => _cipher = null;

  /// Loads the key, or creates one. If the key is gone (for example the
  /// app's secure storage was reset) boxes encrypted with it can't be read,
  /// so they are deleted and the data is downloaded again.
  static Future<void> init(List<String> boxNames) async {
    if (_cipher != null) return;

    String? encoded;
    try {
      encoded = await _storage.read(key: _keyName);
    } catch (e) {
      if (kDebugMode) print('Could not read the storage key: $e');
      encoded = null;
    }

    if (encoded != null) {
      try {
        _cipher = HiveAesCipher(base64Url.decode(encoded));
        return;
      } catch (e) {
        if (kDebugMode) print('Stored key is invalid, creating a new one: $e');
      }
    }

    for (final name in boxNames) {
      final encrypted = physicalName(name);
      if (await Hive.boxExists(encrypted)) {
        await Hive.deleteBoxFromDisk(encrypted);
      }
      await _deleteFlag(name);
    }

    final key = Hive.generateSecureKey();
    await _storage.write(key: _keyName, value: base64UrlEncode(key));
    _cipher = HiveAesCipher(key);
  }

  static Future<Box<dynamic>> open(String name) async {
    final cipher = _cipher;
    if (cipher == null) {
      throw StateError('EncryptedHive.init() has not been called');
    }

    final encrypted = physicalName(name);
    if (Hive.isBoxOpen(encrypted)) return Hive.box<dynamic>(encrypted);

    final migrated = await _isMigrated(name);
    if (!migrated && await Hive.boxExists(name)) {
      // Left over from an interrupted copy: start the copy again.
      if (await Hive.boxExists(encrypted)) {
        await Hive.deleteBoxFromDisk(encrypted);
      }
      final plain = Hive.isBoxOpen(name)
          ? Hive.box<dynamic>(name)
          : await Hive.openBox<dynamic>(name);
      final box =
          await Hive.openBox<dynamic>(encrypted, encryptionCipher: cipher);
      await box.putAll(plain.toMap());
      await box.flush();
      await _setFlag(name);
      await plain.deleteFromDisk();
      if (kDebugMode) print('🔒 Encrypted $name (${box.length} entries)');
      return box;
    }

    // Copied earlier but the plain copy wasn't deleted: remove it now.
    if (migrated && await Hive.boxExists(name)) {
      await Hive.deleteBoxFromDisk(name);
    }

    final box =
        await Hive.openBox<dynamic>(encrypted, encryptionCipher: cipher);
    if (!migrated) await _setFlag(name);
    return box;
  }

  static Future<bool> _isMigrated(String name) async {
    try {
      return await _storage.read(key: '$_migratedPrefix$name') == '1';
    } catch (_) {
      return false;
    }
  }

  static Future<void> _setFlag(String name) =>
      _storage.write(key: '$_migratedPrefix$name', value: '1');

  static Future<void> _deleteFlag(String name) async {
    try {
      await _storage.delete(key: '$_migratedPrefix$name');
    } catch (_) {}
  }
}
