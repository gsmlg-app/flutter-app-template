# Isolate Orchestrator Package Design

## Overview

`isolate_orchestrator` is a generic Dart package that provides a managed pool of long-running isolates with:

- Centralized Hub for lifecycle management
- Type-safe message protocol
- Health monitoring and automatic restart
- Consistent hashing router
- Request-response correlation with timeout handling
- Cross-isolate logging with `logging` package integration

This package is **not** DNS-specific and can be used for any application requiring parallel processing with isolate pools.

**Package Name**: `isolate_orchestrator`  
**License**: MIT  
**Dependencies**: `logging` (for cross-isolate logging support)

---

## Package Structure

```
isolate_orchestrator/
├── lib/
│   ├── isolate_orchestrator.dart           # Main export
│   ├── src/
│   │   ├── hub/
│   │   │   ├── hub.dart            # IsolateHub implementation
│   │   │   ├── registry.dart       # Isolate registry
│   │   │   ├── spawner.dart        # Isolate spawner
│   │   │   └── lifecycle.dart      # Lifecycle manager
│   │   ├── message/
│   │   │   ├── envelope.dart       # Message envelope
│   │   │   ├── address.dart        # IsolateAddress
│   │   │   ├── protocol.dart       # Protocol messages
│   │   │   └── id_generator.dart   # Message ID generator
│   │   ├── pool/
│   │   │   ├── pool.dart           # WorkerPool implementation
│   │   │   ├── router.dart         # Consistent hash router
│   │   │   └── hash_ring.dart      # Hash ring implementation
│   │   ├── worker/
│   │   │   ├── worker.dart         # Worker base class
│   │   │   └── context.dart        # WorkerContext
│   │   ├── request/
│   │   │   ├── manager.dart        # RequestManager
│   │   │   ├── registry.dart       # PendingRequest registry
│   │   │   └── timer_wheel.dart    # Timer wheel for timeouts
│   │   ├── logging/
│   │   │   ├── bridge.dart         # IsolateLogBridge
│   │   │   ├── record.dart         # SerializableLogRecord
│   │   │   ├── central.dart        # Central logger isolate
│   │   │   └── output.dart         # Log output targets
│   │   └── health/
│   │       ├── monitor.dart        # Health monitor
│   │       └── metrics.dart        # IsolateMetrics
│   └── testing/
│       └── mock_worker.dart        # Testing utilities
├── test/
├── example/
│   ├── simple_pool.dart
│   └── custom_router.dart
├── pubspec.yaml
└── README.md
```

---

## Core Concepts

### Roles

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Isolate Roles                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  Hub (Main Isolate)                                                     │
│  ├── Spawns and manages all other isolates                              │
│  ├── Maintains registry of ports                                        │
│  ├── Broadcasts port updates                                            │
│  └── Health monitoring                                                  │
│                                                                         │
│  Worker                                                                 │
│  ├── Long-running processing isolate                                    │
│  ├── User-defined task handler                                          │
│  └── Reports health metrics                                             │
│                                                                         │
│  (User can define additional roles)                                     │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Communication Model

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    Communication Topology                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│                           Hub                                           │
│                            │                                            │
│            Control messages│(Init, Ping, Shutdown)                      │
│                            │                                            │
│         ┌──────────────────┼──────────────────┐                        │
│         ▼                  ▼                  ▼                        │
│     Worker 1           Worker 2           Worker 3                     │
│                                                                         │
│  ═══════════════════════════════════════════════════════════════════   │
│                                                                         │
│  Client code sends tasks directly to workers via SendPort               │
│  Workers respond directly via replyTo port                              │
│                                                                         │
│     Client ─────────────────────────────────────► Worker               │
│        ◄─────────────────────────────────────────                      │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Message Protocol

### IsolateAddress

```dart
/// Identifies an isolate in the system
class IsolateAddress {
  final String role;      // Role name (e.g., "worker", "logger")
  final String id;        // Instance ID (e.g., "worker-1")
  
  const IsolateAddress({required this.role, required this.id});
  
  /// Predefined addresses
  static const hub = IsolateAddress(role: 'hub', id: 'hub');
  static const broadcast = IsolateAddress(role: '*', id: '*');
  
  /// Create address for a role instance
  factory IsolateAddress.of(String role, String id) => 
    IsolateAddress(role: role, id: id);
}
```

### Envelope

```dart
/// Wrapper for all inter-isolate messages
class Envelope<T> {
  // Tracing
  final String id;              // Unique message ID
  final int timestamp;          // Microsecond timestamp
  final String? correlationId;  // For request-response matching
  
  // Routing
  final IsolateAddress source;
  final IsolateAddress target;
  final SendPort? replyTo;      // Direct reply port
  
  // Payload
  final T payload;
  
  // Metadata
  final int version;            // Protocol version (default: 1)
  final int flags;              // Option flags
  
  const Envelope({
    required this.id,
    required this.timestamp,
    this.correlationId,
    required this.source,
    required this.target,
    this.replyTo,
    required this.payload,
    this.version = 1,
    this.flags = 0,
  });
}

/// Envelope flags
abstract class EnvelopeFlags {
  static const int needsAck = 1 << 0;
  static const int isAck = 1 << 1;
  static const int priority = 1 << 2;
}
```

### Protocol Messages

