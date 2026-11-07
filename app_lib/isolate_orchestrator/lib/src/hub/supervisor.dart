import 'dart:isolate';

import 'hub.dart';
import 'lifecycle.dart';
import 'registry.dart';

/// OTP-style supervision strategy for a [Supervisor] / [ServiceGroup].
enum SupervisionStrategy {
  /// Only restart the failed child node.
  oneForOne,

  /// If any child fails, stop all sibling children (in reverse startup order)
  /// and restart all children (in startup order).
  oneForAll,

  /// If a child fails, stop any children started after it (in reverse startup
  /// order), then restart the failed child and those subsequent children (in
  /// startup order).
  restForOne,
}

/// Child restart behavior when an isolate exits or crashes.
enum ChildRestartType {
  /// Always restart the child (whether it exited normally or abnormally),
  /// unless explicitly stopped via `stopNode`.
  permanent,

  /// Restart the child only if it terminates abnormally (uncaught error,
  /// unexpected exit, or health check failure). Normal exits are not restarted.
  transient,

  /// Never restart the child automatically.
  temporary,
}

/// Lifecycle state of a supervision tree node.
enum NodeState { stopped, starting, running, restarting, stopping, failed }

/// Sliding-window restart intensity configuration for a [Supervisor].
class RestartIntensity {
  /// Maximum number of restarts allowed within [withinDuration].
  final int maxRestarts;

  /// Sliding time window for counting restarts.
  final Duration withinDuration;

  /// Exponential backoff delay policy between restarts.
  final RestartPolicy backoffPolicy;

  const RestartIntensity({
    this.maxRestarts = 3,
    this.withinDuration = const Duration(seconds: 5),
    this.backoffPolicy = const RestartPolicy(
      initialDelay: Duration(milliseconds: 20),
      maxDelay: Duration(seconds: 5),
    ),
  });
}

/// Tracks restart timestamps within a sliding time window to enforce [RestartIntensity].
class RestartIntensityTracker {
  final RestartIntensity intensity;
  final List<DateTime> _restartTimestamps = [];

  RestartIntensityTracker(this.intensity);

  /// Number of recorded restarts within the active window.
  int get recentRestarts {
    _prune(DateTime.now());
    return _restartTimestamps.length;
  }

  /// Record a restart attempt at [now] and return `true` if within [intensity.maxRestarts],
  /// or `false` if restart intensity has been exceeded.
  bool recordAndCheck([DateTime? now]) {
    final timestamp = now ?? DateTime.now();
    _prune(timestamp);
    if (_restartTimestamps.length >= intensity.maxRestarts) {
      return false;
    }
    _restartTimestamps.add(timestamp);
    return true;
  }

  /// Calculate backoff delay for the current restart count.
  Duration get currentBackoffDelay =>
      intensity.backoffPolicy.delayForAttempt(_restartTimestamps.length);

  /// Reset recorded restart history.
  void reset() {
    _restartTimestamps.clear();
  }

  void _prune(DateTime now) {
    final cutoff = now.subtract(intensity.withinDuration);
    _restartTimestamps.removeWhere((t) => t.isBefore(cutoff));
  }
}

/// Base specification for any node in the supervision tree.
sealed class NodeSpec {
  String get name;
  ChildRestartType get restartType;
  bool get autoStart;

  const NodeSpec();
}

/// Specification for a supervised child isolate node.
class ChildSpec extends NodeSpec {
  @override
  final String name;

  final String role;
  final void Function(SendPort) entryPoint;
  final Map<String, dynamic>? config;
  final List<String> capabilities;
  final List<String> subscribesTo;

  @override
  final ChildRestartType restartType;

  final Duration shutdownTimeout;

  @override
  final bool autoStart;

  const ChildSpec({
    required this.name,
    String? role,
    required this.entryPoint,
    this.config,
    this.capabilities = const [],
    this.subscribesTo = const [],
    this.restartType = ChildRestartType.permanent,
    this.shutdownTimeout = const Duration(seconds: 5),
    this.autoStart = true,
  }) : role = role ?? name;
}

/// Specification for a supervisor / service group node.
class SupervisorSpec extends NodeSpec {
  @override
  final String name;

  final SupervisionStrategy strategy;
  final RestartIntensity intensity;

  @override
  final ChildRestartType restartType;

  final List<NodeSpec> children;

  @override
  final bool autoStart;

  const SupervisorSpec({
    required this.name,
    this.strategy = SupervisionStrategy.oneForOne,
    this.intensity = const RestartIntensity(),
    this.restartType = ChildRestartType.permanent,
    this.children = const [],
    this.autoStart = true,
  });
}

/// Alias for [SupervisorSpec] when used as a logical service group specification.
typedef ServiceGroupSpec = SupervisorSpec;

/// Immutable snapshot of a node in the supervision tree.
class TreeNodeSnapshot {
  final String name;
  final String path;
  final String kind;
  final NodeState state;
  final String? isolateId;
  final String? role;
  final SupervisionStrategy? strategy;
  final ChildRestartType restartType;
  final int restartCount;
  final List<TreeNodeSnapshot> children;

  const TreeNodeSnapshot({
    required this.name,
    required this.path,
    required this.kind,
    required this.state,
    this.isolateId,
    this.role,
    this.strategy,
    required this.restartType,
    this.restartCount = 0,
    this.children = const [],
  });
}

