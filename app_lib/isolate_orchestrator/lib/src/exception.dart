/// Base class for all isolate orchestrator exceptions.
abstract class IsolateOrchestratorException implements Exception {
  final String message;

  const IsolateOrchestratorException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// Exception thrown when spawning an isolate fails.
class SpawnFailedException extends IsolateOrchestratorException {
  final String role;

  SpawnFailedException(this.role, String message) : super(message);

  @override
  String toString() => 'SpawnFailedException($role): $message';
}

/// Exception thrown when no healthy worker is available.
class NoHealthyWorkerException extends IsolateOrchestratorException {
  NoHealthyWorkerException() : super('No healthy workers available');
}

/// Exception thrown when a task times out.
class TaskTimeoutException extends IsolateOrchestratorException {
  final String taskId;
  final int retryCount;

  TaskTimeoutException(this.taskId, this.retryCount)
    : super('Task $taskId timed out after $retryCount retries');
}

/// Exception thrown when a worker fails.
class WorkerException extends IsolateOrchestratorException {
  final String workerId;

  WorkerException(this.workerId, String message) : super(message);

  @override
  String toString() => 'WorkerException($workerId): $message';
}

/// Exception thrown when hub is in invalid state.
class HubStateException extends IsolateOrchestratorException {
  HubStateException(super.message);
}

/// Exception thrown when pool is in invalid state.
class PoolStateException extends IsolateOrchestratorException {
  PoolStateException(super.message);
}

/// Exception thrown when initialization fails.
class InitializationException extends IsolateOrchestratorException {
  final String isolateId;

  InitializationException(this.isolateId, String reason)
    : super('Isolate "$isolateId" failed to initialize: $reason');
}

/// Exception thrown when message delivery fails.
class MessageDeliveryException extends IsolateOrchestratorException {
  final String targetId;

  MessageDeliveryException(this.targetId, String reason)
    : super('Failed to deliver message to $targetId: $reason');
}

/// Exception thrown when a task is cancelled.
class TaskCancelledException extends IsolateOrchestratorException {
  final String taskId;

  TaskCancelledException(this.taskId) : super('Task $taskId was cancelled');
}

/// Exception thrown when a task fails during worker execution.
class TaskException extends IsolateOrchestratorException {
  final String code;
  final dynamic details;
  final String? stackTrace;

  TaskException(this.code, super.message, [this.details, this.stackTrace]);

  @override
  String toString() => 'TaskException($code): $message';
}

/// Exception thrown when spawn times out.
class SpawnTimeoutException extends IsolateOrchestratorException {
  final String name;
  final Duration timeout;

  SpawnTimeoutException(this.name, this.timeout)
    : super('Isolate "$name" failed to register within ${timeout.inSeconds}s');
}
