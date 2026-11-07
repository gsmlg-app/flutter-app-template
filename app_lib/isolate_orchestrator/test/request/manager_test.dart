import 'dart:async';
import 'dart:isolate';

import 'package:isolate_orchestrator/isolate_orchestrator.dart';
import 'package:test/test.dart';

/// Mock router for testing.
class MockRouter<T> implements Router<T> {
  final List<WorkerPort> _workers = [];
  String? selectReturns;
  bool selectThrows = false;
  final Map<String, int> successCount = {};
  final Map<String, int> failureCount = {};

  @override
  WorkerPort? select(T data, {Set<String>? exclude}) {
    if (selectThrows) throw StateError('Router error');
    if (selectReturns == null) return null;
    if (exclude?.contains(selectReturns) == true) return null;
    return _workers.firstWhere(
      (w) => w.id == selectReturns,
      orElse: () => throw StateError('Worker not found'),
    );
  }

  @override
  void recordSuccess(String workerId, Duration latency) {
    successCount[workerId] = (successCount[workerId] ?? 0) + 1;
  }

  @override
  void recordFailure(String workerId) {
    failureCount[workerId] = (failureCount[workerId] ?? 0) + 1;
  }

  @override
  void updateWorkers(List<PortInfo> workers) {
    _workers.clear();
    for (final w in workers) {
      _workers.add(
        WorkerPort(
          id: w.id,
          port: w.port,
          healthy: true,
          pendingCount: 0,
          avgLatencyUs: 0,
        ),
      );
    }
  }

  @override
  List<WorkerPort> get workers => List.unmodifiable(_workers);

  void addWorker(WorkerPort worker) {
    _workers.add(worker);
    selectReturns ??= worker.id;
  }
}