```dart
/// Base class for all protocol messages
sealed class ProtocolMessage {}

// ═══════════════════════════════════════════════════════════════════
// Lifecycle Messages
// ═══════════════════════════════════════════════════════════════════

/// Child → Hub: Registration
class Register extends ProtocolMessage {
  final String name;
  final String role;
  final SendPort port;
  final List<String> capabilities;
  final List<String> subscribesTo;  // Roles this isolate needs ports for
}

/// Hub → Child: Initialization
class Init extends ProtocolMessage {
  final Map<String, dynamic> config;
  final Map<String, List<PortInfo>> dependencies;
}

/// Port information
class PortInfo {
  final String id;
  final SendPort port;
  final List<String> capabilities;
}

/// Child → Hub: Ready notification
class Ready extends ProtocolMessage {
  final bool success;
  final String? error;
  final Map<String, dynamic>? metadata;
}

/// Bidirectional: Shutdown command
class Shutdown extends ProtocolMessage {
  final bool graceful;
  final int timeoutMs;
  final String? reason;
}

/// Child → Hub: Shutdown acknowledgment
class ShutdownAck extends ProtocolMessage {
  final int pendingTasks;
  final bool flushed;
}

// ═══════════════════════════════════════════════════════════════════
// Health Messages
// ═══════════════════════════════════════════════════════════════════

/// Hub → Child: Health check
class Ping extends ProtocolMessage {
  final int seq;
}

/// Child → Hub: Health response
class Pong extends ProtocolMessage {
  final int seq;
  final IsolateMetrics metrics;
}

/// Isolate health metrics
class IsolateMetrics {
  final int uptimeMs;
  final int processedCount;
  final int pendingCount;
  final int errorCount;
  final int avgLatencyUs;
  final int? memoryBytes;
  final Map<String, dynamic>? custom;
}

// ═══════════════════════════════════════════════════════════════════
// Port Update Messages
// ═══════════════════════════════════════════════════════════════════

/// Hub → Subscribers: Port change notification
class PortUpdate extends ProtocolMessage {
  final int version;           // Monotonic version for ordering
  final String role;           // Which role's ports changed
  final List<PortInfo> added;
  final List<String> removed;  // Removed isolate IDs
}

/// Subscriber → Hub: Update acknowledgment
class PortUpdateAck extends ProtocolMessage {
  final int version;
}

// ═══════════════════════════════════════════════════════════════════
// Application Messages (Generic data passing)
// ═══════════════════════════════════════════════════════════════════

/// Generic task request wrapper
/// Use this to send application-specific requests to workers
class Task<T> extends ProtocolMessage {
  final T data;
  final String? taskType;         // Optional type discriminator
  final Map<String, dynamic>? metadata;
  
  Task({
    required this.data,
    this.taskType,
    this.metadata,
  });
}

/// Generic task result wrapper
/// Use this to send application-specific responses back
class TaskResult<T> extends ProtocolMessage {
  final T data;
  final Map<String, dynamic>? metadata;
  
  TaskResult({
    required this.data,
    this.metadata,
  });
}

/// Generic task error
/// Use this to send application-specific errors back
class TaskError extends ProtocolMessage {
  final String code;
  final String message;
  final dynamic details;          // Application-specific error details
  final String? stackTrace;
  
  TaskError({
    required this.code,
    required this.message,
    this.details,
    this.stackTrace,
  });
}

/// Batch of tasks for bulk processing
class TaskBatch<T> extends ProtocolMessage {
  final List<Task<T>> tasks;
  
  TaskBatch(this.tasks);
}

/// Batch results
class TaskBatchResult<T> extends ProtocolMessage {
  final List<TaskResultOrError<T>> results;
  
  TaskBatchResult(this.results);
}

/// Union type for result or error
sealed class TaskResultOrError<T> {}

class TaskSuccess<T> extends TaskResultOrError<T> {
  final T data;
  TaskSuccess(this.data);
}

class TaskFailure<T> extends TaskResultOrError<T> {
  final TaskError error;
  TaskFailure(this.error);
}
```

### Message ID Generator

```dart
/// Generates unique message IDs
class MessageIdGenerator {
  final String _prefix;
  int _lastMs = 0;
  int _seq = 0;
  
  MessageIdGenerator(this._prefix);
  
  /// Generate next ID
  /// Format: {prefix}-{timestamp_base36}-{sequence_hex}
  /// Example: "worker1-2xf8k9m-0042"
  String next() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs == _lastMs) {
      _seq = (_seq + 1) & 0xFFFF;
    } else {
      _lastMs = nowMs;
      _seq = 0;
    }
    return '$_prefix-${nowMs.toRadixString(36)}-${_seq.toRadixString(16).padLeft(4, '0')}';
  }
}
```

---

## Isolate Hub

### API

```dart
/// Central manager for all isolates
abstract class IsolateHub {
  /// Create a new hub
  factory IsolateHub({HubConfig? config}) => IsolateHubImpl(config: config);
  
  /// Hub configuration
  HubConfig get config;
  
  /// Current hub state
  HubState get state;
  
  /// Start the hub
  Future<void> start();
  
  /// Stop the hub and all managed isolates
  Future<void> stop({Duration? timeout});
  
  /// Spawn a new isolate with given role and entry point
  Future<IsolateHandle> spawn<T>({
    required String role,
    required String name,
    required void Function(SendPort) entryPoint,
    Map<String, dynamic>? config,
    List<String>? subscribesTo,
  });
  
  /// Get all isolates with given role
  List<IsolateHandle> getByRole(String role);
  
  /// Get isolate by ID
  IsolateHandle? getById(String id);
  
  /// Stream of hub events
  Stream<HubEvent> get events;
  
  /// Send message to specific isolate
  void send(String isolateId, ProtocolMessage message);
  
  /// Broadcast message to all isolates with role
  void broadcast(String role, ProtocolMessage message);
}

/// Hub configuration
class HubConfig {
  final Duration healthCheckInterval;
  final Duration healthCheckTimeout;
  final int unhealthyThreshold;
  final int healthyThreshold;
  final RestartPolicy restartPolicy;
  
  const HubConfig({
    this.healthCheckInterval = const Duration(seconds: 5),
    this.healthCheckTimeout = const Duration(seconds: 2),
    this.unhealthyThreshold = 3,
    this.healthyThreshold = 3,
    this.restartPolicy = const RestartPolicy(),
  });
}

/// Restart policy configuration
class RestartPolicy {
  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final double multiplier;
  
  const RestartPolicy({
    this.maxAttempts = 10,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 60),
    this.multiplier = 2.0,
  });
}

/// Handle to a managed isolate
abstract class IsolateHandle {
  String get id;
  String get name;
  String get role;
  IsolateState get state;
  SendPort get sendPort;
  IsolateMetrics? get lastMetrics;
  bool get isHealthy;
  
  /// Send message to this isolate
  void send(ProtocolMessage message);
  
  /// Kill this isolate
  Future<void> kill({bool graceful = true});
}

/// Hub states
enum HubState { created, starting, running, stopping, stopped }

/// Isolate states
enum IsolateState { created, starting, running, stopping, stopped, failed }

/// Hub events
sealed class HubEvent {}
class IsolateSpawned extends HubEvent { final IsolateHandle handle; }
class IsolateReady extends HubEvent { final IsolateHandle handle; }
class IsolateFailed extends HubEvent { final IsolateHandle handle; final String error; }
class IsolateStopped extends HubEvent { final String id; }
class IsolateRestarting extends HubEvent { final String id; final int attempt; }
class HealthChanged extends HubEvent { final String id; final bool healthy; }
```

### Registry

```dart
/// Registry of all managed isolates
class IsolateRegistry {
  final _isolates = <String, IsolateEntry>{};
  final _byRole = <String, Set<String>>{};
  
  /// Register new isolate
  void register(IsolateEntry entry) {
    _isolates[entry.id] = entry;
    _byRole.putIfAbsent(entry.role, () => {}).add(entry.id);
  }
  
  /// Unregister isolate
  void unregister(String id) {
    final entry = _isolates.remove(id);
    if (entry != null) {
      _byRole[entry.role]?.remove(id);
    }
  }
  
  /// Get by ID
  IsolateEntry? get(String id) => _isolates[id];
  
  /// Get all by role
  List<IsolateEntry> getByRole(String role) {
    return _byRole[role]?.map((id) => _isolates[id]!).toList() ?? [];
  }
  
  /// Get all ports for a role
  List<PortInfo> getPortsForRole(String role) {
    return getByRole(role)
      .where((e) => e.state == IsolateState.running)
      .map((e) => PortInfo(
        id: e.id,
        port: e.sendPort,
        capabilities: e.capabilities,
      ))
      .toList();
  }
}

/// Internal registry entry
class IsolateEntry {
  final String id;
  final String name;
  final String role;
  final Isolate isolate;
  final SendPort sendPort;
  final ReceivePort controlPort;
  final List<String> capabilities;
  final List<String> subscribesTo;
  
  IsolateState state = IsolateState.created;
  IsolateMetrics? lastMetrics;
  DateTime? lastHealthCheck;
  int restartCount = 0;
  int consecutiveFailures = 0;
  int consecutiveSuccesses = 0;
}
```

