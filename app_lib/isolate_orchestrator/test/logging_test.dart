import 'dart:async';
import 'dart:isolate';

import 'package:isolate_orchestrator/isolate_orchestrator.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

void main() {
  group('SerializableLogRecord', () {
    test('creates from LogRecord', () {
      final logRecord = LogRecord(Level.INFO, 'Test message', 'test.logger');

      final serializable = SerializableLogRecord.fromLogRecord(
        logRecord,
        'test-isolate',
        context: {'key': 'value'},
      );

      expect(serializable.level, equals(Level.INFO.value));
      expect(serializable.levelName, equals('INFO'));
      expect(serializable.message, equals('Test message'));
      expect(serializable.loggerName, equals('test.logger'));
      expect(serializable.isolateId, equals('test-isolate'));
      expect(serializable.context, equals({'key': 'value'}));
    });

    test('serializes to and from Map', () {
      final original = SerializableLogRecord(
        level: 800,
        levelName: 'INFO',
        message: 'Test message',
        loggerName: 'test.logger',
        time: DateTime(2025, 1, 1).microsecondsSinceEpoch,
        error: 'Test error',
        stackTrace: 'stack trace',
        isolateId: 'test-isolate',
        context: {'key': 'value'},
      );

      final map = original.toMap();
      final restored = SerializableLogRecord.fromMap(map);

      expect(restored.level, equals(original.level));
      expect(restored.levelName, equals(original.levelName));
      expect(restored.message, equals(original.message));
      expect(restored.loggerName, equals(original.loggerName));
      expect(restored.time, equals(original.time));
      expect(restored.error, equals(original.error));
      expect(restored.stackTrace, equals(original.stackTrace));
      expect(restored.isolateId, equals(original.isolateId));
      expect(restored.context, equals(original.context));
    });

    test('converts back to LogRecord', () {
      final serializable = SerializableLogRecord(
        level: 800,
        levelName: 'INFO',
        message: 'Test message',
        loggerName: 'test.logger',
        time: DateTime.now().microsecondsSinceEpoch,
        isolateId: 'test-isolate',
      );

      final logRecord = serializable.toLogRecord();

      expect(logRecord.level.value, equals(800));
      expect(logRecord.level.name, equals('INFO'));
      expect(logRecord.message, equals('Test message'));
      expect(logRecord.loggerName, equals('test.logger'));
    });

    test('dateTime getter works', () {
      final now = DateTime.now();
      final serializable = SerializableLogRecord(
        level: 800,
        levelName: 'INFO',
        message: 'Test',
        loggerName: 'test',
        time: now.microsecondsSinceEpoch,
        isolateId: 'test',
      );

      expect(
        serializable.dateTime.microsecondsSinceEpoch,
        equals(now.microsecondsSinceEpoch),
      );
    });
  });

  group('LogFormatter', () {
    late SerializableLogRecord record;

    setUp(() {
      record = SerializableLogRecord(
        level: 800,
        levelName: 'INFO',
        message: 'Test message',
        loggerName: 'test.logger',
        time: DateTime(2025, 1, 1, 12, 0, 0).microsecondsSinceEpoch,
        isolateId: 'worker-1',
      );
    });

    test('default formatter includes all components', () {
      const formatter = LogFormatter();
      final formatted = formatter.format(record);

      expect(formatted, contains('[INFO'));
      expect(formatted, contains('(worker-1)'));
      expect(formatted, contains('test.logger:'));
      expect(formatted, contains('Test message'));
    });

    test('compact formatter excludes isolate and logger name', () {
      const formatter = CompactLogFormatter();
      final formatted = formatter.format(record);

      expect(formatted, contains('[INFO'));
      expect(formatted, isNot(contains('(worker-1)')));
      expect(formatted, isNot(contains('test.logger:')));
      expect(formatted, contains('Test message'));
    });

    test('simple formatter only includes level', () {
      const formatter = SimpleLogFormatter();
      final formatted = formatter.format(record);

      expect(formatted, contains('[INFO'));
      expect(formatted, isNot(contains('2025')));
      expect(formatted, contains('Test message'));
    });

    test('formatter includes error when present', () {
      final recordWithError = SerializableLogRecord(
        level: 1000,
        levelName: 'SEVERE',
        message: 'Error occurred',
        loggerName: 'test',
        time: DateTime.now().microsecondsSinceEpoch,
        isolateId: 'test',
        error: 'Something went wrong',
      );

      const formatter = LogFormatter();
      final formatted = formatter.format(recordWithError);

      expect(formatted, contains('Error: Something went wrong'));
    });

    test('pattern formatter replaces placeholders', () {
      const formatter = PatternLogFormatter('%l - %m [%i]');
      final formatted = formatter.format(record);

      expect(formatted, equals('INFO - Test message [worker-1]'));
    });
  });

  group('LogOutput', () {
    test('CallbackLogOutput calls callback', () {
      final records = <SerializableLogRecord>[];
      final output = CallbackLogOutput((record, formatted) {
        records.add(record);
      });

      final record = SerializableLogRecord(
        level: 800,
        levelName: 'INFO',
        message: 'Test',
        loggerName: 'test',
        time: DateTime.now().microsecondsSinceEpoch,
        isolateId: 'test',
      );

      output.write(record, 'formatted');

      expect(records.length, equals(1));
      expect(records.first.message, equals('Test'));
    });

    test('FilteredLogOutput filters records', () {
      final records = <SerializableLogRecord>[];
      final output = FilteredLogOutput(
        CallbackLogOutput((record, formatted) => records.add(record)),
        (record) => record.level >= 900, // WARNING and above
      );

      final infoRecord = SerializableLogRecord(
        level: 800, // INFO
        levelName: 'INFO',
        message: 'Info',
        loggerName: 'test',
        time: DateTime.now().microsecondsSinceEpoch,
        isolateId: 'test',
      );

      final warningRecord = SerializableLogRecord(
        level: 900, // WARNING
        levelName: 'WARNING',
        message: 'Warning',
        loggerName: 'test',
        time: DateTime.now().microsecondsSinceEpoch,
        isolateId: 'test',
      );

      output.write(infoRecord, 'info');
      output.write(warningRecord, 'warning');

      expect(records.length, equals(1));
      expect(records.first.message, equals('Warning'));
    });

    test('MultiLogOutput writes to all outputs', () {
      final records1 = <String>[];
      final records2 = <String>[];

      final output = MultiLogOutput([
        CallbackLogOutput((_, formatted) => records1.add(formatted)),
        CallbackLogOutput((_, formatted) => records2.add(formatted)),
      ]);

      final record = SerializableLogRecord(
        level: 800,
        levelName: 'INFO',
        message: 'Test',
        loggerName: 'test',
        time: DateTime.now().microsecondsSinceEpoch,
        isolateId: 'test',
      );

      output.write(record, 'formatted');

      expect(records1, equals(['formatted']));
      expect(records2, equals(['formatted']));
    });
  });

  group('CentralLogger', () {
    test('processes records above level', () {
      final records = <SerializableLogRecord>[];

      final logger = CentralLogger(
        config: CentralLoggerConfig(
          level: Level.WARNING,
          outputs: [CallbackLogOutput((record, _) => records.add(record))],
        ),
      );

      logger.start();

      // Below threshold
      logger.log(
        SerializableLogRecord(
          level: 800, // INFO
          levelName: 'INFO',
          message: 'Info',
          loggerName: 'test',
          time: DateTime.now().microsecondsSinceEpoch,
          isolateId: 'test',
        ),
      );

      // Above threshold
      logger.log(
        SerializableLogRecord(
          level: 900, // WARNING
          levelName: 'WARNING',
          message: 'Warning',
          loggerName: 'test',
          time: DateTime.now().microsecondsSinceEpoch,
          isolateId: 'test',
        ),
      );

      expect(records.length, equals(1));
      expect(records.first.message, equals('Warning'));
      expect(logger.recordsProcessed, equals(1));
      expect(logger.recordsFiltered, equals(1));
    });

    test('applies per-logger level overrides', () {
      final records = <SerializableLogRecord>[];

      final logger = CentralLogger(
        config: CentralLoggerConfig(
          level: Level.WARNING,
          loggerLevels: {'debug.component': Level.FINE},
          outputs: [CallbackLogOutput((record, _) => records.add(record))],
        ),
      );

      logger.start();

      // Regular logger at INFO - should be filtered
      logger.log(
        SerializableLogRecord(
          level: 800,
          levelName: 'INFO',
          message: 'Regular info',
          loggerName: 'regular.component',
          time: DateTime.now().microsecondsSinceEpoch,
          isolateId: 'test',
        ),
      );

      // Debug logger at FINE - should pass due to override
      logger.log(
        SerializableLogRecord(
          level: 500,
          levelName: 'FINE',
          message: 'Debug fine',
          loggerName: 'debug.component.sub',
          time: DateTime.now().microsecondsSinceEpoch,
          isolateId: 'test',
        ),
      );

      expect(records.length, equals(1));
      expect(records.first.message, equals('Debug fine'));
    });

    test('config parses from map', () {
      final config = CentralLoggerConfig.fromMap({
        'level': 'DEBUG',
        'console': true,
        'logger_levels': {'worker.dns': 'DEBUG'},
      });

      expect(config.level, equals(Level.FINE));
      expect(config.loggerLevels?['worker.dns'], equals(Level.FINE));
    });
  });

  group('IsolateLogBridge', () {
    test('forwards logs via SendPort', () async {
      final receivePort = ReceivePort();
      final completer = Completer<Map<String, dynamic>>();

      receivePort.listen((message) {
        if (message is Map<String, dynamic>) {
          completer.complete(message);
        }
      });

      final bridge = IsolateLogBridge(
        isolateId: 'test-worker',
        loggerPort: receivePort.sendPort,
        loggerPrefix: 'worker.test',
      );

      bridge.install();

      // Log something
      Logger('worker.test.component').info('Test message');

      final received = await completer.future.timeout(Duration(seconds: 1));

      expect(received['message'], equals('Test message'));
      expect(received['isolateId'], equals('test-worker'));
      expect(received['levelName'], equals('INFO'));

      bridge.uninstall();
      receivePort.close();
    });

    test('getLogger returns prefixed logger', () {
      final bridge = IsolateLogBridge(
        isolateId: 'test',
        loggerPort: ReceivePort().sendPort,
        loggerPrefix: 'worker.dns',
      );

      final logger = bridge.getLogger('cache');
      expect(logger.fullName, equals('worker.dns.cache'));
    });
  });
}
