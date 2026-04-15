import 'dart:convert';

/// A document stored in the vector index.
class VectorEntry {
  const VectorEntry({
    required this.id,
    required this.content,
    required this.embedding,
    this.metadata,
  });

  final int id;
  final String content;
  final List<double> embedding;
  final Map<String, dynamic>? metadata;

  /// Serializes metadata to JSON string for SQLite storage.
  String? get metadataJson => metadata != null ? jsonEncode(metadata) : null;

  /// Deserializes metadata from JSON string.
  static Map<String, dynamic>? parseMetadata(String? json) =>
      json != null ? jsonDecode(json) as Map<String, dynamic> : null;
}

/// A search result with distance score.
class VectorSearchResult {
  const VectorSearchResult({
    required this.id,
    required this.distance,
    this.content,
    this.metadata,
  });

  final int id;
  final double distance;
  final String? content;
  final Map<String, dynamic>? metadata;
}
