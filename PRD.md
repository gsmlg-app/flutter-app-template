# Product Requirements Document (PRD)

## Flutter App Template

**Version:** 1.0.0
**Last Updated:** January 2026
**Status:** Production Ready

---

## 1. Executive Summary

The Flutter App Template is a production-ready, full-capability monorepo scaffold for building scalable Flutter applications across **Android, iOS, macOS, Windows, and Linux** (Web is explicitly not supported). It follows a **subtractive capability model**: all enterprise capabilities are enabled out-of-the-box, allowing teams to prune what they do not need rather than building up from a barebones template.

### Vision

Enable Flutter engineering teams to ship high-quality, maintainable, cross-platform applications faster by providing a battle-tested foundation with fail-closed security, subtractive pruning, and automated tooling.

### Goals

1. Reduce project setup and boilerplate time from weeks to minutes.
2. Enforce consistent clean architecture and BLoC state management.
3. Sustain continuous build, test, and release parity across 5 platforms (Android, iOS, macOS, Windows, Linux).
4. Provide subtractive capability pruning via automated CLI (`bin/remove_capability.dart`).
5. Ensure fail-closed release signing and cryptographic artifact verification.

---

## 2. Target Users & Platforms

### Supported Platform Contract

| Platform | Support Tier | Release Format | Release Signing Gate |
| :--- | :--- | :--- | :--- |
| **Android** | Tier 1 (Official) | APK, AAB | Checked (fail-closed) |
| **iOS** | Tier 1 (Official) | IPA / Framework | Checked (fail-closed) |
| **macOS** | Tier 1 (Official) | .app, .dmg | Checked (Apple Developer ID) |
| **Windows** | Tier 1 (Official) | .exe, Zip | Checked (Authenticode) |
| **Linux** | Tier 1 (Official) | Tarball, AppImage | Checked (binary bundle) |
| **Web** | **Unsupported** | *Explicitly excluded* | N/A |

---

## 3. Product Features & Capability Architecture

### 3.1 Subtractive Capability Architecture

The template includes all core and optional capabilities enabled by default. Downstream projects use `dart run bin/remove_capability.dart <capabilities>` to prune packages and clean up route registrations.

| Capability | Workspace Location | Description | Prunable |
| :--- | :--- | :--- | :---: |
| **Database** | `app_lib/database` | Drift ORM / SQLite database with migrations | Yes |
| **Secure Storage** | `app_lib/secure_storage` | Platform-native encrypted storage (Keychain/EncryptedSharedPreferences) | Yes |
| **Gamepad** | `app_lib/gamepad`, `app_bloc/gamepad` | Gamepad controller input detection and BLoC | Yes |
| **WebView** | `app_widget/web_view` | Platform-adaptive embedded web browser widget | Yes |
| **Chart** | `app_widget/chart` | Responsive canvas chart visualization | Yes |
| **Vector Store** | `app_lib/vector_store` | Local vector search, CJK multilingual TF-IDF embedder | Yes |
| **Client Info** | `app_plugin/client_info/*` | Federated native device/OS info plugin | Yes |
| **Form** | `app_form/demo` | Reactive FormBloc state management and validation | Yes |
| **Artwork** | `app_widget/artwork` | SVG and asset rendering | Yes |
| **Theme** | `duskmoon_ui`, `duskmoon_theme_bloc` | Multi-palette dynamic theming with SharedPreferences persistence | Core |
| **Locale** | `app_lib/locale` | Internationalization with ARB and type-safe generation | Core |
| **Logging** | `app_lib/logging` | Structured file/console logging with release filtering | Core |
| **Navigation** | `app_bloc/navigation` | GoRouter declarative routing and deep linking | Core |
| **Error Handler** | `app_bloc/error_handler` | Centralized exception handling and routing | Core |

---

## 4. Development Tooling & Code Generation

### 4.1 Mason Bricks (9 Bricks)

All 9 Mason bricks are fully tested and maintained:

| Brick | Category | Output |
| :--- | :--- | :--- |
| `screen` | UI | New screen with routing constants |
| `widget` | UI | Reusable widget package |
| `simple_bloc` | State | Basic BLoC package (bloc, event, state) |
| `list_bloc` | State | Pagination and CRUD list BLoC package |
| `form_bloc` | Forms | Form module with field validation |
| `repository` | Data | Repository package with local & remote data sources |
| `api_client` | API | OpenAPI/Swagger generated client package |
| `native_plugin` | Plugin | Single-package native platform plugin |
| `native_federation_plugin` | Plugin | 7-package federated platform plugin suite |

### 4.2 Automation CLI Tools

- `bin/setup_project.dart`: Interactive and flag-based project initialization and renaming.
- `bin/remove_capability.dart`: Subtractive capability pruning with dry-run support.
- `bin/verify_template.dart`: Template manifest and workspace validation.
- `bin/update_bricks.dart`: Upstream Mason brick synchronization.

---

## 5. CI/CD & Security Specifications

### 5.1 GitHub Actions Workflows

1. **`ci.yml`**: Format check, analyzer (`--fatal-warnings`), unit tests, and build checks.
2. **`brick-test.yml`**: Automated testing of all 9 Mason bricks across PRs and main branches.
3. **`release.yml`**: 5-platform parallel build matrix with pre-release gate, fail-closed signing, and SHA256 checksum generation.
4. **`deploy.yml`**: Promotion of immutable release artifacts verified against `SHA256SUMS.txt`.

---

## 6. Success Metrics

| Metric | Target | Verification |
| :--- | :--- | :--- |
| **Platform Build Success** | 100% across 5 platforms | GitHub Actions Release workflow |
| **Analyzer Cleanliness** | 0 warnings, 0 errors | `melos run analyze` with fatal warnings |
| **Pruning Cleanliness** | 0 orphaned imports / syntax errors | `dart run bin/remove_capability.dart` + `melos run analyze` |
| **Brick Test Pass Rate** | 100% (9/9 suites) | `brick-test.yml` CI workflow |
| **Security Integrity** | No unsigned debug fallback in release | Fail-closed signing Gradle/Xcode/CMake checks |
