#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:io';

/// Script to sync template resources from the flutter-app-template repository.
///
/// This script syncs:
/// 1. Mason bricks (bricks/)
/// 2. Project skills (.claude/skills/project-*)
/// 3. Bin scripts (bin/)
/// 4. Third-party packages (third_party/)
///
/// All synced items are replaced with upstream versions (no change detection).
/// New items from upstream are added.
///
/// Usage: dart run bin/sync_template.dart [options]
///   --dry-run    Show what would be synced without making changes
///   --skip-bricks      Skip syncing bricks
///   --skip-skills      Skip syncing skills
///   --skip-scripts     Skip syncing bin scripts
///   --skip-third-party Skip syncing third_party packages
void main(List<String> args) async {
  const templateName = 'flutter_app_template';
  const templateRepo = 'https://github.com/gsmlg-app/flutter-app-template.git';
  const tempDir = '.template-sync';

  final dryRun = args.contains('--dry-run');
  final skipBricks = args.contains('--skip-bricks');
  final skipSkills = args.contains('--skip-skills');
  final skipScripts = args.contains('--skip-scripts');
  final skipThirdParty = args.contains('--skip-third-party');

  // Get current project name from pubspec.yaml
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('Error: pubspec.yaml not found. Run this script from the project root.');
    exit(1);
  }

  final pubspecContent = pubspecFile.readAsStringSync();
  final nameMatch = RegExp(r'^name:\s*(\S+)', multiLine: true).firstMatch(pubspecContent);
  final currentName = nameMatch?.group(1);

  if (currentName == null) {
    print('Error: Could not parse project name from pubspec.yaml');
    exit(1);
  }

  // Check if project has been renamed
  if (currentName == templateName) {
    print('Error: Project has not been renamed yet.');
    print('');
    print('This script is for syncing resources in projects that have been');
    print('forked/cloned from the template and renamed.');
    print('');
    print('To rename the project, run:');
    print('  dart run bin/setup_project.dart');
    exit(1);
  }

  if (dryRun) {
    print('=== DRY RUN MODE ===');
    print('');
  }

  print('Syncing template resources...');
  print('Current project: $currentName');
  print('');

  // Clean up any existing temp directory
  final tempDirectory = Directory(tempDir);
  if (tempDirectory.existsSync()) {
    tempDirectory.deleteSync(recursive: true);
  }

  try {
    // Clone template repo with sparse checkout
    print('Fetching template repository...');

    var result = Process.runSync('git', [
      'clone',
      '--depth=1',
      '--filter=blob:none',
      '--sparse',
      templateRepo,
      tempDir,
    ]);

    if (result.exitCode != 0) {
      print('Error cloning repository:');
      print(result.stderr);
      exit(1);
    }

    // Set sparse checkout patterns for all directories we need
    // Using --no-cone mode to allow file patterns
    final sparsePatterns = <String>[
      'bricks/',
      'bin/',
      'third_party/',
      '.claude/skills/',
      'mason.yaml',
    ];

    result = Process.runSync(
      'git',
      ['sparse-checkout', 'set', '--no-cone', ...sparsePatterns],
      workingDirectory: tempDir,
    );

    if (result.exitCode != 0) {
      print('Error setting sparse checkout:');
      print(result.stderr);
      exit(1);
    }

    // Track sync statistics
    var totalSynced = 0;
    var totalAdded = 0;

    // 1. Sync bricks
    if (!skipBricks) {
      print('');
      print('=== Syncing Bricks ===');
      final bricksResult = _syncDirectory(
        templateDir: '$tempDir/bricks',
        localDir: 'bricks',
        itemType: 'brick',
        dryRun: dryRun,
      );
      totalSynced += bricksResult.synced;
      totalAdded += bricksResult.added;

      // Sync mason.yaml
      final templateMasonYaml = File('$tempDir/mason.yaml');
      if (templateMasonYaml.existsSync()) {
        if (dryRun) {
          print('  Would sync: mason.yaml');
        } else {
          templateMasonYaml.copySync('mason.yaml');
          print('  Synced: mason.yaml');
        }
        totalSynced++;
      }
    }

    // 2. Sync project skills
    if (!skipSkills) {
      print('');
      print('=== Syncing Project Skills ===');
      final skillsResult = _syncDirectoryWithPrefix(
        templateDir: '$tempDir/.claude/skills',
        localDir: '.claude/skills',
        prefix: 'project-',
        itemType: 'skill',
        dryRun: dryRun,
      );
      totalSynced += skillsResult.synced;
      totalAdded += skillsResult.added;
    }

    // 3. Sync bin scripts
    if (!skipScripts) {
      print('');
      print('=== Syncing Bin Scripts ===');
      final scriptsResult = _syncFiles(
        templateDir: '$tempDir/bin',
        localDir: 'bin',
        itemType: 'script',
        dryRun: dryRun,
      );
      totalSynced += scriptsResult.synced;
      totalAdded += scriptsResult.added;
    }

    // 4. Sync third_party packages
    if (!skipThirdParty) {
      print('');
      print('=== Syncing Third-Party Packages ===');
      final thirdPartyResult = _syncDirectory(
        templateDir: '$tempDir/third_party',
        localDir: 'third_party',
        itemType: 'package',
        dryRun: dryRun,
      );
      totalSynced += thirdPartyResult.synced;
      totalAdded += thirdPartyResult.added;
    }

    // Summary
    print('');
    print('=' * 40);
    if (dryRun) {
      print('DRY RUN COMPLETE');
      print('  Would sync: $totalSynced items');
      print('  Would add: $totalAdded new items');
    } else {
      print('Sync complete!');
      print('  Synced: $totalSynced items');
      print('  Added: $totalAdded new items');
    }
    print('');
    print('Next steps:');
    print('  1. Run: mason get');
    print('  2. Run: melos bootstrap');
    print('  3. Review changes and commit if satisfied');
    print('');
  } finally {
    // Clean up temp directory
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  }
}

