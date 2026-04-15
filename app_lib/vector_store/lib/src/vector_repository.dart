import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite_vector/sqlite_vector.dart';

import 'embedder/text_embedder.dart';
import 'vector_entry.dart';
import 'vector_store_config.dart';

/// Repository for storing and searching vector embeddings in SQLite.
///
/// Wraps `sqlite_vector` extension calls behind a clean Dart API.
class VectorRepository {
  VectorRepository({required this.config, required this.embedder});

  final VectorStoreConfig config;
  final TextEmbedder embedder;

  late Database _db;
  bool _initialized = false;

  /// Loads the sqlite_vector extension, creates the table, and
  /// initializes vector search for the configured column.
  void initialize(Database db) {
    _db = db;

    // Load the native sqlite_vector extension.
    sqlite3.loadSqliteVectorExtension();

    // Create the documents table if it doesn't exist.
    _db.execute('''
      CREATE TABLE IF NOT EXISTS ${config.tableName} (
        id INTEGER PRIMARY KEY,
        content TEXT NOT NULL,
        ${config.embeddingColumn} BLOB,
        metadata TEXT
      )
    ''');

    // Initialize vector search on the column.
    _db.execute(
      "SELECT vector_init('${config.tableName}', '${config.embeddingColumn}', "
      "'${config.initOptions}')",
    );

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

    _db.execute(
      '''INSERT OR REPLACE INTO ${config.tableName}
         (id, content, ${config.embeddingColumn}, metadata)
         VALUES (?, ?, vector_as_f32(?), ?)''',
      [id, content, vectorJson, metaJson],
    );
    return id;
  }

  /// Removes a document from the index.
  void delete(int id) {
    _assertInitialized();
    _db.execute('DELETE FROM ${config.tableName} WHERE id = ?', [id]);
  }

  /// Searches for the [limit] nearest neighbors to a text query.
  ///
  /// The [embedder] converts the query to a vector, then
  /// `vector_full_scan` performs KNN search.
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
  }

  /// Quantizes vectors for faster approximate search on larger datasets.
  ///
  /// Call this after bulk insertions, then use [searchQuantized] instead
  /// of [search] for faster results.
  void quantize({String? options}) {
    _assertInitialized();
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

    final queryVector = embedder.embed(query);
    final vectorJson = _vectorToJson(queryVector);

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
  }
}