---

## Worker Pool

### API

```dart
/// Managed pool of worker isolates
/// TData: The application-specific data type workers process
abstract class WorkerPool<TData> {
  /// Create a worker pool
  factory WorkerPool({
    required IsolateHub hub,
    required WorkerPoolConfig config,
    required void Function(SendPort) workerEntryPoint,
    Router<TData>? router,
  }) => WorkerPoolImpl(
    hub: hub,
    config: config,
    workerEntryPoint: workerEntryPoint,
    router: router,
  );
  
  /// Pool configuration
  WorkerPoolConfig get config;
  
  /// Current pool status
  PoolStatus get status;
  
  /// Start the pool
  Future<void> start();
  
  /// Stop the pool
  Future<void> stop({Duration? timeout});
  
  /// Submit task to pool
  /// Router determines which worker handles it
  /// Returns TaskResult.data on success, throws on TaskError
  Future<TData> submit(
    TData data, {
    String? taskType,
    Map<String, dynamic>? metadata,
    Duration? timeout,
  });
  
  /// Submit task and get full result (including metadata)
  Future<TaskResult<TData>> submitTask(Task<TData> task, {Duration? timeout});
  
  /// Submit batch of tasks
  Future<TaskBatchResult<TData>> submitBatch(
    List<TData> dataList, {
    String? taskType,
    Duration? timeout,
  });
  
  /// Get all worker handles
  List<IsolateHandle> get workers;
  
  /// Stream of pool events
  Stream<PoolEvent> get events;
}

/// Pool configuration
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

/// Pool status
class PoolStatus {
  final int totalWorkers;
  final int healthyWorkers;
  final int pendingRequests;
  final int processedRequests;
  final int failedRequests;
}

/// Pool events
sealed class PoolEvent {}
class WorkerAdded extends PoolEvent { final IsolateHandle worker; }
class WorkerRemoved extends PoolEvent { final String workerId; }
class WorkerHealthChanged extends PoolEvent { final String workerId; final bool healthy; }
class RequestTimeout extends PoolEvent { final String requestId; }
class PoolScaled extends PoolEvent { final int oldSize; final int newSize; }
```

### Router

```dart
/// Routes requests to workers
abstract class Router<T> {
  /// Select worker for request
  /// Returns null if no suitable worker available
  WorkerPort? select(T request, {Set<String>? exclude});
  
  /// Update available workers
  void updateWorkers(List<PortInfo> workers);
  
  /// Record successful response
  void recordSuccess(String workerId, Duration latency);
  
  /// Record timeout/failure
  void recordFailure(String workerId);
}

/// Worker port with metadata
class WorkerPort {
  final String id;
  final SendPort port;
  final bool healthy;
  final int pendingCount;
  final int avgLatencyUs;
}

/// Round-robin router (default)
class RoundRobinRouter<T> implements Router<T> {
  // Simple rotation through workers
}

/// Consistent hash router
class ConsistentHashRouter<T> implements Router<T> {
  final int virtualNodesPerWorker;
  final String Function(T) keyExtractor;
  
  ConsistentHashRouter({
    this.virtualNodesPerWorker = 150,
    required this.keyExtractor,
  });
}

/// Least-connections router  
class LeastConnectionsRouter<T> implements Router<T> {
  // Routes to worker with fewest pending requests
}

/// Custom router
abstract class CustomRouter<T> implements Router<T> {
  // User implements select() logic
}
```

### Hash Ring

```dart
/// Consistent hash ring implementation
class HashRing {
  final int virtualNodesPerWorker;
  final _ring = SortedList<_RingNode>();
  final _workers = <String, _WorkerState>{};
  
  HashRing({this.virtualNodesPerWorker = 150});
  
  /// Add worker to ring
  void addWorker(String id, SendPort port) {
    _workers[id] = _WorkerState(id: id, port: port);
    
    for (var i = 0; i < virtualNodesPerWorker; i++) {
      final virtualKey = '$id-v$i';
      final hash = _fnv1a(virtualKey);
      _ring.add(_RingNode(hash: hash, workerId: id));
    }
  }
  
  /// Remove worker from ring
  void removeWorker(String id) {
    _workers.remove(id);
    _ring.removeWhere((node) => node.workerId == id);
  }
  
  /// Find worker for key
  WorkerPort? find(String key, {Set<String>? exclude}) {
    if (_ring.isEmpty) return null;
    
    final hash = _fnv1a(key);
    final startIndex = _ring.binarySearchInsertPoint(hash);
    
    // Walk ring clockwise
    for (var i = 0; i < _ring.length; i++) {
      final index = (startIndex + i) % _ring.length;
      final workerId = _ring[index].workerId;
      
      if (exclude?.contains(workerId) ?? false) continue;
      
      final worker = _workers[workerId];
      if (worker != null && worker.healthy) {
        return WorkerPort(
          id: worker.id,
          port: worker.port,
          healthy: worker.healthy,
          pendingCount: worker.pendingCount,
          avgLatencyUs: worker.avgLatencyUs,
        );
      }
    }
    
    // Return any worker as last resort
    return _workers.values
      .where((w) => !(exclude?.contains(w.id) ?? false))
      .map((w) => WorkerPort(...))
      .firstOrNull;
  }
  
  /// FNV-1a hash function
  static int _fnv1a(String data) {
    var hash = 2166136261;
    for (final byte in utf8.encode(data)) {
      hash ^= byte;
      hash = (hash * 16777619) & 0xFFFFFFFF;
    }
    return hash;
  }
}
```

---

## Request Manager

### API

```dart
/// Manages task lifecycle with timeout handling
class RequestManager<TData> {
  final Duration defaultTimeout;
  final int maxRetries;
  final Router<TData> router;
  
  RequestManager({
    required this.defaultTimeout,
    required this.maxRetries,
    required this.router,
  });
  
  /// Submit task and wait for result
  Future<TaskResult<TData>> submit(
    Task<TData> task, {
    Duration? timeout,
    SendPort? replyPort,
  });
  
  /// Handle incoming response (TaskResult or TaskError)
  void onResponse(Envelope envelope);
  
  /// Cancel pending task
  void cancel(String taskId);
  
  /// Get pending task count
  int get pendingCount;
}
```

### Timer Wheel

