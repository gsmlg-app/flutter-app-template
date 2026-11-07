import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:duskmoon_ui/duskmoon_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_template/destination.dart';
import 'package:flutter_app_template/screens/showcase/showcase_screen.dart';
import 'package:flutter_app_template/widgets/app_adaptive_scaffold.dart';
import 'package:isolate_orchestrator/isolate_orchestrator.dart';

/// Worker running inside spawned OS isolates for the Showcase screen.
///
/// Supports multi-hop P2P data forwarding (`pipeline_hop`) using `context.call`,
/// direct RPC `ping`, poolboy `compute` tasks, and simulated crashes (`Isolate.exit()`).
class _ShowcaseIsolateWorker extends Worker<Map<String, dynamic>>
    with WorkerMetricsMixin<Map<String, dynamic>> {
  @override
  final WorkerContext context;

  int _customCounter = 0;

  _ShowcaseIsolateWorker(this.context);

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
    final start = DateTime.now();
    final delayMs = (data['delayMs'] as int?) ?? 40;
    if (delayMs > 0) {
      await Future<void>.delayed(Duration(milliseconds: delayMs));
    }

    if (data['op'] == 'crash') {
      Isolate.exit();
    }

    _customCounter++;
    recordSuccess(DateTime.now().difference(start));
    return {
      'workerId': context.id,
      'name': context.name,
      'path': context.path,
      'count': _customCounter,
      'value': ((data['value'] as int?) ?? 1) * 2,
    };
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
        case 'ping':
          _customCounter++;
          return {
            'pongFrom': context.path,
            'id': context.id,
            'count': _customCounter,
          };

        case 'stage_process':
          final input = '${request['data'] ?? ''}';
          final delayMs = (request['delayMs'] as num?)?.toInt() ?? 1000;
          final stopwatch = Stopwatch()..start();
          if (delayMs > 0) {
            await Future<void>.delayed(Duration(milliseconds: delayMs));
          }
          _customCounter++;
          final transformed = _transformAtNode(context.name, input);
          stopwatch.stop();
          return {
            'step': request['step'] ?? 1,
            'nodePath': context.path,
            'isolateId': context.id,
            'input': input,
            'output': transformed,
            'elapsedMs': stopwatch.elapsedMilliseconds,
          };

        case 'pipeline_hop':
          // Multi-isolate P2P data flow pipeline!
          final input = '${request['data'] ?? ''}';
          final remainingTargets =
              (request['targets'] as List<dynamic>?)
                  ?.map((e) => '$e')
                  .toList() ??
              <String>[];
          final hops =
              (request['hops'] as List<dynamic>?)
                  ?.map((e) => Map<String, dynamic>.from(e as Map))
                  .toList() ??
              <Map<String, dynamic>>[];

          _customCounter++;
          final transformed = _transformAtNode(context.name, input);
          hops.add({
            'step': hops.length + 1,
            'nodePath': context.path,
            'isolateId': context.id,
            'input': input,
            'output': transformed,
          });

          if (remainingTargets.isNotEmpty) {
            final nextTarget = remainingTargets.first;
            final nextRemaining = remainingTargets.sublist(1);
            return await context.call<Map<dynamic, dynamic>>(nextTarget, {
              'op': 'pipeline_hop',
              'data': transformed,
              'targets': nextRemaining,
              'hops': hops,
            });
          }

          return {'finalOutput': transformed, 'hops': hops};

        case 'p2p_call':
          final target = request['target'] as String;
          final remote = await context.call<Map<dynamic, dynamic>>(target, {
            'op': 'ping',
            'from': context.path,
          });
          _customCounter++;
          return {'caller': context.path, 'remote': remote};

        case 'normal_stop':
          Timer(const Duration(milliseconds: 20), context.stopSelf);
          return {'stopping': context.path};

        case 'crash':
          Isolate.exit();
      }
    }
    return {'echo': request, 'path': context.path};
  }

  String _transformAtNode(String nodeName, String input) {
    return switch (nodeName) {
      'ingress' => '[Ingress✓] ${input.trim()}',
      'transform' => '$input -> UPPER(${input.toUpperCase()})',
      'cache' =>
        '$input -> #CRC(${input.codeUnits.fold<int>(0, (a, b) => a + b)})',
      _ => '$input -> [$nodeName#$_customCounter]',
    };
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
    } else {
      _customCounter++;
    }
  }

  @override
  Future<void> onShutdown() async {}
}

/// Entry point for isolates spawned from [IsolateDemoScreen].
@pragma('vm:entry-point')
void showcaseIsolateEntryPoint(SendPort hubPort) {
  runWorker<Map<String, dynamic>>(
    hubPort,
    (context) => _ShowcaseIsolateWorker(context),
  );
}

enum _HopStatus { pending, processing, completed, failed }

class _PipelineHopRecord {
  final int step;
  final String fromNode;
  final String toNode;
  final String isolateId;
  final String dataSnapshot;
  final _HopStatus status;
  final int? elapsedMs;

  const _PipelineHopRecord({
    required this.step,
    required this.fromNode,
    required this.toNode,
    required this.isolateId,
    required this.dataSnapshot,
    this.status = _HopStatus.completed,
    this.elapsedMs,
  });

  _PipelineHopRecord copyWith({
    int? step,
    String? fromNode,
    String? toNode,
    String? isolateId,
    String? dataSnapshot,
    _HopStatus? status,
    int? elapsedMs,
  }) {
    return _PipelineHopRecord(
      step: step ?? this.step,
      fromNode: fromNode ?? this.fromNode,
      toNode: toNode ?? this.toNode,
      isolateId: isolateId ?? this.isolateId,
      dataSnapshot: dataSnapshot ?? this.dataSnapshot,
      status: status ?? this.status,
      elapsedMs: elapsedMs ?? this.elapsedMs,
    );
  }
}

class _EventLogEntry {
  final String time;
  final String category;
  final String message;
  final bool isWarning;

  const _EventLogEntry({
    required this.time,
    required this.category,
    required this.message,
    this.isWarning = false,
  });
}

class IsolateDemoScreen extends StatefulWidget {
  static const name = 'Isolate Orchestrator';
  static const path = 'isolate';

  /// Whether to automatically spawn OS isolates on startup.
  ///
  /// Defaults to `true` in normal runtime and `false` under `FlutterTest` binding
  /// so widget tests can `pumpAndSettle()` deterministically.
  final bool? autoStartCluster;

  const IsolateDemoScreen({super.key, this.autoStartCluster});

  @override
  State<IsolateDemoScreen> createState() => _IsolateDemoScreenState();
}

class _IsolateDemoScreenState extends State<IsolateDemoScreen> {
  IsolateHub? _hub;
  IsolatePool<Map<String, dynamic>>? _pool;
  StreamSubscription<HubEvent>? _hubSub;
  StreamSubscription<PoolEvent>? _poolSub;

  bool _clusterRunning = false;
  bool _busy = false;
  String _selectedNodePath = '/pipeline/ingress';

  // ── Network Graph Viewport & Scrolling controls ──
  final ScrollController _graphHorizontalScrollController = ScrollController();
  bool _isGraphAutoFit = false;
  double _graphZoomScale = 1.0;
  String _lastScrolledNodePath = '';

  // ── Mermaid Flowchart Viewport & Zoom controls ──
  final TransformationController _mermaidTransformController =
      TransformationController();
  double _mermaidZoom = 1.0;

  // ── 1. Create Isolate controls ──
  final TextEditingController _isolateNameController = TextEditingController(
    text: 'worker_1',
  );
  String _selectedParentGroup = '/pipeline';
  ChildRestartType _newNodeRestartType = ChildRestartType.permanent;
  int _dynamicCounter = 1;

  // ── 2. Create IsolatePool controls ──
  int _poolSizeConfig = 2;
  int _poolMaxOverflowConfig = 2;
  PoolStrategy _poolStrategyConfig = PoolStrategy.lifo;
  String _lastPoolOutput =
      'Ready — click "Create / Reconfigure Pool" or run a task';

  // ── 3. Supervisor Auto-Respawn Demo state ──
  String _lastSupervisorRecoverySummary =
      'Select any isolate or click "Trigger Crash & Auto-Respawn Demo" to watch Supervisor recovery.';

  // ── 4. Multi-Isolate Data Flow Pipeline controls & state ──
  final TextEditingController _pipelineInputController = TextEditingController(
    text: 'Order#1024',
  );
  String _activeFlowNodePath = '';
  bool _isPipelineRunning = false;
  int _pipelineStepDelayMs = 1000;
  String _pipelineFinalOutput =
      '[Ingress✓] Order#1024 -> UPPER([INGRESS✓] ORDER#1024) -> #CRC(2841)';
  List<_PipelineHopRecord> _pipelineHops = const [
    _PipelineHopRecord(
      step: 1,
      fromNode: 'Main Hub (/)',
      toNode: '/pipeline/ingress',
      isolateId: 'ingress-1',
      dataSnapshot: '[Ingress✓] Order#1024',
      status: _HopStatus.completed,
      elapsedMs: 1000,
    ),
    _PipelineHopRecord(
      step: 2,
      fromNode: '/pipeline/ingress',
      toNode: '/pipeline/transform',
      isolateId: 'transform-2',
      dataSnapshot: '[Ingress✓] Order#1024 -> UPPER([INGRESS✓] ORDER#1024)',
      status: _HopStatus.completed,
      elapsedMs: 1000,
    ),
    _PipelineHopRecord(
      step: 3,
      fromNode: '/pipeline/transform',
      toNode: '/storage/cache',
      isolateId: 'cache-4',
      dataSnapshot:
          '[Ingress✓] Order#1024 -> UPPER([INGRESS✓] ORDER#1024) -> #CRC(2841)',
      status: _HopStatus.completed,
      elapsedMs: 1000,
    ),
  ];

  /// Per-node processed request count for Bar Chart visualization.
  final Map<String, int> _processedByNode = {
    'ingress': 12,
    'transform': 12,
    'dns': 9,
    'db': 15,
    'cache': 18,
  };

  /// Per-node restart count for Bar Chart visualization.
  final Map<String, int> _restartsByNode = {
    'ingress': 0,
    'transform': 0,
    'dns': 0,
    'db': 0,
    'cache': 1,
  };

  /// Poolboy historical series for Line Chart visualization.
  int _poolTick = 6;
  final List<DmVizPoint> _poolTotalSeries = [
    DmVizPoint(x: 1, y: 2),
    DmVizPoint(x: 2, y: 2),
    DmVizPoint(x: 3, y: 3),
    DmVizPoint(x: 4, y: 4),
    DmVizPoint(x: 5, y: 3),
    DmVizPoint(x: 6, y: 2),
  ];
  final List<DmVizPoint> _poolCheckedOutSeries = [
    DmVizPoint(x: 1, y: 0),
    DmVizPoint(x: 2, y: 1),
    DmVizPoint(x: 3, y: 3),
    DmVizPoint(x: 4, y: 4),
    DmVizPoint(x: 5, y: 2),
    DmVizPoint(x: 6, y: 0),
  ];

  final List<PoolWorker<Map<String, dynamic>>> _manualLeases = [];
  int _simulatedCheckedOut = 0;
  int _simulatedOverflow = 0;

