import 'dart:async';
import 'dart:collection';
import 'dart:isolate';

import '../exception.dart';
import '../hub/hub.dart';
import '../hub/registry.dart';
import '../hub/supervisor.dart';
import '../message/address.dart';
import '../message/envelope.dart';
import '../message/id_generator.dart';
import '../message/protocol.dart';
import '../request/manager.dart';
import 'router.dart';

export '../exception.dart'
    show
        CheckoutTimeoutException,
        LeaseInvalidatedException,
        PoolFullException,
        TaskException;

/// Checkout strategy for [WorkerPool] / [IsolatePool] (modeled after Erlang `poolboy`).
enum PoolStrategy {
  /// Last-in, first-out (default in `poolboy`).
  ///
  /// Reuses the most recently returned worker, keeping hot workers active and
  /// allowing idle overflow workers to expire naturally.
  lifo,

  /// First-in, first-out.
  ///
  /// Distributes checkouts evenly across all available workers.
  fifo,
}

/// Pool configuration.
class WorkerPoolConfig {
  final int minWorkers;
  final int maxWorkers;

  /// Base number of permanent workers (`poolboy` `size` parameter).
  ///
  /// Defaults to [minWorkers] when omitted.
  final int? size;

  /// Maximum number of temporary overflow workers created under burst load
  /// (`poolboy` `max_overflow` parameter).
  ///
  /// Defaults to `maxWorkers - baseSize` when omitted.
  final int? maxOverflow;

  /// Worker checkout ordering strategy (`lifo` or `fifo`).
  final PoolStrategy strategy;

  /// Time after which an idle overflow worker is automatically dismissed.
  ///
  /// Set to [Duration.zero] to dismiss overflow workers immediately upon `checkin`
  /// when no callers are waiting.
  final Duration idleTimeout;

  final Duration requestTimeout;
  final int maxRetries;
  final Map<String, dynamic>? workerConfig;

  const WorkerPoolConfig({
    this.minWorkers = 2,
    this.maxWorkers = 8,
    this.size,
    this.maxOverflow,
    this.strategy = PoolStrategy.lifo,
    this.idleTimeout = const Duration(seconds: 30),
    this.requestTimeout = const Duration(seconds: 5),
    this.maxRetries = 2,
    this.workerConfig,
  });

  /// Effective base worker count (`size ?? minWorkers`).
  int get baseSize => size ?? minWorkers;

  /// Effective maximum overflow worker count.
  int get effectiveMaxOverflow =>
      maxOverflow ?? (maxWorkers > baseSize ? maxWorkers - baseSize : 0);

  /// Maximum total concurrent workers (`baseSize + effectiveMaxOverflow`).
  int get maxTotalWorkers => baseSize + effectiveMaxOverflow;
}

/// Alias for [WorkerPoolConfig].
typedef IsolatePoolConfig = WorkerPoolConfig;

/// Pool status.
class PoolStatus {
  final int totalWorkers;
  final int healthyWorkers;
  final int pendingRequests;
  final int processedRequests;
  final int failedRequests;
  final int availableWorkers;
  final int checkedOutWorkers;
  final int overflowWorkers;
  final int waitingCount;

  const PoolStatus({
    required this.totalWorkers,
    required this.healthyWorkers,
    required this.pendingRequests,
    required this.processedRequests,
    required this.failedRequests,
    this.availableWorkers = 0,
    this.checkedOutWorkers = 0,
    this.overflowWorkers = 0,
    this.waitingCount = 0,
  });
}

/// Exclusive lease handle for a checked-out worker from a [WorkerPool] / [IsolatePool].
class PoolWorker<TData> {
  final IsolateHandle _handle;
  final WorkerPoolImpl<TData> _pool;

  /// Whether this worker is a temporary burst overflow worker.
  final bool isOverflow;

  bool _released = false;

  PoolWorker._({
    required IsolateHandle handle,
    required WorkerPoolImpl<TData> pool,
    required this.isOverflow,
  }) : _handle = handle,
       _pool = pool;

  /// Underlying isolate ID.
  String get id => _handle.id;

