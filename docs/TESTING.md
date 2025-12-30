# Testing Guide

This document explains how to run tests across the Flutter monorepo using Melos.

## Available Test Commands

### Melos Test Commands

| Command | Description |
|---------|-------------|
| `melos run test` | Run Flutter tests for all packages |
| `melos run test:dart` | Run Dart tests (non-Flutter packages) |
| `melos run test:flutter` | Run Flutter tests |
| `melos run brick-test` | Run Mason brick tests (in `tool/brick_tests/`) |

### Direct Test Commands

```bash
# Run all tests in a specific package
cd app_lib/theme && flutter test

# Run a single test file
flutter test test/screens/splash_screen_test.dart

# Run tests with coverage
flutter test --coverage

# Run tests in watch mode
flutter test --watch
```

## CI/CD Integration

Tests are automatically run on push/PR to main via GitHub Actions:

```yaml
# .github/workflows/ci.yml
- name: Run tests
  run: melos run test
```

The CI pipeline runs:
1. Format check (`melos run format-check`)
2. Analysis (`melos run analyze`)
3. Tests (`melos run test`)

## Packages with Tests

The following packages have test directories:

### Main Application
- `flutter_app_template` - Main app tests including screen tests in `test/screens/`

### BLoC Packages
- `theme_bloc` - Theme state management tests

### Library Packages
- `app_theme` - Theme management tests
- `app_provider` - Provider/state management tests
- `app_database` - Database layer tests
- `app_locale` - Internationalization tests

### Widget Packages
- `app_adaptive_widgets` - Adaptive widget tests
- `app_feedback` - Feedback component tests
- `app_artwork` - Artwork asset tests
- `app_web_view` - WebView component tests

### Third-Party Packages
- `settings_ui` - Settings UI component tests
- `form_bloc` - Form BLoC tests
- `flutter_adaptive_scaffold` - Adaptive scaffold tests

## Screen Tests

The main application includes comprehensive screen tests in `test/screens/`:

| Screen | Test Coverage |
|--------|---------------|
| SplashScreen | UI rendering, dimensions, orientation, theming |
| ErrorScreen | Error display, localization, navigation |
| HomeScreen | Component rendering, button interactions, exception handling |
| SettingsScreen | Tile display, icons, navigation |
| AppSettingsScreen | SharedPreferences integration, dialogs, user interactions |

## Running Tests

### All Tests
```bash
melos run test
```

### Package-Specific Tests
```bash
# Navigate to package and run tests
cd app_lib/theme
flutter test
```

### Single Test File
```bash
flutter test test/screens/home_screen_test.dart
```

### With Verbose Output
```bash
flutter test --reporter expanded
```

## Test Results

Tests are executed in dependency order. The output shows results for each package individually, making it easy to identify failing tests.

## Writing Tests

### Widget Test Example
```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MyWidget renders correctly', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MyWidget()));

    expect(find.text('Hello'), findsOneWidget);
  });
}
```

### BLoC Test Example
```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:test/test.dart';

void main() {
  blocTest<MyBloc, MyState>(
    'emits [loading, loaded] when fetch is called',
    build: () => MyBloc(),
    act: (bloc) => bloc.add(FetchEvent()),
    expect: () => [isA<Loading>(), isA<Loaded>()],
  );
}
```

## Troubleshooting

### Tests Not Found
Ensure the package has a `test/` directory and test files ending in `_test.dart`.

### Dependency Issues
Run `melos bootstrap` to ensure all dependencies are resolved.

### Flaky Tests
Use `await tester.pumpAndSettle()` for animations and async operations.
