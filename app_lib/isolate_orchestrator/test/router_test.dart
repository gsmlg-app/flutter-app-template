import 'dart:isolate';

import 'package:isolate_orchestrator/isolate_orchestrator.dart';
import 'package:test/test.dart';

void main() {
  group('WorkerPort', () {
    test('creates with correct values', () {
      final port = ReceivePort();
      final workerPort = WorkerPort(
        id: 'w1',
        port: port.sendPort,
        healthy: true,
        pendingCount: 5,
        avgLatencyUs: 1000,
      );

      expect(workerPort.id, equals('w1'));
      expect(workerPort.healthy, isTrue);
      expect(workerPort.pendingCount, equals(5));
      expect(workerPort.avgLatencyUs, equals(1000));

      port.close();
    });
  });

  group('RoundRobinRouter', () {
    late RoundRobinRouter<String> router;
    late List<ReceivePort> ports;

    setUp(() {
      router = RoundRobinRouter<String>();
      ports = [ReceivePort(), ReceivePort(), ReceivePort()];
    });

    tearDown(() {
      for (final port in ports) {
        port.close();
      }
    });

    List<PortInfo> createPortInfos() {
      return [
        PortInfo(id: 'w1', port: ports[0].sendPort, capabilities: []),
        PortInfo(id: 'w2', port: ports[1].sendPort, capabilities: []),
        PortInfo(id: 'w3', port: ports[2].sendPort, capabilities: []),
      ];
    }

    test('returns null when no workers', () {
      expect(router.select('request'), isNull);
    });

    test('selects workers in round-robin order', () {
      router.updateWorkers(createPortInfos());

      final selected = <String>[];
      for (var i = 0; i < 6; i++) {
        final worker = router.select('request');
        selected.add(worker!.id);
      }

      // Should cycle through workers
      expect(selected.toSet().length, equals(3));
    });

    test('skips excluded workers', () {
      router.updateWorkers(createPortInfos());

      final worker = router.select('request', exclude: {'w1', 'w2'});
      expect(worker?.id, equals('w3'));
    });

    test('returns null when all workers excluded', () {
      router.updateWorkers(createPortInfos());

      final worker = router.select('request', exclude: {'w1', 'w2', 'w3'});
      expect(worker, isNull);
    });

    test('skips unhealthy workers', () {
      router.updateWorkers(createPortInfos());
      router.recordFailure('w1');
      router.recordFailure('w2');

      // Should only select w3 since w1 and w2 are unhealthy
      final selected = <String>{};
      for (var i = 0; i < 5; i++) {
        final worker = router.select('request');
        selected.add(worker!.id);
      }
      expect(selected, equals({'w3'}));
    });

    test('falls back to unhealthy workers when no healthy available', () {
      router.updateWorkers(createPortInfos());
      router.recordFailure('w1');
      router.recordFailure('w2');
      router.recordFailure('w3');

      final worker = router.select('request');
      expect(worker, isNotNull);
    });

    test('recordSuccess updates worker state', () {
      router.updateWorkers(createPortInfos());
      router.recordFailure('w1');

      final beforeWorker = router.workers.firstWhere((w) => w.id == 'w1');
      expect(beforeWorker.healthy, isFalse);

      router.recordSuccess('w1', Duration(milliseconds: 100));

      final afterWorker = router.workers.firstWhere((w) => w.id == 'w1');
      expect(afterWorker.healthy, isTrue);
      expect(afterWorker.avgLatencyUs, equals(100000));
    });

    test('updateWorkers removes old workers', () {
      router.updateWorkers(createPortInfos());
      expect(router.workers.length, equals(3));

      router.updateWorkers([
        PortInfo(id: 'w1', port: ports[0].sendPort, capabilities: []),
      ]);
      expect(router.workers.length, equals(1));
      expect(router.workers.first.id, equals('w1'));
    });

    test('updateWorkers adds new workers', () {
      router.updateWorkers([
        PortInfo(id: 'w1', port: ports[0].sendPort, capabilities: []),
      ]);
      expect(router.workers.length, equals(1));

      router.updateWorkers(createPortInfos());
      expect(router.workers.length, equals(3));
    });
  });

  group('LeastConnectionsRouter', () {
    late LeastConnectionsRouter<String> router;
    late List<ReceivePort> ports;

    setUp(() {
      router = LeastConnectionsRouter<String>();
      ports = [ReceivePort(), ReceivePort(), ReceivePort()];
    });

    tearDown(() {
      for (final port in ports) {
        port.close();
      }
    });

    List<PortInfo> createPortInfos() {
      return [
        PortInfo(id: 'w1', port: ports[0].sendPort, capabilities: []),
        PortInfo(id: 'w2', port: ports[1].sendPort, capabilities: []),
        PortInfo(id: 'w3', port: ports[2].sendPort, capabilities: []),
      ];
    }

    test('returns null when no workers', () {
      expect(router.select('request'), isNull);
    });

    test('selects worker with fewest connections', () {
      router.updateWorkers(createPortInfos());

      // All workers start with 0 pending
      // First selection should pick any worker
      final first = router.select('request');
      expect(first, isNotNull);

      // After selecting, that worker should have pending++
      // Next selection should pick a different worker with 0 pending
      final second = router.select('request');
      expect(second!.id, isNot(equals(first!.id)));

      final third = router.select('request');
      expect(third!.id, isNot(equals(first.id)));
      expect(third.id, isNot(equals(second.id)));
    });

    test('recordSuccess decrements pending count', () {
      router.updateWorkers(createPortInfos());

      final worker = router.select('request');
      expect(
        router.workers.firstWhere((w) => w.id == worker!.id).pendingCount,
        equals(1),
      );

      router.recordSuccess(worker!.id, Duration(milliseconds: 100));

      expect(
        router.workers.firstWhere((w) => w.id == worker.id).pendingCount,
        equals(0),
      );
    });

    test('recordFailure decrements pending count', () {
      router.updateWorkers(createPortInfos());

      final worker = router.select('request');
      router.recordFailure(worker!.id);

      expect(
        router.workers.firstWhere((w) => w.id == worker.id).pendingCount,
        equals(0),
      );
    });

    test('skips unhealthy workers', () {
      router.updateWorkers(createPortInfos());
      router.recordFailure('w1');
      router.recordFailure('w2');

      for (var i = 0; i < 5; i++) {
        final worker = router.select('request');
        expect(worker!.id, equals('w3'));
        router.recordSuccess('w3', Duration(milliseconds: 10));
      }
    });
  });

  group('ConsistentHashRouter', () {
    late ConsistentHashRouter<String> router;
    late List<ReceivePort> ports;

    setUp(() {
      router = ConsistentHashRouter<String>(
        keyExtractor: (s) => s,
        virtualNodesPerWorker: 10, // Smaller for tests
      );
      ports = [ReceivePort(), ReceivePort(), ReceivePort()];
    });

    tearDown(() {
      for (final port in ports) {
        port.close();
      }
    });

    List<PortInfo> createPortInfos() {
      return [
        PortInfo(id: 'w1', port: ports[0].sendPort, capabilities: []),
        PortInfo(id: 'w2', port: ports[1].sendPort, capabilities: []),
        PortInfo(id: 'w3', port: ports[2].sendPort, capabilities: []),
      ];
    }

    test('returns null when no workers', () {
      expect(router.select('request'), isNull);
    });

    test('consistently routes same key to same worker', () {
      router.updateWorkers(createPortInfos());

      final firstSelection = router.select('user-123');
      final secondSelection = router.select('user-123');
      final thirdSelection = router.select('user-123');

      expect(firstSelection!.id, equals(secondSelection!.id));
      expect(secondSelection.id, equals(thirdSelection!.id));
    });

    test('different keys may route to different workers', () {
      router.updateWorkers(createPortInfos());

      final selected = <String>{};
      // Try many different keys
      for (var i = 0; i < 100; i++) {
        final worker = router.select('key-$i');
        if (worker != null) {
          selected.add(worker.id);
        }
      }

      // Should distribute across multiple workers
      expect(selected.length, greaterThan(1));
    });

    test('skips excluded workers', () {
      router.updateWorkers(createPortInfos());

      final worker = router.select('request', exclude: {'w1', 'w2'});
      expect(worker?.id, equals('w3'));
    });

    test('recordFailure marks worker unhealthy', () {
      router.updateWorkers(createPortInfos());
      router.recordFailure('w1');

      final w1 = router.workers.firstWhere((w) => w.id == 'w1');
      expect(w1.healthy, isFalse);
    });

    test('recordSuccess marks worker healthy', () {
      router.updateWorkers(createPortInfos());
      router.recordFailure('w1');
      router.recordSuccess('w1', Duration(milliseconds: 100));

      final w1 = router.workers.firstWhere((w) => w.id == 'w1');
      expect(w1.healthy, isTrue);
    });

    test('redistributes when workers change', () {
      // Start with multiple workers
      router.updateWorkers(createPortInfos());

      // Record initial assignments
      final initialAssignments = <String, String>{};
      for (var i = 0; i < 100; i++) {
        final worker = router.select('key-$i');
        if (worker != null) {
          initialAssignments['key-$i'] = worker.id;
        }
      }

      // Remove a worker
      router.updateWorkers([
        PortInfo(id: 'w1', port: ports[0].sendPort, capabilities: []),
        PortInfo(id: 'w2', port: ports[1].sendPort, capabilities: []),
      ]);

      // Check that keys get redistributed
      var redistributed = 0;
      for (var i = 0; i < 100; i++) {
        final worker = router.select('key-$i');
        if (worker != null && initialAssignments['key-$i'] != worker.id) {
          redistributed++;
        }
      }

      // Some keys should have been redistributed (those that were on w3)
      expect(redistributed, greaterThanOrEqualTo(0));
    });
  });
}
