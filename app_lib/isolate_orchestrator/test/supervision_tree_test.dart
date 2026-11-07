import 'dart:async';
import 'dart:isolate';

import 'package:isolate_orchestrator/isolate_orchestrator.dart';
import 'package:test/test.dart';

class ServiceCmd {
  final String action;
  final Object? payload;

  ServiceCmd(this.action, [this.payload]);
}

class SupervisedTestWorker extends Worker<ServiceCmd>
    with WorkerMetricsMixin<ServiceCmd> {
  @override
  final WorkerContext context;

  int _stateCounter = 0;

  SupervisedTestWorker(this.context);

  @override
  Future<void> onInit(Map<String, dynamic> config) async {
    initMetrics();
    if (config['failInit'] == true) {
      throw StateError('Simulated initialization failure');
    }
  }

  @override
  Future<ServiceCmd> onTask(
    ServiceCmd data, {
    String? taskType,
    Map<String, dynamic>? metadata,
  }) async {
    final res = await onCall(
      data.action,
      sender: IsolateAddress.hub,
      metadata: metadata,
    );
    return ServiceCmd('result', res);
  }

  @override
  Future<Object?> onCall(
    Object? request, {
    required IsolateAddress sender,
    Map<String, dynamic>? metadata,
  }) async {
    switch (request) {
      case 'id':
        return context.id;
      case 'path':
        return context.path;
      case 'inc':
        return ++_stateCounter;
      case 'crash':
        Isolate.exit();
      case 'throw_unhandled':
        Timer.run(() {
          throw StateError('Uncaught async error in isolate');
        });
        return 'scheduled_throw';
      case 'normal_stop':
        Timer(const Duration(milliseconds: 10), () {
          context.stopSelf();
        });
        return 'stopping_normally';
      default:
        return 'echo:$request';
    }
  }

  @override
  Future<void> onCast(
    Object? message, {
    required IsolateAddress sender,
    Map<String, dynamic>? metadata,
  }) async {
    if (message == 'crash') {
      Isolate.exit();
    } else if (message == 'normal_stop') {
      context.stopSelf();
    } else if (message == 'inc') {
      _stateCounter++;
    }
  }

  @override
  Future<void> onShutdown() async {}
}

void supervisedWorkerEntryPoint(SendPort hubPort) {
  runWorker<ServiceCmd>(hubPort, (ctx) => SupervisedTestWorker(ctx));
}

Future<void> _waitForCondition(
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 5),
  Duration pollInterval = const Duration(milliseconds: 25),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!predicate()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('Condition not met within $timeout');
    }
    await Future.delayed(pollInterval);
  }
}

