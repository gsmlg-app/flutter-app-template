# Isolate Orchestrator

A generic Dart package for managing pools of long-running isolates with health monitoring, automatic restart, and request-response correlation.

## Features

- **Centralized Hub** - Lifecycle management for all isolates
- **Type-safe Protocol** - Sealed class message hierarchy
- **Health Monitoring** - Automatic health checks with configurable thresholds
- **Automatic Restart** - Exponential backoff restart policy for failed isolates
- **Multiple Routers** - Round-robin, consistent hash, and least-connections routing
- **Timeout Handling** - Efficient timer wheel with automatic retries
- **Concurrent Batch Processing** - Parallel task execution with `Future.wait`
- **Cross-isolate Logging** - Integrated logging with `logging` package support
- **Comprehensive Test Suite** - 197 tests covering unit, integration, and edge cases

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  isolate_orchestrator: any
```

## Quick Start

### 1. Define Your Data Type

```dart
class ComputeData {
  final int input;
  final int? result;

  ComputeData({required this.input, this.result});

  ComputeData withResult(int result) =>
      ComputeData(input: input, result: result);
}
```

### 2. Create a Worker

```dart
class ComputeWorker extends Worker<ComputeData> with WorkerMetricsMixin {
  final WorkerContext _context;

  @override
  WorkerContext get context => _context;

  ComputeWorker(WorkerContext context) : _context = context;

  @override
  Future<void> onInit(Map<String, dynamic> config) async {
    initMetrics();
  }

  @override
  Future<ComputeData> onTask(
    ComputeData data, {
    String? taskType,
    Map<String, dynamic>? metadata,
  }) async {
    final result = data.input * data.input;
    return data.withResult(result);
  }

  @override
  Future<void> onShutdown() async {}
}
```

### 3. Define Worker Entry Point

```dart
void workerEntryPoint(SendPort hubPort) {
  runWorker<ComputeData>(hubPort, (context) => ComputeWorker(context));
}
```

### 4. Create Hub and Pool

```dart
void main() async {
  // Create and start hub
  final hub = IsolateHub();
  await hub.start();

  // Create and start pool
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

  // Submit tasks
  final result = await pool.submit(ComputeData(input: 42));
  print('Result: ${result.result}'); // Result: 1764

  // Submit batch (tasks execute concurrently across workers)
  final batchResult = await pool.submitBatch([
    ComputeData(input: 1),
    ComputeData(input: 2),
    ComputeData(input: 3),
  ]);

  // Process batch results
  for (final result in batchResult.results) {
    switch (result) {
      case TaskSuccess(:final data):
        print('Success: ${data.result}');
      case TaskFailure(:final error):
        print('Failed: ${error.message}');
    }
  }

  // Cleanup
  await pool.stop();
  await hub.stop();
}
```

## Configuration

### HubConfig

```dart
HubConfig(
  healthCheckInterval: Duration(seconds: 5),
  healthCheckTimeout: Duration(seconds: 2),
  unhealthyThreshold: 3,    // Failures before marked unhealthy
  healthyThreshold: 3,      // Successes before marked healthy
  restartPolicy: RestartPolicy(
    maxAttempts: 10,
    initialDelay: Duration(seconds: 1),
    maxDelay: Duration(seconds: 60),
    multiplier: 2.0,
  ),
)
```

### WorkerPoolConfig

```dart
WorkerPoolConfig(
  minWorkers: 2,
  maxWorkers: 8,
  requestTimeout: Duration(seconds: 5),
  maxRetries: 2,
  workerConfig: {'key': 'value'},  // Passed to worker onInit
)
```

## Routing Strategies

### Round-Robin (Default)

```dart
final pool = WorkerPool<MyData>(
  hub: hub,
  config: config,
  workerEntryPoint: entryPoint,
  // Uses RoundRobinRouter by default
);
```

### Consistent Hash

```dart
final pool = WorkerPool<MyData>(
  hub: hub,
  config: config,
  workerEntryPoint: entryPoint,
  router: ConsistentHashRouter<MyData>(
    virtualNodesPerWorker: 150,
    keyExtractor: (data) => data.id,  // Extract routing key
  ),
);
```

### Least Connections

```dart
final pool = WorkerPool<MyData>(
  hub: hub,
  config: config,
  workerEntryPoint: entryPoint,
  router: LeastConnectionsRouter<MyData>(),
);
```

## Error Handling

### Exception Types

| Exception | Description |
|-----------|-------------|
| `TaskException` | Base class for task-related errors |
| `TaskTimeoutException` | Task exceeded timeout after all retries |
| `TaskCancelledException` | Task was explicitly cancelled |
| `NoHealthyWorkerException` | No healthy workers available to handle request |
| `SpawnTimeoutException` | Worker isolate failed to register in time |
| `InitializationException` | Worker failed during initialization |

### Usage

```dart
try {
  final result = await pool.submit(data);
} on TaskException catch (e) {
  print('Task failed: ${e.code} - ${e.message}');
} on TaskTimeoutException catch (e) {
  print('Task ${e.taskId} timed out after ${e.retryCount} retries');
} on TaskCancelledException catch (e) {
  print('Task ${e.taskId} was cancelled');
} on NoHealthyWorkerException {
  print('No workers available');
}
```

## Logging

The package provides cross-isolate logging support using Dart's `logging` package.

### Worker Logging

Workers can log using the `WorkerContext`:

```dart
class MyWorker extends Worker<MyData> {
  late final Logger _cacheLogger;