void main() {
  group('RequestManager', () {
    late RequestManager<int> manager;
    late MockRouter<int> router;
    late ReceivePort replyPort;
    late MessageIdGenerator idGenerator;

    setUp(() {
      router = MockRouter<int>();
      replyPort = ReceivePort();
      idGenerator = MessageIdGenerator('test');
      manager = RequestManager<int>(
        defaultTimeout: const Duration(seconds: 5),
        maxRetries: 2,
        router: router,
        idGenerator: idGenerator,
        replyPort: replyPort.sendPort,
        tickDuration: const Duration(milliseconds: 50),
        wheelSize: 32,
      );
    });

    tearDown(() {
      manager.dispose();
      replyPort.close();
    });

    test('pendingCount starts at 0', () {
      expect(manager.pendingCount, equals(0));
    });

    test('submit throws NoHealthyWorkerException when no worker', () async {
      router.selectReturns = null;

      expect(
        () => manager.submit(Task<int>(data: 42)),
        throwsA(isA<NoHealthyWorkerException>()),
      );
    });

    test('submit sends task to worker and waits for response', () async {
      // Set up worker
      final workerReceivePort = ReceivePort();
      router.addWorker(
        WorkerPort(
          id: 'worker-1',
          port: workerReceivePort.sendPort,
          healthy: true,
          pendingCount: 0,
          avgLatencyUs: 0,
        ),
      );
      router.selectReturns = 'worker-1';

      // Listen for task on worker side
      Envelope? receivedEnvelope;
      workerReceivePort.listen((message) {
        receivedEnvelope = message as Envelope;
        // Simulate worker sending response
        final response = receivedEnvelope!.reply(
          TaskResult<int>(data: 84),
          id: 'resp-1',
        );
        manager.handleResponse(response);
      });

      // Submit task
      final result = await manager.submit(Task<int>(data: 42));

      expect(result.data, equals(84));
      expect(receivedEnvelope, isNotNull);
      expect((receivedEnvelope!.payload as Task).data, equals(42));

      workerReceivePort.close();
    });

    test('handleResponse completes task with TaskResult', () async {
      final workerReceivePort = ReceivePort();
      router.addWorker(
        WorkerPort(
          id: 'worker-1',
          port: workerReceivePort.sendPort,
          healthy: true,
          pendingCount: 0,
          avgLatencyUs: 0,
        ),
      );
      router.selectReturns = 'worker-1';

      String? correlationId;
      workerReceivePort.listen((message) {
        final envelope = message as Envelope;
        correlationId = envelope.correlationId;
      });

      // Start task
      final resultFuture = manager.submit(Task<int>(data: 42));

      // Wait for task to be sent
      await Future.delayed(const Duration(milliseconds: 50));

      expect(manager.pendingCount, equals(1));

      // Simulate response
      final responseEnvelope = Envelope.create(
        id: 'resp-1',
        correlationId: correlationId,
        source: IsolateAddress.of('worker', 'worker-1'),
        target: IsolateAddress.of('pool', 'pool'),
        payload: TaskResult<int>(data: 100),
      );
      manager.handleResponse(responseEnvelope);

      final result = await resultFuture;
      expect(result.data, equals(100));
      expect(manager.pendingCount, equals(0));

      workerReceivePort.close();
    });

    test('handleResponse records success in router', () async {
      final workerReceivePort = ReceivePort();
      router.addWorker(
        WorkerPort(
          id: 'worker-1',
          port: workerReceivePort.sendPort,
          healthy: true,
          pendingCount: 0,
          avgLatencyUs: 0,
        ),
      );
      router.selectReturns = 'worker-1';

      String? correlationId;
      workerReceivePort.listen((message) {
        correlationId = (message as Envelope).correlationId;
      });

      // Start task
      final resultFuture = manager.submit(Task<int>(data: 42));
      await Future.delayed(const Duration(milliseconds: 50));

      // Simulate success response
      final responseEnvelope = Envelope.create(
        id: 'resp-1',
        correlationId: correlationId,
        source: IsolateAddress.of('worker', 'worker-1'),
        target: IsolateAddress.of('pool', 'pool'),
        payload: TaskResult<int>(data: 100),
      );
      manager.handleResponse(responseEnvelope);

      await resultFuture;
      expect(router.successCount['worker-1'], equals(1));

      workerReceivePort.close();
    });

    test('handleResponse completes with error on TaskError', () async {
      final workerReceivePort = ReceivePort();
      router.addWorker(
        WorkerPort(
          id: 'worker-1',
          port: workerReceivePort.sendPort,
          healthy: true,
          pendingCount: 0,
          avgLatencyUs: 0,
        ),
      );
      router.selectReturns = 'worker-1';

      String? correlationId;
      workerReceivePort.listen((message) {
        correlationId = (message as Envelope).correlationId;
      });

      // Start task
      final resultFuture = manager.submit(Task<int>(data: 42));
      await Future.delayed(const Duration(milliseconds: 50));

      // Simulate error response
      final responseEnvelope = Envelope.create(
        id: 'resp-1',
        correlationId: correlationId,
        source: IsolateAddress.of('worker', 'worker-1'),
        target: IsolateAddress.of('pool', 'pool'),
        payload: TaskError(code: 'TEST_ERROR', message: 'Test error'),
      );
      manager.handleResponse(responseEnvelope);

      expect(resultFuture, throwsA(isA<TaskError>()));
      expect(router.failureCount['worker-1'], equals(1));

      workerReceivePort.close();
    });

    test('handleResponse ignores messages without correlationId', () {
      final envelope = Envelope.create(
        id: 'msg-1',
        source: IsolateAddress.of('worker', 'worker-1'),
        target: IsolateAddress.of('pool', 'pool'),
        payload: TaskResult<int>(data: 100),
      );

      // Should not throw
      manager.handleResponse(envelope);
    });

    test('cancel removes pending task and completes with error', () async {
      final workerReceivePort = ReceivePort();
      router.addWorker(
        WorkerPort(
          id: 'worker-1',
          port: workerReceivePort.sendPort,
          healthy: true,
          pendingCount: 0,
          avgLatencyUs: 0,
        ),
      );
      router.selectReturns = 'worker-1';

      String? taskId;
      workerReceivePort.listen((message) {
        taskId = (message as Envelope).id;
      });

      // Start task
      final resultFuture = manager.submit(Task<int>(data: 42));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(manager.pendingCount, equals(1));

      // Cancel task
      manager.cancel(taskId!);

      expect(manager.pendingCount, equals(0));
      expect(resultFuture, throwsA(isA<TaskCancelledException>()));

      workerReceivePort.close();
    });

    test('cancelAll cancels all pending tasks', () async {
      final workerReceivePort = ReceivePort();
      router.addWorker(
        WorkerPort(
          id: 'worker-1',
          port: workerReceivePort.sendPort,
          healthy: true,
          pendingCount: 0,
          avgLatencyUs: 0,
        ),
      );
      router.selectReturns = 'worker-1';

      workerReceivePort.listen((_) {}); // consume messages

      // Start multiple tasks
      final futures = [
        manager.submit(Task<int>(data: 1)),
        manager.submit(Task<int>(data: 2)),
        manager.submit(Task<int>(data: 3)),
      ];

      await Future.delayed(const Duration(milliseconds: 50));
      expect(manager.pendingCount, equals(3));

      // Cancel all
      manager.cancelAll();

      expect(manager.pendingCount, equals(0));

      for (final future in futures) {
        expect(future, throwsA(isA<TaskCancelledException>()));
      }

      workerReceivePort.close();
    });
  });

  group('RequestManager timeout behavior', () {
    late RequestManager<int> manager;
    late MockRouter<int> router;
    late ReceivePort replyPort;
    late MessageIdGenerator idGenerator;

    setUp(() {
      router = MockRouter<int>();
      replyPort = ReceivePort();
      idGenerator = MessageIdGenerator('test');
      // maxRetries: 0 means no retries, timeout fails immediately
      manager = RequestManager<int>(
        defaultTimeout: const Duration(milliseconds: 100),
        maxRetries: 0,
        router: router,
        idGenerator: idGenerator,
        replyPort: replyPort.sendPort,
        tickDuration: const Duration(milliseconds: 20),
        wheelSize: 16,
      );
    });

    tearDown(() {
      manager.dispose();
      replyPort.close();
    });

    test('timeout triggers TaskTimeoutException when no retries', () async {
      final workerReceivePort = ReceivePort();
      router.addWorker(
        WorkerPort(
          id: 'worker-1',
          port: workerReceivePort.sendPort,
          healthy: true,
          pendingCount: 0,
          avgLatencyUs: 0,
        ),
      );
      router.selectReturns = 'worker-1';

      workerReceivePort.listen((_) {}); // consume but don't respond

      expect(
        () => manager.submit(
          Task<int>(data: 42),
          timeout: const Duration(milliseconds: 100),
        ),
        throwsA(isA<TaskTimeoutException>()),
      );

      workerReceivePort.close();
    });
  });
}
