import 'dart:isolate';

import '../health/metrics.dart';

/// Base class for all protocol messages.
sealed class ProtocolMessage {}

// ═══════════════════════════════════════════════════════════════════
// Lifecycle Messages
// ═══════════════════════════════════════════════════════════════════

/// Child → Hub: Registration message.
class Register extends ProtocolMessage {
  final String name;
  final String role;
  final SendPort port;
  final List<String> capabilities;
  final List<String> subscribesTo;

  Register({
    required this.name,
    required this.role,
    required this.port,
    this.capabilities = const [],
    this.subscribesTo = const [],
  });
}

/// Hub → Child: Initialization message.
class Init extends ProtocolMessage {
  final Map<String, dynamic> config;
  final Map<String, List<PortInfo>> dependencies;

  Init({this.config = const {}, this.dependencies = const {}});
}

/// Port information for dependency injection and address resolution.
class PortInfo {
  final String id;
  final SendPort port;
  final List<String> capabilities;
  final String? name;
  final String? path;
  final String? role;

  const PortInfo({
    required this.id,
    required this.port,
    this.capabilities = const [],
    this.name,
    this.path,
    this.role,
  });
}

/// Child → Hub: Ready notification.
class Ready extends ProtocolMessage {
  final bool success;
  final String? error;
  final Map<String, dynamic>? metadata;

  Ready({required this.success, this.error, this.metadata});

  factory Ready.ok([Map<String, dynamic>? metadata]) =>
      Ready(success: true, metadata: metadata);

  factory Ready.failed(String error) => Ready(success: false, error: error);
}

/// Bidirectional: Shutdown command.
class Shutdown extends ProtocolMessage {
  final bool graceful;
  final int timeoutMs;
  final String? reason;

  Shutdown({this.graceful = true, this.timeoutMs = 5000, this.reason});
}

/// Child → Hub: Shutdown acknowledgment.
class ShutdownAck extends ProtocolMessage {
  final int pendingTasks;
  final bool flushed;

  ShutdownAck({required this.pendingTasks, required this.flushed});
}

// ═══════════════════════════════════════════════════════════════════
// Health Messages
// ═══════════════════════════════════════════════════════════════════

/// Hub → Child: Health check ping.
class Ping extends ProtocolMessage {
  final int seq;

  Ping({required this.seq});
}

/// Child → Hub: Health check response.
class Pong extends ProtocolMessage {
  final int seq;
  final IsolateMetrics metrics;

  Pong({required this.seq, required this.metrics});
}

// ═══════════════════════════════════════════════════════════════════
// Port Update Messages
// ═══════════════════════════════════════════════════════════════════

/// Hub → Subscribers: Port change notification.
class PortUpdate extends ProtocolMessage {
  /// Monotonic version for ordering.
  final int version;

  /// Which role's ports changed.
  final String role;

  /// Added port infos.
  final List<PortInfo> added;

  /// Removed isolate IDs.
  final List<String> removed;

  /// Removed isolate names.
  final List<String> removedNames;

  /// Removed isolate tree paths.
  final List<String> removedPaths;

  PortUpdate({
    required this.version,
    required this.role,
    this.added = const [],
    this.removed = const [],
    this.removedNames = const [],
    this.removedPaths = const [],
  });
}

/// Subscriber → Hub: Update acknowledgment.
class PortUpdateAck extends ProtocolMessage {
  final int version;

  PortUpdateAck({required this.version});
}

/// Child → Hub: Dynamic address resolution request.
class ResolveAddress extends ProtocolMessage {
  /// Target path, name, id, or role to resolve.
  final String target;

  ResolveAddress({required this.target});
}

/// Hub → Child: Dynamic address resolution result.
class ResolveAddressResult extends ProtocolMessage {
  final String target;
  final PortInfo? portInfo;
  final List<PortInfo> ports;

  ResolveAddressResult({
    required this.target,
    this.portInfo,
    this.ports = const [],
  });
}

// ═══════════════════════════════════════════════════════════════════
// Direct P2P / RPC Messages (call / cast)
// ═══════════════════════════════════════════════════════════════════

/// Caller → Target Isolate: Synchronous RPC call request.
class RpcRequest extends ProtocolMessage {
  final Object? request;
  final Map<String, dynamic>? metadata;

  RpcRequest({required this.request, this.metadata});
}

/// Target Isolate → Caller: Synchronous RPC call response.
class RpcResponse extends ProtocolMessage {
  final Object? result;
  final Map<String, dynamic>? metadata;

  RpcResponse({required this.result, this.metadata});
}

/// Target Isolate → Caller: Synchronous RPC call error.
class RpcError extends ProtocolMessage {
  final String code;
  final String message;
  final dynamic details;
  final String? stackTrace;

  RpcError({
    required this.code,
    required this.message,
    this.details,
    this.stackTrace,
  });

  @override
  String toString() => 'RpcError($code: $message)';
}

/// Caller → Target Isolate: Asynchronous fire-and-forget message.
class CastMessage extends ProtocolMessage {
  final Object? message;
  final Map<String, dynamic>? metadata;

  CastMessage({required this.message, this.metadata});
}

// ═══════════════════════════════════════════════════════════════════
// Application Messages (Generic data passing)
// ═══════════════════════════════════════════════════════════════════

/// Generic task request wrapper.
///
/// Use this to send application-specific requests to workers.
class Task<T> extends ProtocolMessage {
  final T data;
  final String? taskType;
  final Map<String, dynamic>? metadata;

  Task({required this.data, this.taskType, this.metadata});
}

/// Generic task result wrapper.
///
/// Use this to send application-specific responses back.
class TaskResult<T> extends ProtocolMessage {
  final T data;
  final Map<String, dynamic>? metadata;

  TaskResult({required this.data, this.metadata});
}

/// Generic task error.
///
/// Use this to send application-specific errors back.
class TaskError extends ProtocolMessage {
  final String code;
  final String message;
  final dynamic details;
  final String? stackTrace;

  TaskError({
    required this.code,
    required this.message,
    this.details,
    this.stackTrace,
  });

  @override
  String toString() => 'TaskError($code: $message)';
}

/// Batch of tasks for bulk processing.
class TaskBatch<T> extends ProtocolMessage {
  final List<Task<T>> tasks;

  TaskBatch(this.tasks);
}

/// Batch results.
class TaskBatchResult<T> extends ProtocolMessage {
  final List<TaskResultOrError<T>> results;

  TaskBatchResult(this.results);
}

/// Union type for result or error.
sealed class TaskResultOrError<T> {}

/// Successful task result.
class TaskSuccess<T> extends TaskResultOrError<T> {
  final T data;
  TaskSuccess(this.data);
}

/// Failed task result.
class TaskFailure<T> extends TaskResultOrError<T> {
  final TaskError error;
  TaskFailure(this.error);
}
