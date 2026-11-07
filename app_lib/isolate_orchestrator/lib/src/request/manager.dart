import 'dart:async';
import 'dart:isolate';

import '../exception.dart';
import '../message/address.dart';
import '../message/envelope.dart';
import '../message/id_generator.dart';
import '../message/protocol.dart';
import '../pool/router.dart';
import 'registry.dart';
import 'timer_wheel.dart';

/// Manages task lifecycle with timeout handling.
class RequestManager<TData> {
  final Duration defaultTimeout;
  final int maxRetries;
  final Router<TData> router;
  final MessageIdGenerator idGenerator;
  final SendPort replyPort;

  final PendingRequestRegistry<TData> _registry = PendingRequestRegistry();
  final TimerWheel _timerWheel;

  RequestManager({
    required this.defaultTimeout,
    required this.maxRetries,
    required this.router,
    required this.idGenerator,
    required this.replyPort,
    Duration tickDuration = const Duration(milliseconds: 100),
    int wheelSize = 64,
  }) : _timerWheel = TimerWheel(
         tickDuration: tickDuration,
         wheelSize: wheelSize,
       ) {
    _timerWheel.start(_handleTimeout);
  }

  /// Get pending task count.
  int get pendingCount => _registry.count;

  /// Submit task and wait for result.
  Future<TaskResult<TData>> submit(
    Task<TData> task, {
    Duration? timeout,
  }) async {
    final effectiveTimeout = timeout ?? defaultTimeout;

    // Select worker
    final worker = router.select(task.data);
    if (worker == null) {
      throw NoHealthyWorkerException();
    }

    // Create pending task
    final id = idGenerator.next();
    final correlationId = idGenerator.next();
    final timerBucket = _timerWheel.add(id, effectiveTimeout);

    final completer = Completer<TaskResult<TData>>();
    final pending = PendingTask<TData>(
      id: id,
      correlationId: correlationId,
      task: task,
      completer: completer,
      replyPort: replyPort,
      sentTo: worker.id,
      sentAt: DateTime.now().microsecondsSinceEpoch,
      timerBucket: timerBucket,
    );

    _registry.register(pending);

    // Send task
    final envelope = Envelope.create(
      id: id,
      correlationId: correlationId,
      source: IsolateAddress.of('pool', 'pool'),
      target: IsolateAddress.of('worker', worker.id),
      replyTo: replyPort,
      payload: task,
    );
    worker.port.send(envelope);

    // Wait for result
    try {
      return await completer.future;
    } finally {
      // Clean up timer
      _timerWheel.remove(id, pending.timerBucket);
    }
  }

  /// Handle incoming response.
  void handleResponse(Envelope envelope) {
    final correlationId = envelope.correlationId;
    if (correlationId == null) return;

    final pending = _registry.removeByCorrelation(correlationId);
    if (pending == null) return;

    // Remove from timer
    _timerWheel.remove(pending.id, pending.timerBucket);

    final payload = envelope.payload;

    if (payload is TaskResult) {
      // Record success - cast to TaskResult<TData> after matching
      // (generic type info is lost after SendPort transfer)
      router.recordSuccess(pending.sentTo, pending.elapsed);
      pending.completer.complete(
        TaskResult<TData>(
          data: payload.data as TData,
          metadata: payload.metadata,
        ),
      );
    } else if (payload is TaskError) {
      // Record failure but don't retry for errors
      router.recordFailure(pending.sentTo);
      pending.completer.completeError(payload);
    } else {
      // Unknown response type
      pending.completer.completeError(
        TaskError(
          code: 'INVALID_RESPONSE',
          message: 'Unknown response type: ${payload.runtimeType}',
        ),
      );
    }
  }

  void _handleTimeout(String taskId) {
    final pending = _registry.getById(taskId);
    if (pending == null) return;

    // Record failure
    router.recordFailure(pending.sentTo);

    // Check if can retry
    if (pending.canRetry(maxRetries)) {
      _retryTask(pending);
    } else {
      // Max retries exceeded
      _registry.remove(taskId);
      pending.completer.completeError(
        TaskTimeoutException(taskId, pending.retryCount),
      );
    }
  }

  void _retryTask(PendingTask<TData> pending) {
    // Select new worker, excluding tried ones
    final worker = router.select(
      pending.task.data,
      exclude: pending.triedWorkers,
    );

    if (worker == null) {
      // No available worker
      _registry.remove(pending.id);
      pending.completer.completeError(NoHealthyWorkerException());
      return;
    }

    // Remove from old timer bucket before adding to new one
    final oldTimerBucket = pending.timerBucket;
    _timerWheel.remove(pending.id, oldTimerBucket);

    // Update pending task with new timer bucket
    final newTimerBucket = _timerWheel.add(pending.id, defaultTimeout);
    pending.recordRetry(worker.id, newTimerBucket);

    // Resend task
    final envelope = Envelope.create(
      id: pending.id,
      correlationId: pending.correlationId,
      source: IsolateAddress.of('pool', 'pool'),
      target: IsolateAddress.of('worker', worker.id),
      replyTo: replyPort,
      payload: pending.task,
    );
    worker.port.send(envelope);
  }

  /// Cancel a pending task.
  void cancel(String taskId) {
    final pending = _registry.remove(taskId);
    if (pending != null) {
      _timerWheel.remove(taskId, pending.timerBucket);
      pending.completer.completeError(TaskCancelledException(taskId));
    }
  }

  /// Cancel all pending tasks.
  void cancelAll() {
    for (final id in _registry.allIds.toList()) {
      cancel(id);
    }
    _timerWheel.stop();
  }

  /// Dispose the request manager.
  void dispose() {
    cancelAll();
    _timerWheel.clear();
  }
}
