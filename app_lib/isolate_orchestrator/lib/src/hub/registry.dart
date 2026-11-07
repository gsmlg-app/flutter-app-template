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
  final String path;
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
  bool normalExit = false;
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
    String? path,
  }) : path = path ?? '/$name';

  /// Convert this entry into a [PortInfo] descriptor.
  PortInfo toPortInfo() => PortInfo(
    id: id,
    port: sendPort,
    capabilities: capabilities,
    name: name,
    path: path,
    role: role,
  );

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

/// Multi-index registry of all managed isolates.
///
/// Indexes isolates by:
/// - `id` (unique instance ID, e.g., `dns-1`)
/// - `name` (logical service name, e.g., `dns`)
/// - `path` (hierarchical tree path, e.g., `/network/dns`)
/// - `role` (functional role, e.g., `resolver`)
/// - `capability` (declared capabilities, e.g., `doh`)
class IsolateRegistry {
  final _isolates = <String, IsolateEntry>{};
  final _byName = <String, String>{};
  final _byPath = <String, String>{};
  final _byRole = <String, Set<String>>{};
  final _byCapability = <String, Set<String>>{};

  /// Register new isolate.
  void register(IsolateEntry entry) {
    _isolates[entry.id] = entry;
    _byName[entry.name] = entry.id;
    _byPath[entry.path] = entry.id;
    _byRole.putIfAbsent(entry.role, () => {}).add(entry.id);
    for (final cap in entry.capabilities) {
      _byCapability.putIfAbsent(cap, () => {}).add(entry.id);
    }
  }

  /// Unregister isolate.
  void unregister(String id) {
    final entry = _isolates.remove(id);
    if (entry != null) {
      if (_byName[entry.name] == id) {
        _byName.remove(entry.name);
      }
      if (_byPath[entry.path] == id) {
        _byPath.remove(entry.path);
      }
      _byRole[entry.role]?.remove(id);
      for (final cap in entry.capabilities) {
        _byCapability[cap]?.remove(id);
      }
    }
  }

  /// Get by ID.
  IsolateEntry? get(String id) => _isolates[id];

  /// Get by logical name.
  IsolateEntry? getByName(String name) {
    final id = _byName[name];
    return id != null ? _isolates[id] : null;
  }

  /// Get by hierarchical tree path.
  IsolateEntry? getByPath(String path) {
    final normalized = path.startsWith('/') ? path : '/$path';
    final id = _byPath[normalized];
    return id != null ? _isolates[id] : null;
  }

  /// Resolve a target string by checking `id`, `path`, `name`, `role`, or `capability`.
  IsolateEntry? resolve(String target) {
    // 1. Exact ID match
    final byId = _isolates[target];
    if (byId != null) return byId;

    // 2. Path match (if starts with '/' or matches normalized path)
    if (target.startsWith('/')) {
      final byPath = getByPath(target);
      if (byPath != null) return byPath;
    }

    // 3. Name match
    final byName = getByName(target);
    if (byName != null) return byName;

    // 4. Normalized path match (e.g., 'network/dns' -> '/network/dns')
    final byNormalizedPath = getByPath(target);
    if (byNormalizedPath != null) return byNormalizedPath;

    // 5. Role match (prefer healthy running isolate)
    final roleEntries = getByRole(target);
    if (roleEntries.isNotEmpty) {
      return roleEntries.firstWhere(
        (e) => e.isHealthy,
        orElse: () => roleEntries.firstWhere(
          (e) => e.state == IsolateState.running,
          orElse: () => roleEntries.first,
        ),
      );
    }

    // 6. Capability match (prefer healthy running isolate)
    final capEntries = getByCapability(target);
    if (capEntries.isNotEmpty) {
      return capEntries.firstWhere(
        (e) => e.isHealthy,
        orElse: () => capEntries.firstWhere(
          (e) => e.state == IsolateState.running,
          orElse: () => capEntries.first,
        ),
      );
    }

    return null;
  }

  /// Resolve all matching entries for a target (`id`, `path`, `name`, `role`, or `capability`).
  List<IsolateEntry> resolveAll(String target) {
    final single =
        _isolates[target] ??
        (target.startsWith('/') ? getByPath(target) : null) ??
        getByName(target) ??
        getByPath(target);
    if (single != null) return [single];

    final byRole = getByRole(target);
    if (byRole.isNotEmpty) return byRole;

    final byCap = getByCapability(target);
    if (byCap.isNotEmpty) return byCap;

    return const [];
  }

  /// Get all by role.
  List<IsolateEntry> getByRole(String role) {
    return _byRole[role]
            ?.map((id) => _isolates[id])
            .whereType<IsolateEntry>()
            .toList() ??
        [];
  }

  /// Get all by capability.
  List<IsolateEntry> getByCapability(String capability) {
    return _byCapability[capability]
            ?.map((id) => _isolates[id])
            .whereType<IsolateEntry>()
            .toList() ??
        [];
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
        .map((e) => e.toPortInfo())
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
    _byName.clear();
    _byPath.clear();
    _byRole.clear();
    _byCapability.clear();
  }
}
