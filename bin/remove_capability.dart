#!/usr/bin/env dart

// ignore_for_file: avoid_print

import 'dart:io';

/// Script to prune / remove capabilities from the flutter-app-template.
///
/// Features:
/// - Subtractive pruning (physical package deletion and registry cleanup)
/// - Dry-run mode (--dry-run)
/// - Rollback on unexpected failure
/// - Updates pubspec.yaml, template.yaml, lib/router.dart, lib/main.dart, and showcase screens
///
/// Usage:
///   dart run bin/remove_capability.dart `capability_1` [capability_2 ...] [options]
///   dart run bin/remove_capability.dart gamepad chart web_view --dry-run
void main(List<String> args) async {
  final capabilitiesToRemove = <String>[];
  var dryRun = false;
  var force = false;

  for (final arg in args) {
    if (arg == '--dry-run') {
      dryRun = true;
    } else if (arg == '--force' || arg == '-f') {
      force = true;
    } else if (!arg.startsWith('-')) {
      capabilitiesToRemove.add(arg.trim().toLowerCase());
    }
  }

  if (capabilitiesToRemove.isEmpty) {
    print(
      'Usage: dart run bin/remove_capability.dart <capability_name...> [--dry-run] [--force]',
    );
    print('\nAvailable capabilities to remove:');
    print(
      '  - gamepad        (app_lib/gamepad, app_bloc/gamepad, controller screens)',
    );
    print('  - chart          (app_widget/chart, chart demo screen)');
    print('  - web_view       (app_widget/web_view, webview demo screen)');
    print(
      '  - client_info    (app_plugin/client_info federated plugin, client info screen)',
    );
    print('  - vector_store   (app_lib/vector_store)');
    print('  - form           (app_form/demo, form demo screen)');
    print('  - secure_storage (app_lib/secure_storage, vault demo screen)');
    print('  - database       (app_lib/database, drift sqlite layer)');
    print('  - artwork        (app_widget/artwork, artwork demo screen)');
    exit(1);
  }

  // Check Git clean tree
  if (!dryRun && !force) {
    final gitStatus = Process.runSync('git', ['status', '--porcelain']);
    if (gitStatus.exitCode == 0 &&
        gitStatus.stdout.toString().trim().isNotEmpty) {
      print(
        '❌ Error: Git working tree is dirty. Commit or stash changes before pruning, or pass --force.',
      );
      exit(1);
    }
  }

  print('\n========================================');
  print('Capability Pruning');
  print('========================================');
  print('Capabilities to remove: ${capabilitiesToRemove.join(", ")}');
  print('Mode:                   ${dryRun ? "DRY RUN (no changes)" : "LIVE"}');
  print('========================================\n');

  final backup = <String, String>{};
  final filesToDelete = <String>[];
  final directoriesToDelete = <String>[];

  try {
    for (final cap in capabilitiesToRemove) {
      print('Pruning capability: $cap');
      _pruneCapability(cap, dryRun, backup, filesToDelete, directoriesToDelete);
    }

    // Update pubspec.yaml workspace and dependencies
    _updatePubspec(capabilitiesToRemove, dryRun, backup);

    // Update template.yaml
    _updateTemplateYaml(capabilitiesToRemove, dryRun, backup);

    // Update lib/router.dart
    _updateRouter(capabilitiesToRemove, dryRun, backup);

    // Update lib/screens/showcase/showcase_screen.dart
    _updateShowcaseScreen(capabilitiesToRemove, dryRun, backup);

    // Update lib/screens/settings/settings_screen.dart
    if (capabilitiesToRemove.contains('gamepad')) {
      _updateSettingsScreen(dryRun, backup);
      _updateMainActivityForGamepad(dryRun, backup);
    }

    // Update lib/main.dart
    _updateMainDart(capabilitiesToRemove, dryRun, backup);

    // Execute physical deletions
    if (!dryRun) {
      for (final filePath in filesToDelete) {
        final file = File(filePath);
        if (file.existsSync()) {
          file.deleteSync();
          print('  🗑️ Deleted file: $filePath');
        }
      }
      for (final dirPath in directoriesToDelete) {
        final dir = Directory(dirPath);
        if (dir.existsSync()) {
          dir.deleteSync(recursive: true);
          print('  🗑️ Deleted directory: $dirPath');
        }
      }
    } else {
      for (final filePath in filesToDelete) {
        print('  [DRY RUN] Would delete file: $filePath');
      }
      for (final dirPath in directoriesToDelete) {
        print('  [DRY RUN] Would delete directory: $dirPath');
      }
    }

    print('\n========================================');
    if (dryRun) {
      print(
        'DRY RUN COMPLETE: Pruning simulation finished without modifying files.',
      );
    } else {
      print(
        'SUCCESS: Capabilities [${capabilitiesToRemove.join(", ")}] removed successfully.',
      );
      print('\nNext steps:');
      print('  1. dart bin/verify_template.dart');
      print('  2. dart format lib test bin');
      print('  3. flutter analyze --no-pub');
    }
    print('========================================\n');
  } catch (e, st) {
    print('❌ Error during capability pruning: $e');
    print(st);
    if (!dryRun && backup.isNotEmpty) {
      print('\nRolling back file modifications...');
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

void _pruneCapability(
  String cap,
  bool dryRun,
  Map<String, String> backup,
  List<String> filesToDelete,
  List<String> directoriesToDelete,
) {
  switch (cap) {
    case 'gamepad':
      directoriesToDelete.add('app_lib/gamepad');
      directoriesToDelete.add('app_bloc/gamepad');
      filesToDelete.add('lib/screens/settings/controller_settings_screen.dart');
      filesToDelete.add('lib/screens/settings/controller_test_screen.dart');
      directoriesToDelete.add('lib/screens/settings/widgets');
      break;

    case 'chart':
      directoriesToDelete.add('app_widget/chart');
      filesToDelete.add('lib/screens/showcase/chart_demo_screen.dart');
      break;

    case 'web_view':
      directoriesToDelete.add('app_widget/web_view');
      filesToDelete.add('lib/screens/showcase/webview_demo_screen.dart');
      break;

    case 'client_info':
      directoriesToDelete.add('app_plugin/client_info');
      filesToDelete.add('lib/screens/showcase/client_info_screen.dart');
      break;

    case 'vector_store':
      directoriesToDelete.add('app_lib/vector_store');
      break;

    case 'form':
      directoriesToDelete.add('app_form/demo');
      filesToDelete.add('lib/screens/showcase/form_demo_screen.dart');
      break;

    case 'secure_storage':
      directoriesToDelete.add('app_lib/secure_storage');
      filesToDelete.add('lib/screens/showcase/vault_demo_screen.dart');
      break;

    case 'database':
      directoriesToDelete.add('app_lib/database');
      break;

    case 'artwork':
      directoriesToDelete.add('app_widget/artwork');
      filesToDelete.add('lib/screens/showcase/artwork_demo_screen.dart');
      break;

    default:
      print(
        '  ⚠️ Warning: Unknown capability "$cap", skipping directory deletion.',
      );
  }
}

void _updatePubspec(
  List<String> caps,
  bool dryRun,
  Map<String, String> backup,
) {
  final file = File('pubspec.yaml');
  if (!file.existsSync()) return;

  final content = file.readAsStringSync();
  backup[file.path] = content;

  var updated = content;

  for (final cap in caps) {
    switch (cap) {
      case 'gamepad':
        updated = _removeLinesMatching(updated, [
          r'-\s+app_lib/gamepad',
          r'-\s+app_bloc/gamepad',
          r'app_gamepad:',
          r'gamepad_bloc:',
        ]);
        break;
      case 'chart':
        updated = _removeLinesMatching(updated, [
          r'-\s+app_widget/chart',
          r'app_chart:',
        ]);
        break;
      case 'web_view':
        updated = _removeLinesMatching(updated, [
          r'-\s+app_widget/web_view',
          r'app_web_view:',
        ]);
        break;
      case 'client_info':
        updated = _removeLinesMatching(updated, [
          r'-\s+app_plugin/client_info/.*',
          r'app_client_info:',
        ]);
        break;
      case 'vector_store':
        updated = _removeLinesMatching(updated, [
          r'-\s+app_lib/vector_store',
          r'vector_store:',
        ]);
        break;
      case 'form':
        updated = _removeLinesMatching(updated, [
          r'-\s+app_form/demo',
          r'demo_form:',
        ]);
        break;
      case 'secure_storage':
        updated = _removeLinesMatching(updated, [
          r'-\s+app_lib/secure_storage',
          r'app_secure_storage:',
        ]);
        break;
      case 'database':
        updated = _removeLinesMatching(updated, [
          r'-\s+app_lib/database',
          r'app_database:',
        ]);
        break;
      case 'artwork':
        updated = _removeLinesMatching(updated, [
          r'-\s+app_widget/artwork',
          r'app_artwork:',
        ]);
        break;
    }
  }

  if (dryRun) {
    print('  [DRY RUN] Would update pubspec.yaml');
  } else {
    file.writeAsStringSync(updated);
    print('  ✓ Updated pubspec.yaml');
  }
}

void _updateTemplateYaml(
  List<String> caps,
  bool dryRun,
  Map<String, String> backup,
) {
  final file = File('template.yaml');
  if (!file.existsSync()) return;

  final content = file.readAsStringSync();
  backup[file.path] = content;

  var updated = content;
  for (final cap in caps) {
    final capRegex = RegExp(r'  ' + cap + r':\n(?:    [^\n]+\n|\s*\n)+');
    updated = updated.replaceAll(capRegex, '');
  }

  if (dryRun) {
    print('  [DRY RUN] Would update template.yaml');
  } else {
    file.writeAsStringSync(updated);
    print('  ✓ Updated template.yaml');
  }
}

void _updateRouter(List<String> caps, bool dryRun, Map<String, String> backup) {
  final file = File('lib/router.dart');
  if (!file.existsSync()) return;

  final content = file.readAsStringSync();
  backup[file.path] = content;

  var updated = content;

  if (caps.contains('gamepad')) {
    updated = _removeImports(updated, [
      'screens/settings/controller_settings_screen.dart',
      'screens/settings/controller_test_screen.dart',
    ]);
    updated = _removeRouteBlock(updated, 'ControllerSettingsScreen');
  }
  if (caps.contains('chart')) {
    updated = _removeImports(updated, [
      'screens/showcase/chart_demo_screen.dart',
    ]);
    updated = _removeRouteBlock(updated, 'ChartDemoScreen');
  }
  if (caps.contains('web_view')) {
    updated = _removeImports(updated, [
      'screens/showcase/webview_demo_screen.dart',
    ]);
    updated = _removeRouteBlock(updated, 'WebViewDemoScreen');
  }
  if (caps.contains('client_info')) {
    updated = _removeImports(updated, [
      'screens/showcase/client_info_screen.dart',
    ]);
    updated = _removeRouteBlock(updated, 'ClientInfoScreen');
  }
  if (caps.contains('form')) {
    updated = _removeImports(updated, [
      'screens/showcase/form_demo_screen.dart',
    ]);
    updated = _removeRouteBlock(updated, 'FormDemoScreen');
  }
  if (caps.contains('secure_storage')) {
    updated = _removeImports(updated, [
      'screens/showcase/vault_demo_screen.dart',
    ]);
    updated = _removeRouteBlock(updated, 'VaultDemoScreen');
  }
  if (caps.contains('artwork')) {
    updated = _removeImports(updated, [
      'screens/showcase/artwork_demo_screen.dart',
    ]);
    updated = _removeRouteBlock(updated, 'ArtworkDemoScreen');
  }

  if (dryRun) {
    print('  [DRY RUN] Would update lib/router.dart');
  } else {
    file.writeAsStringSync(updated);
    print('  ✓ Updated lib/router.dart');
  }
}

void _updateShowcaseScreen(
  List<String> caps,
  bool dryRun,
  Map<String, String> backup,
) {
  final file = File('lib/screens/showcase/showcase_screen.dart');
  if (!file.existsSync()) return;

  final content = file.readAsStringSync();
  backup[file.path] = content;

  var updated = content;

  if (caps.contains('chart')) {
    updated = _removeImports(updated, [
      'screens/showcase/chart_demo_screen.dart',
    ]);
    updated = _removeShowcaseCard(updated, 'ChartDemoScreen');
  }
  if (caps.contains('web_view')) {
    updated = _removeImports(updated, [
      'screens/showcase/webview_demo_screen.dart',
    ]);
    updated = _removeShowcaseCard(updated, 'WebViewDemoScreen');
  }
  if (caps.contains('client_info')) {
    updated = _removeImports(updated, [
      'screens/showcase/client_info_screen.dart',
    ]);
    updated = _removeShowcaseCard(updated, 'ClientInfoScreen');
  }
  if (caps.contains('form')) {
    updated = _removeImports(updated, [
      'screens/showcase/form_demo_screen.dart',
    ]);
    updated = _removeShowcaseCard(updated, 'FormDemoScreen');
  }
  if (caps.contains('secure_storage')) {
    updated = _removeImports(updated, [
      'screens/showcase/vault_demo_screen.dart',
    ]);
    updated = _removeShowcaseCard(updated, 'VaultDemoScreen');
  }
  if (caps.contains('artwork')) {
    updated = _removeImports(updated, [
      'screens/showcase/artwork_demo_screen.dart',
    ]);
    updated = _removeShowcaseCard(updated, 'ArtworkDemoScreen');
  }

  if (dryRun) {
    print('  [DRY RUN] Would update lib/screens/showcase/showcase_screen.dart');
  } else {
    file.writeAsStringSync(updated);
    print('  ✓ Updated lib/screens/showcase/showcase_screen.dart');
  }
}

void _updateSettingsScreen(bool dryRun, Map<String, String> backup) {
  final file = File('lib/screens/settings/settings_screen.dart');
  if (!file.existsSync()) return;

  final content = file.readAsStringSync();
  backup[file.path] = content;

  var updated = content;
  updated = _removeImports(updated, [
    'screens/settings/controller_settings_screen.dart',
    'package:gamepad_bloc/gamepad_bloc.dart',
  ]);

  // Remove GamepadBloc builder wrapper and controller settings section
  final gamepadSectionRegex = RegExp(
    r'SettingsSection\(\s*title:\s*Text\(context\.l10n\.controllerSettings\),[\s\S]*?\),\s*',
  );
  updated = updated.replaceAll(gamepadSectionRegex, '');

  final blocBuilderGamepadRegex = RegExp(
    r'return BlocBuilder<GamepadBloc, GamepadState>\(\s*builder: \(context, gamepadState\) \{\s*(return SettingsList\([\s\S]*?\);)\s*\},?\s*\);',
  );
  final match = blocBuilderGamepadRegex.firstMatch(updated);
  if (match != null) {
    updated = updated.replaceAll(blocBuilderGamepadRegex, match.group(1)!);
  }

  if (dryRun) {
    print('  [DRY RUN] Would update lib/screens/settings/settings_screen.dart');
  } else {
    file.writeAsStringSync(updated);
    print('  ✓ Updated lib/screens/settings/settings_screen.dart');
  }
}

void _updateMainActivityForGamepad(bool dryRun, Map<String, String> backup) {
  final kotlinDir = Directory('android/app/src/main/kotlin');
  if (!kotlinDir.existsSync()) return;

  for (final entity in kotlinDir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('MainActivity.kt')) {
      final content = entity.readAsStringSync();
      backup[entity.path] = content;

      var updated = content;
      updated = updated.replaceAll(
        'import org.flame_engine.gamepads_android.GamepadsCompatibleActivity\n',
        '',
      );
      updated = updated.replaceAll(
        'import org.flame_engine.gamepads_android.GamepadsCompatibleActivity',
        '',
      );
      updated = updated.replaceAll(
        'class MainActivity : FlutterActivity(), GamepadsCompatibleActivity {',
        'class MainActivity : FlutterActivity() {',
      );
      updated = updated.replaceAll(
        'class MainActivity: FlutterActivity(), GamepadsCompatibleActivity {',
        'class MainActivity: FlutterActivity() {',
      );

      if (dryRun) {
        print(
          '  [DRY RUN] Would update ${entity.path} (remove GamepadsCompatibleActivity)',
        );
      } else {
        entity.writeAsStringSync(updated);
        print('  ✓ Updated ${entity.path}');
      }
    }
  }
}

void _updateMainDart(
  List<String> caps,
  bool dryRun,
  Map<String, String> backup,
) {
  final file = File('lib/main.dart');
  if (!file.existsSync()) return;

  final content = file.readAsStringSync();
  backup[file.path] = content;

  var updated = content;

  if (caps.contains('database')) {
    updated = _removeImports(updated, [
      'package:app_database/app_database.dart',
    ]);
    updated = updated.replaceAll(
      RegExp(r'final database = AppDatabase\(\);\s*'),
      '',
    );
    updated = updated.replaceAll(RegExp(r'database:\s*database,\s*'), '');
  }
  if (caps.contains('secure_storage')) {
    updated = _removeImports(updated, [
      'package:app_secure_storage/app_secure_storage.dart',
    ]);
    updated = updated.replaceAll(
      RegExp(r'final vault = SecureStorageVaultRepository\(\);\s*'),
      '',
    );
    updated = updated.replaceAll(RegExp(r'vault:\s*vault,\s*'), '');
  }

  if (dryRun) {
    print('  [DRY RUN] Would update lib/main.dart');
  } else {
    file.writeAsStringSync(updated);
    print('  ✓ Updated lib/main.dart');
  }
}

String _removeLinesMatching(String content, List<String> patterns) {
  final lines = content.split('\n');
  final regexes = patterns.map((p) => RegExp(p)).toList();
  final filtered = lines.where((line) {
    return !regexes.any((r) => r.hasMatch(line));
  }).toList();
  return filtered.join('\n');
}

String _removeImports(String content, List<String> importSubstrings) {
  final lines = content.split('\n');
  final filtered = lines.where((line) {
    if (!line.trim().startsWith('import ')) return true;
    return !importSubstrings.any((sub) => line.contains(sub));
  }).toList();
  return filtered.join('\n');
}

String _removeRouteBlock(String content, String screenName) {
  final regex = RegExp(
    r'GoRoute\(\s*name:\s*' + screenName + r'\.name,[\s\S]*?\),?\s*',
  );
  return content.replaceAll(regex, '');
}

String _removeShowcaseCard(String content, String screenName) {
  final regex = RegExp(
    r'_buildDemoCard\([\s\S]*?context\.goNamed\(' +
        screenName +
        r'\.name\),\s*\),?\s*(?:const SizedBox\(height: \d+\),)?',
  );
  return content.replaceAll(regex, '');
}
