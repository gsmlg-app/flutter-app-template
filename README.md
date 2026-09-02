# Flutter App Template

A production-ready, full-capability Flutter application template with monorepo architecture, supporting **Android, iOS, macOS, Windows, and Linux** (Web is explicitly not supported).

Designed with a **subtractive capability model**: all capabilities are enabled out-of-the-box in the default template, and downstream projects remove capabilities they do not need rather than building up from scratch.

---

## 🎯 Target Platforms

| Platform | Supported | Release Artifacts | Fail-Closed Signing |
| :--- | :---: | :--- | :--- |
| **Android** | ✅ Yes | APK, AAB | Checked (fails if release keystore missing) |
| **iOS** | ✅ Yes | IPA / Framework | Checked (certificate & provisioning profile) |
| **macOS** | ✅ Yes | .app, .dmg | Checked (Apple Developer certificate) |
| **Windows** | ✅ Yes | .exe / Zip | Checked (Authenticode certificate) |
| **Linux** | ✅ Yes | Tarball / AppImage | Checked (binary bundle) |
| **Web** | ❌ **No** | *Explicitly excluded* | N/A |

---

## ✨ Features & Default Capabilities

All capabilities are included in the workspace and wired into the demo UI by default:

- 🗄️ **App Database (`app_lib/database`)** — Relational database with Drift (SQLite) for structured local storage.
- 🔐 **Secure Storage (`app_lib/secure_storage`)** — Platform-native secure key-value store (Keychain on macOS/iOS, EncryptedSharedPreferences on Android).
- 🎮 **Gamepad & Input (`app_lib/gamepad`, `app_bloc/gamepad`)** — Game controller input handling with cross-platform GamepadBloc.
- 🌐 **Web View (`app_widget/web_view`)** — Platform-adaptive embedded web browser widget.
- 📊 **Charts & Visualization (`app_widget/chart`)** — Line, bar, and pie charts with responsive canvas rendering.
- 🔍 **Vector Store (`app_lib/vector_store`)** — Local vector search and TF-IDF embedding engine with multilingual CJK support.
- 📱 **Client Info (`app_plugin/client_info`)** — Federated native platform plugin for device and OS metadata across 5 platforms.
- 📋 **Form BLoC (`app_form/demo`)** — Reactive form state management and field validation using FormBloc.
- 🎨 **Duskmoon Theme & UI (`duskmoon_ui`, `duskmoon_theme_bloc`)** — Multi-palette dynamic theming (fire, green, violet, wheat) with persistent SharedPreferences storage.
- 🌍 **Internationalization (`app_lib/locale`)** — Full i18n support with ARB files and type-safe code generation (`gen-l10n`).
- 📝 **App Logging (`app_lib/logging`)** — Structured logging with debug/release log levels and file stream persistence.
- 🛡️ **Error Handling & Navigation (`app_bloc/error_handler`, `app_bloc/navigation`)** — Centralized exception routing and GoRouter declarative navigation.

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `>=3.8.0`
- Dart SDK `>=3.8.0`
- Git & Git LFS

### Installation & Initialization

1. **Clone the repository:**
   ```bash
   git clone https://github.com/gsmlg-app/flutter-app-template.git my_app
   cd my_app
   ```

2. **Initialize Git LFS & Install global tools:**
   ```bash
   git lfs install
   dart pub global activate melos
   dart pub global activate mason_cli
   ```

3. **Rename the template to your project name:**
   ```bash
   dart run bin/setup_project.dart my_app \
     --org com.example \
     --description "My production Flutter application"
   ```

4. **Prepare the workspace:**
   ```bash
   melos run prepare
   mason get
   ```

5. **Verify template integrity:**
   ```bash
   dart run bin/verify_template.dart
   ```

---

## ✂️ Subtractive Capability Pruning

If your project does not need specific capabilities, use the built-in pruning CLI to physically delete the packages and clean up route registrations, showcase cards, and dependencies:

```bash
# Preview what would be removed
dart run bin/remove_capability.dart gamepad web_view chart --dry-run

# Prune capabilities permanently
dart run bin/remove_capability.dart gamepad web_view chart
```

