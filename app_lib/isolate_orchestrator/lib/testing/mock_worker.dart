import 'dart:async';

import '../src/health/metrics.dart';
import '../src/worker/context.dart';
import '../src/worker/worker.dart';

/// Mock worker for testing.
///
/// Allows customizing task handling behavior for tests.
class MockWorker<TData> extends Worker<TData> {
  final Future<TData> Function(TData, String?, Map<String, dynamic>?) handler;
  final Duration? delay;
  final WorkerContext _context;

  int _processedCount = 0;
  int _errorCount = 0;
  DateTime? _startTime;

  MockWorker({
    required WorkerContext context,
    required this.handler,
    this.delay,
  }) : _context = context;

  @override
  WorkerContext get context => _context;

  @override
  Future<void> onInit(Map<String, dynamic> config) async {
    _startTime = DateTime.now();
  }

  @override
  Future<TData> onTask(
    TData data, {
    String? taskType,
    Map<String, dynamic>? metadata,
  }) async {
    if (delay != null) {
      await Future.delayed(delay!);
    }
    try {
      final result = await handler(data, taskType, metadata);
      _processedCount++;
      return result;
    } catch (e) {
      _errorCount++;
      rethrow;
    }
  }

  @override
  IsolateMetrics onHealthCheck() {
    return IsolateMetrics(
      uptimeMs: _startTime != null
          ? DateTime.now().difference(_startTime!).inMilliseconds
          : 0,
      processedCount: _processedCount,
      pendingCount: 0,
      errorCount: _errorCount,
      avgLatencyUs: 0,
    );
  }

  @override
  Future<void> onShutdown() async {
    // Cleanup
  }
}

/// Factory for creating mock workers.
class MockWorkerFactory<TData> {
  final Future<TData> Function(TData, String?, Map<String, dynamic>?) handler;
  final Duration? delay;

  MockWorkerFactory({required this.handler, this.delay});

  MockWorker<TData> create(WorkerContext context) {
    return MockWorker<TData>(context: context, handler: handler, delay: delay);
  }
}

/// Simple worker that echoes input data.
class EchoWorker<TData> extends Worker<TData> {
  late WorkerContext _context;
  DateTime? _startTime;
  int _count = 0;

  @override
  WorkerContext get context => _context;

  @override
  Future<void> onInit(Map<String, dynamic> config) async {
    _startTime = DateTime.now();
  }

  void setContext(WorkerContext context) {
    _context = context;
  }

  @override
  Future<TData> onTask(
    TData data, {
    String? taskType,
    Map<String, dynamic>? metadata,
  }) async {
    _count++;
    return data;
  }

  @override
  IsolateMetrics onHealthCheck() {
    return IsolateMetrics(
      uptimeMs: _startTime != null
          ? DateTime.now().difference(_startTime!).inMilliseconds
          : 0,
      processedCount: _count,
      pendingCount: 0,
      errorCount: 0,
      avgLatencyUs: 0,
    );
  }

  @override
  Future<void> onShutdown() async {}
}

/// Worker that fails after N successful tasks.
class FailingWorker<TData> extends Worker<TData> {
  final int failAfter;
  final TData Function(TData) transform;

  late WorkerContext _context;
  DateTime? _startTime;
  int _count = 0;
  int _errors = 0;

  FailingWorker({required this.failAfter, required this.transform});

  @override
  WorkerContext get context => _context;

  void setContext(WorkerContext context) {
    _context = context;
  }

  @override
  Future<void> onInit(Map<String, dynamic> config) async {
    _startTime = DateTime.now();
  }

  @override
  Future<TData> onTask(
    TData data, {
    String? taskType,
    Map<String, dynamic>? metadata,
  }) async {
    _count++;
    if (_count > failAfter) {
      _errors++;
      throw StateError('Worker failed after $failAfter tasks');
    }
    return transform(data);
  }

  @override
  IsolateMetrics onHealthCheck() {
    return IsolateMetrics(
      uptimeMs: _startTime != null
          ? DateTime.now().difference(_startTime!).inMilliseconds
          : 0,
      processedCount: _count,
      pendingCount: 0,
      errorCount: _errors,
      avgLatencyUs: 0,
    );
  }

  @override
  Future<void> onShutdown() async {}
}

/// Worker with configurable latency.
class SlowWorker<TData> extends Worker<TData> {
  final Duration latency;
  final TData Function(TData) transform;

  late WorkerContext _context;
  DateTime? _startTime;
  int _count = 0;

  SlowWorker({required this.latency, required this.transform});

  @override
  WorkerContext get context => _context;

  void setContext(WorkerContext context) {
    _context = context;
  }

  @override
  Future<void> onInit(Map<String, dynamic> config) async {
    _startTime = DateTime.now();
  }

  @override
  Future<TData> onTask(
    TData data, {
    String? taskType,
    Map<String, dynamic>? metadata,
  }) async {
    await Future.delayed(latency);
    _count++;
    return transform(data);
  }

  @override
  IsolateMetrics onHealthCheck() {
    return IsolateMetrics(
      uptimeMs: _startTime != null
          ? DateTime.now().difference(_startTime!).inMilliseconds
          : 0,
      processedCount: _count,
      pendingCount: 0,
      errorCount: 0,
      avgLatencyUs: latency.inMicroseconds,
    );
  }

  @override
  Future<void> onShutdown() async {}
}
