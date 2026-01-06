import 'dart:io';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('Native Plugin Brick Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('native_plugin_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('generates plugin with all platforms', () async {
      final brick = Brick.path(
        path.join('bricks', 'native_plugin'),
      );

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: {
          'name': 'battery_monitor',
          'description': 'A battery monitoring plugin',
          'package_prefix': 'app',
          'author': 'Test Author',
          'support_android': true,
          'support_ios': true,
          'support_linux': true,
          'support_macos': true,
          'support_windows': true,
          'support_web': false,
        },
      );

      // Check pubspec.yaml exists
      final pubspec = File(
        path.join(tempDir.path, 'battery_monitor', 'pubspec.yaml'),
      );
      expect(await pubspec.exists(), isTrue);

      // Check main Dart file
      final mainDart = File(
        path.join(tempDir.path, 'battery_monitor', 'lib', 'app_battery_monitor.dart'),
      );
      expect(await mainDart.exists(), isTrue);

      // Check Android platform
      final androidPlugin = File(
        path.join(
          tempDir.path,
          'battery_monitor',
          'android',
          'src',
          'main',
          'kotlin',
          'com',
          'app',
          'battery_monitor',
          'BatteryMonitorPlugin.kt',
        ),
      );
      expect(await androidPlugin.exists(), isTrue);

      // Check iOS platform
      final iosPlugin = File(
        path.join(tempDir.path, 'battery_monitor', 'ios', 'Classes', 'BatteryMonitorPlugin.swift'),
      );
      expect(await iosPlugin.exists(), isTrue);

      // Check Linux platform
      final linuxPlugin = File(
        path.join(tempDir.path, 'battery_monitor', 'linux', 'battery_monitor_plugin.cc'),
      );
      expect(await linuxPlugin.exists(), isTrue);

      // Check macOS platform
      final macosPlugin = File(
        path.join(tempDir.path, 'battery_monitor', 'macos', 'Classes', 'BatteryMonitorPlugin.swift'),
      );
      expect(await macosPlugin.exists(), isTrue);

      // Check Windows platform
      final windowsPlugin = File(
        path.join(tempDir.path, 'battery_monitor', 'windows', 'battery_monitor_plugin.cpp'),
      );
      expect(await windowsPlugin.exists(), isTrue);
    });

    test('generates correct Dart structure', () async {
      final brick = Brick.path(
        path.join('bricks', 'native_plugin'),
      );

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: {
          'name': 'device_info',
          'description': 'Device info plugin',
          'package_prefix': 'my',
          'author': 'Test',
          'support_android': true,
          'support_ios': true,
          'support_linux': false,
          'support_macos': false,
          'support_windows': false,
          'support_web': false,
        },
      );

      // Check main export file
      final mainExport = File(
        path.join(tempDir.path, 'device_info', 'lib', 'my_device_info.dart'),
      );
      expect(await mainExport.exists(), isTrue);

      // Check source files
      final srcFile = File(
        path.join(tempDir.path, 'device_info', 'lib', 'src', 'device_info.dart'),
      );
      expect(await srcFile.exists(), isTrue);

      // Check models
      final modelsDir = Directory(
        path.join(tempDir.path, 'device_info', 'lib', 'src', 'models'),
      );
      expect(await modelsDir.exists(), isTrue);
    });

    test('generates Android implementation with Kotlin code', () async {
      final brick = Brick.path(
        path.join('bricks', 'native_plugin'),
      );

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: {
          'name': 'audio',
          'description': 'Audio plugin',
          'package_prefix': 'app',
          'author': 'Test',
          'support_android': true,
          'support_ios': false,
          'support_linux': false,
          'support_macos': false,
          'support_windows': false,
          'support_web': false,
        },
      );

      // Check Kotlin plugin file
      final kotlinFile = File(
        path.join(
          tempDir.path,
          'audio',
          'android',
          'src',
          'main',
          'kotlin',
          'com',
          'app',
          'audio',
          'AudioPlugin.kt',
        ),
      );
      expect(await kotlinFile.exists(), isTrue);

      final kotlinContent = await kotlinFile.readAsString();
      expect(kotlinContent, contains('class AudioPlugin'));
      expect(kotlinContent, contains('FlutterPlugin'));
      expect(kotlinContent, contains('MethodCallHandler'));

      // Check build.gradle
      final buildGradle = File(
        path.join(tempDir.path, 'audio', 'android', 'build.gradle'),
      );
      expect(await buildGradle.exists(), isTrue);
    });

    test('generates iOS implementation with Swift code', () async {
      final brick = Brick.path(
        path.join('bricks', 'native_plugin'),
      );

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: {
          'name': 'camera',
          'description': 'Camera plugin',
          'package_prefix': 'app',
          'author': 'Test',
          'support_android': false,
          'support_ios': true,
          'support_linux': false,
          'support_macos': false,
          'support_windows': false,
          'support_web': false,
        },
      );

      // Check Swift plugin file
      final swiftFile = File(
        path.join(tempDir.path, 'camera', 'ios', 'Classes', 'CameraPlugin.swift'),
      );
      expect(await swiftFile.exists(), isTrue);

      final swiftContent = await swiftFile.readAsString();
      expect(swiftContent, contains('CameraPlugin'));
      expect(swiftContent, contains('FlutterPlugin'));

      // Check podspec
      final podspec = File(
        path.join(tempDir.path, 'camera', 'ios', 'camera.podspec'),
      );
      expect(await podspec.exists(), isTrue);
    });

    test('handles different package prefixes correctly', () async {
      final brick = Brick.path(
        path.join('bricks', 'native_plugin'),
      );

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: {
          'name': 'network',
          'description': 'Network plugin',
          'package_prefix': 'my_company',
          'author': 'My Company',
          'support_android': true,
          'support_ios': false,
          'support_linux': false,
          'support_macos': false,
          'support_windows': false,
          'support_web': false,
        },
      );

      // Check main export uses custom prefix
      final mainExport = File(
        path.join(tempDir.path, 'network', 'lib', 'my_company_network.dart'),
      );
      expect(await mainExport.exists(), isTrue);

      // Check pubspec has correct name
      final pubspec = File(
        path.join(tempDir.path, 'network', 'pubspec.yaml'),
      );
      final pubspecContent = await pubspec.readAsString();
      expect(pubspecContent, contains('name: my_company_network'));
    });

    test('generates README documentation', () async {
      final brick = Brick.path(
        path.join('bricks', 'native_plugin'),
      );

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: {
          'name': 'storage',
          'description': 'Storage plugin',
          'package_prefix': 'app',
          'author': 'Test',
          'support_android': true,
          'support_ios': true,
          'support_linux': true,
          'support_macos': true,
          'support_windows': true,
          'support_web': false,
        },
      );

      final readme = File(path.join(tempDir.path, 'storage', 'README.md'));
      expect(await readme.exists(), isTrue);

      final readmeContent = await readme.readAsString();
      expect(readmeContent, contains('Storage'));
      expect(readmeContent, contains('Storage plugin'));
    });
  });
}
