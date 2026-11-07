/// Isolate health metrics.
class IsolateMetrics {
  /// Uptime in milliseconds.
  final int uptimeMs;

  /// Number of processed tasks.
  final int processedCount;

  /// Number of pending tasks.
  final int pendingCount;

  /// Number of errors encountered.
  final int errorCount;

  /// Average latency in microseconds.
  final int avgLatencyUs;

  /// Memory usage in bytes (if available).
  final int? memoryBytes;

  /// Custom application-specific metrics.
  final Map<String, dynamic>? custom;

  const IsolateMetrics({
    required this.uptimeMs,
    required this.processedCount,
    required this.pendingCount,
    required this.errorCount,
    required this.avgLatencyUs,
    this.memoryBytes,
    this.custom,
  });

  /// Create empty metrics.
  factory IsolateMetrics.empty() => const IsolateMetrics(
    uptimeMs: 0,
    processedCount: 0,
    pendingCount: 0,
    errorCount: 0,
    avgLatencyUs: 0,
  );

  /// Calculate error rate.
  double get errorRate {
    final total = processedCount + errorCount;
    return total > 0 ? errorCount / total : 0.0;
  }

  /// Create copy with updated values.
  IsolateMetrics copyWith({
    int? uptimeMs,
    int? processedCount,
    int? pendingCount,
    int? errorCount,
    int? avgLatencyUs,
    int? memoryBytes,
    Map<String, dynamic>? custom,
  }) {
    return IsolateMetrics(
      uptimeMs: uptimeMs ?? this.uptimeMs,
      processedCount: processedCount ?? this.processedCount,
      pendingCount: pendingCount ?? this.pendingCount,
      errorCount: errorCount ?? this.errorCount,
      avgLatencyUs: avgLatencyUs ?? this.avgLatencyUs,
      memoryBytes: memoryBytes ?? this.memoryBytes,
      custom: custom ?? this.custom,
    );
  }

  @override
  String toString() =>
      'IsolateMetrics(uptime: ${uptimeMs}ms, processed: $processedCount, pending: $pendingCount, errors: $errorCount)';
}
