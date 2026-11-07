import 'dart:isolate';

import '../message/protocol.dart';
import 'hash_ring.dart';

/// Worker port with metadata.
class WorkerPort {
  final String id;
  final SendPort port;
  final bool healthy;
  final int pendingCount;
  final int avgLatencyUs;

  const WorkerPort({
    required this.id,
    required this.port,
    required this.healthy,
    required this.pendingCount,
    required this.avgLatencyUs,
  });
}

/// Routes requests to workers.
abstract class Router<T> {
  /// Select worker for request.
  /// Returns null if no suitable worker available.
  WorkerPort? select(T request, {Set<String>? exclude});

  /// Update available workers.
  void updateWorkers(List<PortInfo> workers);

  /// Record successful response.
  void recordSuccess(String workerId, Duration latency);

  /// Record timeout/failure.
  void recordFailure(String workerId);

  /// Get all workers.
  List<WorkerPort> get workers;
}

/// Round-robin router (default).
class RoundRobinRouter<T> implements Router<T> {
  final List<_WorkerEntry> _workers = [];
  int _currentIndex = 0;

  @override
  WorkerPort? select(T request, {Set<String>? exclude}) {
    if (_workers.isEmpty) return null;

    final healthyWorkers = _workers
        .where((w) => w.healthy && !(exclude?.contains(w.id) ?? false))
        .toList();

    if (healthyWorkers.isEmpty) {
      // Fall back to any worker
      final available = _workers
          .where((w) => !(exclude?.contains(w.id) ?? false))
          .toList();
      if (available.isEmpty) return null;
      return available.first.toWorkerPort();
    }

    _currentIndex = (_currentIndex + 1) % healthyWorkers.length;
    return healthyWorkers[_currentIndex].toWorkerPort();
  }

  @override
  void updateWorkers(List<PortInfo> workers) {
    // Remove workers not in new list
    _workers.removeWhere((w) => !workers.any((p) => p.id == w.id));

    // Add new workers
    for (final port in workers) {
      if (!_workers.any((w) => w.id == port.id)) {
        _workers.add(_WorkerEntry(id: port.id, port: port.port));
      }
    }
  }

  @override
  void recordSuccess(String workerId, Duration latency) {
    final worker = _workers.firstWhere(
      (w) => w.id == workerId,
      orElse: () => throw StateError('Worker not found'),
    );
    worker.recordSuccess(latency);
  }

  @override
  void recordFailure(String workerId) {
    final worker = _workers.firstWhere(
      (w) => w.id == workerId,
      orElse: () => throw StateError('Worker not found'),
    );
    worker.recordFailure();
  }

  @override
  List<WorkerPort> get workers =>
      _workers.map((w) => w.toWorkerPort()).toList();
}

/// Consistent hash router.
class ConsistentHashRouter<T> implements Router<T> {
  final int virtualNodesPerWorker;
  final String Function(T) keyExtractor;
  final HashRing _ring;

  ConsistentHashRouter({
    this.virtualNodesPerWorker = 150,
    required this.keyExtractor,
  }) : _ring = HashRing(virtualNodesPerWorker: virtualNodesPerWorker);

  @override
  WorkerPort? select(T request, {Set<String>? exclude}) {
    final key = keyExtractor(request);
    return _ring.find(key, exclude: exclude);
  }

  @override
  void updateWorkers(List<PortInfo> workers) {
    // Get current worker IDs
    final currentIds = _ring.allWorkers.map((w) => w.id).toSet();
    final newIds = workers.map((w) => w.id).toSet();

    // Remove workers not in new list
    for (final id in currentIds.difference(newIds)) {
      _ring.removeWorker(id);
    }

    // Add new workers
    for (final port in workers) {
      if (!currentIds.contains(port.id)) {
        _ring.addWorker(port.id, port.port);
      }
    }
  }

  @override
  void recordSuccess(String workerId, Duration latency) {
    _ring.setHealthy(workerId, true);
    _ring.updateMetrics(workerId, avgLatencyUs: latency.inMicroseconds);
  }

  @override
  void recordFailure(String workerId) {
    _ring.setHealthy(workerId, false);
  }

  @override
  List<WorkerPort> get workers => _ring.allWorkers;
}

/// Least-connections router.
class LeastConnectionsRouter<T> implements Router<T> {
  final List<_WorkerEntry> _workers = [];

  @override
  WorkerPort? select(T request, {Set<String>? exclude}) {
    if (_workers.isEmpty) return null;

    final healthyWorkers = _workers
        .where((w) => w.healthy && !(exclude?.contains(w.id) ?? false))
        .toList();

    if (healthyWorkers.isEmpty) {
      // Fall back to any worker
      final available = _workers
          .where((w) => !(exclude?.contains(w.id) ?? false))
          .toList();
      if (available.isEmpty) return null;
      return available.first.toWorkerPort();
    }

    // Sort by pending count
    healthyWorkers.sort((a, b) => a.pendingCount.compareTo(b.pendingCount));
    final selected = healthyWorkers.first;
    selected.pendingCount++;
    return selected.toWorkerPort();
  }

  @override
  void updateWorkers(List<PortInfo> workers) {
    // Remove workers not in new list
    _workers.removeWhere((w) => !workers.any((p) => p.id == w.id));

    // Add new workers
    for (final port in workers) {
      if (!_workers.any((w) => w.id == port.id)) {
        _workers.add(_WorkerEntry(id: port.id, port: port.port));
      }
    }
  }

  @override
  void recordSuccess(String workerId, Duration latency) {
    final worker = _workers.firstWhere(
      (w) => w.id == workerId,
      orElse: () => throw StateError('Worker not found'),
    );
    worker.pendingCount--;
    worker.recordSuccess(latency);
  }

  @override
  void recordFailure(String workerId) {
    final worker = _workers.firstWhere(
      (w) => w.id == workerId,
      orElse: () => throw StateError('Worker not found'),
    );
    worker.pendingCount--;
    worker.recordFailure();
  }

  @override
  List<WorkerPort> get workers =>
      _workers.map((w) => w.toWorkerPort()).toList();
}

/// Internal worker entry for tracking.
class _WorkerEntry {
  final String id;
  final SendPort port;
  bool healthy = true;
  int pendingCount = 0;
  int totalLatencyUs = 0;
  int successCount = 0;

  _WorkerEntry({required this.id, required this.port});

  int get avgLatencyUs => successCount > 0 ? totalLatencyUs ~/ successCount : 0;

  void recordSuccess(Duration latency) {
    healthy = true;
    totalLatencyUs += latency.inMicroseconds;
    successCount++;
  }

  void recordFailure() {
    healthy = false;
  }

  WorkerPort toWorkerPort() => WorkerPort(
    id: id,
    port: port,
    healthy: healthy,
    pendingCount: pendingCount,
    avgLatencyUs: avgLatencyUs,
  );
}
