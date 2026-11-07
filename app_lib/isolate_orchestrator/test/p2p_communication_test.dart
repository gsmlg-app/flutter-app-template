import 'dart:async';
import 'dart:isolate';

import 'package:isolate_orchestrator/isolate_orchestrator.dart';
import 'package:test/test.dart';

class KvStoreWorker extends Worker<Map<String, dynamic>>
    with WorkerMetricsMixin<Map<String, dynamic>> {
  @override
  final WorkerContext context;

  final Map<String, Object?> _store = {};

  KvStoreWorker(this.context);

  @override
  Future<void> onInit(Map<String, dynamic> config) async {
    initMetrics();
    if (config['seed'] is Map) {
      final seed = config['seed'] as Map;
      for (final entry in seed.entries) {
        _store['${entry.key}'] = entry.value;
      }
    }
  }

  @override
  Future<Map<String, dynamic>> onTask(
    Map<String, dynamic> data, {
    String? taskType,
    Map<String, dynamic>? metadata,
  }) async {
    final res = await onCall(
      data,
      sender: IsolateAddress.hub,
      metadata: metadata,
    );
    return {'result': res, 'workerId': context.id};
  }

  @override
  Future<Object?> onCall(
    Object? request, {
    required IsolateAddress sender,
    Map<String, dynamic>? metadata,
  }) async {
    if (request is Map) {
      final op = request['op'] as String?;
      switch (op) {
        case 'get':
          return _store[request['key'] as String];
        case 'set':
          final key = request['key'] as String;
          final val = request['value'];
          _store[key] = val;
          return 'ok';
        case 'whoami':
          return {'id': context.id, 'name': context.name, 'path': context.path};
        case 'fail':
          throw ArgumentError('Invalid operation requested');
      }
    }
    return null;
  }

  @override
  Future<void> onCast(
    Object? message, {
    required IsolateAddress sender,
    Map<String, dynamic>? metadata,
  }) async {
    if (message is Map) {
      final op = message['op'] as String?;
      if (op == 'set') {
        _store[message['key'] as String] = message['value'];
      } else if (op == 'crash') {
        Isolate.exit();
      }
    }
  }

  @override
  Future<void> onShutdown() async {}
}

class ApiGatewayWorker extends Worker<Map<String, dynamic>>
    with WorkerMetricsMixin<Map<String, dynamic>> {
  @override
  final WorkerContext context;

  ApiGatewayWorker(this.context);

  @override
  Future<void> onInit(Map<String, dynamic> config) async {
    initMetrics();
  }

  @override
  Future<Map<String, dynamic>> onTask(
    Map<String, dynamic> data, {
    String? taskType,
    Map<String, dynamic>? metadata,
  }) async {
    final res = await onCall(
      data,
      sender: IsolateAddress.hub,
      metadata: metadata,
    );
    return res as Map<String, dynamic>;
  }

  @override
  Future<Object?> onCall(
    Object? request, {
    required IsolateAddress sender,
    Map<String, dynamic>? metadata,
  }) async {
    if (request is Map) {
      final target = request['target'] as String;
      final mode = request['mode'] as String? ?? 'call';
      final payload = request['payload'];

      if (mode == 'cast') {
        await context.cast(target, payload);
        return {'casted': true};
      } else {
        final remoteRes = await context.call<Object?>(target, payload);
        return {'fromGateway': context.id, 'remote': remoteRes};
      }
    }
    return null;
  }

  @override
  Future<void> onShutdown() async {}
}

void kvStoreEntryPoint(SendPort hubPort) {
  runWorker<Map<String, dynamic>>(hubPort, (ctx) => KvStoreWorker(ctx));
}

