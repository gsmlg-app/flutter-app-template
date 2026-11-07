import 'dart:async';
import 'dart:isolate';

import 'package:logging/logging.dart';

import 'record.dart';

/// Bridges the logging package to a central logger via SendPort.
///
/// This class intercepts all log records in the current isolate and
/// forwards them to a central logger running in another isolate.
///
/// Example:
/// ```dart
/// // In worker isolate
/// final bridge = IsolateLogBridge(
///   isolateId: 'worker-1',
///   loggerPort: centralLoggerPort,
/// );
/// bridge.install();
///
/// // Now all logs are forwarded
/// Logger('my.component').info('Hello from worker');
/// ```
class IsolateLogBridge {
  /// Unique identifier for this isolate.
  final String isolateId;

  /// SendPort to the central logger.
  final SendPort loggerPort;

  /// Prefix for logger names (optional).
  final String _loggerPrefix;

  StreamSubscription<LogRecord>? _subscription;
  Map<String, dynamic>? _defaultContext;

  IsolateLogBridge({
    required this.isolateId,
    required this.loggerPort,
    String loggerPrefix = '',
  }) : _loggerPrefix = loggerPrefix;

  /// Install the bridge.
  ///
  /// Intercepts all log records in the current isolate and forwards them
  /// to the central logger. Sets the root logger level to [level].
  ///
  /// [defaultContext] is included in all log records sent to the central logger.
  void install({
    Level level = Level.ALL,
    Map<String, dynamic>? defaultContext,
  }) {
    _defaultContext = defaultContext;
    Logger.root.level = level;

    _subscription = Logger.root.onRecord.listen(_forwardRecord);
  }

  /// Uninstall the bridge.
  ///
  /// Stops forwarding log records.
  void uninstall() {
    _subscription?.cancel();
    _subscription = null;
  }

  void _forwardRecord(LogRecord record) {
    // Merge default context with any record-specific context
    final context = _defaultContext != null
        ? Map<String, dynamic>.from(_defaultContext!)
        : null;

    final serializable = SerializableLogRecord.fromLogRecord(
      record,
      isolateId,
      context: context,
    );
    loggerPort.send(serializable.toMap());
  }

  /// Get a named logger with the configured prefix.
  ///
  /// Example:
  /// ```dart
  /// final logger = bridge.getLogger('cache');
  /// // If prefix is 'worker.dns', logger name is 'worker.dns.cache'
  /// ```
  Logger getLogger(String name) {
    final fullName = _loggerPrefix.isEmpty ? name : '$_loggerPrefix.$name';
    return Logger(fullName);
  }

  /// Check if the bridge is currently installed.
  bool get isInstalled => _subscription != null;

  /// Get the logger prefix.
  String get loggerPrefix => _loggerPrefix;
}
