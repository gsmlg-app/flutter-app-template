import 'dart:async';
import 'dart:isolate';

import 'package:logging/logging.dart';

import '../health/metrics.dart';
import '../hub/hub.dart';
import '../message/address.dart';
import '../message/envelope.dart';
import '../message/protocol.dart';
import 'formatter.dart';
import 'output.dart';
import 'record.dart';

/// Configuration for [CentralLogger].
class CentralLoggerConfig {
  /// Minimum log level to process.
  final Level level;

  /// Log formatter.
  final LogFormatter formatter;

  /// Output destinations.
  final List<LogOutput> outputs;

  /// Per-logger level overrides.
  ///
  /// Keys are logger name prefixes, values are minimum levels.
  /// More specific prefixes take precedence.
  final Map<String, Level>? loggerLevels;

  const CentralLoggerConfig({
    this.level = Level.INFO,
    this.formatter = const LogFormatter(),
    this.outputs = const [ConsoleLogOutput()],
    this.loggerLevels,
  });

  /// Create config from a map (e.g., from JSON/TOML configuration).
  factory CentralLoggerConfig.fromMap(Map<String, dynamic> config) {
    final levelName = config['level'] as String? ?? 'INFO';
    final level = _parseLogLevel(levelName);

    final outputs = <LogOutput>[];

    if (config['console'] != false) {
      outputs.add(const ConsoleLogOutput());
    }

    if (config['file'] != null) {
      final fileConfig = config['file'] as Map<String, dynamic>;
      outputs.add(
        FileLogOutput(
          path: fileConfig['path'] as String? ?? 'app.log',
          maxSizeBytes:
              fileConfig['max_size_bytes'] as int? ?? 10 * 1024 * 1024,
          maxFiles: fileConfig['max_files'] as int? ?? 5,
        ),
      );
    }

    Map<String, Level>? loggerLevels;
    if (config['logger_levels'] != null) {
      final levels = config['logger_levels'] as Map<String, dynamic>;
      loggerLevels = {};
      for (final entry in levels.entries) {
        final lvl = _parseLogLevel(entry.value as String);
        loggerLevels[entry.key] = lvl;
      }
    }

    return CentralLoggerConfig(
      level: level,
      outputs: outputs.isEmpty ? const [ConsoleLogOutput()] : outputs,
      loggerLevels: loggerLevels,
    );
  }

  /// Parse a log level string, mapping common names to logging package levels.
  static Level _parseLogLevel(String name) {
    switch (name.toUpperCase()) {
      case 'DEBUG':
        return Level.FINE;
      case 'TRACE':
        return Level.FINEST;
      case 'WARN':
        return Level.WARNING;
      case 'ERROR':
        return Level.SEVERE;
      default:
        return Level.LEVELS.firstWhere(
          (l) => l.name == name.toUpperCase(),
          orElse: () => Level.INFO,
        );
    }
  }
}

/// Central logger that aggregates logs from all isolates.
///
/// The central logger runs in the main isolate (or a dedicated logger isolate)
/// and receives log records from all worker isolates via SendPort.
///
/// Example:
/// ```dart
/// final logger = CentralLogger(config: CentralLoggerConfig(
///   level: Level.INFO,
///   outputs: [ConsoleLogOutput(), FileLogOutput(path: 'app.log')],
/// ));
///
/// logger.start();
///
/// // Give sendPort to worker isolates
/// final port = logger.sendPort;
///
/// // ... later ...
/// await logger.stop();
/// ```
class CentralLogger {
  /// Logger configuration.
  final CentralLoggerConfig config;

  final ReceivePort _receivePort = ReceivePort();
  StreamSubscription<dynamic>? _subscription;

  /// Statistics
  int _recordsProcessed = 0;
  int _recordsFiltered = 0;

  CentralLogger({required this.config});

  /// Get SendPort for worker isolates to send logs.
  SendPort get sendPort => _receivePort.sendPort;

  /// Number of records processed.
  int get recordsProcessed => _recordsProcessed;

  /// Number of records filtered out.
  int get recordsFiltered => _recordsFiltered;

  /// Start processing logs.
  void start() {
    _subscription = _receivePort.listen(_handleMessage);
  }

  /// Stop processing and cleanup.
  Future<void> stop() async {
    _subscription?.cancel();
    _subscription = null;
    _receivePort.close();

    for (final output in config.outputs) {
      await output.flush();
      await output.close();
    }
  }

  /// Process a log record directly (without SendPort).
  ///
  /// Useful for logging from the main isolate.
  void log(SerializableLogRecord record) {
    _processRecord(record);
  }

  void _handleMessage(dynamic message) {
    if (message is! Map<String, dynamic>) return;

    final record = SerializableLogRecord.fromMap(message);
    _processRecord(record);
  }

  void _processRecord(SerializableLogRecord record) {
    // Check level filter
    if (!_shouldLog(record)) {
      _recordsFiltered++;
      return;
    }

    _recordsProcessed++;

    // Format
    final formatted = config.formatter.format(record);

    // Output to all targets
    for (final output in config.outputs) {
      output.write(record, formatted);
    }
  }

  bool _shouldLog(SerializableLogRecord record) {
    // Check per-logger level overrides
    if (config.loggerLevels != null) {
      // Find the most specific matching prefix
      String? bestMatch;
      Level? bestLevel;

      for (final entry in config.loggerLevels!.entries) {
        if (record.loggerName.startsWith(entry.key)) {
          if (bestMatch == null || entry.key.length > bestMatch.length) {
            bestMatch = entry.key;
            bestLevel = entry.value;
          }
        }
      }

      if (bestLevel != null) {
        return record.level >= bestLevel.value;
      }
    }

    // Fall back to global level
    return record.level >= config.level.value;
  }
}

