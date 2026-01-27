# Product Requirements Document (PRD)

## Flutter App Template

**Version:** 1.0.0
**Last Updated:** January 2026
**Status:** Production Ready

---

## 1. Executive Summary

The Flutter App Template is a production-ready monorepo scaffold for building scalable Flutter applications with enterprise-grade architecture. It combines clean architecture principles, BLoC state management, extensive code generation tooling (Mason), and modular package organization (Melos) to accelerate development while maintaining code quality.

### Vision

Enable Flutter teams to ship high-quality, maintainable applications faster by providing a comprehensive foundation that eliminates boilerplate decisions and enforces best practices.

### Goals

1. Reduce project setup time from weeks to hours
2. Enforce consistent architecture across large teams
3. Support all Flutter platforms with shared codebase
4. Provide code generation for common patterns
5. Include production-ready features out of the box

---

## 2. Target Users

### Primary Users

| User Type | Description | Needs |
|-----------|-------------|-------|
| **Flutter Teams** | 3-50+ developers building production apps | Consistent patterns, reduced merge conflicts, clear ownership |
| **Enterprise Organizations** | Companies requiring maintainable architecture | Scalability, testability, compliance-friendly structure |
| **Multi-Platform Projects** | Apps targeting iOS, Android, Web, Desktop | Code sharing, platform-specific capabilities |
| **Solo Developers** | Building complex apps efficiently | Code generation, pre-built components, best practices |

### Use Cases

1. **Enterprise Mobile Applications** - Financial, healthcare, e-commerce apps with complex state management
2. **Multi-Platform Apps** - Single codebase targeting 6 platforms with feature parity
3. **Data-Heavy Applications** - Real-time visualization, complex forms, database-driven workflows
4. **Native Integration Projects** - Apps requiring platform-specific APIs and device features
5. **Large Team Projects** - Clear organization enabling parallel development

---

## 3. Product Features

### 3.1 Core Architecture

| Feature | Description | Status |
|---------|-------------|--------|
| **Monorepo Structure** | Melos-managed workspace with 37+ packages | Complete |
| **Clean Architecture** | Presentation, business logic, and data layer separation | Complete |
| **BLoC State Management** | bloc/flutter_bloc with Equatable for state | Complete |
| **Dependency Injection** | MainProvider with SharedPreferences, Database, Vault | Complete |
| **GoRouter Navigation** | Declarative routing with deep linking support | Complete |

### 3.2 Platform Support

| Platform | Min Version | Status |
|----------|-------------|--------|
| Android | API 21 (5.0) | Complete |
| iOS | 12.0 | Complete |
| Web | Modern browsers | Complete |
| macOS | 10.11 | Complete |
| Linux | X11/Wayland | Complete |
| Windows | 7+ | Complete |

### 3.3 Feature Packages

#### UI Components (app_widget/)

| Package | Features | Priority |
|---------|----------|----------|
| `app_adaptive_widgets` | Responsive scaffolds, platform-adaptive layouts | P0 |
| `app_artwork` | Lottie animations, SVG icons, asset management | P1 |
| `app_chart` | Line, bar, pie charts with data_visualization | P1 |
| `app_feedback` | Dialogs, snackbars, toasts, bottom sheets | P0 |
| `app_web_view` | WebView integration with error handling | P2 |

#### State Management (app_bloc/)

| Package | Purpose | Priority |
|---------|---------|----------|
| `theme_bloc` | Theme state (light/dark, color schemes) | P0 |
| `nav_bloc` | Navigation state management | P0 |
| `gamepad_bloc` | Game controller input handling | P2 |

#### Core Libraries (app_lib/)

| Package | Features | Priority |
|---------|----------|----------|
| `app_database` | Drift ORM, migrations, type-safe queries | P0 |
| `app_theme` | 4 color schemes, light/dark modes | P0 |
| `app_locale` | i18n with ARB files, context extensions | P0 |
| `app_provider` | MainProvider dependency injection | P0 |
| `app_logging` | File-based logging, configurable levels | P0 |
| `app_secure_storage` | Platform-native encrypted storage | P1 |
| `app_gamepad` | Controller detection and input mapping | P2 |

#### Native Plugins (app_plugin/)

| Plugin | Architecture | Platforms |
|--------|--------------|-----------|
| `client_info` | Federated plugin | Android, iOS, Linux, macOS, Windows |

### 3.4 Development Tooling

#### Mason Code Generation (8 bricks)