/// Base class for live nodes in the supervision tree.
sealed class TreeNode {
  /// Node name (e.g., `dns`, `network`, or `/` for root).
  String get name;

  /// Full hierarchical path (e.g., `/`, `/network`, `/network/dns`).
  String get path;

  /// Parent supervisor (`null` only for the root supervisor `/`).
  Supervisor? get parent;

  /// Current lifecycle state of this node.
  NodeState get state;

  /// Restart type configured for this node.
  ChildRestartType get restartType;

  /// Total number of times this node has been restarted.
  int get restartCount;

  /// Create an immutable snapshot of this node and its subtree.
  TreeNodeSnapshot toSnapshot();
}

/// A leaf node in the supervision tree backed by an OS [Isolate].
class IsolateNode extends TreeNode {
  final ChildSpec spec;

  @override
  final Supervisor parent;

  @override
  final String path;

  @override
  NodeState state = NodeState.stopped;

  /// Active isolate handle if running.
  IsolateHandle? handle;
  int _restartCount = 0;

  /// Whether this node was explicitly stopped by a user/supervisor action
  /// and should stay stopped until `startNode` is called.
  bool explicitlyStopped = false;

  IsolateNode({required this.spec, required this.parent, required this.path});

  @override
  String get name => spec.name;

  @override
  ChildRestartType get restartType => spec.restartType;

  @override
  int get restartCount => _restartCount;

  /// Increment and return the restart count.
  int incrementRestartCount() => ++_restartCount;

  /// Current isolate ID if spawned.
  String? get currentIsolateId => handle?.id;

  /// Whether the underlying isolate is currently running.
  bool get isRunning =>
      state == NodeState.running &&
      handle != null &&
      handle!.state == IsolateState.running;

  @override
  TreeNodeSnapshot toSnapshot() => TreeNodeSnapshot(
    name: name,
    path: path,
    kind: 'isolate',
    state: state,
    isolateId: currentIsolateId,
    role: spec.role,
    restartType: restartType,
    restartCount: _restartCount,
  );
}

/// Composite supervisor / service group node in the supervision tree.
class Supervisor extends TreeNode {
  final SupervisorSpec spec;
  final IsolateHub _hub;

  @override
  final Supervisor? parent;

  @override
  final String path;

  @override
  NodeState state = NodeState.stopped;

  final List<TreeNode> _children = [];
  final RestartIntensityTracker intensityTracker;
  int _restartCount = 0;
  bool isRecovering = false;
  bool explicitlyStopped = false;

  Supervisor({
    required this.spec,
    required IsolateHub hub,
    required this.parent,
    required this.path,
  }) : _hub = hub,
       intensityTracker = RestartIntensityTracker(spec.intensity);

  @override
  String get name => spec.name;

  @override
  ChildRestartType get restartType => spec.restartType;

  /// Supervision strategy of this group.
  SupervisionStrategy get strategy => spec.strategy;

  /// Restart intensity of this group.
  RestartIntensity get intensity => spec.intensity;

  @override
  int get restartCount => _restartCount;

  /// Increment and return the restart count.
  int incrementRestartCount() => ++_restartCount;

  /// Ordered list of child nodes (in startup order).
  List<TreeNode> get children => List.unmodifiable(_children);

  /// Internal mutable child list for hub management.
  List<TreeNode> get mutableChildren => _children;

  /// Find direct child by name.
  TreeNode? getChild(String childName) {
    for (final child in _children) {
      if (child.name == childName) return child;
    }
    return null;
  }

  /// Create and attach a child [Supervisor] / [ServiceGroup] under this supervisor.
  Future<Supervisor> createGroup({
    required String name,
    SupervisionStrategy strategy = SupervisionStrategy.oneForOne,
    RestartIntensity intensity = const RestartIntensity(),
    ChildRestartType restartType = ChildRestartType.permanent,
    List<NodeSpec> children = const [],
    bool start = true,
  }) {
    return _hub.createGroup(
      name: name,
      parentPath: path,
      strategy: strategy,
      intensity: intensity,
      restartType: restartType,
      children: children,
      start: start,
    );
  }

  /// Register a child isolate service under this supervisor.
  Future<IsolateNode> registerService(
    ChildSpec childSpec, {
    bool start = true,
  }) {
    return _hub.registerService(childSpec, parentPath: path, start: start);
  }

  /// Start this supervisor and all of its children in startup order.
  Future<void> start() => _hub.startNode(path);

  /// Stop this supervisor and all of its children in reverse startup order.
  Future<void> stop({Duration? timeout}) =>
      _hub.stopNode(path, timeout: timeout);

  /// Restart this supervisor and all of its children.
  Future<void> restart({Duration? timeout}) =>
      _hub.restartNode(path, timeout: timeout);

  @override
  TreeNodeSnapshot toSnapshot() => TreeNodeSnapshot(
    name: name,
    path: path,
    kind: 'supervisor',
    state: state,
    strategy: strategy,
    restartType: restartType,
    restartCount: _restartCount,
    children: _children.map((c) => c.toSnapshot()).toList(),
  );
}

/// Alias for [Supervisor] when referred to as a service group.
typedef ServiceGroup = Supervisor;
