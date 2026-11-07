import 'dart:isolate';

import 'package:isolate_orchestrator/isolate_orchestrator.dart';
import 'package:test/test.dart';

void main() {
  group('IsolateEntry', () {
    late ReceivePort controlPort;
    late IsolateEntry entry;

    setUp(() {
      controlPort = ReceivePort();
      final broadcastStream = controlPort.asBroadcastStream();
      entry = IsolateEntry(
        id: 'worker-1',
        name: 'test-worker',
        role: 'worker',
        isolate: Isolate.current, // Using current isolate for testing
        sendPort: controlPort.sendPort,
        controlPort: controlPort,
        broadcastStream: broadcastStream,
        capabilities: ['compute'],
        subscribesTo: ['logger'],
      );
    });

    tearDown(() {
      controlPort.close();
    });

    test('initializes with correct values', () {
      expect(entry.id, equals('worker-1'));
      expect(entry.name, equals('test-worker'));
      expect(entry.role, equals('worker'));
      expect(entry.capabilities, equals(['compute']));
      expect(entry.subscribesTo, equals(['logger']));
      expect(entry.state, equals(IsolateState.created));
      expect(entry.restartCount, equals(0));
      expect(entry.consecutiveFailures, equals(0));
      expect(entry.consecutiveSuccesses, equals(0));
    });

    test('isHealthy returns false when not running', () {
      expect(entry.isHealthy, isFalse);
    });

    test('isHealthy returns true when running with no failures', () {
      entry.state = IsolateState.running;
      expect(entry.isHealthy, isTrue);
    });

    test('isHealthy returns false when running with failures', () {
      entry.state = IsolateState.running;
      entry.consecutiveFailures = 1;
      expect(entry.isHealthy, isFalse);
    });

    test('recordHealthCheck updates counters on success', () {
      entry.recordHealthCheck(true);
      expect(entry.consecutiveSuccesses, equals(1));
      expect(entry.consecutiveFailures, equals(0));
      expect(entry.lastHealthCheck, isNotNull);

      entry.recordHealthCheck(true);
      expect(entry.consecutiveSuccesses, equals(2));
    });

    test('recordHealthCheck updates counters on failure', () {
      entry.recordHealthCheck(false);
      expect(entry.consecutiveFailures, equals(1));
      expect(entry.consecutiveSuccesses, equals(0));

      entry.recordHealthCheck(false);
      expect(entry.consecutiveFailures, equals(2));
    });

    test('recordHealthCheck resets opposite counter', () {
      entry.recordHealthCheck(true);
      entry.recordHealthCheck(true);
      entry.recordHealthCheck(true);
      expect(entry.consecutiveSuccesses, equals(3));

      entry.recordHealthCheck(false);
      expect(entry.consecutiveSuccesses, equals(0));
      expect(entry.consecutiveFailures, equals(1));

      entry.recordHealthCheck(true);
      expect(entry.consecutiveSuccesses, equals(1));
      expect(entry.consecutiveFailures, equals(0));
    });
  });

  group('IsolateRegistry', () {
    late IsolateRegistry registry;
    late ReceivePort port1;
    late ReceivePort port2;
    late ReceivePort port3;

    setUp(() {
      registry = IsolateRegistry();
      port1 = ReceivePort();
      port2 = ReceivePort();
      port3 = ReceivePort();
    });

    tearDown(() {
      port1.close();
      port2.close();
      port3.close();
    });

    IsolateEntry createEntry(String id, String role, ReceivePort port) {
      return IsolateEntry(
        id: id,
        name: id,
        role: role,
        isolate: Isolate.current,
        sendPort: port.sendPort,
        controlPort: port,
        broadcastStream: port.asBroadcastStream(),
      );
    }

    test('register adds entry', () {
      final entry = createEntry('w1', 'worker', port1);
      registry.register(entry);

      expect(registry.count, equals(1));
      expect(registry.get('w1'), equals(entry));
    });

    test('register multiple entries', () {
      registry.register(createEntry('w1', 'worker', port1));
      registry.register(createEntry('w2', 'worker', port2));
      registry.register(createEntry('l1', 'logger', port3));

      expect(registry.count, equals(3));
      expect(registry.countByRole('worker'), equals(2));
      expect(registry.countByRole('logger'), equals(1));
    });

    test('unregister removes entry', () {
      final entry = createEntry('w1', 'worker', port1);
      registry.register(entry);
      registry.unregister('w1');

      expect(registry.count, equals(0));
      expect(registry.get('w1'), isNull);
    });

    test('unregister non-existent id does nothing', () {
      registry.register(createEntry('w1', 'worker', port1));
      registry.unregister('non-existent');

      expect(registry.count, equals(1));
    });

    test('getByRole returns entries for role', () {
      registry.register(createEntry('w1', 'worker', port1));
      registry.register(createEntry('w2', 'worker', port2));
      registry.register(createEntry('l1', 'logger', port3));

      final workers = registry.getByRole('worker');
      expect(workers.length, equals(2));
      expect(workers.map((e) => e.id), containsAll(['w1', 'w2']));

      final loggers = registry.getByRole('logger');
      expect(loggers.length, equals(1));
      expect(loggers.first.id, equals('l1'));
    });

    test('getByRole returns empty list for unknown role', () {
      expect(registry.getByRole('unknown'), isEmpty);
    });

    test('getPortsForRole returns ports for running isolates only', () {
      final entry1 = createEntry('w1', 'worker', port1);
      entry1.state = IsolateState.running;
      registry.register(entry1);

      final entry2 = createEntry('w2', 'worker', port2);
      entry2.state = IsolateState.starting;
      registry.register(entry2);

      final ports = registry.getPortsForRole('worker');
      expect(ports.length, equals(1));
      expect(ports.first.id, equals('w1'));
    });

    test('all returns all entries', () {
      registry.register(createEntry('w1', 'worker', port1));
      registry.register(createEntry('w2', 'worker', port2));

      expect(registry.all.length, equals(2));
    });

    test('running returns only running entries', () {
      final entry1 = createEntry('w1', 'worker', port1);
      entry1.state = IsolateState.running;
      registry.register(entry1);

      final entry2 = createEntry('w2', 'worker', port2);
      entry2.state = IsolateState.stopped;
      registry.register(entry2);

      expect(registry.running.length, equals(1));
      expect(registry.running.first.id, equals('w1'));
    });

    test('contains checks existence', () {
      registry.register(createEntry('w1', 'worker', port1));

      expect(registry.contains('w1'), isTrue);
      expect(registry.contains('w2'), isFalse);
    });

    test('clear removes all entries', () {
      registry.register(createEntry('w1', 'worker', port1));
      registry.register(createEntry('w2', 'worker', port2));

      registry.clear();

      expect(registry.count, equals(0));
      expect(registry.countByRole('worker'), equals(0));
    });
  });

  group('IsolateState', () {
    test('has all expected states', () {
      expect(IsolateState.values, contains(IsolateState.created));
      expect(IsolateState.values, contains(IsolateState.starting));
      expect(IsolateState.values, contains(IsolateState.running));
      expect(IsolateState.values, contains(IsolateState.stopping));
      expect(IsolateState.values, contains(IsolateState.stopped));
      expect(IsolateState.values, contains(IsolateState.failed));
    });
  });
}
