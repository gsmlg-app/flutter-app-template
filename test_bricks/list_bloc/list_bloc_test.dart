import 'dart:io';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

/// Default variables for list_bloc brick tests.
Map<String, dynamic> defaultVars(String name, {String itemType = 'Item'}) => {
      'name': name,
      'item_type': itemType,
      'has_pagination': true,
      'has_search': true,
      'has_filters': true,
      'has_reorder': false,
      'has_crud': true,
      'filter_types': ['category', 'status'],
      'sort_options': ['name', 'date'],
      'output_directory': 'app_bloc',
    };

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
      final brick = Brick.path(path.join('bricks', 'list_bloc'));

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: defaultVars('users', itemType: 'User'),
      );

      final expectedFiles = [
        'pubspec.yaml',
        'lib/users_list_bloc.dart',
        'lib/src/bloc.dart',
        'lib/src/event.dart',
        'lib/src/state.dart',
        'lib/src/schema.dart',
        'lib/src/item_state.dart',
        'test/users_list_bloc_test.dart',
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
      final brick = Brick.path(path.join('bricks', 'list_bloc'));

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: defaultVars('products', itemType: 'Product'),
      );

      final pubspecFile = File(path.join(tempDir.path, 'pubspec.yaml'));
      expect(await pubspecFile.exists(), isTrue);

      final pubspecContent = await pubspecFile.readAsString();

      // Check package name (list_bloc uses _list_bloc suffix)
      expect(pubspecContent, contains('name: products_list_bloc'));

      // Check dependencies
      expect(pubspecContent, contains('bloc:'));
      expect(pubspecContent, contains('equatable:'));

      // Check dev dependencies
      expect(pubspecContent, contains('bloc_test:'));
      expect(pubspecContent, contains('mocktail:'));
    });

    test('generates BLoC file with correct structure', () async {
      final brick = Brick.path(path.join('bricks', 'list_bloc'));

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: defaultVars('orders', itemType: 'Order'),
      );

      final blocFile = File(path.join(tempDir.path, 'lib', 'src', 'bloc.dart'));
      expect(await blocFile.exists(), isTrue);

      final blocContent = await blocFile.readAsString();
      expect(blocContent, contains('class OrdersListBloc'));
      expect(blocContent, contains('Bloc<OrdersListEvent, OrdersListState>'));
    });

    test('generates event file with correct structure', () async {
      final brick = Brick.path(path.join('bricks', 'list_bloc'));

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: defaultVars('tasks', itemType: 'Task'),
      );

      final eventFile = File(path.join(tempDir.path, 'lib', 'src', 'event.dart'));
      expect(await eventFile.exists(), isTrue);

      final eventContent = await eventFile.readAsString();
      expect(eventContent, contains('TasksListEvent'));
    });

    test('generates state file with correct structure', () async {
      final brick = Brick.path(path.join('bricks', 'list_bloc'));

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: defaultVars('comments', itemType: 'Comment'),
      );

      final stateFile = File(path.join(tempDir.path, 'lib', 'src', 'state.dart'));
      expect(await stateFile.exists(), isTrue);

      final stateContent = await stateFile.readAsString();
      expect(stateContent, contains('CommentsListState'));
      expect(stateContent, contains('Equatable'));
    });

    test('generates correct main export file', () async {
      final brick = Brick.path(path.join('bricks', 'list_bloc'));

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: defaultVars('notifications', itemType: 'Notification'),
      );

      final mainFile = File(path.join(tempDir.path, 'lib', 'notifications_list_bloc.dart'));
      expect(await mainFile.exists(), isTrue);

      final mainContent = await mainFile.readAsString();
      expect(mainContent, contains("export 'src/bloc.dart'"));
    });

    test('generates test file with correct structure', () async {
      final brick = Brick.path(path.join('bricks', 'list_bloc'));

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: defaultVars('documents', itemType: 'Document'),
      );

      final testFile = File(path.join(tempDir.path, 'test', 'documents_list_bloc_test.dart'));
      expect(await testFile.exists(), isTrue);

      final testContent = await testFile.readAsString();
      expect(testContent, contains("import 'package:bloc_test/bloc_test.dart'"));
      expect(testContent, contains('DocumentsListBloc'));
    });

    test('handles different naming conventions', () async {
      final brick = Brick.path(path.join('bricks', 'list_bloc'));

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: defaultVars('user_profiles', itemType: 'UserProfile'),
      );

      final blocFile = File(path.join(tempDir.path, 'lib', 'src', 'bloc.dart'));
      final blocContent = await blocFile.readAsString();
      expect(blocContent, contains('class UserProfilesListBloc'));
    });
  });
}
