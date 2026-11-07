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

  /// Handle a synchronous RPC `call` request from the Hub or another isolate.
  ///
  /// By default, if [request] is [TData], delegates to [onTask].
  /// Override this method to handle custom RPC message types.
  Future<Object?> onCall(
    Object? request, {
    required IsolateAddress sender,
    Map<String, dynamic>? metadata,
  }) async {
    if (request is TData) {
      return await onTask(request, metadata: metadata);
    }
    throw UnsupportedError(
      '$runtimeType does not implement onCall for ${request.runtimeType}',
    );
  }

  /// Handle an asynchronous fire-and-forget `cast` message from the Hub or another isolate.
  ///
  /// By default, if [message] is [TData], delegates to [onTask] and ignores the return value.
  /// Override this method to handle custom cast message types.
  Future<void> onCast(
    Object? message, {
    required IsolateAddress sender,
    Map<String, dynamic>? metadata,
  }) async {
    if (message is TData) {
      await onTask(message, metadata: metadata);
    }
  }

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
  Worker<TData> Function(WorkerContext context) createWorker, {
  String? name,
  String? role,
  List<String>? capabilities,
  List<String>? subscribesTo,
}) {
  final receivePort = ReceivePort();
  final idGenerator = MessageIdGenerator('worker');
  final spawnMeta = Zone.current[#isolateSpawnMeta] as Map<String, Object>?;

  Worker<TData>? worker;
  WorkerContext? context;
  String? workerId = spawnMeta?['id'] as String?;
  String? workerName = name ?? (spawnMeta?['name'] as String?);
  String? workerRole = role ?? (spawnMeta?['role'] as String?);
  final workerPath =
      (spawnMeta?['path'] as String?) ?? '/${workerName ?? 'worker'}';
  final regCapabilities =
      capabilities ??
      (spawnMeta?['capabilities'] as List<String>?) ??
      const <String>[];
  final regSubscribesTo =
      subscribesTo ??
      (spawnMeta?['subscribesTo'] as List<String>?) ??
      const <String>[];
  final dependencyPorts = <String, List<PortInfo>>{};

  // Send registration
  final regEnvelope = Envelope.create(
    id: idGenerator.next(),
    source: IsolateAddress.of(workerRole ?? 'worker', workerId ?? 'pending'),
    target: IsolateAddress.hub,
    payload: Register(
      name: workerName ?? 'worker',
      role: workerRole ?? 'worker',
      port: receivePort.sendPort,
      capabilities: regCapabilities,
      subscribesTo: regSubscribesTo,
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
        workerName ??= workerId;
        workerRole = envelope.target.role;

        // Build dependencies map
        final dependencies = <String, List<SendPort>>{};
        for (final entry in init.dependencies.entries) {
          dependencyPorts[entry.key] = List<PortInfo>.from(entry.value);
          dependencies[entry.key] = entry.value.map((p) => p.port).toList();
        }

        // Extract logger port from config if present
        final loggerPort = init.config['loggerPort'] as SendPort?;

        // Create context
        context = WorkerContext(
          id: workerId!,
          name: workerName!,
          role: workerRole!,
          path: workerPath,
          hubPort: hubPort,
          loggerPort: loggerPort,
          dependencies: dependencies,
          idGenerator: idGenerator,
          config: init.config,
          onSelfStop: () {
            unawaited(() async {
              try {
                await worker?.onShutdown();
              } finally {
                context?.dispose();
                receivePort.close();
              }
            }());
          },
        );

        // Seed P2P cache with initial dependency ports
        for (final entry in init.dependencies.entries) {
          if (entry.value.isNotEmpty) {
            context!.applyPortUpdate(
              PortUpdate(version: 0, role: entry.key, added: entry.value),
            );
          }
        }

        // Create and initialize worker
        try {
          worker = createWorker(context!);
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

      case RpcRequest rpcReq:
        if (worker == null) return;

        try {
          final result = await worker!.onCall(
            rpcReq.request,
            sender: envelope.source,
            metadata: rpcReq.metadata,
          );
          final responseEnvelope = envelope.reply(
            RpcResponse(result: result),
            id: idGenerator.next(),
          );
          envelope.replyTo?.send(responseEnvelope);
        } catch (e, stackTrace) {
          final errorEnvelope = envelope.reply(
            RpcError(
              code: e.runtimeType.toString(),
              message: e.toString(),
              stackTrace: stackTrace.toString(),
            ),
            id: idGenerator.next(),
          );
          envelope.replyTo?.send(errorEnvelope);
        }

      case CastMessage castMsg:
        if (worker == null) return;

        try {
          await worker!.onCast(
            castMsg.message,
            sender: envelope.source,
            metadata: castMsg.metadata,
          );
        } catch (e, stackTrace) {
          context?.severe('Error handling cast message', e, stackTrace);
        }

      case Shutdown():
        try {
          await worker?.onShutdown();
        } finally {
          // Dispose context to clean up log bridge and other resources
          context?.dispose();

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
        if (context != null) {
          final currentInfos = dependencyPorts.putIfAbsent(
            update.role,
            () => <PortInfo>[],
          );
          if (update.removed.isNotEmpty) {
            currentInfos.removeWhere((p) => update.removed.contains(p.id));
          }
          for (final added in update.added) {
            currentInfos.removeWhere((p) => p.id == added.id);
            currentInfos.add(added);
          }
          context!.dependencies[update.role] = currentInfos
              .map((p) => p.port)
              .toList();
          context!.applyPortUpdate(update);
        }

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
  DateTime _startTime = DateTime.now();

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
