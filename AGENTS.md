# Build/Lint/Test Commands
- Run single test: `flutter test test/widget_test.dart`
- Run all tests: `melos run test` (dart + flutter tests) or `flutter test`
- Lint: `melos run analyze` + `melos run format` (no lint:all command)
- Format: `melos run format`
- Analyze: `melos run analyze`
- Build: `melos run build-runner`
- Prepare: `melos run prepare` (bootstrap + gen-l10n + build-runner)

# Mason Bricks
- Usage documentation for mason bricks can be found in BRICKS.md

# Code Style Guidelines
- Use flutter_lints from analysis_options.yaml
- Import order: dart, package, local (standard Dart convention)
- Use single quotes for strings (prefer_single_quotes rule available)
- Prefer const constructors for performance
- Use BLoC pattern for state management (flutter_bloc in dependencies)
- Error handling: try/catch with logging (use app_logging package in app_lib/logging)
- Naming: PascalCase for classes, camelCase for variables
- Types: always specify return types and parameter types
- Workspace structure: multi-package with melos, use workspace packages

# Package Management
- This project uses Melos for mono-repo management
- When including packages in this project, use `<package_name>: any` in pubspec.yaml
- Do not use path dependencies for workspace packages