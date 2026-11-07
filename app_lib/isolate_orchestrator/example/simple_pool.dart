import 'dart:isolate';

import 'package:isolate_orchestrator/isolate_orchestrator.dart';

/// Example data type for computation tasks.
class ComputeData {
  final int input;
  final int? result;

  ComputeData({required this.input, this.result});

  ComputeData withResult(int result) =>
      ComputeData(input: input, result: result);

  @override
  String toString() => 'ComputeData(input: $input, result: $result)';
}

/// Example worker implementation.
class ComputeWorker extends Worker<ComputeData> with WorkerMetricsMixin {
  final WorkerContext _context;

  @override
  WorkerContext get context => _context;

  ComputeWorker(WorkerContext context) : _context = context;

  @override
  Future<void> onInit(Map<String, dynamic> config) async {
    initMetrics();
    context.info('ComputeWorker initialized');
  }

  @override
  Future<ComputeData> onTask(
    ComputeData data, {
    String? taskType,
    Map<String, dynamic>? metadata,
  }) async {
    final startTime = DateTime.now();

    // Simulate heavy computation
    final result = _expensiveComputation(data.input);

    recordSuccess(DateTime.now().difference(startTime));
    return data.withResult(result);
  }

  int _expensiveComputation(int value) {
    // Simulate work
    var result = value;
    for (var i = 0; i < 1000; i++) {
      result = (result * 31 + i) % 1000000;
    }
    return result;
  }

  @override
  Future<void> onShutdown() async {
    context.info('ComputeWorker shutting down');
  }
}

/// Entry point for worker isolate.
void workerEntryPoint(SendPort hubPort) {
  runWorker<ComputeData>(hubPort, (context) => ComputeWorker(context));
}

void main() async {
  print('Starting isolate orchestrator example...');

  // Create hub
  final hub = IsolateHub(
    config: const HubConfig(
      healthCheckInterval: Duration(seconds: 5),
      healthCheckTimeout: Duration(seconds: 2),
    ),
  );
  await hub.start();
  print('Hub started');

  // Create pool
  final pool = WorkerPool<ComputeData>(
    hub: hub,
    config: const WorkerPoolConfig(
      minWorkers: 4,
      maxWorkers: 8,
      requestTimeout: Duration(seconds: 10),
    ),
    workerEntryPoint: workerEntryPoint,
  );

  await pool.start();
  print('Pool started with ${pool.workers.length} workers');

  // Submit tasks
  print('\nSubmitting 20 tasks...');
  final futures = <Future<ComputeData>>[];
  for (var i = 0; i < 20; i++) {
    futures.add(pool.submit(ComputeData(input: i)));
  }

  final results = await Future.wait(futures);
  print('All tasks completed!');
  print('Results:');
  for (final result in results) {
    print('  ${result.input} -> ${result.result}');
  }

  // Print pool status
  final status = pool.status;
  print('\nPool Status:');
  print('  Total workers: ${status.totalWorkers}');
  print('  Healthy workers: ${status.healthyWorkers}');
  print('  Processed requests: ${status.processedRequests}');
  print('  Failed requests: ${status.failedRequests}');

  // Cleanup
  print('\nShutting down...');
  await pool.stop();
  await hub.stop();
  print('Done!');
}
