import 'dart:async';
import 'dart:isolate';

import '../hub/hub.dart';
import '../message/envelope.dart';
import '../message/id_generator.dart';
import '../message/protocol.dart';
import '../request/manager.dart';
import 'router.dart';

/// Pool configuration.
class WorkerPoolConfig {
  final int minWorkers;
  final int maxWorkers;
  final Duration requestTimeout;
  final int maxRetries;
  final Map<String, dynamic>? workerConfig;

  const WorkerPoolConfig({
    this.minWorkers = 2,
    this.maxWorkers = 8,
    this.requestTimeout = const Duration(seconds: 5),
    this.maxRetries = 2,
    this.workerConfig,
  });
}

/// Pool status.
class PoolStatus {
  final int totalWorkers;
  final int healthyWorkers;
  final int pendingRequests;
  final int processedRequests;
  final int failedRequests;

  const PoolStatus({
    required this.totalWorkers,
    required this.healthyWorkers,
    required this.pendingRequests,
    required this.processedRequests,
    required this.failedRequests,
  });
}

/// Pool events.
sealed class PoolEvent {}

class WorkerAdded extends PoolEvent {
  final IsolateHandle worker;
  WorkerAdded(this.worker);
}

class WorkerRemoved extends PoolEvent {
  final String workerId;
  WorkerRemoved(this.workerId);
}

class WorkerHealthChanged extends PoolEvent {
  final String workerId;
  final bool healthy;
  WorkerHealthChanged(this.workerId, this.healthy);
}

class RequestTimeout extends PoolEvent {
  final String requestId;
  RequestTimeout(this.requestId);
}

class PoolScaled extends PoolEvent {
  final int oldSize;
  final int newSize;
  PoolScaled(this.oldSize, this.newSize);
}

/// Managed pool of worker isolates.
abstract class WorkerPool<TData> {
  /// Create a worker pool.
  factory WorkerPool({
    required IsolateHub hub,
    required WorkerPoolConfig config,
    required void Function(SendPort) workerEntryPoint,
    Router<TData>? router,
  }) => WorkerPoolImpl<TData>(
    hub: hub,
    config: config,
    workerEntryPoint: workerEntryPoint,
    router: router,
  );

  /// Pool configuration.
  WorkerPoolConfig get config;

  /// Current pool status.
  PoolStatus get status;

  /// Start the pool.
  Future<void> start();

  /// Stop the pool.
  Future<void> stop({Duration? timeout});

  /// Submit task to pool.
  /// Router determines which worker handles it.
  /// Returns TaskResult.data on success, throws on TaskError.
  Future<TData> submit(
    TData data, {
    String? taskType,
    Map<String, dynamic>? metadata,
    Duration? timeout,
  });

  /// Submit task and get full result (including metadata).
  Future<TaskResult<TData>> submitTask(Task<TData> task, {Duration? timeout});

  /// Submit batch of tasks.
  Future<TaskBatchResult<TData>> submitBatch(
    List<TData> dataList, {
    String? taskType,
    Duration? timeout,
  });

  /// Get all worker handles.
  List<IsolateHandle> get workers;

  /// Stream of pool events.
  Stream<PoolEvent> get events;
}

/// Implementation of WorkerPool.
class WorkerPoolImpl<TData> implements WorkerPool<TData> {
  @override
  final WorkerPoolConfig config;

  final IsolateHub hub;
  final void Function(SendPort) workerEntryPoint;
  final Router<TData> router;
  final MessageIdGenerator _idGenerator = MessageIdGenerator('pool');
  final StreamController<PoolEvent> _eventController =
      StreamController<PoolEvent>.broadcast();

  late final RequestManager<TData> _requestManager;
  final List<IsolateHandle> _workers = [];
  final ReceivePort _replyPort = ReceivePort();

  int _workerCounter = 0;
  int _processedCount = 0;
  int _failedCount = 0;
  bool _started = false;
  StreamSubscription? _hubSubscription;

  WorkerPoolImpl({
    required this.hub,
    required this.config,
    required this.workerEntryPoint,
    Router<TData>? router,
  }) : router = router ?? RoundRobinRouter<TData>() {
    _requestManager = RequestManager<TData>(
      defaultTimeout: config.requestTimeout,
      maxRetries: config.maxRetries,
      router: this.router,
      idGenerator: _idGenerator,
      replyPort: _replyPort.sendPort,
    );
  }

  @override
  Stream<PoolEvent> get events => _eventController.stream;

  @override
  List<IsolateHandle> get workers => List.unmodifiable(_workers);