```dart
/// Efficient timeout management using timer wheel
class TimerWheel {
  final Duration tickDuration;
  final int wheelSize;
  final List<Set<String>> _buckets;
  int _currentTick = 0;
  Timer? _timer;
  
  TimerWheel({
    this.tickDuration = const Duration(milliseconds: 100),
    this.wheelSize = 64,
  }) : _buckets = List.generate(wheelSize, (_) => {});
  
  /// Start the timer wheel
  void start(void Function(String) onTimeout) {
    _timer = Timer.periodic(tickDuration, (_) {
      final expired = _buckets[_currentTick];
      for (final id in expired) {
        onTimeout(id);
      }
      expired.clear();
      _currentTick = (_currentTick + 1) % wheelSize;
    });
  }
  
  /// Stop the timer wheel
  void stop() {
    _timer?.cancel();
    _timer = null;
  }
  
  /// Add timeout for request
  /// Returns bucket index for later removal
  int add(String requestId, Duration timeout) {
    final ticks = timeout.inMilliseconds ~/ tickDuration.inMilliseconds;
    final bucket = (_currentTick + ticks) % wheelSize;
    _buckets[bucket].add(requestId);
    return bucket;
  }
  
  /// Remove request from timeout tracking
  void remove(String requestId, int bucket) {
    _buckets[bucket].remove(requestId);
  }
}
```

### Pending Task

```dart
/// Tracks in-flight task
class PendingTask<TData> {
  final String id;
  final String correlationId;
  final Task<TData> task;
  final Completer<TaskResult<TData>> completer;
  final SendPort replyPort;
  
  String sentTo;
  int sentAt;
  int retryCount = 0;
  Set<String> triedWorkers = {};
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
  });
}
```

---

## Worker Base

### API

```dart
/// Base class for worker implementation
/// TData: The application-specific data type this worker processes
abstract class Worker<TData> {
  /// Worker context with dependencies
  WorkerContext get context;
  
  /// Initialize worker
  Future<void> onInit(Map<String, dynamic> config);
  
  /// Process task
  /// Receives unwrapped data from Task<TData>, returns data for TaskResult<TData>
  /// Throw exception to return TaskError
  Future<TData> onTask(TData data, {String? taskType, Map<String, dynamic>? metadata});
  
  /// Get current metrics
  IsolateMetrics onHealthCheck();
  
  /// Cleanup on shutdown
  Future<void> onShutdown();
}

/// Context provided to worker
class WorkerContext {
  final String id;
  final String name;
  final SendPort hubPort;
  final Map<String, List<SendPort>> dependencies;
  final MessageIdGenerator idGenerator;
  
  /// Send log message
  void log(LogLevel level, String message, {Map<String, dynamic>? context});
}

/// Standard worker entry point helper
void runWorker<TData>(
  SendPort hubPort,
  Worker<TData> Function() createWorker,
) {
  final receivePort = ReceivePort();
  Worker<TData>? worker;
  
  hubPort.send(Envelope(
    // ... registration
  ));
  
  receivePort.listen((envelope) async {
    switch (envelope.payload) {
      case Init init:
        worker = createWorker();
        await worker!.onInit(init.config);
        hubPort.send(Ready(success: true));
        
      case Ping ping:
        hubPort.send(Pong(
          seq: ping.seq,
          metrics: worker!.onHealthCheck(),
        ));
        
      // Handle application task
      case Task<TData> task:
        try {
          final result = await worker!.onTask(
            task.data,
            taskType: task.taskType,
            metadata: task.metadata,
          );
          envelope.replyTo?.send(Envelope(
            correlationId: envelope.id,
            payload: TaskResult<TData>(data: result),
          ));
        } catch (e, stackTrace) {
          envelope.replyTo?.send(Envelope(
            correlationId: envelope.id,
            payload: TaskError(
              code: e.runtimeType.toString(),
              message: e.toString(),
              stackTrace: stackTrace.toString(),
            ),
          ));
        }
      
      // Handle batch tasks
      case TaskBatch<TData> batch:
        final results = <TaskResultOrError<TData>>[];
        for (final task in batch.tasks) {
          try {
            final result = await worker!.onTask(
              task.data,
              taskType: task.taskType,
              metadata: task.metadata,
            );
            results.add(TaskSuccess(result));
          } catch (e, stackTrace) {
            results.add(TaskFailure(TaskError(
              code: e.runtimeType.toString(),
              message: e.toString(),
              stackTrace: stackTrace.toString(),
            )));
          }
        }
        envelope.replyTo?.send(Envelope(
          correlationId: envelope.id,
          payload: TaskBatchResult<TData>(results),
        ));
        
      case Shutdown shutdown:
        await worker?.onShutdown();
        hubPort.send(ShutdownAck(pendingTasks: 0, flushed: true));
        receivePort.close();
    }
  });
}
```

---

## Logging Module

The logging module provides cross-isolate logging support using Dart's `logging` package. Since `LogRecord` objects cannot be directly passed across isolate boundaries, this module provides serialization and a central logger pattern.

### Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Logging Architecture                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   Worker Isolate 1          Worker Isolate 2          Worker Isolate N  │
│  ┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐│
│  │ Logger('worker')│       │ Logger('worker')│       │ Logger('worker')││
│  │       │         │       │       │         │       │       │         ││
│  │       ▼         │       │       ▼         │       │       ▼         ││
│  │ LogBridge       │       │ LogBridge       │       │ LogBridge       ││
│  └───────┬─────────┘       └───────┬─────────┘       └───────┬─────────┘│
│          │                         │                         │          │
│          │    SerializableLogRecord (via SendPort)           │          │
│          └─────────────────────────┼─────────────────────────┘          │
│                                    ▼                                    │
│                        ┌───────────────────────┐                        │
│                        │  Central Logger       │                        │
│                        │  ┌─────────────────┐  │                        │
│                        │  │ Filter by Level │  │                        │
│                        │  │ Format Record   │  │                        │
│                        │  │ Route to Output │  │                        │
│                        │  └─────────────────┘  │                        │
│                        └───────────┬───────────┘                        │
│                                    │                                    │
│                    ┌───────────────┼───────────────┐                    │
│                    ▼               ▼               ▼                    │
│               ┌────────┐     ┌──────────┐    ┌──────────┐               │
│               │Console │     │   File   │    │ Custom   │               │
│               └────────┘     └──────────┘    └──────────┘               │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### SerializableLogRecord

