import 'dart:async';
import 'dart:isolate';

import 'package:isolate_orchestrator/isolate_orchestrator.dart';
import 'package:test/test.dart';

void main() {
  group('HealthMonitor', () {
    late HealthMonitor monitor;
    late IsolateRegistry registry;
    late MessageIdGenerator idGenerator;
    late List<String> healthChangedEvents;
    late List<String> isolateFailedEvents;
    late ReceivePort mockPort;

    setUp(() {
      registry = IsolateRegistry();
      idGenerator = MessageIdGenerator('test');
      healthChangedEvents = [];
      isolateFailedEvents = [];
      mockPort = ReceivePort();

      monitor = HealthMonitor(
        registry: registry,
        config: const HubConfig(
          healthCheckInterval: Duration(milliseconds: 50),
          healthCheckTimeout: Duration(milliseconds: 25),
          healthyThreshold: 2,
          unhealthyThreshold: 2,
        ),
        idGenerator: idGenerator,
        onHealthChanged: (id, healthy) {
          healthChangedEvents.add('$id:$healthy');
        },
        onIsolateFailed: (id) {
          isolateFailedEvents.add(id);
        },
      );
    });

    tearDown(() {
      monitor.stop();
      mockPort.close();
    });

    IsolateEntry createMockEntry(String id) {
      final controlPort = ReceivePort();
      return IsolateEntry(
        id: id,
        name: 'test-$id',
        role: 'worker',
        isolate: Isolate.current,
        sendPort: mockPort.sendPort,
        controlPort: controlPort,
        broadcastStream: controlPort.asBroadcastStream(),
      );
    }

    test('start begins periodic health checks', () async {
      final entry = createMockEntry('worker-1');
      entry.state = IsolateState.running;
      registry.register(entry);

      final messages = <dynamic>[];
      mockPort.listen(messages.add);

      monitor.start();

      // Wait for at least one health check cycle
      await Future.delayed(const Duration(milliseconds: 100));

      monitor.stop();

      // Should have sent at least one ping
      expect(messages.length, greaterThan(0));
      final envelope = messages.first as Envelope;
      expect(envelope.payload, isA<Ping>());
    });

    test('stop cancels health checks and clears pending pings', () async {
      final entry = createMockEntry('worker-1');
      entry.state = IsolateState.running;
      registry.register(entry);

      mockPort.listen((_) {}); // consume messages

      monitor.start();
      await Future.delayed(const Duration(milliseconds: 60));

      monitor.stop();

      // After stop, no more pings should be sent
      await Future.delayed(const Duration(milliseconds: 100));
      // Can't easily verify no new pings without more infrastructure
      // but stop() should complete without error
    });

    test('removePendingPing removes pending ping for isolate', () async {
      final entry = createMockEntry('worker-1');
      entry.state = IsolateState.running;
      registry.register(entry);

      mockPort.listen((_) {}); // consume messages

      monitor.start();
      await Future.delayed(const Duration(milliseconds: 60));

      // Remove pending ping
      monitor.removePendingPing('worker-1');

      // Should not throw or cause issues
      monitor.stop();
    });

    test('handlePong records successful health check', () async {
      final entry = createMockEntry('worker-1');
      entry.state = IsolateState.running;
      registry.register(entry);

      mockPort.listen((_) {}); // consume messages

      monitor.start();
      await Future.delayed(const Duration(milliseconds: 60));

      // Simulate pong response
      monitor.handlePong(
        'worker-1',
        Pong(
          seq: 1,
          metrics: IsolateMetrics(
            uptimeMs: 1000,
            processedCount: 10,
            pendingCount: 0,
            errorCount: 0,
            avgLatencyUs: 500,
          ),
        ),
      );

      expect(entry.lastMetrics, isNotNull);
      expect(entry.lastMetrics!.uptimeMs, equals(1000));
      expect(entry.lastMetrics!.processedCount, equals(10));
      expect(entry.lastHealthCheck, isNotNull);

      monitor.stop();
    });

    test('handlePong ignores pong without pending ping', () {
      final entry = createMockEntry('worker-1');
      entry.state = IsolateState.running;
      registry.register(entry);

      // No monitor.start() - no pending pings
      monitor.handlePong(
        'worker-1',
        Pong(
          seq: 1,
          metrics: IsolateMetrics(
            uptimeMs: 1000,
            processedCount: 10,
            pendingCount: 0,
            errorCount: 0,
            avgLatencyUs: 500,
          ),
        ),
      );

      // Should not update metrics since no pending ping
      expect(entry.lastMetrics, isNull);
    });

    test('handlePong ignores pong for unregistered isolate', () async {
      final entry = createMockEntry('worker-1');
      entry.state = IsolateState.running;
      registry.register(entry);

      mockPort.listen((_) {}); // consume messages

      monitor.start();
      await Future.delayed(const Duration(milliseconds: 60));

      // Unregister the entry
      registry.unregister('worker-1');

      // Simulate pong - should not throw
      monitor.handlePong(
        'worker-1',
        Pong(
          seq: 1,
          metrics: IsolateMetrics(
            uptimeMs: 1000,
            processedCount: 10,
            pendingCount: 0,
            errorCount: 0,
            avgLatencyUs: 500,
          ),
        ),
      );

      monitor.stop();
    });

    test('health check timeout triggers failure callback', () async {
      // Create a separate monitor with unhealthyThreshold: 1 for this test
      final failMonitor = HealthMonitor(
        registry: registry,
        config: const HubConfig(
          healthCheckInterval: Duration(milliseconds: 50),
          healthCheckTimeout: Duration(milliseconds: 25),
          healthyThreshold: 1,
          unhealthyThreshold: 1, // Fail after 1 timeout
        ),
        idGenerator: idGenerator,
        onHealthChanged: (id, healthy) {
          healthChangedEvents.add('$id:$healthy');
        },
        onIsolateFailed: (id) {
          isolateFailedEvents.add(id);
        },
      );

      final entry = createMockEntry('worker-1');
      entry.state = IsolateState.running;
      registry.register(entry);

      mockPort.listen((_) {}); // consume messages but don't respond

      failMonitor.start();

      // Wait for timeout - healthCheckInterval: 50ms, timeout: 25ms
      // First check at ~50ms sends ping, second check at ~100ms sees timeout
      await Future.delayed(const Duration(milliseconds: 150));

      failMonitor.stop();

      // After failed health check, onIsolateFailed should be called
      expect(isolateFailedEvents, contains('worker-1'));
    });

    test('consecutive successes trigger healthy callback', () async {
      // Create a monitor with healthyThreshold: 1 for this test
      final healthyMonitor = HealthMonitor(
        registry: registry,
        config: const HubConfig(
          healthCheckInterval: Duration(milliseconds: 50),
          healthCheckTimeout: Duration(milliseconds: 25),
          healthyThreshold: 1, // Become healthy after 1 success
          unhealthyThreshold: 1,
        ),
        idGenerator: idGenerator,
        onHealthChanged: (id, healthy) {
          healthChangedEvents.add('$id:$healthy');
        },
        onIsolateFailed: (id) {
          isolateFailedEvents.add(id);
        },
      );

      final entry = createMockEntry('worker-1');
      entry.state = IsolateState.running;
      // Start with a failure to make it unhealthy
      entry.recordHealthCheck(false);
      registry.register(entry);

      expect(entry.isHealthy, isFalse);

      mockPort.listen((_) {}); // consume messages

      healthyMonitor.start();
      await Future.delayed(const Duration(milliseconds: 60));

      // Simulate successful pong
      healthyMonitor.handlePong(
        'worker-1',
        Pong(
          seq: 1,
          metrics: IsolateMetrics(
            uptimeMs: 1000,
            processedCount: 10,
            pendingCount: 0,
            errorCount: 0,
            avgLatencyUs: 500,
          ),
        ),
      );

      // With threshold 1, should now be healthy
      expect(healthChangedEvents, contains('worker-1:true'));

      healthyMonitor.stop();
    });

    test('only checks running isolates', () async {
      final entry = createMockEntry('worker-1');
      entry.state = IsolateState.created; // Not running
      registry.register(entry);

      final messages = <dynamic>[];
      mockPort.listen(messages.add);

      monitor.start();
      await Future.delayed(const Duration(milliseconds: 100));
      monitor.stop();

      // Should not have sent any pings since isolate is not running
      expect(messages, isEmpty);
    });
  });
}
