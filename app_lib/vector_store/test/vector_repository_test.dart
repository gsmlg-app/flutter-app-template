import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite_vector/sqlite_vector.dart';
import 'package:test/test.dart';
import 'package:vector_store/vector_store.dart';

/// Returns true if the sqlite_vector native extension is available.
bool _extensionAvailable() {
  try {
    final db = sqlite3.openInMemory();
    try {
      sqlite3.loadSqliteVectorExtension();
      db.select('SELECT vector_version()');
      return true;
    } catch (_) {
      return false;
    } finally {
      db.close();
    }
  } catch (_) {
    return false;
  }
}

void main() {
  final hasExtension = _extensionAvailable();

  const config = VectorStoreConfig(
    tableName: 'documents',
    dimension: 128,
    distanceMetric: DistanceMetric.cosine,
  );

  group('VectorRepository', () {
    late Database db;
    late TfIdfEmbedder embedder;
    late VectorRepository repository;

    setUp(() {
      db = sqlite3.openInMemory();
      embedder = TfIdfEmbedder(db: db, dimension: config.dimension);
      repository = VectorRepository(config: config, embedder: embedder);
      repository.initialize(db);
    });

    tearDown(() {
      embedder.dispose();
      db.close();
    });

    test('initialize creates table', () {
      final result = db.select(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='documents'",
      );
      expect(result, hasLength(1));
    });

    test('upsert inserts a document', () {
      embedder.learn('hello world');
      repository.upsert(id: 1, content: 'hello world');

      final rows = db.select('SELECT id, content FROM documents WHERE id = 1');
      expect(rows, hasLength(1));
      expect(rows.first['content'], 'hello world');
    });

    test('upsert with metadata stores JSON', () {
      embedder.learn('test document');
      repository.upsert(
        id: 1,
        content: 'test document',
        metadata: {'source': 'unit_test', 'priority': 1},
      );

      final rows = db.select('SELECT metadata FROM documents WHERE id = 1');
      expect(rows.first['metadata'], contains('unit_test'));
    });

    test('upsert replaces existing document', () {
      embedder.learn('original content');
      repository.upsert(id: 1, content: 'original content');

      embedder.learn('updated content');
      repository.upsert(id: 1, content: 'updated content');

      final rows = db.select('SELECT content FROM documents WHERE id = 1');
      expect(rows, hasLength(1));
      expect(rows.first['content'], 'updated content');
    });

    test('delete removes a document', () {
      embedder.learn('to be deleted');
      repository.upsert(id: 1, content: 'to be deleted');
      repository.delete(1);

      final rows = db.select('SELECT id FROM documents WHERE id = 1');
      expect(rows, isEmpty);
    });

    test('search returns ranked results', () {
      final docs = {
        1: 'flutter dart mobile development',
        2: 'python machine learning data science',
        3: 'dart programming language flutter widgets',
        4: 'cooking recipes pasta italian food',
      };

      for (final entry in docs.entries) {
        embedder.learn(entry.value);
      }
      for (final entry in docs.entries) {
        repository.upsert(id: entry.key, content: entry.value);
      }

      final results = repository.search('flutter dart', limit: 4);
      expect(results, isNotEmpty);
      expect(results.first.id, isIn([1, 3]));
    });

    test('search results are ordered by distance ascending', () {
      final docs = {
        1: 'alpha beta gamma',
        2: 'alpha beta delta',
        3: 'epsilon zeta eta',
      };

      for (final entry in docs.entries) {
        embedder.learn(entry.value);
      }
      for (final entry in docs.entries) {
        repository.upsert(id: entry.key, content: entry.value);
      }

      final results = repository.search('alpha beta', limit: 3);
      expect(results.length, greaterThanOrEqualTo(2));

      for (var i = 1; i < results.length; i++) {
        expect(
          results[i].distance,
          greaterThanOrEqualTo(results[i - 1].distance),
        );
      }
    });

    test('search returns content and metadata', () {
      embedder.learn('hello world');
      repository.upsert(
        id: 1,
        content: 'hello world',
        metadata: {'tag': 'greeting'},
      );

      final results = repository.search('hello', limit: 1);
      expect(results, hasLength(1));
      expect(results.first.content, 'hello world');
      expect(results.first.metadata?['tag'], 'greeting');
    });

    test('searchByVector works with raw vectors', () {
      embedder.learn('test document');
      repository.upsert(id: 1, content: 'test document');

      final vector = embedder.embed('test document');
      final results = repository.searchByVector(vector, limit: 1);
      expect(results, hasLength(1));
      expect(results.first.id, 1);
    });

    test('throws when not initialized', () {
      final uninitRepo = VectorRepository(config: config, embedder: embedder);
      expect(() => uninitRepo.search('test'), throwsA(isA<StateError>()));
    });

    test('validates SQL identifiers', () {
      expect(
        () => VectorRepository(
          config: const VectorStoreConfig(
            tableName: 'invalid table; DROP TABLE x;',
            dimension: 128,
          ),
          embedder: embedder,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('TfIdfEmbedder', () {
    late Database db;
    late TfIdfEmbedder embedder;

    setUp(() {
      db = sqlite3.openInMemory();
      embedder = TfIdfEmbedder(db: db, dimension: config.dimension);
    });

    tearDown(() {
      embedder.dispose();
      db.close();
    });

    test('produces consistent vectors for same input', () {
      embedder.learn('hello world');
      final v1 = embedder.embed('hello world');
      final v2 = embedder.embed('hello world');

      expect(v1, equals(v2));
    });

    test('produces vectors of correct dimension', () {
      embedder.learn('some text here');
      final vector = embedder.embed('some text here');
      expect(vector.length, config.dimension);
    });

    test('produces normalized vectors', () {
      embedder.learn('normalize this vector please');
      final vector = embedder.embed('normalize this vector please');

      final norm = vector.fold<double>(0.0, (sum, v) => sum + v * v);
      if (norm > 0) {
        expect(norm, closeTo(1.0, 0.001));
      }
    });

    test('empty input produces zero vector', () {
      final vector = embedder.embed('');
      expect(vector.every((v) => v == 0.0), isTrue);
    });

    test('vocabulary persists across instances', () {
      embedder.learn('persistent vocabulary test');
      final v1 = embedder.embed('persistent vocabulary test');

      final embedder2 = TfIdfEmbedder(db: db, dimension: config.dimension);
      final v2 = embedder2.embed('persistent vocabulary test');
      embedder2.dispose();

      expect(v1, equals(v2));
    });

    test('tokenize splits Latin and preserves CJK characters', () {
      final tokens = TfIdfEmbedder.tokenize('Flutter 模板 跨平台 开发 Test-123.');
      expect(
        tokens,
        containsAll([
          'flutter',
          '模',
          '板',
          '跨',
          '平',
          '台',
          '开',
          '发',
          'test',
          '123',
        ]),
      );
      expect(tokens, isNot(contains('.')));
    });

    test('embeds CJK text with correct non-zero vector', () {
      embedder.learn('跨平台应用开发');
      final vector = embedder.embed('应用开发');
      final norm = vector.fold<double>(0.0, (sum, v) => sum + v * v);
      expect(norm, greaterThan(0.0));
    });
  });
}