```dart
/// Serializable log record for cross-isolate transport
class SerializableLogRecord {
  final int level;            // Level.value
  final String levelName;     // Level.name  
  final String message;
  final String loggerName;
  final int time;             // microsecondsSinceEpoch
  final String? error;
  final String? stackTrace;
  final String isolateId;
  final Map<String, dynamic>? context;  // Additional context data
  
  const SerializableLogRecord({
    required this.level,
    required this.levelName,
    required this.message,
    required this.loggerName,
    required this.time,
    this.error,
    this.stackTrace,
    required this.isolateId,
    this.context,
  });
  
  /// Create from logging package LogRecord
  factory SerializableLogRecord.fromLogRecord(
    LogRecord record,
    String isolateId, {
    Map<String, dynamic>? context,
  }) {
    return SerializableLogRecord(
      level: record.level.value,
      levelName: record.level.name,
      message: record.message,
      loggerName: record.loggerName,
      time: record.time.microsecondsSinceEpoch,
      error: record.error?.toString(),
      stackTrace: record.stackTrace?.toString(),
      isolateId: isolateId,
      context: context,
    );
  }
  
  /// Convert back to LogRecord
  LogRecord toLogRecord() {
    return LogRecord(
      Level(levelName, level),
      message,
      loggerName,
      error != null ? Exception(error) : null,
      stackTrace != null ? StackTrace.fromString(stackTrace!) : null,
    );
  }
  
  /// Serialize to Map for SendPort
  Map<String, dynamic> toMap() => {
    'level': level,
    'levelName': levelName,
    'message': message,
    'loggerName': loggerName,
    'time': time,
    'error': error,
    'stackTrace': stackTrace,
    'isolateId': isolateId,
    'context': context,
  };
  
  /// Deserialize from Map
  factory SerializableLogRecord.fromMap(Map<String, dynamic> map) {
    return SerializableLogRecord(
      level: map['level'],
      levelName: map['levelName'],
      message: map['message'],
      loggerName: map['loggerName'],
      time: map['time'],
      error: map['error'],
      stackTrace: map['stackTrace'],
      isolateId: map['isolateId'],
      context: map['context'],
    );
  }
}
```

### IsolateLogBridge

```dart
/// Bridges logging package to central logger via SendPort
class IsolateLogBridge {
  final String isolateId;
  final SendPort loggerPort;
  final String _loggerPrefix;
  
  StreamSubscription<LogRecord>? _subscription;
  Map<String, dynamic>? _defaultContext;
  
  IsolateLogBridge({
    required this.isolateId,
    required this.loggerPort,
    String loggerPrefix = '',
  }) : _loggerPrefix = loggerPrefix;
  
  /// Install bridge - intercepts all logs in current isolate
  void install({
    Level level = Level.ALL,
    Map<String, dynamic>? defaultContext,
  }) {
    _defaultContext = defaultContext;
    Logger.root.level = level;
    
    _subscription = Logger.root.onRecord.listen(_forwardRecord);
  }
  
  /// Uninstall bridge
  void uninstall() {
    _subscription?.cancel();
    _subscription = null;
  }
  
  void _forwardRecord(LogRecord record) {
    final serializable = SerializableLogRecord.fromLogRecord(
      record,
      isolateId,
      context: _defaultContext,
    );
    loggerPort.send(serializable.toMap());
  }
  
  /// Get a named logger with prefix
  Logger getLogger(String name) {
    final fullName = _loggerPrefix.isEmpty ? name : '$_loggerPrefix.$name';
    return Logger(fullName);
  }
}
```

### WorkerContext Logging Integration

```dart
/// Extended WorkerContext with logging support
class WorkerContext {
  final String id;
  final String name;
  final SendPort hubPort;
  final SendPort? loggerPort;
  final MessageIdGenerator idGenerator;
  
  late final Logger _logger;
  IsolateLogBridge? _logBridge;
  
  WorkerContext({
    required this.id,
    required this.name,
    required this.hubPort,
    this.loggerPort,
    required this.idGenerator,
  }) {
    final loggerName = 'worker.$name';
    _logger = Logger(loggerName);
    
    // Install log bridge if logger port available
    if (loggerPort != null) {
      _logBridge = IsolateLogBridge(
        isolateId: id,
        loggerPort: loggerPort!,
        loggerPrefix: loggerName,
      );
      _logBridge!.install(
        defaultContext: {'workerId': id, 'workerName': name},
      );
    }
  }
  
  /// Get root logger for this worker
  Logger get logger => _logger;
  
  /// Get a sub-logger (e.g., 'worker.dns.cache')
  Logger getLogger(String name) => Logger('${_logger.fullName}.$name');
  
  // Convenience logging methods
  void finest(String message, [Object? error, StackTrace? stackTrace]) =>
    _logger.finest(message, error, stackTrace);
    
  void finer(String message, [Object? error, StackTrace? stackTrace]) =>
    _logger.finer(message, error, stackTrace);
    
  void fine(String message, [Object? error, StackTrace? stackTrace]) =>
    _logger.fine(message, error, stackTrace);
    
  void config(String message, [Object? error, StackTrace? stackTrace]) =>
    _logger.config(message, error, stackTrace);
    
  void info(String message, [Object? error, StackTrace? stackTrace]) =>
    _logger.info(message, error, stackTrace);
    
  void warning(String message, [Object? error, StackTrace? stackTrace]) =>
    _logger.warning(message, error, stackTrace);
    
  void severe(String message, [Object? error, StackTrace? stackTrace]) =>
    _logger.severe(message, error, stackTrace);
    
  void shout(String message, [Object? error, StackTrace? stackTrace]) =>
    _logger.shout(message, error, stackTrace);
  
  /// Cleanup
  void dispose() {
    _logBridge?.uninstall();
  }
}
```

### Log Output Targets

```dart
/// Base class for log output destinations
abstract class LogOutput {
  const LogOutput();
  
  /// Write formatted log record
  void write(SerializableLogRecord record, String formatted);
  
  /// Flush any buffered output
  Future<void> flush() async {}
  
  /// Close the output
  Future<void> close() async {}
}

/// Console output (stdout/stderr)
class ConsoleLogOutput extends LogOutput {
  final bool useStderr;
  final int stderrThreshold;  // Level.value threshold for stderr
  
  const ConsoleLogOutput({
    this.useStderr = true,
    this.stderrThreshold = 900,  // Level.WARNING
  });
  
  @override
  void write(SerializableLogRecord record, String formatted) {
    if (useStderr && record.level >= stderrThreshold) {
      stderr.writeln(formatted);
    } else {
      print(formatted);
    }
  }
}

/// File output with rotation support
class FileLogOutput extends LogOutput {
  final String path;
  final int maxSizeBytes;
  final int maxFiles;
  
  IOSink? _sink;
  int _currentSize = 0;
  
  FileLogOutput({
    required this.path,
    this.maxSizeBytes = 10 * 1024 * 1024,  // 10MB
    this.maxFiles = 5,
  });
  
  @override
  void write(SerializableLogRecord record, String formatted) {
    _ensureOpen();
    final line = '$formatted\n';
    _sink!.write(line);
    _currentSize += line.length;
    
    if (_currentSize >= maxSizeBytes) {
      _rotate();
    }
  }
  
  void _ensureOpen() {
    _sink ??= File(path).openWrite(mode: FileMode.append);
  }
  
  void _rotate() {
    _sink?.close();
    _sink = null;
    _currentSize = 0;
    
    // Rotate files: log.4 -> delete, log.3 -> log.4, etc.
    for (var i = maxFiles - 1; i >= 0; i--) {
      final file = File(i == 0 ? path : '$path.$i');
      if (file.existsSync()) {
        if (i == maxFiles - 1) {
          file.deleteSync();
        } else {
          file.renameSync('$path.${i + 1}');
        }
      }
    }
  }
  
  @override
  Future<void> flush() async {
    await _sink?.flush();
  }
  
  @override
  Future<void> close() async {
    await _sink?.close();
    _sink = null;
  }
}

/// JSON lines output (for log aggregation systems)
class JsonLogOutput extends LogOutput {
  final LogOutput inner;
  
  const JsonLogOutput(this.inner);
  
  @override
  void write(SerializableLogRecord record, String formatted) {
    final json = jsonEncode(record.toMap());
    inner.write(record, json);
  }
  
  @override
  Future<void> flush() => inner.flush();
  
  @override
  Future<void> close() => inner.close();
}

/// Callback output for custom handling
class CallbackLogOutput extends LogOutput {
  final void Function(SerializableLogRecord record, String formatted) callback;
  
  const CallbackLogOutput(this.callback);
  
  @override
  void write(SerializableLogRecord record, String formatted) {
    callback(record, formatted);
  }
}
```