| Brick | Output | Use Case |
|-------|--------|----------|
| `screen` | Screen widget | New app screens with routing |
| `widget` | Widget package | Reusable UI components |
| `simple_bloc` | BLoC package | Basic state management |
| `list_bloc` | BLoC package | Pagination and lists |
| `form_bloc` | Form module | Form validation/submission |
| `repository` | Repository package | Data layer pattern |
| `api_client` | API client | OpenAPI/Swagger integration |
| `native_plugin` | Plugin package | Simple native plugins |
| `native_federation_plugin` | Plugin suite | Full federated plugins |

#### Melos Scripts (23 commands)

| Command | Purpose |
|---------|---------|
| `melos run prepare` | Full setup (bootstrap + gen-l10n + build-runner) |
| `melos run analyze` | Lint all packages with fatal-warnings |
| `melos run format` | Format all packages |
| `melos run test` | Run all tests (dart + flutter) |
| `melos run build-runner` | Code generation |
| `melos run gen-l10n` | Localization generation |

### 3.5 Quality Assurance

| Feature | Implementation |
|---------|----------------|
| **Linting** | flutter_lints with fatal-warnings |
| **Testing** | Unit, widget, and integration tests per package |
| **CI/CD** | GitHub Actions (format, analyze, test, build) |
| **Crash Reporting** | CrashReportingWidget with ErrorReportingService |
| **Dependency Validation** | dependency_validator for usage checking |

---

## 4. Technical Specifications

### 4.1 SDK Requirements

```yaml
environment:
  sdk: ">=3.8.0 <4.0.0"
```

### 4.2 Key Dependencies

| Category | Package | Version |
|----------|---------|---------|
| State | bloc | ^9.0.0 |
| State | flutter_bloc | ^9.0.0 |
| State | provider | ^6.1.5 |
| Navigation | go_router | ^17.0.1 |
| Database | drift | ^2.26.2 |
| Storage | flutter_secure_storage | ^9.2.4 |
| UI | google_fonts | ^6.2.1 |
| UI | lottie | ^3.3.1 |
| Visualization | data_visualization | ^1.0.0 |
| Dev | melos | ^7.0.0 |
| Dev | mason_cli | ^0.1.1 |

### 4.3 Package Architecture

```
flutter-app-template/
├── lib/                          # Main application
│   ├── main.dart                 # Entry point with initialization
│   ├── app.dart                  # Root widget with ThemeBloc
│   ├── router.dart               # GoRouter configuration
│   ├── destination.dart          # Navigation destinations
│   └── screens/                  # Feature screens
├── app_bloc/                     # State management packages
│   ├── gamepad/
│   ├── navigation/
│   └── theme/
├── app_lib/                      # Core utility packages
│   ├── database/
│   ├── gamepad/
│   ├── locale/
│   ├── logging/
│   ├── provider/
│   ├── secure_storage/
│   └── theme/
├── app_widget/                   # UI component packages
│   ├── adaptive/
│   ├── artwork/
│   ├── chart/
│   ├── feedback/
│   └── web_view/
├── app_form/                     # Form modules
│   └── demo/
├── app_plugin/                   # Native plugins
│   └── client_info/
├── third_party/                  # Modified dependencies
├── bricks/                       # Mason templates
└── test_bricks/                  # Brick tests
```

---

## 5. Screen Architecture

### 5.1 Available Screens

| Category | Screens |
|----------|---------|
| **App** | SplashScreen, ErrorScreen |
| **Home** | HomeScreen |
| **Settings** | SettingsScreen, AppSettingsScreen, AppearanceSettingsScreen, AccentColorSettingsScreen, ControllerSettingsScreen |
| **Showcase** | ShowcaseScreen, AdaptiveDemoScreen, ArtworkDemoScreen, ChartDemoScreen, ClientInfoScreen, FeedbackDemoScreen, FormDemoScreen, VaultDemoScreen, WebViewDemoScreen |

### 5.2 Screen Pattern

```dart
class FeatureScreen extends StatelessWidget {
  static const name = 'Feature';      // Display name
  static const path = '/feature';     // Route path

  const FeatureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppAdaptiveScaffold(
      selectedIndex: Destinations.indexOf(const Key(name), context),
      onSelectedIndexChange: (idx) => Destinations.changeHandler(idx, context),
      destinations: Destinations.navs(context),
      body: (context) => /* Screen content */,
    );
  }
}
```

---

## 6. CI/CD Workflows

### 6.1 GitHub Actions

