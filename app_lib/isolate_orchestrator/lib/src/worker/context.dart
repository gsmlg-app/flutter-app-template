import 'dart:async';
import 'dart:isolate';

import 'package:logging/logging.dart';

import '../exception.dart';
import '../logging/bridge.dart';
import '../message/address.dart';
import '../message/envelope.dart';
import '../message/id_generator.dart';
import '../message/protocol.dart';

/// Log levels for worker logging.
///
/// @deprecated Use [Level] from the logging package instead.
enum LogLevel { debug, info, warning, error }

/// Context provided to worker.
///
/// WorkerContext provides workers with:
/// - Identity information (id, name, role, path)
/// - Communication ports (hubPort, loggerPort, dependencies)
/// - Direct cross-isolate P2P RPC (`call`) and fire-and-forget (`cast`)
/// - Dynamic address resolution (`resolve`) with automatic cache invalidation on `PortUpdate`
/// - Configuration data
/// - Logging support via the `logging` package
///
/// Example:
/// ```dart
/// class MyWorker extends Worker<MyData> {
///   @override
///   Future<void> onInit(Map<String, dynamic> config) async {
///     context.info('Worker initialized');
///
///     // Get a sub-logger
///     final cacheLogger = context.getLogger('cache');
///     cacheLogger.fine('Cache initialized');
///   }
/// }
/// ```
class WorkerContext {
  /// Unique worker ID.
  final String id;

  /// Worker name.
  final String name;

  /// Worker role.
  final String role;

  /// Hierarchical path in the supervision tree (e.g., `/network/dns`).
  final String path;

  /// Port to send messages back to hub.
  final SendPort hubPort;

  /// Optional port to send logs to central logger.
  final SendPort? loggerPort;

  /// Dependencies (ports) for other roles.
  final Map<String, List<SendPort>> dependencies;

  /// ID generator for messages.
  final MessageIdGenerator idGenerator;

  /// Configuration passed during initialization.
  final Map<String, dynamic> config;

  late final Logger _logger;
  IsolateLogBridge? _logBridge;

  /// Cached target -> PortInfo entries for P2P communication.
  final Map<String, PortInfo> _resolvedCache = {};

  /// Lazily initialized ReceivePort for RPC responses and address resolution replies.
  ReceivePort? _rpcPort;
  StreamSubscription? _rpcSubscription;
  final Map<String, Completer<Object?>> _pendingRpc = {};
  final Map<String, Completer<ResolveAddressResult>> _pendingResolves = {};
  final void Function()? _onSelfStop;

  WorkerContext({
    required this.id,
    required this.name,
    required this.role,
    String? path,
    required this.hubPort,
    this.loggerPort,
    required this.dependencies,
    required this.idGenerator,
    required this.config,
    void Function()? onSelfStop,
  }) : path = path ?? '/$name',
       _onSelfStop = onSelfStop {
    final loggerName = 'worker.$name';
    _logger = Logger(loggerName);

    // Install log bridge if logger port is available
    if (loggerPort != null) {
      _logBridge = IsolateLogBridge(
        isolateId: id,
        loggerPort: loggerPort!,
        loggerPrefix: loggerName,
      );
      _logBridge!.install(
        defaultContext: {'workerId': id, 'workerName': name, 'role': role},
      );
    }
  }

  /// Address of this worker isolate.
  IsolateAddress get address => IsolateAddress.of(role, id);

  /// Get the root logger for this worker.
  Logger get logger => _logger;

  /// Get a sub-logger with the given name.
  ///
  /// Example:
  /// ```dart
  /// final cacheLogger = context.getLogger('cache');
  /// // Logger name will be 'worker.myworker.cache'
  /// ```
  Logger getLogger(String name) => Logger('${_logger.fullName}.$name');

  /// Get a specific config value.
  T? getConfig<T>(String key) {
    final value = config[key];
    return value is T ? value : null;
  }

  /// Get required config value or throw.
  T requireConfig<T>(String key) {
    final value = config[key];
    if (value is! T) {
      throw ArgumentError('Missing required config: $key');
    }
    return value;
  }

  /// Get ports for a dependency role.
  List<SendPort> getDependency(String role) {
    return dependencies[role] ?? [];
  }