  /// Underlying isolate name.
  String get name => _handle.name;

  /// Direct [SendPort] of the leased worker isolate.
  SendPort get sendPort => _handle.sendPort;

  /// Underlying [IsolateHandle].
  IsolateHandle get handle => _handle;

  /// Whether this lease is still active and the underlying isolate is running.
  bool get isValid => !_released && _handle.state == IsolateState.running;

  void _markReleased() {
    _released = true;
  }

  void _ensureValid() {
    if (_released) {
      throw LeaseInvalidatedException(id, 'Worker has already been checked in');
    }
    if (_handle.state != IsolateState.running) {
      throw LeaseInvalidatedException(
        id,
        'Underlying isolate is in state ${_handle.state.name}',
      );
    }
  }

  /// Execute a task directly on this leased worker.
  Future<TData> execute(
    TData data, {
    String? taskType,
    Map<String, dynamic>? metadata,
    Duration? timeout,
  }) async {
    final result = await executeTask(
      Task<TData>(data: data, taskType: taskType, metadata: metadata),
      timeout: timeout,
    );
    return result.data;
  }

  /// Execute a [Task] directly on this leased worker and return the full [TaskResult].
  Future<TaskResult<TData>> executeTask(
    Task<TData> task, {
    Duration? timeout,
  }) async {
    _ensureValid();
    return _pool._executeDirect(this, task, timeout: timeout);
  }

  /// Perform a direct RPC `call` on this leased worker.
  Future<TRes> call<TRes>(
    Object? request, {
    Duration? timeout,
    Map<String, dynamic>? metadata,
  }) {
    _ensureValid();
    return _handle.call<TRes>(request, timeout: timeout, metadata: metadata);
  }

  /// Send a direct fire-and-forget `cast` message to this leased worker.
  void cast(Object? message, {Map<String, dynamic>? metadata}) {
    _ensureValid();
    _handle.cast(message, metadata: metadata);
  }
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

/// Managed pool of worker isolates supporting both routed task submission
/// and Erlang `poolboy`-style exclusive worker checkout/checkin.
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

  /// Check out an exclusive [PoolWorker] from the pool (`poolboy:checkout/3`).
  ///
  /// - If an idle worker is available, returns it immediately according to [WorkerPoolConfig.strategy] (`lifo` or `fifo`).
  /// - If no idle worker is available and active overflow workers are below [WorkerPoolConfig.effectiveMaxOverflow],
  ///   dynamically spawns a temporary overflow worker.
  /// - If the pool is at maximum capacity (`baseSize + effectiveMaxOverflow`):
  ///   - When `block == false`, throws [PoolFullException] immediately.
  ///   - When `block == true`, waits in a FIFO queue until a worker is checked in or [timeout] expires
  ///     (throwing [CheckoutTimeoutException]).
  Future<PoolWorker<TData>> checkout({bool block = true, Duration? timeout});

  /// Non-blocking attempt to check out an available [PoolWorker].
  ///
  /// Returns `null` if the pool is full instead of throwing [PoolFullException].
  Future<PoolWorker<TData>?> tryCheckout();

  /// Return a checked-out [PoolWorker] back to the pool (`poolboy:checkin/2`).
  ///
  /// Safe and idempotent to call multiple times.
  Future<void> checkin(PoolWorker<TData> worker);

  /// Check out a [PoolWorker], execute [action], and guarantee [checkin] in a `finally` block
  /// (`poolboy:transaction/3`).
  Future<R> transaction<R>(
    Future<R> Function(PoolWorker<TData> worker) action, {
    bool block = true,
    Duration? timeout,
  });

  /// Get all worker handles.
  List<IsolateHandle> get workers;

  /// Scale the pool to [targetWorkers], clamped between [WorkerPoolConfig.baseSize]
  /// and [WorkerPoolConfig.maxTotalWorkers].
  Future<void> scale(int targetWorkers);

  /// Stream of pool events.
  Stream<PoolEvent> get events;
}

/// Alias for [WorkerPool] (`poolboy`-style isolate pool).
typedef IsolatePool<TData> = WorkerPool<TData>;

