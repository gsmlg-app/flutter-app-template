import 'package:isolate_orchestrator/isolate_orchestrator.dart';
import 'package:test/test.dart';

void main() {
  group('IsolateAddress', () {
    test('creates address with role and id', () {
      final address = IsolateAddress(role: 'worker', id: 'worker-1');
      expect(address.role, 'worker');
      expect(address.id, 'worker-1');
    });

    test('hub address is predefined', () {
      expect(IsolateAddress.hub.role, 'hub');
      expect(IsolateAddress.hub.id, 'hub');
    });

    test('broadcast address is predefined', () {
      expect(IsolateAddress.broadcast.role, '*');
      expect(IsolateAddress.broadcast.id, '*');
    });

    test('equality works correctly', () {
      final a1 = IsolateAddress(role: 'worker', id: 'w1');
      final a2 = IsolateAddress(role: 'worker', id: 'w1');
      final a3 = IsolateAddress(role: 'worker', id: 'w2');

      expect(a1, equals(a2));
      expect(a1, isNot(equals(a3)));
    });
  });

  group('MessageIdGenerator', () {
    test('generates unique IDs', () {
      final gen = MessageIdGenerator('test');
      final ids = <String>{};

      for (var i = 0; i < 1000; i++) {
        ids.add(gen.next());
      }

      expect(ids.length, 1000);
    });

    test('IDs contain prefix', () {
      final gen = MessageIdGenerator('myprefix');
      final id = gen.next();

      expect(id, startsWith('myprefix-'));
    });
  });

  group('Envelope', () {
    test('creates envelope with required fields', () {
      final envelope = Envelope(
        id: 'msg-1',
        timestamp: 12345,
        source: IsolateAddress.hub,
        target: IsolateAddress.of('worker', 'w1'),
        payload: 'test payload',
      );

      expect(envelope.id, 'msg-1');
      expect(envelope.timestamp, 12345);
      expect(envelope.source, IsolateAddress.hub);
      expect(envelope.payload, 'test payload');
    });

    test('checks flags correctly', () {
      final envelope = Envelope(
        id: 'msg-1',
        timestamp: 12345,
        source: IsolateAddress.hub,
        target: IsolateAddress.hub,
        payload: 'test',
        flags: EnvelopeFlags.needsAck | EnvelopeFlags.priority,
      );

      expect(envelope.needsAck, true);
      expect(envelope.isPriority, true);
      expect(envelope.isAck, false);
    });
  });

  group('IsolateMetrics', () {
    test('calculates error rate', () {
      final metrics = IsolateMetrics(
        uptimeMs: 1000,
        processedCount: 90,
        pendingCount: 5,
        errorCount: 10,
        avgLatencyUs: 100,
      );

      expect(metrics.errorRate, 0.1);
    });

    test('error rate is zero when no tasks', () {
      final metrics = IsolateMetrics.empty();
      expect(metrics.errorRate, 0.0);
    });
  });

  group('RestartPolicy', () {
    test('calculates delay with exponential backoff', () {
      const policy = RestartPolicy(
        initialDelay: Duration(seconds: 1),
        multiplier: 2.0,
        maxDelay: Duration(seconds: 60),
      );

      expect(policy.delayForAttempt(1), Duration(seconds: 1));
      expect(policy.delayForAttempt(2), Duration(seconds: 2));
      expect(policy.delayForAttempt(3), Duration(seconds: 4));
    });

    test('caps delay at maxDelay', () {
      const policy = RestartPolicy(
        initialDelay: Duration(seconds: 1),
        multiplier: 2.0,
        maxDelay: Duration(seconds: 10),
      );

      expect(policy.delayForAttempt(10), Duration(seconds: 10));
    });

    test('canRetry respects maxAttempts', () {
      const policy = RestartPolicy(maxAttempts: 3);

      expect(policy.canRetry(0), true);
      expect(policy.canRetry(2), true);
      expect(policy.canRetry(3), false);
    });
  });

  group('TimerWheel', () {
    test('adds and removes requests', () {
      final wheel = TimerWheel(
        tickDuration: Duration(milliseconds: 100),
        wheelSize: 64,
      );

      final bucket = wheel.add('req-1', Duration(seconds: 1));
      expect(wheel.pendingCount, 1);

      wheel.remove('req-1', bucket);
      expect(wheel.pendingCount, 0);
    });
  });

  group('HashRing', () {
    test('distributes keys across workers', () {
      // This is a simplified test since we can't actually create SendPorts
      // in unit tests without spawning isolates
      expect(HashRing.fnv1a('test'), isA<int>());
      expect(HashRing.fnv1a('test'), equals(HashRing.fnv1a('test')));
      expect(HashRing.fnv1a('test'), isNot(equals(HashRing.fnv1a('other'))));
    });
  });

  group('Protocol Messages', () {
    test('Register creates correctly', () {
      // Cannot test with actual SendPort without isolate
    });

    test('Task wraps data correctly', () {
      final task = Task<String>(
        data: 'test data',
        taskType: 'compute',
        metadata: {'priority': 'high'},
      );

      expect(task.data, 'test data');
      expect(task.taskType, 'compute');
      expect(task.metadata?['priority'], 'high');
    });

    test('TaskResult wraps data correctly', () {
      final result = TaskResult<int>(data: 42);
      expect(result.data, 42);
    });

    test('TaskError contains error info', () {
      final error = TaskError(
        code: 'TIMEOUT',
        message: 'Request timed out',
        details: {'elapsed': 5000},
      );

      expect(error.code, 'TIMEOUT');
      expect(error.message, 'Request timed out');
      expect(error.details['elapsed'], 5000);
    });

    test('TaskBatchResult collects results', () {
      final results = TaskBatchResult<int>([
        TaskSuccess(1),
        TaskSuccess(2),
        TaskFailure(TaskError(code: 'ERR', message: 'failed')),
      ]);

      expect(results.results.length, 3);
      expect(results.results[0], isA<TaskSuccess<int>>());
      expect(results.results[2], isA<TaskFailure<int>>());
    });
  });

  group('Exceptions', () {
    test('NoHealthyWorkerException has correct message', () {
      final e = NoHealthyWorkerException();
      expect(e.toString(), contains('No healthy workers'));
    });

    test('TaskTimeoutException includes task info', () {
      final e = TaskTimeoutException('task-123', 3);
      expect(e.taskId, 'task-123');
      expect(e.retryCount, 3);
      expect(e.toString(), contains('task-123'));
      expect(e.toString(), contains('3'));
    });
  });
}