  // =========================================================================
  // P2P Communication (resolve, call, cast)
  // =========================================================================

  SendPort _ensureRpcPort() {
    if (_rpcPort == null) {
      _rpcPort = ReceivePort();
      _rpcSubscription = _rpcPort!.listen(_handleRpcMessage);
    }
    return _rpcPort!.sendPort;
  }

  void _handleRpcMessage(dynamic message) {
    if (message is! Envelope) return;
    final corrId = message.correlationId ?? message.id;
    final payload = message.payload;

    if (payload is ResolveAddressResult) {
      final completer = _pendingResolves.remove(corrId);
      if (completer != null && !completer.isCompleted) {
        completer.complete(payload);
      }
      return;
    }

    final completer = _pendingRpc.remove(corrId);
    if (completer == null || completer.isCompleted) return;

    switch (payload) {
      case RpcResponse response:
        completer.complete(response.result);
      case RpcError error:
        completer.completeError(
          TaskException(
            error.code,
            error.message,
            error.details,
            error.stackTrace,
          ),
        );
      case TaskResult result:
        completer.complete(result.data);
      case TaskError error:
        completer.completeError(
          TaskException(
            error.code,
            error.message,
            error.details,
            error.stackTrace,
          ),
        );
      default:
        completer.complete(payload);
    }
  }

