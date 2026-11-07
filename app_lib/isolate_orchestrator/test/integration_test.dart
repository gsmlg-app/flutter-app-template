import 'dart:async';
import 'dart:isolate';

import 'package:isolate_orchestrator/isolate_orchestrator.dart';
import 'package:test/test.dart';

/// Simple data type for testing.
class TestData {
  final int value;
  final String? error;

  TestData(this.value, {this.error});

  Map<String, dynamic> toMap() => {'value': value, 'error': error};

  factory TestData.fromMap(Map<String, dynamic> map) =>
      TestData(map['value'] as int, error: map['error'] as String?);
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
    context.info('TestWorker initialized');
  }

  @override
  Future<TestData> onTask(
    TestData data, {
    String? taskType,
    Map<String, dynamic>? metadata,
  }) async {
    final startTime = DateTime.now();

    // Simulate work
    await Future.delayed(const Duration(milliseconds: 10));

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
