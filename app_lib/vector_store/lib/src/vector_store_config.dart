/// Distance metric for vector similarity search.
enum DistanceMetric {
  cosine('COSINE'),
  l2('L2'),
  squaredL2('SQUARED_L2'),
  l1('L1'),
  dot('DOT');

  const DistanceMetric(this.sqlValue);
  final String sqlValue;
}

/// Configuration for vector storage and search.
class VectorStoreConfig {
  const VectorStoreConfig({
    required this.tableName,
    required this.dimension,
    this.embeddingColumn = 'embedding',
    this.vectorType = 'FLOAT32',
    this.distanceMetric = DistanceMetric.cosine,
  });

  final String tableName;
  final String embeddingColumn;
  final int dimension;
  final String vectorType;
  final DistanceMetric distanceMetric;

  /// Generates the options string for `vector_init()`.
  String get initOptions =>
      'type=$vectorType,dimension=$dimension,distance=${distanceMetric.sqlValue}';
}
