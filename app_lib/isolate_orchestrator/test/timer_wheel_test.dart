import 'package:isolate_orchestrator/isolate_orchestrator.dart';
import 'package:test/test.dart';

void main() {
  group('TimerWheel', () {
    late TimerWheel wheel;

    setUp(() {
      wheel = TimerWheel(
        tickDuration: Duration(milliseconds: 10),
        wheelSize: 8,
      );
    });

    tearDown(() {
      wheel.stop();
    });

    test('default configuration', () {
      final defaultWheel = TimerWheel();
      expect(defaultWheel.tickDuration, equals(Duration(milliseconds: 100)));
      expect(defaultWheel.wheelSize, equals(64));
      defaultWheel.stop();
    });

    test('custom configuration', () {
      expect(wheel.tickDuration, equals(Duration(milliseconds: 10)));
      expect(wheel.wheelSize, equals(8));
    });

    test('add increments pending count', () {
      expect(wheel.pendingCount, equals(0));

      wheel.add('req-1', Duration(milliseconds: 50));
      expect(wheel.pendingCount, equals(1));

      wheel.add('req-2', Duration(milliseconds: 100));
      expect(wheel.pendingCount, equals(2));
    });

    test('remove decrements pending count', () {
      final bucket1 = wheel.add('req-1', Duration(milliseconds: 50));
      final bucket2 = wheel.add('req-2', Duration(milliseconds: 100));
      expect(wheel.pendingCount, equals(2));

      wheel.remove('req-1', bucket1);
      expect(wheel.pendingCount, equals(1));

      wheel.remove('req-2', bucket2);
      expect(wheel.pendingCount, equals(0));
    });

    test('remove non-existent request does not throw', () {
      expect(() => wheel.remove('non-existent', 0), returnsNormally);
    });

    test('start triggers timeout callback', () async {
      final timedOut = <String>[];

      wheel.start((requestId) {
        timedOut.add(requestId);
      });

      wheel.add('req-1', Duration(milliseconds: 30));

      // Wait for timeout to trigger
      await Future.delayed(Duration(milliseconds: 100));

      expect(timedOut, contains('req-1'));
    });

    test('removed request does not trigger timeout', () async {
      final timedOut = <String>[];

      wheel.start((requestId) {
        timedOut.add(requestId);
      });

      final bucket = wheel.add('req-1', Duration(milliseconds: 30));
      wheel.remove('req-1', bucket);

      await Future.delayed(Duration(milliseconds: 100));

      expect(timedOut, isEmpty);
    });

    test('stop prevents timeout callbacks', () async {
      final timedOut = <String>[];

      wheel.start((requestId) {
        timedOut.add(requestId);
      });

      wheel.add('req-1', Duration(milliseconds: 50));
      wheel.stop();

      await Future.delayed(Duration(milliseconds: 100));

      expect(timedOut, isEmpty);
    });

    test('multiple requests in same bucket', () async {
      final timedOut = <String>[];

      wheel.start((requestId) {
        timedOut.add(requestId);
      });

      // Add requests with similar timeouts (should go to same bucket)
      wheel.add('req-1', Duration(milliseconds: 20));
      wheel.add('req-2', Duration(milliseconds: 25));
      wheel.add('req-3', Duration(milliseconds: 28));

      await Future.delayed(Duration(milliseconds: 150));

      expect(timedOut, containsAll(['req-1', 'req-2', 'req-3']));
    });

    test('requests with different timeouts', () async {
      final timedOut = <String>[];

      wheel.start((requestId) {
        timedOut.add(requestId);
      });

      wheel.add('req-1', Duration(milliseconds: 20));
      wheel.add('req-2', Duration(milliseconds: 60));

      await Future.delayed(Duration(milliseconds: 150));

      expect(timedOut, containsAll(['req-1', 'req-2']));

      // req-1 should timeout before req-2
      final index1 = timedOut.indexOf('req-1');
      final index2 = timedOut.indexOf('req-2');
      expect(index1, lessThan(index2));
    });

    test('bucket wraps around wheel', () {
      // With wheelSize=8 and tickDuration=10ms, bucket should wrap
      final bucket1 = wheel.add(
        'req-1',
        Duration(milliseconds: 5),
      ); // bucket ~0-1
      final bucket2 = wheel.add(
        'req-2',
        Duration(milliseconds: 100),
      ); // bucket wraps

      // Both should be valid bucket indices
      expect(bucket1, inInclusiveRange(0, 7));
      expect(bucket2, inInclusiveRange(0, 7));
    });

    test('clear removes all pending requests', () {
      wheel.add('req-1', Duration(milliseconds: 50));
      wheel.add('req-2', Duration(milliseconds: 100));
      wheel.add('req-3', Duration(milliseconds: 150));

      expect(wheel.pendingCount, equals(3));

      wheel.clear();

      expect(wheel.pendingCount, equals(0));
    });

    test('clear prevents pending timeouts', () async {
      final timedOut = <String>[];

      wheel.start((requestId) {
        timedOut.add(requestId);
      });

      wheel.add('req-1', Duration(milliseconds: 30));
      wheel.add('req-2', Duration(milliseconds: 30));

      wheel.clear();

      await Future.delayed(Duration(milliseconds: 100));

      expect(timedOut, isEmpty);
    });

    test('handles zero timeout', () async {
      final timedOut = <String>[];

      wheel.start((requestId) {
        timedOut.add(requestId);
      });

      wheel.add('req-1', Duration.zero);

      await Future.delayed(Duration(milliseconds: 50));

      expect(timedOut, contains('req-1'));
    });

    test('handles very long timeout', () {
      // Should not throw even with very long timeout
      final bucket = wheel.add('req-1', Duration(hours: 1));
      expect(bucket, inInclusiveRange(0, 7));
    });

    test('start ignores subsequent calls when already running', () async {
      var callCount = 0;

      wheel.start((requestId) {
        callCount++;
      });

      // Calling start again should be ignored (timer already running)
      wheel.start((requestId) {
        callCount += 10;
      });

      wheel.add('req-1', Duration(milliseconds: 20));

      await Future.delayed(Duration(milliseconds: 100));

      // Should use the first callback (second one ignored)
      expect(callCount, equals(1));
    });

    test('isRunning returns correct state', () {
      expect(wheel.isRunning, isFalse);

      wheel.start((requestId) {});
      expect(wheel.isRunning, isTrue);

      wheel.stop();
      expect(wheel.isRunning, isFalse);
    });
  });
}
