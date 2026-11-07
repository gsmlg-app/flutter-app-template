import 'dart:isolate';

import 'package:logging/logging.dart';

import '../logging/bridge.dart';
import '../message/id_generator.dart';

/// Log levels for worker logging.
///
/// @deprecated Use [Level] from the logging package instead.
enum LogLevel { debug, info, warning, error }

/// Context provided to worker.
///
/// WorkerContext provides workers with:
/// - Identity information (id, name, role)
/// - Communication ports (hubPort, loggerPort, dependencies)
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

  WorkerContext({
    required this.id,
    required this.name,
    required this.role,
    required this.hubPort,
    this.loggerPort,
    required this.dependencies,
    required this.idGenerator,
    required this.config,
  }) {
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
  }
}
