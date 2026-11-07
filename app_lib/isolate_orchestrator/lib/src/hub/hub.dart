import 'dart:async';
import 'dart:isolate';

import '../exception.dart';
import '../health/metrics.dart';
import '../health/monitor.dart';
import '../message/address.dart';
import '../message/envelope.dart';
import '../message/id_generator.dart';
import '../message/protocol.dart';
import 'lifecycle.dart';
import 'registry.dart';
import 'spawner.dart';
import 'supervisor.dart';

/// Hub configuration.
class HubConfig {
  final Duration healthCheckInterval;
  final Duration healthCheckTimeout;
  final int unhealthyThreshold;
  final int healthyThreshold;
  final RestartPolicy restartPolicy;
  final SupervisionStrategy rootStrategy;
  final RestartIntensity? rootIntensity;

  const HubConfig({
    this.healthCheckInterval = const Duration(seconds: 5),
    this.healthCheckTimeout = const Duration(seconds: 2),
    this.unhealthyThreshold = 3,
    this.healthyThreshold = 3,
    this.restartPolicy = const RestartPolicy(),
    this.rootStrategy = SupervisionStrategy.oneForOne,
    this.rootIntensity,
  });

  /// Effective restart intensity for the root supervisor (`/`).
  RestartIntensity get effectiveRootIntensity =>
      rootIntensity ??
      RestartIntensity(
        maxRestarts: restartPolicy.maxAttempts,
        withinDuration: const Duration(hours: 1),
        backoffPolicy: restartPolicy,
      );
}

/// Hub states.
enum HubState { created, starting, running, stopping, stopped }

/// Hub events.
sealed class HubEvent {}

class IsolateSpawned extends HubEvent {
  final IsolateHandle handle;
  IsolateSpawned(this.handle);
}

class IsolateReady extends HubEvent {
  final IsolateHandle handle;
  IsolateReady(this.handle);
}

class IsolateFailed extends HubEvent {
  final IsolateHandle handle;
  final String error;
  IsolateFailed(this.handle, this.error);
}

class IsolateStopped extends HubEvent {
  final String id;
  IsolateStopped(this.id);
}

class IsolateRestarting extends HubEvent {
  final String id;
  final int attempt;
  IsolateRestarting(this.id, this.attempt);
}

class HealthChanged extends HubEvent {
  final String id;
  final bool healthy;
  HealthChanged(this.id, this.healthy);
}

/// Emitted when a [Supervisor] restarts a failed child according to its [SupervisionStrategy].
class SupervisorChildRestarted extends HubEvent {
  final String supervisorPath;
  final String childPath;
  final SupervisionStrategy strategy;
  final int attempt;

  SupervisorChildRestarted({
    required this.supervisorPath,
    required this.childPath,
    required this.strategy,
    required this.attempt,
  });
}

/// Emitted when a [Supervisor] exceeds its [RestartIntensity] and escalates failure.
class SupervisorEscalated extends HubEvent {
  final String supervisorPath;
  final String failedChildPath;
  final String reason;

  SupervisorEscalated({
    required this.supervisorPath,
    required this.failedChildPath,
    required this.reason,
  });
}

/// Emitted when a node or service group in the supervision tree changes [NodeState].
class NodeStateChanged extends HubEvent {
  final String path;
  final NodeState state;

  NodeStateChanged(this.path, this.state);
}

/// Handle to a managed isolate.
abstract class IsolateHandle {
  String get id;
  String get name;
  String get role;
  String get path;
  IsolateState get state;
  SendPort get sendPort;
  IsolateMetrics? get lastMetrics;
  bool get isHealthy;

  /// Send protocol message to this isolate.
  void send(ProtocolMessage message);

  /// Perform a synchronous RPC call to this isolate.
  Future<TRes> call<TRes>(
    Object? request, {
    Duration? timeout,
    Map<String, dynamic>? metadata,
  });

  /// Send an asynchronous fire-and-forget message to this isolate.
  void cast(Object? message, {Map<String, dynamic>? metadata});

  /// Kill this isolate.
  Future<void> kill({bool graceful = true});
}

/// Central manager and root supervisor for all isolates.
abstract class IsolateHub {
  /// Create a new hub.
  factory IsolateHub({HubConfig? config}) => IsolateHubImpl(config: config);

  /// Hub configuration.
  HubConfig get config;

  /// Current hub state.
  HubState get state;

  /// Root supervisor (`/`) of the supervision tree.
  Supervisor get root;

  /// Start the hub.
  Future<void> start();

  /// Stop the hub and all managed isolates.
  Future<void> stop({Duration? timeout});

  /// Spawn a new isolate with given role and entry point.
  ///
  /// If [parentPath] is provided, attaches the node under that [Supervisor];
  /// otherwise attaches it under the [root] supervisor (`/`).
  Future<IsolateHandle> spawn<T>({
    required String role,
    required String name,
    required void Function(SendPort) entryPoint,
    Map<String, dynamic>? config,
    List<String>? capabilities,
    List<String>? subscribesTo,
    String? parentPath,
    ChildRestartType restartType = ChildRestartType.permanent,
  });

  /// Create a logical [Supervisor] / [ServiceGroup] in the supervision tree.
  Future<Supervisor> createGroup({
    required String name,
    String? parentPath,
    SupervisionStrategy strategy = SupervisionStrategy.oneForOne,
    RestartIntensity intensity = const RestartIntensity(),
    ChildRestartType restartType = ChildRestartType.permanent,
    List<NodeSpec> children = const [],
    bool start = true,
  });

  /// Register a supervised child service specification under [parentPath] (defaults to `/`).
  Future<IsolateNode> registerService(
    ChildSpec spec, {
    String? parentPath,
    bool start = true,
  });

  /// Register any [NodeSpec] ([ChildSpec] or [SupervisorSpec]) under [parentPath] (defaults to `/`).
  Future<TreeNode> registerNode(
    NodeSpec spec, {
    String? parentPath,
    bool start = true,
  });

  /// Start a stopped isolate node or an entire service group subtree (top-down in startup order).
  Future<void> startNode(String target);