### Log Formatter

```dart
/// Configurable log formatter
class LogFormatter {
  final bool includeTimestamp;
  final bool includeLevel;
  final bool includeIsolateId;
  final bool includeLoggerName;
  final String timestampFormat;
  final String separator;
  
  const LogFormatter({
    this.includeTimestamp = true,
    this.includeLevel = true,
    this.includeIsolateId = true,
    this.includeLoggerName = true,
    this.timestampFormat = 'yyyy-MM-ddTHH:mm:ss.SSS',
    this.separator = ' ',
  });
  
  String format(SerializableLogRecord record) {
    final parts = <String>[];
    
    if (includeTimestamp) {
      final time = DateTime.fromMicrosecondsSinceEpoch(record.time);
      parts.add(_formatTimestamp(time));
    }
    
    if (includeLevel) {
      parts.add('[${record.levelName.padRight(7)}]');
    }
    
    if (includeIsolateId) {
      parts.add('(${record.isolateId})');
    }
    
    if (includeLoggerName) {
      parts.add('${record.loggerName}:');
    }
    
    parts.add(record.message);
    
    final buffer = StringBuffer(parts.join(separator));
    
    if (record.error != null) {
      buffer.write('\n  Error: ${record.error}');
    }
    
    if (record.stackTrace != null) {
      buffer.write('\n${record.stackTrace}');
    }
    
    return buffer.toString();
  }
  
  String _formatTimestamp(DateTime time) {
    // Simple ISO format, can be extended with intl package
    return time.toIso8601String();
  }
}

/// Compact formatter for high-volume logging
class CompactLogFormatter extends LogFormatter {
  const CompactLogFormatter() : super(
    includeTimestamp: true,
    includeLevel: true,
    includeIsolateId: false,
    includeLoggerName: false,
  );
}

/// Detailed formatter for debugging
class DetailedLogFormatter extends LogFormatter {
  const DetailedLogFormatter() : super(
    includeTimestamp: true,
    includeLevel: true,
    includeIsolateId: true,
    includeLoggerName: true,
  );
}
```

### Central Logger

```dart
/// Configuration for central logger
class CentralLoggerConfig {
  final Level level;
  final LogFormatter formatter;
  final List<LogOutput> outputs;
  final Map<String, Level>? loggerLevels;  // Per-logger level overrides
  
  const CentralLoggerConfig({
    this.level = Level.INFO,
    this.formatter = const LogFormatter(),
    this.outputs = const [ConsoleLogOutput()],
    this.loggerLevels,
  });
}

/// Central logger that aggregates logs from all isolates
class CentralLogger {
  final CentralLoggerConfig config;
  final ReceivePort _receivePort = ReceivePort();
  
  StreamSubscription? _subscription;
  
  CentralLogger({required this.config});
  
  /// Get SendPort for worker isolates to send logs
  SendPort get sendPort => _receivePort.sendPort;
  
  /// Start processing logs
  void start() {
    _subscription = _receivePort.listen(_handleMessage);
  }
  
  /// Stop processing and cleanup
  Future<void> stop() async {
    _subscription?.cancel();
    _receivePort.close();
    
    for (final output in config.outputs) {
      await output.flush();
      await output.close();
    }
  }
  
  void _handleMessage(dynamic message) {
    if (message is! Map<String, dynamic>) return;
    
    final record = SerializableLogRecord.fromMap(message);
    
    // Check level filter
    if (!_shouldLog(record)) return;
    
    // Format
    final formatted = config.formatter.format(record);
    
    // Output to all targets
    for (final output in config.outputs) {
      output.write(record, formatted);
    }
  }
  
  bool _shouldLog(SerializableLogRecord record) {
    // Check per-logger level overrides
    if (config.loggerLevels != null) {
      for (final entry in config.loggerLevels!.entries) {
        if (record.loggerName.startsWith(entry.key)) {
          return record.level >= entry.value.value;
        }
      }
    }
    
    // Fall back to global level
    return record.level >= config.level.value;
  }
}

/// Central logger isolate entry point
void centralLoggerEntryPoint(SendPort hubPort) {
  final receivePort = ReceivePort();
  CentralLogger? logger;
  
  // Register with hub
  hubPort.send(Envelope(
    id: 'logger-register',
    timestamp: DateTime.now().microsecondsSinceEpoch,
    source: IsolateAddress(role: 'logger', id: 'logger-0'),
    target: IsolateAddress.hub,
    payload: Register(
      name: 'central-logger',
      role: 'logger',
      port: receivePort.sendPort,
      capabilities: ['logging'],
      subscribesTo: [],
    ),
  ));
  
  receivePort.listen((message) {
    if (message is Envelope) {
      switch (message.payload) {
        case Init init:
          final config = _parseConfig(init.config);
          logger = CentralLogger(config: config);
          logger!.start();
          
          hubPort.send(Envelope(
            id: 'logger-ready',
            timestamp: DateTime.now().microsecondsSinceEpoch,
            source: IsolateAddress(role: 'logger', id: 'logger-0'),
            target: IsolateAddress.hub,
            payload: Ready(success: true),
          ));
          
        case Shutdown _:
          logger?.stop();
          hubPort.send(Envelope(
            id: 'logger-shutdown-ack',
            timestamp: DateTime.now().microsecondsSinceEpoch,
            source: IsolateAddress(role: 'logger', id: 'logger-0'),
            target: IsolateAddress.hub,
            payload: ShutdownAck(pendingTasks: 0, flushed: true),
          ));
          receivePort.close();
      }
    } else if (message is Map<String, dynamic>) {
      // Log record from worker
      logger?._handleMessage(message);
    }
  });
}

CentralLoggerConfig _parseConfig(Map<String, dynamic> config) {
  final levelName = config['level'] as String? ?? 'INFO';
  final level = Level.LEVELS.firstWhere(
    (l) => l.name == levelName,
    orElse: () => Level.INFO,
  );
  
  final outputs = <LogOutput>[];
  
  if (config['console'] != false) {
    outputs.add(ConsoleLogOutput());
  }
  
  if (config['file'] != null) {
    outputs.add(FileLogOutput(
      path: config['file']['path'] ?? 'app.log',
      maxSizeBytes: config['file']['max_size_bytes'] ?? 10 * 1024 * 1024,
      maxFiles: config['file']['max_files'] ?? 5,
    ));
  }
  
  return CentralLoggerConfig(
    level: level,
    outputs: outputs.isEmpty ? [ConsoleLogOutput()] : outputs,
  );
}
```

