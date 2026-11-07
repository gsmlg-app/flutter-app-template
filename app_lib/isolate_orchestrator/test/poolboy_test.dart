import 'dart:async';
import 'dart:isolate';

import 'package:isolate_orchestrator/isolate_orchestrator.dart';
import 'package:test/test.dart';

class PoolTask {
  final String op;
  final int value;
  final int delayMs;
  final String? workerId;

  PoolTask(this.op, {this.value = 0, this.delayMs = 0, this.workerId});
}

class PoolTestWorker extends Worker<PoolTask>
    with WorkerMetricsMixin<PoolTask> {
  @override
  final WorkerContext context;

  int _sessionCounter = 0;

  PoolTestWorker(this.context);

  @override
  Future<void> onInit(Map<String, dynamic> config) async {
    initMetrics();
  }

  @override
  Future<PoolTask> onTask(
    PoolTask data, {
    String? taskType,
    Map<String, dynamic>? metadata,
  }) async {
    if (data.delayMs > 0) {
      await Future.delayed(Duration(milliseconds: data.delayMs));
    }

    switch (data.op) {
      case 'crash':
        Isolate.exit();
      case 'inc':
        _sessionCounter += data.value;
        return PoolTask('result', value: _sessionCounter, workerId: context.id);
      case 'reset':
        _sessionCounter = 0;
        return PoolTask('result', value: 0, workerId: context.id);
      default:
        return PoolTask('result', value: data.value * 2, workerId: context.id);
    }
  }

  @override
  Future<void> onShutdown() async {}
}

void poolTestWorkerEntryPoint(SendPort hubPort) {
  runWorker<PoolTask>(hubPort, (ctx) => PoolTestWorker(ctx));
}

Future<void> _waitForCondition(
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!predicate()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('Condition not met within $timeout');
    }
    await Future.delayed(const Duration(milliseconds: 25));
  }
}

