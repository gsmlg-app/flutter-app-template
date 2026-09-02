import 'dart:io';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('Widget Brick Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('widget_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('generates basic stateless widget', () async {
      final brick = Brick.path(path.join('bricks', 'widget'));

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: {
          'name': 'CustomButton',
          'type': 'stateless',
          'has_platform_adaptive': true,
        },
      );

      final libFile = File(
        path.join(tempDir.path, 'lib', 'custom_button_widget.dart'),
      );
      expect(await libFile.exists(), isTrue);

      final srcFile = File(
        path.join(tempDir.path, 'lib', 'src', 'custom_button_widget.dart'),
      );
      expect(await srcFile.exists(), isTrue);
    });

    test('generates stateful widget', () async {
      final brick = Brick.path(path.join('bricks', 'widget'));

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: {
          'name': 'LoadingSpinner',
          'type': 'stateful',
          'has_platform_adaptive': false,
        },
      );

      final srcFile = File(
        path.join(tempDir.path, 'lib', 'src', 'loading_spinner_widget.dart'),
      );
      expect(await srcFile.exists(), isTrue);

      final content = await srcFile.readAsString();
      expect(content, contains('LoadingSpinnerWidget'));
    });

    test('creates complete widget package structure', () async {
      final brick = Brick.path(path.join('bricks', 'widget'));

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: {
          'name': 'TestCard',
          'type': 'stateless',
          'has_platform_adaptive': true,
        },
      );

      // Check main structure
      expect(
        await File(
          path.join(tempDir.path, 'lib', 'src', 'test_card_widget.dart'),
        ).exists(),
        isTrue,
      );
      expect(
        await File(
          path.join(tempDir.path, 'lib', 'test_card_widget.dart'),
        ).exists(),
        isTrue,
      );
      expect(
        await File(
          path.join(tempDir.path, 'test', 'test_card_widget_test.dart'),
        ).exists(),
        isTrue,
      );

      // Check package files
      expect(
        await File(path.join(tempDir.path, 'pubspec.yaml')).exists(),
        isTrue,
      );
      expect(await File(path.join(tempDir.path, 'README.md')).exists(), isTrue);
    });

    test('generates proper export file', () async {
      final brick = Brick.path(path.join('bricks', 'widget'));

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: {
          'name': 'TestWidget',
          'type': 'stateless',
          'has_platform_adaptive': false,
        },
      );

      final exportFile = File(
        path.join(tempDir.path, 'lib', 'test_widget_widget.dart'),
      );
      expect(await exportFile.exists(), isTrue);

      final content = await exportFile.readAsString();
      expect(content, contains("export 'src/test_widget_widget.dart'"));
    });

    test('includes test template', () async {
      final brick = Brick.path(path.join('bricks', 'widget'));

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: {
          'name': 'TestComponent',
          'type': 'stateful',
          'has_platform_adaptive': true,
        },
      );

      final testFile = File(
        path.join(tempDir.path, 'test', 'test_component_widget_test.dart'),
      );
      expect(await testFile.exists(), isTrue);

      final content = await testFile.readAsString();
      expect(
        content,
        contains("import 'package:flutter_test/flutter_test.dart'"),
      );
    });

    test('handles camelCase to snakeCase conversion', () async {
      final brick = Brick.path(path.join('bricks', 'widget'));

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: {
          'name': 'MyCustomWidget',
          'type': 'stateless',
          'has_platform_adaptive': false,
        },
      );

      final libFile = File(
        path.join(tempDir.path, 'lib', 'src', 'my_custom_widget_widget.dart'),
      );
      expect(await libFile.exists(), isTrue);
    });

    test('creates proper pubspec.yaml with dependencies', () async {
      final brick = Brick.path(path.join('bricks', 'widget'));

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: {
          'name': 'TestWidget',
          'type': 'stateless',
          'has_platform_adaptive': true,
        },
      );

      final pubspecFile = File(path.join(tempDir.path, 'pubspec.yaml'));
      expect(await pubspecFile.exists(), isTrue);

      final content = await pubspecFile.readAsString();
      expect(content, contains('name: test_widget_widget'));
      expect(content, contains('flutter:'));
      expect(content, contains('sdk: flutter'));
    });
  });
}
