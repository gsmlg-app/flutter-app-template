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

  /// Update health status of a worker directly (e.g. from health monitor events).
  void setWorkerHealth(String workerId, bool healthy) {}

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
      _currentIndex = (_currentIndex + 1) % available.length;
      return available[_currentIndex].toWorkerPort();
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
    for (final worker in _workers) {
      if (worker.id == workerId) {
        worker.recordSuccess(latency);
        break;
      }
    }
  }

  @override
  void recordFailure(String workerId) {
    for (final worker in _workers) {
      if (worker.id == workerId) {
        worker.recordFailure();
        break;
      }
    }
  }

  @override
  void setWorkerHealth(String workerId, bool healthy) {
    for (final worker in _workers) {
      if (worker.id == workerId) {
        worker.healthy = healthy;
        break;
      }
    }
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
  void setWorkerHealth(String workerId, bool healthy) {
    _ring.setHealthy(workerId, healthy);
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
      // Fall back to any worker with fewest pending connections
      final available = _workers
          .where((w) => !(exclude?.contains(w.id) ?? false))
          .toList();
      if (available.isEmpty) return null;
      available.sort((a, b) => a.pendingCount.compareTo(b.pendingCount));
      final selected = available.first;
      selected.pendingCount++;
      return selected.toWorkerPort();
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
    for (final worker in _workers) {
      if (worker.id == workerId) {
        if (worker.pendingCount > 0) {
          worker.pendingCount--;
        }
        worker.recordSuccess(latency);
        break;
      }
    }
  }

  @override
  void recordFailure(String workerId) {
    for (final worker in _workers) {
      if (worker.id == workerId) {
        if (worker.pendingCount > 0) {
          worker.pendingCount--;
        }
        worker.recordFailure();
        break;
      }
    }
  }

  @override
  void setWorkerHealth(String workerId, bool healthy) {
    for (final worker in _workers) {
      if (worker.id == workerId) {
        worker.healthy = healthy;
        break;
      }
    }
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