  @override
  Future<void> onInit(Map<String, dynamic> config) async {
    context.info('Worker initialized');

    // Get sub-loggers for different components
    _cacheLogger = context.getLogger('cache');
  }

  @override
  Future<MyData> onTask(MyData data, {...}) async {
    context.fine('Processing task');
    _cacheLogger.finer('Cache lookup');
    return processedData;
  }
}
```

### Central Logger Setup

Set up centralized logging to aggregate logs from all isolates:

```dart
void main() async {
  // Create central logger
  final centralLogger = CentralLogger(
    config: CentralLoggerConfig(
      level: Level.INFO,
      formatter: DetailedLogFormatter(),
      outputs: [
        ConsoleLogOutput(),
        FileLogOutput(path: 'app.log', maxSizeBytes: 10 * 1024 * 1024),
      ],
      loggerLevels: {
        'worker.dns.cache': Level.FINEST,  // Per-logger overrides
      },
    ),
  );
  centralLogger.start();

  // Pass logger port to workers via config
  final pool = WorkerPool<MyData>(
    hub: hub,
    config: WorkerPoolConfig(
      workerConfig: {
        'loggerPort': centralLogger.sendPort,
      },
    ),
    workerEntryPoint: entryPoint,
  );

  // ... later ...
  await centralLogger.stop();
}
```

### Log Formatters

- `LogFormatter` - Default formatter with all components
- `CompactLogFormatter` - Minimal output for high-volume logging
- `DetailedLogFormatter` - Full context for debugging
- `ColoredLogFormatter` - ANSI colors for terminal output
- `PatternLogFormatter` - Custom format patterns

### Log Outputs

- `ConsoleLogOutput` - stdout/stderr output
- `FileLogOutput` - File output with rotation
- `JsonLogOutput` - JSON lines format for log aggregation
- `CallbackLogOutput` - Custom handling via callback
- `MultiLogOutput` - Write to multiple destinations
- `FilteredLogOutput` - Filter records by predicate

## Testing

### Test Coverage

The package includes comprehensive test coverage:

| Test Category | Count | Description |
|---------------|-------|-------------|
| Unit Tests | 160 | Core components, protocol, routing |
| Integration Tests | 18 | IsolateHub, WorkerPool, health monitoring |
| RequestManager Tests | 10 | Task lifecycle, retries, cancellation |
| HealthMonitor Tests | 9 | Health checks, thresholds, callbacks |
| **Total** | **197** | |

Run tests:

```bash
dart test
```

### Testing Utilities

Import testing utilities for your own tests:

```dart
import 'package:isolate_orchestrator/testing.dart';

// Use MockWorker for unit tests
final worker = MockWorker<MyData>(
  context: mockContext,
  handler: (data, taskType, metadata) async => processedData,
  delay: Duration(milliseconds: 100),
);
```

## Architecture

See [design.md](design.md) for detailed architecture documentation.

## Changelog

### Latest Updates

**Bug Fixes**
- Fixed memory leak in HealthMonitor - pending pings now properly cleaned up when isolates unregister
- Fixed race condition in RequestManager retry logic - timer buckets correctly removed before re-adding
- Fixed resource leak in Worker shutdown - context now properly disposed
- Fixed hub communication - permanent broadcast stream listeners ensure pong responses are received
- Consolidated duplicate exception definitions into single `exception.dart`

**Performance**
- `submitBatch()` now processes tasks concurrently using `Future.wait()` instead of sequential submission

**Testing**
- Added 37 new tests (integration, RequestManager, HealthMonitor)
- Total test coverage: 197 tests

## License

MIT
