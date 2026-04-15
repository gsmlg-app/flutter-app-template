import 'dart:math' as math;

import 'package:sqlite3/sqlite3.dart';

import 'text_embedder.dart';

/// A pure-Dart TF-IDF embedder that produces fixed-dimension vectors.
///
/// Vocabulary is persisted to a SQLite table so it survives app restarts.
/// This is intentionally simple — suitable for keyword-based note search,
/// replaceable with a semantic embedding model later.
class TfIdfEmbedder implements TextEmbedder {
  TfIdfEmbedder({
    required Database db,
    this.dimension = 128,
    this.vocabTable = '_tfidf_vocab',
  }) : _db = db {
    _ensureVocabTable();
    _loadVocabulary();
  }

  final Database _db;

  @override
  final int dimension;

  final String vocabTable;

  /// Maps token → column index in the vector (0..dimension-1).
  final Map<String, int> _vocab = {};

  /// Number of documents each token appears in (for IDF calculation).
  final Map<String, int> _docFreq = {};

  /// Total number of documents indexed.
  int _docCount = 0;

  void _ensureVocabTable() {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS $vocabTable (
        token TEXT PRIMARY KEY,
        slot INTEGER NOT NULL,
        doc_freq INTEGER NOT NULL DEFAULT 0
      )
    ''');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS ${vocabTable}_meta (
        key TEXT PRIMARY KEY,
        value INTEGER NOT NULL
      )
    ''');
  }

  void _loadVocabulary() {
    final rows = _db.select('SELECT token, slot, doc_freq FROM $vocabTable');
    for (final row in rows) {
      final token = row['token'] as String;
      final slot = row['slot'] as int;
      final docFreq = row['doc_freq'] as int;
      _vocab[token] = slot;
      _docFreq[token] = docFreq;
    }
    final meta = _db.select(
      "SELECT value FROM ${vocabTable}_meta WHERE key = 'doc_count'",
    );
    if (meta.isNotEmpty) {
      _docCount = meta.first['value'] as int;
    }
  }

  void _saveVocabulary() {
    _db.execute('DELETE FROM $vocabTable');
    final stmt = _db.prepare(
      'INSERT INTO $vocabTable (token, slot, doc_freq) VALUES (?, ?, ?)',
    );
    for (final entry in _vocab.entries) {
      stmt.execute([entry.key, entry.value, _docFreq[entry.key] ?? 0]);
    }
    stmt.close();

    _db.execute("DELETE FROM ${vocabTable}_meta WHERE key = 'doc_count'");
    _db.execute(
      "INSERT INTO ${vocabTable}_meta (key, value) VALUES ('doc_count', $_docCount)",
    );
  }

  /// Tokenizes text: lowercase, split on non-alphanumeric.
  static List<String> tokenize(String text) {
    return text
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((t) => t.length > 1)
        .toList();
  }

  /// Updates the vocabulary with tokens from a new document.
  ///
  /// Call this when indexing documents so the IDF weights stay current.
  void learn(String text) {
    final tokens = tokenize(text);
    final uniqueTokens = tokens.toSet();
    _docCount++;

    for (final token in uniqueTokens) {
      _docFreq[token] = (_docFreq[token] ?? 0) + 1;
      if (!_vocab.containsKey(token) && _vocab.length < dimension) {
        _vocab[token] = _vocab.length;
      }
    }
    _saveVocabulary();
  }

  /// Removes a document's contribution to term frequencies.
  void unlearn(String text) {
    final tokens = tokenize(text);
    final uniqueTokens = tokens.toSet();
    if (_docCount > 0) _docCount--;

    for (final token in uniqueTokens) {
      final freq = _docFreq[token];
      if (freq != null && freq > 0) {
        _docFreq[token] = freq - 1;
      }
    }
    _saveVocabulary();
  }

  @override
  List<double> embed(String text) {
    final tokens = tokenize(text);
    if (tokens.isEmpty) return List.filled(dimension, 0.0);

    // Compute term frequency
    final tf = <String, int>{};
    for (final token in tokens) {
      tf[token] = (tf[token] ?? 0) + 1;
    }

    // Build TF-IDF vector
    final vector = List.filled(dimension, 0.0);
    for (final entry in tf.entries) {
      final slot = _vocab[entry.key];
      if (slot == null) continue;

      final termFreq = entry.value / tokens.length;
      final docFreq = _docFreq[entry.key] ?? 0;
      final idf = _docCount > 0 && docFreq > 0
          ? math.log((_docCount + 1) / (docFreq + 1)) + 1
          : 1.0;
      vector[slot] = termFreq * idf;
    }

    // L2 normalize
    final norm = math.sqrt(vector.fold<double>(0.0, (sum, v) => sum + v * v));
    if (norm > 0) {
      for (var i = 0; i < vector.length; i++) {
        vector[i] /= norm;
      }
    }

    return vector;
  }

  @override
  void dispose() {
    // No resources to release; DB is managed externally.
  }
}
