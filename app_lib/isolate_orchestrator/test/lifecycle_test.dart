import 'package:isolate_orchestrator/isolate_orchestrator.dart';
import 'package:test/test.dart';

void main() {
  group('RestartPolicy', () {
    test('default values', () {
      const policy = RestartPolicy();

      expect(policy.maxAttempts, equals(10));
      expect(policy.initialDelay, equals(Duration(seconds: 1)));
      expect(policy.maxDelay, equals(Duration(seconds: 60)));
      expect(policy.multiplier, equals(2.0));
    });

    test('custom values', () {
      const policy = RestartPolicy(
        maxAttempts: 5,
        initialDelay: Duration(milliseconds: 500),
        maxDelay: Duration(seconds: 30),
        multiplier: 1.5,
      );

      expect(policy.maxAttempts, equals(5));
      expect(policy.initialDelay, equals(Duration(milliseconds: 500)));
      expect(policy.maxDelay, equals(Duration(seconds: 30)));
      expect(policy.multiplier, equals(1.5));
    });

    test('delayForAttempt calculates exponential backoff', () {
      const policy = RestartPolicy(
        initialDelay: Duration(seconds: 1),
        multiplier: 2.0,
        maxDelay: Duration(seconds: 60),
      );

      expect(policy.delayForAttempt(1), equals(Duration(seconds: 1)));
      expect(policy.delayForAttempt(2), equals(Duration(seconds: 2)));
      expect(policy.delayForAttempt(3), equals(Duration(seconds: 4)));
      expect(policy.delayForAttempt(4), equals(Duration(seconds: 8)));
      expect(policy.delayForAttempt(5), equals(Duration(seconds: 16)));
    });

    test('delayForAttempt caps at maxDelay', () {
      const policy = RestartPolicy(
        initialDelay: Duration(seconds: 1),
        multiplier: 2.0,
        maxDelay: Duration(seconds: 10),
      );

      expect(policy.delayForAttempt(5), equals(Duration(seconds: 10)));
      expect(policy.delayForAttempt(10), equals(Duration(seconds: 10)));
      expect(policy.delayForAttempt(100), equals(Duration(seconds: 10)));
    });

    test('delayForAttempt handles zero or negative attempt', () {
      const policy = RestartPolicy(initialDelay: Duration(seconds: 1));

      expect(policy.delayForAttempt(0), equals(Duration(seconds: 1)));
      expect(policy.delayForAttempt(-1), equals(Duration(seconds: 1)));
    });

    test('delayForAttempt with fractional multiplier', () {
      const policy = RestartPolicy(
        initialDelay: Duration(seconds: 1),
        multiplier: 1.5,
        maxDelay: Duration(seconds: 60),
      );

      expect(policy.delayForAttempt(1), equals(Duration(seconds: 1)));
      expect(policy.delayForAttempt(2), equals(Duration(milliseconds: 1500)));
      expect(policy.delayForAttempt(3), equals(Duration(milliseconds: 2250)));
    });

    test('canRetry returns true when under maxAttempts', () {
      const policy = RestartPolicy(maxAttempts: 5);

      expect(policy.canRetry(0), isTrue);
      expect(policy.canRetry(1), isTrue);
      expect(policy.canRetry(4), isTrue);
    });

    test('canRetry returns false when at or above maxAttempts', () {
      const policy = RestartPolicy(maxAttempts: 5);

      expect(policy.canRetry(5), isFalse);
      expect(policy.canRetry(6), isFalse);
      expect(policy.canRetry(100), isFalse);
    });
  });

  group('RestartTracker', () {
    late RestartTracker tracker;

    setUp(() {
      tracker = RestartTracker(
        policy: const RestartPolicy(
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 10),
          multiplier: 2.0,
        ),
        isolateId: 'test-isolate',
      );
    });

    tearDown(() {
      tracker.cancel();
    });

    test('initializes with zero attempts', () {
      expect(tracker.attempts, equals(0));
      expect(tracker.canRetry, isTrue);
    });

    test('scheduleRestart increments attempts', () async {
      var called = false;

      final future = tracker.scheduleRestart(() {
        called = true;
      });

      expect(tracker.attempts, equals(1));
      await future;
      expect(called, isTrue);
    });

    test('scheduleRestart returns null when max attempts reached', () {
      // Exhaust all attempts
      for (var i = 0; i < 3; i++) {
        tracker.scheduleRestart(() {});
      }

      expect(tracker.attempts, equals(3));
      expect(tracker.canRetry, isFalse);

      final result = tracker.scheduleRestart(() {});
      expect(result, isNull);
    });

    test('cancel stops pending restart', () async {
      var called = false;

      tracker.scheduleRestart(() {
        called = true;
      });

      tracker.cancel();

      await Future.delayed(Duration(milliseconds: 50));
      expect(called, isFalse);
    });

    test('reset clears attempts', () {
      tracker.scheduleRestart(() {});
      tracker.scheduleRestart(() {});
      expect(tracker.attempts, equals(2));

      tracker.reset();

      expect(tracker.attempts, equals(0));
      expect(tracker.canRetry, isTrue);
    });

    test('reset cancels pending restart', () async {
      var called = false;

      tracker.scheduleRestart(() {
        called = true;
      });

      tracker.reset();

      await Future.delayed(Duration(milliseconds: 50));
      expect(called, isFalse);
    });

    test('timeUntilRestart returns remaining time', () {
      tracker.scheduleRestart(() {});

      final time = tracker.timeUntilRestart;
      expect(time, isNotNull);
      expect(time!.inMilliseconds, lessThanOrEqualTo(10));
    });

    test('timeUntilRestart returns null when no pending restart', () {
      expect(tracker.timeUntilRestart, isNull);
    });
  });

  group('LifecycleManager', () {
    late LifecycleManager manager;

    setUp(() {
      manager = LifecycleManager(
        policy: const RestartPolicy(
          maxAttempts: 5,
          initialDelay: Duration(milliseconds: 10),
        ),
      );
    });

    tearDown(() {
      manager.clear();
    });

    test('getTracker creates new tracker', () {
      final tracker = manager.getTracker('isolate-1');

      expect(tracker, isNotNull);
      expect(tracker.isolateId, equals('isolate-1'));
    });

    test('getTracker returns same tracker for same id', () {
      final tracker1 = manager.getTracker('isolate-1');
      final tracker2 = manager.getTracker('isolate-1');

      expect(identical(tracker1, tracker2), isTrue);
    });

    test('getTracker with custom policy', () {
      final customPolicy = const RestartPolicy(maxAttempts: 20);
      final tracker = manager.getTracker('isolate-1', policy: customPolicy);

      expect(tracker.policy, equals(customPolicy));
    });

    test('removeTracker removes and cancels tracker', () {
      final tracker = manager.getTracker('isolate-1');
      tracker.scheduleRestart(() {});

      manager.removeTracker('isolate-1');

      // Getting tracker again should create new one
      final newTracker = manager.getTracker('isolate-1');
      expect(identical(tracker, newTracker), isFalse);
      expect(newTracker.attempts, equals(0));
    });

    test('resetTracker resets attempts', () {
      final tracker = manager.getTracker('isolate-1');
      tracker.scheduleRestart(() {});
      tracker.scheduleRestart(() {});
      expect(tracker.attempts, equals(2));

      manager.resetTracker('isolate-1');

      expect(tracker.attempts, equals(0));
    });

    test('cancelAll cancels all pending restarts', () async {
      final tracker1 = manager.getTracker('isolate-1');
      final tracker2 = manager.getTracker('isolate-2');

      var called1 = false;
      var called2 = false;

      tracker1.scheduleRestart(() => called1 = true);
      tracker2.scheduleRestart(() => called2 = true);

      manager.cancelAll();

      await Future.delayed(Duration(milliseconds: 50));
      expect(called1, isFalse);
      expect(called2, isFalse);
    });

    test('clear removes all trackers', () {
      manager.getTracker('isolate-1');
      manager.getTracker('isolate-2');

      manager.clear();

      // New trackers should be created
      final tracker1 = manager.getTracker('isolate-1');
      expect(tracker1.attempts, equals(0));
    });
  });
}
