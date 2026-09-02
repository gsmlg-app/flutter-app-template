import 'dart:io';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('Form BLoC Brick Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('form_bloc_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('generates form bloc package with correct structure', () async {
      final brick = Brick.path(path.join('bricks', 'form_bloc'));

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: {
          'name': 'test_form',
          'output_directory': 'app_bloc',
          'fields': ['email:email', 'password:password'],
        },
      );

      final expectedFiles = [
        'pubspec.yaml',
        'lib/test_form_form_bloc.dart',
        'lib/src/bloc.dart',
        'test/test_form_form_bloc_test.dart',
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
      final brick = Brick.path(path.join('bricks', 'form_bloc'));

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: {
          'name': 'test_form',
          'output_directory': 'app_bloc',
          'fields': ['email:email', 'password:password'],
        },
      );

      final pubspecFile = File(path.join(tempDir.path, 'pubspec.yaml'));
      expect(await pubspecFile.exists(), isTrue);

      final pubspecContent = await pubspecFile.readAsString();

      // Check package name
      expect(pubspecContent, contains('name: test_form_form_bloc'));

      // Check dependencies
      expect(pubspecContent, contains('duskmoon_form:'));

      // Check dev dependencies
      expect(pubspecContent, contains('bloc_test:'));
      expect(pubspecContent, contains('mocktail:'));
    });

    test('generates correct main library file', () async {
      final brick = Brick.path(path.join('bricks', 'form_bloc'));

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: {
          'name': 'test_form',
          'output_directory': 'app_bloc',
          'fields': ['email:email', 'password:password'],
        },
      );

      final libFile = File(
        path.join(tempDir.path, 'lib', 'test_form_form_bloc.dart'),
      );
      expect(await libFile.exists(), isTrue);

      final libContent = await libFile.readAsString();
      expect(libContent, contains("export 'src/bloc.dart';"));
    });

    test('generates BLoC file with correct structure', () async {
      final brick = Brick.path(path.join('bricks', 'form_bloc'));

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: {
          'name': 'test_form',
          'output_directory': 'app_bloc',
          'fields': ['email:email', 'password:password'],
        },
      );

      final blocFile = File(path.join(tempDir.path, 'lib', 'src', 'bloc.dart'));
      expect(await blocFile.exists(), isTrue);

      final blocContent = await blocFile.readAsString();
      expect(blocContent, contains('class TestFormFormBloc'));
      expect(blocContent, contains('extends FormBloc<String, String>'));
      expect(blocContent, contains('onSubmitting'));
      expect(blocContent, contains('getFormData'));
    });

    test('generates main export file with correct structure', () async {
      final brick = Brick.path(path.join('bricks', 'form_bloc'));

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: {
          'name': 'test_form',
          'output_directory': 'app_bloc',
          'fields': ['email:email', 'password:password'],
        },
      );

      final mainFile = File(
        path.join(tempDir.path, 'lib', 'test_form_form_bloc.dart'),
      );
      expect(await mainFile.exists(), isTrue);

      final content = await mainFile.readAsString();
      expect(content, contains("export 'src/bloc.dart';"));
    });

    test('handles different naming conventions', () async {
      final brick = Brick.path(path.join('bricks', 'form_bloc'));

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: {
          'name': 'user_registration',
          'output_directory': 'app_bloc',
          'fields': ['email:email', 'password:password'],
        },
      );

      final blocFile = File(path.join(tempDir.path, 'lib', 'src', 'bloc.dart'));

      final blocContent = await blocFile.readAsString();
      expect(blocContent, contains('class UserRegistrationFormBloc'));
      expect(blocContent, contains('extends FormBloc<String, String>'));
    });

    test('generates test file with correct structure', () async {
      final brick = Brick.path(path.join('bricks', 'form_bloc'));

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: {
          'name': 'test_form',
          'output_directory': 'app_bloc',
          'fields': ['email:email', 'password:password'],
        },
      );

      final testFile = File(
        path.join(tempDir.path, 'test', 'test_form_form_bloc_test.dart'),
      );
      expect(await testFile.exists(), isTrue);

      final testContent = await testFile.readAsString();
      expect(
        testContent,
        contains("import 'package:flutter_test/flutter_test.dart'"),
      );
      expect(
        testContent,
        contains("import 'package:bloc_test/bloc_test.dart'"),
      );
      expect(testContent, contains("group('TestFormFormBloc'"));
    });
  });
}