void main() {
  group('Erlang Poolboy-Style WorkerPool / IsolatePool', () {
    late IsolateHub hub;

    setUp(() async {
      hub = IsolateHub(
        config: const HubConfig(
          healthCheckInterval: Duration(seconds: 5),
          healthCheckTimeout: Duration(seconds: 2),
          restartPolicy: RestartPolicy(
            maxAttempts: 5,
            initialDelay: Duration(milliseconds: 20),
          ),
        ),
      );
      await hub.start();
    });

    tearDown(() async {
      await hub.stop(timeout: const Duration(seconds: 3));
    });

    test(
      'checkout, exclusive multi-step execution, and checkin lifecycle',
      () async {
        final pool = IsolatePool<PoolTask>(
          hub: hub,
          config: const IsolatePoolConfig(size: 2, maxOverflow: 0),
          workerEntryPoint: poolTestWorkerEntryPoint,
        );
        await pool.start();

        try {
          expect(pool.status.totalWorkers, equals(2));
          expect(pool.status.availableWorkers, equals(2));
          expect(pool.status.checkedOutWorkers, equals(0));

          final worker = await pool.checkout();
          expect(worker.isValid, isTrue);
          expect(worker.isOverflow, isFalse);
          expect(pool.status.availableWorkers, equals(1));
          expect(pool.status.checkedOutWorkers, equals(1));

          // Execute multiple stateful steps on the SAME checked-out worker
          await worker.execute(PoolTask('reset'));
          final step1 = await worker.execute(PoolTask('inc', value: 10));
          final step2 = await worker.execute(PoolTask('inc', value: 15));
          expect(step1.workerId, equals(worker.id));
          expect(step2.workerId, equals(worker.id));
          expect(step2.value, equals(25));

          await pool.checkin(worker);
          expect(worker.isValid, isFalse);
          expect(pool.status.availableWorkers, equals(2));
          expect(pool.status.checkedOutWorkers, equals(0));

          // Using a checked-in worker lease throws LeaseInvalidatedException
          await expectLater(
            worker.execute(PoolTask('inc', value: 1)),
            throwsA(isA<LeaseInvalidatedException>()),
          );
        } finally {
          await pool.stop();
        }
      },
    );

    test('PoolStrategy.lifo vs PoolStrategy.fifo checkout ordering', () async {
      // 1. LIFO pool: returns the most recently checked-in worker
      final lifoPool = WorkerPool<PoolTask>(
        hub: hub,
        config: const WorkerPoolConfig(
          size: 2,
          maxOverflow: 0,
          strategy: PoolStrategy.lifo,
        ),
        workerEntryPoint: poolTestWorkerEntryPoint,
      );
      await lifoPool.start();

      try {
        final w1 = await lifoPool.checkout();
        final w2 = await lifoPool.checkout();
        expect(w1.id, isNot(equals(w2.id)));

        // Check in w1 first, then w2 second -> w2 is at the top of the LIFO stack
        await lifoPool.checkin(w1);
        await lifoPool.checkin(w2);

        final next = await lifoPool.checkout();
        expect(next.id, equals(w2.id));
        await lifoPool.checkin(next);
      } finally {
        await lifoPool.stop();
      }

      // 2. FIFO pool: returns the earliest checked-in worker
      final fifoPool = WorkerPool<PoolTask>(
        hub: hub,
        config: const WorkerPoolConfig(
          size: 2,
          maxOverflow: 0,
          strategy: PoolStrategy.fifo,
        ),
        workerEntryPoint: poolTestWorkerEntryPoint,
      );
      await fifoPool.start();

      try {
        final w1 = await fifoPool.checkout();
        final w2 = await fifoPool.checkout();

        // Check in w1 first, then w2 second -> w1 is at the front of the FIFO queue
        await fifoPool.checkin(w1);
        await fifoPool.checkin(w2);

        final next = await fifoPool.checkout();
        expect(next.id, equals(w1.id));
        await fifoPool.checkin(next);
      } finally {
        await fifoPool.stop();
      }
    });

    test(
      'transaction automatically checks in worker on success and on error',
      () async {
        final pool = WorkerPool<PoolTask>(
          hub: hub,
          config: const WorkerPoolConfig(size: 1, maxOverflow: 0),
          workerEntryPoint: poolTestWorkerEntryPoint,
        );
        await pool.start();

        try {
          final value = await pool.transaction((worker) async {
            await worker.execute(PoolTask('reset'));
            final r = await worker.execute(PoolTask('inc', value: 42));
            return r.value;
          });
          expect(value, equals(42));
          expect(pool.status.availableWorkers, equals(1));
          expect(pool.status.checkedOutWorkers, equals(0));

          await expectLater(
            pool.transaction<int>((worker) async {
              throw StateError('Simulated transaction error');
            }),
            throwsA(isA<StateError>()),
          );

          // Worker must still be checked back in after exception!
          expect(pool.status.availableWorkers, equals(1));
          expect(pool.status.checkedOutWorkers, equals(0));
        } finally {
          await pool.stop();
        }
      },
    );

    test(
      'maxOverflow spawns temporary burst workers and dismisses them on checkin',
      () async {
        final pool = WorkerPool<PoolTask>(
          hub: hub,
          config: const WorkerPoolConfig(
            size: 1,
            maxOverflow: 2,
            idleTimeout: Duration.zero,
          ),
          workerEntryPoint: poolTestWorkerEntryPoint,
        );
        await pool.start();

        try {
          expect(pool.status.totalWorkers, equals(1));

          // Checkout base worker
          final baseWorker = await pool.checkout(block: false);
          expect(baseWorker.isOverflow, isFalse);

          // Checkout 2 overflow workers
          final overflow1 = await pool.checkout(block: false);
          final overflow2 = await pool.checkout(block: false);
          expect(overflow1.isOverflow, isTrue);
          expect(overflow2.isOverflow, isTrue);
          expect(pool.status.totalWorkers, equals(3));
          expect(pool.status.overflowWorkers, equals(2));

          // Pool is now at size (1) + maxOverflow (2) = 3:
          // Non-blocking checkout must throw PoolFullException, tryCheckout returns null
          await expectLater(
            pool.checkout(block: false),
            throwsA(isA<PoolFullException>()),
          );
          expect(await pool.tryCheckout(), isNull);

          // Check in overflow workers -> with idleTimeout == Duration.zero and no waiters,
          // they are immediately dismissed!
          await pool.checkin(overflow1);
          await pool.checkin(overflow2);
          await _waitForCondition(() => pool.status.overflowWorkers == 0);
          expect(pool.status.totalWorkers, equals(1));

          await pool.checkin(baseWorker);
          expect(pool.status.availableWorkers, equals(1));
        } finally {
          await pool.stop();
        }
      },
    );

    test(
      'blocking checkout queues waiters in FIFO order and enforces CheckoutTimeoutException',
      () async {
        final pool = WorkerPool<PoolTask>(
          hub: hub,
          config: const WorkerPoolConfig(size: 1, maxOverflow: 0),
          workerEntryPoint: poolTestWorkerEntryPoint,
        );
        await pool.start();

        try {
          final w1 = await pool.checkout();

          // Start two blocking checkouts in order
          final order = <int>[];
          final waiter1Future = pool.checkout().then((w) {
            order.add(1);
            return w;
          });
          final waiter2Future = pool.checkout().then((w) {
            order.add(2);
            return w;
          });

          // Also start a checkout with a short timeout that will expire
          await expectLater(
            pool.checkout(timeout: const Duration(milliseconds: 60)),
            throwsA(isA<CheckoutTimeoutException>()),
          );

          expect(pool.status.waitingCount, equals(2));

          // Check in w1 -> should hand off to waiter 1 first
          await pool.checkin(w1);
          final leasedTo1 = await waiter1Future;
          expect(order, equals([1]));

          // Check in leasedTo1 -> should hand off to waiter 2
          await pool.checkin(leasedTo1);
          final leasedTo2 = await waiter2Future;
          expect(order, equals([1, 2]));

          await pool.checkin(leasedTo2);
          expect(pool.status.availableWorkers, equals(1));
        } finally {
          await pool.stop();
        }
      },
    );

    test(
      'crash of checked-out worker invalidates lease and hands replacement worker to waiting caller',
      () async {
        final pool = WorkerPool<PoolTask>(
          hub: hub,
          config: const WorkerPoolConfig(size: 1, maxOverflow: 0),
          workerEntryPoint: poolTestWorkerEntryPoint,
        );
        await pool.start();

        try {
          final w1 = await pool.checkout();
          final crashedId = w1.id;

          // Queue a waiter while w1 is checked out
          final waitingCheckout = pool.checkout(
            timeout: const Duration(seconds: 3),
          );

          // Crash w1 while it is checked out!
          await expectLater(
            w1.execute(PoolTask('crash')),
            throwsA(isA<IsolateOrchestratorException>()),
          );

          expect(w1.isValid, isFalse);

          // Waiter should automatically receive the replacement base worker spawned after crash!
          final replacement = await waitingCheckout;
          expect(replacement.isValid, isTrue);
          expect(replacement.id, isNot(equals(crashedId)));

          final res = await replacement.execute(PoolTask('echo', value: 21));
          expect(res.value, equals(42));

          // Calling checkin on the crashed lease is a safe no-op
          await pool.checkin(w1);
          await pool.checkin(replacement);
          expect(pool.status.availableWorkers, equals(1));
        } finally {
          await pool.stop();
        }
      },
    );
  });
}