  /// Resolve a target isolate (`path`, `name`, `id`, `role`, or `capability`) to a [PortInfo].
  ///
  /// Caches resolved ports locally and automatically updates or invalidates them
  /// when the Hub pushes a [PortUpdate].
  Future<PortInfo?> resolve(
    String target, {
    bool forceRefresh = false,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (!forceRefresh) {
      final cached = _resolvedCache[target];
      if (cached != null) return cached;
    }

    final msgId = idGenerator.next();
    final completer = Completer<ResolveAddressResult>();
    _pendingResolves[msgId] = completer;

    final envelope = Envelope<ProtocolMessage>(
      id: msgId,
      timestamp: DateTime.now().microsecondsSinceEpoch,
      correlationId: msgId,
      source: address,
      target: IsolateAddress.hub,
      replyTo: _ensureRpcPort(),
      payload: ResolveAddress(target: target),
    );
    hubPort.send(envelope);

    try {
      final result = await completer.future.timeout(timeout);
      final info = result.portInfo;
      if (info != null) {
        _cachePortInfo(info, requestedTarget: target);
      } else {
        _resolvedCache.remove(target);
      }
      return info;
    } on TimeoutException {
      return null;
    } finally {
      _pendingResolves.remove(msgId);
    }
  }

  void _cachePortInfo(PortInfo info, {String? requestedTarget}) {
    if (requestedTarget != null) {
      _resolvedCache[requestedTarget] = info;
    }
    _resolvedCache[info.id] = info;
    if (info.name != null) {
      _resolvedCache[info.name!] = info;
    }
    if (info.path != null) {
      _resolvedCache[info.path!] = info;
    }
    if (info.role != null) {
      _resolvedCache[info.role!] = info;
    }
  }

  /// Apply a [PortUpdate] from the Hub to refresh or invalidate cached P2P targets.
  void applyPortUpdate(PortUpdate update) {
    if (update.removed.isNotEmpty ||
        update.removedNames.isNotEmpty ||
        update.removedPaths.isNotEmpty) {
      _resolvedCache.removeWhere(
        (key, info) =>
            update.removed.contains(info.id) ||
            update.removed.contains(key) ||
            update.removedNames.contains(key) ||
            update.removedPaths.contains(key) ||
            (info.name != null && update.removedNames.contains(info.name)) ||
            (info.path != null && update.removedPaths.contains(info.path)),
      );
    }
    for (final added in update.added) {
      _cachePortInfo(added);
    }
  }

  /// Perform a direct peer-to-peer RPC call to [target] (`path`, `name`, `id`, `role`, or `capability`).
  Future<TRes> call<TRes>(
    String target,
    Object? request, {
    Duration timeout = const Duration(seconds: 5),
    Map<String, dynamic>? metadata,
  }) async {
    final portInfo = await resolve(target, timeout: timeout);
    if (portInfo == null) {
      throw NodeNotFoundException(target);
    }

    final msgId = idGenerator.next();
    final completer = Completer<Object?>();
    _pendingRpc[msgId] = completer;

    final envelope = Envelope<ProtocolMessage>(
      id: msgId,
      timestamp: DateTime.now().microsecondsSinceEpoch,
      correlationId: msgId,
      source: address,
      target: IsolateAddress.of(portInfo.role ?? 'worker', portInfo.id),
      replyTo: _ensureRpcPort(),
      payload: RpcRequest(request: request, metadata: metadata),
    );
    portInfo.port.send(envelope);

    try {
      final res = await completer.future.timeout(timeout);
      return res as TRes;
    } on TimeoutException {
      throw TaskTimeoutException(msgId, 0);
    } finally {
      _pendingRpc.remove(msgId);
    }
  }

  /// Send a direct peer-to-peer fire-and-forget message to [target] (`path`, `name`, `id`, `role`, or `capability`).
  Future<void> cast(
    String target,
    Object? message, {
    Map<String, dynamic>? metadata,
  }) async {
    final portInfo = await resolve(target);
    if (portInfo == null) {
      throw NodeNotFoundException(target);
    }

    final envelope = Envelope.create(
      id: idGenerator.next(),
      source: address,
      target: IsolateAddress.of(portInfo.role ?? 'worker', portInfo.id),
      payload: CastMessage(message: message, metadata: metadata),
    );
    portInfo.port.send(envelope);
  }

  /// Initiate a voluntary normal shutdown of this worker isolate.
  ///
  /// Under `ChildRestartType.transient`, a worker that stops via [stopSelf]
  /// is treated as a normal exit and is not restarted by its supervisor.
  void stopSelf() {
    final ackEnvelope = Envelope.create(
      id: idGenerator.next(),
      source: address,
      target: IsolateAddress.hub,
      payload: ShutdownAck(pendingTasks: 0, flushed: true),
    );
    hubPort.send(ackEnvelope);
    _onSelfStop?.call();
  }

  // =========================================================================
  // Convenience logging methods
  // =========================================================================

  /// Log at FINEST level.
  void finest(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.finest(message, error, stackTrace);

  /// Log at FINER level.
  void finer(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.finer(message, error, stackTrace);

  /// Log at FINE level.
  void fine(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.fine(message, error, stackTrace);

  /// Log at CONFIG level.
  void configLog(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.config(message, error, stackTrace);

  /// Log at INFO level.
  void info(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.info(message, error, stackTrace);

  /// Log at WARNING level.
  void warning(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.warning(message, error, stackTrace);

  /// Log at SEVERE level.
  void severe(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.severe(message, error, stackTrace);

  /// Log at SHOUT level.
  void shout(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.shout(message, error, stackTrace);

  // =========================================================================
  // Legacy logging methods (deprecated)
  // =========================================================================

  /// Send log message to hub.
  ///
  /// @deprecated Use the new logging methods (info, warning, etc.) instead.
  void log(LogLevel level, String message, {Map<String, dynamic>? context}) {
    switch (level) {
      case LogLevel.debug:
        _logger.fine(message);
      case LogLevel.info:
        _logger.info(message);
      case LogLevel.warning:
        _logger.warning(message);
      case LogLevel.error:
        _logger.severe(message);
    }
  }

  /// @deprecated Use [fine] instead.
  void debug(String message, {Map<String, dynamic>? context}) =>
      log(LogLevel.debug, message, context: context);

  /// @deprecated Use [severe] instead.
  void error(String message, {Map<String, dynamic>? context}) =>
      log(LogLevel.error, message, context: context);

  // =========================================================================
  // Lifecycle
  // =========================================================================

  /// Dispose of resources.
  ///
  /// Should be called when the worker is shutting down.
  void dispose() {
    _logBridge?.uninstall();
    _rpcSubscription?.cancel();
    _rpcSubscription = null;
    _rpcPort?.close();
    _rpcPort = null;
    _pendingRpc.clear();
    _pendingResolves.clear();
    _resolvedCache.clear();
  }
}