### Logging Usage Example

```dart
// In worker implementation
class MyWorker extends Worker<MyData> {
  late final Logger _cacheLogger;
  late final Logger _networkLogger;
  
  @override
  Future<void> onInit(Map<String, dynamic> config) async {
    // Get sub-loggers for different components
    _cacheLogger = context.getLogger('cache');
    _networkLogger = context.getLogger('network');
    
    context.info('Worker initialized with config: $config');
  }
  
  @override
  Future<MyData> onTask(
    MyData data, {
    String? taskType,
    Map<String, dynamic>? metadata,
  }) async {
    context.fine('Processing task: $taskType');
    
    // Use component-specific loggers
    _cacheLogger.finer('Cache lookup for key: ${data.key}');
    
    try {
      final result = await _processData(data);
      _cacheLogger.finest('Cache hit ratio: ${_hitRatio}');
      return result;
    } catch (e, st) {
      _networkLogger.severe('Network request failed', e, st);
      rethrow;
    }
  }
  
  @override
  Future<void> onShutdown() async {
    context.info('Worker shutting down');
  }
}

// Hub setup with logging
void main() async {
  final hub = IsolateHub();
  await hub.start();
  
  // Start central logger
  final loggerHandle = await hub.spawn(
    role: 'logger',
    name: 'central-logger',
    entryPoint: centralLoggerEntryPoint,
    config: {
      'level': 'FINE',
      'console': true,
      'file': {
        'path': '/var/log/app.log',
        'max_size_bytes': 10485760,
        'max_files': 5,
      },
    },
  );
  
  // Get logger port for workers
  final loggerPort = loggerHandle.sendPort;
  
  // Start worker pool with logger port
  final pool = WorkerPool<MyData>(
    hub: hub,
    config: WorkerPoolConfig(
      minWorkers: 4,
      workerConfig: {
        'loggerPort': loggerPort,  // Pass to workers
      },
    ),
    workerEntryPoint: myWorkerEntryPoint,
  );
  
  await pool.start();
  
  // ... use pool ...
  
  await pool.stop();
  await hub.stop();
}
```

### Log Output Example

```
2025-01-01T12:00:00.123 [INFO   ] (worker-1) worker.dns: Worker initialized with config: {upstream: 8.8.8.8}
2025-01-01T12:00:00.234 [FINE   ] (worker-1) worker.dns: Processing task: dns_query
2025-01-01T12:00:00.235 [FINER  ] (worker-1) worker.dns.cache: Cache lookup for key: google.com
2025-01-01T12:00:00.236 [FINEST ] (worker-1) worker.dns.cache: Cache hit ratio: 0.85
2025-01-01T12:00:01.345 [FINE   ] (worker-2) worker.dns: Processing task: dns_query
2025-01-01T12:00:01.456 [SEVERE ] (worker-2) worker.dns.network: Network request failed
  Error: SocketException: Connection refused (OS Error: Connection refused, errno = 111)
  #0      DnsResolver.resolve (package:dns/resolver.dart:45:7)
  #1      DnsWorker.onTask (package:dns/worker.dart:67:20)
  <asynchronous suspension>
```

---

## Configuration

```toml
[isolate_orchestrator]

[isolate_orchestrator.hub]
health_check_interval_ms = 5000
health_check_timeout_ms = 2000
unhealthy_threshold = 3
healthy_threshold = 3

[isolate_orchestrator.hub.restart]
max_attempts = 10
initial_delay_ms = 1000
max_delay_ms = 60000
multiplier = 2.0

[isolate_orchestrator.pool]
min_workers = 2
max_workers = 8
request_timeout_ms = 5000
max_retries = 2

[isolate_orchestrator.router]
type = "consistent_hash"  # or "round_robin", "least_connections"
virtual_nodes_per_worker = 150

[isolate_orchestrator.timer_wheel]
tick_duration_ms = 100
wheel_size = 64

[isolate_orchestrator.logging]
level = "INFO"  # FINEST, FINER, FINE, CONFIG, INFO, WARNING, SEVERE, SHOUT
console = true

[isolate_orchestrator.logging.file]
enabled = true
path = "/var/log/app.log"
max_size_bytes = 10485760  # 10MB
max_files = 5

[isolate_orchestrator.logging.levels]
# Per-logger level overrides
"worker.dns.cache" = "FINEST"
"worker.dns.resolver" = "FINE"
```

---

## Usage Example

### Simple Worker Pool

```dart
import 'package:isolate_orchestrator/isolate_orchestrator.dart';

// Define data type for computation tasks
class ComputeData {
  final int input;
  final int? result;
  
  ComputeData({required this.input, this.result});
  
  ComputeData withResult(int result) => ComputeData(input: input, result: result);
}

// Define worker
class ComputeWorker extends Worker<ComputeData> {
  int _processedCount = 0;
  int _errorCount = 0;
  late DateTime _startTime;
  
  @override
  Future<void> onInit(Map<String, dynamic> config) async {
    _startTime = DateTime.now();
    // Initialize resources
  }
  
  @override
  Future<ComputeData> onTask(
    ComputeData data, {
    String? taskType,
    Map<String, dynamic>? metadata,
  }) async {
    _processedCount++;
    // Heavy computation
    final result = _expensiveComputation(data.input);
    return data.withResult(result);
  }
  
  int _expensiveComputation(int value) {
    // Simulate work
    return value * value;
  }
  
  @override
  IsolateMetrics onHealthCheck() {
    return IsolateMetrics(
      uptimeMs: DateTime.now().difference(_startTime).inMilliseconds,
      processedCount: _processedCount,
      pendingCount: 0,
      errorCount: _errorCount,
      avgLatencyUs: 0,
    );
  }
  
  @override
  Future<void> onShutdown() async {
    // Cleanup
  }
}

// Entry point for worker isolate
void workerEntryPoint(SendPort hubPort) {
  runWorker<ComputeData>(hubPort, () => ComputeWorker());
}

// Main application
void main() async {
  // Create hub
  final hub = IsolateHub();
  await hub.start();
  
  // Create pool
  final pool = WorkerPool<ComputeData>(
    hub: hub,
    config: WorkerPoolConfig(
      minWorkers: 4,
      maxWorkers: 8,
      requestTimeout: Duration(seconds: 10),
    ),
    workerEntryPoint: workerEntryPoint,
  );
  
  await pool.start();
  
  // Submit tasks (simple API - just data)
  final futures = <Future<ComputeData>>[];
  for (var i = 0; i < 100; i++) {
    futures.add(pool.submit(ComputeData(input: i)));
  }
  
  final results = await Future.wait(futures);
  print('Processed ${results.length} tasks');
  print('Results: ${results.map((r) => r.result).toList()}');
  
  // Submit with task type and metadata
  final result = await pool.submit(
    ComputeData(input: 42),
    taskType: 'priority_compute',
    metadata: {'priority': 'high'},
  );
  print('Priority result: ${result.result}');
  
  // Submit batch
  final batchResult = await pool.submitBatch(
    [ComputeData(input: 1), ComputeData(input: 2), ComputeData(input: 3)],
    taskType: 'batch_compute',
  );
  for (final r in batchResult.results) {
    switch (r) {
      case TaskSuccess(:final data):
        print('Success: ${data.result}');
      case TaskFailure(:final error):
        print('Error: ${error.message}');
    }
  }
  
  // Cleanup
  await pool.stop();
  await hub.stop();
}
```

