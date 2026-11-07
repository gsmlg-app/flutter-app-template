/// Identifies an isolate in the system.
class IsolateAddress {
  /// Role name (e.g., "worker", "logger")
  final String role;

  /// Instance ID (e.g., "worker-1")
  final String id;

  const IsolateAddress({required this.role, required this.id});

  /// Predefined address for the hub isolate.
  static const hub = IsolateAddress(role: 'hub', id: 'hub');

  /// Predefined address for broadcast to all isolates.
  static const broadcast = IsolateAddress(role: '*', id: '*');

  /// Create address for a role instance.
  factory IsolateAddress.of(String role, String id) =>
      IsolateAddress(role: role, id: id);

  /// Create worker address with index.
  factory IsolateAddress.worker(int index) =>
      IsolateAddress(role: 'worker', id: 'worker-$index');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IsolateAddress && role == other.role && id == other.id;

  @override
  int get hashCode => Object.hash(role, id);

  @override
  String toString() => 'IsolateAddress($role:$id)';
}
