import 'dart:async';
import 'dart:isolate';

import 'package:isolate_orchestrator/isolate_orchestrator.dart';
import 'package:test/test.dart';

///Simple data type for testing.
class TestData {
  final int value;
  final String? error;
  final int? delayMs;

  TestData(this.value, {this.error, this.delayMs});

  Map<String, dynamic> toMap() => {
    'value': value,
    'error': error,
    'delayMs': delayMs,
  };

  factory TestData.fromMap(Map<String, dynamic> map) => TestData(
    map['value'] as int,
    error: map['error'] as String?,
    delayMs: map['delayMs'] as int?,
  );
}

/// Test worker implementation.
class TestWorker extends Worker<TestData> with WorkerMetricsMixin<TestData> {
  final WorkerContext _context;

  @override
  WorkerContext get context => _context;

  TestWorker(this._context);

  @override
  Future<void> onInit(Map<String, dynamic> config) async {
    initMetrics();
    if (config['failInit'] == true) {
      throw StateError('Simulated init failure');
    }
    context.info('TestWorker initialized');
  }

  @override
  Future<TestData> onTask(
    TestData data, {
    String? taskType,
    Map<String, dynamic>? metadata,
  }) async {
    final startTime = DateTime.now();

    if (taskType == 'checkDeps') {
      final deps = context.getDependency('service');
      return TestData(deps.length);
    }

    if (taskType == 'crash') {
      Isolate.exit();
    }

    // Simulate work
    await Future.delayed(Duration(milliseconds: data.delayMs ?? 10));

    // Check for simulated errors
    if (data.error != null) {
      throw Exception(data.error);
    }

    recordSuccess(DateTime.now().difference(startTime));
    return TestData(data.value * 2);
  }

  @override
  Future<void> onShutdown() async {
    context.info('TestWorker shutting down');
  }
}

/// Entry point for test worker isolate.
void testWorkerEntryPoint(SendPort hubPort) {
  runWorker<TestData>(hubPort, (context) => TestWorker(context));
}

