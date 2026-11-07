import 'dart:async';

import '../hub/hub.dart';
import '../hub/registry.dart';
import '../message/address.dart';
import '../message/envelope.dart';
import '../message/id_generator.dart';
import '../message/protocol.dart';

/// Monitors health of all managed isolates.
class HealthMonitor {
  final IsolateRegistry registry;
  final HubConfig config;
  final MessageIdGenerator idGenerator;
  final void Function(String isolateId, bool healthy) onHealthChanged;
  final void Function(String isolateId) onIsolateFailed;

  Timer? _timer;
  int _pingSeq = 0;
  final Map<String, _PendingPing> _pendingPings = {};

  HealthMonitor({
    required this.registry,
    required this.config,
    required this.idGenerator,
    required this.onHealthChanged,
    required this.onIsolateFailed,
  });

  /// Start health monitoring.
  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(config.healthCheckInterval, (_) => _checkAll());
  }

  /// Stop health monitoring.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _pendingPings.clear();
  }

  /// Remove pending ping for an isolate.
  ///
  /// Call this when an isolate is unregistered to prevent memory leaks.
  void removePendingPing(String isolateId) {
    _pendingPings.remove(isolateId);
  }

  /// Check health of all running isolates.
  void _checkAll() {
    for (final entry in registry.running) {
      _checkIsolate(entry);
    }
  }

  void _checkIsolate(IsolateEntry entry) {
    // Check for pending ping timeout
    final pending = _pendingPings[entry.id];
    if (pending != null) {
      final elapsed = DateTime.now().difference(pending.sentAt);
      if (elapsed > config.healthCheckTimeout) {
        // Ping timed out
        _pendingPings.remove(entry.id);
        _handleHealthCheckFailed(entry);
        return;
      }
    }

    // Send new ping
    _pingSeq++;
    final ping = Ping(seq: _pingSeq);
    final envelope = Envelope.create(
      id: idGenerator.next(),
      source: IsolateAddress.hub,
      target: IsolateAddress.of(entry.role, entry.id),
      payload: ping,
    );

    _pendingPings[entry.id] = _PendingPing(
      seq: _pingSeq,
      sentAt: DateTime.now(),
    );

    entry.sendPort.send(envelope);
  }

  /// Handle pong response from isolate.
  void handlePong(String isolateId, Pong pong) {
    final pending = _pendingPings.remove(isolateId);
    if (pending == null) return;

    final entry = registry.get(isolateId);
    if (entry == null) return;

    // Update metrics
    entry.lastMetrics = pong.metrics;
    entry.lastHealthCheck = DateTime.now();

    // Record success
    final wasHealthy = entry.isHealthy;
    entry.recordHealthCheck(true);

    // Check if health status changed
    if (!wasHealthy && entry.consecutiveSuccesses >= config.healthyThreshold) {
      onHealthChanged(isolateId, true);
    }
  }

  void _handleHealthCheckFailed(IsolateEntry entry) {
    final wasHealthy = entry.isHealthy;
    entry.recordHealthCheck(false);

    if (wasHealthy && entry.consecutiveFailures >= config.unhealthyThreshold) {
      onHealthChanged(entry.id, false);
      onIsolateFailed(entry.id);
    }
  }
}

class _PendingPing {
  final int seq;
  final DateTime sentAt;

  _PendingPing({required this.seq, required this.sentAt});
}