void main() {
  group('RestartIntensityTracker', () {
    test('allows restarts within limit and rejects when exceeded', () {
      final tracker = RestartIntensityTracker(
        const RestartIntensity(
          maxRestarts: 3,
          withinDuration: Duration(seconds: 5),
        ),
      );

      final t0 = DateTime(2026, 1, 1, 12, 0, 0);
      expect(tracker.recordAndCheck(t0), isTrue);
      expect(
        tracker.recordAndCheck(t0.add(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        tracker.recordAndCheck(t0.add(const Duration(seconds: 2))),
        isTrue,
      );
      // 4th restart within 5s window should fail
      expect(
        tracker.recordAndCheck(t0.add(const Duration(seconds: 3))),
        isFalse,
      );

      // After sliding window passes (t0 + 6s), t0 is pruned so a new restart is allowed
      expect(
        tracker.recordAndCheck(t0.add(const Duration(seconds: 6))),
        isTrue,
      );
    });
  });

  group('Supervision Tree & ServiceGroup Lifecycle', () {
    late IsolateHub hub;

    setUp(() async {
      hub = IsolateHub(
        config: const HubConfig(
          healthCheckInterval: Duration(seconds: 5),
          healthCheckTimeout: Duration(seconds: 2),
        ),
      );
      await hub.start();
    });

    tearDown(() async {
      await hub.stop(timeout: const Duration(seconds: 3));
    });

    test(
      'creates nested service groups, inspects treeSnapshot, and stops/starts subtrees',
      () async {
        final networkGroup = await hub.createGroup(
          name: 'network',
          strategy: SupervisionStrategy.oneForAll,
        );

        final dnsNode = await networkGroup.registerService(
          const ChildSpec(
            name: 'dns',
            role: 'resolver',
            capabilities: ['doh', 'dot'],
            entryPoint: supervisedWorkerEntryPoint,
          ),
        );

        final proxyNode = await networkGroup.registerService(
          const ChildSpec(
            name: 'proxy',
            role: 'gateway',
            capabilities: ['socks5'],
            entryPoint: supervisedWorkerEntryPoint,
          ),
        );

        expect(networkGroup.path, equals('/network'));
        expect(dnsNode.path, equals('/network/dns'));
        expect(proxyNode.path, equals('/network/proxy'));
        expect(dnsNode.isRunning, isTrue);
        expect(proxyNode.isRunning, isTrue);

        // Multi-index lookup checks
        expect(hub.getByName('dns')?.id, equals(dnsNode.currentIsolateId));
        expect(
          hub.getByPath('/network/dns')?.id,
          equals(dnsNode.currentIsolateId),
        );
        expect(hub.getByCapability('doh').length, equals(1));
        expect(hub.lookup('socks5')?.id, equals(proxyNode.currentIsolateId));

        // Tree snapshot verification
        final snapshot = hub.treeSnapshot();
        expect(snapshot.path, equals('/'));
        expect(snapshot.children.length, equals(1));
        expect(snapshot.children.first.path, equals('/network'));
        expect(snapshot.children.first.children.length, equals(2));

        // Stop entire /network service group; specs must remain in tree
        final oldDnsId = dnsNode.currentIsolateId;
        await hub.stopNode('/network');

        expect(networkGroup.state, equals(NodeState.stopped));
        expect(dnsNode.state, equals(NodeState.stopped));
        expect(proxyNode.state, equals(NodeState.stopped));
        expect(hub.getByPath('/network/dns'), isNull);
        expect(hub.lookupNode('/network/dns'), same(dnsNode));

        // Start /network service group again
        await hub.startNode('/network');

        expect(networkGroup.state, equals(NodeState.running));
        expect(dnsNode.isRunning, isTrue);
        expect(proxyNode.isRunning, isTrue);
        expect(dnsNode.currentIsolateId, isNot(equals(oldDnsId)));
      },
    );

    test(
      'ChildRestartType: permanent, transient, and temporary semantics',
      () async {
        final group = await hub.createGroup(
          name: 'workers',
          strategy: SupervisionStrategy.oneForOne,
          intensity: const RestartIntensity(
            maxRestarts: 5,
            withinDuration: Duration(seconds: 10),
            backoffPolicy: RestartPolicy(
              initialDelay: Duration(milliseconds: 20),
            ),
          ),
        );

        final permNode = await group.registerService(
          const ChildSpec(
            name: 'perm',
            entryPoint: supervisedWorkerEntryPoint,
            restartType: ChildRestartType.permanent,
          ),
        );
        final transNode = await group.registerService(
          const ChildSpec(
            name: 'trans',
            entryPoint: supervisedWorkerEntryPoint,
            restartType: ChildRestartType.transient,
          ),
        );
        final tempNode = await group.registerService(
          const ChildSpec(
            name: 'temp',
            entryPoint: supervisedWorkerEntryPoint,
            restartType: ChildRestartType.temporary,
          ),
        );

        // 1. Temporary node crashes -> should NOT be restarted
        final tempOldId = tempNode.currentIsolateId!;
        hub.cast('/workers/temp', 'crash');
        await _waitForCondition(() => tempNode.state == NodeState.failed);
        await Future.delayed(const Duration(milliseconds: 80));
        expect(tempNode.isRunning, isFalse);
        expect(tempNode.restartCount, equals(0));
        expect(hub.getById(tempOldId), isNull);

        // 2. Transient node crashes abnormally -> SHOULD be restarted
        final transOldId = transNode.currentIsolateId!;
        hub.cast('/workers/trans', 'crash');
        await _waitForCondition(
          () =>
              transNode.isRunning &&
              transNode.currentIsolateId != null &&
              transNode.currentIsolateId != transOldId,
        );
        expect(transNode.restartCount, equals(1));

        // 3. Transient node stops normally via stopSelf() -> should NOT be restarted
        await hub.call<String>('/workers/trans', 'normal_stop');
        await _waitForCondition(() => transNode.state == NodeState.stopped);
        await Future.delayed(const Duration(milliseconds: 80));
        expect(transNode.isRunning, isFalse);
        expect(transNode.restartCount, equals(1));

        // 4. Permanent node stops normally via stopSelf() -> SHOULD still be restarted
        final permOldId = permNode.currentIsolateId!;
        await hub.call<String>('/workers/perm', 'normal_stop');
        await _waitForCondition(
          () =>
              permNode.isRunning &&
              permNode.currentIsolateId != null &&
              permNode.currentIsolateId != permOldId,
        );
        expect(permNode.restartCount, equals(1));
      },
    );

    test(
      'SupervisionStrategy.oneForOne only restarts the crashed child',
      () async {
        final group = await hub.createGroup(
          name: 'one_for_one_group',
          strategy: SupervisionStrategy.oneForOne,
          intensity: const RestartIntensity(
            maxRestarts: 5,
            withinDuration: Duration(seconds: 10),
            backoffPolicy: RestartPolicy(
              initialDelay: Duration(milliseconds: 20),
            ),
          ),
        );

        final nodeA = await group.registerService(
          const ChildSpec(name: 'a', entryPoint: supervisedWorkerEntryPoint),
        );
        final nodeB = await group.registerService(
          const ChildSpec(name: 'b', entryPoint: supervisedWorkerEntryPoint),
        );
        final nodeC = await group.registerService(
          const ChildSpec(name: 'c', entryPoint: supervisedWorkerEntryPoint),
        );

        final idA = nodeA.currentIsolateId!;
        final idB = nodeB.currentIsolateId!;
        final idC = nodeC.currentIsolateId!;

        // Crash B
        hub.cast('/one_for_one_group/b', 'crash');

        await _waitForCondition(
          () => nodeB.isRunning && nodeB.currentIsolateId != idB,
        );

        // A and C must remain untouched
        expect(nodeA.currentIsolateId, equals(idA));
        expect(nodeB.currentIsolateId, isNot(equals(idB)));
        expect(nodeC.currentIsolateId, equals(idC));
      },
    );

    test(
      'SupervisionStrategy.oneForAll restarts all sibling children when one crashes',
      () async {
        final group = await hub.createGroup(
          name: 'one_for_all_group',
          strategy: SupervisionStrategy.oneForAll,
          intensity: const RestartIntensity(
            maxRestarts: 5,
            withinDuration: Duration(seconds: 10),
            backoffPolicy: RestartPolicy(
              initialDelay: Duration(milliseconds: 20),
            ),
          ),
        );

        final nodeA = await group.registerService(
          const ChildSpec(
            name: 'ofa_a',
            entryPoint: supervisedWorkerEntryPoint,
          ),
        );
        final nodeB = await group.registerService(
          const ChildSpec(
            name: 'ofa_b',
            entryPoint: supervisedWorkerEntryPoint,
          ),
        );
        final nodeC = await group.registerService(
          const ChildSpec(
            name: 'ofa_c',
            entryPoint: supervisedWorkerEntryPoint,
          ),
        );

        final idA = nodeA.currentIsolateId!;
        final idB = nodeB.currentIsolateId!;
        final idC = nodeC.currentIsolateId!;

        // Crash B
        hub.cast('/one_for_all_group/ofa_b', 'crash');

        await _waitForCondition(
          () =>
              nodeA.isRunning &&
              nodeB.isRunning &&
              nodeC.isRunning &&
              nodeA.currentIsolateId != idA &&
              nodeB.currentIsolateId != idB &&
              nodeC.currentIsolateId != idC,
        );

        expect(nodeA.restartCount, equals(1));
        expect(nodeB.restartCount, equals(1));
        expect(nodeC.restartCount, equals(1));
      },
    );

    test(
      'SupervisionStrategy.restForOne restarts only failed child and subsequent children',
      () async {
        final group = await hub.createGroup(
          name: 'rest_for_one_group',
          strategy: SupervisionStrategy.restForOne,
          intensity: const RestartIntensity(
            maxRestarts: 5,
            withinDuration: Duration(seconds: 10),
            backoffPolicy: RestartPolicy(
              initialDelay: Duration(milliseconds: 20),
            ),
          ),
        );

        final nodeA = await group.registerService(
          const ChildSpec(
            name: 'rfo_a',
            entryPoint: supervisedWorkerEntryPoint,
          ),
        );
        final nodeB = await group.registerService(
          const ChildSpec(
            name: 'rfo_b',
            entryPoint: supervisedWorkerEntryPoint,
          ),
        );
        final nodeC = await group.registerService(
          const ChildSpec(
            name: 'rfo_c',
            entryPoint: supervisedWorkerEntryPoint,
          ),
        );

        final idA = nodeA.currentIsolateId!;
        final idB = nodeB.currentIsolateId!;
        final idC = nodeC.currentIsolateId!;

        // Crash B -> A stays running with idA; B and C both restart
        hub.cast('/rest_for_one_group/rfo_b', 'crash');

        await _waitForCondition(
          () =>
              nodeB.isRunning &&
              nodeC.isRunning &&
              nodeB.currentIsolateId != idB &&
              nodeC.currentIsolateId != idC,
        );

        expect(nodeA.currentIsolateId, equals(idA));
        expect(nodeA.restartCount, equals(0));
        expect(nodeB.restartCount, equals(1));
        expect(nodeC.restartCount, equals(1));
      },
    );

    test(
      'exceeding RestartIntensity emits SupervisorEscalated and stops group',
      () async {
        final escalations = <SupervisorEscalated>[];
        final sub = hub.events
            .where((e) => e is SupervisorEscalated)
            .cast<SupervisorEscalated>()
            .listen(escalations.add);

        final group = await hub.createGroup(
          name: 'fragile_group',
          strategy: SupervisionStrategy.oneForOne,
          restartType: ChildRestartType.temporary,
          intensity: const RestartIntensity(
            maxRestarts: 1,
            withinDuration: Duration(seconds: 10),
            backoffPolicy: RestartPolicy(
              initialDelay: Duration(milliseconds: 20),
            ),
          ),
        );

        final child = await group.registerService(
          const ChildSpec(
            name: 'fragile_worker',
            entryPoint: supervisedWorkerEntryPoint,
          ),
        );

        final firstId = child.currentIsolateId!;
        // First crash -> allowed (restart #1)
        hub.cast('/fragile_group/fragile_worker', 'crash');
        await _waitForCondition(
          () => child.isRunning && child.currentIsolateId != firstId,
        );

        // Second crash within window -> exceeds maxRestarts (1) -> escalates!
        hub.cast('/fragile_group/fragile_worker', 'crash');
        await _waitForCondition(() => escalations.isNotEmpty);
        await _waitForCondition(() => group.state == NodeState.failed);

        await sub.cancel();

        expect(escalations.first.supervisorPath, equals('/fragile_group'));
        expect(
          escalations.first.failedChildPath,
          equals('/fragile_group/fragile_worker'),
        );
        expect(child.isRunning, isFalse);
      },
    );
  });
}
