import 'package:flutter_test/flutter_test.dart';
import 'package:joul_v2/core/sync/storage_settings.dart';

void main() {
  final now = DateTime(2026, 9, 28, 14, 30);

  test('3 months keeps from the start of the month 3 months back', () {
    expect(StorageSettings.cutoffFor(3, null, now), DateTime(2026, 6, 1));
  });

  test('a window reaching into last year counts back across January', () {
    expect(StorageSettings.cutoffFor(12, null, now), DateTime(2025, 9, 1));
    expect(StorageSettings.cutoffFor(3, null, DateTime(2026, 2, 10)),
        DateTime(2025, 11, 1));
  });

  test('keeping everything has no cutoff', () {
    expect(StorageSettings.cutoffFor(0, null, now), isNull);
  });

  test('"remove all history" wins when it is later than the window', () {
    expect(StorageSettings.cutoffFor(12, DateTime(2026, 9, 1), now),
        DateTime(2026, 9, 1));
  });

  test('the window wins when it is later than an old removal date', () {
    expect(StorageSettings.cutoffFor(3, DateTime(2025, 1, 1), now),
        DateTime(2026, 6, 1));
  });

  test('the current month is never removed', () {
    expect(StorageSettings.cutoffFor(0, DateTime(2026, 9, 20), now),
        DateTime(2026, 9, 1));
  });
}
