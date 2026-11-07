import 'dart:async';
import 'dart:isolate';

import '../exception.dart';
import '../message/address.dart';
import '../message/envelope.dart';
import '../message/id_generator.dart';
import '../message/protocol.dart';
import 'registry.dart';

/// Configuration for spawning an isolate.
class SpawnConfig {
  final String role;
  final String name;
  final void Function(SendPort) entryPoint;
  final Map<String, dynamic>? config;
  final List<String> capabilities;
  final List<String> subscribesTo;
  final Duration timeout;

  const SpawnConfig({
    required this.role,
    required this.name,
    required this.entryPoint,
    this.config,
    this.capabilities = const [],
    this.subscribesTo = const [],
    this.timeout = const Duration(seconds: 30),
  });
}

/// Result of spawning an isolate.
class SpawnResult {
  final IsolateEntry entry;
  final bool success;
  final String? error;

  SpawnResult.success(this.entry) : success = true, error = null;

  SpawnResult.failure(this.error)
    : success = false,
      entry = throw StateError('No entry on failure');
}

/// Spawns and initializes isolates.
class IsolateSpawner {
  final SendPort? hubPort;
  final MessageIdGenerator idGenerator;

  int _spawnCounter = 0;

  IsolateSpawner({this.hubPort, required this.idGenerator});

  /// Spawn a new isolate with the given configuration.
  Future<IsolateEntry> spawn(SpawnConfig config) async {
    _spawnCounter++;
    final id = '${config.role}-$_spawnCounter';

    // Create control port for this isolate
    final controlPort = ReceivePort();

    // Convert to broadcast stream so multiple listeners can subscribe
    final broadcastStream = controlPort.asBroadcastStream();

    final completer = Completer<IsolateEntry>();

    // Listen for registration
    late StreamSubscription subscription;
    subscription = broadcastStream.listen((message) {
      if (message is Envelope && message.payload is Register) {
        final reg = message.payload as Register;
        final capabilities = reg.capabilities.isNotEmpty
            ? reg.capabilities
            : config.capabilities;
        final subscribesTo = reg.subscribesTo.isNotEmpty
            ? reg.subscribesTo
            : config.subscribesTo;

        final entry = IsolateEntry(
          id: id,
          name: config.name,
          role: config.role,
          isolate: Isolate.current, // Will be replaced
          sendPort: reg.port,
          controlPort: controlPort,
          broadcastStream: broadcastStream,
          capabilities: capabilities,
          subscribesTo: subscribesTo,
        );

        entry.state = IsolateState.starting;
        subscription.cancel();
        completer.complete(entry);
      }
    });

    // Spawn the isolate
    final isolate = await Isolate.spawn(
      _isolateEntryWrapper,
      _SpawnData(
        entryPoint: config.entryPoint,
        hubPort: controlPort.sendPort,
        id: id,
        name: config.name,
        role: config.role,
        capabilities: config.capabilities,
        subscribesTo: config.subscribesTo,
      ),
      debugName: config.name,
    );

    // Wait for registration with timeout
    try {
      final entry = await completer.future.timeout(config.timeout);

      // Replace the placeholder isolate with actual one
      return IsolateEntry(
        id: entry.id,
        name: entry.name,
        role: entry.role,
        isolate: isolate,
        sendPort: entry.sendPort,
        controlPort: entry.controlPort,
        broadcastStream: entry.broadcastStream,
        capabilities: entry.capabilities,
        subscribesTo: entry.subscribesTo,
      );
    } on TimeoutException {
      subscription.cancel();
      controlPort.close();
      isolate.kill(priority: Isolate.immediate);
      throw SpawnTimeoutException(config.name, config.timeout);
    }
  }

  /// Initialize an isolate after spawning.
  Future<void> initialize(
    IsolateEntry entry, {
    Map<String, dynamic>? config,
    Map<String, List<PortInfo>>? dependencies,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final completer = Completer<void>();

    // Listen for Ready message using broadcast stream
    late StreamSubscription subscription;
    subscription = entry.broadcastStream.listen((message) {
      if (message is Envelope && message.payload is Ready) {
        final ready = message.payload as Ready;
        subscription.cancel();

        if (ready.success) {
          entry.state = IsolateState.running;
          completer.complete();
        } else {
          entry.state = IsolateState.failed;
          completer.completeError(
            InitializationException(entry.id, ready.error ?? 'Unknown error'),
          );
        }
      }
    });

    // Send Init message
    final initEnvelope = Envelope.create(
      id: idGenerator.next(),
      source: IsolateAddress.hub,
      target: IsolateAddress.of(entry.role, entry.id),
      payload: Init(config: config ?? {}, dependencies: dependencies ?? {}),
    );

    entry.sendPort.send(initEnvelope);

    // Wait with timeout
    try {
      await completer.future.timeout(timeout);
    } on TimeoutException {
      subscription.cancel();
      entry.state = IsolateState.failed;
      throw InitializationException(entry.id, 'Initialization timed out');
    }
  }
}

/// Data passed to isolate entry wrapper.
class _SpawnData {
  final void Function(SendPort) entryPoint;
  final SendPort hubPort;
  final String id;
  final String name;
  final String role;
  final List<String> capabilities;
  final List<String> subscribesTo;

  _SpawnData({
    required this.entryPoint,
    required this.hubPort,
    required this.id,
    required this.name,
    required this.role,
    this.capabilities = const [],
    this.subscribesTo = const [],
  });
}

/// Wrapper entry point that sets up communication.
void _isolateEntryWrapper(_SpawnData data) {
  runZoned(
    () => data.entryPoint(data.hubPort),
    zoneValues: {
      #isolateSpawnMeta: <String, Object>{
        'id': data.id,
        'name': data.name,
        'role': data.role,
        'capabilities': data.capabilities,
        'subscribesTo': data.subscribesTo,
      },
    },
  );
}
