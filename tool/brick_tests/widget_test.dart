import 'dart:io';
import 'dart:convert';
import 'package:test/test.dart';
import 'test_utils.dart';

/// Tests for the widget brick
void main() {
  group('Widget Brick Tests', () {
    late TestDirectory tempDir;

    setUp(() async {
      tempDir = await TestDirectory.create();
    });

    tearDown(() async {
      await tempDir.cleanup();
    });

    test('generates basic stateless widget with platform adaptation', () async {
      final config = {
        'name': 'CustomButton',
        'type': 'stateless',
        'folder': 'buttons',
        'has_platform_adaptive': true,
      };

      final result = await runMasonBrick('widget', config, tempDir.path);
      expect(result.exitCode, equals(0));

      final widgetFile = File('${tempDir.path}/app_widget/buttons/custom_button_widget/lib/src/custom_button_widget.dart');
      expect(widgetFile.existsSync(), isTrue);

      final content = await widgetFile.readAsString();
      expect(content, contains('class CustomButtonWidget'));
      expect(content, contains('Material'));
      expect(content, contains('Cupertino'));
    });

    test('generates stateful widget without platform adaptation', () async {
      final config = {
        'name': 'LoadingSpinner',
        'type': 'stateful',
        'folder': '',
        'has_platform_adaptive': false,
      };

      final result = await runMasonBrick('widget', config, tempDir.path);
      expect(result.exitCode, equals(0));

      final widgetFile = File('${tempDir.path}/app_widget/loading_spinner_widget/lib/src/loading_spinner_widget.dart');
      expect(widgetFile.existsSync(), isTrue);

      final content = await widgetFile.readAsString();
      expect(content, contains('class LoadingSpinnerWidget'));
      expect(content, isNot(contains('Material')));
      expect(content, isNot(contains('Cupertino')));
    });

    test('creates complete widget package structure', () async {
      final config = {
        'name': 'TestCard',
        'type': 'stateless',
        'folder': 'cards',
        'has_platform_adaptive': true,
      };

      final result = await runMasonBrick('widget', config, tempDir.path);
      expect(result.exitCode, equals(0));

      final basePath = '${tempDir.path}/app_widget/cards/test_card_widget';
      
      // Check main structure
      expect(File('$basePath/lib/src/test_card_widget.dart').existsSync(), isTrue);
      expect(File('$basePath/lib/test_card_widget.dart').existsSync(), isTrue);
      expect(File('$basePath/test/test_card_widget_test.dart').existsSync(), isTrue);
      
      // Check package files
      expect(File('$basePath/pubspec.yaml').existsSync(), isTrue);
      expect(File('$basePath/README.md').existsSync(), isTrue);
      expect(File('$basePath/CHANGELOG.md').existsSync(), isTrue);
      expect(File('$basePath/LICENSE').existsSync(), isTrue);
      expect(File('$basePath/.gitignore').existsSync(), isTrue);
      expect(File('$basePath/analysis_options.yaml').existsSync(), isTrue);
    });

    test('generates proper export file', () async {
      final config = {
        'name': 'TestWidget',
        'type': 'stateless',
        'folder': '',
        'has_platform_adaptive': false,
      };

      final result = await runMasonBrick('widget', config, tempDir.path);
      expect(result.exitCode, equals(0));

      final exportFile = File('${tempDir.path}/app_widget/test_widget_widget/lib/test_widget_widget.dart');
      expect(exportFile.existsSync(), isTrue);

      final content = await exportFile.readAsString();
      expect(content, contains('export \'src/test_widget_widget.dart\';'));
    });

    test('includes comprehensive test template', () async {
      final config = {
        'name': 'TestComponent',
        'type': 'stateful',
        'folder': 'components',
        'has_platform_adaptive': true,
      };

      final result = await runMasonBrick('widget', config, tempDir.path);
      expect(result.exitCode, equals(0));

      final testFile = File('${tempDir.path}/app_widget/components/test_component_widget/test/test_component_widget_test.dart');
      expect(testFile.existsSync(), isTrue);

      final content = await testFile.readAsString();
      expect(content, contains('import \'package:flutter_test/flutter_test.dart\';'));
      expect(content, contains('import \'../lib/test_component_widget.dart\';'));
      expect(content, contains('group(\'TestComponentWidget\', () {'));
      expect(content, contains('testWidgets(\'renders correctly\', (tester) async {'));
    });

    test('validates widget type enum', () async {
      final config = {
        'name': 'TestWidget',
        'type': 'invalid_type',
        'folder': '',
        'has_platform_adaptive': true,
      };

      final result = await runMasonBrick('widget', config, tempDir.path);
      expect(result.exitCode, isNot(equals(0)));
    });

    test('handles camelCase to snakeCase conversion', () async {
      final config = {
        'name': 'MyCustomWidget',
        'type': 'stateless',
        'folder': 'custom',
        'has_platform_adaptive': false,
      };

      final result = await runMasonBrick('widget', config, tempDir.path);
      expect(result.exitCode, equals(0));

      final widgetFile = File('${tempDir.path}/app_widget/custom/my_custom_widget_widget/lib/src/my_custom_widget.dart');
      expect(widgetFile.existsSync(), isTrue);

      final content = await widgetFile.readAsString();
      expect(content, contains('class MyCustomWidget'));
    });

    test('creates proper pubspec.yaml with dependencies', () async {
      final config = {
        'name': 'TestWidget',
        'type': 'stateless',
        'folder': '',
        'has_platform_adaptive': true,
      };

      final result = await runMasonBrick('widget', config, tempDir.path);
      expect(result.exitCode, equals(0));

      final pubspecFile = File('${tempDir.path}/app_widget/test_widget_widget/pubspec.yaml');
      expect(pubspecFile.existsSync(), isTrue);

      final content = await pubspecFile.readAsString();
      expect(content, contains('name: test_widget_widget'));
      expect(content, contains('flutter:'));
      expect(content, contains('sdk: flutter'));
    });
  });
}