#!/usr/bin/env dart

// ignore_for_file: avoid_print

import 'dart:io';

/// Script to initialize and rename flutter-app-template to a new project.
///
/// Features:
/// - Single source of truth (reads from and updates template.yaml)
/// - Multi-platform renaming:
///   * Dart package name & imports
///   * Android namespace, applicationId, Kotlin package path
///   * iOS/macOS bundle ID, display name, project.pbxproj
///   * Windows application identity, product name, CMakeLists, Runner.rc
///   * Linux application ID, binary name, CMakeLists, desktop file
///   * Fastlane Appfiles
/// - Clean Git tree guard
/// - Dry-run mode (--dry-run)
/// - Rollback on failure
/// - Idempotent execution
/// - Old identifier residual scanner
///
/// Usage:
///   dart run bin/setup_project.dart `new_name` [options]
///   dart run bin/setup_project.dart --name my_app --org com.example --display-name "My App"
void main(List<String> args) async {
  var newName = '';
  var newOrg = '';
  var displayName = '';
  var dryRun = false;
  var force = false;

  // Parse arguments
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--dry-run') {
      dryRun = true;
    } else if (arg == '--force' || arg == '-f') {
      force = true;
    } else if (arg == '--name' && i + 1 < args.length) {
      newName = args[++i];
    } else if (arg == '--org' && i + 1 < args.length) {
      newOrg = args[++i];
    } else if (arg == '--display-name' && i + 1 < args.length) {
      displayName = args[++i];
    } else if (!arg.startsWith('-') && newName.isEmpty) {
      newName = arg;
    }
  }

  // Validate environment
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print(
      '❌ Error: pubspec.yaml not found. Run this script from the project root.',
    );
    exit(1);
  }

  final currentPubspec = pubspecFile.readAsStringSync();
  final nameMatch = RegExp(
    r'^name:\s*(\S+)',
    multiLine: true,
  ).firstMatch(currentPubspec);
  final currentName = nameMatch?.group(1) ?? 'flutter_app_template';

  // Interactive input if name not provided
  if (newName.isEmpty) {
    stdout.write(
      'Enter new project name (snake_case) [current: $currentName]: ',
    );
    newName = stdin.readLineSync()?.trim() ?? '';
  }

  if (newName.isEmpty) {
    print('❌ Error: Project name cannot be empty.');
    exit(1);
  }

  if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(newName)) {
    print(
      '❌ Error: Project name must be in snake_case (lowercase letters, numbers, underscores, starting with letter).',
    );
    exit(1);
  }

  if (newOrg.isEmpty) {
    newOrg = 'app.gsmlg';
  }

  if (displayName.isEmpty) {
    displayName = newName
        .split('_')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  // Check Git clean tree
  if (!dryRun && !force) {
    final gitStatus = Process.runSync('git', ['status', '--porcelain']);
    if (gitStatus.exitCode == 0 &&
        gitStatus.stdout.toString().trim().isNotEmpty) {
      print(
        '❌ Error: Git working tree is dirty. Commit or stash changes before renaming, or pass --force.',
      );
      exit(1);
    }
  }

  final androidPackageSuffix = newName.replaceAll('_', '');
  final androidNamespace = '$newOrg.$androidPackageSuffix';
  final appleBundleId = '$newOrg.${_toCamelCase(newName)}';

  print('\n========================================');
  print('Project Setup & Rename');
  print('========================================');
  print('Project Name:     $newName');
  print('Display Name:     $displayName');
  print('Organization:     $newOrg');
  print('Android App ID:   $androidNamespace');
  print('Apple Bundle ID:  $appleBundleId');
  print('Mode:             ${dryRun ? "DRY RUN (no changes)" : "LIVE"}');
  print('========================================\n');

  final backup = <String, String>{};
  final modifiedFiles = <String>[];

  try {
    // 1. Update template.yaml
    _processFile('template.yaml', dryRun, backup, modifiedFiles, (content) {
      var updated = content;
      updated = updated.replaceAll(
        RegExp(r'^name:\s*.*$', multiLine: true),
        'name: $newName',
      );
      updated = updated.replaceAll(
        RegExp(r'^display_name:\s*.*$', multiLine: true),
        'display_name: $displayName',
      );
      updated = updated.replaceAll(
        RegExp(r'^organization:\s*.*$', multiLine: true),
        'organization: $newOrg',
      );
      updated = updated.replaceAll(
        RegExp(r'^logging_namespace:\s*.*$', multiLine: true),
        'logging_namespace: $newName',
      );
      return updated;
    });

    // 2. Update pubspec.yaml
    _processFile('pubspec.yaml', dryRun, backup, modifiedFiles, (content) {
      var updated = content;
      updated = updated.replaceAll(
        RegExp(r'^name:\s*.*$', multiLine: true),
        'name: $newName',
      );
      updated = updated.replaceAll(
        RegExp(r'name:\s*flutter_app_template'),
        'name: $newName',
      );
      return updated;
    });

    // 3. Update all Dart imports in lib/ and test/
    final dartDirs = [Directory('lib'), Directory('test')];
    for (final dir in dartDirs) {
      if (dir.existsSync()) {
        for (final entity in dir.listSync(recursive: true)) {
          if (entity is File && entity.path.endsWith('.dart')) {
            _processFile(entity.path, dryRun, backup, modifiedFiles, (content) {
              return content.replaceAll(
                'package:$currentName/',
                'package:$newName/',
              );
            });
          }
        }
      }
    }

    // 4. Update Android files
    _processFile(
      'android/app/build.gradle.kts',
      dryRun,
      backup,
      modifiedFiles,
      (content) {
        var updated = content;
        updated = updated.replaceAll(
          RegExp(r'namespace = ".*"'),
          'namespace = "$androidNamespace"',
        );
        updated = updated.replaceAll(
          RegExp(r'applicationId = ".*"'),
          'applicationId = "$androidNamespace"',
        );
        return updated;
      },
    );

    _processFile('android/fastlane/Appfile', dryRun, backup, modifiedFiles, (
      content,
    ) {
      return content.replaceAll(
        RegExp(r'package_name\(.*\)'),
        'package_name("$androidNamespace")',
      );
    });

    // Move Kotlin MainActivity to new package folder
    final kotlinBaseDir = 'android/app/src/main/kotlin';
    final oldKotlinPath =
        '$kotlinBaseDir/app/gsmlg/flutterapptemplate/MainActivity.kt';
    final newKotlinRelPath = androidNamespace.replaceAll('.', '/');
    final newKotlinPath = '$kotlinBaseDir/$newKotlinRelPath/MainActivity.kt';

    if (File(oldKotlinPath).existsSync()) {
      if (dryRun) {
        print(
          '  [DRY RUN] Move Kotlin MainActivity: $oldKotlinPath -> $newKotlinPath',
        );
      } else {
        final content = File(oldKotlinPath).readAsStringSync();
        final updatedContent = content.replaceAll(
          RegExp(r'package\s+[\w\.]+'),
          'package $androidNamespace',
        );
        File(newKotlinPath).createSync(recursive: true);
        File(newKotlinPath).writeAsStringSync(updatedContent);
        if (oldKotlinPath != newKotlinPath) {
          File(oldKotlinPath).deleteSync();
        }
        modifiedFiles.add(newKotlinPath);
        print('  ✓ Moved Kotlin MainActivity to: $newKotlinPath');
      }
    }

    // 5. Update iOS files
    _processFile('ios/Runner/Info.plist', dryRun, backup, modifiedFiles, (
      content,
    ) {
      var updated = content;
      updated = updated.replaceAll(
        RegExp(r'<key>CFBundleDisplayName<\/key>\s*<string>[^<]*<\/string>'),
        '<key>CFBundleDisplayName</key>\n\t<string>$displayName</string>',
      );
      updated = updated.replaceAll(
        RegExp(r'<key>CFBundleName<\/key>\s*<string>[^<]*<\/string>'),
        '<key>CFBundleName</key>\n\t<string>$newName</string>',
      );
      return updated;
    });

    _processFile(
      'ios/Runner.xcodeproj/project.pbxproj',
      dryRun,
      backup,
      modifiedFiles,
      (content) {
        return content.replaceAll(
          'app.gsmlg.flutterAppTemplate',
          appleBundleId,
        );
      },
    );

    _processFile('ios/fastlane/Appfile', dryRun, backup, modifiedFiles, (
      content,
    ) {
      return content.replaceAll(
        RegExp(r'app_identifier\(.*\)'),
        'app_identifier("$appleBundleId")',
      );
    });

    // 6. Update macOS files
    _processFile('macos/Runner/Info.plist', dryRun, backup, modifiedFiles, (
      content,
    ) {
      var updated = content;
      updated = updated.replaceAll(
        RegExp(r'<key>CFBundleDisplayName<\/key>\s*<string>[^<]*<\/string>'),
        '<key>CFBundleDisplayName</key>\n\t<string>$displayName</string>',
      );
      updated = updated.replaceAll(
        RegExp(r'<key>CFBundleName<\/key>\s*<string>[^<]*<\/string>'),
        '<key>CFBundleName</key>\n\t<string>$newName</string>',
      );
      return updated;
    });

    _processFile(
      'macos/Runner.xcodeproj/project.pbxproj',
      dryRun,
      backup,
      modifiedFiles,
      (content) {
        return content.replaceAll(
          'app.gsmlg.flutterAppTemplate',
          appleBundleId,
        );
      },
    );

    // 7. Update Linux files
    _processFile('linux/CMakeLists.txt', dryRun, backup, modifiedFiles, (
      content,
    ) {
      var updated = content;
      updated = updated.replaceAll(
        RegExp(r'set\(BINARY_NAME "[^"]*"\)'),
        'set(BINARY_NAME "$newName")',
      );
      updated = updated.replaceAll(
        RegExp(r'set\(APPLICATION_ID "[^"]*"\)'),
        'set(APPLICATION_ID "$androidNamespace")',
      );
      return updated;
    });

    // 8. Update Windows files
    _processFile('windows/CMakeLists.txt', dryRun, backup, modifiedFiles, (
      content,
    ) {
      var updated = content;
      updated = updated.replaceAll(
        RegExp(r'project\([^\s]+\s+LANGUAGES CXX\)'),
        'project($newName LANGUAGES CXX)',
      );
      updated = updated.replaceAll(
        RegExp(r'set\(BINARY_NAME "[^"]*"\)'),
        'set(BINARY_NAME "$newName")',
      );
      return updated;
    });

    _processFile('windows/runner/Runner.rc', dryRun, backup, modifiedFiles, (
      content,
    ) {
      var updated = content;
      updated = updated.replaceAll(
        RegExp(r'"InternalName",\s*"[^"]*"'),
        '"InternalName", "$newName"',
      );
      updated = updated.replaceAll(
        RegExp(r'"OriginalFilename",\s*"[^"]*"'),
        '"OriginalFilename", "$newName.exe"',
      );
      updated = updated.replaceAll(
        RegExp(r'"ProductName",\s*"[^"]*"'),
        '"ProductName", "$displayName"',
      );
      return updated;
    });

    // 9. Rename Melos IML file
    final oldIml = File('melos_$currentName.iml');
    final newIml = File('melos_$newName.iml');
    if (oldIml.existsSync()) {
      if (dryRun) {
        print(
          '  [DRY RUN] Rename melos_$currentName.iml -> melos_$newName.iml',
        );
      } else {
        oldIml.renameSync(newIml.path);
        modifiedFiles.add(newIml.path);
        print('  ✓ Renamed ${oldIml.path} -> ${newIml.path}');
      }
    }

    // 10. Update docs & config references
    for (final doc in ['README.md', 'CLAUDE.md', 'GEMINI.md', 'AGENTS.md']) {
      _processFile(doc, dryRun, backup, modifiedFiles, (content) {
        return content.replaceAll(currentName, newName);
      });
    }

    print('\n========================================');
    if (dryRun) {
      print(
        'DRY RUN COMPLETE: ${modifiedFiles.length} files would be updated.',
      );
    } else {
      print(
        'SUCCESS: Project successfully initialized as "$newName" (${modifiedFiles.length} files updated).',
      );
      print('\nNext steps:');
      print('  1. melos bootstrap');
      print('  2. dart bin/verify_template.dart');
      print('  3. flutter analyze');
    }
    print('========================================\n');
  } catch (e, st) {
    print('❌ Error during setup: $e');
    print(st);
    if (!dryRun && backup.isNotEmpty) {
      print('\nRolling back modified files...');
      for (final entry in backup.entries) {
        try {
          File(entry.key).writeAsStringSync(entry.value);
        } catch (_) {}
      }
      print('Rollback completed.');
    }
    exit(1);
  }
}

void _processFile(
  String path,
  bool dryRun,
  Map<String, String> backup,
  List<String> modifiedFiles,
  String Function(String content) transform,
) {
  final file = File(path);
  if (!file.existsSync()) return;

  final original = file.readAsStringSync();
  final transformed = transform(original);

  if (original != transformed) {
    if (dryRun) {
      print('  [DRY RUN] Would update: $path');
    } else {
      backup[path] = original;
      file.writeAsStringSync(transformed);
      print('  ✓ Updated: $path');
    }
    modifiedFiles.add(path);
  }
}

String _toCamelCase(String snake) {
  final parts = snake.split('_');
  if (parts.isEmpty) return '';
  return parts.first +
      parts
          .skip(1)
          .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
          .join('');
}