/// Entry point for running CentralLogger in a dedicated isolate.
///
/// Example:
/// ```dart
/// final handle = await hub.spawn(
///   role: 'logger',
///   name: 'central-logger',
///   entryPoint: centralLoggerEntryPoint,
///   config: {
///     'level': 'DEBUG',
///     'console': true,
///     'file': {'path': '/var/log/app.log'},
///   },
/// );
/// ```
void centralLoggerEntryPoint(SendPort hubPort) {
  final receivePort = ReceivePort();
  CentralLogger? logger;
  String? loggerId;
  final startTime = DateTime.now();

  // Register with hub
  final regEnvelope = Envelope.create(
    id: 'logger-register-${DateTime.now().microsecondsSinceEpoch}',
    source: IsolateAddress.of('logger', 'logger-pending'),
    target: IsolateAddress.hub,
    payload: Register(
      name: 'central-logger',
      role: 'logger',
      port: receivePort.sendPort,
      capabilities: const ['logging'],
      subscribesTo: const [],
    ),
  );
  hubPort.send(regEnvelope);

  receivePort.listen((message) async {
    if (message is Envelope) {
      final payload = message.payload;

      switch (payload) {
        case Init init:
          // Extract logger ID from target address
          loggerId = message.target.id;

          final config = CentralLoggerConfig.fromMap(init.config);
          logger = CentralLogger(config: config);
          logger!.start();

          final readyEnvelope = Envelope.create(
            id: 'logger-ready-${DateTime.now().microsecondsSinceEpoch}',
            source: IsolateAddress.of('logger', loggerId!),
            target: IsolateAddress.hub,
            payload: Ready.ok(),
          );
          hubPort.send(readyEnvelope);

        case Ping ping:
          // Respond to health checks
          final pongEnvelope = Envelope.create(
            id: 'logger-pong-${DateTime.now().microsecondsSinceEpoch}',
            source: IsolateAddress.of('logger', loggerId ?? 'logger-0'),
            target: IsolateAddress.hub,
            payload: Pong(
              seq: ping.seq,
              metrics: IsolateMetrics(
                uptimeMs: DateTime.now().difference(startTime).inMilliseconds,
                processedCount: logger?.recordsProcessed ?? 0,
                pendingCount: 0,
                errorCount: 0,
                avgLatencyUs: 0,
              ),
            ),
          );
          hubPort.send(pongEnvelope);

        case Shutdown():
          await logger?.stop();
          final ackEnvelope = Envelope.create(
            id: 'logger-shutdown-${DateTime.now().microsecondsSinceEpoch}',
            source: IsolateAddress.of('logger', loggerId ?? 'logger-0'),
            target: IsolateAddress.hub,
            payload: ShutdownAck(pendingTasks: 0, flushed: true),
          );
          hubPort.send(ackEnvelope);
          receivePort.close();

        default:
          break;
      }
    } else if (message is Map<String, dynamic>) {
      // Log record from worker
      if (logger != null) {
        final record = SerializableLogRecord.fromMap(message);
        logger!.log(record);
      }
    }
  });
}

/// Helper class for setting up logging in the main application.
///
/// Example:
/// ```dart
/// final setup = LoggingSetup(hub: hub);
/// await setup.start(config);
///
/// // Use loggerPort when spawning workers
/// final pool = WorkerPool(...);
/// await pool.start();
///
/// // ... later ...
/// await setup.stop();
/// ```
class LoggingSetup {
  /// The central logger (if running in main isolate).
  CentralLogger? _logger;

  /// Logger isolate handle (if running in separate isolate).
  IsolateHandle? _loggerHandle;

  /// Logger port for workers.
  SendPort? _loggerPort;

  /// Hub used when [useIsolate] is true.
  final IsolateHub? hub;

  /// Whether logging is running in a separate isolate.
  final bool useIsolate;

  LoggingSetup({this.hub, this.useIsolate = false});

  /// Get the logger port for workers.
  SendPort? get loggerPort => _loggerPort ?? _logger?.sendPort;

  /// Start logging with the given configuration.
  Future<void> start(CentralLoggerConfig config) async {
    if (useIsolate) {
      if (hub == null) {
        throw StateError('IsolateHub is required when useIsolate is true');
      }
      final loggerLevelsMap = config.loggerLevels?.map(
        (k, v) => MapEntry(k, v.name),
      );
      _loggerHandle = await hub!.spawn(
        role: 'logger',
        name: 'central-logger',
        entryPoint: centralLoggerEntryPoint,
        capabilities: const ['logging'],
        config: {
          'level': config.level.name,
          'console': config.outputs.any((o) => o is ConsoleLogOutput),
          'logger_levels': ?loggerLevelsMap,
        },
      );
      _loggerPort = _loggerHandle!.sendPort;
    } else {
      _logger = CentralLogger(config: config);
      _logger!.start();
      _loggerPort = _logger!.sendPort;
    }
  }

  /// Stop logging.
  Future<void> stop() async {
    if (_loggerHandle != null) {
      await _loggerHandle!.kill(graceful: true);
      _loggerHandle = null;
    }
    if (_logger != null) {
      await _logger!.stop();
      _logger = null;
    }
    _loggerPort = null;
  }
}