  /// Stop a running isolate node or an entire service group subtree (bottom-up in reverse startup order).
  ///
  /// The node specification remains registered in the supervision tree and can be started again
  /// with [startNode].
  Future<void> stopNode(String target, {Duration? timeout});

  /// Restart an isolate node or an entire service group subtree.
  Future<void> restartNode(String target, {Duration? timeout});

  /// Stop and permanently remove a node or service group from the supervision tree.
  Future<void> removeNode(String target, {Duration? timeout});

  /// Look up a running isolate handle by `id`, `path`, `name`, `role`, or `capability`.
  IsolateHandle? lookup(String target);

  /// Look up a supervision tree node ([Supervisor] or [IsolateNode]) by `path`, `name`, or active `id`.
  TreeNode? lookupNode(String target);

  /// Get isolate handle by logical name.
  IsolateHandle? getByName(String name);

  /// Get isolate handle by hierarchical tree path (e.g., `/network/dns`).
  IsolateHandle? getByPath(String path);

  /// Get all isolates with given role.
  List<IsolateHandle> getByRole(String role);

  /// Get all isolates declaring the given capability.
  List<IsolateHandle> getByCapability(String capability);

  /// Get isolate by ID.
  IsolateHandle? getById(String id);

  /// Capture an immutable snapshot of the entire supervision tree starting at `/`.
  TreeNodeSnapshot treeSnapshot();

  /// Stream of hub events.
  Stream<HubEvent> get events;

  /// Send protocol message to specific isolate (by `id`, `path`, or `name`).
  void send(String target, ProtocolMessage message);

  /// Broadcast protocol message to all isolates with role.
  void broadcast(String role, ProtocolMessage message);

  /// Perform a synchronous RPC request-response call to [target] (`path`, `name`, `id`, `role`, or `capability`).
  Future<TRes> call<TRes>(
    String target,
    Object? request, {
    Duration? timeout,
    Map<String, dynamic>? metadata,
  });

  /// Send an asynchronous fire-and-forget message to [target] (`path`, `name`, `id`, `role`, or `capability`).
  void cast(String target, Object? message, {Map<String, dynamic>? metadata});
}

/// Implementation of [IsolateHub].
class IsolateHubImpl implements IsolateHub {
  @override
  final HubConfig config;

  final IsolateRegistry _registry = IsolateRegistry();
  final LifecycleManager _lifecycle;
  final MessageIdGenerator _idGenerator = MessageIdGenerator('hub');
  final StreamController<HubEvent> _eventController =
      StreamController<HubEvent>.broadcast();
  final Map<String, StreamSubscription> _isolateSubscriptions = {};
  final Map<String, SpawnConfig> _spawnConfigs = {};
  final Map<String, ReceivePort> _exitPorts = {};
  final Map<String, ReceivePort> _errorPorts = {};

  /// Supervision tree indices.
  late final Supervisor _root;
  final Map<String, TreeNode> _nodesByPath = {};
  final Map<String, TreeNode> _nodesByName = {};
  final Map<String, IsolateNode> _nodeByIsolateId = {};

  /// Tracks which targets each isolate has dynamically resolved via [ResolveAddress].
  final Map<String, Set<String>> _resolvedByIsolate = {};

  /// RPC reply port and pending RPC completers for `hub.call`.
  final ReceivePort _rpcReplyPort = ReceivePort();
  final Map<String, Completer<Object?>> _pendingRpcCalls = {};
  StreamSubscription? _rpcSubscription;

  late final IsolateSpawner _spawner;
  late final HealthMonitor _healthMonitor;

  HubState _state = HubState.created;

  IsolateHubImpl({HubConfig? config})
    : config = config ?? const HubConfig(),
      _lifecycle = LifecycleManager(policy: config?.restartPolicy) {
    final effectiveConfig = this.config;
    _root = Supervisor(
      spec: SupervisorSpec(
        name: '/',
        strategy: effectiveConfig.rootStrategy,
        intensity: effectiveConfig.effectiveRootIntensity,
      ),
      hub: this,
      parent: null,
      path: '/',
    );
    _nodesByPath['/'] = _root;
  }

  @override
  HubState get state => _state;

  @override
  Supervisor get root => _root;

  @override
  Stream<HubEvent> get events => _eventController.stream;

  @override
  Future<void> start() async {
    if (_state != HubState.created) {
      throw StateError('Hub already started');
    }

    _state = HubState.starting;

    // Initialize spawner
    _spawner = IsolateSpawner(idGenerator: _idGenerator);

    // Listen for RPC replies
    _rpcSubscription = _rpcReplyPort.listen(_handleRpcReply);

    // Initialize health monitor
    _healthMonitor = HealthMonitor(
      registry: _registry,
      config: config,
      idGenerator: _idGenerator,
      onHealthChanged: _onHealthChanged,
      onIsolateFailed: _onIsolateFailed,
    );

    // Start health monitoring
    _healthMonitor.start();

    _root.state = NodeState.running;
    _state = HubState.running;

    // Start any pre-registered nodes under root that have autoStart == true
    for (final child in _root.children) {
      if (_shouldAutoStart(child)) {
        await _startTreeNode(child);
      }
    }
  }

  bool _shouldAutoStart(TreeNode node) {
    return switch (node) {
      IsolateNode(:final spec) => spec.autoStart,
      Supervisor(:final spec) => spec.autoStart,
    };
  }

  @override
  Future<void> stop({Duration? timeout}) async {
    if (_state != HubState.running) return;

    _state = HubState.stopping;

    // Stop health monitoring
    _healthMonitor.stop();

    // Cancel all pending restarts
    _lifecycle.cancelAll();

    // Fail any pending RPC calls
    for (final completer in _pendingRpcCalls.values) {
      if (!completer.isCompleted) {
        completer.completeError(HubStateException('Hub is stopping'));
      }
    }
    _pendingRpcCalls.clear();
    await _rpcSubscription?.cancel();
    _rpcReplyPort.close();

    // Stop the supervision tree bottom-up (reverse startup order)
    final shutdownTimeout = timeout ?? const Duration(seconds: 10);
    await _stopSupervisorChildren(
      _root,
      timeout: shutdownTimeout,
      markExplicit: true,
    );
    _root.state = NodeState.stopped;

    // Shutdown any remaining standalone isolates
    final futures = <Future>[];
    for (final entry in _registry.all.toList()) {
      futures.add(_shutdownIsolate(entry, shutdownTimeout));
    }
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }

