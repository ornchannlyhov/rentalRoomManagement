import 'package:hive_flutter/hive_flutter.dart';
import 'package:joul_v2/core/sync/outbox.dart';

/// Device settings for what stays on this phone, stored next to the outbox.
///
/// - Which account the local data belongs to, so a session that expires
///   keeps its waiting changes, and a different account starts clean.
/// - How much receipt history to keep. Older receipts stay on the server
///   and are not stored again after being removed.
class StorageSettings {
  StorageSettings(this._box);

  factory StorageSettings.fromHive() =>
      StorageSettings(Hive.box<dynamic>(Outbox.metaBoxName));

  final Box<dynamic> _box;

  static const String _ownerKey = 'ownerUserId';
  static const String _monthsKey = 'historyMonths';
  static const String _fromKey = 'historyFrom';

  /// Months of receipts kept on the phone. 0 keeps everything.
  static const int defaultHistoryMonths = 3;
  static const List<int> historyMonthOptions = [3, 6, 12, 0];

  String? get ownerUserId => _box.get(_ownerKey) as String?;

  Future<void> setOwner(String? userId) =>
      userId == null ? _box.delete(_ownerKey) : _box.put(_ownerKey, userId);

  int get historyMonths =>
      (_box.get(_monthsKey) as num?)?.toInt() ?? defaultHistoryMonths;

  /// Changing the window also forgets "remove all history", so choosing
  /// a longer window brings older receipts back on the next download.
  Future<void> setHistoryMonths(int months) async {
    await _box.put(_monthsKey, months);
    await _box.delete(_fromKey);
  }

  DateTime? get historyFrom =>
      DateTime.tryParse(_box.get(_fromKey) as String? ?? '');

  /// Keeps nothing before [from] (used by "remove all history").
  Future<void> setHistoryFrom(DateTime from) =>
      _box.put(_fromKey, from.toIso8601String());

  /// Receipts dated before this are not kept on the phone, or null to keep
  /// everything. Never later than the start of the current month, so the
  /// month being billed is always available.
  DateTime? historyCutoff([DateTime? now]) =>
      cutoffFor(historyMonths, historyFrom, now ?? DateTime.now());

  static DateTime? cutoffFor(int months, DateTime? from, DateTime now) {
    final monthStart = DateTime(now.year, now.month, 1);
    DateTime? cutoff =
        months > 0 ? DateTime(now.year, now.month - months, 1) : null;
    if (from != null && (cutoff == null || from.isAfter(cutoff))) {
      cutoff = from;
    }
    if (cutoff != null && cutoff.isAfter(monthStart)) cutoff = monthStart;
    return cutoff;
  }
}
