/// Generates unique message IDs.
///
/// Format: {prefix}-{timestamp_base36}-{sequence_hex}
/// Example: "worker1-2xf8k9m-0042"
class MessageIdGenerator {
  final String _prefix;
  int _lastMs = 0;
  int _seq = 0;

  MessageIdGenerator(this._prefix);

  /// Generate next unique ID.
  String next() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs == _lastMs) {
      _seq = (_seq + 1) & 0xFFFF;
    } else {
      _lastMs = nowMs;
      _seq = 0;
    }
    return '$_prefix-${nowMs.toRadixString(36)}-${_seq.toRadixString(16).padLeft(4, '0')}';
  }

  /// Generate ID with custom suffix.
  String nextWith(String suffix) => '${next()}-$suffix';
}
