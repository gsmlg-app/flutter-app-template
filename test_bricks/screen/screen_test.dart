import 'dart:io';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('Screen Brick Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('screen_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('generates basic screen with default options', () async {
      final brick = Brick.path(path.join('bricks', 'screen'));

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: {
          'name': 'TestHome',
          'has_adaptive_scaffold': true,
          'has_app_bar': true,
        },
      );

      final screenFile = File(
        path.join(tempDir.path, 'lib', 'screens', 'test_home_screen.dart'),
      );
      expect(await screenFile.exists(), isTrue);

      final content = await screenFile.readAsString();
      expect(content, contains('class TestHomeScreen extends StatelessWidget'));
      expect(content, contains("static const name = 'Test Home'"));
      expect(content, contains("static const path = '/test-home'"));
      expect(content, contains('AppAdaptiveScaffold'));
      expect(content, contains('SliverAppBar'));
    });

    test('generates screen without adaptive scaffold', () async {
      final brick = Brick.path(path.join('bricks', 'screen'));

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: {
          'name': 'TestLogin',
          'has_adaptive_scaffold': false,
          'has_app_bar': true,
        },
      );

      final screenFile = File(
        path.join(tempDir.path, 'lib', 'screens', 'test_login_screen.dart'),
      );
      expect(await screenFile.exists(), isTrue);

      final content = await screenFile.readAsString();
      expect(content, contains('class TestLoginScreen extends StatelessWidget'));
      expect(content, contains('return Scaffold('));
      expect(content, contains('appBar: AppBar('));
    });

    test('generates minimal screen', () async {
      final brick = Brick.path(path.join('bricks', 'screen'));

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: {
          'name': 'TestSplash',
          'has_adaptive_scaffold': false,
          'has_app_bar': false,
        },
      );

      final screenFile = File(
        path.join(tempDir.path, 'lib', 'screens', 'test_splash_screen.dart'),
      );
      expect(await screenFile.exists(), isTrue);

      final content = await screenFile.readAsString();
      expect(content, contains('class TestSplashScreen extends StatelessWidget'));
      expect(content, contains('return Scaffold('));
      expect(content, isNot(contains('appBar:')));
    });

    test('handles different screen names', () async {
      final brick = Brick.path(path.join('bricks', 'screen'));

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: {
          'name': 'UserProfile',
          'has_adaptive_scaffold': true,
          'has_app_bar': true,
        },
      );

      final screenFile = File(
        path.join(tempDir.path, 'lib', 'screens', 'user_profile_screen.dart'),
      );
      expect(await screenFile.exists(), isTrue);

      final content = await screenFile.readAsString();
      expect(content, contains('class UserProfileScreen extends StatelessWidget'));
      expect(content, contains("static const name = 'User Profile'"));
      expect(content, contains("static const path = '/user-profile'"));
    });

    test('generates screen with app bar only', () async {
      final brick = Brick.path(path.join('bricks', 'screen'));

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: {
          'name': 'Settings',
          'has_adaptive_scaffold': false,
          'has_app_bar': true,
        },
      );

      final screenFile = File(
        path.join(tempDir.path, 'lib', 'screens', 'settings_screen.dart'),
      );
      expect(await screenFile.exists(), isTrue);

      final content = await screenFile.readAsString();
      expect(content, contains('class SettingsScreen extends StatelessWidget'));
      expect(content, contains('appBar: AppBar('));
      expect(content, contains("title: const Text('Settings')"));
    });
  });
}
