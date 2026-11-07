import 'dart:async';
import 'dart:isolate';

import 'package:isolate_orchestrator/isolate_orchestrator.dart';
import 'package:test/test.dart';

void main() {
  group('PendingTask', () {
    late ReceivePort replyPort;
    late Completer<TaskResult<String>> completer;

    setUp(() {
      replyPort = ReceivePort();
      completer = Completer<TaskResult<String>>();
    });

    tearDown(() {
      replyPort.close();
    });

    PendingTask<String> createTask({
      String id = 'task-1',
      String correlationId = 'corr-1',
      String sentTo = 'worker-1',
      int retryCount = 0,
    }) {
      return PendingTask<String>(
        id: id,
        correlationId: correlationId,
        task: Task<String>(data: 'test data'),
        completer: completer,
        replyPort: replyPort.sendPort,
        sentTo: sentTo,
        sentAt: DateTime.now().microsecondsSinceEpoch,
        timerBucket: 0,
        retryCount: retryCount,
      );
    }

    test('creates with correct values', () {
      final task = createTask();

      expect(task.id, equals('task-1'));
      expect(task.correlationId, equals('corr-1'));
      expect(task.sentTo, equals('worker-1'));
      expect(task.retryCount, equals(0));
      expect(task.triedWorkers, isEmpty);
    });

    test('canRetry returns true when under maxRetries', () {
      final task = createTask(retryCount: 0);
      expect(task.canRetry(3), isTrue);

      final task2 = createTask(retryCount: 2);
      expect(task2.canRetry(3), isTrue);
    });

    test('canRetry returns false when at maxRetries', () {
      final task = createTask(retryCount: 3);
      expect(task.canRetry(3), isFalse);
    });

    test('recordRetry updates state', () {
      final task = createTask(sentTo: 'worker-1');
      final originalSentAt = task.sentAt;

      // Small delay to ensure time difference
      task.recordRetry('worker-2', 5);

      expect(task.retryCount, equals(1));
      expect(task.sentTo, equals('worker-2'));
      expect(task.triedWorkers, contains('worker-1'));
      expect(task.timerBucket, equals(5));
      expect(task.sentAt, greaterThanOrEqualTo(originalSentAt));
    });

    test('recordRetry accumulates tried workers', () {
      final task = createTask(sentTo: 'worker-1');

      task.recordRetry('worker-2', 1);
      task.recordRetry('worker-3', 2);
      task.recordRetry('worker-4', 3);

      expect(
        task.triedWorkers,
        containsAll(['worker-1', 'worker-2', 'worker-3']),
      );
      expect(task.triedWorkers, isNot(contains('worker-4'))); // Current worker
      expect(task.retryCount, equals(3));
    });

    test('elapsed returns correct duration', () async {
      final task = createTask();

      await Future.delayed(Duration(milliseconds: 50));

      expect(task.elapsed.inMilliseconds, greaterThanOrEqualTo(50));
    });
  });

  group('PendingRequestRegistry', () {
    late PendingRequestRegistry<String> registry;
    late ReceivePort replyPort;

    setUp(() {
      registry = PendingRequestRegistry<String>();
      replyPort = ReceivePort();
    });

    tearDown(() {
      replyPort.close();
    });

    PendingTask<String> createTask({
      required String id,
      required String correlationId,
    }) {
      return PendingTask<String>(
        id: id,
        correlationId: correlationId,
        task: Task<String>(data: 'test'),
        completer: Completer<TaskResult<String>>(),
        replyPort: replyPort.sendPort,
        sentTo: 'worker-1',
        sentAt: DateTime.now().microsecondsSinceEpoch,
        timerBucket: 0,
      );
    }

    test('register adds task', () {
      final task = createTask(id: 'task-1', correlationId: 'corr-1');
      registry.register(task);

      expect(registry.count, equals(1));
      expect(registry.isEmpty, isFalse);
    });

    test('getById returns registered task', () {
      final task = createTask(id: 'task-1', correlationId: 'corr-1');
      registry.register(task);

      expect(registry.getById('task-1'), equals(task));
      expect(registry.getById('non-existent'), isNull);
    });

    test('getByCorrelation returns registered task', () {
      final task = createTask(id: 'task-1', correlationId: 'corr-1');
      registry.register(task);

      expect(registry.getByCorrelation('corr-1'), equals(task));
      expect(registry.getByCorrelation('non-existent'), isNull);
    });

    test('remove by id removes task', () {
      final task = createTask(id: 'task-1', correlationId: 'corr-1');
      registry.register(task);

      final removed = registry.remove('task-1');

      expect(removed, equals(task));
      expect(registry.count, equals(0));
      expect(registry.getById('task-1'), isNull);
      expect(registry.getByCorrelation('corr-1'), isNull);
    });

    test('remove returns null for non-existent id', () {
      expect(registry.remove('non-existent'), isNull);
    });

    test('removeByCorrelation removes task', () {
      final task = createTask(id: 'task-1', correlationId: 'corr-1');
      registry.register(task);

      final removed = registry.removeByCorrelation('corr-1');

      expect(removed, equals(task));
      expect(registry.count, equals(0));
      expect(registry.getById('task-1'), isNull);
      expect(registry.getByCorrelation('corr-1'), isNull);
    });

    test('allIds returns all task IDs', () {
      registry.register(createTask(id: 'task-1', correlationId: 'corr-1'));
      registry.register(createTask(id: 'task-2', correlationId: 'corr-2'));
      registry.register(createTask(id: 'task-3', correlationId: 'corr-3'));

      expect(registry.allIds, containsAll(['task-1', 'task-2', 'task-3']));
    });

    test('all returns all tasks', () {
      registry.register(createTask(id: 'task-1', correlationId: 'corr-1'));
      registry.register(createTask(id: 'task-2', correlationId: 'corr-2'));

      expect(registry.all.length, equals(2));
    });

    test('clear removes all tasks', () {
      registry.register(createTask(id: 'task-1', correlationId: 'corr-1'));
      registry.register(createTask(id: 'task-2', correlationId: 'corr-2'));

      registry.clear();

      expect(registry.count, equals(0));
      expect(registry.isEmpty, isTrue);
    });

    test('completeAllWithError completes all pending tasks', () async {
      final completer1 = Completer<TaskResult<String>>();
      final completer2 = Completer<TaskResult<String>>();

      registry.register(
        PendingTask<String>(
          id: 'task-1',
          correlationId: 'corr-1',
          task: Task<String>(data: 'test'),
          completer: completer1,
          replyPort: replyPort.sendPort,
          sentTo: 'worker-1',
          sentAt: DateTime.now().microsecondsSinceEpoch,
          timerBucket: 0,
        ),
      );

      registry.register(
        PendingTask<String>(
          id: 'task-2',
          correlationId: 'corr-2',
          task: Task<String>(data: 'test'),
          completer: completer2,
          replyPort: replyPort.sendPort,
          sentTo: 'worker-1',
          sentAt: DateTime.now().microsecondsSinceEpoch,
          timerBucket: 0,
        ),
      );

      final error = Exception('Pool shutdown');
      registry.completeAllWithError(error);

      expect(registry.isEmpty, isTrue);

      await expectLater(completer1.future, throwsA(equals(error)));
      await expectLater(completer2.future, throwsA(equals(error)));
    });

    test('completeAllWithError skips already completed tasks', () async {
      final completer = Completer<TaskResult<String>>();
      completer.complete(TaskResult(data: 'completed'));

      registry.register(
        PendingTask<String>(
          id: 'task-1',
          correlationId: 'corr-1',
          task: Task<String>(data: 'test'),
          completer: completer,
          replyPort: replyPort.sendPort,
          sentTo: 'worker-1',
          sentAt: DateTime.now().microsecondsSinceEpoch,
          timerBucket: 0,
        ),
      );

      // Should not throw
      registry.completeAllWithError(Exception('error'));

      // Original result should be preserved
      final result = await completer.future;
      expect(result.data, equals('completed'));
    });
  });
}