  @override
  PoolStatus get status => PoolStatus(
    totalWorkers: _workers.length,
    healthyWorkers: _workers.where((w) => w.isHealthy).length,
    pendingRequests: _requestManager.pendingCount,
    processedRequests: _processedCount,
    failedRequests: _failedCount,
  );

  @override
  Future<void> start() async {
    if (_started) throw StateError('Pool already started');
    _started = true;

    // Listen for replies
    _replyPort.listen(_handleReply);

    // Listen for hub events
    _hubSubscription = hub.events.listen(_handleHubEvent);

    // Spawn initial workers
    for (var i = 0; i < config.minWorkers; i++) {
      await _spawnWorker();
    }

    // Update router with workers
    _updateRouter();
  }

  @override
  Future<void> stop({Duration? timeout}) async {
    if (!_started) return;

    // Cancel pending requests
    _requestManager.cancelAll();

    // Stop listening to hub events
    await _hubSubscription?.cancel();

    // Kill all workers
    for (final worker in _workers.toList()) {
      await worker.kill(graceful: true);
      _workers.remove(worker);
      _eventController.add(WorkerRemoved(worker.id));
    }

    _replyPort.close();
    await _eventController.close();

    _started = false;
  }

  Future<void> _spawnWorker() async {
    _workerCounter++;
    final name = 'worker-$_workerCounter';

    final worker = await hub.spawn(
      role: 'worker',
      name: name,
      entryPoint: workerEntryPoint,
      config: config.workerConfig,
      subscribesTo: [],
    );

    _workers.add(worker);
    _eventController.add(WorkerAdded(worker));
    _updateRouter();
  }

  void _updateRouter() {
    final ports = _workers
        .map((w) => PortInfo(id: w.id, port: w.sendPort, capabilities: []))
        .toList();
    router.updateWorkers(ports);
  }

  void _handleReply(dynamic message) {
    if (message is! Envelope) return;
    _requestManager.handleResponse(message);
  }

  void _handleHubEvent(HubEvent event) {
    switch (event) {
      case HealthChanged healthChanged:
        if (_workers.any((w) => w.id == healthChanged.id)) {
          _eventController.add(
            WorkerHealthChanged(healthChanged.id, healthChanged.healthy),
          );
        }
      case IsolateStopped stopped:
        _workers.removeWhere((w) => w.id == stopped.id);
        _eventController.add(WorkerRemoved(stopped.id));
        _updateRouter();

        // Ensure minimum workers
        if (_workers.length < config.minWorkers) {
          _spawnWorker();
        }
      default:
        break;
    }
  }

  @override
  Future<TData> submit(
    TData data, {
    String? taskType,
    Map<String, dynamic>? metadata,
    Duration? timeout,
  }) async {
    final task = Task<TData>(
      data: data,
      taskType: taskType,
      metadata: metadata,
    );

    final result = await submitTask(task, timeout: timeout);
    return result.data;
  }

  @override
  Future<TaskResult<TData>> submitTask(
    Task<TData> task, {
    Duration? timeout,
  }) async {
    if (!_started) throw StateError('Pool not started');

    try {
      final result = await _requestManager.submit(task, timeout: timeout);
      _processedCount++;
      return result;
    } on TaskError catch (e) {
      _failedCount++;
      throw TaskException(e.code, e.message, e.details);
    } on TimeoutException {
      _failedCount++;
      _eventController.add(RequestTimeout(_idGenerator.next()));
      rethrow;
    }
  }

  @override
  Future<TaskBatchResult<TData>> submitBatch(
    List<TData> dataList, {
    String? taskType,
    Duration? timeout,
  }) async {
    // Process all tasks concurrently for better throughput
    final futures = dataList.map((data) async {
      try {
        final result = await submit(data, taskType: taskType, timeout: timeout);
        return TaskSuccess<TData>(result);
      } on TaskException catch (e) {
        return TaskFailure<TData>(
          TaskError(code: e.code, message: e.message, details: e.details),
        );
      } on TimeoutException {
        return TaskFailure<TData>(
          TaskError(code: 'TIMEOUT', message: 'Task timed out'),
        );
      } catch (e) {
        // Handle any other unexpected exceptions
        return TaskFailure<TData>(
          TaskError(code: 'UNEXPECTED_ERROR', message: e.toString()),
        );
      }
    });

    final results = await Future.wait(futures);
    return TaskBatchResult<TData>(results.toList());
  }
}

/// Exception thrown when a task fails.
class TaskException implements Exception {
  final String code;
  final String message;
  final dynamic details;

  TaskException(this.code, this.message, [this.details]);

  @override
  String toString() => 'TaskException($code): $message';
}
