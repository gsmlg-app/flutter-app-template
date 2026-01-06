import 'dart:io';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('API Client Brick Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('api_client_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('generates API client package with correct structure', () async {
      final brick = Brick.path(path.join('..', '..', 'bricks', 'api_client'));

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: {'package_name': 'test_api'},
      );

      final expectedFiles = [
        'pubspec.yaml',
        'lib/test_api.dart',
        'lib/openapi.yaml',
        'swagger_parser.yaml',
        'test/test_api_test.dart',
      ];

      for (final expectedFile in expectedFiles) {
        final file = File(path.join(tempDir.path, expectedFile));
        expect(
          await file.exists(),
          isTrue,
          reason: '$expectedFile should exist',
        );
      }
    });

    test('generates valid pubspec.yaml with correct dependencies', () async {
      final brick = Brick.path(path.join('..', '..', 'bricks', 'api_client'));

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: {'package_name': 'test_api'},
      );

      final pubspecFile = File(path.join(tempDir.path, 'pubspec.yaml'));
      expect(await pubspecFile.exists(), isTrue);

      final pubspecContent = await pubspecFile.readAsString();

      // Check package name
      expect(pubspecContent, contains('name: test_api'));

      // Check dependencies
      expect(pubspecContent, contains('dio:'));
      expect(pubspecContent, contains('json_annotation:'));
      expect(pubspecContent, contains('retrofit:'));

      // Check dev dependencies
      expect(pubspecContent, contains('build_runner:'));
      expect(pubspecContent, contains('swagger_parser:'));
    });

    test('generates correct main library file', () async {
      final brick = Brick.path(path.join('..', '..', 'bricks', 'api_client'));

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: {'package_name': 'test_api'},
      );

      final libFile = File(path.join(tempDir.path, 'lib/test_api.dart'));
      expect(await libFile.exists(), isTrue);

      final libContent = await libFile.readAsString();
      expect(libContent, contains('library test_api;'));
    });

    test('generates OpenAPI template file', () async {
      final brick = Brick.path(path.join('..', '..', 'bricks', 'api_client'));

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: {'package_name': 'test_api'},
      );

      final openapiFile = File(path.join(tempDir.path, 'lib/openapi.yaml'));
      expect(await openapiFile.exists(), isTrue);

      final openapiContent = await openapiFile.readAsString();
      expect(openapiContent, contains('openapi: 3.0.0'));
      expect(openapiContent, contains('title: API Specification'));
    });

    test('generates swagger_parser configuration', () async {
      final brick = Brick.path(path.join('..', '..', 'bricks', 'api_client'));

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: {'package_name': 'test_api'},
      );

      final swaggerFile = File(path.join(tempDir.path, 'swagger_parser.yaml'));
      expect(await swaggerFile.exists(), isTrue);

      final swaggerContent = await swaggerFile.readAsString();
      expect(swaggerContent, contains('schema_path: ./lib/openapi.yaml'));
      expect(swaggerContent, contains('output_directory: lib/src'));
      expect(swaggerContent, contains('name: TestApi'));
    });

    test('generates test file with correct structure', () async {
      final brick = Brick.path(path.join('..', '..', 'bricks', 'api_client'));

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: {'package_name': 'test_api'},
      );

      final testFile = File(path.join(tempDir.path, 'test/test_api_test.dart'));
      expect(await testFile.exists(), isTrue);

      final testContent = await testFile.readAsString();
      expect(testContent, contains("import 'package:test_api/test_api.dart';"));
      expect(testContent, contains("import 'package:test/test.dart';"));
      expect(testContent, contains("import 'package:dio/dio.dart';"));
    });

    test('handles different package names correctly', () async {
      final brick = Brick.path(path.join('..', '..', 'bricks', 'api_client'));

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: {'package_name': 'user_service_api'},
      );

      final pubspecFile = File(path.join(tempDir.path, 'pubspec.yaml'));
      final pubspecContent = await pubspecFile.readAsString();
      expect(pubspecContent, contains('name: user_service_api'));

      final libFile = File(
        path.join(tempDir.path, 'lib/user_service_api.dart'),
      );
      expect(await libFile.exists(), isTrue);
    });
  });
}