  late TreeNodeSnapshot _treeSnapshot = _buildDefaultSnapshot();

  final List<_EventLogEntry> _eventLogs = [
    const _EventLogEntry(
      time: '00:00.0',
      category: 'SUPERVISOR',
      message:
          'Initialized supervision tree: / -> [/pipeline (oneForOne), /network (oneForAll), /storage (restForOne)]',
    ),
    const _EventLogEntry(
      time: '00:00.1',
      category: 'POOLBOY',
      message:
          'Configured IsolatePool (size: 2, maxOverflow: 2, strategy: LIFO)',
    ),
  ];

  bool get _shouldAutoStart {
    if (widget.autoStartCluster != null) return widget.autoStartCluster!;
    final bindingName = WidgetsBinding.instance.runtimeType.toString();
    return !bindingName.contains('TestWidgetsFlutterBinding') &&
        !bindingName.contains('AutomatedTestWidgetsFlutterBinding');
  }

  @override
  void initState() {
    super.initState();
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      _pipelineStepDelayMs = 50;
    }
    if (_shouldAutoStart) {
      unawaited(_startLiveCluster());
    }
  }

  @override
  void dispose() {
    _isolateNameController.dispose();
    _pipelineInputController.dispose();
    _graphHorizontalScrollController.dispose();
    _mermaidTransformController.dispose();
    _hubSub?.cancel();
    _poolSub?.cancel();
    final pool = _pool;
    final hub = _hub;
    if (pool != null) {
      unawaited(pool.stop());
    }
    if (hub != null) {
      unawaited(hub.stop(timeout: const Duration(seconds: 2)));
    }
    super.dispose();
  }

  TreeNodeSnapshot _buildDefaultSnapshot() {
    return TreeNodeSnapshot(
      name: '/',
      path: '/',
      kind: 'supervisor',
      state: NodeState.running,
      strategy: SupervisionStrategy.oneForOne,
      restartType: ChildRestartType.permanent,
      children: [
        TreeNodeSnapshot(
          name: 'pipeline',
          path: '/pipeline',
          kind: 'supervisor',
          state: NodeState.running,
          strategy: SupervisionStrategy.oneForOne,
          restartType: ChildRestartType.permanent,
          children: [
            TreeNodeSnapshot(
              name: 'ingress',
              path: '/pipeline/ingress',
              kind: 'isolate',
              state: NodeState.running,
              isolateId: 'ingress-1',
              role: 'gateway',
              restartType: ChildRestartType.permanent,
              restartCount: _restartsByNode['ingress'] ?? 0,
            ),
            TreeNodeSnapshot(
              name: 'transform',
              path: '/pipeline/transform',
              kind: 'isolate',
              state: NodeState.running,
              isolateId: 'transform-2',
              role: 'processor',
              restartType: ChildRestartType.permanent,
              restartCount: _restartsByNode['transform'] ?? 0,
            ),
          ],
        ),
        TreeNodeSnapshot(
          name: 'network',
          path: '/network',
          kind: 'supervisor',
          state: NodeState.running,
          strategy: SupervisionStrategy.oneForAll,
          restartType: ChildRestartType.permanent,
          children: [
            TreeNodeSnapshot(
              name: 'dns',
              path: '/network/dns',
              kind: 'isolate',
              state: NodeState.running,
              isolateId: 'resolver-3',
              role: 'resolver',
              restartType: ChildRestartType.permanent,
              restartCount: _restartsByNode['dns'] ?? 0,
            ),
          ],
        ),
        TreeNodeSnapshot(
          name: 'storage',
          path: '/storage',
          kind: 'supervisor',
          state: NodeState.running,
          strategy: SupervisionStrategy.restForOne,
          restartType: ChildRestartType.permanent,
          children: [
            TreeNodeSnapshot(
              name: 'db',
              path: '/storage/db',
              kind: 'isolate',
              state: NodeState.running,
              isolateId: 'database-4',
              role: 'database',
              restartType: ChildRestartType.permanent,
              restartCount: _restartsByNode['db'] ?? 0,
            ),
            TreeNodeSnapshot(
              name: 'cache',
              path: '/storage/cache',
              kind: 'isolate',
              state: NodeState.running,
              isolateId: 'cache-5',
              role: 'cache',
              restartType: ChildRestartType.transient,
              restartCount: _restartsByNode['cache'] ?? 1,
            ),
          ],
        ),
      ],
    );
  }

  void _appendLog(String category, String message, {bool isWarning = false}) {
    final now = DateTime.now();
    final stamp =
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}.'
        '${(now.millisecond ~/ 100)}';
    _eventLogs.insert(
      0,
      _EventLogEntry(
        time: stamp,
        category: category,
        message: message,
        isWarning: isWarning,
      ),
    );
    if (_eventLogs.length > 25) {
      _eventLogs.removeLast();
    }
  }

  void _syncSnapshotFromHub() {
    final hub = _hub;
    if (hub == null || hub.state != HubState.running) return;
    final raw = hub.treeSnapshot();
    final poolWorkerPattern = RegExp(r'^/(worker|overflow)-\d+$');
    _treeSnapshot = TreeNodeSnapshot(
      name: raw.name,
      path: raw.path,
      kind: raw.kind,
      state: raw.state,
      isolateId: raw.isolateId,
      role: raw.role,
      strategy: raw.strategy,
      restartType: raw.restartType,
      restartCount: raw.restartCount,
      children: raw.children
          .where((c) => !poolWorkerPattern.hasMatch(c.path))
          .toList(),
    );
    _syncRestartCounts(_treeSnapshot);
  }

  void _syncRestartCounts(TreeNodeSnapshot node) {
    if (node.kind == 'isolate') {
      _restartsByNode[node.name] = node.restartCount;
      _processedByNode.putIfAbsent(node.name, () => 1);
    }
    for (final child in node.children) {
      _syncRestartCounts(child);
    }
  }

  void _recordPoolMetricsPoint({int? totalOverride, int? checkedOutOverride}) {
    final status = _pool?.status;
    final total =
        totalOverride ??
        status?.totalWorkers ??
        (_poolSizeConfig + _simulatedOverflow);
    final checkedOut =
        checkedOutOverride ?? status?.checkedOutWorkers ?? _simulatedCheckedOut;

    _poolTick++;
    _poolTotalSeries.add(DmVizPoint(x: _poolTick, y: total.toDouble()));
    _poolCheckedOutSeries.add(
      DmVizPoint(x: _poolTick, y: checkedOut.toDouble()),
    );
    if (_poolTotalSeries.length > 10) {
      _poolTotalSeries.removeAt(0);
      _poolCheckedOutSeries.removeAt(0);
    }
  }

  Future<void> _startLiveCluster() async {
    if (_busy || _clusterRunning) return;
    setState(() => _busy = true);

    try {
      final hub = IsolateHub(
        config: const HubConfig(
          healthCheckInterval: Duration(seconds: 5),
          healthCheckTimeout: Duration(seconds: 2),
          restartPolicy: RestartPolicy(
            maxAttempts: 5,
            initialDelay: Duration(milliseconds: 60),
          ),
        ),
      );
      await hub.start();
      _hub = hub;

      _hubSub = hub.events.listen((event) {
        if (!mounted) return;
        setState(() {
          switch (event) {
            case IsolateReady(:final handle):
              _appendLog(
                'READY',
                'Isolate ${handle.path} (${handle.id}) is running',
              );
            case IsolateFailed(:final handle, :final error):
              _appendLog(
                'CRASH',
                'Isolate ${handle.path} (${handle.id}) failed: $error',
                isWarning: true,
              );
            case SupervisorChildRestarted(
              :final supervisorPath,
              :final childPath,
              :final strategy,
              :final attempt,
            ):
              _lastSupervisorRecoverySummary =
                  'Supervisor "$supervisorPath" detected crash of "$childPath" -> '
                  'applied [${strategy.name}] strategy (attempt #$attempt) and respawned isolate!';
              _appendLog(
                'SUPERVISOR',
                '$supervisorPath restarting $childPath [strategy: ${strategy.name}, attempt #$attempt]',
                isWarning: true,
              );
            case SupervisorEscalated(
              :final supervisorPath,
              :final failedChildPath,
              :final reason,
            ):
              _appendLog(
                'ESCALATE',
                '$supervisorPath escalated $failedChildPath: $reason',
                isWarning: true,
              );
            case NodeStateChanged(:final path, :final state):
              _appendLog('STATE', 'Node $path -> ${state.name}');
            default:
              break;
          }
          _syncSnapshotFromHub();
        });
      });

      final pipelineGroup = await hub.createGroup(
        name: 'pipeline',
        strategy: SupervisionStrategy.oneForOne,
        intensity: const RestartIntensity(
          maxRestarts: 5,
          withinDuration: Duration(seconds: 10),
          backoffPolicy: RestartPolicy(
            initialDelay: Duration(milliseconds: 40),
          ),
        ),
      );
      await pipelineGroup.registerService(
        const ChildSpec(
          name: 'ingress',
          role: 'gateway',
          restartType: ChildRestartType.permanent,
          entryPoint: showcaseIsolateEntryPoint,
        ),
      );
      await pipelineGroup.registerService(
        const ChildSpec(
          name: 'transform',
          role: 'processor',
          restartType: ChildRestartType.permanent,
          entryPoint: showcaseIsolateEntryPoint,
        ),
      );

      final networkGroup = await hub.createGroup(
        name: 'network',
        strategy: SupervisionStrategy.oneForAll,
        intensity: const RestartIntensity(
          maxRestarts: 5,
          withinDuration: Duration(seconds: 10),
          backoffPolicy: RestartPolicy(
            initialDelay: Duration(milliseconds: 40),
          ),
        ),
      );
      await networkGroup.registerService(
        const ChildSpec(
          name: 'dns',
          role: 'resolver',
          capabilities: ['doh'],
          restartType: ChildRestartType.permanent,
          entryPoint: showcaseIsolateEntryPoint,
        ),
      );

      final storageGroup = await hub.createGroup(
        name: 'storage',
        strategy: SupervisionStrategy.restForOne,
        intensity: const RestartIntensity(
          maxRestarts: 5,
          withinDuration: Duration(seconds: 10),
          backoffPolicy: RestartPolicy(
            initialDelay: Duration(milliseconds: 40),
          ),
        ),
      );
      await storageGroup.registerService(
        const ChildSpec(
          name: 'db',
          role: 'database',
          capabilities: ['sql'],
          restartType: ChildRestartType.permanent,
          entryPoint: showcaseIsolateEntryPoint,
        ),
      );
      await storageGroup.registerService(
        const ChildSpec(
          name: 'cache',
          role: 'cache',
          capabilities: ['kv'],
          restartType: ChildRestartType.transient,
          entryPoint: showcaseIsolateEntryPoint,
        ),
      );

      await _recreateLivePool();

      if (!mounted) return;
      setState(() {
        _clusterRunning = true;
        _syncSnapshotFromHub();
        _recordPoolMetricsPoint();
        _appendLog(
          'CLUSTER',
          'Live IsolateHub supervision tree & Poolboy pool started',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _recreateLivePool() async {
    final hub = _hub;
    if (hub == null || hub.state != HubState.running) {
      setState(() {
        _simulatedCheckedOut = 0;
        _simulatedOverflow = 0;
        _lastPoolOutput =
            'Created IsolatePool (size: $_poolSizeConfig, maxOverflow: $_poolMaxOverflowConfig, strategy: ${_poolStrategyConfig.name.toUpperCase()})';
        _recordPoolMetricsPoint(
          totalOverride: _poolSizeConfig,
          checkedOutOverride: 0,
        );
        _appendLog('POOLBOY', _lastPoolOutput);
      });
      return;
    }

    _manualLeases.clear();
    await _poolSub?.cancel();
    _poolSub = null;
    await _pool?.stop();

    final pool = IsolatePool<Map<String, dynamic>>(
      hub: hub,
      config: IsolatePoolConfig(
        size: _poolSizeConfig,
        maxOverflow: _poolMaxOverflowConfig,
        strategy: _poolStrategyConfig,
        idleTimeout: const Duration(seconds: 6),
      ),
      workerEntryPoint: showcaseIsolateEntryPoint,
    );
    await pool.start();
    _pool = pool;

    _poolSub = pool.events.listen((event) {
      if (!mounted) return;
      setState(() {
        switch (event) {
          case WorkerAdded(:final worker):
            _appendLog('POOL', 'Pool worker added: ${worker.id}');
          case WorkerRemoved(:final workerId):
            _appendLog('POOL', 'Pool worker removed: $workerId');
          default:
            break;
        }
        _recordPoolMetricsPoint();
      });
    });

    if (!mounted) return;
    setState(() {
      _lastPoolOutput =
          'Created live IsolatePool (size: $_poolSizeConfig, maxOverflow: $_poolMaxOverflowConfig, strategy: ${_poolStrategyConfig.name.toUpperCase()})';
      _recordPoolMetricsPoint();
      _appendLog('POOLBOY', _lastPoolOutput);
    });
  }

  Future<void> _stopLiveCluster() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      _manualLeases.clear();
      await _poolSub?.cancel();
      _poolSub = null;
      await _hubSub?.cancel();
      _hubSub = null;
      await _pool?.stop();
      _pool = null;
      await _hub?.stop(timeout: const Duration(seconds: 2));
      _hub = null;
      if (!mounted) return;
      setState(() {
        _clusterRunning = false;
        _appendLog('CLUSTER', 'Stopped IsolateHub and all child isolates');
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  // ===========================================================================
  // 1. Create Isolate & Node Inspector Operations
  // ===========================================================================

  List<TreeNodeSnapshot> _flattenTree(TreeNodeSnapshot root) {
    final result = <TreeNodeSnapshot>[root];
    for (final child in root.children) {
      result.addAll(_flattenTree(child));
    }
    return result;
  }

  TreeNodeSnapshot _findSelectedSnapshot() {
    final all = _flattenTree(_treeSnapshot);
    return all.firstWhere(
      (n) => n.path == _selectedNodePath,
      orElse: () => _treeSnapshot,
    );
  }

  Future<void> _spawnDynamicIsolate() async {
    final rawName = _isolateNameController.text.trim();
    final name = rawName.isEmpty ? 'worker_${_dynamicCounter++}' : rawName;
    final parentPath = _selectedParentGroup;
    final fullPath = parentPath == '/' ? '/$name' : '$parentPath/$name';

    if (_clusterRunning && _hub != null) {
      await _hub!.registerService(
        ChildSpec(
          name: name,
          role: 'custom',
          restartType: _newNodeRestartType,
          entryPoint: showcaseIsolateEntryPoint,
        ),
        parentPath: parentPath,
      );
      if (!mounted) return;
      setState(() {
        _processedByNode[name] = 1;
        _restartsByNode[name] = 0;
        _selectedNodePath = fullPath;
        _isolateNameController.text = 'worker_${++_dynamicCounter}';
        _syncSnapshotFromHub();
        _appendLog(
          'SPAWN',
          'Created Isolate $fullPath [restartType: ${_newNodeRestartType.name}]',
        );
      });
    } else {
      setState(() {
        _processedByNode[name] = 1;
        _restartsByNode[name] = 0;
        final newNode = TreeNodeSnapshot(
          name: name,
          path: fullPath,
          kind: 'isolate',
          state: NodeState.running,
          isolateId: '$name-${++_dynamicCounter}',
          role: 'custom',
          restartType: _newNodeRestartType,
        );
        _treeSnapshot = _insertChildSnapshot(
          _treeSnapshot,
          parentPath,
          newNode,
        );
        _selectedNodePath = fullPath;
        _isolateNameController.text = 'worker_${_dynamicCounter + 1}';
        _appendLog(
          'SPAWN',
          'Created Isolate $fullPath [restartType: ${_newNodeRestartType.name}]',
        );
      });
    }
  }

  Future<void> _toggleStartStopSelectedNode() async {
    final selected = _findSelectedSnapshot();
    if (selected.path == '/') return;

    final isStopped =
        selected.state == NodeState.stopped ||
        selected.state == NodeState.failed;

    if (_clusterRunning && _hub != null) {
      if (isStopped) {
        await _hub!.startNode(selected.path);
      } else {
        await _hub!.stopNode(selected.path);
      }
      if (!mounted) return;
      setState(_syncSnapshotFromHub);
    } else {
      setState(() {
        final targetState = isStopped ? NodeState.running : NodeState.stopped;
        _treeSnapshot = _updateSnapshotNodeState(
          _treeSnapshot,
          selected.path,
          targetState,
        );
        _appendLog(
          'NODE',
          '${isStopped ? "Started" : "Stopped"} ${selected.path}',
        );
      });
    }
  }

  Future<void> _restartSelectedNode() async {
    final selected = _findSelectedSnapshot();
    if (selected.path == '/') return;

    if (_clusterRunning && _hub != null) {
      await _hub!.restartNode(selected.path);
      if (!mounted) return;
      setState(() {
        _syncSnapshotFromHub();
        _appendLog('RESTART', 'Restarted ${selected.path}');
      });
    } else {
      setState(() {
        _restartsByNode[selected.name] =
            (_restartsByNode[selected.name] ?? 0) + 1;
        _treeSnapshot = _updateSnapshotNodeState(
          _treeSnapshot,
          selected.path,
          NodeState.running,
          incrementRestart: true,
        );
        _appendLog('RESTART', 'Restarted ${selected.path}');
      });
    }
  }

  // ===========================================================================
  // 3. Supervisor Auto-Respawn Demonstration
  // ===========================================================================

  Future<void> _simulateCrashSelectedNode() async {
    var selected = _findSelectedSnapshot();
    if (selected.kind != 'isolate') {
      // Default to /pipeline/ingress if a supervisor is currently selected
      _selectedNodePath = '/pipeline/ingress';
      selected = _findSelectedSnapshot();
    }
    final oldIsolateId = selected.isolateId ?? '${selected.name}-old';

    if (_clusterRunning && _hub != null) {
      try {
        _hub!.cast(selected.path, 'crash');
      } on IsolateOrchestratorException catch (e) {
        _appendLog('ERROR', e.message, isWarning: true);
      }
      await Future<void>.delayed(const Duration(milliseconds: 240));
      if (!mounted) return;
      setState(() {
        _syncSnapshotFromHub();
        final after = _findSelectedSnapshot();
        _lastSupervisorRecoverySummary =
            'Isolate "${selected.path}" ($oldIsolateId) exited abnormally -> '
            'Supervisor automatically respawned it as (${after.isolateId ?? "new"}) '
            '[total restarts: ${after.restartCount}]';
      });
    } else {
      setState(() {
        if (selected.restartType == ChildRestartType.temporary) {
          _treeSnapshot = _updateSnapshotNodeState(
            _treeSnapshot,
            selected.path,
            NodeState.failed,
          );
          _lastSupervisorRecoverySummary =
              'Isolate "${selected.path}" ($oldIsolateId) crashed -> '
              'restartType is [temporary], so Supervisor left it in FAILED state.';
          _appendLog(
            'SUPERVISOR',
            '${selected.path} crashed [temporary -> not restarted]',
            isWarning: true,
          );
        } else {
          final nextCount = (_restartsByNode[selected.name] ?? 0) + 1;
          _restartsByNode[selected.name] = nextCount;
          final newIsolateId = '${selected.name}-respawned-$nextCount';
          _treeSnapshot = _updateSnapshotNodeState(
            _treeSnapshot,
            selected.path,
            NodeState.running,
            incrementRestart: true,
            newIsolateId: newIsolateId,
          );
          _lastSupervisorRecoverySummary =
              'Isolate "${selected.path}" ($oldIsolateId) crashed -> '
              'Supervisor caught exit signal and auto-respawned new Isolate ($newIsolateId) '
              '[restart #$nextCount]!';
          _appendLog(
            'SUPERVISOR',
            _lastSupervisorRecoverySummary,
            isWarning: true,
          );
        }
      });
    }
  }

  // ===========================================================================
  // 4. Multi-Isolate Data Flow Pipeline (Hub -> Ingress -> Transform -> Cache -> Output)
  // ===========================================================================

  Future<void> _runMultiIsolateDataPipeline() async {
    if (_isPipelineRunning) return;

    final rawPayload = _pipelineInputController.text.trim().isEmpty
        ? 'Order#333'
        : _pipelineInputController.text.trim();

    final delay = _pipelineStepDelayMs;

    setState(() {
      _isPipelineRunning = true;
      _pipelineFinalOutput =
          'Pipeline actively routing through OS isolates (${delay}ms per stage)...';
      _pipelineHops = [
        _PipelineHopRecord(
          step: 1,
          fromNode: 'Main Hub (/)',
          toNode: '/pipeline/ingress',
          isolateId: 'ingress-1',
          dataSnapshot: 'Processing payload in separate OS isolate...',
          status: _HopStatus.processing,
        ),
        const _PipelineHopRecord(
          step: 2,
          fromNode: '/pipeline/ingress',
          toNode: '/pipeline/transform',
          isolateId: 'transform-2',
          dataSnapshot: 'Waiting for Ingress output...',
          status: _HopStatus.pending,
        ),
        const _PipelineHopRecord(
          step: 3,
          fromNode: '/pipeline/transform',
          toNode: '/storage/cache',
          isolateId: 'cache-5',
          dataSnapshot: 'Waiting for Transform output...',
          status: _HopStatus.pending,
        ),
      ];
      _activeFlowNodePath = '/pipeline/ingress';
      _selectedNodePath = '/pipeline/ingress';
      _appendLog(
        'DATA FLOW',
        'Initiating multi-isolate data pipeline with ${delay}ms per-hop processing delay...',
      );
    });

    final overallStopwatch = Stopwatch()..start();

    try {
      // ── Step 1: Main Hub (/) -> /pipeline/ingress ──
      final String step1Out;
      final String ingressId;
      final int hop1Elapsed;

      if (_clusterRunning && _hub != null) {
        final res1 = await _hub!.call<Map<dynamic, dynamic>>(
          '/pipeline/ingress',
          {
            'op': 'stage_process',
            'step': 1,
            'data': rawPayload,
            'delayMs': delay,
          },
        );
        if (!mounted) return;
        step1Out = '${res1['output']}';
        ingressId = '${res1['isolateId']}';
        hop1Elapsed = (res1['elapsedMs'] as num?)?.toInt() ?? delay;
      } else {
        await Future.delayed(Duration(milliseconds: delay));
        if (!mounted) return;
        step1Out = '[Ingress✓] $rawPayload';
        ingressId = 'ingress-1';
        hop1Elapsed = delay;
      }

      setState(() {
        _pipelineHops = [
          _PipelineHopRecord(
            step: 1,
            fromNode: 'Main Hub (/)',
            toNode: '/pipeline/ingress',
            isolateId: ingressId,
            dataSnapshot: step1Out,
            status: _HopStatus.completed,
            elapsedMs: hop1Elapsed,
          ),
          _PipelineHopRecord(
            step: 2,
            fromNode: '/pipeline/ingress',
            toNode: '/pipeline/transform',
            isolateId: 'transform-2',
            dataSnapshot: 'Transforming payload to UPPERCASE in OS isolate...',
            status: _HopStatus.processing,
          ),
          const _PipelineHopRecord(
            step: 3,
            fromNode: '/pipeline/transform',
            toNode: '/storage/cache',
            isolateId: 'cache-5',
            dataSnapshot: 'Waiting for Transform output...',
            status: _HopStatus.pending,
          ),
        ];
        _activeFlowNodePath = '/pipeline/transform';
        _selectedNodePath = '/pipeline/transform';
        _processedByNode['ingress'] = (_processedByNode['ingress'] ?? 0) + 1;
        _appendLog(
          'DATA FLOW',
          'Hop 1 completed at /pipeline/ingress ($hop1Elapsed ms) -> $step1Out',
        );
      });

      // ── Step 2: /pipeline/ingress -> /pipeline/transform ──
      final String step2Out;
      final String transformId;
      final int hop2Elapsed;

      if (_clusterRunning && _hub != null) {
        final res2 = await _hub!
            .call<Map<dynamic, dynamic>>('/pipeline/transform', {
              'op': 'stage_process',
              'step': 2,
              'from': '/pipeline/ingress',
              'data': step1Out,
              'delayMs': delay,
            });
        if (!mounted) return;
        step2Out = '${res2['output']}';
        transformId = '${res2['isolateId']}';
        hop2Elapsed = (res2['elapsedMs'] as num?)?.toInt() ?? delay;
      } else {
        await Future.delayed(Duration(milliseconds: delay));
        if (!mounted) return;
        step2Out = '$step1Out -> UPPER(${step1Out.toUpperCase()})';
        transformId = 'transform-2';
        hop2Elapsed = delay;
      }

      setState(() {
        _pipelineHops = [
          _pipelineHops[0],
          _PipelineHopRecord(
            step: 2,
            fromNode: '/pipeline/ingress',
            toNode: '/pipeline/transform',
            isolateId: transformId,
            dataSnapshot: step2Out,
            status: _HopStatus.completed,
            elapsedMs: hop2Elapsed,
          ),
          _PipelineHopRecord(
            step: 3,
            fromNode: '/pipeline/transform',
            toNode: '/storage/cache',
            isolateId: 'cache-5',
            dataSnapshot: 'Computing CRC checksum & caching in OS isolate...',
            status: _HopStatus.processing,
          ),
        ];
        _activeFlowNodePath = '/storage/cache';
        _selectedNodePath = '/storage/cache';
        _processedByNode['transform'] =
            (_processedByNode['transform'] ?? 0) + 1;
        _appendLog(
          'DATA FLOW',
          'Hop 2 completed at /pipeline/transform ($hop2Elapsed ms) -> $step2Out',
        );
      });

      // ── Step 3: /pipeline/transform -> /storage/cache ──
      final String step3Out;
      final String cacheId;
      final int hop3Elapsed;

      if (_clusterRunning && _hub != null) {
        final res3 = await _hub!.call<Map<dynamic, dynamic>>('/storage/cache', {
          'op': 'stage_process',
          'step': 3,
          'from': '/pipeline/transform',
          'data': step2Out,
          'delayMs': delay,
        });
        if (!mounted) return;
        step3Out = '${res3['output']}';
        cacheId = '${res3['isolateId']}';
        hop3Elapsed = (res3['elapsedMs'] as num?)?.toInt() ?? delay;
      } else {
        await Future.delayed(Duration(milliseconds: delay));
        if (!mounted) return;
        final crc = step2Out.codeUnits.fold<int>(0, (a, b) => a + b);
        step3Out = '$step2Out -> #CRC($crc)';
        cacheId = 'cache-5';
        hop3Elapsed = delay;
      }

      overallStopwatch.stop();

      setState(() {
        _pipelineHops = [
          _pipelineHops[0],
          _pipelineHops[1],
          _PipelineHopRecord(
            step: 3,
            fromNode: '/pipeline/transform',
            toNode: '/storage/cache',
            isolateId: cacheId,
            dataSnapshot: step3Out,
            status: _HopStatus.completed,
            elapsedMs: hop3Elapsed,
          ),
        ];
        _pipelineFinalOutput = step3Out;
        _processedByNode['cache'] = (_processedByNode['cache'] ?? 0) + 1;
        _isPipelineRunning = false;
        _appendLog(
          'DATA FLOW',
          'Pipeline completed in ${overallStopwatch.elapsedMilliseconds} ms across 3 isolates -> Output: $step3Out',
        );
      });
    } on IsolateOrchestratorException catch (e) {
      if (!mounted) return;
      setState(() {
        _isPipelineRunning = false;
        _appendLog('FLOW ERR', e.message, isWarning: true);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isPipelineRunning = false;
        _appendLog('FLOW ERR', '$e', isWarning: true);
      });
    }
  }

  Future<void> _callSelectedIsolate({bool p2pToDns = false}) async {
    final selected = _findSelectedSnapshot();
    if (selected.kind != 'isolate') return;

    if (_clusterRunning && _hub != null) {
      try {
        if (p2pToDns) {
          final res = await _hub!.call<Map<dynamic, dynamic>>(selected.path, {
            'op': 'p2p_call',
            'target': '/network/dns',
          });
          if (!mounted) return;
          setState(() {
            _processedByNode[selected.name] =
                (_processedByNode[selected.name] ?? 0) + 1;
            _processedByNode['dns'] = (_processedByNode['dns'] ?? 0) + 1;
            _appendLog('P2P RPC', '${selected.path} -> /network/dns: $res');
          });
        } else {
          final res = await _hub!.call<Map<dynamic, dynamic>>(selected.path, {
            'op': 'ping',
          });
          if (!mounted) return;
          setState(() {
            _processedByNode[selected.name] =
                (_processedByNode[selected.name] ?? 0) + 1;
            _appendLog('HUB RPC', 'hub.call(${selected.path}) -> $res');
          });
        }
      } on IsolateOrchestratorException catch (e) {
        if (!mounted) return;
        setState(() => _appendLog('RPC ERR', e.message, isWarning: true));
      }
    } else {
      setState(() {
        _processedByNode[selected.name] =
            (_processedByNode[selected.name] ?? 0) + 1;
        if (p2pToDns) {
          _processedByNode['dns'] = (_processedByNode['dns'] ?? 0) + 1;
          _appendLog(
            'P2P RPC',
            '${selected.path} called /network/dns via WorkerContext.call()',
          );
        } else {
          _appendLog(
            'HUB RPC',
            'hub.call("${selected.path}", {"op": "ping"}) -> pong',
          );
        }
      });
    }
  }

  TreeNodeSnapshot _insertChildSnapshot(
    TreeNodeSnapshot current,
    String targetParentPath,
    TreeNodeSnapshot newChild,
  ) {
    if (current.path == targetParentPath && current.kind == 'supervisor') {
      return TreeNodeSnapshot(
        name: current.name,
        path: current.path,
        kind: current.kind,
        state: current.state,
        strategy: current.strategy,
        restartType: current.restartType,
        restartCount: current.restartCount,
        children: [...current.children, newChild],
      );
    }
    return TreeNodeSnapshot(
      name: current.name,
      path: current.path,
      kind: current.kind,
      state: current.state,
      isolateId: current.isolateId,
      role: current.role,
      strategy: current.strategy,
      restartType: current.restartType,
      restartCount: current.restartCount,
      children: current.children
          .map((c) => _insertChildSnapshot(c, targetParentPath, newChild))
          .toList(),
    );
  }

  TreeNodeSnapshot _updateSnapshotNodeState(
    TreeNodeSnapshot current,
    String targetPath,
    NodeState newState, {
    bool incrementRestart = false,
    String? newIsolateId,
  }) {
    final matches =
        current.path == targetPath ||
        (targetPath != '/' && current.path.startsWith('$targetPath/'));
    final nextRestartCount = (current.path == targetPath && incrementRestart)
        ? current.restartCount + 1
        : current.restartCount;

    return TreeNodeSnapshot(
      name: current.name,
      path: current.path,
      kind: current.kind,
      state: matches ? newState : current.state,
      isolateId: (current.path == targetPath && newIsolateId != null)
          ? newIsolateId
          : current.isolateId,
      role: current.role,
      strategy: current.strategy,
      restartType: current.restartType,
      restartCount: nextRestartCount,
      children: current.children
          .map(
            (c) => _updateSnapshotNodeState(
              c,
              targetPath,
              newState,
              incrementRestart: incrementRestart,
              newIsolateId: newIsolateId,
            ),
          )
          .toList(),
    );
  }

  // ===========================================================================
  // 2. Poolboy Operations (transaction, burst overflow, manual checkout/checkin)
  // ===========================================================================

  Future<void> _runPoolTransaction() async {
    if (_clusterRunning && _pool != null) {
      final res = await _pool!.transaction((worker) async {
        if (mounted) {
          setState(_recordPoolMetricsPoint);
        }
        return worker.execute({'value': 21, 'delayMs': 80});
      });
      if (!mounted) return;
      setState(() {
        _recordPoolMetricsPoint();
        _lastPoolOutput =
            'transaction() executed on ${res['workerId']} -> returned value=${res['value']}';
        _appendLog('POOLBOY', _lastPoolOutput);
      });
    } else {
      setState(() {
        _recordPoolMetricsPoint(
          totalOverride: _poolSizeConfig,
          checkedOutOverride: 1,
        );
        _recordPoolMetricsPoint(
          totalOverride: _poolSizeConfig,
          checkedOutOverride: 0,
        );
        _lastPoolOutput =
            'transaction() leased worker-1 (${_poolStrategyConfig.name.toUpperCase()}) -> output=42 -> auto-checked in';
        _appendLog('POOLBOY', _lastPoolOutput);
      });
    }
  }

  Future<void> _runPoolBurstOverflow() async {
    final burstCount = _poolSizeConfig + _poolMaxOverflowConfig;
    if (_clusterRunning && _pool != null) {
      final futures = List.generate(burstCount, (i) async {
        return _pool!.transaction((worker) async {
          if (mounted) {
            setState(_recordPoolMetricsPoint);
          }
          return worker.execute({'value': i + 1, 'delayMs': 250});
        });
      });
      final results = await Future.wait(futures);
      if (!mounted) return;
      setState(() {
        _recordPoolMetricsPoint();
        _lastPoolOutput =
            'Burst of $burstCount concurrent checkouts completed (outputs: ${results.map((r) => r['value']).toList()})';
        _appendLog('POOLBOY', _lastPoolOutput);
      });
    } else {
      setState(() {
        _simulatedCheckedOut = burstCount;
        _simulatedOverflow = _poolMaxOverflowConfig;
        _recordPoolMetricsPoint(
          totalOverride: burstCount,
          checkedOutOverride: burstCount,
        );
        _simulatedCheckedOut = 0;
        _simulatedOverflow = 0;
        _recordPoolMetricsPoint(
          totalOverride: _poolSizeConfig,
          checkedOutOverride: 0,
        );
        _lastPoolOutput =
            'Burst leased $_poolSizeConfig base + $_poolMaxOverflowConfig overflow workers -> returned $burstCount results';
        _appendLog('POOLBOY', _lastPoolOutput);
      });
    }
  }

  Future<void> _manualCheckoutWorker() async {
    final maxCap = _poolSizeConfig + _poolMaxOverflowConfig;
    if (_clusterRunning && _pool != null) {
      final lease = await _pool!.tryCheckout();
      if (!mounted) return;
      setState(() {
        if (lease == null) {
          _lastPoolOutput =
              'Pool Full! tryCheckout() returned null (all $maxCap workers checked out)';
          _appendLog('POOL FULL', _lastPoolOutput, isWarning: true);
        } else {
          _manualLeases.add(lease);
          _recordPoolMetricsPoint();
          _lastPoolOutput =
              'Checked out ${lease.id} (overflow: ${lease.isOverflow})';
          _appendLog('CHECKOUT', _lastPoolOutput);
        }
      });
    } else {
      setState(() {
        if (_simulatedCheckedOut >= maxCap) {
          _lastPoolOutput =
              'Pool Full! tryCheckout() returned null (max capacity $maxCap reached)';
          _appendLog('POOL FULL', _lastPoolOutput, isWarning: true);
        } else {
          _simulatedCheckedOut++;
          if (_simulatedCheckedOut > _poolSizeConfig) {
            _simulatedOverflow = _simulatedCheckedOut - _poolSizeConfig;
          }
          _recordPoolMetricsPoint();
          _lastPoolOutput =
              'Checked out worker #$_simulatedCheckedOut (overflow: ${_simulatedCheckedOut > _poolSizeConfig})';
          _appendLog('CHECKOUT', _lastPoolOutput);
        }
      });
    }
  }

  Future<void> _manualCheckinAll() async {
    if (_clusterRunning && _pool != null) {
      for (final lease in _manualLeases.toList()) {
        await _pool!.checkin(lease);
      }
      _manualLeases.clear();
      if (!mounted) return;
      setState(() {
        _recordPoolMetricsPoint();
        _lastPoolOutput = 'Returned all manually leased workers to pool';
        _appendLog('CHECKIN', _lastPoolOutput);
      });
    } else {
      setState(() {
        _simulatedCheckedOut = 0;
        _simulatedOverflow = 0;
        _recordPoolMetricsPoint();
        _lastPoolOutput = 'Returned all manually leased workers to pool';
        _appendLog('CHECKIN', _lastPoolOutput);
      });
    }
  }

  // ===========================================================================
  // DuskMoon DAG & Chart Data Builders
  // ===========================================================================

  String _mermaidNodeId(String path) {
    if (path == '/') return 'n_root';
    final cleaned = path.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    return 'n$cleaned';
  }

  String _mermaidNodeDecl(TreeNodeSnapshot snap) {
    final id = _mermaidNodeId(snap.path);
    final isSelected = snap.path == _selectedNodePath;

    if (snap.path == '/') {
      return isSelected
          ? '$id(((★ SELECTED: Root Hub / ★)))'
          : '$id((Root Hub /))';
    }
    if (snap.kind == 'supervisor') {
      final strategy = snap.strategy?.name ?? 'oneForOne';
      return isSelected
          ? '$id[[★ SELECTED: ${snap.name} : $strategy ★]]'
          : '$id{{${snap.name} : $strategy}}';
    }
    final state = snap.state.name;
    final restarts = snap.restartCount > 0 ? ' r#${snap.restartCount}' : '';
    if (snap.role == 'database' || snap.role == 'cache') {
      return isSelected
          ? '$id[[★ SELECTED: ${snap.name} : $state$restarts ★]]'
          : '$id[(${snap.name} : $state$restarts)]';
    }
    return isSelected
        ? '$id[[★ SELECTED: ${snap.name} : $state$restarts ★]]'
        : '$id([${snap.name} : $state$restarts])';
  }

  /// Builds a Mermaid `flowchart TD` DAG definition for [DmMermaidView].
  String _buildMermaidDagSource() {
    final lines = <String>['flowchart TD'];
    final visitedIds = <String>{};

    void visit(TreeNodeSnapshot snap) {
      visitedIds.add(snap.path);
      final parentDecl = _mermaidNodeDecl(snap);
      for (final child in snap.children) {
        visitedIds.add(child.path);
        final childDecl = _mermaidNodeDecl(child);
        final isConnectedToSelected =
            snap.path == _selectedNodePath || child.path == _selectedNodePath;
        final arrow = isConnectedToSelected ? '==>' : '-->';
        lines.add('  $parentDecl $arrow $childDecl');
        visit(child);
      }
    }

    visit(_treeSnapshot);

    if (visitedIds.contains('/pipeline/ingress') &&
        visitedIds.contains('/pipeline/transform')) {
      final isSelectedP2P =
          _selectedNodePath == '/pipeline/ingress' ||
          _selectedNodePath == '/pipeline/transform';
      final p2pArrow = isSelectedP2P
          ? '==>|P2P flow (SELECTED)|'
          : '-.->|P2P flow|';
      lines.add(
        '  ${_mermaidNodeId('/pipeline/ingress')} $p2pArrow ${_mermaidNodeId('/pipeline/transform')}',
      );
    }
    if (visitedIds.contains('/pipeline/transform') &&
        visitedIds.contains('/storage/cache')) {
      final isSelectedP2P =
          _selectedNodePath == '/pipeline/transform' ||
          _selectedNodePath == '/storage/cache';
      final p2pArrow = isSelectedP2P
          ? '==>|P2P flow (SELECTED)|'
          : '-.->|P2P flow|';
      lines.add(
        '  ${_mermaidNodeId('/pipeline/transform')} $p2pArrow ${_mermaidNodeId('/storage/cache')}',
      );
    }

    return lines.join('\n');
  }

  void _zoomMermaid(double factor) {
    final currentScale = _mermaidTransformController.value.getMaxScaleOnAxis();
    final newScale = (currentScale * factor).clamp(0.4, 4.0);
    setState(() {
      _mermaidZoom = newScale;
      _mermaidTransformController.value = Matrix4.diagonal3Values(
        newScale,
        newScale,
        1.0,
      );
    });
  }

  void _resetMermaidZoom() {
    setState(() {
      _mermaidZoom = 1.0;
      _mermaidTransformController.value = Matrix4.identity();
    });
  }

  void _showMermaidFullscreenDialog(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog.fullscreen(
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Supervision Tree DAG Flowchart (Mermaid)'),
              actions: [
                IconButton(
                  tooltip: '关闭',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ],
            ),
            body: Container(
              color: cs.surfaceContainerLowest,
              child: Center(
                child: InteractiveViewer(
                  minScale: 0.4,
                  maxScale: 5.0,
                  boundaryMargin: const EdgeInsets.all(500),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: DmMermaidView(
                        source: _buildMermaidDagSource(),
                        options: MermaidRenderOptions(
                          theme: MermaidTheme(
                            background: cs.surfaceContainerLowest,
                            nodeFill: cs.surfaceContainer,
                            nodeStroke: cs.primary,
                            edgeStroke: cs.secondary,
                            textColor: cs.onSurface,
                            labelBackground: cs.surfaceContainerLow,
                            errorFill: cs.errorContainer,
                            errorStroke: cs.error,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds a deterministic 3-tier hierarchical DAG layout (`(x, y)` coordinates)
  /// for [DmVizNetworkGraph] with `enableSimulation: false` so nodes never clump.
  ///
  /// Supports both auto-fit mode (fits within [viewportWidth]) and scrollable mode
  /// with [_graphZoomScale] and horizontal scrollbars.
  (List<DmVizNetworkNode>, List<DmVizNetworkEdge>, double canvasWidth)
  _buildNetworkGraphData({double viewportWidth = 1000.0}) {
    final nodes = <DmVizNetworkNode>[];
    final edges = <DmVizNetworkEdge>[];

    String groupFor(TreeNodeSnapshot snap) {
      if (snap.path == _selectedNodePath) return 'selected';
      if (snap.path == '/') return 'root';
      if (snap.kind == 'supervisor') return 'supervisor';
      return snap.state == NodeState.running ? 'running' : 'inactive';
    }

    String labelFor(TreeNodeSnapshot snap) {
      final isSelected = snap.path == _selectedNodePath;
      final prefix = isSelected ? '★ ' : '';
      final suffix = isSelected ? ' ★' : '';
      if (snap.path == '/') {
        return isSelected ? '★ Root Hub (/) ★' : 'Root Hub (/)';
      }
      if (snap.kind == 'supervisor') {
        final strategy = snap.strategy?.name ?? '';
        final stratText = strategy.isNotEmpty ? ' [$strategy]' : '';
        return '$prefix/${snap.name}$stratText$suffix';
      }
      return '$prefix${snap.name} (${snap.state.name})$suffix';
    }

    final layer1 = _treeSnapshot.children;
    final layer2Entries = <(TreeNodeSnapshot parent, TreeNodeSnapshot child)>[];
    for (final child in layer1) {
      for (final grandChild in child.children) {
        layer2Entries.add((child, grandChild));
      }
    }

    final m = layer2Entries.length;
    final s = layer1.length;

    // Calculate canvas width and node horizontal positions
    double canvasWidth;
    double supervisorSpacing;
    double workerSpacing;

    if (_isGraphAutoFit) {
      canvasWidth = math.max(360.0, viewportWidth);
      final availW = math.max(240.0, canvasWidth - 140.0);
      supervisorSpacing = s <= 1 ? 0.0 : (availW / (s - 1)).clamp(60.0, 240.0);
      workerSpacing = m <= 1 ? 0.0 : (availW / (m - 1)).clamp(40.0, 160.0);
    } else {
      // Scrollable mode with zoom scaling
      final baseWSpacing = (140.0 * _graphZoomScale).clamp(80.0, 320.0);
      final baseSSpacing = (240.0 * _graphZoomScale).clamp(120.0, 480.0);
      workerSpacing = baseWSpacing;
      supervisorSpacing = baseSSpacing;

      final neededW =
          math.max(
            m > 1 ? (m - 1) * baseWSpacing : 0.0,
            s > 1 ? (s - 1) * baseSSpacing : 0.0,
          ) +
          260.0;
      canvasWidth = math.max(viewportWidth, neededW);
    }

    // Layer 0: Root Hub at top center (0, -135) with generous top padding
    final isRootSelected = _treeSnapshot.path == _selectedNodePath;
    nodes.add(
      DmVizNetworkNode(
        id: _treeSnapshot.path,
        label: labelFor(_treeSnapshot),
        group: groupFor(_treeSnapshot),
        x: 0,
        y: -135,
        fixed: true,
        radius: isRootSelected ? 24 : 16,
        color: isRootSelected ? const Color(0xFFF59E0B) : null,
      ),
    );

    // Layer 1: Supervisor groups at y = -30
    for (var i = 0; i < s; i++) {
      final child = layer1[i];
      final isSelected = child.path == _selectedNodePath;
      final x = s == 1 ? 0.0 : (i - (s - 1) / 2.0) * supervisorSpacing;
      nodes.add(
        DmVizNetworkNode(
          id: child.path,
          label: labelFor(child),
          group: groupFor(child),
          x: x,
          y: -30,
          fixed: true,
          radius: isSelected ? 22 : (child.kind == 'supervisor' ? 14 : 11),
          color: isSelected ? const Color(0xFFF59E0B) : null,
        ),
      );
      final isEdgeConnected =
          _treeSnapshot.path == _selectedNodePath || isSelected;
      edges.add(
        DmVizNetworkEdge(
          source: _treeSnapshot.path,
          target: child.path,
          directed: true,
          width: isEdgeConnected ? 3.6 : 2.0,
          color: isEdgeConnected ? const Color(0xFFF59E0B) : null,
        ),
      );
    }

    // Layer 2: Worker Isolates spread across y = +65 (even) and y = +120 (odd)
    for (var j = 0; j < m; j++) {
      final (parent, leaf) = layer2Entries[j];
      final isSelected = leaf.path == _selectedNodePath;
      final x = m == 1 ? 0.0 : (j - (m - 1) / 2.0) * workerSpacing;
      final y = j.isEven ? 65.0 : 120.0;

      nodes.add(
        DmVizNetworkNode(
          id: leaf.path,
          label: labelFor(leaf),
          group: groupFor(leaf),
          x: x,
          y: y,
          fixed: true,
          radius: isSelected ? 22 : 11,
          color: isSelected ? const Color(0xFFF59E0B) : null,
        ),
      );
      final isEdgeConnected = parent.path == _selectedNodePath || isSelected;
      edges.add(
        DmVizNetworkEdge(
          source: parent.path,
          target: leaf.path,
          directed: true,
          width: isEdgeConnected ? 3.6 : 1.8,
          color: isEdgeConnected ? const Color(0xFFF59E0B) : null,
        ),
      );
    }

    final nodeIds = nodes.map((n) => n.id).toSet();
    // Add P2P data flow edges between pipeline isolates when present in the tree
    if (nodeIds.contains('/pipeline/ingress') &&
        nodeIds.contains('/pipeline/transform')) {
      final isP2PSelected =
          _selectedNodePath == '/pipeline/ingress' ||
          _selectedNodePath == '/pipeline/transform';
      edges.add(
        DmVizNetworkEdge(
          source: '/pipeline/ingress',
          target: '/pipeline/transform',
          directed: true,
          label: isP2PSelected ? 'P2P flow (SELECTED)' : 'P2P flow',
          width: isP2PSelected ? 3.8 : 2.4,
          color: isP2PSelected ? const Color(0xFFF59E0B) : null,
        ),
      );
    }
    if (nodeIds.contains('/pipeline/transform') &&
        nodeIds.contains('/storage/cache')) {
      final isP2PSelected =
          _selectedNodePath == '/pipeline/transform' ||
          _selectedNodePath == '/storage/cache';
      edges.add(
        DmVizNetworkEdge(
          source: '/pipeline/transform',
          target: '/storage/cache',
          directed: true,
          label: isP2PSelected ? 'P2P flow (SELECTED)' : 'P2P flow',
          width: isP2PSelected ? 3.8 : 2.4,
          color: isP2PSelected ? const Color(0xFFF59E0B) : null,
        ),
      );
    }

    return (nodes, edges, canvasWidth);
  }

  void _scrollToSelectedNode(
    double nodeX,
    double canvasWidth,
    double viewportWidth,
  ) {
    if (!_graphHorizontalScrollController.hasClients) return;
    final maxScroll = _graphHorizontalScrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;
    final nodeAbsoluteX = canvasWidth / 2 + nodeX;
    final targetOffset = (nodeAbsoluteX - viewportWidth / 2).clamp(
      0.0,
      maxScroll,
    );
    _graphHorizontalScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  List<DmVizPoint> _buildProcessedBarData() {
    return _processedByNode.entries
        .map((e) => DmVizPoint(x: e.key, y: e.value.toDouble()))
        .toList();
  }

  List<DmVizPoint> _buildRestartBarData() {
    return _restartsByNode.entries
        .map((e) => DmVizPoint(x: e.key, y: e.value.toDouble()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final allNodes = _flattenTree(_treeSnapshot);
    final selectedNode = _findSelectedSnapshot();

    final poolStatus = _pool?.status;
    final availableWorkers =
        poolStatus?.availableWorkers ??
        (_poolSizeConfig - _simulatedCheckedOut).clamp(0, _poolSizeConfig);
    final checkedOutWorkers =
        poolStatus?.checkedOutWorkers ?? _simulatedCheckedOut;
    final overflowWorkers = poolStatus?.overflowWorkers ?? _simulatedOverflow;

    return AppAdaptiveScaffold(
      internalAnimations: false,
      selectedIndex: Destinations.indexOf(
        const Key(ShowcaseScreen.name),
        context,
      ),
      onSelectedIndexChange: (idx) => Destinations.changeHandler(idx, context),
      destinations: Destinations.navs(context),
      body: (context) {
        return SafeArea(
          child: CustomScrollView(
            slivers: <Widget>[
              const SliverAppBar(title: Text(IsolateDemoScreen.name)),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── 1. Cluster Control & Create Isolate ──
                    _buildClusterControlCard(
                      context,
                      cs: cs,
                      textTheme: textTheme,
                      allNodes: allNodes,
                    ),
                    const SizedBox(height: 20),

                    // ── 2. Multi-Isolate Data Flow Pipeline & Output ──
                    _buildDataFlowPipelineCard(
                      context,
                      cs: cs,
                      textTheme: textTheme,
                    ),
                    const SizedBox(height: 20),

                    // ── 3. Supervision Tree & Data Flow DAG (DmMermaidView + DmVizNetworkGraph) ──
                    _buildSectionCard(
                      context,
                      key: const ValueKey('supervision-tree-graph-card'),
                      title:
                          'Supervision Tree & Data Flow DAG (DmMermaidView & DmVizNetworkGraph)',
                      subtitle:
                          'Layered Directed Acyclic Graph (DAG): Root Hub (/) -> Supervisors (/pipeline, /network, /storage) -> Isolates & P2P flow',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Toolbar: Mermaid Title + Zoom Controls + Fullscreen modal
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Sugiyama Hierarchical DAG Flowchart (DmMermaidView):',
                                  style: textTheme.labelLarge,
                                ),
                              ),
                              IconButton.outlined(
                                tooltip: '缩小 (Zoom Out)',
                                icon: const Icon(Icons.zoom_out, size: 18),
                                onPressed: () => _zoomMermaid(1 / 1.25),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${(_mermaidZoom * 100).round()}%',
                                style: textTheme.labelMedium,
                              ),
                              const SizedBox(width: 4),
                              IconButton.outlined(
                                tooltip: '放大 (Zoom In)',
                                icon: const Icon(Icons.zoom_in, size: 18),
                                onPressed: () => _zoomMermaid(1.25),
                              ),
                              const SizedBox(width: 4),
                              IconButton.outlined(
                                tooltip: '重置缩放 (100%)',
                                icon: const Icon(Icons.restart_alt, size: 18),
                                onPressed: _resetMermaidZoom,
                              ),
                              const SizedBox(width: 4),
                              IconButton.filledTonal(
                                tooltip: '全屏大图查看',
                                icon: const Icon(Icons.open_in_full, size: 18),
                                onPressed: () =>
                                    _showMermaidFullscreenDialog(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            height: 380,
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: cs.outlineVariant),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: InteractiveViewer(
                              transformationController:
                                  _mermaidTransformController,
                              minScale: 0.4,
                              maxScale: 4.0,
                              boundaryMargin: const EdgeInsets.all(300),
                              onInteractionUpdate: (details) {
                                final currentScale = _mermaidTransformController
                                    .value
                                    .getMaxScaleOnAxis();
                                if ((currentScale - _mermaidZoom).abs() >
                                    0.05) {
                                  setState(() => _mermaidZoom = currentScale);
                                }
                              },
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: DmMermaidView(
                                    key: const ValueKey(
                                      'supervision-mermaid-dag',
                                    ),
                                    source: _buildMermaidDagSource(),
                                    options: MermaidRenderOptions(
                                      theme: MermaidTheme(
                                        background: cs.surfaceContainerHighest,
                                        nodeFill: cs.surfaceContainer,
                                        nodeStroke: cs.primary,
                                        edgeStroke: cs.secondary,
                                        textColor: cs.onSurface,
                                        labelBackground: cs.surfaceContainerLow,
                                        errorFill: cs.errorContainer,
                                        errorStroke: cs.error,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 14,
                                color: cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '💡 提示：点击上方 [+] 按钮放大高清细节，支持鼠标拖拽平移、触控板双指缩放，亦可点击全屏图标弹窗大图浏览。',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              _buildLegendChip(cs.primary, 'Root Hub (/)'),
                              _buildLegendChip(
                                cs.secondary,
                                'Supervisor Group',
                              ),
                              _buildLegendChip(cs.tertiary, 'Running Isolate'),
                              _buildLegendChip(
                                cs.error,
                                'Stopped / Failed Isolate',
                              ),
                              _buildLegendChip(
                                const Color(0xFFF59E0B),
                                '★ Selected / 选中高亮',
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final viewportWidth = constraints.maxWidth;
                              final (
                                graphNodes,
                                graphEdges,
                                canvasWidth,
                              ) = _buildNetworkGraphData(
                                viewportWidth: viewportWidth,
                              );
                              final isOverflowing =
                                  canvasWidth > viewportWidth + 1;

                              // Auto-scroll to center the selected node in the horizontal viewport
                              final selectedGraphNode = graphNodes
                                  .where((n) => n.id == _selectedNodePath)
                                  .firstOrNull;
                              if (selectedGraphNode != null &&
                                  selectedGraphNode.x != null &&
                                  _selectedNodePath != _lastScrolledNodePath) {
                                _lastScrolledNodePath = _selectedNodePath;
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  _scrollToSelectedNode(
                                    selectedGraphNode.x!,
                                    canvasWidth,
                                    viewportWidth,
                                  );
                                });
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Toolbar: Mode switch + Zoom + Canvas status badge
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      SegmentedButton<bool>(
                                        segments: const [
                                          ButtonSegment<bool>(
                                            value: false,
                                            icon: Icon(
                                              Icons.swap_horiz,
                                              size: 16,
                                            ),
                                            label: Text('横向滚动 (Scroll)'),
                                          ),
                                          ButtonSegment<bool>(
                                            value: true,
                                            icon: Icon(
                                              Icons.fit_screen,
                                              size: 16,
                                            ),
                                            label: Text('自适应画布 (Fit)'),
                                          ),
                                        ],
                                        selected: {_isGraphAutoFit},
                                        onSelectionChanged: (selected) {
                                          setState(
                                            () => _isGraphAutoFit =
                                                selected.first,
                                          );
                                        },
                                      ),
                                      if (!_isGraphAutoFit) ...[
                                        IconButton.outlined(
                                          tooltip: '缩小 (Zoom Out)',
                                          icon: const Icon(
                                            Icons.zoom_out,
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _graphZoomScale =
                                                  (_graphZoomScale / 1.2).clamp(
                                                    0.6,
                                                    2.5,
                                                  );
                                            });
                                          },
                                        ),
                                        Text(
                                          '${(_graphZoomScale * 100).round()}%',
                                          style: textTheme.labelMedium,
                                        ),
                                        IconButton.outlined(
                                          tooltip: '放大 (Zoom In)',
                                          icon: const Icon(
                                            Icons.zoom_in,
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _graphZoomScale =
                                                  (_graphZoomScale * 1.2).clamp(
                                                    0.6,
                                                    2.5,
                                                  );
                                            });
                                          },
                                        ),
                                        IconButton.outlined(
                                          tooltip: '重置缩放 (100%)',
                                          icon: const Icon(
                                            Icons.restart_alt,
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            setState(
                                              () => _graphZoomScale = 1.0,
                                            );
                                          },
                                        ),
                                      ],
                                      Chip(
                                        avatar: Icon(
                                          isOverflowing
                                              ? Icons.view_carousel
                                              : Icons.check_circle_outline,
                                          size: 16,
                                          color: isOverflowing
                                              ? cs.tertiary
                                              : cs.primary,
                                        ),
                                        label: Text(
                                          '画布: ${canvasWidth.round()} × 440 px${isOverflowing ? " (超出可视区，已开启滚动条)" : " (完全贴合)"}',
                                          style: textTheme.labelSmall,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Scrollbar + Scrollable Viewport
                                  Container(
                                    width: double.infinity,
                                    height: 440,
                                    decoration: BoxDecoration(
                                      color: cs.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isOverflowing
                                            ? cs.tertiary.withValues(alpha: 0.5)
                                            : cs.outlineVariant,
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Scrollbar(
                                      controller:
                                          _graphHorizontalScrollController,
                                      thumbVisibility: true,
                                      trackVisibility: isOverflowing,
                                      interactive: true,
                                      thickness: 8,
                                      radius: const Radius.circular(4),
                                      child: SingleChildScrollView(
                                        controller:
                                            _graphHorizontalScrollController,
                                        scrollDirection: Axis.horizontal,
                                        physics: const ClampingScrollPhysics(),
                                        child: SizedBox(
                                          width: canvasWidth,
                                          height: 440,
                                          child: DmVizNetworkGraph(
                                            nodes: graphNodes,
                                            links: graphEdges,
                                            enableSimulation: false,
                                            showNodeLabels: true,
                                            showLinkLabels: true,
                                            enableZoomPan: false,
                                            draggableNodes: false,
                                            linkStyle:
                                                DmVizNetworkLinkStyle.straight,
                                            groupColors: {
                                              'root': cs.primary,
                                              'supervisor': cs.secondary,
                                              'running': cs.tertiary,
                                              'inactive': cs.error,
                                              'selected': const Color(
                                                0xFFF59E0B,
                                              ),
                                            },
                                            onNodeTap: (node) {
                                              setState(
                                                () =>
                                                    _selectedNodePath = node.id,
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (isOverflowing) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          size: 14,
                                          color: cs.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            '💡 节点已超出可视区域，请拖动上方滚动条或使用鼠标/触控板横向滑动；亦可切换为“自适应画布”一屏全览。',
                                            style: textTheme.bodySmall
                                                ?.copyWith(
                                                  color: cs.onSurfaceVariant,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Select Node or ServiceGroup to Inspect, Start/Stop, or Trigger Crash:',
                            style: textTheme.labelLarge,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: allNodes.map((node) {
                              final isSelected = node.path == _selectedNodePath;
                              final isRunning = node.state == NodeState.running;
                              return FilterChip(
                                key: ValueKey('node-chip-${node.path}'),
                                selected: isSelected,
                                selectedColor: const Color(
                                  0xFFF59E0B,
                                ).withValues(alpha: 0.22),
                                checkmarkColor: const Color(0xFFF59E0B),
                                side: BorderSide(
                                  color: isSelected
                                      ? const Color(0xFFF59E0B)
                                      : cs.outlineVariant,
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                                label: Text(
                                  '${node.path} (${node.state.name})',
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? const Color(0xFFF59E0B)
                                        : null,
                                  ),
                                ),
                                avatar: Icon(
                                  node.kind == 'supervisor'
                                      ? Icons.account_tree
                                      : (isRunning
                                            ? Icons.memory
                                            : Icons.power_off),
                                  size: 16,
                                  color: isSelected
                                      ? const Color(0xFFF59E0B)
                                      : null,
                                ),
                                onSelected: (_) {
                                  setState(() => _selectedNodePath = node.path);
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── 4. Supervisor Auto-Respawn & Node Inspector ──
                    _buildNodeInspectorCard(
                      context,
                      cs: cs,
                      textTheme: textTheme,
                      selected: selectedNode,
                    ),
                    const SizedBox(height: 20),

                    // ── 5. Create IsolatePool & Poolboy Burst Chart (DmVizLineChart) ──
                    _buildPoolboyCard(
                      context,
                      cs: cs,
                      textTheme: textTheme,
                      availableWorkers: availableWorkers,
                      checkedOutWorkers: checkedOutWorkers,
                      overflowWorkers: overflowWorkers,
                    ),
                    const SizedBox(height: 20),

                    // ── 6. DmVizBarChart: Processed RPCs & Supervisor Restarts ──
                    _buildSectionCard(
                      context,
                      key: const ValueKey('isolate-metrics-bar-card'),
                      title:
                          'Isolate Throughput & Supervisor Restarts (DmVizBarChart)',
                      subtitle:
                          'Compare RPC/task volume and automatic OTP supervisor recovery counts per isolate',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Processed Tasks / RPC Calls per Isolate',
                            style: textTheme.titleSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 220,
                            child: DmVizBarChart(
                              data: _buildProcessedBarData(),
                              xAxisLabel: 'Isolate Name',
                              yAxisLabel: 'Tasks / RPCs',
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Supervisor Auto-Restart Count per Isolate',
                            style: textTheme.titleSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 200,
                            child: DmVizBarChart(
                              data: _buildRestartBarData(),
                              xAxisLabel: 'Isolate Name',
                              yAxisLabel: 'Restarts',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── 7. Live Event Timeline ──
                    _buildEventLogCard(context, cs: cs, textTheme: textTheme),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClusterControlCard(
    BuildContext context, {
    required ColorScheme cs,
    required TextTheme textTheme,
    required List<TreeNodeSnapshot> allNodes,
  }) {
    final isolateNodes = allNodes.where((n) => n.kind == 'isolate').toList();
    final runningIsolates = isolateNodes
        .where((n) => n.state == NodeState.running)
        .length;
    final supervisorGroups = allNodes
        .where((n) => n.kind == 'supervisor')
        .toList();

    return Card(
      key: const ValueKey('cluster-control-card'),
      color: cs.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.hub, color: cs.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '1. Create & Manage Isolates (IsolateHub & ServiceGroup)',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _clusterRunning
                            ? 'Live OS Isolates Active • Running: $runningIsolates/${isolateNodes.length} • Groups: ${supervisorGroups.length}'
                            : 'Interactive Mode • Tap "Start Live Isolates" to spawn real OS isolates',
                        style: textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  key: const ValueKey('toggle-cluster-btn'),
                  onPressed: _busy
                      ? null
                      : (_clusterRunning
                            ? _stopLiveCluster
                            : _startLiveCluster),
                  icon: Icon(
                    _clusterRunning ? Icons.stop_circle : Icons.play_arrow,
                  ),
                  label: Text(
                    _clusterRunning ? 'Stop Cluster' : 'Start Live Isolates',
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              'Create a New Supervised Isolate in Tree:',
              style: textTheme.labelLarge,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 160,
                  child: TextField(
                    key: const ValueKey('new-isolate-name-input'),
                    controller: _isolateNameController,
                    decoration: const InputDecoration(
                      labelText: 'Isolate Name',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                DropdownButton<String>(
                  value: _selectedParentGroup,
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedParentGroup = v);
                  },
                  items: const [
                    DropdownMenuItem(
                      value: '/pipeline',
                      child: Text('Group: /pipeline (oneForOne)'),
                    ),
                    DropdownMenuItem(
                      value: '/network',
                      child: Text('Group: /network (oneForAll)'),
                    ),
                    DropdownMenuItem(
                      value: '/storage',
                      child: Text('Group: /storage (restForOne)'),
                    ),
                    DropdownMenuItem(
                      value: '/',
                      child: Text('Group: / (Root)'),
                    ),
                  ],
                ),
                DropdownButton<ChildRestartType>(
                  value: _newNodeRestartType,
                  onChanged: (v) {
                    if (v != null) setState(() => _newNodeRestartType = v);
                  },
                  items: ChildRestartType.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text('Restart: ${t.name}'),
                        ),
                      )
                      .toList(),
                ),
                FilledButton.tonalIcon(
                  key: const ValueKey('spawn-dynamic-isolate-btn'),
                  onPressed: _spawnDynamicIsolate,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Create Isolate'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataFlowPipelineCard(
    BuildContext context, {
    required ColorScheme cs,
    required TextTheme textTheme,
  }) {
    return Card(
      key: const ValueKey('data-flow-pipeline-card'),
      color: cs.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.alt_route, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '2. Cross-Isolate Data Flow Pipeline (Step-by-Step Multi-Isolate Flow)',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Main Hub -> /pipeline/ingress -> /pipeline/transform -> /storage/cache -> Final Output',
                        style: textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Text(
                  'Per-Hop Processing Delay:',
                  style: textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                for (final (delay, label) in [
                  (500, '0.5s'),
                  (1000, '1.0s (标准)'),
                  (1500, '1.5s'),
                  (2000, '2.0s (慢速演示)'),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: _pipelineStepDelayMs == delay,
                    onSelected: _isPipelineRunning
                        ? null
                        : (selected) {
                            if (selected) {
                              setState(() => _pipelineStepDelayMs = delay);
                            }
                          },
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('pipeline-input-field'),
                    controller: _pipelineInputController,
                    enabled: !_isPipelineRunning,
                    decoration: const InputDecoration(
                      labelText: 'Input Payload to Send Into Isolate Pipeline',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  key: const ValueKey('send-pipeline-data-btn'),
                  onPressed: _isPipelineRunning
                      ? null
                      : _runMultiIsolateDataPipeline,
                  icon: _isPipelineRunning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    _isPipelineRunning
                        ? 'Streaming Flow...'
                        : 'Send & Trace Flow',
                  ),
                ),
              ],
            ),
            if (_isPipelineRunning) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: switch (_activeFlowNodePath) {
                    '/pipeline/ingress' => 0.33,
                    '/pipeline/transform' => 0.66,
                    '/storage/cache' => 1.0,
                    _ => null,
                  },
                  backgroundColor: cs.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                ),
              ),
            ],
            const SizedBox(height: 14),
            ..._pipelineHops.map((hop) {
              final isProcessing = hop.status == _HopStatus.processing;
              final isCompleted = hop.status == _HopStatus.completed;
              final isPending = hop.status == _HopStatus.pending;
              final isFailed = hop.status == _HopStatus.failed;

              final Color borderColor = isProcessing
                  ? cs.primary
                  : isCompleted
                  ? Colors.green.withValues(alpha: 0.5)
                  : isFailed
                  ? cs.error
                  : cs.outlineVariant.withValues(alpha: 0.4);

              final Color bgColor = isProcessing
                  ? cs.primaryContainer.withValues(alpha: 0.15)
                  : isCompleted
                  ? cs.surfaceContainer
                  : cs.surfaceContainerLowest;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: borderColor,
                    width: isProcessing ? 2.0 : 1.0,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isProcessing)
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                cs.primary,
                              ),
                            ),
                            Text(
                              '${hop.step}',
                              style: textTheme.labelSmall?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (isCompleted)
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.green.withValues(alpha: 0.2),
                        child: const Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.green,
                        ),
                      )
                    else if (isFailed)
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: cs.errorContainer,
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: cs.onErrorContainer,
                        ),
                      )
                    else
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: cs.surfaceContainerHighest,
                        child: Text(
                          '${hop.step}',
                          style: textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${hop.fromNode} ──(call)──► ${hop.toNode} [${hop.isolateId}]',
                                  style: textTheme.labelMedium?.copyWith(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    color: isProcessing ? cs.primary : null,
                                  ),
                                ),
                              ),
                              if (isProcessing)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cs.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'PROCESSING (~${_pipelineStepDelayMs}ms)',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: cs.onPrimary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              else if (isCompleted && hop.elapsedMs != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.green.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    '✓ ${hop.elapsedMs} ms',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: Colors.green,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              else if (isPending)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'PENDING',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Stage Output: ${hop.dataSnapshot}',
                            style: textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                              color: isProcessing
                                  ? cs.primary
                                  : isPending
                                  ? cs.onSurfaceVariant.withValues(alpha: 0.6)
                                  : cs.onSurfaceVariant,
                              fontStyle: isProcessing || isPending
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isPipelineRunning
                    ? cs.surfaceContainerHigh
                    : cs.primaryContainer,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isPipelineRunning ? cs.outlineVariant : cs.primary,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isPipelineRunning
                            ? Icons.hourglass_top
                            : Icons.check_circle_outline,
                        size: 16,
                        color: _isPipelineRunning
                            ? cs.onSurfaceVariant
                            : cs.onPrimaryContainer,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isPipelineRunning
                            ? 'PIPELINE EXECUTION IN PROGRESS...'
                            : 'FINAL RETURNED OUTPUT TO CALLER:',
                        style: textTheme.labelSmall?.copyWith(
                          color: _isPipelineRunning
                              ? cs.onSurfaceVariant
                              : cs.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _pipelineFinalOutput,
                    key: const ValueKey('pipeline-final-output-text'),
                    style: textTheme.bodyMedium?.copyWith(
                      color: _isPipelineRunning
                          ? cs.onSurface
                          : cs.onPrimaryContainer,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNodeInspectorCard(
    BuildContext context, {
    required ColorScheme cs,
    required TextTheme textTheme,
    required TreeNodeSnapshot selected,
  }) {
    final isRoot = selected.path == '/';
    final isIsolate = selected.kind == 'isolate';
    final isRunning = selected.state == NodeState.running;

    return Card(
      key: const ValueKey('node-inspector-card'),
      color: cs.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isIsolate ? Icons.memory : Icons.account_tree,
                  color: cs.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '3. Supervisor Auto-Respawn & Node Control (${selected.path})',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isRunning ? cs.tertiaryContainer : cs.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    selected.state.name.toUpperCase(),
                    style: textTheme.labelSmall?.copyWith(
                      color: isRunning
                          ? cs.onTertiaryContainer
                          : cs.onErrorContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _lastSupervisorRecoverySummary,
                key: const ValueKey('supervisor-recovery-summary'),
                style: textTheme.bodySmall?.copyWith(
                  color: cs.onSecondaryContainer,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                Text('Kind: ${selected.kind}', style: textTheme.bodyMedium),
                if (selected.strategy != null)
                  Text(
                    'Strategy: ${selected.strategy!.name}',
                    style: textTheme.bodyMedium,
                  ),
                Text(
                  'RestartType: ${selected.restartType.name}',
                  style: textTheme.bodyMedium,
                ),
                if (selected.isolateId != null)
                  Text(
                    'Isolate ID: ${selected.isolateId}',
                    style: textTheme.bodyMedium,
                  ),
                Text(
                  'Auto-Restarts: ${selected.restartCount}',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  key: const ValueKey('inspector-crash-btn'),
                  onPressed: _simulateCrashSelectedNode,
                  icon: Icon(Icons.warning_amber, color: cs.error),
                  label: Text(
                    'Trigger Crash & Supervisor Auto-Respawn',
                    style: TextStyle(color: cs.error),
                  ),
                ),
                FilledButton.tonalIcon(
                  key: const ValueKey('inspector-start-stop-btn'),
                  onPressed: isRoot ? null : _toggleStartStopSelectedNode,
                  icon: Icon(isRunning ? Icons.stop : Icons.play_arrow),
                  label: Text(
                    isRunning
                        ? (isIsolate ? 'Stop Isolate' : 'Stop ServiceGroup')
                        : (isIsolate ? 'Start Isolate' : 'Start ServiceGroup'),
                  ),
                ),
                FilledButton.tonalIcon(
                  key: const ValueKey('inspector-restart-btn'),
                  onPressed: isRoot ? null : _restartSelectedNode,
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    isIsolate ? 'Restart Isolate' : 'Restart ServiceGroup',
                  ),
                ),
                if (isIsolate) ...[
                  FilledButton.tonalIcon(
                    key: const ValueKey('inspector-rpc-call-btn'),
                    onPressed: isRunning
                        ? () => _callSelectedIsolate(p2pToDns: false)
                        : null,
                    icon: const Icon(Icons.send),
                    label: const Text('Hub RPC call()'),
                  ),
                  FilledButton.tonalIcon(
                    key: const ValueKey('inspector-p2p-call-btn'),
                    onPressed: isRunning
                        ? () => _callSelectedIsolate(p2pToDns: true)
                        : null,
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('P2P call -> /network/dns'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoolboyCard(
    BuildContext context, {
    required ColorScheme cs,
    required TextTheme textTheme,
    required int availableWorkers,
    required int checkedOutWorkers,
    required int overflowWorkers,
  }) {
    return _buildSectionCard(
      context,
      key: const ValueKey('poolboy-chart-card'),
      title: '4. Create IsolatePool & Poolboy Burst Load (DmVizLineChart)',
      subtitle:
          'Configure pool size, maxOverflow, LIFO/FIFO checkout strategy, and watch worker leasing',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DropdownButton<int>(
                value: _poolSizeConfig,
                onChanged: (v) {
                  if (v != null) setState(() => _poolSizeConfig = v);
                },
                items: [1, 2, 3, 4]
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text('Base Size: $s'),
                      ),
                    )
                    .toList(),
              ),
              DropdownButton<int>(
                value: _poolMaxOverflowConfig,
                onChanged: (v) {
                  if (v != null) setState(() => _poolMaxOverflowConfig = v);
                },
                items: [0, 1, 2, 3, 4]
                    .map(
                      (o) => DropdownMenuItem(
                        value: o,
                        child: Text('Max Overflow: $o'),
                      ),
                    )
                    .toList(),
              ),
              DropdownButton<PoolStrategy>(
                value: _poolStrategyConfig,
                onChanged: (v) {
                  if (v != null) setState(() => _poolStrategyConfig = v);
                },
                items: PoolStrategy.values
                    .map(
                      (st) => DropdownMenuItem(
                        value: st,
                        child: Text('Strategy: ${st.name.toUpperCase()}'),
                      ),
                    )
                    .toList(),
              ),
              FilledButton.icon(
                key: const ValueKey('create-pool-btn'),
                onPressed: _recreateLivePool,
                icon: const Icon(Icons.layers),
                label: const Text('Create / Reconfigure Pool'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              Chip(
                avatar: Icon(Icons.check_circle, size: 16, color: cs.primary),
                label: Text('Available: $availableWorkers'),
              ),
              Chip(
                avatar: Icon(Icons.lock_clock, size: 16, color: cs.secondary),
                label: Text('Checked Out: $checkedOutWorkers'),
              ),
              Chip(
                avatar: Icon(Icons.bolt, size: 16, color: cs.tertiary),
                label: Text(
                  'Overflow Workers: $overflowWorkers / $_poolMaxOverflowConfig',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Pool Output: $_lastPoolOutput',
              key: const ValueKey('pool-output-summary'),
              style: textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.tonalIcon(
                key: const ValueKey('pool-transaction-btn'),
                onPressed: _runPoolTransaction,
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Run transaction()'),
              ),
              FilledButton.tonalIcon(
                key: const ValueKey('pool-burst-btn'),
                onPressed: _runPoolBurstOverflow,
                icon: const Icon(Icons.flash_on),
                label: const Text('Burst Checkouts (Trigger Overflow)'),
              ),
              OutlinedButton.icon(
                key: const ValueKey('pool-checkout-btn'),
                onPressed: _manualCheckoutWorker,
                icon: const Icon(Icons.output),
                label: const Text('Manual checkout()'),
              ),
              OutlinedButton.icon(
                key: const ValueKey('pool-checkin-btn'),
                onPressed: checkedOutWorkers > 0 ? _manualCheckinAll : null,
                icon: const Icon(Icons.input),
                label: const Text('Checkin All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: DmVizLineChart(
              data: List<DmVizPoint>.from(_poolTotalSeries),
              comparisonData: List<DmVizPoint>.from(_poolCheckedOutSeries),
              xAxisLabel: 'Event Tick',
              yAxisLabel: 'Workers (Solid=Total, Dashed=CheckedOut)',
              smooth: true,
              showMarkers: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventLogCard(
    BuildContext context, {
    required ColorScheme cs,
    required TextTheme textTheme,
  }) {
    return Card(
      key: const ValueKey('isolate-event-log-card'),
      color: cs.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.terminal, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Supervisor, Data Flow & Poolboy Event Log',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(_eventLogs.clear),
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_eventLogs.isEmpty)
              Text(
                'No events recorded yet.',
                style: textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              )
            else
              ..._eventLogs.take(10).map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.time,
                        style: textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: entry.isWarning
                              ? cs.errorContainer
                              : cs.secondaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          entry.category,
                          style: textTheme.labelSmall?.copyWith(
                            fontFamily: 'monospace',
                            color: entry.isWarning
                                ? cs.onErrorContainer
                                : cs.onSecondaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.message,
                          style: textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    Key? key,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      key: key,
      color: cs.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildLegendChip(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