class _CheckoutWaiter<TData> {
  final Completer<PoolWorker<TData>> completer = Completer<PoolWorker<TData>>();
  Timer? timer;

  void cancelTimer() {
    timer?.cancel();
    timer = null;
  }
}

class _DirectPendingRequest<TData> {
  final String requestId;
  final String workerId;
  final Completer<TaskResult<TData>> completer;
  final Timer timer;

  _DirectPendingRequest({
    required this.requestId,
    required this.workerId,
    required this.completer,
    required this.timer,
  });
}

/// Implementation of [WorkerPool].
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
  final Set<String> _managedWorkerNames = {};
  final Set<String> _restartingWorkerIds = {};
  final ReceivePort _replyPort = ReceivePort();

  /// Poolboy state: available idle workers, checked-out leases, overflow tracking, and wait queue.
  final List<IsolateHandle> _availableWorkers = [];
  final Map<String, PoolWorker<TData>> _checkedOutLeases = {};
  final Set<String> _overflowWorkerIds = {};
  final Set<String> _overflowWorkerNames = {};
  final Map<String, Timer> _idleTimers = {};
  final Queue<_CheckoutWaiter<TData>> _waitQueue =
      Queue<_CheckoutWaiter<TData>>();
  final Map<String, _DirectPendingRequest<TData>> _directPendingRequests = {};
  int _spawningOverflowCount = 0;

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
    pendingRequests:
        _requestManager.pendingCount + _directPendingRequests.length,
    processedRequests: _processedCount,
    failedRequests: _failedCount,
    availableWorkers: _availableWorkers.length,
    checkedOutWorkers: _checkedOutLeases.length,
    overflowWorkers: _overflowWorkerIds.length,
    waitingCount: _waitQueue.length,
  );

  @override
  Future<void> start() async {
    if (_started) throw StateError('Pool already started');
    _started = true;

    // Listen for replies
    _replyPort.listen(_handleReply);

    // Listen for hub events
    _hubSubscription = hub.events.listen(_handleHubEvent);

    // Spawn initial base workers
    for (var i = 0; i < config.baseSize; i++) {
      await _spawnWorker(isOverflow: false, forCheckout: false);
    }

    // Update router with workers
    _updateRouter();
  }

  @override
  Future<void> stop({Duration? timeout}) async {
    if (!_started) return;
    _started = false;

    // Stop listening to hub events first so we don't respawn during shutdown
    await _hubSubscription?.cancel();
    _hubSubscription = null;

    // Cancel idle timers
    for (final timer in _idleTimers.values) {
      timer.cancel();
    }
    _idleTimers.clear();

    // Fail any waiting checkout callers
    while (_waitQueue.isNotEmpty) {
      final waiter = _waitQueue.removeFirst();
      waiter.cancelTimer();
      if (!waiter.completer.isCompleted) {
        waiter.completer.completeError(
          PoolStateException('Pool stopped while waiting for checkout'),
        );
      }
    }

    // Invalidate all active leases and fail direct pending requests
    for (final lease in _checkedOutLeases.values) {
      lease._markReleased();
    }
    _checkedOutLeases.clear();
    _availableWorkers.clear();

    for (final pending in _directPendingRequests.values) {
      pending.timer.cancel();
      if (!pending.completer.isCompleted) {
        pending.completer.completeError(
          PoolStateException('Pool stopped during task execution'),
        );
      }
    }
    _directPendingRequests.clear();

    // Cancel pending requests and stop timer wheel
    _requestManager.dispose();

    // Kill all workers
    for (final worker in _workers.toList()) {
      _managedWorkerNames.remove(worker.name);
      _overflowWorkerNames.remove(worker.name);
      _overflowWorkerIds.remove(worker.id);
      await worker.kill(graceful: true);
      _workers.remove(worker);
      if (!_eventController.isClosed) {
        _eventController.add(WorkerRemoved(worker.id));
      }
    }

    _restartingWorkerIds.clear();
    _replyPort.close();
    await _eventController.close();
  }

  @override
  Future<void> scale(int targetWorkers) async {
    if (!_started) throw StateError('Pool not started');

    final desired = targetWorkers.clamp(
      config.baseSize,
      config.maxTotalWorkers,
    );
    final oldSize = _workers.length;
    if (desired == oldSize) return;

    if (desired > oldSize) {
      final toAdd = desired - oldSize;
      for (var i = 0; i < toAdd; i++) {
        await _spawnWorker(isOverflow: false, forCheckout: false);
      }
    } else {
      final toRemove = oldSize - desired;
      for (var i = 0; i < toRemove && _workers.isNotEmpty; i++) {
        // Prefer removing idle workers first
        final worker = _availableWorkers.isNotEmpty
            ? _availableWorkers.removeLast()
            : _workers.last;
        _workers.remove(worker);
        _idleTimers.remove(worker.id)?.cancel();
        _checkedOutLeases.remove(worker.id)?._markReleased();
        _overflowWorkerIds.remove(worker.id);
        _overflowWorkerNames.remove(worker.name);
        _managedWorkerNames.remove(worker.name);
        await worker.kill(graceful: true);
        if (!_eventController.isClosed) {
          _eventController.add(WorkerRemoved(worker.id));
        }
      }
      _updateRouter();
    }

    if (!_eventController.isClosed) {
      _eventController.add(PoolScaled(oldSize, _workers.length));
    }
  }

  // ===========================================================================
  // Poolboy API: checkout, tryCheckout, checkin, transaction
  // ===========================================================================

  @override
  Future<PoolWorker<TData>> checkout({
    bool block = true,
    Duration? timeout,
  }) async {
    if (!_started) throw PoolStateException('Pool not started');

    // 1. Prune any dead handles from _availableWorkers
    _availableWorkers.removeWhere(
      (w) => w.state != IsolateState.running || !w.isHealthy,
    );

    // 2. If an idle worker is available, pop according to strategy (LIFO or FIFO)
    if (_availableWorkers.isNotEmpty) {
      final handle = switch (config.strategy) {
        PoolStrategy.lifo => _availableWorkers.removeLast(),
        PoolStrategy.fifo => _availableWorkers.removeAt(0),
      };
      _idleTimers.remove(handle.id)?.cancel();
      return _createLease(handle);
    }

    // 3. If overflow capacity is available, spawn a temporary burst worker
    if (_overflowWorkerIds.length + _spawningOverflowCount <
        config.effectiveMaxOverflow) {
      _spawningOverflowCount++;
      try {
        final handle = await _spawnWorker(isOverflow: true, forCheckout: true);
        return _createLease(handle);
      } finally {
        _spawningOverflowCount--;
      }
    }

    // 4. Pool is at full capacity (baseSize + effectiveMaxOverflow)
    if (!block) {
      throw PoolFullException(config.baseSize, config.effectiveMaxOverflow);
    }

    final waiter = _CheckoutWaiter<TData>();
    _waitQueue.addLast(waiter);

    if (timeout != null) {
      waiter.timer = Timer(timeout, () {
        _waitQueue.remove(waiter);
        if (!waiter.completer.isCompleted) {
          waiter.completer.completeError(CheckoutTimeoutException(timeout));
        }
      });
    }

    return waiter.completer.future;
  }

  @override
  Future<PoolWorker<TData>?> tryCheckout() async {
    try {
      return await checkout(block: false);
    } on PoolFullException {
      return null;
    }
  }

  @override
  Future<void> checkin(PoolWorker<TData> worker) async {
    if (worker._released) return;
    worker._markReleased();
    _checkedOutLeases.remove(worker.id);

    if (!_started) return;

    final handle = worker.handle;
    final stillAlive =
        _workers.any((w) => w.id == handle.id) &&
        handle.state == IsolateState.running &&
        handle.isHealthy;

    if (!stillAlive) {
      return;
    }

    _handOffOrMakeAvailable(handle);
  }

  @override
  Future<R> transaction<R>(
    Future<R> Function(PoolWorker<TData> worker) action, {
    bool block = true,
    Duration? timeout,
  }) async {
    final worker = await checkout(block: block, timeout: timeout);
    try {
      return await action(worker);
    } finally {
      await checkin(worker);
    }
  }

  PoolWorker<TData> _createLease(IsolateHandle handle) {
    final isOverflow = _overflowWorkerIds.contains(handle.id);
    final lease = PoolWorker<TData>._(
      handle: handle,
      pool: this,
      isOverflow: isOverflow,
    );
    _checkedOutLeases[handle.id] = lease;
    return lease;
  }

  void _handOffOrMakeAvailable(IsolateHandle handle) {
    if (!_started) return;

    // 1. Hand off directly to the next waiting caller in FIFO order
    while (_waitQueue.isNotEmpty) {
      final waiter = _waitQueue.removeFirst();
      waiter.cancelTimer();
      if (!waiter.completer.isCompleted) {
        final lease = _createLease(handle);
        waiter.completer.complete(lease);
        return;
      }
    }

    // 2. No callers waiting: handle overflow vs base worker
    final isOverflow = _overflowWorkerIds.contains(handle.id);
    if (isOverflow) {
      if (config.idleTimeout <= Duration.zero) {
        unawaited(_dismissOverflowWorker(handle));
        return;
      }
      if (!_availableWorkers.any((w) => w.id == handle.id)) {
        _availableWorkers.add(handle);
      }
      _idleTimers[handle.id]?.cancel();
      _idleTimers[handle.id] = Timer(
        config.idleTimeout,
        () => _onOverflowIdleTimeout(handle),
      );
    } else {
      if (!_availableWorkers.any((w) => w.id == handle.id)) {
        _availableWorkers.add(handle);
      }
    }
  }

  void _onOverflowIdleTimeout(IsolateHandle handle) {
    _idleTimers.remove(handle.id);
    if (!_started) return;
    // Only dismiss if it is still sitting idle in _availableWorkers
    if (_checkedOutLeases.containsKey(handle.id)) return;
    _availableWorkers.removeWhere((w) => w.id == handle.id);
    unawaited(_dismissOverflowWorker(handle));
  }

  Future<void> _dismissOverflowWorker(IsolateHandle handle) async {
    _idleTimers.remove(handle.id)?.cancel();
    _availableWorkers.removeWhere((w) => w.id == handle.id);
    _overflowWorkerIds.remove(handle.id);
    _overflowWorkerNames.remove(handle.name);
    _managedWorkerNames.remove(handle.name);
    _workers.removeWhere((w) => w.id == handle.id);
    _updateRouter();
    await handle.kill(graceful: true);
    if (!_eventController.isClosed) {
      _eventController.add(WorkerRemoved(handle.id));
    }
  }

  Future<TaskResult<TData>> _executeDirect(
    PoolWorker<TData> lease,
    Task<TData> task, {
    Duration? timeout,
  }) async {
    if (!_started) throw PoolStateException('Pool not started');

    final msgId = _idGenerator.next();
    final completer = Completer<TaskResult<TData>>();
    final effectiveTimeout = timeout ?? config.requestTimeout;

    final timer = Timer(effectiveTimeout, () {
      final pending = _directPendingRequests.remove(msgId);
      if (pending != null && !pending.completer.isCompleted) {
        _failedCount++;
        if (!_eventController.isClosed) {
          _eventController.add(RequestTimeout(msgId));
        }
        pending.completer.completeError(TaskTimeoutException(msgId, 0));
      }
    });

    _directPendingRequests[msgId] = _DirectPendingRequest<TData>(
      requestId: msgId,
      workerId: lease.id,
      completer: completer,
      timer: timer,
    );

    final envelope = Envelope<ProtocolMessage>(
      id: msgId,
      timestamp: DateTime.now().microsecondsSinceEpoch,
      correlationId: msgId,
      source: IsolateAddress.hub,
      target: IsolateAddress.of(lease.handle.role, lease.id),
      replyTo: _replyPort.sendPort,
      payload: task,
    );

    lease.sendPort.send(envelope);
    return completer.future;
  }

  // ===========================================================================
  // Worker Spawning & Event Handling
  // ===========================================================================

  Future<IsolateHandle> _spawnWorker({
    required bool isOverflow,
    required bool forCheckout,
  }) async {
    if (!_started) throw PoolStateException('Pool not started');
    _workerCounter++;
    final name = isOverflow
        ? 'worker-overflow-$_workerCounter'
        : 'worker-$_workerCounter';
    _managedWorkerNames.add(name);
    if (isOverflow) {
      _overflowWorkerNames.add(name);
    }

    try {
      final worker = await hub.spawn(
        role: 'worker',
        name: name,
        entryPoint: workerEntryPoint,
        config: config.workerConfig,
        subscribesTo: [],
        restartType: isOverflow
            ? ChildRestartType.temporary
            : ChildRestartType.permanent,
      );

      if (!_started) {
        await worker.kill(graceful: false);
        throw PoolStateException('Pool stopped during spawn');
      }

      if (isOverflow) {
        _overflowWorkerIds.add(worker.id);
      }

      if (!_workers.any((w) => w.id == worker.id)) {
        _workers.add(worker);
        if (!_eventController.isClosed) {
          _eventController.add(WorkerAdded(worker));
        }
        _updateRouter();
      }

      if (!forCheckout) {
        _handOffOrMakeAvailable(worker);
      }

      return worker;
    } catch (_) {
      _managedWorkerNames.remove(name);
      _overflowWorkerNames.remove(name);
      rethrow;
    }
  }

  void _updateRouter() {
    final ports = _workers
        .map((w) => PortInfo(id: w.id, port: w.sendPort, capabilities: []))
        .toList();
    router.updateWorkers(ports);
  }

  void _handleReply(dynamic message) {
    if (message is! Envelope) return;

    final corrId = message.correlationId ?? message.id;
    final directPending = _directPendingRequests.remove(corrId);
    if (directPending != null) {
      directPending.timer.cancel();
      if (directPending.completer.isCompleted) return;

      final payload = message.payload;
      if (payload is TaskResult) {
        _processedCount++;
        directPending.completer.complete(
          TaskResult<TData>(
            data: payload.data as TData,
            metadata: payload.metadata,
          ),
        );
      } else if (payload is TaskError) {
        _failedCount++;
        directPending.completer.completeError(
          TaskException(
            payload.code,
            payload.message,
            payload.details,
            payload.stackTrace,
          ),
        );
      }
      return;
    }

    _requestManager.handleResponse(message);
  }

  void _handleHubEvent(HubEvent event) {
    if (!_started) return;

    switch (event) {
      case HealthChanged healthChanged:
        if (_workers.any((w) => w.id == healthChanged.id)) {
          router.setWorkerHealth(healthChanged.id, healthChanged.healthy);
          if (!_eventController.isClosed) {
            _eventController.add(
              WorkerHealthChanged(healthChanged.id, healthChanged.healthy),
            );
          }
        }

      case IsolateRestarting restarting:
        if (_workers.any((w) => w.id == restarting.id)) {
          _restartingWorkerIds.add(restarting.id);
        }

      case IsolateReady ready:
        if (_managedWorkerNames.contains(ready.handle.name) &&
            !_workers.any((w) => w.id == ready.handle.id)) {
          final isOverflow = _overflowWorkerNames.contains(ready.handle.name);
          if (isOverflow) {
            _overflowWorkerIds.add(ready.handle.id);
          }
          _workers.add(ready.handle);
          if (!_eventController.isClosed) {
            _eventController.add(WorkerAdded(ready.handle));
          }
          _updateRouter();
          if (!_checkedOutLeases.containsKey(ready.handle.id)) {
            _handOffOrMakeAvailable(ready.handle);
          }
        }

      case IsolateStopped stopped:
        final wasManaged = _workers.any((w) => w.id == stopped.id);
        if (!wasManaged) return;

        final stoppedHandle = _workers.firstWhere((w) => w.id == stopped.id);
        final wasOverflow = _overflowWorkerIds.remove(stopped.id);
        if (wasOverflow) {
          _overflowWorkerNames.remove(stoppedHandle.name);
          _managedWorkerNames.remove(stoppedHandle.name);
        }

        _idleTimers.remove(stopped.id)?.cancel();
        _availableWorkers.removeWhere((w) => w.id == stopped.id);

        // Invalidate active lease if this worker crashed while checked out
        final activeLease = _checkedOutLeases.remove(stopped.id);
        if (activeLease != null) {
          activeLease._markReleased();
        }

        // Fail any in-flight direct requests targeting this stopped worker
        final failedReqIds = _directPendingRequests.entries
            .where((e) => e.value.workerId == stopped.id)
            .map((e) => e.key)
            .toList();
        for (final reqId in failedReqIds) {
          final pending = _directPendingRequests.remove(reqId);
          if (pending != null) {
            pending.timer.cancel();
            if (!pending.completer.isCompleted) {
              _failedCount++;
              pending.completer.completeError(
                LeaseInvalidatedException(
                  stopped.id,
                  'Worker isolate terminated during execution',
                ),
              );
            }
          }
        }

        _workers.removeWhere((w) => w.id == stopped.id);
        if (!_eventController.isClosed) {
          _eventController.add(WorkerRemoved(stopped.id));
        }
        _updateRouter();

        final isHubRestarting = _restartingWorkerIds.remove(stopped.id);

        if (wasOverflow) {
          // If callers are waiting in the queue and overflow capacity is now free,
          // spawn a replacement overflow worker for the waiting caller.
          if (_waitQueue.isNotEmpty &&
              _overflowWorkerIds.length + _spawningOverflowCount <
                  config.effectiveMaxOverflow) {
            _spawningOverflowCount++;
            unawaited(
              _spawnWorker(isOverflow: true, forCheckout: true)
                  .then((handle) {
                    _spawningOverflowCount--;
                    _handOffOrMakeAvailable(handle);
                  })
                  .catchError((Object e, StackTrace st) {
                    _spawningOverflowCount--;
                  }),
            );
          }
        } else {
          // Base worker: ensure minimum base workers if Hub is not already restarting it
          final currentBaseWorkers =
              _workers.length - _overflowWorkerIds.length;
          if (!isHubRestarting &&
              _started &&
              currentBaseWorkers < config.baseSize) {
            unawaited(
              _spawnWorker(
                isOverflow: false,
                forCheckout: false,
              ).catchError((_) => stoppedHandle),
            );
          }
        }

      default:
        break;
    }
  }

  // ===========================================================================
  // Stateless Routed Task Submission (submit, submitTask, submitBatch)
  // ===========================================================================

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
      throw TaskException(e.code, e.message, e.details, e.stackTrace);
    } on TaskTimeoutException catch (e) {
      _failedCount++;
      if (!_eventController.isClosed) {
        _eventController.add(RequestTimeout(e.taskId));
      }
      rethrow;
    } on TimeoutException {
      _failedCount++;
      if (!_eventController.isClosed) {
        _eventController.add(RequestTimeout('unknown'));
      }
      rethrow;
    }
  }

  @override
  Future<TaskBatchResult<TData>> submitBatch(
    List<TData> dataList, {
    String? taskType,
    Duration? timeout,
  }) async {
    if (!_started) throw StateError('Pool not started');

    if (dataList.isEmpty) {
      return TaskBatchResult<TData>([]);
    }

    // Submit all tasks concurrently using Future.wait
    final futures = dataList.map((data) async {
      try {
        final result = await submit(data, taskType: taskType, timeout: timeout);
        return TaskSuccess<TData>(result);
      } on TaskException catch (e) {
        return TaskFailure<TData>(
          TaskError(code: e.code, message: e.message, details: e.details),
        );
      } on TaskTimeoutException catch (e) {
        return TaskFailure<TData>(TaskError(code: 'TIMEOUT', message: '$e'));
      } on TimeoutException catch (e) {
        return TaskFailure<TData>(TaskError(code: 'TIMEOUT', message: '$e'));
      } catch (e, stackTrace) {
        return TaskFailure<TData>(
          TaskError(
            code: e.runtimeType.toString(),
            message: e.toString(),
            stackTrace: stackTrace.toString(),
          ),
        );
      }
    }).toList();

    final results = await Future.wait(futures);
    return TaskBatchResult<TData>(results);
  }
}