### Custom Router

```dart
// Data type with priority
class PriorityData {
  final dynamic payload;
  final Priority priority;
  PriorityData(this.payload, this.priority);
}

enum Priority { low, normal, high }

// Custom router that routes based on data priority
class PriorityRouter extends CustomRouter<PriorityData> {
  @override
  WorkerPort? select(PriorityData data, {Set<String>? exclude}) {
    if (data.priority == Priority.high) {
      // Route to least loaded worker
      return workers
        .where((w) => w.healthy && !(exclude?.contains(w.id) ?? false))
        .reduce((a, b) => a.pendingCount < b.pendingCount ? a : b);
    } else {
      // Round-robin for normal priority
      return nextWorker(exclude: exclude);
    }
  }
}

// Use custom router
final pool = WorkerPool<PriorityData>(
  hub: hub,
  config: config,
  workerEntryPoint: workerEntryPoint,
  router: PriorityRouter(),
);
```

---

## Error Handling

```dart
/// Orchestrator-related exceptions
class IsolateOrchestratorException implements Exception {
  final String message;
  IsolateOrchestratorException(this.message);
}

class SpawnFailedException extends IsolateOrchestratorException {
  final String role;
  SpawnFailedException(this.role, String message) : super(message);
}

class NoHealthyWorkerException extends IsolateOrchestratorException {
  NoHealthyWorkerException() : super('No healthy workers available');
}

class TaskTimeoutException extends IsolateOrchestratorException {
  final String taskId;
  final int retryCount;
  TaskTimeoutException(this.taskId, this.retryCount)
    : super('Task $taskId timed out after $retryCount retries');
}

class WorkerException extends IsolateOrchestratorException {
  final String workerId;
  WorkerException(this.workerId, String message) : super(message);
}
```

---

## Testing Utilities

```dart
/// Mock worker for testing
class MockWorker<TData> extends Worker<TData> {
  final Future<TData> Function(TData, String?, Map<String, dynamic>?) handler;
  final Duration? delay;
  
  MockWorker({required this.handler, this.delay});
  
  @override
  Future<void> onInit(Map<String, dynamic> config) async {}
  
  @override
  Future<TData> onTask(
    TData data, {
    String? taskType,
    Map<String, dynamic>? metadata,
  }) async {
    if (delay != null) await Future.delayed(delay!);
    return handler(data, taskType, metadata);
  }
  
  @override
  IsolateMetrics onHealthCheck() => IsolateMetrics(
    uptimeMs: 0,
    processedCount: 0,
    pendingCount: 0,
    errorCount: 0,
    avgLatencyUs: 0,
  );
  
  @override
  Future<void> onShutdown() async {}
}

/// Test helpers
class IsolateOrchestratorTesting {
  /// Create hub that doesn't actually spawn isolates
  static IsolateHub createMockHub();
  
  /// Create pool with inline workers (no isolates)
  static WorkerPool<TData> createInlinePool<TData>({
    required Future<TData> Function(TData, String?, Map<String, dynamic>?) handler,
    int workerCount = 4,
  });
}
```

---

## Design Changes Log

### Communication Architecture

**Problem**: Pong responses from workers were being lost after initialization because the hub only temporarily listened to the `controlPort` during spawn and init phases.

**Solution**: Added permanent `broadcastStream` listeners in `IsolateHub`:

```dart
final Map<String, StreamSubscription> _isolateSubscriptions = {};

// After registry.register(entry):
_isolateSubscriptions[entry.id] = entry.broadcastStream.listen(
  _handleMessage,
);
```

**Impact**: Health monitoring now correctly receives pong responses, enabling proper health status tracking and failure detection.

### Memory Management

**Problem**: When isolates were unregistered, pending ping entries in `HealthMonitor` remained, causing memory leaks.

**Solution**: Added `removePendingPing()` method to `HealthMonitor`:

```dart
void removePendingPing(String isolateId) {
  _pendingPings.remove(isolateId);
}
```

The hub now calls this method before unregistering isolates:

```dart
_healthMonitor?.removePendingPing(entry.id);
_isolateSubscriptions[entry.id]?.cancel();
_isolateSubscriptions.remove(entry.id);
_registry.unregister(entry.id);
```

**Impact**: Prevents memory accumulation when workers are frequently restarted.

### Exception Consolidation

**Problem**: Exception classes were scattered across multiple files with some duplication.

**Solution**: Consolidated all exceptions into `lib/src/exception.dart`:

| Exception | Description |
|-----------|-------------|
| `TaskException` | Base class for task-related errors |
| `TaskTimeoutException` | Task exceeded timeout after all retries |
| `TaskCancelledException` | Task was explicitly cancelled |
| `NoHealthyWorkerException` | No healthy workers available |
| `SpawnTimeoutException` | Worker isolate failed to register in time |
| `InitializationException` | Worker failed during initialization |

**Impact**: Single import for all exception types, cleaner error handling code.

### Concurrent Batch Processing

**Problem**: `submitBatch()` processed tasks sequentially, not leveraging the parallel worker pool.

**Solution**: Changed to concurrent execution using `Future.wait()`:

```dart
Future<BatchResult<T>> submitBatch(List<T> dataList, {...}) async {
  final futures = dataList.map((data) => _submitSingle(data, ...));
  final results = await Future.wait(
    futures,
    eagerError: false,  // Collect all results even if some fail
  );
  return BatchResult(results);
}
```

**Impact**: Batch tasks now execute concurrently across all available workers, significantly improving throughput.

### Timer Wheel Race Condition

**Problem**: When retrying a task, the old timer bucket entry wasn't removed before adding to the new bucket, causing duplicate timeout callbacks.

**Solution**: Remove from old bucket before adding to new:

```dart
void _retryTask(PendingTask task) {
  // Remove from old bucket FIRST
  _timerWheel.remove(task.id, task.timerBucket);

  // Add to new bucket
  task.timerBucket = _timerWheel.add(task.id, _timeout);
  task.retryCount++;

  // Send to new worker...
}
```

**Impact**: Prevents spurious timeout errors during retry operations.

### Worker Resource Cleanup

**Problem**: `WorkerContext` logging bridge was not being cleaned up on worker shutdown, potentially leaving dangling stream subscriptions.

**Solution**: Added `context.dispose()` call in worker shutdown:

```dart
case Shutdown shutdown:
  await worker?.onShutdown();
  context.dispose();  // Cleanup logging bridge
  hubPort.send(ShutdownAck(...));
  receivePort.close();
```

**Impact**: Clean worker shutdown without resource leaks.

---

*Package Version: 1.0.0*
*Dart SDK: ^3.0.0*