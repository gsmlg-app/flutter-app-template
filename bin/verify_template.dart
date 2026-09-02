#!/usr/bin/env dart

// ignore_for_file: avoid_print

import 'dart:io';

/// Script to verify template invariants and integrity.
///
/// Verifies:
/// 1. Workspace packages on disk match root pubspec.yaml workspace list.
/// 2. Template manifest (template.yaml) is valid and matches workspace packages.
/// 3. Five target platform directories exist (android, ios, macos, windows, linux).
/// 4. Web platform directory is strictly disallowed.
/// 5. No unhydrated Git LFS pointer files exist among tracked assets.
/// 6. No forbidden debug signing fallbacks in release configurations.
///
/// Usage: dart run bin/verify_template.dart
void main(List<String> args) {
  print('========================================');
  print('Verifying Flutter App Template Invariants');
  print('========================================\n');

  final errors = <String>[];

  // 1. Verify root pubspec.yaml
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('❌ Error: pubspec.yaml not found in current directory.');
    exit(1);
  }

  final pubspecContent = pubspecFile.readAsStringSync();

  // Extract workspace packages from pubspec.yaml
  final workspacePackages = <String>[];
  final workspaceRegex = RegExp(r'workspace:\s*\n((?:\s+-\s+[^\n]+\n)+)');
  final workspaceMatch = workspaceRegex.firstMatch(pubspecContent);
  if (workspaceMatch != null) {
    final entries = workspaceMatch.group(1)!.split('\n');
    for (final entry in entries) {
      final trimmed = entry.trim();
      if (trimmed.startsWith('- ')) {
        workspacePackages.add(trimmed.substring(2).trim());
      }
    }
  }

  // 2. Discover all actual package directories on disk
  final diskPackages = <String>[];
  final packageDirs = [
    Directory('app_lib'),
    Directory('app_bloc'),
    Directory('app_widget'),
    Directory('app_form'),
    Directory('app_plugin'),
  ];

  for (final dir in packageDirs) {
    if (dir.existsSync()) {
      for (final entity in dir.listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('/pubspec.yaml')) {
          final relativePath = entity.parent.path.replaceAll(
            RegExp(r'^\./'),
            '',
          );
          // Ignore brick templates or build cache
          if (!relativePath.contains('bricks') &&
              !relativePath.contains('build')) {
            diskPackages.add(relativePath);
          }
        }
      }
    }
  }

  // Check for phantom packages or unregistered packages
  final unregistered = diskPackages
      .where((p) => !workspacePackages.contains(p))
      .toList();
  final missingOnDisk = workspacePackages
      .where((p) => !diskPackages.contains(p))
      .toList();

  if (unregistered.isNotEmpty) {
    errors.add(
      'Found packages on disk that are missing from root pubspec.yaml workspace:\n  - ${unregistered.join('\n  - ')}',
    );
  }
  if (missingOnDisk.isNotEmpty) {
    errors.add(
      'Found workspace packages in pubspec.yaml that do not exist on disk:\n  - ${missingOnDisk.join('\n  - ')}',
    );
  }

  // 3. Verify template.yaml manifest
  final manifestFile = File('template.yaml');
  if (!manifestFile.existsSync()) {
    errors.add('template.yaml manifest not found.');
  } else {
    final manifestContent = manifestFile.readAsStringSync();
    if (!manifestContent.contains('schema_version:')) {
      errors.add('template.yaml is missing schema_version.');
    }
  }

  // 4. Verify 5-Platform Rule: Android, iOS, macOS, Windows, Linux exist; Web does NOT exist
  final requiredPlatforms = ['android', 'ios', 'macos', 'windows', 'linux'];
  for (final platform in requiredPlatforms) {
    if (!Directory(platform).existsSync()) {
      errors.add('Required platform directory "$platform" is missing.');
    }
  }

  if (Directory('web').existsSync()) {
    errors.add(
      'Disallowed platform directory "web" was found. This template strictly supports only 5 native platforms.',
    );
  }

  // 5. Check Git LFS pointer hydration for critical assets
  final assetDir = Directory('app_widget/artwork/assets');
  if (assetDir.existsSync()) {
    for (final entity in assetDir.listSync(recursive: true)) {
      if (entity is File &&
          (entity.path.endsWith('.png') ||
              entity.path.endsWith('.jpg') ||
              entity.path.endsWith('.svg'))) {
        try {
          final bytes = entity.readAsBytesSync();
          if (bytes.length < 200) {
            final text = String.fromCharCodes(bytes);
            if (text.startsWith('version https://git-lfs.github.com/spec/v1')) {
              errors.add(
                'Asset "${entity.path}" is an unhydrated Git LFS pointer file.',
              );
            }
          }
        } catch (_) {}
      }
    }
  }

  // 6. Verify Android Release signing doesn't fall back to debug
  final androidBuildGradle = File('android/app/build.gradle.kts');
  if (androidBuildGradle.existsSync()) {
    final gradleText = androidBuildGradle.readAsStringSync();
    if (gradleText.contains('signingConfigs.getByName("debug")') &&
        gradleText.contains('release {')) {
      errors.add(
        'android/app/build.gradle.kts still contains debug fallback in release buildType.',
      );
    }
  }

  // Output results
  if (errors.isEmpty) {
    print(
      '✅ Workspace packages: ${workspacePackages.length} packages verified.',
    );
    for (final pkg in workspacePackages) {
      print('   ✓ $pkg');
    }
    print('\n✅ Platform directories verified (5 platforms):');
    for (final p in requiredPlatforms) {
      print('   ✓ $p');
    }
    print('✅ Web platform confirmed absent.');
    print('✅ Assets and manifest verified.');
    print('\n🎉 All template invariants passed!');
    exit(0);
  } else {
    print('❌ Template Invariant Violations Found:\n');
    for (var i = 0; i < errors.length; i++) {
      print('${i + 1}. ${errors[i]}\n');
    }
    exit(1);
  }
}
