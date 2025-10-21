# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a sophisticated Flutter monorepo template that demonstrates modern Flutter development practices with modular architecture, BLoC state management, and comprehensive tooling setup. The project follows clean architecture principles with separation of concerns across multiple specialized packages, providing a production-ready foundation for building scalable Flutter applications.

## Architecture Structure

### Monorepo Organization
- **Main App**: `lib/` - Entry point and main application code
- **State Management**: `app_bloc/` - BLoC pattern implementations for business logic
- **Shared Libraries**: `app_lib/` - Core utilities, themes, localization, database, logging
- **UI Components**: `app_widget/` - Reusable widgets and UI elements
- **Code Generation**: `bricks/` - Mason templates for scaffolding
- **Third-party**: `third_party/` - Modified/custom third-party packages

### Key Packages
- **app_database**: Database management and data persistence
- **app_theme**: Theme management with multiple color schemes (fire, green, violet, wheat)
- **app_locale**: Internationalization support with ARB files, outputs to `lib/gen_l10n/`
- **app_provider**: Dependency injection and app-level providers using `MainProvider`
- **app_logging**: Structured logging with file output support
- **theme_bloc**: State management for theme switching
- **app_adaptive_widgets**: Responsive/adaptive UI components
- **app_artwork**: Asset management (icons, lottie animations)
- **app_feedback**: User feedback mechanisms (snackbars, dialogs, toasts)
- **app_web_view**: Web view integration components
- **settings_ui**: Custom settings UI components

## Development Commands

### Setup & Installation
```bash
# Install global dependencies
dart pub global activate melos
dart pub global activate mason_cli

# Bootstrap the project
melos bootstrap

# Initialize mason
mason get
```

### Development Workflow
```bash
# Code quality and analysis
melos run analyze      # Run Flutter analysis for all packages
melos run format       # Format all Dart code
melos run fix          # Apply automatic fixes

# Testing
melos run test         # Run Flutter tests for all packages
melos run test:dart    # Run Dart tests for non-Flutter packages
melos run test:flutter # Run Flutter tests
melos run test:all     # All tests including brick tests
melos run test:coverage # Run tests with coverage reports
melos run test:watch   # Watch mode for development

# Code generation
melos run prepare      # Bootstrap + gen-l10n + build-runner
melos run build-runner # Run build_runner
melos run gen-l10n     # Generate localization files

# Dependency management
melos run validate-dependencies # Validate dependencies usage
melos run outdated      # Check outdated dependencies
```

### Individual Package Commands
```bash
# Run tests for specific package
cd app_lib/theme && flutter test

# Analyze specific package
cd app_widget/adaptive && flutter analyze

# Build specific package
cd app_lib/theme && dart run build_runner build --delete-conflicting-outputs

# Run single test
flutter test test/widget_test.dart
```

### Code Generation
```bash
# Generate API client
mason make api_client -o app_api/app_api --package_name=app_api
# Then add openapi spec to app_api/app_api/openapi.yaml

# Generate new BLoC
mason make simple_bloc -o app_bloc/feature_name --name=feature_name

# Generate new list BLoC
mason make list_bloc -o app_bloc/feature_name --name=feature_name

# Generate new form BLoC
mason make form_bloc --name Login --field_names "email,password"

# Generate new repository
mason make repository -o app_lib/feature_name --name=feature_name

# Generate new screen
mason make screen --name ScreenName --folder subfolder

# Generate new widget
mason make widget --name WidgetName --type stateless --folder components
```

For complete documentation on all available Mason bricks and their usage, see [BRICKS.md](./BRICKS.md).

### Running the App
```bash
# Development
flutter run

# Specific platform
flutter run -d chrome
flutter run -d android
flutter run -d ios

# Generate app icons
dart run flutter_launcher_icons:main
```

## Key Files & Entry Points

- **Main Entry**: `lib/main.dart` - App initialization with `MainProvider`, logging setup, database initialization
- **App Shell**: `lib/app.dart` - Root widget with `ThemeBloc` integration and `MaterialApp.router`
- **Routing**: `lib/router.dart` - GoRouter configuration with declarative routing and `NoTransitionPage`
- **Screens**: `lib/screens/` - Feature screens organized by domain (app/, home/, settings/)
- **Localization**: `lib/arb/` - ARB files for i18n, generated to `lib/gen_l10n/`

## Configuration Files