    // Close any remaining exit and error ports
    for (final exitPort in _exitPorts.values) {
      exitPort.close();
    }
    _exitPorts.clear();
    for (final errorPort in _errorPorts.values) {
      errorPort.close();
    }
    _errorPorts.clear();
    _spawnConfigs.clear();
    _resolvedByIsolate.clear();
    _nodeByIsolateId.clear();

    // Clear registry
    _registry.clear();
    _lifecycle.clear();

    _state = HubState.stopped;

    // Close event stream
    await _eventController.close();
  }

  // ===========================================================================
  // Supervision Tree & Service Group Management
  // ===========================================================================

  @override
  Future<Supervisor> createGroup({
    required String name,
    String? parentPath,
    SupervisionStrategy strategy = SupervisionStrategy.oneForOne,
    RestartIntensity intensity = const RestartIntensity(),
    ChildRestartType restartType = ChildRestartType.permanent,
    List<NodeSpec> children = const [],
    bool start = true,
  }) async {
    final spec = SupervisorSpec(
      name: name,
      strategy: strategy,
      intensity: intensity,
      restartType: restartType,
      children: children,
      autoStart: start,
    );
    final node = await registerNode(spec, parentPath: parentPath, start: start);
    return node as Supervisor;
  }

  @override
  Future<IsolateNode> registerService(
    ChildSpec spec, {
    String? parentPath,
    bool start = true,
  }) async {
    final node = await registerNode(spec, parentPath: parentPath, start: start);
    return node as IsolateNode;
  }

  @override
  Future<TreeNode> registerNode(
    NodeSpec spec, {
    String? parentPath,
    bool start = true,
  }) async {
    final parent = _resolveParentSupervisor(parentPath);
    final nodePath = _joinPath(parent.path, spec.name);

    final existing = _nodesByPath[nodePath];
    if (existing != null) {
      if (start && _state == HubState.running) {
        await _startTreeNode(existing);
      }
      return existing;
    }

    switch (spec) {
      case ChildSpec childSpec:
        final isolateNode = IsolateNode(
          spec: childSpec,
          parent: parent,
          path: nodePath,
        );
        parent.mutableChildren.add(isolateNode);
        _nodesByPath[nodePath] = isolateNode;
        _nodesByName[childSpec.name] = isolateNode;

        if (start && childSpec.autoStart && _state == HubState.running) {
          await _startIsolateNode(isolateNode);
        }
        return isolateNode;

      case SupervisorSpec groupSpec:
        final supervisor = Supervisor(
          spec: groupSpec,
          hub: this,
          parent: parent,
          path: nodePath,
        );
        parent.mutableChildren.add(supervisor);
        _nodesByPath[nodePath] = supervisor;
        _nodesByName[groupSpec.name] = supervisor;

        // Materialize declarative children
        for (final childSpec in groupSpec.children) {
          await registerNode(childSpec, parentPath: nodePath, start: false);
        }

        if (start && groupSpec.autoStart && _state == HubState.running) {
          await _startSupervisorNode(supervisor);
        }
        return supervisor;
    }
  }

  @override
  Future<void> startNode(String target) async {
    if (_state != HubState.running) {
      throw HubStateException('Hub is not running');
    }
    final node = lookupNode(target);
    if (node == null) {
      throw NodeNotFoundException(target);
    }
    await _startTreeNode(node);
  }

  @override
  Future<void> stopNode(String target, {Duration? timeout}) async {
    final node = lookupNode(target);
    if (node == null) {
      throw NodeNotFoundException(target);
    }
    await _stopTreeNode(node, timeout: timeout, markExplicit: true);
  }

  @override
  Future<void> restartNode(String target, {Duration? timeout}) async {
    if (_state != HubState.running) {
      throw HubStateException('Hub is not running');
    }
    final node = lookupNode(target);
    if (node == null) {
      throw NodeNotFoundException(target);
    }
    await _stopTreeNode(node, timeout: timeout, markExplicit: false);
    await _startTreeNode(node);
  }

  @override
  Future<void> removeNode(String target, {Duration? timeout}) async {
    final node = lookupNode(target);
    if (node == null) {
      throw NodeNotFoundException(target);
    }
    if (node.path == '/') {
      throw ArgumentError('Cannot remove root supervisor "/"');
    }
    await _stopTreeNode(node, timeout: timeout, markExplicit: true);
    _removeSubtreeFromIndices(node);
    node.parent?.mutableChildren.remove(node);
  }

  void _removeSubtreeFromIndices(TreeNode node) {
    _nodesByPath.remove(node.path);
    if (_nodesByName[node.name] == node) {
      _nodesByName.remove(node.name);
    }
    if (node is Supervisor) {
      for (final child in node.mutableChildren.toList()) {
        _removeSubtreeFromIndices(child);
      }
      node.mutableChildren.clear();
    } else if (node is IsolateNode) {
      if (node.currentIsolateId != null) {
        _nodeByIsolateId.remove(node.currentIsolateId);
      }
    }
  }

  Supervisor _resolveParentSupervisor(String? parentPath) {
    if (parentPath == null || parentPath.isEmpty || parentPath == '/') {
      return _root;
    }
    final node = lookupNode(parentPath);
    if (node is Supervisor) {
      return node;
    }
    throw NodeNotFoundException(parentPath);
  }

  String _joinPath(String parentPath, String name) {
    final cleanName = name.startsWith('/') ? name.substring(1) : name;
    if (parentPath == '/' || parentPath.isEmpty) {
      return '/$cleanName';
    }
    return '$parentPath/$cleanName';
  }

  Future<void> _startTreeNode(TreeNode node) async {
    switch (node) {
      case IsolateNode isolateNode:
        await _startIsolateNode(isolateNode);
      case Supervisor supervisor:
        await _startSupervisorNode(supervisor);
    }
  }

  Future<void> _stopTreeNode(
    TreeNode node, {
    Duration? timeout,
    required bool markExplicit,
  }) async {
    switch (node) {
      case IsolateNode isolateNode:
        await _stopIsolateNode(
          isolateNode,
          timeout: timeout,
          markExplicit: markExplicit,
        );
      case Supervisor supervisor:
        await _stopSupervisorNode(
          supervisor,
          timeout: timeout,
          markExplicit: markExplicit,
        );
    }
  }

  Future<void> _startSupervisorNode(Supervisor supervisor) async {
    supervisor.explicitlyStopped = false;
    _setNodeState(supervisor, NodeState.starting);

    // Start children top-down in startup order
    for (final child in supervisor.mutableChildren) {
      await _startTreeNode(child);
    }

    supervisor.intensityTracker.reset();
    _setNodeState(supervisor, NodeState.running);
  }

  Future<void> _stopSupervisorNode(
    Supervisor supervisor, {
    Duration? timeout,
    required bool markExplicit,
  }) async {
    if (markExplicit) {
      supervisor.explicitlyStopped = true;
    }
    _setNodeState(supervisor, NodeState.stopping);
    await _stopSupervisorChildren(
      supervisor,
      timeout: timeout,
      markExplicit: markExplicit,
    );
    _setNodeState(supervisor, NodeState.stopped);
  }

  Future<void> _stopSupervisorChildren(
    Supervisor supervisor, {
    Duration? timeout,
    required bool markExplicit,
  }) async {
    // Stop children bottom-up in reverse startup order
    final reversed = supervisor.mutableChildren.reversed.toList();
    for (final child in reversed) {
      await _stopTreeNode(child, timeout: timeout, markExplicit: markExplicit);
    }
  }

  Future<IsolateHandle> _startIsolateNode(IsolateNode node) async {
    if (node.isRunning && node.handle != null) {
      return node.handle!;
    }

    node.explicitlyStopped = false;
    _setNodeState(node, NodeState.starting);

    try {
      final handle = await _spawnInternal(
        role: node.spec.role,
        name: node.spec.name,
        path: node.path,
        entryPoint: node.spec.entryPoint,
        config: node.spec.config,
        capabilities: node.spec.capabilities,
        subscribesTo: node.spec.subscribesTo,
        node: node,
      );
      node.handle = handle;
      _nodeByIsolateId[handle.id] = node;
      _setNodeState(node, NodeState.running);
      return handle;
    } catch (e) {
      _setNodeState(node, NodeState.failed);
      rethrow;
    }
  }

  Future<void> _stopIsolateNode(
    IsolateNode node, {
    Duration? timeout,
    required bool markExplicit,
  }) async {
    if (markExplicit) {
      node.explicitlyStopped = true;
    }
    final activeId = node.currentIsolateId;
    final entry = activeId != null ? _registry.get(activeId) : null;
    if (entry != null && entry.state != IsolateState.stopped) {
      _setNodeState(node, NodeState.stopping);
      await _shutdownIsolate(entry, timeout ?? node.spec.shutdownTimeout);
    }
    if (activeId != null) {
      _nodeByIsolateId.remove(activeId);
    }
    node.handle = null;
    _setNodeState(node, NodeState.stopped);
  }

  void _setNodeState(TreeNode node, NodeState newState) {
    switch (node) {
      case IsolateNode n:
        n.state = newState;
      case Supervisor s:
        s.state = newState;
    }
    if (!_eventController.isClosed) {
      _eventController.add(NodeStateChanged(node.path, newState));
    }
  }

  // ===========================================================================
  // Isolate Spawning & Shutdown
  // ===========================================================================

  @override
  Future<IsolateHandle> spawn<T>({
    required String role,
    required String name,
    required void Function(SendPort) entryPoint,
    Map<String, dynamic>? config,
    List<String>? capabilities,
    List<String>? subscribesTo,
    String? parentPath,
    ChildRestartType restartType = ChildRestartType.permanent,
  }) async {
    if (_state != HubState.running) {
      throw StateError('Hub is not running');
    }

    final parent = _resolveParentSupervisor(parentPath);
    final nodePath = _joinPath(parent.path, name);

    IsolateNode isolateNode;
    final existing = _nodesByPath[nodePath];
    if (existing is IsolateNode) {
      isolateNode = existing;
    } else {
      final spec = ChildSpec(
        name: name,
        role: role,
        entryPoint: entryPoint,
        config: config,
        capabilities: capabilities ?? const [],
        subscribesTo: subscribesTo ?? const [],
        restartType: restartType,
      );
      isolateNode = IsolateNode(spec: spec, parent: parent, path: nodePath);
      parent.mutableChildren.add(isolateNode);
      _nodesByPath[nodePath] = isolateNode;
      _nodesByName[name] = isolateNode;
    }

    return _startIsolateNode(isolateNode);
  }

  Future<IsolateHandle> _spawnInternal({
    required String role,
    required String name,
    required String path,
    required void Function(SendPort) entryPoint,
    Map<String, dynamic>? config,
    List<String>? capabilities,
    List<String>? subscribesTo,
    IsolateNode? node,
  }) async {
    final spawnConfig = SpawnConfig(
      role: role,
      name: name,
      path: path,
      entryPoint: entryPoint,
      config: config,
      capabilities: capabilities ?? const [],
      subscribesTo: subscribesTo ?? const [],
    );

    // Spawn isolate
    final entry = await _spawner.spawn(spawnConfig);
    _registry.register(entry);
    _spawnConfigs[entry.id] = spawnConfig;
    if (node != null) {
      _nodeByIsolateId[entry.id] = node;
    }

    // Set up permanent listener for messages from this isolate
    _isolateSubscriptions[entry.id] = entry.broadcastStream.listen(
      _handleMessage,
    );

    final handle = _IsolateHandleImpl(entry, this);
    if (node != null) {
      node.handle = handle;
    }
    if (!_eventController.isClosed) {
      _eventController.add(IsolateSpawned(handle));
    }

    // Gather dependencies (supports role, name, or path in subscribesTo)
    final dependencies = <String, List<PortInfo>>{};
    for (final dep in entry.subscribesTo) {
      final byRole = _registry.getPortsForRole(dep);
      if (byRole.isNotEmpty) {
        dependencies[dep] = byRole;
      } else {
        final resolved = _registry
            .resolveAll(dep)
            .where((e) => e.state == IsolateState.running)
            .map((e) => e.toPortInfo())
            .toList();
        dependencies[dep] = resolved;
      }
    }

    // Initialize
    try {
      await _spawner.initialize(
        entry,
        config: config,
        dependencies: dependencies,
      );
    } catch (e) {
      entry.state = IsolateState.failed;
      entry.isolate.kill(priority: Isolate.immediate);
      entry.controlPort.close();
      await _isolateSubscriptions.remove(entry.id)?.cancel();
      _spawnConfigs.remove(entry.id);
      _nodeByIsolateId.remove(entry.id);
      _registry.unregister(entry.id);
      rethrow;
    }

    // Monitor uncaught errors in child isolate
    final errorPort = ReceivePort();
    _errorPorts[entry.id] = errorPort;
    entry.isolate.addErrorListener(errorPort.sendPort);
    errorPort.listen((errorData) {
      errorPort.close();
      _errorPorts.remove(entry.id);
      if (_state == HubState.running && entry.state == IsolateState.running) {
        final errorMsg = errorData is List && errorData.isNotEmpty
            ? '${errorData.first}'
            : '$errorData';
        _onIsolateTerminated(
          entry.id,
          isAbnormal: true,
          reason: 'Uncaught error: $errorMsg',
        );
      }
    });

    // Monitor isolate exit
    final exitPort = ReceivePort();
    _exitPorts[entry.id] = exitPort;
    entry.isolate.addOnExitListener(exitPort.sendPort);
    exitPort.listen((_) {
      exitPort.close();
      _exitPorts.remove(entry.id);
      _errorPorts.remove(entry.id)?.close();
      if (_state == HubState.running && entry.state == IsolateState.running) {
        final isAbnormal = !entry.normalExit;
        _onIsolateTerminated(
          entry.id,
          isAbnormal: isAbnormal,
          reason: isAbnormal ? 'Unexpected isolate exit' : 'Normal exit',
        );
      }
    });

    if (!_eventController.isClosed) {
      _eventController.add(IsolateReady(handle));
    }

    // Notify subscribers and resolvers about new port
    _notifyPortUpdate(entry);

    return handle;
  }

  Future<void> _shutdownIsolate(IsolateEntry entry, Duration timeout) async {
    if (entry.state == IsolateState.stopped) return;

    entry.state = IsolateState.stopping;
    _lifecycle.removeTracker(entry.id);
    _spawnConfigs.remove(entry.id);
    _exitPorts.remove(entry.id)?.close();
    _errorPorts.remove(entry.id)?.close();
    _resolvedByIsolate.remove(entry.id);

    final completer = Completer<void>();

    // Listen for shutdown ack using broadcast stream
    late StreamSubscription subscription;
    subscription = entry.broadcastStream.listen((message) {
      if (message is Envelope && message.payload is ShutdownAck) {
        subscription.cancel();
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });

    // Send shutdown command
    final envelope = Envelope.create(
      id: _idGenerator.next(),
      source: IsolateAddress.hub,
      target: IsolateAddress.of(entry.role, entry.id),
      payload: Shutdown(graceful: true, timeoutMs: timeout.inMilliseconds),
    );
    entry.sendPort.send(envelope);

    // Wait with timeout
    try {
      await completer.future.timeout(timeout);
    } on TimeoutException {
      // Force kill
      entry.isolate.kill(priority: Isolate.immediate);
    } finally {
      await subscription.cancel();
      entry.controlPort.close();
      entry.state = IsolateState.stopped;
      _healthMonitor.removePendingPing(entry.id);
      await _isolateSubscriptions.remove(entry.id)?.cancel();
      _registry.unregister(entry.id);
      _notifyPortRemoved(entry);
      if (!_eventController.isClosed) {
        _eventController.add(IsolateStopped(entry.id));
      }
    }
  }

  // ===========================================================================
  // Port Updates & Dynamic Address Resolution
  // ===========================================================================

  bool _shouldNotifyIsolate(IsolateEntry listener, IsolateEntry changed) {
    if (listener.id == changed.id) return false;
    if (listener.subscribesTo.contains(changed.role) ||
        listener.subscribesTo.contains(changed.name) ||
        listener.subscribesTo.contains(changed.path) ||
        listener.subscribesTo.contains('*')) {
      return true;
    }
    final resolvedTargets = _resolvedByIsolate[listener.id];
    if (resolvedTargets != null && resolvedTargets.isNotEmpty) {
      if (resolvedTargets.contains(changed.id) ||
          resolvedTargets.contains(changed.name) ||
          resolvedTargets.contains(changed.path) ||
          resolvedTargets.contains(changed.role) ||
          changed.capabilities.any(resolvedTargets.contains)) {
        return true;
      }
    }
    return false;
  }

  void _notifyPortUpdate(IsolateEntry newEntry) {
    final portInfo = newEntry.toPortInfo();

    final update = PortUpdate(
      version: DateTime.now().microsecondsSinceEpoch,
      role: newEntry.role,
      added: [portInfo],
    );

    for (final entry in _registry.all) {
      if (_shouldNotifyIsolate(entry, newEntry)) {
        final envelope = Envelope.create(
          id: _idGenerator.next(),
          source: IsolateAddress.hub,
          target: IsolateAddress.of(entry.role, entry.id),
          payload: update,
        );
        entry.sendPort.send(envelope);
      }
    }
  }

  void _notifyPortRemoved(IsolateEntry removedEntry) {
    final update = PortUpdate(
      version: DateTime.now().microsecondsSinceEpoch,
      role: removedEntry.role,
      removed: [removedEntry.id],
      removedNames: [removedEntry.name],
      removedPaths: [removedEntry.path],
    );

    for (final entry in _registry.all) {
      if (_shouldNotifyIsolate(entry, removedEntry)) {
        final envelope = Envelope.create(
          id: _idGenerator.next(),
          source: IsolateAddress.hub,
          target: IsolateAddress.of(entry.role, entry.id),
          payload: update,
        );
        entry.sendPort.send(envelope);
      }
    }
  }

  // ===========================================================================
  // Registry Lookup & Tree Inspection
  // ===========================================================================

  @override
  IsolateHandle? lookup(String target) {
    final entry = _registry.resolve(target);
    return entry != null ? _IsolateHandleImpl(entry, this) : null;
  }

  @override
  TreeNode? lookupNode(String target) {
    if (target == '/') return _root;

    final normalizedPath = target.startsWith('/') ? target : '/$target';
    final byPath = _nodesByPath[normalizedPath];
    if (byPath != null) return byPath;

    final byName = _nodesByName[target];
    if (byName != null) return byName;

    final byIsolateId = _nodeByIsolateId[target];
    if (byIsolateId != null) return byIsolateId;

    return null;
  }

  @override
  IsolateHandle? getByName(String name) {
    final entry = _registry.getByName(name);
    return entry != null ? _IsolateHandleImpl(entry, this) : null;
  }

  @override
  IsolateHandle? getByPath(String path) {
    final entry = _registry.getByPath(path);
    return entry != null ? _IsolateHandleImpl(entry, this) : null;
  }

  @override
  List<IsolateHandle> getByRole(String role) {
    return _registry
        .getByRole(role)
        .map((e) => _IsolateHandleImpl(e, this))
        .toList();
  }

  @override
  List<IsolateHandle> getByCapability(String capability) {
    return _registry
        .getByCapability(capability)
        .map((e) => _IsolateHandleImpl(e, this))
        .toList();
  }

  @override
  IsolateHandle? getById(String id) {
    final entry = _registry.get(id);
    return entry != null ? _IsolateHandleImpl(entry, this) : null;
  }

  @override
  TreeNodeSnapshot treeSnapshot() => _root.toSnapshot();

  // ===========================================================================
  // Messaging & Direct RPC (send, broadcast, call, cast)
  // ===========================================================================

  @override
  void send(String target, ProtocolMessage message) {
    final entry = _registry.get(target) ?? _registry.resolve(target);
    if (entry == null) return;

    final envelope = Envelope.create(
      id: _idGenerator.next(),
      source: IsolateAddress.hub,
      target: IsolateAddress.of(entry.role, entry.id),
      payload: message,
    );
    entry.sendPort.send(envelope);
  }

  @override
  void broadcast(String role, ProtocolMessage message) {
    for (final entry in _registry.getByRole(role)) {
      final envelope = Envelope.create(
        id: _idGenerator.next(),
        source: IsolateAddress.hub,
        target: IsolateAddress.of(entry.role, entry.id),
        payload: message,
      );
      entry.sendPort.send(envelope);
    }
  }

  @override
  void cast(String target, Object? message, {Map<String, dynamic>? metadata}) {
    final entry = _registry.resolve(target);
    if (entry == null || entry.state != IsolateState.running) {
      throw NodeNotFoundException(target);
    }

    final envelope = Envelope.create(
      id: _idGenerator.next(),
      source: IsolateAddress.hub,
      target: IsolateAddress.of(entry.role, entry.id),
      payload: CastMessage(message: message, metadata: metadata),
    );
    entry.sendPort.send(envelope);
  }

  @override
  Future<TRes> call<TRes>(
    String target,
    Object? request, {
    Duration? timeout,
    Map<String, dynamic>? metadata,
  }) async {
    final entry = _registry.resolve(target);
    if (entry == null || entry.state != IsolateState.running) {
      throw NodeNotFoundException(target);
    }

    final msgId = _idGenerator.next();
    final completer = Completer<Object?>();
    _pendingRpcCalls[msgId] = completer;

    final envelope = Envelope<ProtocolMessage>(
      id: msgId,
      timestamp: DateTime.now().microsecondsSinceEpoch,
      correlationId: msgId,
      source: IsolateAddress.hub,
      target: IsolateAddress.of(entry.role, entry.id),
      replyTo: _rpcReplyPort.sendPort,
      payload: RpcRequest(request: request, metadata: metadata),
    );

    entry.sendPort.send(envelope);

    final effectiveTimeout = timeout ?? const Duration(seconds: 5);
    try {
      final res = await completer.future.timeout(effectiveTimeout);
      return res as TRes;
    } on TimeoutException {
      throw TaskTimeoutException(msgId, 0);
    } finally {
      _pendingRpcCalls.remove(msgId);
    }
  }

  void _handleRpcReply(dynamic message) {
    if (message is! Envelope) return;
    final corrId = message.correlationId ?? message.id;
    final completer = _pendingRpcCalls.remove(corrId);
    if (completer == null || completer.isCompleted) return;

    final payload = message.payload;
    switch (payload) {
      case RpcResponse response:
        completer.complete(response.result);
      case RpcError error:
        completer.completeError(
          TaskException(
            error.code,
            error.message,
            error.details,
            error.stackTrace,
          ),
        );
      case TaskResult result:
        completer.complete(result.data);
      case TaskError error:
        completer.completeError(
          TaskException(
            error.code,
            error.message,
            error.details,
            error.stackTrace,
          ),
        );
      default:
        completer.complete(payload);
    }
  }

  // ===========================================================================
  // Hub Control Message Handling & OTP Supervision Recovery
  // ===========================================================================

  void _handleMessage(dynamic message) {
    if (message is! Envelope) return;

    final payload = message.payload;

    switch (payload) {
      case Pong pong:
        _healthMonitor.handlePong(message.source.id, pong);

      case PortUpdateAck():
        break;

      case ResolveAddress resolveReq:
        _resolvedByIsolate
            .putIfAbsent(message.source.id, () => {})
            .add(resolveReq.target);
        final single = _registry.resolve(resolveReq.target);
        final allPorts = _registry
            .resolveAll(resolveReq.target)
            .where((e) => e.state == IsolateState.running)
            .map((e) => e.toPortInfo())
            .toList();
        final replyEnvelope = message.reply(
          ResolveAddressResult(
            target: resolveReq.target,
            portInfo: single != null && single.state == IsolateState.running
                ? single.toPortInfo()
                : null,
            ports: allPorts,
          ),
          id: _idGenerator.next(),
        );
        final replyPort =
            message.replyTo ?? _registry.get(message.source.id)?.sendPort;
        replyPort?.send(replyEnvelope);

      case ShutdownAck():
        // If a running isolate sends ShutdownAck without Hub initiating Shutdown,
        // mark it as a voluntary normal exit for transient restart semantics.
        final entry = _registry.get(message.source.id);
        if (entry != null && entry.state == IsolateState.running) {
          entry.normalExit = true;
        }

      default:
        break;
    }
  }

  void _onHealthChanged(String isolateId, bool healthy) {
    if (healthy) {
      _lifecycle.resetTracker(isolateId);
      final node = _nodeByIsolateId[isolateId];
      node?.parent.intensityTracker.reset();
    }
    if (!_eventController.isClosed) {
      _eventController.add(HealthChanged(isolateId, healthy));
    }
  }

  void _onIsolateFailed(String isolateId) {
    _onIsolateTerminated(
      isolateId,
      isAbnormal: true,
      reason: 'Health check failed',
    );
  }

  void _onIsolateTerminated(
    String isolateId, {
    required bool isAbnormal,
    required String reason,
  }) {
    final entry = _registry.get(isolateId);
    if (entry == null ||
        entry.state == IsolateState.stopping ||
        entry.state == IsolateState.stopped ||
        entry.state == IsolateState.failed) {
      return;
    }

    final node = _nodeByIsolateId.remove(isolateId);

    if (isAbnormal) {
      entry.state = IsolateState.failed;
      final handle = _IsolateHandleImpl(entry, this);
      if (!_eventController.isClosed) {
        _eventController.add(IsolateFailed(handle, reason));
      }
    } else {
      entry.state = IsolateState.stopped;
    }

    // Clean up terminated isolate resources
    _spawnConfigs.remove(entry.id);
    entry.isolate.kill(priority: Isolate.immediate);
    entry.controlPort.close();
    _exitPorts.remove(entry.id)?.close();
    _errorPorts.remove(entry.id)?.close();
    _resolvedByIsolate.remove(entry.id);
    _healthMonitor.removePendingPing(entry.id);
    _isolateSubscriptions.remove(entry.id)?.cancel();
    _registry.unregister(entry.id);
    _notifyPortRemoved(entry);

    if (node == null || node.explicitlyStopped) {
      if (!_eventController.isClosed) {
        _eventController.add(IsolateStopped(entry.id));
      }
      return;
    }

    final shouldRestart = switch (node.restartType) {
      ChildRestartType.permanent => true,
      ChildRestartType.transient => isAbnormal,
      ChildRestartType.temporary => false,
    };

    if (!shouldRestart) {
      node.handle = null;
      _setNodeState(node, isAbnormal ? NodeState.failed : NodeState.stopped);
      if (!_eventController.isClosed) {
        _eventController.add(IsolateStopped(entry.id));
      }
      return;
    }

    final supervisor = node.parent;
    if (supervisor.explicitlyStopped || supervisor.isRecovering) {
      if (!_eventController.isClosed) {
        _eventController.add(IsolateStopped(entry.id));
      }
      return;
    }

    _handleSupervisorChildFailure(
      supervisor,
      node,
      failedIsolateId: entry.id,
      oldRestartCount: entry.restartCount,
      reason: reason,
    );
  }

  void _handleSupervisorChildFailure(
    Supervisor supervisor,
    TreeNode failedChild, {
    String? failedIsolateId,
    int oldRestartCount = 0,
    required String reason,
  }) {
    final withinIntensity = supervisor.intensityTracker.recordAndCheck();

    if (!withinIntensity) {
      // Restart intensity exceeded -> stop supervisor's children and escalate!
      if (failedIsolateId != null && !_eventController.isClosed) {
        _eventController.add(IsolateStopped(failedIsolateId));
      }
      if (failedChild is IsolateNode) {
        failedChild.handle = null;
        _setNodeState(failedChild, NodeState.failed);
      }

      final escalationReason =
          'Restart intensity exceeded (${supervisor.intensity.maxRestarts} '
          'restarts within ${supervisor.intensity.withinDuration.inMilliseconds}ms): $reason';

      if (!_eventController.isClosed) {
        _eventController.add(
          SupervisorEscalated(
            supervisorPath: supervisor.path,
            failedChildPath: failedChild.path,
            reason: escalationReason,
          ),
        );
      }

      supervisor.isRecovering = true;
      unawaited(() async {
        try {
          await _stopSupervisorChildren(supervisor, markExplicit: false);
          _setNodeState(supervisor, NodeState.failed);
        } finally {
          supervisor.isRecovering = false;
        }

        // Escalate to parent supervisor if present and allowed by restartType
        final parent = supervisor.parent;
        if (parent != null &&
            !parent.explicitlyStopped &&
            supervisor.restartType != ChildRestartType.temporary) {
          _handleSupervisorChildFailure(
            parent,
            supervisor,
            reason: 'Child supervisor "${supervisor.path}" failed',
          );
        }
      }());
      return;
    }

    final attempt = supervisor.intensityTracker.recentRestarts;
    final delay = supervisor.intensityTracker.currentBackoffDelay;

    if (failedIsolateId != null && !_eventController.isClosed) {
      _eventController.add(IsolateRestarting(failedIsolateId, attempt));
      _eventController.add(IsolateStopped(failedIsolateId));
    }

    if (!_eventController.isClosed) {
      _eventController.add(
        SupervisorChildRestarted(
          supervisorPath: supervisor.path,
          childPath: failedChild.path,
          strategy: supervisor.strategy,
          attempt: attempt,
        ),
      );
    }

    supervisor.isRecovering = true;
    _setNodeState(supervisor, NodeState.restarting);
    if (failedChild is IsolateNode) {
      failedChild.handle = null;
      _setNodeState(failedChild, NodeState.restarting);
    }

    Timer(delay, () async {
      if (_state != HubState.running || supervisor.explicitlyStopped) {
        supervisor.isRecovering = false;
        return;
      }

      try {
        await _executeSupervisionStrategy(
          supervisor,
          failedChild,
          failedIsolateId: failedIsolateId,
          oldRestartCount: oldRestartCount,
        );
        supervisor.isRecovering = false;
        if (_state == HubState.running && !supervisor.explicitlyStopped) {
          _setNodeState(supervisor, NodeState.running);
        }
      } catch (e) {
        supervisor.isRecovering = false;
        if (_state == HubState.running && !supervisor.explicitlyStopped) {
          _handleSupervisorChildFailure(
            supervisor,
            failedChild,
            oldRestartCount: oldRestartCount,
            reason: 'Restart attempt failed: $e',
          );
        }
      }
    });
  }

  Future<void> _executeSupervisionStrategy(
    Supervisor supervisor,
    TreeNode failedChild, {
    String? failedIsolateId,
    required int oldRestartCount,
  }) async {
    switch (supervisor.strategy) {
      case SupervisionStrategy.oneForOne:
        await _restartChildNode(
          failedChild,
          failedIsolateId: failedIsolateId,
          oldRestartCount: oldRestartCount,
        );

      case SupervisionStrategy.oneForAll:
        // 1. Stop all sibling children in reverse startup order
        final reversed = supervisor.mutableChildren.reversed.toList();
        for (final child in reversed) {
          if (child == failedChild && child is IsolateNode) continue;
          await _stopTreeNode(child, markExplicit: false);
        }
        // 2. Start all non-explicitly-stopped children in startup order
        for (final child in supervisor.mutableChildren) {
          if (_isExplicitlyStopped(child)) continue;
          if (child != failedChild &&
              child.restartType == ChildRestartType.temporary) {
            continue;
          }
          await _restartChildNode(
            child,
            failedIsolateId: child == failedChild ? failedIsolateId : null,
            oldRestartCount: child == failedChild ? oldRestartCount : 0,
          );
        }

      case SupervisionStrategy.restForOne:
        final children = supervisor.mutableChildren;
        final idx = children.indexOf(failedChild);
        if (idx == -1) return;

        // 1. Stop subsequent children in reverse startup order
        for (var i = children.length - 1; i > idx; i--) {
          await _stopTreeNode(children[i], markExplicit: false);
        }
        if (failedChild is Supervisor) {
          await _stopTreeNode(failedChild, markExplicit: false);
        }

        // 2. Restart from idx to end in startup order
        for (var i = idx; i < children.length; i++) {
          final child = children[i];
          if (_isExplicitlyStopped(child)) continue;
          if (child != failedChild &&
              child.restartType == ChildRestartType.temporary) {
            continue;
          }
          await _restartChildNode(
            child,
            failedIsolateId: child == failedChild ? failedIsolateId : null,
            oldRestartCount: child == failedChild ? oldRestartCount : 0,
          );
        }
    }
  }

  bool _isExplicitlyStopped(TreeNode node) {
    return switch (node) {
      IsolateNode n => n.explicitlyStopped,
      Supervisor s => s.explicitlyStopped,
    };
  }

  Future<void> _restartChildNode(
    TreeNode child, {
    String? failedIsolateId,
    required int oldRestartCount,
  }) async {
    switch (child) {
      case IsolateNode isolateNode:
        final newHandle = await _startIsolateNode(isolateNode);
        isolateNode.incrementRestartCount();
        if (failedIsolateId != null) {
          _lifecycle.transferTracker(failedIsolateId, newHandle.id);
        }
        final newEntry = _registry.get(newHandle.id);
        if (newEntry != null) {
          newEntry.restartCount = isolateNode.restartCount > oldRestartCount
              ? isolateNode.restartCount
              : oldRestartCount + 1;
        }

      case Supervisor childSupervisor:
        childSupervisor.incrementRestartCount();
        await _startSupervisorNode(childSupervisor);
    }
  }
}

