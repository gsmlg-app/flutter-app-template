/// A generic Dart package that provides a managed pool of long-running isolates.
///
/// Features:
/// - Centralized Hub for lifecycle management
/// - Type-safe message protocol
/// - Health monitoring and automatic restart
/// - Consistent hashing router
/// - Request-response correlation with timeout handling
/// - Cross-isolate logging with `logging` package integration
///
/// ## Usage
///
/// ```dart
/// import 'package:isolate_orchestrator/isolate_orchestrator.dart';
///
/// // Define your data type
/// class MyData {
///   final int value;
///   MyData(this.value);
/// }
///
/// // Define your worker
/// class MyWorker extends Worker<MyData> {
///   // ... implementation
/// }
///
/// // Entry point for worker isolate
/// void workerEntryPoint(SendPort hubPort) {
///   runWorker<MyData>(hubPort, (context) => MyWorker(context));
/// }
///
/// // Main application
/// void main() async {
///   final hub = IsolateHub();
///   await hub.start();
///
///   final pool = WorkerPool<MyData>(
///     hub: hub,
///     config: WorkerPoolConfig(minWorkers: 4),
///     workerEntryPoint: workerEntryPoint,
///   );
///
///   await pool.start();
///
///   // Submit tasks
///   final result = await pool.submit(MyData(42));
///
///   await pool.stop();
///   await hub.stop();
/// }
/// ```
library;

// Exceptions
export 'src/exception.dart';

// Health
export 'src/health/metrics.dart';
export 'src/health/monitor.dart';

// Hub
export 'src/hub/hub.dart';
export 'src/hub/lifecycle.dart';
export 'src/hub/registry.dart';
export 'src/hub/spawner.dart';

// Message
export 'src/message/address.dart';
export 'src/message/envelope.dart';
export 'src/message/id_generator.dart';
export 'src/message/protocol.dart';

// Pool
export 'src/pool/hash_ring.dart';
export 'src/pool/pool.dart';
export 'src/pool/router.dart';

// Request
export 'src/request/manager.dart';
export 'src/request/registry.dart';
export 'src/request/timer_wheel.dart';

// Worker
export 'src/worker/context.dart';
export 'src/worker/worker.dart';

// Logging
export 'src/logging/bridge.dart';
export 'src/logging/central.dart';
export 'src/logging/formatter.dart';
export 'src/logging/output.dart';
export 'src/logging/record.dart';
