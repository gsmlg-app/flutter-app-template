import 'dart:isolate';

import 'address.dart';

/// Wrapper for all inter-isolate messages.
class Envelope<T> {
  /// Unique message ID.
  final String id;

  /// Microsecond timestamp.
  final int timestamp;

  /// For request-response matching.
  final String? correlationId;

  /// Source isolate address.
  final IsolateAddress source;

  /// Target isolate address.
  final IsolateAddress target;

  /// Direct reply port.
  final SendPort? replyTo;

  /// Message payload.
  final T payload;

  /// Protocol version (default: 1).
  final int version;

  /// Option flags.
  final int flags;

  const Envelope({
    required this.id,
    required this.timestamp,
    this.correlationId,
    required this.source,
    required this.target,
    this.replyTo,
    required this.payload,
    this.version = 1,
    this.flags = 0,
  });

  /// Create envelope with current timestamp.
  factory Envelope.create({
    required String id,
    String? correlationId,
    required IsolateAddress source,
    required IsolateAddress target,
    SendPort? replyTo,
    required T payload,
    int flags = 0,
  }) {
    return Envelope(
      id: id,
      timestamp: DateTime.now().microsecondsSinceEpoch,
      correlationId: correlationId,
      source: source,
      target: target,
      replyTo: replyTo,
      payload: payload,
      flags: flags,
    );
  }

  /// Create a reply envelope.
  ///
  /// Uses the original correlationId if present, otherwise falls back to
  /// the original message id for correlation.
  Envelope<R> reply<R>(R payload, {required String id}) {
    return Envelope<R>(
      id: id,
      timestamp: DateTime.now().microsecondsSinceEpoch,
      correlationId: correlationId ?? this.id,
      source: target,
      target: source,
      payload: payload,
    );
  }

  /// Check if this envelope needs acknowledgment.
  bool get needsAck => (flags & EnvelopeFlags.needsAck) != 0;

  /// Check if this envelope is an acknowledgment.
  bool get isAck => (flags & EnvelopeFlags.isAck) != 0;

  /// Check if this is a priority message.
  bool get isPriority => (flags & EnvelopeFlags.priority) != 0;

  @override
  String toString() =>
      'Envelope(id: $id, from: $source, to: $target, payload: ${payload.runtimeType})';
}

/// Envelope flags for message options.
abstract class EnvelopeFlags {
  /// Message requires acknowledgment.
  static const int needsAck = 1 << 0;

  /// Message is an acknowledgment.
  static const int isAck = 1 << 1;

  /// Priority message.
  static const int priority = 1 << 2;
}