- **Melos**: `pubspec.yaml` (workspace configuration with scripts)
- **Mason**: `mason.yaml` (code generation templates: api_client, simple_bloc, list_bloc, form_bloc, repository, screen, widget)
- **Analysis**: `analysis_options.yaml` (linting rules, excludes generated files)
- **Localization**: `app_lib/locale/l10n.yaml` (i18n configuration)
- **Environment**: `.envrc`, `devenv.nix` (development environment setup)

## Testing Structure

### Test Organization
Tests are co-located with their respective packages:
- **Unit tests**: `test/` directory in each package
- **Widget tests**: `test/screens/` in main app with comprehensive coverage
- **Integration tests**: Use `flutter test` at root level
- **Brick tests**: `tool/brick_tests/` for Mason template validation

### Screen Test Coverage
The main application includes comprehensive screen tests covering:
- **SplashScreen**: UI rendering, dimensions, orientation, theming
- **ErrorScreen**: Error display, localization, navigation
- **HomeScreen**: Component rendering, button interactions, exception handling
- **SettingsScreen**: Tile display, icons, navigation
- **AppSettingsScreen**: SharedPreferences integration, dialogs, user interactions

### Running Tests
```bash
# All tests
melos run test

# Specific test types
melos run test:selective  # Only packages with tests
melos run test:bricks     # Mason brick tests

# Single test
flutter test test/screens/splash_screen_test.dart
```

## Package Dependencies

This project uses Melos to manage a mono-repo structure. When including packages in this project, use `<package_name>: any` in pubspec.yaml dependencies - do not use path dependencies. Melos automatically resolves internal package dependencies through workspace configuration.

## Key Architecture Patterns

### Provider Pattern
The app uses `MainProvider` at the root level to provide shared instances:
- `SharedPreferences` for local storage
- `AppDatabase` for data persistence
- Theme and locale management through BLoC

### Logging System
Structured logging with:
- File-based logging to app support directory
- Configurable log levels
- Centralized `AppLogger` instance
- Use the `app_logging` package from `app_lib/logging` for all logging needs

### Theme Management
Dynamic theme switching through:
- `ThemeBloc` for state management
- Multiple predefined color schemes (fire, green, violet, wheat)
- Light/dark theme support

### Routing
Declarative routing with GoRouter:
- Route definitions with static paths and names
- `MaterialApp.router` configuration in `lib/app.dart`
- Error handling with dedicated error screen

## Mason Code Generation System

### Available Bricks
The project includes 7+ Mason bricks for rapid development:

1. **api_client**: Generate API client from OpenAPI specifications
2. **simple_bloc**: Generate basic BLoC structure with event/state management
3. **list_bloc**: Generate list-based BLoC with pagination support
4. **form_bloc**: Generate form validation and submission BLoC
5. **repository**: Generate repository pattern classes with data sources
6. **screen**: Generate screen with adaptive scaffold integration
7. **widget**: Generate reusable widget components

### Brick Usage Examples
```bash
# Generate API client (add OpenAPI spec afterward)
mason make api_client -o app_api/app_api --package_name=app_api

# Generate BLoC patterns
mason make simple_bloc -o app_bloc/feature_name --name=feature_name
mason make list_bloc -o app_bloc/feature_name --name=feature_name

# Generate form BLoC with validation
mason make form_bloc --name Login --field_names "email,password"

# Generate repository with data sources
mason make repository -o app_lib/feature_name --name=feature_name

# Generate UI components
mason make screen --name ScreenName --folder subfolder
mason make widget --name WidgetName --type stateless --folder components
```

For complete documentation, see [BRICKS.md](./BRICKS.md).

## CI/CD and Development Environment

### GitHub Workflows
- **Brick Integration Demo**: Automated testing of Mason brick generation
- Supports manual and automatic triggering for brick changes
- Multiple test types: unit, performance, integration, specific bricks

### Development Environment
- **Nix**: Reproducible development environment via Devenv
- **Direnv**: Automatic environment loading with `.envrc`
- **Devenv**: Composable development environments with `devenv.nix`
- **Flutter SDK**: Managed through Devenv for consistent versions

## Code Style Guidelines

### General Style
- Use flutter_lints from analysis_options.yaml
- Import order: dart, package, local (standard Dart convention)
- Use single quotes for strings (prefer_single_quotes rule available)
- Prefer const constructors for performance
- Naming: PascalCase for classes, camelCase for variables
- Types: always specify return types and parameter types

### Architecture Patterns
- Use BLoC pattern for state management (flutter_bloc in dependencies)
- Error handling: try/catch with logging (use app_logging package)
- Provider pattern for dependency injection via MainProvider
- Repository pattern for data layer abstraction
- Clean architecture with separation of concerns