import 'dart:async';
import 'dart:isolate';

import '../health/metrics.dart';
import '../health/monitor.dart';
import '../message/address.dart';
import '../message/envelope.dart';
import '../message/id_generator.dart';
import '../message/protocol.dart';
import 'lifecycle.dart';
import 'registry.dart';
import 'spawner.dart';

/// Hub configuration.
class HubConfig {
  final Duration healthCheckInterval;
  final Duration healthCheckTimeout;
  final int unhealthyThreshold;
  final int healthyThreshold;
  final RestartPolicy restartPolicy;

  const HubConfig({
    this.healthCheckInterval = const Duration(seconds: 5),
    this.healthCheckTimeout = const Duration(seconds: 2),
    this.unhealthyThreshold = 3,
    this.healthyThreshold = 3,
    this.restartPolicy = const RestartPolicy(),
  });
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

/// Handle to a managed isolate.
abstract class IsolateHandle {
  String get id;
  String get name;
  String get role;
  IsolateState get state;
  SendPort get sendPort;
  IsolateMetrics? get lastMetrics;
  bool get isHealthy;

  /// Send message to this isolate.
  void send(ProtocolMessage message);

  /// Kill this isolate.
  Future<void> kill({bool graceful = true});
}

/// Central manager for all isolates.
abstract class IsolateHub {
  /// Create a new hub.
  factory IsolateHub({HubConfig? config}) => IsolateHubImpl(config: config);

  /// Hub configuration.
  HubConfig get config;

  /// Current hub state.
  HubState get state;

  /// Start the hub.
  Future<void> start();

  /// Stop the hub and all managed isolates.
  Future<void> stop({Duration? timeout});

  /// Spawn a new isolate with given role and entry point.
  Future<IsolateHandle> spawn<T>({
    required String role,
    required String name,
    required void Function(SendPort) entryPoint,
    Map<String, dynamic>? config,
    List<String>? capabilities,
    List<String>? subscribesTo,
  });

  /// Get all isolates with given role.
  List<IsolateHandle> getByRole(String role);

  /// Get isolate by ID.
  IsolateHandle? getById(String id);

  /// Stream of hub events.
  Stream<HubEvent> get events;

  /// Send message to specific isolate.
  void send(String isolateId, ProtocolMessage message);

  /// Broadcast message to all isolates with role.
  void broadcast(String role, ProtocolMessage message);
}

/// Implementation of IsolateHub.
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

  late final IsolateSpawner _spawner;
  late final HealthMonitor _healthMonitor;

  HubState _state = HubState.created;

  IsolateHubImpl({HubConfig? config})
    : config = config ?? const HubConfig(),
      _lifecycle = LifecycleManager(policy: config?.restartPolicy);

  @override
  HubState get state => _state;

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