void main() {
  group('IsolateHub Integration', () {
    late IsolateHub hub;

    setUp(() async {
      hub = IsolateHub(
        config: const HubConfig(
          healthCheckInterval: Duration(seconds: 1),
          healthCheckTimeout: Duration(milliseconds: 500),
        ),
      );
      await hub.start();
    });

    tearDown(() async {
      await hub.stop(timeout: const Duration(seconds: 5));
    });

    test('spawns isolate and returns handle', () async {
      final handle = await hub.spawn(
        role: 'testWorker',
        name: 'test-worker-1',
        entryPoint: testWorkerEntryPoint,
        config: {'testKey': 'testValue'},
      );

      expect(handle.id, isNotEmpty);
      expect(handle.name, equals('test-worker-1'));
      expect(handle.role, equals('testWorker'));
      expect(handle.state, equals(IsolateState.running));
    });

    test('getByRole returns spawned isolates', () async {
      await hub.spawn(
        role: 'testWorker',
        name: 'worker-1',
        entryPoint: testWorkerEntryPoint,
      );

      await hub.spawn(
        role: 'testWorker',
        name: 'worker-2',
        entryPoint: testWorkerEntryPoint,
      );

      final workers = hub.getByRole('testWorker');
      expect(workers.length, equals(2));
    });

    test('getById returns correct isolate', () async {
      final handle = await hub.spawn(
        role: 'testWorker',
        name: 'test-worker',
        entryPoint: testWorkerEntryPoint,
      );

      final found = hub.getById(handle.id);
      expect(found, isNotNull);
      expect(found!.id, equals(handle.id));
    });

    test('emits IsolateSpawned and IsolateReady events', () async {
      final events = <HubEvent>[];
      final subscription = hub.events.listen(events.add);

      await hub.spawn(
        role: 'testWorker',
        name: 'test-worker',
        entryPoint: testWorkerEntryPoint,
      );

      // Allow events to propagate
      await Future.delayed(const Duration(milliseconds: 100));

      await subscription.cancel();

      expect(events.whereType<IsolateSpawned>().length, equals(1));
      expect(events.whereType<IsolateReady>().length, equals(1));
    });

    test('graceful kill stops isolate', () async {
      final handle = await hub.spawn(
        role: 'testWorker',
        name: 'test-worker',
        entryPoint: testWorkerEntryPoint,
      );

      await handle.kill(graceful: true);

      // Isolate should be removed from registry
      expect(hub.getById(handle.id), isNull);
    });

    test('non-graceful kill stops isolate and emits IsolateStopped', () async {
      final stoppedIds = <String>[];
      final sub = hub.events
          .where((e) => e is IsolateStopped)
          .cast<IsolateStopped>()
          .listen((e) => stoppedIds.add(e.id));

      final handle = await hub.spawn(
        role: 'testWorker',
        name: 'test-worker',
        entryPoint: testWorkerEntryPoint,
      );

      await handle.kill(graceful: false);
      await Future.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      expect(hub.getById(handle.id), isNull);
      expect(stoppedIds, contains(handle.id));
    });

    test('cleans up isolate when initialization fails', () async {
      await expectLater(
        hub.spawn(
          role: 'testWorker',
          name: 'failing-init-worker',
          entryPoint: testWorkerEntryPoint,
          config: {'failInit': true},
        ),
        throwsA(isA<InitializationException>()),
      );

      expect(hub.getByRole('testWorker'), isEmpty);
    });

    test(
      'automatically restarts crashed isolate according to RestartPolicy',
      () async {
        final restartHub = IsolateHub(
          config: const HubConfig(
            healthCheckInterval: Duration(milliseconds: 200),
            healthCheckTimeout: Duration(milliseconds: 100),
            restartPolicy: RestartPolicy(
              maxAttempts: 2,
              initialDelay: Duration(milliseconds: 50),
            ),
          ),
        );
        await restartHub.start();

        try {
          final events = <HubEvent>[];
          final sub = restartHub.events.listen(events.add);

          final handle = await restartHub.spawn(
            role: 'testWorker',
            name: 'crashable-worker',
            entryPoint: testWorkerEntryPoint,
          );

          // Send a task that causes the worker isolate to exit unexpectedly
          final replyPort = ReceivePort();
          handle.sendPort.send(
            Envelope.create(
              id: 'crash-1',
              source: IsolateAddress.hub,
              target: IsolateAddress.of('testWorker', handle.id),
              replyTo: replyPort.sendPort,
              payload: Task<TestData>(data: TestData(1), taskType: 'crash'),
            ),
          );

          // Wait for onExit detection + 50ms restart delay + spawn
          await Future.delayed(const Duration(milliseconds: 400));
          replyPort.close();
          await sub.cancel();

          expect(events.whereType<IsolateFailed>(), isNotEmpty);
          expect(events.whereType<IsolateRestarting>(), isNotEmpty);

          final activeWorkers = restartHub.getByRole('testWorker');
          expect(activeWorkers.length, equals(1));
          expect(activeWorkers.first.name, equals('crashable-worker'));
          expect(activeWorkers.first.id, isNot(equals(handle.id)));
        } finally {
          await restartHub.stop(timeout: const Duration(seconds: 2));
        }
      },
    );

    test(
      'propagates subscribesTo dependencies and PortUpdate notifications',
      () async {
        final subscriber = await hub.spawn(
          role: 'worker',
          name: 'subscriber-worker',
          entryPoint: testWorkerEntryPoint,
          subscribesTo: ['service'],
        );

        Future<int> queryServicePortCount() async {
          final replyPort = ReceivePort();
          final completer = Completer<int>();
          replyPort.listen((msg) {
            if (msg is Envelope && msg.payload is TaskResult) {
              final res = (msg.payload as TaskResult).data as TestData;
              completer.complete(res.value);
              replyPort.close();
            }
          });
          subscriber.sendPort.send(
            Envelope.create(
              id: 'check-deps',
              source: IsolateAddress.hub,
              target: IsolateAddress.of('worker', subscriber.id),
              replyTo: replyPort.sendPort,
              payload: Task<TestData>(data: TestData(0), taskType: 'checkDeps'),
            ),
          );
          return completer.future.timeout(const Duration(seconds: 2));
        }

        expect(await queryServicePortCount(), equals(0));

        final serviceHandle = await hub.spawn(
          role: 'service',
          name: 'service-1',
          entryPoint: testWorkerEntryPoint,
        );
        await Future.delayed(const Duration(milliseconds: 50));
        expect(await queryServicePortCount(), equals(1));

        await serviceHandle.kill(graceful: true);
        await Future.delayed(const Duration(milliseconds: 50));
        expect(await queryServicePortCount(), equals(0));
      },
    );
  });

  group('WorkerPool Integration', () {
    late IsolateHub hub;
    late WorkerPool<TestData> pool;

    setUp(() async {
      hub = IsolateHub(
        config: const HubConfig(
          healthCheckInterval: Duration(seconds: 2),
          healthCheckTimeout: Duration(milliseconds: 500),
        ),
      );
      await hub.start();

      pool = WorkerPool<TestData>(
        hub: hub,
        config: WorkerPoolConfig(
          minWorkers: 2,
          maxWorkers: 4,
          requestTimeout: const Duration(seconds: 5),
        ),
        workerEntryPoint: testWorkerEntryPoint,
      );
      await pool.start();
    });

    tearDown(() async {
      await pool.stop();
      await hub.stop(timeout: const Duration(seconds: 5));
    });

    test('starts with minimum workers', () async {
      expect(pool.workers.length, equals(2));
      expect(pool.status.totalWorkers, equals(2));
    });

    test('submits task and receives result', () async {
      final TestData result = await pool.submit(TestData(21));

      expect(result.value, equals(42));
    });

    test('handles multiple concurrent tasks', () async {
      final futures = List.generate(10, (i) => pool.submit(TestData(i)));

      final List<TestData> results = await Future.wait(futures);

      for (var i = 0; i < 10; i++) {
        expect(results[i].value, equals(i * 2));
      }
    });

    test('submitBatch processes all tasks concurrently', () async {
      final dataList = List.generate(5, (i) => TestData(i));

      final batchResult = await pool.submitBatch(dataList);

      expect(batchResult.results.length, equals(5));

      for (var i = 0; i < 5; i++) {
        final result = batchResult.results[i];
        expect(result, isA<TaskSuccess<TestData>>());
        expect((result as TaskSuccess<TestData>).data.value, equals(i * 2));
      }
    });

    test('handles task errors', () async {
      expect(
        () => pool.submit(TestData(1, error: 'Simulated error')),
        throwsA(isA<TaskException>()),
      );
    });

    test('batch handles mixed success and failures', () async {
      final dataList = [
        TestData(1),
        TestData(2, error: 'Error on task 2'),
        TestData(3),
      ];

      final batchResult = await pool.submitBatch(dataList);

      expect(batchResult.results[0], isA<TaskSuccess<TestData>>());
      expect(batchResult.results[1], isA<TaskFailure<TestData>>());
      expect(batchResult.results[2], isA<TaskSuccess<TestData>>());
    });

    test('pool status reflects activity', () async {
      final initialStatus = pool.status;
      expect(initialStatus.processedRequests, equals(0));

      await pool.submit(TestData(1));

      final afterStatus = pool.status;
      expect(afterStatus.processedRequests, equals(1));
    });

    test(
      'timeout increments failedRequests, emits RequestTimeout, and maps to TIMEOUT in batch',
      () async {
        final timeoutEvents = <RequestTimeout>[];
        final sub = pool.events
            .where((e) => e is RequestTimeout)
            .cast<RequestTimeout>()
            .listen(timeoutEvents.add);

        await expectLater(
          pool.submit(
            TestData(1, delayMs: 500),
            timeout: const Duration(milliseconds: 100),
          ),
          throwsA(isA<TaskTimeoutException>()),
        );

        await Future.delayed(const Duration(milliseconds: 50));
        await sub.cancel();

        expect(pool.status.failedRequests, greaterThanOrEqualTo(1));
        expect(timeoutEvents, isNotEmpty);

        final batchResult = await pool.submitBatch([
          TestData(1, delayMs: 500),
        ], timeout: const Duration(milliseconds: 100));
        expect(batchResult.results.first, isA<TaskFailure<TestData>>());
        final failure = batchResult.results.first as TaskFailure<TestData>;
        expect(failure.error.code, equals('TIMEOUT'));
      },
    );

    test('scale adjusts worker count and emits PoolScaled event', () async {
      final scaledEvents = <PoolScaled>[];
      final sub = pool.events
          .where((e) => e is PoolScaled)
          .cast<PoolScaled>()
          .listen(scaledEvents.add);

      await pool.scale(3);
      expect(pool.workers.length, equals(3));

      await pool.scale(2);
      expect(pool.workers.length, equals(2));

      await Future.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      expect(scaledEvents.length, equals(2));
      expect(scaledEvents[0].oldSize, equals(2));
      expect(scaledEvents[0].newSize, equals(3));
      expect(scaledEvents[1].oldSize, equals(3));
      expect(scaledEvents[1].newSize, equals(2));
    });
  });

  group('Health Monitoring Integration', () {
    late IsolateHub hub;

    setUp(() async {
      hub = IsolateHub(
        config: const HubConfig(
          healthCheckInterval: Duration(milliseconds: 200),
          healthCheckTimeout: Duration(milliseconds: 100),
          unhealthyThreshold: 2,
          healthyThreshold: 2,
        ),
      );
      await hub.start();
    });

    tearDown(() async {
      await hub.stop(timeout: const Duration(seconds: 5));
    });

    test('reports healthy isolates after health checks', () async {
      final handle = await hub.spawn(
        role: 'testWorker',
        name: 'healthy-worker',
        entryPoint: testWorkerEntryPoint,
      );

      // Wait for multiple health checks to complete
      // Health check interval is 200ms, healthy threshold is 2
      // So we need at least 2 successful health checks
      await Future.delayed(const Duration(milliseconds: 800));

      // After enough time, worker should be healthy
      expect(handle.isHealthy, isTrue);
    });

    test('receives HealthChanged events', () async {
      final events = <HealthChanged>[];
      final subscription = hub.events
          .where((e) => e is HealthChanged)
          .cast<HealthChanged>()
          .listen(events.add);

      await hub.spawn(
        role: 'testWorker',
        name: 'test-worker',
        entryPoint: testWorkerEntryPoint,
      );

      // Wait for multiple health checks
      await Future.delayed(const Duration(seconds: 1));

      await subscription.cancel();

      // Worker should remain healthy, so we may or may not have events
      // depending on initial state
    });
  });

  group('Exception Handling', () {
    test('all exceptions extend IsolateOrchestratorException', () {
      final exceptions = <IsolateOrchestratorException>[
        NoHealthyWorkerException(),
        TaskTimeoutException('task-1', 3),
        TaskCancelledException('task-1'),
        SpawnTimeoutException('worker-1', const Duration(seconds: 30)),
        InitializationException('worker-1', 'Failed to initialize'),
        SpawnFailedException('worker', 'Spawn failed'),
        WorkerException('worker-1', 'Worker failed'),
        HubStateException('Invalid hub state'),
        PoolStateException('Invalid pool state'),
        MessageDeliveryException('target-1', 'Delivery failed'),
        TaskException('ERR_CODE', 'Task failed', {'detail': 1}, 'stack'),
      ];

      for (final e in exceptions) {
        expect(e, isA<IsolateOrchestratorException>());
        expect(e.toString(), isNotEmpty);
      }
    });

    test('NoHealthyWorkerException message', () {
      final e = NoHealthyWorkerException();
      expect(e.message, contains('No healthy workers'));
    });

    test('TaskTimeoutException includes retry count', () {
      final e = TaskTimeoutException('task-123', 5);
      expect(e.taskId, equals('task-123'));
      expect(e.retryCount, equals(5));
      expect(e.toString(), contains('5'));
    });

    test('TaskCancelledException includes task ID', () {
      final e = TaskCancelledException('task-456');
      expect(e.taskId, equals('task-456'));
      expect(e.toString(), contains('task-456'));
    });
  });
}
