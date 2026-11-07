import 'dart:async';
import 'dart:isolate';

import '../message/protocol.dart';

/// Tracks in-flight task.
class PendingTask<TData> {
  final String id;
  final String correlationId;
  final Task<TData> task;
  final Completer<TaskResult<TData>> completer;
  final SendPort replyPort;

  String sentTo;
  int sentAt;
  int retryCount;
  Set<String> triedWorkers;
  int timerBucket;

  PendingTask({
    required this.id,
    required this.correlationId,
    required this.task,
    required this.completer,
    required this.replyPort,
    required this.sentTo,
    required this.sentAt,
    required this.timerBucket,
    this.retryCount = 0,
    Set<String>? triedWorkers,
  }) : triedWorkers = triedWorkers ?? {};

  /// Check if task can be retried.
  bool canRetry(int maxRetries) => retryCount < maxRetries;

  /// Record a retry attempt.
  void recordRetry(String workerId, int newTimerBucket) {
    retryCount++;
    triedWorkers.add(sentTo);
    sentTo = workerId;
    sentAt = DateTime.now().microsecondsSinceEpoch;
    timerBucket = newTimerBucket;
  }

  /// Get elapsed time since sent.
  Duration get elapsed =>
      Duration(microseconds: DateTime.now().microsecondsSinceEpoch - sentAt);
}

/// Registry for pending requests.
class PendingRequestRegistry<TData> {
  final Map<String, PendingTask<TData>> _byId = {};
  final Map<String, PendingTask<TData>> _byCorrelation = {};

  /// Register a new pending task.
  void register(PendingTask<TData> task) {
    _byId[task.id] = task;
    _byCorrelation[task.correlationId] = task;
  }

  /// Get task by ID.
  PendingTask<TData>? getById(String id) => _byId[id];

  /// Get task by correlation ID.
  PendingTask<TData>? getByCorrelation(String correlationId) =>
      _byCorrelation[correlationId];

  /// Remove and return task by ID.
  PendingTask<TData>? remove(String id) {
    final task = _byId.remove(id);
    if (task != null) {
      _byCorrelation.remove(task.correlationId);
    }
    return task;
  }

  /// Remove and return task by correlation ID.
  PendingTask<TData>? removeByCorrelation(String correlationId) {
    final task = _byCorrelation.remove(correlationId);
    if (task != null) {
      _byId.remove(task.id);
    }
    return task;
  }

  /// Get count of pending tasks.
  int get count => _byId.length;

  /// Check if registry is empty.
  bool get isEmpty => _byId.isEmpty;

  /// Get all pending task IDs.
  Iterable<String> get allIds => _byId.keys;

  /// Get all pending tasks.
  Iterable<PendingTask<TData>> get all => _byId.values;

  /// Clear all pending tasks.
  void clear() {
    _byId.clear();
    _byCorrelation.clear();
  }

  /// Complete all pending tasks with error.
  void completeAllWithError(Object error) {
    for (final task in _byId.values.toList()) {
      if (!task.completer.isCompleted) {
        task.completer.completeError(error);
      }
    }
    clear();
  }
}