    _state = HubState.running;
  }

  @override
  Future<void> stop({Duration? timeout}) async {
    if (_state != HubState.running) return;

    _state = HubState.stopping;

    // Stop health monitoring
    _healthMonitor.stop();

    // Cancel all pending restarts
    _lifecycle.cancelAll();

    // Shutdown all isolates
    final shutdownTimeout = timeout ?? const Duration(seconds: 10);
    final futures = <Future>[];

    for (final entry in _registry.all.toList()) {
      futures.add(_shutdownIsolate(entry, shutdownTimeout));
    }

    await Future.wait(futures);

    // Close any remaining exit ports
    for (final exitPort in _exitPorts.values) {
      exitPort.close();
    }
    _exitPorts.clear();
    _spawnConfigs.clear();

    // Clear registry
    _registry.clear();
    _lifecycle.clear();

    _state = HubState.stopped;

    // Close event stream
    await _eventController.close();
  }

  Future<void> _shutdownIsolate(IsolateEntry entry, Duration timeout) async {
    if (entry.state == IsolateState.stopped) return;

    entry.state = IsolateState.stopping;
    _lifecycle.removeTracker(entry.id);
    _spawnConfigs.remove(entry.id);
    _exitPorts.remove(entry.id)?.close();

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

  @override
  Future<IsolateHandle> spawn<T>({
    required String role,
    required String name,
    required void Function(SendPort) entryPoint,
    Map<String, dynamic>? config,
    List<String>? capabilities,
    List<String>? subscribesTo,
  }) async {
    if (_state != HubState.running) {
      throw StateError('Hub is not running');
    }

    final spawnConfig = SpawnConfig(
      role: role,
      name: name,
      entryPoint: entryPoint,
      config: config,
      capabilities: capabilities ?? const [],
      subscribesTo: subscribesTo ?? const [],
    );

    // Spawn isolate
    final entry = await _spawner.spawn(spawnConfig);
    _registry.register(entry);
    _spawnConfigs[entry.id] = spawnConfig;

    // Set up permanent listener for messages from this isolate
    _isolateSubscriptions[entry.id] = entry.broadcastStream.listen(
      _handleMessage,
    );

    final handle = _IsolateHandleImpl(entry, this);
    if (!_eventController.isClosed) {
      _eventController.add(IsolateSpawned(handle));
    }

    // Gather dependencies
    final dependencies = <String, List<PortInfo>>{};
    for (final depRole in entry.subscribesTo) {
      dependencies[depRole] = _registry.getPortsForRole(depRole);
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
      _registry.unregister(entry.id);
      rethrow;
    }

    // Monitor unexpected isolate exit
    final exitPort = ReceivePort();
    _exitPorts[entry.id] = exitPort;
    entry.isolate.addOnExitListener(exitPort.sendPort);
    exitPort.listen((_) {
      exitPort.close();
      _exitPorts.remove(entry.id);
      if (_state == HubState.running && entry.state == IsolateState.running) {
        _onIsolateFailed(entry.id);
      }
    });

    if (!_eventController.isClosed) {
      _eventController.add(IsolateReady(handle));
    }

    // Notify subscribers about new port
    _notifyPortUpdate(entry);

    return handle;
  }

  void _notifyPortUpdate(IsolateEntry newEntry) {
    final portInfo = PortInfo(
      id: newEntry.id,
      port: newEntry.sendPort,
      capabilities: newEntry.capabilities,
    );

    final update = PortUpdate(
      version: DateTime.now().microsecondsSinceEpoch,
      role: newEntry.role,
      added: [portInfo],
    );

    // Notify all isolates that subscribe to this role
    for (final entry in _registry.all) {
      if (entry.id == newEntry.id) continue;
      if (entry.subscribesTo.contains(newEntry.role)) {
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
    );

    for (final entry in _registry.all) {
      if (entry.id == removedEntry.id) continue;
      if (entry.subscribesTo.contains(removedEntry.role)) {
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

  @override
  List<IsolateHandle> getByRole(String role) {
    return _registry
        .getByRole(role)
        .map((e) => _IsolateHandleImpl(e, this))
        .toList();
  }

  @override
  IsolateHandle? getById(String id) {
    final entry = _registry.get(id);
    return entry != null ? _IsolateHandleImpl(entry, this) : null;
  }

  @override
  void send(String isolateId, ProtocolMessage message) {
    final entry = _registry.get(isolateId);
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

  void _handleMessage(dynamic message) {
    if (message is! Envelope) return;

    final payload = message.payload;

    switch (payload) {
      case Pong pong:
        _healthMonitor.handlePong(message.source.id, pong);
      case PortUpdateAck():
        // Port update acknowledged
        break;
      default:
        // Unknown message type
        break;
    }
  }

  void _onHealthChanged(String isolateId, bool healthy) {
    if (healthy) {
      _lifecycle.resetTracker(isolateId);
    }
    if (!_eventController.isClosed) {
      _eventController.add(HealthChanged(isolateId, healthy));
    }
  }

  void _onIsolateFailed(String isolateId) {
    final entry = _registry.get(isolateId);
    if (entry == null ||
        entry.state == IsolateState.failed ||
        entry.state == IsolateState.stopped) {
      return;
    }

    entry.state = IsolateState.failed;
    final handle = _IsolateHandleImpl(entry, this);
    if (!_eventController.isClosed) {
      _eventController.add(IsolateFailed(handle, 'Health check failed'));
    }

    // Attempt restart
    _attemptRestart(entry);
  }

  void _attemptRestart(IsolateEntry entry) {
    final spawnConfig = _spawnConfigs.remove(entry.id);
    final tracker = _lifecycle.getTracker(entry.id);

    // Clean up failed isolate resources
    entry.isolate.kill(priority: Isolate.immediate);
    entry.controlPort.close();
    _exitPorts.remove(entry.id)?.close();
    _healthMonitor.removePendingPing(entry.id);
    _isolateSubscriptions.remove(entry.id)?.cancel();
    _registry.unregister(entry.id);
    _notifyPortRemoved(entry);

    if (!tracker.canRetry || spawnConfig == null) {
      // Max retries exceeded or no spawn config available
      if (!_eventController.isClosed) {
        _eventController.add(IsolateStopped(entry.id));
      }
      return;
    }

    if (!_eventController.isClosed) {
      _eventController.add(IsolateRestarting(entry.id, tracker.attempts + 1));
      _eventController.add(IsolateStopped(entry.id));
    }

    tracker.scheduleRestart(() async {
      if (_state != HubState.running) return;

      try {
        final newHandle = await spawn(
          role: spawnConfig.role,
          name: spawnConfig.name,
          entryPoint: spawnConfig.entryPoint,
          config: spawnConfig.config,
          capabilities: spawnConfig.capabilities,
          subscribesTo: spawnConfig.subscribesTo,
        );
        _lifecycle.transferTracker(entry.id, newHandle.id);
        final newEntry = _registry.get(newHandle.id);
        if (newEntry != null) {
          newEntry.restartCount = entry.restartCount + 1;
        }
      } catch (_) {
        // Respawn failed; tracker retains attempt count
      }
    });
  }
}

/// Implementation of IsolateHandle.
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
  Future<void> kill({bool graceful = true}) async {
    if (graceful) {
      await _hub._shutdownIsolate(_entry, const Duration(seconds: 5));
    } else {
      if (_entry.state == IsolateState.stopped) return;
      _entry.state = IsolateState.stopped;
      _hub._lifecycle.removeTracker(id);
      _hub._spawnConfigs.remove(id);
      _hub._exitPorts.remove(id)?.close();
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
