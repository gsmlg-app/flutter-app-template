import 'dart:isolate';

import '../health/metrics.dart';
import '../message/protocol.dart';

/// Isolate states.
enum IsolateState { created, starting, running, stopping, stopped, failed }

/// Internal registry entry for an isolate.
class IsolateEntry {
  final String id;
  final String name;
  final String role;
  final Isolate isolate;
  final SendPort sendPort;
  final ReceivePort controlPort;
  final Stream<dynamic> broadcastStream;
  final List<String> capabilities;
  final List<String> subscribesTo;

  IsolateState state = IsolateState.created;
  IsolateMetrics? lastMetrics;
  DateTime? lastHealthCheck;
  int restartCount = 0;
  int consecutiveFailures = 0;
  int consecutiveSuccesses = 0;
  bool? _healthy;

  IsolateEntry({
    required this.id,
    required this.name,
    required this.role,
    required this.isolate,
    required this.sendPort,
    required this.controlPort,
    required this.broadcastStream,
    this.capabilities = const [],
    this.subscribesTo = const [],
  });

  /// Check if isolate is healthy based on consecutive successes/failures
  /// and threshold state managed by [HealthMonitor].
  bool get isHealthy =>
      state == IsolateState.running && (_healthy ?? (consecutiveFailures == 0));

  /// Explicitly set the threshold-evaluated health status.
  set isHealthy(bool value) => _healthy = value;

  /// Update health check result.
  void recordHealthCheck(bool success) {
    lastHealthCheck = DateTime.now();
    if (success) {
      consecutiveSuccesses++;
      consecutiveFailures = 0;
    } else {
      consecutiveFailures++;
      consecutiveSuccesses = 0;
    }
  }
}

/// Registry of all managed isolates.
class IsolateRegistry {
  final _isolates = <String, IsolateEntry>{};
  final _byRole = <String, Set<String>>{};

  /// Register new isolate.
  void register(IsolateEntry entry) {
    _isolates[entry.id] = entry;
    _byRole.putIfAbsent(entry.role, () => {}).add(entry.id);
  }

  /// Unregister isolate.
  void unregister(String id) {
    final entry = _isolates.remove(id);
    if (entry != null) {
      _byRole[entry.role]?.remove(id);
    }
  }

  /// Get by ID.
  IsolateEntry? get(String id) => _isolates[id];

  /// Get all by role.
  List<IsolateEntry> getByRole(String role) {
    return _byRole[role]?.map((id) => _isolates[id]!).toList() ?? [];
  }

  /// Get all entries.
  Iterable<IsolateEntry> get all => _isolates.values;

  /// Get count of isolates.
  int get count => _isolates.length;

  /// Get count of isolates by role.
  int countByRole(String role) => _byRole[role]?.length ?? 0;

  /// Get all ports for a role.
  List<PortInfo> getPortsForRole(String role) {
    return getByRole(role)
        .where((e) => e.state == IsolateState.running)
        .map(
          (e) => PortInfo(
            id: e.id,
            port: e.sendPort,
            capabilities: e.capabilities,
          ),
        )
        .toList();
  }

  /// Get all running isolates.
  List<IsolateEntry> get running =>
      _isolates.values.where((e) => e.state == IsolateState.running).toList();

  /// Check if isolate exists.
  bool contains(String id) => _isolates.containsKey(id);

  /// Clear all entries.
  void clear() {
    _isolates.clear();
    _byRole.clear();
  }
}
