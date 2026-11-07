import 'record.dart';

/// Configurable log formatter.
///
/// Formats [SerializableLogRecord] into human-readable strings
/// with configurable components.
///
/// Example output:
/// ```
/// 2025-01-01T12:00:00.123 [INFO   ] (worker-1) worker.dns: Message here
/// ```
class LogFormatter {
  /// Whether to include timestamp in output.
  final bool includeTimestamp;

  /// Whether to include log level in output.
  final bool includeLevel;

  /// Whether to include isolate ID in output.
  final bool includeIsolateId;

  /// Whether to include logger name in output.
  final bool includeLoggerName;

  /// Separator between components.
  final String separator;

  /// Width for level name padding (for alignment).
  final int levelPadding;

  const LogFormatter({
    this.includeTimestamp = true,
    this.includeLevel = true,
    this.includeIsolateId = true,
    this.includeLoggerName = true,
    this.separator = ' ',
    this.levelPadding = 7,
  });

  /// Format a log record into a string.
  String format(SerializableLogRecord record) {
    final parts = <String>[];

    if (includeTimestamp) {
      parts.add(_formatTimestamp(record.dateTime));
    }

    if (includeLevel) {
      parts.add('[${record.levelName.padRight(levelPadding)}]');
    }

    if (includeIsolateId) {
      parts.add('(${record.isolateId})');
    }

    if (includeLoggerName && record.loggerName.isNotEmpty) {
      parts.add('${record.loggerName}:');
    }

    parts.add(record.message);

    final buffer = StringBuffer(parts.join(separator));

    if (record.error != null) {
      buffer.write('\n  Error: ${record.error}');
    }

    if (record.stackTrace != null) {
      buffer.write('\n${record.stackTrace}');
    }

    return buffer.toString();
  }

  /// Format timestamp as ISO8601.
  String _formatTimestamp(DateTime time) {
    return time.toIso8601String();
  }
}

/// Compact formatter for high-volume logging.
///
/// Only includes timestamp and level, omitting isolate ID and logger name
/// for reduced output size.
///
/// Example output:
/// ```
/// 2025-01-01T12:00:00.123 [INFO   ] Message here
/// ```
class CompactLogFormatter extends LogFormatter {
  const CompactLogFormatter()
    : super(
        includeTimestamp: true,
        includeLevel: true,
        includeIsolateId: false,
        includeLoggerName: false,
      );
}

/// Detailed formatter for debugging.
///
/// Includes all components for maximum context.
///
/// Example output:
/// ```
/// 2025-01-01T12:00:00.123 [INFO   ] (worker-1) worker.dns.cache: Message here
/// ```
class DetailedLogFormatter extends LogFormatter {
  const DetailedLogFormatter()
    : super(
        includeTimestamp: true,
        includeLevel: true,
        includeIsolateId: true,
        includeLoggerName: true,
      );
}

/// Simple formatter with minimal decoration.
///
/// Only includes level and message.
///
/// Example output:
/// ```
/// [INFO   ] Message here
/// ```
class SimpleLogFormatter extends LogFormatter {
  const SimpleLogFormatter()
    : super(
        includeTimestamp: false,
        includeLevel: true,
        includeIsolateId: false,
        includeLoggerName: false,
      );
}

/// Colored formatter for terminal output.
///
/// Adds ANSI color codes based on log level.
/// Best used with [ConsoleLogOutput].
class ColoredLogFormatter extends LogFormatter {
  /// ANSI color codes for each level.
  /// Supports both project levels (DEBUG, ERROR) and Dart logging levels.
  static const Map<String, String> _levelColors = {
    'DEBUG': '\x1B[37m', // Light gray
    'FINEST': '\x1B[90m', // Dark gray (Dart logging)
    'FINER': '\x1B[90m', // Dark gray (Dart logging)
    'FINE': '\x1B[37m', // Light gray (Dart logging)
    'CONFIG': '\x1B[36m', // Cyan (Dart logging)
    'INFO': '\x1B[32m', // Green
    'WARNING': '\x1B[33m', // Yellow
    'ERROR': '\x1B[31m', // Red
    'SEVERE': '\x1B[31m', // Red (Dart logging)
    'SHOUT': '\x1B[35m', // Magenta (Dart logging)
    'OFF': '\x1B[90m', // Dark gray
  };

  static const String _reset = '\x1B[0m';

  const ColoredLogFormatter({
    super.includeTimestamp = true,
    super.includeLevel = true,
    super.includeIsolateId = true,
    super.includeLoggerName = true,
    super.separator = ' ',
    super.levelPadding = 7,
  });

  @override
  String format(SerializableLogRecord record) {
    final color = _levelColors[record.levelName] ?? '';
    final formatted = super.format(record);

    if (color.isEmpty) {
      return formatted;
    }

    return '$color$formatted$_reset';
  }
}

/// Pattern-based formatter with customizable format string.
///
/// Supports the following placeholders:
/// - `%t` - Timestamp (ISO8601)
/// - `%T` - Timestamp (milliseconds since epoch)
/// - `%l` - Level name
/// - `%L` - Level value
/// - `%i` - Isolate ID
/// - `%n` - Logger name
/// - `%m` - Message
/// - `%e` - Error (if any)
/// - `%s` - Stack trace (if any)
/// - `%%` - Literal %
///
/// Example:
/// ```dart
/// final formatter = PatternLogFormatter('%t [%l] %m');
/// ```
class PatternLogFormatter extends LogFormatter {
  /// Format pattern string.
  final String pattern;

  const PatternLogFormatter(this.pattern);

  @override
  String format(SerializableLogRecord record) {
    var result = pattern;

    result = result.replaceAll('%%', '\x00'); // Escape %%
    result = result.replaceAll('%t', record.dateTime.toIso8601String());
    result = result.replaceAll('%T', record.time.toString());
    result = result.replaceAll('%l', record.levelName);
    result = result.replaceAll('%L', record.level.toString());
    result = result.replaceAll('%i', record.isolateId);
    result = result.replaceAll('%n', record.loggerName);
    result = result.replaceAll('%m', record.message);
    result = result.replaceAll('%e', record.error ?? '');
    result = result.replaceAll('%s', record.stackTrace ?? '');
    result = result.replaceAll('\x00', '%'); // Restore literal %

    return result;
  }
}
