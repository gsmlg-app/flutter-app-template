/// Data model for ClientInfo.
class ClientInfoData {
  /// Creates a ClientInfoData instance.
  const ClientInfoData({
    required this.platform,
    required this.timestamp,
    this.additionalData = const {},
  });

  /// The platform name (e.g., 'android', 'ios', 'linux').
  final String platform;

  /// The timestamp when this data was collected.
  final DateTime timestamp;

  /// Additional platform-specific data.
  final Map<String, dynamic> additionalData;

  /// Creates a ClientInfoData from a map.
  factory ClientInfoData.fromMap(Map<String, dynamic> map) {
    return ClientInfoData(
      platform: map['platform'] as String? ?? 'unknown',
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'] as String)
          : DateTime.now(),
      additionalData: Map<String, dynamic>.from(
        (map['additionalData'] as Map<dynamic, dynamic>?) ?? {},
      ),
    );
  }

  /// Converts this ClientInfoData to a map.
  Map<String, dynamic> toMap() {
    return {
      'platform': platform,
      'timestamp': timestamp.toIso8601String(),
      'additionalData': additionalData,
    };
  }

  @override
  String toString() {
    return 'ClientInfoData(platform: $platform, timestamp: $timestamp, additionalData: $additionalData)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ClientInfoData &&
        other.platform == platform &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => platform.hashCode ^ timestamp.hashCode;
}
