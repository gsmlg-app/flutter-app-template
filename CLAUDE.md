# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Flutter monorepo template with modular architecture, BLoC state management, and comprehensive tooling. Follows clean architecture principles with separation of concerns across specialized packages.

**Requirements**: Flutter SDK >=3.8.0, Dart >=3.8.0

## Architecture Structure

```
├── lib/                    # Main app entry point
├── app_bloc/               # BLoC state management packages
├── app_lib/                # Core utilities (database, locale, logging, provider)
├── app_widget/             # Reusable UI components (artwork, chart, web_view)
├── app_form/               # Form modules with BLoC state management
├── app_plugin/             # Native platform plugins with federated architecture
├── bricks/                 # Mason templates for code generation
└── test_bricks/            # Brick tests (one folder per brick)
```

**Workspace packages** (defined in root `pubspec.yaml` `workspace:` section—there is no separate melos.yaml):
- `app_lib/`: database, gamepad, locale, provider, logging, secure_storage, vector_store
- `app_bloc/`: gamepad, navigation
- `app_widget/`: artwork, chart, web_view
- `app_form/`: demo
- `app_plugin/`: client_info/ (nested federated plugin containing: client_info, client_info_platform_interface, client_info_android, client_info_ios, client_info_linux, client_info_macos, client_info_windows)

**External UI packages** (from pub.dev, pinned in root pubspec.yaml):
- `duskmoon_ui` (^1.4.2) — umbrella re-exporting all duskmoon packages below
- `duskmoon_theme_bloc` (^1.4.2) — BLoC for theme persistence via SharedPreferences
- Sub-packages (re-exported by `duskmoon_ui`):
  - `duskmoon_theme` — theme system, color schemes (sunshine/moonlight/forest/ocean), DmThemeData
  - `duskmoon_widgets` — 19 adaptive widgets (DmButton, DmAppBar, DmSwitch, DmSlider, DmTextField, DmCheckbox, DmDropdown, DmCard, etc.), DmMarkdown, DmCodeEditor
  - `duskmoon_settings` — platform-aware settings UI (SettingsList, SettingsSection, SettingsTile)
  - `duskmoon_feedback` — showDmDialog, showDmSnackbar, showDmSuccessToast, showDmErrorToast, showDmBottomSheetActionList
  - `duskmoon_form` — BLoC-based form management (FormBloc, TextFieldBloc, DmTextFieldBlocBuilder, etc.)
  - `duskmoon_visualization` — data visualization charts (line, bar, scatter, heatmap, network, map)
  - `duskmoon_adaptive_scaffold` — DmAdaptiveScaffold with responsive M3 layout and breakpoints
  - `duskmoon_code_engine` — pure Dart code editor with 19 language grammars

## Custom Skills (Claude Code)

Project-specific skill available in `.claude/skills/`:
- `/template-mason-brick` - Create, update, or remove Mason bricks with tests

External skills (from plugins):
- `/gsmlg-app:flutter-duskmoon` - DuskMoon UI design system reference for all duskmoon_* packages

## Development Commands

### Setup
```bash
dart pub global activate melos
dart pub global activate mason_cli
melos bootstrap
mason get
```

### Common Workflows
```bash
melos run prepare          # Bootstrap + gen-l10n + build-runner (full setup)
melos run analyze          # Lint all packages (--fatal-warnings)
melos run format           # Format all packages
melos run format-check     # Check formatting (CI uses this, exits non-zero if changes needed)
melos run fix              # Apply dart fix --apply
melos run test             # Run all tests (flutter + dart)
```

### Individual Package Operations
```bash
# Test single file
flutter test test/screens/splash_screen_test.dart

# Package-specific commands
cd app_lib/database && flutter test
cd app_lib/database && dart run build_runner build --delete-conflicting-outputs
```

### Code Generation with Mason
```bash
# Screens and widgets
mason make screen --name ScreenName --folder subfolder
mason make widget --name WidgetName --type stateless --folder components

# BLoC patterns
mason make simple_bloc -o app_bloc/feature_name --name=feature_name
mason make list_bloc -o app_bloc/feature_name --name=feature_name
mason make form_bloc --name Login --field_names "email,password"

# Other generators
mason make repository -o app_lib/feature_name --name=feature_name
mason make api_client -o app_api/app_api --package_name=app_api

# Native plugins (prefer native_plugin for simplicity)
mason make native_plugin --name plugin_name --description "Description" --package_prefix app -o app_plugin
# Use native_federation_plugin only when publishing separate platform packages
mason make native_federation_plugin --name plugin_name --description "Description" --package_prefix app -o app_plugin
```

