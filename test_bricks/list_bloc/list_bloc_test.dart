import 'dart:io';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('List BLoC Brick Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('list_bloc_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('generates list BLoC package with correct structure', () async {
      final brick = Brick.path(path.join('..', '..', 'bricks', 'list_bloc'));

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: {'name': 'users'},
      );

      final expectedFiles = [
        'pubspec.yaml',
        'lib/users_bloc.dart',
        'lib/src/bloc.dart',
        'lib/src/event.dart',
        'lib/src/state.dart',
        'test/users_bloc_test.dart',
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
      final brick = Brick.path(path.join('..', '..', 'bricks', 'list_bloc'));

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: {'name': 'products'},
      );

      final pubspecFile = File(path.join(tempDir.path, 'pubspec.yaml'));
      expect(await pubspecFile.exists(), isTrue);

      final pubspecContent = await pubspecFile.readAsString();

      // Check package name
      expect(pubspecContent, contains('name: products_bloc'));

      // Check dependencies
      expect(pubspecContent, contains('bloc:'));
      expect(pubspecContent, contains('equatable:'));

      // Check dev dependencies
      expect(pubspecContent, contains('bloc_test:'));
      expect(pubspecContent, contains('mocktail:'));
    });

    test('generates BLoC file with correct structure', () async {
      final brick = Brick.path(path.join('..', '..', 'bricks', 'list_bloc'));

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: {'name': 'orders'},
      );

      final blocFile = File(path.join(tempDir.path, 'lib', 'src', 'bloc.dart'));
      expect(await blocFile.exists(), isTrue);

      final blocContent = await blocFile.readAsString();
      expect(blocContent, contains('class OrdersBloc'));
      expect(blocContent, contains('extends Bloc<OrdersEvent, OrdersState>'));
    });

    test('generates event file with correct structure', () async {
      final brick = Brick.path(path.join('..', '..', 'bricks', 'list_bloc'));

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: {'name': 'tasks'},
      );

      final eventFile = File(path.join(tempDir.path, 'lib', 'src', 'event.dart'));
      expect(await eventFile.exists(), isTrue);

      final eventContent = await eventFile.readAsString();
      expect(eventContent, contains('TasksEvent'));
    });

    test('generates state file with correct structure', () async {
      final brick = Brick.path(path.join('..', '..', 'bricks', 'list_bloc'));

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: {'name': 'comments'},
      );

      final stateFile = File(path.join(tempDir.path, 'lib', 'src', 'state.dart'));
      expect(await stateFile.exists(), isTrue);

      final stateContent = await stateFile.readAsString();
      expect(stateContent, contains('CommentsState'));
      expect(stateContent, contains('extends Equatable'));
    });

    test('generates correct main export file', () async {
      final brick = Brick.path(path.join('..', '..', 'bricks', 'list_bloc'));

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: {'name': 'notifications'},
      );

      final mainFile = File(path.join(tempDir.path, 'lib', 'notifications_bloc.dart'));
      expect(await mainFile.exists(), isTrue);

      final mainContent = await mainFile.readAsString();
      expect(mainContent, contains("export 'src/bloc.dart'"));
    });

    test('generates test file with correct structure', () async {
      final brick = Brick.path(path.join('..', '..', 'bricks', 'list_bloc'));

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: {'name': 'documents'},
      );

      final testFile = File(path.join(tempDir.path, 'test', 'documents_bloc_test.dart'));
      expect(await testFile.exists(), isTrue);

      final testContent = await testFile.readAsString();
      expect(testContent, contains("import 'package:bloc_test/bloc_test.dart'"));
      expect(testContent, contains('DocumentsBloc'));
    });

    test('handles different naming conventions', () async {
      final brick = Brick.path(path.join('..', '..', 'bricks', 'list_bloc'));

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: {'name': 'user_profiles'},
      );

      final blocFile = File(path.join(tempDir.path, 'lib', 'src', 'bloc.dart'));
      final blocContent = await blocFile.readAsString();
      expect(blocContent, contains('class UserProfilesBloc'));
    });
  });
}