/// Result of a sync operation
class SyncResult {
  final int synced;
  final int added;

  SyncResult({required this.synced, required this.added});
}

/// Sync all subdirectories from template to local
SyncResult _syncDirectory({
  required String templateDir,
  required String localDir,
  required String itemType,
  required bool dryRun,
}) {
  final templateDirectory = Directory(templateDir);
  if (!templateDirectory.existsSync()) {
    print('  Warning: $templateDir not found in template');
    return SyncResult(synced: 0, added: 0);
  }

  final localDirectory = Directory(localDir);
  if (!localDirectory.existsSync()) {
    if (!dryRun) {
      localDirectory.createSync(recursive: true);
    }
  }

  // Get list of items in template
  final templateItems = templateDirectory
      .listSync()
      .whereType<Directory>()
      .map((d) => d.path.split('/').last)
      .toList();

  // Get list of local items
  final localItems = localDirectory.existsSync()
      ? localDirectory
          .listSync()
          .whereType<Directory>()
          .map((d) => d.path.split('/').last)
          .toSet()
      : <String>{};

  var syncedCount = 0;
  var addedCount = 0;

  for (final item in templateItems) {
    final templateItem = Directory('$templateDir/$item');
    final localItem = Directory('$localDir/$item');

    if (localItems.contains(item)) {
      // Replace existing item
      if (dryRun) {
        print('  Would sync: $item');
      } else {
        if (localItem.existsSync()) {
          localItem.deleteSync(recursive: true);
        }
        _copyDirectory(templateItem, localItem);
        print('  Synced: $item');
      }
      syncedCount++;
    } else {
      // Add new item
      if (dryRun) {
        print('  Would add: $item (new)');
      } else {
        _copyDirectory(templateItem, localItem);
        print('  Added: $item (new)');
      }
      addedCount++;
    }
  }

  if (syncedCount == 0 && addedCount == 0) {
    print('  No ${itemType}s to sync');
  }

  return SyncResult(synced: syncedCount, added: addedCount);
}

