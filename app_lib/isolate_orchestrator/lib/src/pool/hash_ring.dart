import 'dart:convert';
import 'dart:isolate';

import 'router.dart';

/// Consistent hash ring implementation.
class HashRing {
  final int virtualNodesPerWorker;
  final List<_RingNode> _ring = [];
  final Map<String, _WorkerState> _workers = {};

  HashRing({this.virtualNodesPerWorker = 150});

  /// Add worker to ring.
  void addWorker(String id, SendPort port) {
    _workers[id] = _WorkerState(id: id, port: port);

    for (var i = 0; i < virtualNodesPerWorker; i++) {
      final virtualKey = '$id-v$i';
      final hash = fnv1a(virtualKey);
      _insertSorted(_RingNode(hash: hash, workerId: id));
    }
  }

  /// Remove worker from ring.
  void removeWorker(String id) {
    _workers.remove(id);
    _ring.removeWhere((node) => node.workerId == id);
  }

  /// Update worker health status.
  void setHealthy(String id, bool healthy) {
    final worker = _workers[id];
    if (worker != null) {
      worker.healthy = healthy;
    }
  }

  /// Update worker metrics.
  void updateMetrics(String id, {int? pendingCount, int? avgLatencyUs}) {
    final worker = _workers[id];
    if (worker != null) {
      if (pendingCount != null) worker.pendingCount = pendingCount;
      if (avgLatencyUs != null) worker.avgLatencyUs = avgLatencyUs;
    }
  }

  /// Find worker for key.
  WorkerPort? find(String key, {Set<String>? exclude}) {
    if (_ring.isEmpty) return null;

    final hash = fnv1a(key);
    final startIndex = _binarySearchInsertPoint(hash);

    // Walk ring clockwise
    for (var i = 0; i < _ring.length; i++) {
      final index = (startIndex + i) % _ring.length;
      final workerId = _ring[index].workerId;

      if (exclude?.contains(workerId) ?? false) continue;

      final worker = _workers[workerId];
      if (worker != null && worker.healthy) {
        return WorkerPort(
          id: worker.id,
          port: worker.port,
          healthy: worker.healthy,
          pendingCount: worker.pendingCount,
          avgLatencyUs: worker.avgLatencyUs,
        );
      }
    }

    // Return any worker as last resort
    for (final worker in _workers.values) {
      if (exclude?.contains(worker.id) ?? false) continue;
      return WorkerPort(
        id: worker.id,
        port: worker.port,
        healthy: worker.healthy,
        pendingCount: worker.pendingCount,
        avgLatencyUs: worker.avgLatencyUs,
      );
    }

    return null;
  }

  /// Get all workers.
  List<WorkerPort> get allWorkers {
    return _workers.values
        .map(
          (w) => WorkerPort(
            id: w.id,
            port: w.port,
            healthy: w.healthy,
            pendingCount: w.pendingCount,
            avgLatencyUs: w.avgLatencyUs,
          ),
        )
        .toList();
  }

  /// Get count of workers.
  int get workerCount => _workers.length;

  /// Check if empty.
  bool get isEmpty => _workers.isEmpty;

  /// Clear all workers from the ring.
  void clear() {
    _workers.clear();
    _ring.clear();
  }

  void _insertSorted(_RingNode node) {
    final index = _binarySearchInsertPoint(node.hash);
    _ring.insert(index, node);
  }

  int _binarySearchInsertPoint(int hash) {
    var low = 0;
    var high = _ring.length;

    while (low < high) {
      final mid = (low + high) ~/ 2;
      if (_ring[mid].hash < hash) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }

    return low;
  }

  /// FNV-1a hash function.
  static int fnv1a(String data) {
    var hash = 2166136261;
    for (final byte in utf8.encode(data)) {
      hash ^= byte;
      hash = (hash * 16777619) & 0xFFFFFFFF;
    }
    return hash;
  }
}

class _RingNode {
  final int hash;
  final String workerId;

  _RingNode({required this.hash, required this.workerId});
}

class _WorkerState {
  final String id;
  final SendPort port;
  bool healthy = true;
  int pendingCount = 0;
  int avgLatencyUs = 0;

  _WorkerState({required this.id, required this.port});
}
