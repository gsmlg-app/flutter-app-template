import 'dart:io';
import 'dart:convert';
import 'package:test/test.dart';
import 'test_utils.dart';

/// Tests for the screen brick
void main() {
  group('Screen Brick Tests', () {
    late TestDirectory tempDir;

    setUp(() async {
      tempDir = await TestDirectory.create();
    });

    tearDown(() async {
      await tempDir.cleanup();
    });

    test('generates basic screen with default options', () async {
      final config = {
        'name': 'TestHome',
        'folder': '',
        'has_adaptive_scaffold': true,
        'has_app_bar': true,
      };

      final result = await runMasonBrick('screen', config, tempDir.path);
      expect(result.exitCode, equals(0));

      final screenFile = File('${tempDir.path}/lib/screens/test_home_screen.dart');
      expect(screenFile.existsSync(), isTrue);

      final content = await screenFile.readAsString();
      expect(content, contains('class TestHomeScreen extends StatelessWidget'));
      expect(content, contains('static const name = \'Test Home\''));
      expect(content, contains('static const path = \'/test-home\''));
      expect(content, contains('AppAdaptiveScaffold'));
      expect(content, contains('SliverAppBar'));
    });

    test('generates screen without adaptive scaffold', () async {
      final config = {
        'name': 'TestLogin',
        'folder': 'auth',
        'has_adaptive_scaffold': false,
        'has_app_bar': true,
      };

      final result = await runMasonBrick('screen', config, tempDir.path);
      expect(result.exitCode, equals(0));

      final screenFile = File('${tempDir.path}/lib/screens/auth/test_login_screen.dart');
      expect(screenFile.existsSync(), isTrue);

      final content = await screenFile.readAsString();
      expect(content, contains('class TestLoginScreen extends StatelessWidget'));
      expect(content, contains('return Scaffold('));
      expect(content, contains('appBar: AppBar('));
    });

    test('generates minimal screen', () async {
      final config = {
        'name': 'TestSplash',
        'folder': '',
        'has_adaptive_scaffold': false,
        'has_app_bar': false,
      };

      final result = await runMasonBrick('screen', config, tempDir.path);
      expect(result.exitCode, equals(0));

      final screenFile = File('${tempDir.path}/lib/screens/test_splash_screen.dart');
      expect(screenFile.existsSync(), isTrue);

      final content = await screenFile.readAsString();
      expect(content, contains('class TestSplashScreen extends StatelessWidget'));
      expect(content, contains('return Scaffold('));
      expect(content, isNot(contains('appBar:')));
    });

    test('handles special characters in screen name', () async {
      final config = {
        'name': 'UserProfile',
        'folder': 'user',
        'has_adaptive_scaffold': true,
        'has_app_bar': true,
      };

      final result = await runMasonBrick('screen', config, tempDir.path);
      expect(result.exitCode, equals(0));

      final screenFile = File('${tempDir.path}/lib/screens/user/user_profile_screen.dart');
      expect(screenFile.existsSync(), isTrue);

      final content = await screenFile.readAsString();
      expect(content, contains('class UserProfileScreen extends StatelessWidget'));
      expect(content, contains('static const name = \'User Profile\''));
      expect(content, contains('static const path = \'/user-profile\''));
    });

    test('validates required name parameter', () async {
      final config = {
        'folder': '',
        'has_adaptive_scaffold': true,
        'has_app_bar': true,
      };

      final result = await runMasonBrick('screen', config, tempDir.path);
      expect(result.exitCode, isNot(equals(0)));
    });

    test('creates directory structure for nested screens', () async {
      final config = {
        'name': 'Settings',
        'folder': 'user/profile',
        'has_adaptive_scaffold': true,
        'has_app_bar': true,
      };

      final result = await runMasonBrick('screen', config, tempDir.path);
      expect(result.exitCode, equals(0));

      final screenFile = File('${tempDir.path}/lib/screens/user/profile/settings_screen.dart');
      expect(screenFile.existsSync(), isTrue);
      expect(File('${tempDir.path}/lib/screens/user').existsSync(), isTrue);
      expect(File('${tempDir.path}/lib/screens/user/profile').existsSync(), isTrue);
    });
  });
}