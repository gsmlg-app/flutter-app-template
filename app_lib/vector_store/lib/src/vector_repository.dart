import 'dart:convert';
import 'dart:math' as math;

import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite_vector/sqlite_vector.dart';

import 'embedder/text_embedder.dart';
import 'vector_entry.dart';
import 'vector_store_config.dart';

/// Repository for storing and searching vector embeddings in SQLite.
///
/// Wraps `sqlite_vector` extension calls behind a clean Dart API,
/// with automatic in-memory fallback if the native extension cannot be loaded.
class VectorRepository {
  VectorRepository({required this.config, required this.embedder}) {
    _validateIdentifiers();
  }

  final VectorStoreConfig config;
  final TextEmbedder embedder;

  late Database _db;
  bool _initialized = false;
  bool _nativeVectorAvailable = false;

  static final _identifierRegex = RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$');

  void _validateIdentifiers() {
    if (!_identifierRegex.hasMatch(config.tableName)) {
      throw ArgumentError.value(
        config.tableName,
        'config.tableName',
        'Invalid SQL table name identifier',
      );
    }
    if (!_identifierRegex.hasMatch(config.embeddingColumn)) {
      throw ArgumentError.value(
        config.embeddingColumn,
        'config.embeddingColumn',
        'Invalid SQL column name identifier',
      );
    }
  }

  /// Loads the sqlite_vector extension (or falls back), creates the table,
  /// and initializes vector search for the configured column.
  void initialize(Database db) {
    _db = db;

    // Attempt to load the native sqlite_vector extension.
    try {
      sqlite3.loadSqliteVectorExtension();
      _nativeVectorAvailable = true;
    } catch (_) {
      _nativeVectorAvailable = false;
    }

    // Create the documents table if it doesn't exist.
    _db.execute('''
      CREATE TABLE IF NOT EXISTS ${config.tableName} (
        id INTEGER PRIMARY KEY,
        content TEXT NOT NULL,
        ${config.embeddingColumn} BLOB,
        metadata TEXT
      )
    ''');

    // Initialize vector search on the column if native extension is available.
    if (_nativeVectorAvailable) {
      try {
        _db.execute(
          "SELECT vector_init('${config.tableName}', '${config.embeddingColumn}', "
          "'${config.initOptions}')",
        );
      } catch (_) {
        _nativeVectorAvailable = false;
      }
    }

    _initialized = true;
  }

  void _assertInitialized() {
    if (!_initialized) {
      throw StateError(
        'VectorRepository not initialized. Call initialize() first.',
      );
    }
  }

  /// Converts a `List<double>` to a JSON string for `vector_as_f32()`.
  static String _vectorToJson(List<double> vector) => jsonEncode(vector);

  /// Inserts or updates a document with its computed embedding.
  ///
  /// The [embedder] is used to convert [content] into a vector.
  /// Pass [metadata] to store arbitrary key-value data alongside the document.
  /// Returns the row id.
  int upsert({
    required int id,
    required String content,
    Map<String, dynamic>? metadata,
  }) {
    _assertInitialized();

    final embedding = embedder.embed(content);
    final vectorJson = _vectorToJson(embedding);
    final metaJson = metadata != null ? jsonEncode(metadata) : null;

    _db.execute('BEGIN TRANSACTION');
    try {
      if (_nativeVectorAvailable) {
        _db.execute(
          '''INSERT OR REPLACE INTO ${config.tableName}
             (id, content, ${config.embeddingColumn}, metadata)
             VALUES (?, ?, vector_as_f32(?), ?)''',
          [id, content, vectorJson, metaJson],
        );
      } else {
        _db.execute(
          '''INSERT OR REPLACE INTO ${config.tableName}
             (id, content, ${config.embeddingColumn}, metadata)
             VALUES (?, ?, ?, ?)''',
          [id, content, vectorJson, metaJson],
        );
      }
      _db.execute('COMMIT');
    } catch (e) {
      _db.execute('ROLLBACK');
      rethrow;
    }

    return id;
  }

