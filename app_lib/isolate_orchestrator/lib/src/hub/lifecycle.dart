import 'dart:async';

/// Restart policy configuration.
class RestartPolicy {
  /// Maximum number of restart attempts.
  final int maxAttempts;

  /// Initial delay before first restart.
  final Duration initialDelay;

  /// Maximum delay between restarts.
  final Duration maxDelay;

  /// Multiplier for exponential backoff.
  final double multiplier;

  const RestartPolicy({
    this.maxAttempts = 10,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 60),
    this.multiplier = 2.0,
  });

  /// Calculate delay for given attempt number.
  Duration delayForAttempt(int attempt) {
    if (attempt <= 0) return initialDelay;

    final delayMs = initialDelay.inMilliseconds * _pow(multiplier, attempt - 1);
    final cappedMs = delayMs.clamp(0, maxDelay.inMilliseconds);
    return Duration(milliseconds: cappedMs.toInt());
  }

  /// Check if more attempts are allowed.
  bool canRetry(int currentAttempts) => currentAttempts < maxAttempts;

  static double _pow(double base, int exp) {
    var result = 1.0;
    for (var i = 0; i < exp; i++) {
      result *= base;
    }
    return result;
  }
}

/// Tracks restart state for an isolate.
class RestartTracker {
  final RestartPolicy policy;
  final String isolateId;

  int _attempts = 0;
  DateTime? _lastAttempt;
  Timer? _pendingRestart;

  RestartTracker({required this.policy, required this.isolateId});

  /// Get current attempt count.
  int get attempts => _attempts;

  /// Check if can retry.
  bool get canRetry => policy.canRetry(_attempts);

  /// Schedule next restart attempt.
  ///
  /// Returns a Future that completes when the delay is over,
  /// or null if max attempts reached.
  Future<void>? scheduleRestart(void Function() onRestart) {
    if (!canRetry) return null;

    _attempts++;
    _lastAttempt = DateTime.now();

    final delay = policy.delayForAttempt(_attempts);
    final completer = Completer<void>();

    _pendingRestart = Timer(delay, () {
      _pendingRestart = null;
      onRestart();
      completer.complete();
    });

    return completer.future;
  }

  /// Cancel pending restart.
  void cancel() {
    _pendingRestart?.cancel();
    _pendingRestart = null;
  }

  /// Reset attempts on successful recovery.
  void reset() {
    _attempts = 0;
    _lastAttempt = null;
    cancel();
  }

  /// Get time until next restart attempt.
  Duration? get timeUntilRestart {
    if (_pendingRestart == null || _lastAttempt == null) return null;
    final delay = policy.delayForAttempt(_attempts);
    final elapsed = DateTime.now().difference(_lastAttempt!);
    final remaining = delay - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }
}

/// Manages lifecycle state transitions.
class LifecycleManager {
  final Map<String, RestartTracker> _trackers = {};
  final RestartPolicy defaultPolicy;

  LifecycleManager({RestartPolicy? policy})
    : defaultPolicy = policy ?? const RestartPolicy();

  /// Get or create tracker for isolate.
  RestartTracker getTracker(String isolateId, {RestartPolicy? policy}) {
    return _trackers.putIfAbsent(
      isolateId,
      () =>
          RestartTracker(policy: policy ?? defaultPolicy, isolateId: isolateId),
    );
  }

  /// Remove tracker for isolate.
  void removeTracker(String isolateId) {
    final tracker = _trackers.remove(isolateId);
    tracker?.cancel();
  }

  /// Transfer tracker state from an old isolate ID to a newly respawned isolate ID.
  void transferTracker(String fromIsolateId, String toIsolateId) {
    final tracker = _trackers.remove(fromIsolateId);
    if (tracker != null) {
      _trackers[toIsolateId] = tracker;
    }
  }

  /// Reset tracker on successful recovery.
  void resetTracker(String isolateId) {
    _trackers[isolateId]?.reset();
  }

  /// Cancel all pending restarts.
  void cancelAll() {
    for (final tracker in _trackers.values) {
      tracker.cancel();
    }
  }

  /// Clear all trackers.
  void clear() {
    cancelAll();
    _trackers.clear();
  }
}
