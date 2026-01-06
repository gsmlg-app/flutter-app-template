<!--
Sync Impact Report:
- Version change: 0.0.0 → 1.0.0
- Modified principles: N/A (initial constitution)
- Added sections:
  - Core Principles (5 principles)
  - Development Standards
  - Quality Gates
  - Governance
- Removed sections: N/A
- Templates requiring updates:
  - .specify/templates/plan-template.md ✅ (no changes needed - generic constitution check)
  - .specify/templates/spec-template.md ✅ (no changes needed - technology agnostic)
  - .specify/templates/tasks-template.md ✅ (no changes needed - generic structure)
- Follow-up TODOs: None
-->

# Flutter App Template Constitution

## Core Principles

### I. Modular Monorepo Architecture

All functionality MUST be organized into purpose-driven packages within the monorepo structure:

- **app_lib/**: Core utilities (database, theme, locale, logging, provider)
- **app_bloc/**: BLoC state management packages
- **app_widget/**: Reusable UI components
- **app_plugin/**: Native platform plugins with federated architecture
- **third_party/**: Modified third-party packages
- **bricks/**: Mason templates for code generation

Each package MUST be independently testable and have a clear, single purpose. Organizational-only
packages without concrete functionality are prohibited.

### II. BLoC State Management

State management MUST follow the BLoC (Business Logic Component) pattern:

- All business logic MUST reside in BLoC classes, not in UI widgets
- State changes MUST flow through events and states
- BLoCs MUST be unit testable without UI dependencies
- Use `flutter_bloc` for widget integration
- ThemeBloc pattern serves as the reference implementation

### III. Workspace Dependency Convention

Internal package dependencies MUST use workspace resolution:

- Declare workspace packages with `<package_name>: any` in pubspec.yaml
- NEVER use path dependencies (`path: ../some_package`)
- Melos resolves all internal dependencies through workspace configuration
- External dependencies SHOULD specify version constraints

### IV. Code Generation First

Scaffolding new code MUST use Mason templates when available:

- Use `mason make screen` for new screens
- Use `mason make widget` for new widgets
- Use `mason make simple_bloc` or `mason make list_bloc` for BLoCs
- Use `mason make form_bloc` for form handling
- Use `mason make repository` for data layer
- Use `mason make native_federation_plugin` for platform plugins

Custom implementations without using available templates require justification.

### V. Testing Co-location

Tests MUST be co-located with their packages:

- Each package with logic MUST have a `test/` directory
- Main app screen tests reside in `test/screens/`
- Use `melos run test` to run all tests across packages
- Use `melos run test:dart` for non-Flutter packages
- Use `melos run test:flutter` for Flutter packages
- Isolated brick tests reside in `test_bricks/` (excluded from default analysis)

## Development Standards

### Code Style

- Flutter Lints rules from `analysis_options.yaml` are enforced
- Run `melos run analyze` before commits (warnings are fatal)
- Run `melos run format` to ensure consistent formatting
- Prefer `const` constructors where possible
- Use `AppLogger` from `app_logging` for all logging needs

### Routing Convention

Screens MUST define static route constants for GoRouter integration:

```dart
class ExampleScreen extends StatelessWidget {
  static const name = 'example';
  static const path = '/example';
}
```

### App Initialization Pattern

App startup MUST follow the MainProvider pattern:

```dart
MainProvider(
  sharedPrefs: sharedPrefs,
  database: database,
  child: MaterialApp.router(...),
)
```

## Quality Gates

Before merging any PR:

1. `melos run analyze` MUST pass with no warnings
2. `melos run format` MUST show no changes needed
3. `melos run test` MUST pass for affected packages
4. New packages MUST include test coverage
5. New screens/widgets MUST be generated via Mason templates (when applicable)

## Governance

This constitution establishes the foundational rules for the Flutter App Template project.
All contributors and AI assistants MUST verify compliance with these principles.

**Amendment Process**:

1. Propose changes via pull request to this file
2. Document rationale for changes
3. Update version according to semantic versioning:
   - MAJOR: Backward incompatible principle changes
   - MINOR: New principles or expanded guidance
   - PATCH: Clarifications and wording fixes
4. Update dependent documentation if principles change

**Compliance Review**:

- All PRs MUST be checked against constitution principles
- Violations require documented justification in Complexity Tracking
- Use CLAUDE.md as runtime development guidance

**Version**: 1.0.0 | **Ratified**: 2025-01-05 | **Last Amended**: 2025-01-05
