import 'dart:convert';
import 'dart:io';

import 'record.dart';

/// Base class for log output destinations.
///
/// Implement this class to create custom log output targets.
abstract class LogOutput {
  const LogOutput();

  /// Write a formatted log record to the output.
  ///
  /// [record] is the original log record data.
  /// [formatted] is the pre-formatted string representation.
  void write(SerializableLogRecord record, String formatted);

  /// Flush any buffered output.
  Future<void> flush() async {}

  /// Close the output and release resources.
  Future<void> close() async {}
}

/// Console output (stdout/stderr).
///
/// By default, logs at WARNING level and above go to stderr,
/// while lower-level logs go to stdout.
class ConsoleLogOutput extends LogOutput {
  /// Whether to use stderr for high-level logs.
  final bool useStderr;

  /// Level value threshold for stderr (default: Level.WARNING = 900).
  final int stderrThreshold;

  const ConsoleLogOutput({
    this.useStderr = true,
    this.stderrThreshold = 900, // Level.WARNING
  });

  @override
  void write(SerializableLogRecord record, String formatted) {
    if (useStderr && record.level >= stderrThreshold) {
      stderr.writeln(formatted);
    } else {
      // ignore: avoid_print
      print(formatted);
    }
  }
}

/// File output with rotation support.
///
/// Writes logs to a file with automatic rotation when the file exceeds
/// [maxSizeBytes]. Keeps up to [maxFiles] rotated files.
class FileLogOutput extends LogOutput {
  /// Path to the log file.
  final String path;

  /// Maximum file size before rotation (default: 10MB).
  final int maxSizeBytes;

  /// Maximum number of rotated files to keep.
  final int maxFiles;

  IOSink? _sink;
  int _currentSize = 0;

  FileLogOutput({
    required this.path,
    this.maxSizeBytes = 10 * 1024 * 1024, // 10MB
    this.maxFiles = 5,
  });

  @override
  void write(SerializableLogRecord record, String formatted) {
    _ensureOpen();
    final line = '$formatted\n';
    _sink!.write(line);
    _currentSize += line.length;

    if (_currentSize >= maxSizeBytes) {
      _rotate();
    }
  }

  void _ensureOpen() {
    if (_sink == null) {
      final file = File(path);
      // Create parent directories if needed
      file.parent.createSync(recursive: true);
      _sink = file.openWrite(mode: FileMode.append);

      // Get current file size
      if (file.existsSync()) {
        _currentSize = file.lengthSync();
      }
    }
  }

  void _rotate() {
    _sink?.close();
    _sink = null;
    _currentSize = 0;

    // Rotate files: log.4 -> delete, log.3 -> log.4, etc.
    for (var i = maxFiles - 1; i >= 0; i--) {
      final file = File(i == 0 ? path : '$path.$i');
      if (file.existsSync()) {
        if (i == maxFiles - 1) {
          file.deleteSync();
        } else {
          file.renameSync('$path.${i + 1}');
        }
      }
    }
  }

  @override
  Future<void> flush() async {
    await _sink?.flush();
  }

  @override
  Future<void> close() async {
    await _sink?.close();
    _sink = null;
  }
}

/// JSON lines output (for log aggregation systems).
///
/// Wraps another [LogOutput] and writes logs as JSON objects,
/// one per line. This format is commonly used by log aggregation
/// systems like Elasticsearch, Splunk, etc.
class JsonLogOutput extends LogOutput {
  /// Inner output target.
  final LogOutput inner;

  const JsonLogOutput(this.inner);

  @override
  void write(SerializableLogRecord record, String formatted) {
    final json = jsonEncode(record.toMap());
    inner.write(record, json);
  }

  @override
  Future<void> flush() => inner.flush();

  @override
  Future<void> close() => inner.close();
}

/// Callback output for custom handling.
///
/// Calls the provided callback for each log record, allowing
/// custom processing or integration with other logging systems.
class CallbackLogOutput extends LogOutput {
  /// Callback function to handle log records.
  final void Function(SerializableLogRecord record, String formatted) callback;

  const CallbackLogOutput(this.callback);

  @override
  void write(SerializableLogRecord record, String formatted) {
    callback(record, formatted);
  }
}

/// Multi-output that writes to multiple destinations.
///
/// Useful for simultaneously logging to console and file.
class MultiLogOutput extends LogOutput {
  /// List of output targets.
  final List<LogOutput> outputs;

  const MultiLogOutput(this.outputs);

  @override
  void write(SerializableLogRecord record, String formatted) {
    for (final output in outputs) {
      output.write(record, formatted);
    }
  }

  @override
  Future<void> flush() async {
    for (final output in outputs) {
      await output.flush();
    }
  }

  @override
  Future<void> close() async {
    for (final output in outputs) {
      await output.close();
    }
  }
}

/// Buffered output that batches writes for performance.
///
/// Buffers log records and writes them in batches to improve
/// I/O performance for high-volume logging.
class BufferedLogOutput extends LogOutput {
  /// Inner output target.
  final LogOutput inner;

  /// Maximum buffer size before auto-flush.
  final int maxBufferSize;

  /// Maximum time to hold records before flushing.
  final Duration maxBufferTime;

  final List<_BufferedRecord> _buffer = [];
  DateTime? _lastFlush;

  BufferedLogOutput(
    this.inner, {
    this.maxBufferSize = 100,
    this.maxBufferTime = const Duration(seconds: 5),
  });

  @override
  void write(SerializableLogRecord record, String formatted) {
    _buffer.add(_BufferedRecord(record, formatted));

    final now = DateTime.now();
    _lastFlush ??= now;

    if (_buffer.length >= maxBufferSize ||
        now.difference(_lastFlush!) >= maxBufferTime) {
      _flushBuffer();
    }
  }

  void _flushBuffer() {
    for (final item in _buffer) {
      inner.write(item.record, item.formatted);
    }
    _buffer.clear();
    _lastFlush = DateTime.now();
  }

  @override
  Future<void> flush() async {
    _flushBuffer();
    await inner.flush();
  }

  @override
  Future<void> close() async {
    _flushBuffer();
    await inner.close();
  }
}

class _BufferedRecord {
  final SerializableLogRecord record;
  final String formatted;

  _BufferedRecord(this.record, this.formatted);
}

/// Filtered output that only writes records matching a predicate.
class FilteredLogOutput extends LogOutput {
  /// Inner output target.
  final LogOutput inner;

  /// Predicate to filter records.
  final bool Function(SerializableLogRecord record) predicate;

  const FilteredLogOutput(this.inner, this.predicate);

  @override
  void write(SerializableLogRecord record, String formatted) {
    if (predicate(record)) {
      inner.write(record, formatted);
    }
  }

  @override
  Future<void> flush() => inner.flush();

  @override
  Future<void> close() => inner.close();
}
