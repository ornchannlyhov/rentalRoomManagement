import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:joul_v2/core/helpers/api_helper.dart';
import 'package:joul_v2/core/helpers/repository_manager.dart';
import 'package:joul_v2/core/sync/outbox.dart';
import 'package:joul_v2/core/sync/outbox_pusher.dart';

enum SyncPhase { idle, syncing, offline, sessionExpired, error }

/// What the sync engine is doing, for banners and the sync status screen.
@immutable
class SyncState {
  const SyncState({
    this.phase = SyncPhase.idle,
    this.pendingCount = 0,
    this.failedCount = 0,
    this.lastSyncAt,
    this.lastError,
  });

  final SyncPhase phase;
  final int pendingCount;
  final int failedCount;
  final DateTime? lastSyncAt;
  final String? lastError;

  SyncState copyWith({
    SyncPhase? phase,
    int? pendingCount,
    int? failedCount,
    DateTime? lastSyncAt,
    String? lastError,
    bool clearError = false,
  }) {
    return SyncState(
      phase: phase ?? this.phase,
      pendingCount: pendingCount ?? this.pendingCount,
      failedCount: failedCount ?? this.failedCount,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastError: clearError ? null : lastError ?? this.lastError,
    );
  }
}

/// The only thing that talks to the API on behalf of queued changes.
///
/// One run at a time: upload waiting changes in order, then download every
/// data type and merge it with local changes that are still waiting.
/// Runs on start, when the app resumes, when the backend becomes reachable,
/// shortly after a change is queued, and every 15 minutes.
class SyncEngine with WidgetsBindingObserver {
  SyncEngine({
    required Outbox outbox,
    required RepositoryManager repositoryManager,
    OutboxPusher? pusher,
    ApiHelper? apiHelper,
  })  : _outbox = outbox,
        _repositoryManager = repositoryManager,
        _pusher = pusher ?? OutboxPusher(outbox),
        _api = apiHelper ?? ApiHelper.instance;

  final Outbox _outbox;
  final RepositoryManager _repositoryManager;
  final OutboxPusher _pusher;
  final ApiHelper _api;

  static const Duration _debounce = Duration(seconds: 2);
  static const Duration _interval = Duration(minutes: 15);

  final ValueNotifier<SyncState> state = ValueNotifier(const SyncState());
  final StreamController<void> _dataChanged =
      StreamController<void>.broadcast();

  Future<bool>? _running;
  bool _rerun = false;
  bool _started = false;
  int _seenAdded = 0;
  Timer? _debounceTimer;
  Timer? _periodic;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  /// Fires after a download changed local data, so screens can reload.
  Stream<void> get onDataChanged => _dataChanged.stream;

  void start() {
    if (_started) return;
    _started = true;
    _seenAdded = _outbox.addedCount;
    _updateCounts();

    _subscriptions
      ..add(_outbox.changes.listen((_) {
        _updateCounts();
        // Only new changes need a run; the engine's own progress also fires.
        if (_outbox.addedCount == _seenAdded) return;
        _seenAdded = _outbox.addedCount;
        if (_running != null) {
          _rerun = true;
        } else {
          requestSync();
        }
      }))
      ..add(_api.onNetworkStatusChanged.listen((online) {
        if (online) {
          unawaited(_outbox.clearBackoff());
          requestSync(immediate: true);
        } else {
          _setPhase(SyncPhase.offline);
        }
      }));

    _periodic = Timer.periodic(_interval, (_) => requestSync());
    WidgetsBinding.instance.addObserver(this);
    requestSync(immediate: true);
  }

  void stop() {
    if (!_started) return;
    _started = false;
    _debounceTimer?.cancel();
    _periodic?.cancel();
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) requestSync(immediate: true);
  }

  /// Asks for a sync soon. Several requests close together become one run.
  void requestSync({bool immediate = false}) {
    _debounceTimer?.cancel();
    if (immediate) {
      unawaited(syncNow());
    } else {
      _debounceTimer = Timer(_debounce, () => unawaited(syncNow()));
    }
  }

  /// Uploads waiting changes, then downloads fresh data. If a run is
  /// already going, one more run follows it. Returns false when the sync
  /// couldn't finish (offline, signed out, or a download failed).
  Future<bool> syncNow() {
    final current = _running;
    if (current != null) {
      _rerun = true;
      return current;
    }
    final run = _runLoop();
    _running = run;
    return run.whenComplete(() => _running = null);
  }

  Future<bool> _runLoop() async {
    bool ok;
    do {
      _rerun = false;
      ok = await _runOnce();
    } while (_rerun);
    return ok;
  }

  Future<bool> _runOnce() async {
    final token = await _api.storage.read(key: 'auth_token');
    if (token == null || token.isEmpty) {
      _setPhase(SyncPhase.idle);
      return false;
    }

    if (!await _api.hasNetwork()) {
      _setPhase(SyncPhase.offline);
      return false;
    }

    _setPhase(SyncPhase.syncing);
    try {
      final outcome = await _pusher.pushAll();
      if (outcome == PushOutcome.unauthorized) {
        _setPhase(SyncPhase.sessionExpired);
        return false;
      }

      final pulled = await _repositoryManager.pullAll();
      _dataChanged.add(null);

      state.value = state.value.copyWith(
        phase: pulled ? SyncPhase.idle : SyncPhase.error,
        lastSyncAt: pulled ? DateTime.now() : null,
        lastError: pulled ? null : 'Some data could not be downloaded',
        clearError: pulled,
      );
      _updateCounts();
      return pulled && outcome == PushOutcome.done;
    } catch (e) {
      if (kDebugMode) print('❌ Sync run failed: $e');
      state.value = state.value.copyWith(
        phase: SyncPhase.error,
        lastError: e.toString(),
      );
      return false;
    }
  }

  /// Tries once to upload everything and returns how many changes are
  /// still not on the server (waiting or failed).
  Future<int> uploadBeforeSignOut() async {
    if (_outbox.totalCount == 0) return 0;
    await _outbox.clearBackoff();
    await syncNow();
    return _outbox.totalCount;
  }

  Future<void> retry(String opId) async {
    await _outbox.retry(opId);
    requestSync(immediate: true);
  }

  Future<void> retryAllFailed() async {
    await _outbox.retryAllFailed();
    requestSync(immediate: true);
  }

  Future<void> discard(String opId) async {
    await _outbox.discard(opId);
    // Download again so the discarded change disappears from screens.
    requestSync(immediate: true);
  }

  void _updateCounts() {
    state.value = state.value.copyWith(
      pendingCount: _outbox.pendingCount,
      failedCount: _outbox.failedCount,
    );
  }

  void _setPhase(SyncPhase phase) {
    state.value = state.value.copyWith(phase: phase);
    _updateCounts();
  }
}