/// Implementation of [IsolateHandle].
class _IsolateHandleImpl implements IsolateHandle {
  final IsolateEntry _entry;
  final IsolateHubImpl _hub;

  _IsolateHandleImpl(this._entry, this._hub);

  @override
  String get id => _entry.id;

  @override
  String get name => _entry.name;

  @override
  String get role => _entry.role;

  @override
  String get path => _entry.path;

  @override
  IsolateState get state => _entry.state;

  @override
  SendPort get sendPort => _entry.sendPort;

  @override
  IsolateMetrics? get lastMetrics => _entry.lastMetrics;

  @override
  bool get isHealthy => _entry.isHealthy;

  @override
  void send(ProtocolMessage message) {
    _hub.send(id, message);
  }

  @override
  Future<TRes> call<TRes>(
    Object? request, {
    Duration? timeout,
    Map<String, dynamic>? metadata,
  }) {
    return _hub.call<TRes>(id, request, timeout: timeout, metadata: metadata);
  }

  @override
  void cast(Object? message, {Map<String, dynamic>? metadata}) {
    _hub.cast(id, message, metadata: metadata);
  }

  @override
  Future<void> kill({bool graceful = true}) async {
    final node = _hub._nodeByIsolateId.remove(id);
    if (node != null) {
      node.explicitlyStopped = true;
      node.handle = null;
      _hub._setNodeState(node, NodeState.stopped);
    }

    if (graceful) {
      await _hub._shutdownIsolate(_entry, const Duration(seconds: 5));
    } else {
      if (_entry.state == IsolateState.stopped) return;
      _entry.state = IsolateState.stopped;
      _hub._lifecycle.removeTracker(id);
      _hub._spawnConfigs.remove(id);
      _hub._exitPorts.remove(id)?.close();
      _hub._errorPorts.remove(id)?.close();
      _hub._resolvedByIsolate.remove(id);
      _entry.isolate.kill(priority: Isolate.immediate);
      _entry.controlPort.close();
      _hub._healthMonitor.removePendingPing(id);
      await _hub._isolateSubscriptions.remove(id)?.cancel();
      _hub._registry.unregister(id);
      _hub._notifyPortRemoved(_entry);
      if (!_hub._eventController.isClosed) {
        _hub._eventController.add(IsolateStopped(id));
      }
    }
  }
}
