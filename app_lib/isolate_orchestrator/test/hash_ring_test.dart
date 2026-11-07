import 'dart:isolate';

import 'package:isolate_orchestrator/isolate_orchestrator.dart';
import 'package:test/test.dart';

void main() {
  group('HashRing', () {
    late HashRing ring;
    late List<ReceivePort> ports;

    setUp(() {
      ring = HashRing(virtualNodesPerWorker: 10);
      ports = [ReceivePort(), ReceivePort(), ReceivePort(), ReceivePort()];
    });

    tearDown(() {
      for (final port in ports) {
        port.close();
      }
    });

    test('default virtual nodes', () {
      final defaultRing = HashRing();
      expect(defaultRing.virtualNodesPerWorker, equals(150));
    });

    test('custom virtual nodes', () {
      expect(ring.virtualNodesPerWorker, equals(10));
    });

    test('fnv1a produces consistent hash', () {
      final hash1 = HashRing.fnv1a('test-key');
      final hash2 = HashRing.fnv1a('test-key');

      expect(hash1, equals(hash2));
    });

    test('fnv1a produces different hashes for different inputs', () {
      final hash1 = HashRing.fnv1a('key-1');
      final hash2 = HashRing.fnv1a('key-2');

      expect(hash1, isNot(equals(hash2)));
    });

    test('fnv1a produces 32-bit hash', () {
      final hash = HashRing.fnv1a('test');
      expect(hash, inInclusiveRange(0, 0xFFFFFFFF));
    });

    test('find returns null when empty', () {
      expect(ring.find('any-key'), isNull);
    });

    test('addWorker adds worker to ring', () {
      ring.addWorker('w1', ports[0].sendPort);

      final worker = ring.find('test-key');
      expect(worker, isNotNull);
      expect(worker!.id, equals('w1'));
    });

    test('find returns same worker for same key', () {
      ring.addWorker('w1', ports[0].sendPort);
      ring.addWorker('w2', ports[1].sendPort);
      ring.addWorker('w3', ports[2].sendPort);

      final worker1 = ring.find('user-123');
      final worker2 = ring.find('user-123');
      final worker3 = ring.find('user-123');

      expect(worker1!.id, equals(worker2!.id));
      expect(worker2.id, equals(worker3!.id));
    });

    test('find distributes keys across workers', () {
      ring.addWorker('w1', ports[0].sendPort);
      ring.addWorker('w2', ports[1].sendPort);
      ring.addWorker('w3', ports[2].sendPort);

      final counts = <String, int>{'w1': 0, 'w2': 0, 'w3': 0};

      for (var i = 0; i < 1000; i++) {
        final worker = ring.find('key-$i');
        if (worker != null) {
          counts[worker.id] = counts[worker.id]! + 1;
        }
      }

      // Each worker should get some keys
      expect(counts['w1'], greaterThan(0));
      expect(counts['w2'], greaterThan(0));
      expect(counts['w3'], greaterThan(0));
    });

    test('removeWorker removes worker from ring', () {
      ring.addWorker('w1', ports[0].sendPort);
      ring.addWorker('w2', ports[1].sendPort);

      ring.removeWorker('w1');

      // All keys should now go to w2
      for (var i = 0; i < 100; i++) {
        final worker = ring.find('key-$i');
        expect(worker!.id, equals('w2'));
      }
    });

    test('removeWorker handles non-existent worker', () {
      ring.addWorker('w1', ports[0].sendPort);

      expect(() => ring.removeWorker('non-existent'), returnsNormally);
    });

    test('find respects exclude set', () {
      ring.addWorker('w1', ports[0].sendPort);
      ring.addWorker('w2', ports[1].sendPort);
      ring.addWorker('w3', ports[2].sendPort);

      final worker = ring.find('test-key', exclude: {'w1', 'w2'});
      expect(worker!.id, equals('w3'));
    });

    test('find returns null when all workers excluded', () {
      ring.addWorker('w1', ports[0].sendPort);
      ring.addWorker('w2', ports[1].sendPort);

      final worker = ring.find('test-key', exclude: {'w1', 'w2'});
      expect(worker, isNull);
    });

    test('find skips unhealthy workers', () {
      ring.addWorker('w1', ports[0].sendPort);
      ring.addWorker('w2', ports[1].sendPort);
      ring.addWorker('w3', ports[2].sendPort);

      ring.setHealthy('w1', false);
      ring.setHealthy('w2', false);

      // All keys should go to w3 (only healthy one)
      for (var i = 0; i < 50; i++) {
        final worker = ring.find('key-$i');
        expect(worker!.id, equals('w3'));
      }
    });

    test('find falls back to unhealthy workers when no healthy available', () {
      ring.addWorker('w1', ports[0].sendPort);
      ring.setHealthy('w1', false);

      final worker = ring.find('test-key');
      expect(worker, isNotNull);
      expect(worker!.healthy, isFalse);
    });

    test('setHealthy updates worker health status', () {
      ring.addWorker('w1', ports[0].sendPort);

      expect(ring.allWorkers.first.healthy, isTrue);

      ring.setHealthy('w1', false);
      expect(ring.allWorkers.first.healthy, isFalse);

      ring.setHealthy('w1', true);
      expect(ring.allWorkers.first.healthy, isTrue);
    });

    test('updateMetrics updates worker metrics', () {
      ring.addWorker('w1', ports[0].sendPort);

      ring.updateMetrics('w1', pendingCount: 5, avgLatencyUs: 1000);

      final worker = ring.allWorkers.first;
      expect(worker.pendingCount, equals(5));
      expect(worker.avgLatencyUs, equals(1000));
    });

    test('allWorkers returns all workers', () {
      ring.addWorker('w1', ports[0].sendPort);
      ring.addWorker('w2', ports[1].sendPort);
      ring.addWorker('w3', ports[2].sendPort);

      final workers = ring.allWorkers;
      expect(workers.length, equals(3));
      expect(workers.map((w) => w.id), containsAll(['w1', 'w2', 'w3']));
    });

    test('isEmpty returns true when no workers', () {
      expect(ring.isEmpty, isTrue);

      ring.addWorker('w1', ports[0].sendPort);
      expect(ring.isEmpty, isFalse);

      ring.removeWorker('w1');
      expect(ring.isEmpty, isTrue);
    });

    test('workerCount returns correct count', () {
      expect(ring.workerCount, equals(0));

      ring.addWorker('w1', ports[0].sendPort);
      expect(ring.workerCount, equals(1));

      ring.addWorker('w2', ports[1].sendPort);
      expect(ring.workerCount, equals(2));

      ring.removeWorker('w1');
      expect(ring.workerCount, equals(1));
    });

    test('clear removes all workers', () {
      ring.addWorker('w1', ports[0].sendPort);
      ring.addWorker('w2', ports[1].sendPort);
      ring.addWorker('w3', ports[2].sendPort);

      ring.clear();

      expect(ring.isEmpty, isTrue);
      expect(ring.workerCount, equals(0));
      expect(ring.find('test-key'), isNull);
    });

    test('redistribution occurs when worker added', () {
      ring.addWorker('w1', ports[0].sendPort);
      ring.addWorker('w2', ports[1].sendPort);

      // Record initial assignments
      final initialAssignments = <String, String>{};
      for (var i = 0; i < 100; i++) {
        final key = 'key-$i';
        initialAssignments[key] = ring.find(key)!.id;
      }

      // Add new worker
      ring.addWorker('w3', ports[2].sendPort);

      // Count redistributed keys
      var redistributed = 0;
      var goToNew = 0;
      for (var i = 0; i < 100; i++) {
        final key = 'key-$i';
        final newWorker = ring.find(key)!.id;
        if (newWorker != initialAssignments[key]) {
          redistributed++;
        }
        if (newWorker == 'w3') {
          goToNew++;
        }
      }

      // Some keys should be redistributed to the new worker
      expect(goToNew, greaterThan(0));
      // Most original assignments should be preserved
      expect(redistributed, lessThan(100)); // Not all keys should move
    });

    test('minimal redistribution when worker removed', () {
      ring.addWorker('w1', ports[0].sendPort);
      ring.addWorker('w2', ports[1].sendPort);
      ring.addWorker('w3', ports[2].sendPort);

      // Record initial assignments (excluding w3 keys)
      final initialAssignments = <String, String>{};
      for (var i = 0; i < 100; i++) {
        final key = 'key-$i';
        final worker = ring.find(key)!.id;
        if (worker != 'w3') {
          initialAssignments[key] = worker;
        }
      }

      // Remove w3
      ring.removeWorker('w3');

      // Keys that were assigned to w1 or w2 should mostly stay
      var stayed = 0;
      for (final entry in initialAssignments.entries) {
        final newWorker = ring.find(entry.key)!.id;
        if (newWorker == entry.value) {
          stayed++;
        }
      }

      // Most keys should stay with original workers
      expect(stayed, greaterThan(initialAssignments.length * 0.8));
    });
  });
}