void apiGatewayEntryPoint(SendPort hubPort) {
  runWorker<Map<String, dynamic>>(hubPort, (ctx) => ApiGatewayWorker(ctx));
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
  group('P2P Cross-Isolate call and cast Communication', () {
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
      'Hub can call and cast to isolate by path, name, id, role, or capability',
      () async {
        final storageGroup = await hub.createGroup(name: 'storage');
        final kvNode = await storageGroup.registerService(
          const ChildSpec(
            name: 'kv',
            role: 'database',
            capabilities: ['key_value'],
            entryPoint: kvStoreEntryPoint,
          ),
        );

        // 1. Cast by path
        hub.cast('/storage/kv', {
          'op': 'set',
          'key': 'greeting',
          'value': 'hi',
        });
        await Future.delayed(const Duration(milliseconds: 30));

        // 2. Call by name
        final valByName = await hub.call<String>('kv', {
          'op': 'get',
          'key': 'greeting',
        });
        expect(valByName, equals('hi'));

        // 3. Call by role
        final valByRole = await hub.call<String>('database', {
          'op': 'get',
          'key': 'greeting',
        });
        expect(valByRole, equals('hi'));

        // 4. Call by capability
        final valByCap = await hub.call<String>('key_value', {
          'op': 'get',
          'key': 'greeting',
        });
        expect(valByCap, equals('hi'));

        // 5. Call by ID
        final who = await hub.call<Map<dynamic, dynamic>>(
          kvNode.currentIsolateId!,
          {'op': 'whoami'},
        );
        expect(who['path'], equals('/storage/kv'));

        // 6. Error propagation in RPC call
        await expectLater(
          hub.call<Object?>('/storage/kv', {'op': 'fail'}),
          throwsA(isA<TaskException>()),
        );
      },
    );

    test(
      'Child isolate can P2P call and cast to another child isolate and auto-refreshes port on restart',
      () async {
        final backendGroup = await hub.createGroup(
          name: 'backend',
          strategy: SupervisionStrategy.oneForOne,
          intensity: const RestartIntensity(
            maxRestarts: 5,
            withinDuration: Duration(seconds: 10),
            backoffPolicy: RestartPolicy(
              initialDelay: Duration(milliseconds: 20),
            ),
          ),
        );

        final kvNode = await backendGroup.registerService(
          const ChildSpec(
            name: 'kv_store',
            role: 'storage',
            entryPoint: kvStoreEntryPoint,
            config: {
              'seed': {'version': 'v1'},
            },
          ),
        );

        await hub.registerService(
          const ChildSpec(
            name: 'gateway',
            role: 'edge',
            entryPoint: apiGatewayEntryPoint,
          ),
        );

        // Gateway calls kv_store by tree path '/backend/kv_store'
        final res1 = await hub.call<Map<dynamic, dynamic>>('/gateway', {
          'target': '/backend/kv_store',
          'mode': 'call',
          'payload': {'op': 'whoami'},
        });
        final remote1 = res1['remote'] as Map<dynamic, dynamic>;
        final firstKvId = kvNode.currentIsolateId!;
        expect(remote1['id'], equals(firstKvId));

        // Gateway casts to kv_store by name 'kv_store'
        await hub.call<Map<dynamic, dynamic>>('/gateway', {
          'target': 'kv_store',
          'mode': 'cast',
          'payload': {'op': 'set', 'key': 'token', 'value': 'secret-123'},
        });
        await Future.delayed(const Duration(milliseconds: 30));

        // Gateway reads back the value via cached SendPort
        final tokenRes = await hub.call<Map<dynamic, dynamic>>('/gateway', {
          'target': '/backend/kv_store',
          'mode': 'call',
          'payload': {'op': 'get', 'key': 'token'},
        });
        expect(tokenRes['remote'], equals('secret-123'));

        // Now crash kv_store! Supervisor will respawn it with a new Isolate & SendPort,
        // and Hub will push PortUpdate to Gateway so Gateway's cache is updated.
        hub.cast('/backend/kv_store', {'op': 'crash'});

        await _waitForCondition(
          () => kvNode.isRunning && kvNode.currentIsolateId != firstKvId,
        );
        // Allow PortUpdate to arrive at gateway isolate
        await Future.delayed(const Duration(milliseconds: 50));

        final secondKvId = kvNode.currentIsolateId!;
        expect(secondKvId, isNot(equals(firstKvId)));

        // Gateway calls '/backend/kv_store' again -> transparently talks to the new isolate!
        final res2 = await hub.call<Map<dynamic, dynamic>>('/gateway', {
          'target': '/backend/kv_store',
          'mode': 'call',
          'payload': {'op': 'whoami'},
        });
        final remote2 = res2['remote'] as Map<dynamic, dynamic>;
        expect(remote2['id'], equals(secondKvId));
      },
    );
  });
}
