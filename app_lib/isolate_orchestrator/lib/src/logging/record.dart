import 'package:logging/logging.dart';

/// Serializable log record for cross-isolate transport.
///
/// Since [LogRecord] objects cannot be directly passed across isolate
/// boundaries, this class provides a serializable representation that
/// can be sent via SendPort.
class SerializableLogRecord {
  /// Log level value (e.g., Level.INFO.value)
  final int level;

  /// Log level name (e.g., "INFO")
  final String levelName;

  /// Log message
  final String message;

  /// Name of the logger that created this record
  final String loggerName;

  /// Time when the record was created (microseconds since epoch)
  final int time;

  /// Error object as string, if any
  final String? error;

  /// Stack trace as string, if any
  final String? stackTrace;

  /// ID of the isolate that created this record
  final String isolateId;

  /// Additional context data
  final Map<String, dynamic>? context;

  const SerializableLogRecord({
    required this.level,
    required this.levelName,
    required this.message,
    required this.loggerName,
    required this.time,
    this.error,
    this.stackTrace,
    required this.isolateId,
    this.context,
  });

  /// Create from logging package [LogRecord].
  factory SerializableLogRecord.fromLogRecord(
    LogRecord record,
    String isolateId, {
    Map<String, dynamic>? context,
  }) {
    return SerializableLogRecord(
      level: record.level.value,
      levelName: record.level.name,
      message: record.message,
      loggerName: record.loggerName,
      time: record.time.microsecondsSinceEpoch,
      error: record.error?.toString(),
      stackTrace: record.stackTrace?.toString(),
      isolateId: isolateId,
      context: context,
    );
  }

  /// Convert back to [LogRecord].
  ///
  /// Note: The returned LogRecord will have the level reconstructed from
  /// levelName and level value.
  LogRecord toLogRecord() {
    return LogRecord(
      Level(levelName, level),
      message,
      loggerName,
      error != null ? Exception(error) : null,
      stackTrace != null ? StackTrace.fromString(stackTrace!) : null,
    );
  }

  /// Serialize to Map for SendPort transport.
  Map<String, dynamic> toMap() => {
    'level': level,
    'levelName': levelName,
    'message': message,
    'loggerName': loggerName,
    'time': time,
    'error': error,
    'stackTrace': stackTrace,
    'isolateId': isolateId,
    'context': context,
  };

  /// Deserialize from Map.
  factory SerializableLogRecord.fromMap(Map<String, dynamic> map) {
    return SerializableLogRecord(
      level: map['level'] as int,
      levelName: map['levelName'] as String,
      message: map['message'] as String,
      loggerName: map['loggerName'] as String,
      time: map['time'] as int,
      error: map['error'] as String?,
      stackTrace: map['stackTrace'] as String?,
      isolateId: map['isolateId'] as String,
      context: map['context'] as Map<String, dynamic>?,
    );
  }

  /// Get the time as DateTime.
  DateTime get dateTime => DateTime.fromMicrosecondsSinceEpoch(time);

  @override
  String toString() {
    return 'SerializableLogRecord('
        'level: $levelName, '
        'message: $message, '
        'logger: $loggerName, '
        'isolate: $isolateId)';
  }
}