See [BRICKS.md](./docs/BRICKS.md) for complete brick documentation.

### Template Scripts
```bash
# Rename template to your project name (run once after cloning)
dart run bin/setup_project.dart my_project_name

# Update bricks from upstream template (only works after renaming)
dart run bin/update_bricks.dart
dart run bin/update_bricks.dart --force  # Force update all bricks
```

## Key Entry Points

- `lib/main.dart` - App initialization: MainProvider, AppLogger, AppDatabase, SharedPreferences
- `lib/app.dart` - Root widget with DmThemeBloc and MaterialApp.router
- `lib/router.dart` - GoRouter configuration with NoTransitionPage
- `lib/screens/` - Feature screens (app/, home/, settings/)

## Package Dependencies

Use `<package_name>: any` for workspace packages in pubspec.yaml dependencies. Melos resolves internal dependencies through the workspace configuration. Never use path dependencies.

## Architecture Patterns

### App Initialization (lib/main.dart)
```dart
MainProvider(
  sharedPrefs: sharedPrefs,
  database: database,
  child: MaterialApp(...),
)
```

### Routing Pattern
Screens define static `name` and `path` constants for GoRouter integration:
```dart
class HomeScreen extends StatelessWidget {
  static const name = 'home';
  static const path = '/home';
}
```

### Logging
Use `AppLogger` from `app_logging` package with configurable levels (debug, info, warning, error). Logs to file in application support directory.

### Theme
`DmThemeBloc` (from `duskmoon_theme_bloc`) manages theme state with automatic SharedPreferences persistence. Available themes are defined by `DmThemeData.themes`. Events: `DmSetTheme(name)`, `DmSetThemeMode(mode)`. State: `DmThemeState` with `.themeName`, `.themeMode`, `.entry` (DmThemeEntry with `.light`/`.dark` ThemeData).

### DuskMoon UI Conventions
All screens use `duskmoon_ui` widgets. Prefer Dm-prefixed widgets over plain Flutter equivalents:
- **Scaffold**: `DmAdaptiveScaffold` with `destinations`, `selectedIndex`, `body` builder
- **Buttons**: `DmButton` (replaces ElevatedButton/FilledButton/TextButton via `variant: DmButtonVariant`)
- **AppBar**: `DmAppBar` (adaptive Material/Cupertino)
- **Inputs**: `DmTextField`, `DmSwitch`, `DmCheckbox`, `DmSlider`, `DmDropdown`
- **Dialogs**: `showDmDialog` with `DmDialogAction` (replaces showDialog+AlertDialog)
- **Snackbars**: `showDmSnackbar` (replaces ScaffoldMessenger.showSnackBar)
- **Toasts**: `showDmSuccessToast`, `showDmErrorToast`
- **Settings**: `SettingsList`, `SettingsSection`, `SettingsTile` (from `duskmoon_settings`)
- **Forms**: `DmTextFieldBlocBuilder`, `DmCheckboxFieldBlocBuilder`, etc. (from `duskmoon_form`)
- **Import**: `import 'package:duskmoon_ui/duskmoon_ui.dart';` (umbrella, includes flutter_bloc re-export)

## Testing

Tests co-located with packages in `test/` directories. Main app has comprehensive screen tests in `test/screens/`.

```bash
melos run test:dart       # Non-Flutter packages only
melos run test:flutter    # Flutter packages only
```

Brick tests are in `test_bricks/` (one folder per brick) and run via GitHub Actions workflow `brick-test.yml`.

## Development Environment

Uses Nix/Devenv for reproducible environment. Auto-loads via direnv (`.envrc`). Flutter SDK version managed through `devenv.nix`.

**macOS Entitlements**: When using `flutter_secure_storage`, the app requires `keychain-access-groups` entitlement in both `macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements`.

## Git Configuration

- **Git LFS**: Images (png, jpg, ico, etc.) tracked with LFS. Run `git lfs install` after cloning.
- **Lock files**: Treated as binary in `.gitattributes` to avoid merge conflicts.

## Code Style

- flutter_lints rules from analysis_options.yaml
- BLoC pattern for state management
- Repository pattern for data layer
- Prefer const constructors
- Use AppLogger for error handling with logging

## Running the App

```bash
flutter run                # Default device
flutter run -d chrome      # Web
flutter run -d macos       # macOS
flutter run -d linux       # Linux
```

## CI Workflows

- `ci.yml` - Format check, analyze, test, and build (skips for docs/config changes)
- `brick-test.yml` - Tests Mason bricks (only runs when brick files change)
- `release.yml` - Manual workflow for creating releases with platform builds