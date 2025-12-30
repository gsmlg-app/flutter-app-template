# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Flutter monorepo template with modular architecture, BLoC state management, and comprehensive tooling. Follows clean architecture principles with separation of concerns across specialized packages.

## Architecture Structure

```
├── lib/                    # Main app entry point
├── app_bloc/               # BLoC state management packages
├── app_lib/                # Core utilities (database, theme, locale, logging, provider)
├── app_widget/             # Reusable UI components (adaptive, artwork, feedback, web_view)
├── app_plugin/             # Native platform plugins with federated architecture
├── bricks/                 # Mason templates for code generation
└── third_party/            # Modified third-party packages
```

**Workspace packages** (defined in root `pubspec.yaml` workspace section):
- `app_lib/`: database, theme, locale, provider, logging
- `app_bloc/`: theme
- `app_widget/`: adaptive, artwork, feedback, web_view
- `app_plugin/`: client_info (federated plugin with platform implementations)
- `third_party/`: form_bloc, flutter_form_bloc, flutter_adaptive_scaffold, settings_ui

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
melos run analyze          # Lint all packages (--fatal-infos)
melos run format           # Format all packages
melos run fix              # Apply dart fix --apply
melos run test             # Run all tests (flutter + dart)
melos run brick-test       # Test Mason bricks (tool/brick_tests/)
```

### Individual Package Operations
```bash
# Test single file
flutter test test/screens/splash_screen_test.dart

# Package-specific commands
cd app_lib/theme && flutter test
cd app_lib/theme && dart run build_runner build --delete-conflicting-outputs
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
mason make native_federation_plugin --name plugin_name --description "Description" --package_prefix app -o app_plugin
```

See [BRICKS.md](./BRICKS.md) for complete brick documentation.

## Key Entry Points

- `lib/main.dart` - App initialization: MainProvider, AppLogger, AppDatabase, SharedPreferences
- `lib/app.dart` - Root widget with ThemeBloc and MaterialApp.router
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
`ThemeBloc` manages theme state. Available color schemes: fire, green, violet, wheat. Supports light/dark modes.

## Testing

Tests co-located with packages in `test/` directories. Main app has comprehensive screen tests in `test/screens/`.

```bash
melos run test:dart       # Non-Flutter packages only
melos run test:flutter    # Flutter packages only
melos run test:selective  # Only packages with test/ directory
```

## Development Environment

Uses Nix/Devenv for reproducible environment. Auto-loads via direnv (`.envrc`). Flutter SDK version managed through `devenv.nix`.

## Code Style

- flutter_lints rules from analysis_options.yaml
- BLoC pattern for state management
- Repository pattern for data layer
- Prefer const constructors
- Use AppLogger for error handling with logging