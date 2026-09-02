# Gemini Project Configuration

This file helps Gemini understand the project structure, conventions, and operational workflows.

## Project Overview

A production-ready, full-capability Flutter application template with monorepo architecture, supporting **Android, iOS, macOS, Windows, and Linux** (Web is explicitly not supported).

Follows a **subtractive capability model**: all capabilities are enabled out-of-the-box in the default template, and downstream projects remove capabilities they do not need rather than building up from scratch.

## Key Technologies & Constraints

* **Flutter & Dart SDK**: `>=3.8.0`
* **Supported Platforms**: Android, iOS, macOS, Windows, Linux (Web is excluded from code, docs, CI, and release matrices).
* **State Management**: BLoC pattern (`flutter_bloc`, `bloc`, `duskmoon_theme_bloc`)
* **Dependency Injection**: `MainProvider`
* **Monorepo Manager**: Melos (configured in root `pubspec.yaml`)
* **Code Generation**: Mason (`bricks/`)

## Important Directories

* `lib/`: Main application source code and entry points (`main.dart`, `app.dart`, `router.dart`, `screens/`).
* `app_bloc/`: Feature BLoC packages (`error_handler`, `gamepad`, `navigation`).
* `app_lib/`: Shared core libraries (`database`, `gamepad`, `locale`, `logging`, `provider`, `secure_storage`, `vector_store`).
* `app_widget/`: Reusable widgets (`artwork`, `chart`, `web_view`).
* `app_form/`: Form modules (`demo`).
* `app_plugin/`: Federated native plugins (`client_info`).
* `bricks/`: 9 Mason bricks for scaffolding.
* `test_bricks/`: Unit tests for all 9 Mason bricks.
* `bin/`: CLI tools (`setup_project.dart`, `remove_capability.dart`, `verify_template.dart`, `update_bricks.dart`).

## Key Workflows

* `melos run prepare`: Full workspace preparation (bootstrap + gen-l10n + build-runner).
* `melos run analyze`: Lint all packages with fatal warnings.
* `melos run format`: Format all packages.
* `melos run test`: Run all tests.
* `dart run bin/verify_template.dart`: Verify template integrity.
* `dart run bin/remove_capability.dart <capabilities>`: Subtractive capability pruning.
* `dart run bin/setup_project.dart <name>`: Rename project.

