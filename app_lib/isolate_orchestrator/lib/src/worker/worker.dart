import 'dart:async';
import 'dart:isolate';

import '../health/metrics.dart';
import '../message/address.dart';
import '../message/envelope.dart';
import '../message/id_generator.dart';
import '../message/protocol.dart';
import 'context.dart';

/// Base class for worker implementation.
///
/// [TData] is the application-specific data type this worker processes.
abstract class Worker<TData> {
  /// Worker context with dependencies.
  WorkerContext get context;

  /// Initialize worker.
  Future<void> onInit(Map<String, dynamic> config);

  /// Process task.
  ///
  /// Receives unwrapped data from [Task<TData>], returns data for [TaskResult<TData>].
  /// Throw exception to return [TaskError].
  Future<TData> onTask(
    TData data, {
    String? taskType,
    Map<String, dynamic>? metadata,
  });

  /// Get current metrics.
  IsolateMetrics onHealthCheck();

  /// Cleanup on shutdown.
  Future<void> onShutdown();
}

/// Standard worker entry point helper.
///
/// Use this function to create a properly configured worker isolate.
void runWorker<TData>(
  SendPort hubPort,
  Worker<TData> Function(WorkerContext context) createWorker,
) {
  final receivePort = ReceivePort();
  final idGenerator = MessageIdGenerator('worker');

  Worker<TData>? worker;
  late WorkerContext context;
  String? workerId;
  String? workerName;
  String? workerRole;

  // Send registration
  final regEnvelope = Envelope.create(
    id: idGenerator.next(),
    source: IsolateAddress.of('worker', 'pending'),
    target: IsolateAddress.hub,
    payload: Register(
      name: 'worker',
      role: 'worker',
      port: receivePort.sendPort,
    ),
  );
  hubPort.send(regEnvelope);

  receivePort.listen((message) async {
    if (message is! Envelope) return;

    final envelope = message;
    final payload = envelope.payload;

    switch (payload) {
      case Init init:
        // Extract worker info from target address
        workerId = envelope.target.id;
        workerName = workerId;
        workerRole = envelope.target.role;

        // Build dependencies map
        final dependencies = <String, List<SendPort>>{};
        for (final entry in init.dependencies.entries) {
          dependencies[entry.key] = entry.value.map((p) => p.port).toList();
        }

        // Extract logger port from config if present
        final loggerPort = init.config['loggerPort'] as SendPort?;

        // Create context
        context = WorkerContext(
          id: workerId!,
          name: workerName!,
          role: workerRole!,
          hubPort: hubPort,
          loggerPort: loggerPort,
          dependencies: dependencies,
          idGenerator: idGenerator,
          config: init.config,
        );

        // Create and initialize worker
        try {
          worker = createWorker(context);
          await worker!.onInit(init.config);

          // Send ready
          final readyEnvelope = Envelope.create(
            id: idGenerator.next(),
            source: IsolateAddress.of(workerRole!, workerId!),
            target: IsolateAddress.hub,
            payload: Ready.ok(),
          );
          hubPort.send(readyEnvelope);
        } catch (e, stackTrace) {
          // Send failure
          final failEnvelope = Envelope.create(
            id: idGenerator.next(),
            source: IsolateAddress.of(
              workerRole ?? 'worker',
              workerId ?? 'unknown',
            ),
            target: IsolateAddress.hub,
            payload: Ready.failed('$e\n$stackTrace'),
          );
          hubPort.send(failEnvelope);
        }

      case Ping ping:
        if (worker == null) return;

        final metrics = worker!.onHealthCheck();
        final pongEnvelope = Envelope.create(
          id: idGenerator.next(),
          source: IsolateAddress.of(workerRole!, workerId!),
          target: IsolateAddress.hub,
          payload: Pong(seq: ping.seq, metrics: metrics),
        );
        hubPort.send(pongEnvelope);

      case Task task:
        if (worker == null) return;

        try {
          // Cast data to TData - generic type info is lost after SendPort transfer
          final data = task.data as TData;
          final result = await worker!.onTask(
            data,
            taskType: task.taskType,
            metadata: task.metadata,
          );

          final resultEnvelope = envelope.reply(
            TaskResult<TData>(data: result),
            id: idGenerator.next(),
          );
          envelope.replyTo?.send(resultEnvelope);
        } catch (e, stackTrace) {
          final errorEnvelope = envelope.reply(
            TaskError(
              code: e.runtimeType.toString(),
              message: e.toString(),
              stackTrace: stackTrace.toString(),
            ),
            id: idGenerator.next(),
          );
          envelope.replyTo?.send(errorEnvelope);
        }

      case TaskBatch batch:
        if (worker == null) return;

        final results = <TaskResultOrError<TData>>[];
        for (final task in batch.tasks) {
          try {
            // Cast data to TData - generic type info is lost after SendPort transfer
            final data = task.data as TData;
            final result = await worker!.onTask(
              data,
              taskType: task.taskType,
              metadata: task.metadata,
            );
            results.add(TaskSuccess<TData>(result));
          } catch (e, stackTrace) {
            results.add(
              TaskFailure<TData>(
                TaskError(
                  code: e.runtimeType.toString(),
                  message: e.toString(),
                  stackTrace: stackTrace.toString(),
                ),
              ),
            );
          }
        }

        final batchResultEnvelope = envelope.reply(
          TaskBatchResult<TData>(results),
          id: idGenerator.next(),
        );
        envelope.replyTo?.send(batchResultEnvelope);

      case Shutdown():
        try {
          await worker?.onShutdown();
        } finally {
          // Dispose context to clean up log bridge and other resources
          context.dispose();

          final ackEnvelope = Envelope.create(
            id: idGenerator.next(),
            source: IsolateAddress.of(
              workerRole ?? 'worker',
              workerId ?? 'unknown',
            ),
            target: IsolateAddress.hub,
            payload: ShutdownAck(pendingTasks: 0, flushed: true),
          );
          hubPort.send(ackEnvelope);
          receivePort.close();
        }

      case PortUpdate update:
        // Handle port updates for dependencies
        // Could be used for worker-to-worker communication
        final ackEnvelope = Envelope.create(
          id: idGenerator.next(),
          source: IsolateAddress.of(
            workerRole ?? 'worker',
            workerId ?? 'unknown',
          ),
          target: IsolateAddress.hub,
          payload: PortUpdateAck(version: update.version),
        );
        hubPort.send(ackEnvelope);

      default:
        // Unknown message type, ignore
        break;
    }
  });
}

/// Mixin for tracking worker metrics.
mixin WorkerMetricsMixin<TData> on Worker<TData> {
  int _processedCount = 0;
  int _errorCount = 0;
  int _totalLatencyUs = 0;
  late DateTime _startTime;

  /// Initialize metrics tracking.
  void initMetrics() {
    _startTime = DateTime.now();
  }

  /// Record successful task processing.
  void recordSuccess(Duration latency) {
    _processedCount++;
    _totalLatencyUs += latency.inMicroseconds;
  }

  /// Record task error.
  void recordError() {
    _errorCount++;
  }

  /// Get average latency in microseconds.
  int get avgLatencyUs =>
      _processedCount > 0 ? _totalLatencyUs ~/ _processedCount : 0;

  @override
  IsolateMetrics onHealthCheck() {
    return IsolateMetrics(
      uptimeMs: DateTime.now().difference(_startTime).inMilliseconds,
      processedCount: _processedCount,
      pendingCount: 0,
      errorCount: _errorCount,
      avgLatencyUs: avgLatencyUs,
    );
  }
}