| Workflow | Trigger | Jobs |
|----------|---------|------|
| `ci.yml` | Push/PR to main | Format, Analyze, Test |
| `brick-test.yml` | Brick file changes | Mason brick tests |
| `release.yml` | Manual trigger | Multi-platform builds |
| `deploy.yml` | Release events | Deployment |

### 6.2 Quality Gates

- Format check (`dart format --set-exit-if-changed`)
- Lint analysis (`flutter analyze --fatal-warnings`)
- Test suite (`melos run test`)
- Dependency validation

---

## 7. Documentation

### 7.1 In-Repository Docs

| Document | Purpose |
|----------|---------|
| `README.md` | Quick start and overview |
| `CLAUDE.md` | AI assistant guidance |
| `docs/INDEX.md` | Documentation index |
| `docs/BRICKS.md` | Mason brick guide |
| `docs/FORM_BLOC.md` | Form management guide |
| `docs/TESTING.md` | Testing strategies |
| `docs/DOCUMENTATION.md` | Error handling guide |

### 7.2 AI-Assisted Development

Project-specific Claude Code skills in `.claude/skills/`:

| Skill | Purpose |
|-------|---------|
| `/project-development` | Workflow guide (start here) |
| `/project-screen` | Create screens |
| `/project-widget` | Create widgets |
| `/project-bloc` | Create BLoCs |
| `/project-form` | Create forms |
| `/project-database` | Database operations |
| `/project-locale` | Localization |
| `/project-plugin` | Native plugins |
| `/project-data-visualization` | Charts and graphs |

---

## 8. Getting Started

### 8.1 Prerequisites

- Flutter SDK >= 3.8.0
- Dart >= 3.8.0
- Git with LFS support
- (Optional) Nix/Devenv for reproducible environment

### 8.2 Setup Steps

```bash
# Clone repository
git clone https://github.com/gsmlg-app/flutter-app-template.git
cd flutter-app-template

# Install Git LFS assets
git lfs install && git lfs pull

# Install global tools
dart pub global activate melos
dart pub global activate mason_cli

# Bootstrap workspace
melos bootstrap
mason get

# Full preparation (code generation)
melos run prepare

# Verify setup
melos run analyze
melos run test

# Run application
flutter run
```

### 8.3 Rename Template

```bash
# Rename to your project (run once)
dart run bin/setup_project.dart my_project_name
```

---

## 9. Roadmap

### Current Release (v1.0)

- [x] Core architecture with 37+ packages
- [x] 6-platform support
- [x] 8 Mason code generation bricks
- [x] Theme system with 4 color schemes
- [x] Internationalization framework
- [x] Secure storage integration
- [x] Data visualization (charts)
- [x] Gamepad controller support
- [x] GitHub Actions CI/CD
- [x] AI-assisted development skills

### Future Considerations

- [ ] Additional chart types (scatter, heatmap, treemap)
- [ ] Authentication module template
- [ ] Push notification integration
- [ ] Analytics integration template
- [ ] Additional Mason bricks (API mocking, test fixtures)
- [ ] Performance monitoring integration

---

## 10. Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Setup Time** | < 1 hour | Time from clone to running app |
| **Build Success** | 100% | CI pipeline pass rate |
| **Code Coverage** | > 80% | Test coverage per package |
| **Lint Compliance** | 0 warnings | Fatal warnings in CI |
| **Documentation** | Complete | All features documented |

---

## 11. Appendix

### A. Package Summary

| Category | Count | Examples |
|----------|-------|----------|
| app_lib | 7 | database, theme, locale, logging |
| app_bloc | 3 | theme, navigation, gamepad |
| app_widget | 5 | adaptive, artwork, chart, feedback |
| app_form | 1 | demo |
| app_plugin | 7 | client_info (federated) |
| third_party | 4 | form_bloc, settings_ui |
| **Total** | **37+** | |

### B. Brick Summary

| Brick | Generated Files |
|-------|-----------------|
| screen | 1 Dart file |
| widget | Package (pubspec, lib, test) |
| simple_bloc | Package (bloc, event, state, test) |
| list_bloc | Package (bloc, event, state, test) |
| form_bloc | Package (form module) |
| repository | Package (repository pattern) |
| api_client | Package (OpenAPI client) |
| native_plugin | Package (single plugin) |
| native_federation_plugin | 7 packages (federated) |

### C. Supported Color Schemes

| Scheme | Primary Color |
|--------|--------------|
| Fire | Orange/Red |
| Green | Green |
| Violet | Purple |
| Wheat | Warm neutral |

---

*This PRD is maintained alongside the codebase. For implementation details, see CLAUDE.md and the docs/ directory.*