### Supported Capabilities for Pruning:
- `gamepad` — Removes `app_lib/gamepad`, `app_bloc/gamepad`, Gamepad routes, and Android GamepadsActivity.
- `web_view` — Removes `app_widget/web_view` and WebView routes.
- `chart` — Removes `app_widget/chart` and Chart demo screens.
- `client_info` — Removes federated `app_plugin/client_info/*` packages and Client Info screens.
- `vector_store` — Removes `app_lib/vector_store` and vector search services.
- `form` — Removes `app_form/demo` and Form showcase routes.
- `secure_storage` — Removes `app_lib/secure_storage`.
- `database` — Removes `app_lib/database`.
- `artwork` — Removes `app_widget/artwork`.

---

## 🛠️ Development & CI Commands

```bash
# Full setup & code generation
melos run prepare          # Bootstrap + gen-l10n + build-runner

# Code quality
melos run analyze          # Lint all packages (--fatal-warnings)
melos run format           # Format Dart code across all packages
melos run format-check     # CI format check

# Testing
melos run test             # Run Dart and Flutter tests across all packages
flutter test               # Run root application tests

# Run on devices (5 supported platforms)
flutter run -d macos       # macOS Desktop
flutter run -d android     # Android Device / Emulator
flutter run -d ios         # iOS Simulator / Device
flutter run -d windows     # Windows Desktop
flutter run -d linux       # Linux Desktop
```

---

## 🧱 Code Generation with Mason

9 tested Mason bricks are included for rapid feature development:

```bash
# Screens & Widgets
mason make screen --name UserProfile --folder user
mason make widget --name MetricCard --type stateless

# State Management & Forms
mason make simple_bloc -o app_bloc/notifications --name=notifications
mason make list_bloc -o app_bloc/users --name=users
mason make form_bloc --name Login --field_names "email,password"

# Data Layer & API
mason make repository -o app_lib/user --name=user
mason make api_client -o app_api/petstore --package_name=petstore

# Native Platform Plugins
mason make native_plugin --name biometric_auth --description "Biometrics" --package_prefix app -o app_plugin
mason make native_federation_plugin --name biometric_auth --description "Biometrics" --package_prefix app -o app_plugin
```

To run all Mason brick tests:
```bash
dart run test_bricks/screen/screen_test.dart
dart run test_bricks/simple_bloc/simple_bloc_test.dart
dart run test_bricks/list_bloc/list_bloc_test.dart
dart run test_bricks/form_bloc/form_bloc_test.dart
dart run test_bricks/repository/repository_test.dart
dart run test_bricks/widget/widget_test.dart
dart run test_bricks/api_client/api_client_test.dart
dart run test_bricks/native_plugin/native_plugin_test.dart
dart run test_bricks/native_federation_plugin/native_federation_plugin_test.dart
```

---

## 📦 Project Architecture

```
├── bin/                    # Automation scripts (setup_project, remove_capability, verify_template)
├── lib/                    # Root Flutter application
│   ├── main.dart           # App initialization & Logging
│   ├── app.dart            # DmThemeBloc & MaterialApp.router
│   ├── router.dart         # GoRouter configuration
│   └── screens/            # Screens (showcase, home, settings, splash)
├── app_bloc/               # BLoC state management packages
├── app_lib/                # Core libraries (database, secure_storage, locale, logging, vector_store)
├── app_widget/             # UI widgets (artwork, chart, web_view)
├── app_plugin/             # Federated native plugins (client_info)
├── bricks/                 # Mason templates (9 bricks)
├── test_bricks/            # Automated test suites for all 9 bricks
└── .github/workflows/      # CI/CD (ci.yml, release.yml, deploy.yml, brick-test.yml)
```

---

## 🔒 Security & Release Integrity

- **Fail-Closed Release Signing**: Production release builds fail immediately if valid keystores/certificates are not provided, preventing insecure debug artifact distribution.
- **SHA-256 Checksum Verification**: Every GitHub Release produces a verified `SHA256SUMS.txt`. The deployment workflow downloads release artifacts and validates their cryptographic hashes before deployment.

---

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.