  /// Removes a document from the index.
  void delete(int id) {
    _assertInitialized();
    _db.execute('BEGIN TRANSACTION');
    try {
      _db.execute('DELETE FROM ${config.tableName} WHERE id = ?', [id]);
      _db.execute('COMMIT');
    } catch (e) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  /// Searches for the [limit] nearest neighbors to a text query.
  ///
  /// The [embedder] converts the query to a vector, then
  /// `vector_full_scan` (or fallback cosine distance) performs KNN search.
  List<VectorSearchResult> search(String query, {int limit = 10}) {
    _assertInitialized();

    final queryVector = embedder.embed(query);
    return searchByVector(queryVector, limit: limit);
  }

  /// Searches for the [limit] nearest neighbors to a raw vector.
  List<VectorSearchResult> searchByVector(
    List<double> vector, {
    int limit = 10,
  }) {
    _assertInitialized();

    final vectorJson = _vectorToJson(vector);

    if (_nativeVectorAvailable) {
      try {
        final results = _db.select(
          '''SELECT v.rowid AS id, v.distance, t.content, t.metadata
             FROM vector_full_scan('${config.tableName}', '${config.embeddingColumn}',
                  vector_as_f32(?), ?) AS v
             JOIN ${config.tableName} AS t ON t.id = v.rowid''',
          [vectorJson, limit],
        );

        return results.map((row) {
          return VectorSearchResult(
            id: row['id'] as int,
            distance: (row['distance'] as num).toDouble(),
            content: row['content'] as String?,
            metadata: VectorEntry.parseMetadata(row['metadata'] as String?),
          );
        }).toList();
      } catch (_) {
        // If native query fails at runtime, fall back to pure Dart computation
      }
    }

    // Pure Dart cosine distance fallback
    final rows = _db.select(
      'SELECT id, content, ${config.embeddingColumn}, metadata FROM ${config.tableName}',
    );

    final scored = <VectorSearchResult>[];
    for (final row in rows) {
      final rawEmbedding = row[config.embeddingColumn];
      List<double>? docVector;

      if (rawEmbedding is String) {
        try {
          final decoded = jsonDecode(rawEmbedding) as List<dynamic>;
          docVector = decoded.map((e) => (e as num).toDouble()).toList();
        } catch (_) {}
      }

      if (docVector == null || docVector.isEmpty) continue;

      final distance = _cosineDistance(vector, docVector);
      scored.add(
        VectorSearchResult(
          id: row['id'] as int,
          distance: distance,
          content: row['content'] as String?,
          metadata: VectorEntry.parseMetadata(row['metadata'] as String?),
        ),
      );
    }

    scored.sort((a, b) => a.distance.compareTo(b.distance));
    return scored.take(limit).toList();
  }

  static double _cosineDistance(List<double> a, List<double> b) {
    if (a.length != b.length || a.isEmpty) return 1.0;
    var dot = 0.0;
    var normA = 0.0;
    var normB = 0.0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA <= 0 || normB <= 0) return 1.0;
    final similarity = dot / (math.sqrt(normA) * math.sqrt(normB));
    return (1.0 - similarity).clamp(0.0, 2.0);
  }

  /// Quantizes vectors for faster approximate search on larger datasets.
  ///
  /// Call this after bulk insertions, then use [searchQuantized] instead
  /// of [search] for faster results.
  void quantize({String? options}) {
    _assertInitialized();
    if (!_nativeVectorAvailable) return;
    final opts = options != null ? ", '$options'" : '';
    _db.execute(
      "SELECT vector_quantize('${config.tableName}', '${config.embeddingColumn}'$opts)",
    );
  }

  /// Searches using the quantized index (faster, approximate).
  ///
  /// Requires [quantize] to have been called first.
  List<VectorSearchResult> searchQuantized(String query, {int limit = 10}) {
    _assertInitialized();

    if (!_nativeVectorAvailable) {
      return search(query, limit: limit);
    }

    final queryVector = embedder.embed(query);
    final vectorJson = _vectorToJson(queryVector);

    try {
      final results = _db.select(
        '''SELECT v.rowid AS id, v.distance, t.content, t.metadata
           FROM vector_quantize_scan('${config.tableName}', '${config.embeddingColumn}',
                vector_as_f32(?), ?) AS v
           JOIN ${config.tableName} AS t ON t.id = v.rowid''',
        [vectorJson, limit],
      );

      return results.map((row) {
        return VectorSearchResult(
          id: row['id'] as int,
          distance: (row['distance'] as num).toDouble(),
          content: row['content'] as String?,
          metadata: VectorEntry.parseMetadata(row['metadata'] as String?),
        );
      }).toList();
    } catch (_) {
      return search(query, limit: limit);
    }
  }
}
