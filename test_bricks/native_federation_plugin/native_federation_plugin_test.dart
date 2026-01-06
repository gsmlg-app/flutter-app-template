import 'dart:io';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('Native Federation Plugin Brick Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('native_plugin_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('generates federated plugin with all platforms', () async {
      final brick = Brick.path(
        path.join('bricks', 'native_federation_plugin'),
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

      // Check main plugin package
      final mainPubspec = File(
        path.join(tempDir.path, 'battery_monitor', 'pubspec.yaml'),
      );
      expect(await mainPubspec.exists(), isTrue);

      // Check platform interface package
      final interfacePubspec = File(
        path.join(
          tempDir.path,
          'battery_monitor_platform_interface',
          'pubspec.yaml',
        ),
      );
      expect(await interfacePubspec.exists(), isTrue);

      // Check platform implementations
      final platforms = ['android', 'ios', 'linux', 'macos', 'windows'];
      for (final platform in platforms) {
        final platformPubspec = File(
          path.join(tempDir.path, 'battery_monitor_$platform', 'pubspec.yaml'),
        );
        expect(
          await platformPubspec.exists(),
          isTrue,
          reason: '$platform platform pubspec should exist',
        );
      }
    });

    test('generates correct main plugin structure', () async {
      final brick = Brick.path(
        path.join('bricks', 'native_federation_plugin'),
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

    test('generates platform interface with correct structure', () async {
      final brick = Brick.path(
        path.join('bricks', 'native_federation_plugin'),
      );

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: {
          'name': 'sensor',
          'description': 'Sensor plugin',
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

      final interfaceDir = path.join(tempDir.path, 'sensor_platform_interface');

      // Check main export
      final mainExport = File(
        path.join(interfaceDir, 'lib', 'app_sensor_platform_interface.dart'),
      );
      expect(await mainExport.exists(), isTrue);

      // Check platform class
      final platformFile = File(
        path.join(interfaceDir, 'lib', 'src', 'sensor_platform.dart'),
      );
      expect(await platformFile.exists(), isTrue);

      // Check method channel implementation
      final methodChannelFile = File(
        path.join(interfaceDir, 'lib', 'src', 'method_channel_sensor.dart'),
      );
      expect(await methodChannelFile.exists(), isTrue);
    });

    test('generates Android implementation with Kotlin code', () async {
      final brick = Brick.path(
        path.join('bricks', 'native_federation_plugin'),
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

      final androidDir = path.join(tempDir.path, 'audio_android');

      // Check Kotlin plugin file
      final kotlinFile = File(
        path.join(
          androidDir,
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

      // Check build.gradle
      final buildGradle = File(
        path.join(androidDir, 'android', 'build.gradle'),
      );
      expect(await buildGradle.exists(), isTrue);
    });

    test('generates iOS implementation with Swift code', () async {
      final brick = Brick.path(
        path.join('bricks', 'native_federation_plugin'),
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

      final iosDir = path.join(tempDir.path, 'camera_ios');

      // Check Swift plugin file
      final swiftFile = File(
        path.join(iosDir, 'ios', 'Classes', 'CameraPlugin.swift'),
      );
      expect(await swiftFile.exists(), isTrue);

      final swiftContent = await swiftFile.readAsString();
      expect(swiftContent, contains('CameraPlugin'));
      expect(swiftContent, contains('FlutterPlugin'));

      // Check podspec
      final podspec = File(
        path.join(iosDir, 'ios', 'camera_ios.podspec'),
      );
      expect(await podspec.exists(), isTrue);
    });

    test('generates Linux implementation with C++ code', () async {
      final brick = Brick.path(
        path.join('bricks', 'native_federation_plugin'),
      );

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: {
          'name': 'file_picker',
          'description': 'File picker plugin',
          'package_prefix': 'app',
          'author': 'Test',
          'support_android': false,
          'support_ios': false,
          'support_linux': true,
          'support_macos': false,
          'support_windows': false,
          'support_web': false,
        },
      );

      final linuxDir = path.join(tempDir.path, 'file_picker_linux');

      // Check C++ plugin file
      final cppFile = File(
        path.join(linuxDir, 'linux', 'file_picker_plugin.cc'),
      );
      expect(await cppFile.exists(), isTrue);

      // Check header file
      final headerFile = File(
        path.join(
          linuxDir,
          'linux',
          'include',
          'app_file_picker_linux',
          'file_picker_plugin.h',
        ),
      );
      expect(await headerFile.exists(), isTrue);

      // Check CMakeLists.txt
      final cmake = File(path.join(linuxDir, 'linux', 'CMakeLists.txt'));
      expect(await cmake.exists(), isTrue);
    });

    test('generates Windows implementation with C++ code', () async {
      final brick = Brick.path(
        path.join('bricks', 'native_federation_plugin'),
      );

      final generator = await MasonGenerator.fromBrick(brick);
      await generator.generate(
        DirectoryGeneratorTarget(tempDir),
        vars: {
          'name': 'clipboard',
          'description': 'Clipboard plugin',
          'package_prefix': 'app',
          'author': 'Test',
          'support_android': false,
          'support_ios': false,
          'support_linux': false,
          'support_macos': false,
          'support_windows': true,
          'support_web': false,
        },
      );

      final windowsDir = path.join(tempDir.path, 'clipboard_windows');

      // Check C++ plugin files
      final cppFile = File(
        path.join(windowsDir, 'windows', 'clipboard_plugin.cpp'),
      );
      expect(await cppFile.exists(), isTrue);

      final headerFile = File(
        path.join(windowsDir, 'windows', 'clipboard_plugin.h'),
      );
      expect(await headerFile.exists(), isTrue);

      // Check CMakeLists.txt
      final cmake = File(path.join(windowsDir, 'windows', 'CMakeLists.txt'));
      expect(await cmake.exists(), isTrue);
    });

    test('handles different package prefixes correctly', () async {
      final brick = Brick.path(
        path.join('bricks', 'native_federation_plugin'),
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

      // Check platform interface uses custom prefix
      final interfaceExport = File(
        path.join(
          tempDir.path,
          'network_platform_interface',
          'lib',
          'my_company_network_platform_interface.dart',
        ),
      );
      expect(await interfaceExport.exists(), isTrue);
    });

    test('generates README documentation', () async {
      final brick = Brick.path(
        path.join('bricks', 'native_federation_plugin'),
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

      final readme = File(path.join(tempDir.path, 'README.md'));
      expect(await readme.exists(), isTrue);

      final readmeContent = await readme.readAsString();
      expect(readmeContent, contains('storage'));
    });
  });
}
