import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Keeps images attached to waiting changes in app storage until they are
/// uploaded. Image picker files live in a cache folder the OS may clear.
class OutboxFiles {
  OutboxFiles._();

  static const String _folderName = 'outbox_files';
  static Directory? _folder;

  static Future<Directory> _dir() async {
    final cached = _folder;
    if (cached != null) return cached;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_folderName');
    if (!await dir.exists()) await dir.create(recursive: true);
    return _folder = dir;
  }

  /// Returns a path inside app storage holding a copy of [path]. If the
  /// copy fails, the original path is returned so the change still queues.
  static Future<String> keep(String path) async {
    try {
      final dir = await _dir();
      if (path.startsWith(dir.path)) return path;
      final source = File(path);
      if (!await source.exists()) return path;
      final name = path.split(Platform.pathSeparator).last;
      final target = '${dir.path}/${const Uuid().v4()}_$name';
      await source.copy(target);
      return target;
    } catch (e) {
      if (kDebugMode) print('Could not keep outbox file $path: $e');
      return path;
    }
  }

  /// Deletes a copy made by [keep]. Files outside app storage are left alone.
  static Future<void> release(String path) async {
    try {
      final dir = await _dir();
      if (!path.startsWith(dir.path)) return;
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (e) {
      if (kDebugMode) print('Could not delete outbox file $path: $e');
    }
  }
}
