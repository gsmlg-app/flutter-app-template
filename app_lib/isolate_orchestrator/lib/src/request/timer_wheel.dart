import 'dart:async';

/// Efficient timeout management using timer wheel.
class TimerWheel {
  final Duration tickDuration;
  final int wheelSize;
  final List<Map<String, int>> _buckets;

  int _currentTick = 0;
  Timer? _timer;
  void Function(String)? _onTimeout;

  TimerWheel({
    this.tickDuration = const Duration(milliseconds: 100),
    this.wheelSize = 64,
  }) : _buckets = List.generate(wheelSize, (_) => {});

  /// Check if the timer wheel is running.
  bool get isRunning => _timer != null;

  /// Start the timer wheel.
  void start(void Function(String) onTimeout) {
    if (_timer != null) return;

    _onTimeout = onTimeout;
    _timer = Timer.periodic(tickDuration, (_) => _tick());
  }

  /// Stop the timer wheel.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _onTimeout = null;
  }

  void _tick() {
    final bucket = _buckets[_currentTick];
    if (bucket.isNotEmpty) {
      final entries = bucket.entries
          .toList(); // Copy to avoid concurrent modification

      for (final entry in entries) {
        if (entry.value <= 0) {
          bucket.remove(entry.key);
          _onTimeout?.call(entry.key);
        } else {
          final currentRounds = bucket[entry.key];
          if (currentRounds != null && currentRounds > 0) {
            bucket[entry.key] = currentRounds - 1;
          }
        }
      }
    }

    _currentTick = (_currentTick + 1) % wheelSize;
  }

  /// Add timeout for request.
  /// Returns bucket index for later removal.
  int add(String requestId, Duration timeout) {
    final ticks = timeout.inMilliseconds ~/ tickDuration.inMilliseconds;
    final effectiveTicks = ticks < 1 ? 1 : ticks;
    final rounds = effectiveTicks ~/ wheelSize;
    final bucket = (_currentTick + effectiveTicks) % wheelSize;
    _buckets[bucket][requestId] = rounds;
    return bucket;
  }

  /// Remove request from timeout tracking.
  void remove(String requestId, int bucket) {
    if (bucket >= 0 && bucket < wheelSize) {
      _buckets[bucket].remove(requestId);
    }
  }

  /// Remove request by searching all buckets.
  void removeById(String requestId) {
    for (final bucket in _buckets) {
      bucket.remove(requestId);
    }
  }

  /// Get total pending requests.
  int get pendingCount =>
      _buckets.fold(0, (sum, bucket) => sum + bucket.length);

  /// Clear all pending requests.
  void clear() {
    for (final bucket in _buckets) {
      bucket.clear();
    }
  }
}