/// Sync subdirectories matching a prefix from template to local
SyncResult _syncDirectoryWithPrefix({
  required String templateDir,
  required String localDir,
  required String prefix,
  required String itemType,
  required bool dryRun,
}) {
  final templateDirectory = Directory(templateDir);
  if (!templateDirectory.existsSync()) {
    print('  Warning: $templateDir not found in template');
    return SyncResult(synced: 0, added: 0);
  }

  final localDirectory = Directory(localDir);
  if (!localDirectory.existsSync()) {
    if (!dryRun) {
      localDirectory.createSync(recursive: true);
    }
  }

  // Get list of items in template matching prefix
  final templateItems = templateDirectory
      .listSync()
      .whereType<Directory>()
      .map((d) => d.path.split('/').last)
      .where((name) => name.startsWith(prefix))
      .toList();

  // Get list of local items matching prefix
  final localItems = localDirectory.existsSync()
      ? localDirectory
          .listSync()
          .whereType<Directory>()
          .map((d) => d.path.split('/').last)
          .where((name) => name.startsWith(prefix))
          .toSet()
      : <String>{};

  var syncedCount = 0;
  var addedCount = 0;

  for (final item in templateItems) {
    final templateItem = Directory('$templateDir/$item');
    final localItem = Directory('$localDir/$item');

    if (localItems.contains(item)) {
      // Replace existing item
      if (dryRun) {
        print('  Would sync: $item');
      } else {
        if (localItem.existsSync()) {
          localItem.deleteSync(recursive: true);
        }
        _copyDirectory(templateItem, localItem);
        print('  Synced: $item');
      }
      syncedCount++;
    } else {
      // Add new item
      if (dryRun) {
        print('  Would add: $item (new)');
      } else {
        _copyDirectory(templateItem, localItem);
        print('  Added: $item (new)');
      }
      addedCount++;
    }
  }

  if (syncedCount == 0 && addedCount == 0) {
    print('  No ${itemType}s matching "$prefix*" to sync');
  }

  return SyncResult(synced: syncedCount, added: addedCount);
}

/// Sync all files from template to local directory
SyncResult _syncFiles({
  required String templateDir,
  required String localDir,
  required String itemType,
  required bool dryRun,
}) {
  final templateDirectory = Directory(templateDir);
  if (!templateDirectory.existsSync()) {
    print('  Warning: $templateDir not found in template');
    return SyncResult(synced: 0, added: 0);
  }

  final localDirectory = Directory(localDir);
  if (!localDirectory.existsSync()) {
    if (!dryRun) {
      localDirectory.createSync(recursive: true);
    }
  }

  // Get list of files in template
  final templateFiles = templateDirectory
      .listSync()
      .whereType<File>()
      .map((f) => f.path.split('/').last)
      .toList();

  // Get list of local files
  final localFiles = localDirectory.existsSync()
      ? localDirectory
          .listSync()
          .whereType<File>()
          .map((f) => f.path.split('/').last)
          .toSet()
      : <String>{};

  var syncedCount = 0;
  var addedCount = 0;

  for (final fileName in templateFiles) {
    final templateFile = File('$templateDir/$fileName');
    final localFile = File('$localDir/$fileName');

    if (localFiles.contains(fileName)) {
      // Replace existing file
      if (dryRun) {
        print('  Would sync: $fileName');
      } else {
        if (localFile.existsSync()) {
          localFile.deleteSync();
        }
        templateFile.copySync(localFile.path);
        print('  Synced: $fileName');
      }
      syncedCount++;
    } else {
      // Add new file
      if (dryRun) {
        print('  Would add: $fileName (new)');
      } else {
        templateFile.copySync(localFile.path);
        print('  Added: $fileName (new)');
      }
      addedCount++;
    }
  }

  if (syncedCount == 0 && addedCount == 0) {
    print('  No ${itemType}s to sync');
  }

  return SyncResult(synced: syncedCount, added: addedCount);
}

/// Copy a directory recursively
void _copyDirectory(Directory source, Directory destination) {
  if (!destination.existsSync()) {
    destination.createSync(recursive: true);
  }

  for (final entity in source.listSync(recursive: false)) {
    final newPath = '${destination.path}/${entity.path.split('/').last}';

    if (entity is File) {
      entity.copySync(newPath);
    } else if (entity is Directory) {
      _copyDirectory(entity, Directory(newPath));
    }
  }
}
