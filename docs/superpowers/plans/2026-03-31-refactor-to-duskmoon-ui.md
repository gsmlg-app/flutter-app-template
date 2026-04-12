# Refactor to DuskMoon UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the project's custom theme, adaptive widgets, settings UI, feedback, and theme BLoC packages with the upstream `duskmoon_ui` and `duskmoon_theme_bloc` packages, eliminating forked third-party code and reducing maintenance burden.

**Architecture:** The current project has 4 custom workspace packages (`app_lib/theme`, `app_widget/adaptive`, `app_widget/feedback`, `app_bloc/theme`) plus 2 forked third-party packages (`third_party/settings_ui`, `third_party/flutter_adaptive_scaffold`) that all have upstream equivalents in the DuskMoon UI suite. We replace them bottom-up: theme first, then BLoC, then widgets/feedback/settings, then update all consumers (screens).

**Tech Stack:** Flutter 3.8+, duskmoon_ui ^1.0.0, duskmoon_theme_bloc ^1.0.0, BLoC pattern

---

## Package Mapping

| Current Package | Workspace Name | DuskMoon Replacement |
|---|---|---|
| `app_lib/theme/` | `app_theme` | `duskmoon_theme` (via `duskmoon_ui`) |
| `app_bloc/theme/` | `theme_bloc` | `duskmoon_theme_bloc` |
| `app_widget/adaptive/` | `app_adaptive_widgets` | `duskmoon_widgets` (via `duskmoon_ui`) — `DmScaffold`, `DmActionList` |
| `app_widget/feedback/` | `app_feedback` | `duskmoon_feedback` (via `duskmoon_ui`) |
| `third_party/settings_ui/` | `settings_ui` | `duskmoon_settings` (via `duskmoon_ui`) |
| `third_party/flutter_adaptive_scaffold/` | (transitive) | `duskmoon_widgets` uses its own adaptive scaffold |

## File Structure

### Files to Create
- None — this is a replacement refactor, not new features.

### Files to Modify
- `pubspec.yaml` — add `duskmoon_ui`, `duskmoon_theme_bloc`; remove replaced workspace entries
- `app_lib/provider/lib/src/main.dart` — swap `ThemeBloc` → `DmThemeBloc`
- `lib/app.dart` — swap theme/bloc references
- `lib/screens/home/home_screen.dart` — `AppAdaptiveScaffold` → `DmScaffold`
- `lib/screens/settings/settings_screen.dart` — settings_ui imports → duskmoon_settings
- `lib/screens/settings/appearance_settings_screen.dart` — ThemeBloc → DmThemeBloc
- `lib/screens/settings/accent_color_settings_screen.dart` — ThemeBloc → DmThemeBloc, AppTheme → DmThemeEntry
- `lib/screens/settings/app_settings_screen.dart` — scaffold swap
- `lib/screens/settings/controller_settings_screen.dart` — scaffold swap
- `lib/screens/settings/controller_test_screen.dart` — scaffold swap
- `lib/screens/showcase/showcase_screen.dart` — scaffold swap
- `lib/screens/showcase/feedback_demo_screen.dart` — feedback function swaps
- `lib/screens/showcase/adaptive_demo_screen.dart` — widget swaps
- `lib/screens/showcase/artwork_demo_screen.dart` — scaffold swap
- `lib/screens/showcase/chart_demo_screen.dart` — scaffold swap
- `lib/screens/showcase/client_info_screen.dart` — scaffold swap
- `lib/screens/showcase/form_demo_screen.dart` — scaffold swap
- `lib/screens/showcase/vault_demo_screen.dart` — scaffold swap
- `lib/screens/showcase/webview_demo_screen.dart` — scaffold swap
- `lib/destination.dart` — if it references adaptive widgets
- `lib/router.dart` — if it references adaptive widgets
- All test files under `test/screens/` that reference replaced types

### Workspace Packages to Remove (after migration)
- `app_lib/theme/` — replaced by `duskmoon_theme`
- `app_bloc/theme/` — replaced by `duskmoon_theme_bloc`
- `app_widget/adaptive/` — replaced by `duskmoon_widgets`
- `app_widget/feedback/` — replaced by `duskmoon_feedback`
- `third_party/settings_ui/` — replaced by `duskmoon_settings`
- `third_party/flutter_adaptive_scaffold/` — no longer needed

---

### Task 1: Add DuskMoon Dependencies and Update Workspace

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add duskmoon_ui and duskmoon_theme_bloc to root pubspec.yaml**

In `pubspec.yaml`, add under `dependencies:`:

```yaml
  duskmoon_ui: ^1.0.0
  duskmoon_theme_bloc: ^1.0.0
```

Keep all existing workspace packages for now — we remove them after migration.

- [ ] **Step 2: Run pub get to verify resolution**

Run: `cd /Users/gao/Workspace/gsmlg-app/flutter-app-template && flutter pub get`
Expected: No version conflicts. Both packages resolve.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore(deps): add duskmoon_ui and duskmoon_theme_bloc"
```

---

### Task 2: Migrate ThemeBloc (app_bloc/theme → duskmoon_theme_bloc)

**Files:**
- Modify: `app_lib/provider/lib/src/main.dart`
- Modify: `app_lib/provider/pubspec.yaml`
- Modify: `lib/app.dart`

- [ ] **Step 1: Update app_lib/provider to use DmThemeBloc**

In `app_lib/provider/pubspec.yaml`, replace `theme_bloc: any` with `duskmoon_theme_bloc: any`.

In `app_lib/provider/lib/src/main.dart`:
- Replace `import 'package:theme_bloc/theme_bloc.dart'` with `import 'package:duskmoon_theme_bloc/duskmoon_theme_bloc.dart'`
- Replace `ThemeBloc` constructor call with `DmThemeBloc(prefs: sharedPrefs)`
  - The old `ThemeBloc` took `SharedPreferences` and created `AppTheme`/`ThemeMode` from it
  - `DmThemeBloc` takes `prefs:` named parameter and auto-restores from SharedPreferences keys `dm_theme_name` and `dm_theme_mode`
- Replace `BlocProvider<ThemeBloc>` with `BlocProvider<DmThemeBloc>`

- [ ] **Step 2: Update lib/app.dart to use DmThemeBloc and DmThemeData**

In `lib/app.dart`:
- Replace `import 'package:theme_bloc/theme_bloc.dart'` with `import 'package:duskmoon_theme_bloc/duskmoon_theme_bloc.dart'`
- Replace `import 'package:app_theme/app_theme.dart'` with `import 'package:duskmoon_ui/duskmoon_ui.dart'`
- Replace `BlocBuilder<ThemeBloc, ThemeState>` with `BlocBuilder<DmThemeBloc, DmThemeState>`
- Update MaterialApp.router theme properties:
  - Old: `theme: state.theme.lightTheme`, `darkTheme: state.theme.darkTheme`, `themeMode: state.themeMode`
  - New: `theme: state.entry.light`, `darkTheme: state.entry.dark`, `themeMode: state.themeMode`

- [ ] **Step 3: Run flutter analyze on modified packages**

Run: `cd /Users/gao/Workspace/gsmlg-app/flutter-app-template && flutter analyze lib/ app_lib/provider/`
Expected: No errors related to theme types. May have warnings in settings screens (not yet migrated) — that's OK.

- [ ] **Step 4: Commit**

```bash
git add app_lib/provider/ lib/app.dart
git commit -m "refactor(theme): migrate ThemeBloc to DmThemeBloc"
```

---

### Task 3: Migrate Settings Screens (ThemeBloc events + settings_ui → duskmoon_settings)

**Files:**
- Modify: `lib/screens/settings/settings_screen.dart`
- Modify: `lib/screens/settings/appearance_settings_screen.dart`
- Modify: `lib/screens/settings/accent_color_settings_screen.dart`
- Modify: `lib/screens/settings/app_settings_screen.dart`

- [ ] **Step 1: Migrate settings_screen.dart**

Replace imports:
- `import 'package:settings_ui/settings_ui.dart'` → `import 'package:duskmoon_ui/duskmoon_ui.dart'`
- `import 'package:theme_bloc/theme_bloc.dart'` → `import 'package:duskmoon_theme_bloc/duskmoon_theme_bloc.dart'`
- `import 'package:app_theme/app_theme.dart'` → remove (DmThemeState has `.themeName`)

Update BLoC references:
- `BlocBuilder<ThemeBloc, ThemeState>` → `BlocBuilder<DmThemeBloc, DmThemeState>`
- `state.theme.name` → `state.themeName`
- `state.themeMode.title` → `state.themeMode.title` (ThemeModeExtension exists in both)

The `SettingsList`, `SettingsSection`, `SettingsTile` API is the same in `duskmoon_settings` — just the import changes.

- [ ] **Step 2: Migrate appearance_settings_screen.dart**

Replace imports:
- `import 'package:theme_bloc/theme_bloc.dart'` → `import 'package:duskmoon_theme_bloc/duskmoon_theme_bloc.dart'`

Update event dispatches:
- `context.read<ThemeBloc>().add(ChangeThemeMode(mode))` → `context.read<DmThemeBloc>().add(DmSetThemeMode(mode))`
- `BlocBuilder<ThemeBloc, ThemeState>` → `BlocBuilder<DmThemeBloc, DmThemeState>`
- `state.themeMode` stays the same (both use `ThemeMode`)

- [ ] **Step 3: Migrate accent_color_settings_screen.dart**

Replace imports:
- `import 'package:theme_bloc/theme_bloc.dart'` → `import 'package:duskmoon_theme_bloc/duskmoon_theme_bloc.dart'`
- `import 'package:app_theme/app_theme.dart'` → `import 'package:duskmoon_ui/duskmoon_ui.dart'`

Update theme list and selection:
- Old: iterates `themeList` (List<AppTheme>), dispatches `ChangeTheme(theme)`
- New: iterate `DmThemeData.themes` (List<DmThemeEntry>), dispatch `DmSetTheme(entry.name)`
- `AppTheme.name` → `DmThemeEntry.name`
- `AppTheme.lightColorScheme.primary` → `DmThemeEntry.light.colorScheme.primary` (for the color circle preview)
- `state.theme == theme` → `state.themeName == entry.name` (for selected check)

- [ ] **Step 4: Migrate app_settings_screen.dart**

Replace scaffold import if it uses `AppAdaptiveScaffold`. If it uses `SafeArea + CustomScrollView + SliverAppBar` pattern (sub-screens), no scaffold change needed — just update any theme/settings imports.

- [ ] **Step 5: Run flutter analyze**

Run: `flutter analyze lib/screens/settings/`
Expected: Clean — no references to old ThemeBloc or settings_ui.

- [ ] **Step 6: Commit**

```bash
git add lib/screens/settings/
git commit -m "refactor(settings): migrate to duskmoon_settings and DmThemeBloc"
```

---

### Task 4: Migrate Adaptive Scaffold (AppAdaptiveScaffold → DmScaffold)

**Files:**
- Modify: `lib/screens/home/home_screen.dart`
- Modify: `lib/screens/showcase/showcase_screen.dart`
- Modify: `lib/screens/settings/controller_settings_screen.dart`
- Modify: `lib/screens/settings/controller_test_screen.dart`
- Modify: All showcase sub-screens that use `AppAdaptiveScaffold`
- Modify: `lib/destination.dart` (if it references adaptive widget types)

- [ ] **Step 1: Map AppAdaptiveScaffold properties to DmScaffold**

Key mappings:
- `AppAdaptiveScaffold` → `DmScaffold`
- `import 'package:app_adaptive_widgets/...'` → `import 'package:duskmoon_ui/duskmoon_ui.dart'`
- `appSmallBreakpoint` → `DmScaffold.smallBreakpoint` (or just use DmScaffold defaults)
- `destinations:` → `destinations:` (same `NavigationDestination` type from Material)
- `selectedIndex:` → `selectedIndex:`
- `onSelectedIndexChange:` → `onSelectedIndexChange:`
- `smallBody:` → `smallBody:`
- `body:` → `body:`
- `largeBody:` → `largeBody:`
- `secondaryBody:` → `secondaryBody:`

- [ ] **Step 2: Migrate home_screen.dart**

Replace `AppAdaptiveScaffold` with `DmScaffold`. Update import from `app_adaptive_widgets` to `duskmoon_ui`. Adjust any custom breakpoint references to use DmScaffold's built-in constants.

- [ ] **Step 3: Migrate showcase_screen.dart and all showcase sub-screens**

Replace `AppAdaptiveScaffold` with `DmScaffold` in:
- `showcase_screen.dart`
- `artwork_demo_screen.dart`
- `chart_demo_screen.dart`
- `client_info_screen.dart`
- `form_demo_screen.dart`
- `vault_demo_screen.dart`
- `webview_demo_screen.dart`

- [ ] **Step 4: Migrate adaptive_demo_screen.dart**

This screen demonstrates `AppAdaptiveActionList` — replace with `DmActionList`:
- `AppAdaptiveAction` → `DmAction`
- `AppAdaptiveActionList` → `DmActionList`
- `size: AppAdaptiveActionSize.small/medium/large` → `size: DmActionSize.small/medium/large`

- [ ] **Step 5: Migrate controller settings screens**

Replace `AppAdaptiveScaffold` in `controller_settings_screen.dart` and `controller_test_screen.dart`.

- [ ] **Step 6: Run flutter analyze**

Run: `flutter analyze lib/`
Expected: No references to `app_adaptive_widgets`.

- [ ] **Step 7: Commit**

```bash
git add lib/
git commit -m "refactor(widgets): migrate AppAdaptiveScaffold to DmScaffold"
```

---

### Task 5: Migrate Feedback Functions (app_feedback → duskmoon_feedback)

**Files:**
- Modify: `lib/screens/showcase/feedback_demo_screen.dart`
- Modify: Any other screen that calls `showAppDialog`, `showSnackbar`, `showSuccessToast`, `showErrorToast`, `showBottomSheetActionList`, `showFullScreenDialog`

- [ ] **Step 1: Map feedback function names**

| Old | New |
|---|---|
| `showAppDialog()` | `showDmDialog()` |
| `AppDialogAction` | `DmDialogAction` |
| `showSnackbar()` | `showDmSnackbar()` |
| `showUndoSnackbar()` | `showDmUndoSnackbar()` |
| `showSuccessToast()` | `showDmSuccessToast()` |
| `showErrorToast()` | `showDmErrorToast()` |
| `showBottomSheetActionList()` | `showDmBottomSheetActionList()` |
| `BottomSheetAction` | `DmBottomSheetAction` |
| `showFullScreenDialog()` | `showDmFullscreenDialog()` |
| `scaffoldMessengerKey` | `dmScaffoldMessengerKey` |
| `getWidgetSize()` | `getDmWidgetSize()` |

- [ ] **Step 2: Migrate feedback_demo_screen.dart**

Replace `import 'package:app_feedback/app_feedback.dart'` with `import 'package:duskmoon_ui/duskmoon_ui.dart'`.
Apply all function/class renames from step 1. Parameter names are the same.

- [ ] **Step 3: Search for other feedback usages and migrate**

Run: `grep -r "app_feedback\|showAppDialog\|showSnackbar\|showSuccessToast\|showErrorToast\|showBottomSheetActionList\|showFullScreenDialog\|scaffoldMessengerKey" lib/`

Migrate any remaining references.

- [ ] **Step 4: Update scaffoldMessengerKey in app.dart if used**

If `lib/app.dart` sets `scaffoldMessengerKey` on `MaterialApp.router`, rename to `dmScaffoldMessengerKey`.

- [ ] **Step 5: Run flutter analyze**

Run: `flutter analyze lib/`
Expected: No references to `app_feedback`.

- [ ] **Step 6: Commit**

```bash
git add lib/
git commit -m "refactor(feedback): migrate to duskmoon_feedback"
```

---

### Task 6: Update Root pubspec.yaml — Remove Replaced Workspace Packages

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Remove replaced packages from workspace list**

Remove these entries from `workspace:`:
```yaml
  - app_lib/theme
  - app_bloc/theme
  - app_widget/adaptive
  - app_widget/feedback
  - third_party/settings_ui
  - third_party/flutter_adaptive_scaffold
```

- [ ] **Step 2: Remove replaced packages from dependencies**

Remove these from `dependencies:`:
```yaml
  app_theme: any
  theme_bloc: any
  app_adaptive_widgets: any
  app_feedback: any
  settings_ui: any
```

- [ ] **Step 3: Run flutter pub get**

Run: `flutter pub get`
Expected: Clean resolution. If any transitive dependency still references removed packages, fix that first.

- [ ] **Step 4: Run full analyze**

Run: `melos run analyze`
Expected: Clean across all packages.

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore(deps): remove workspace packages replaced by duskmoon_ui"
```

---

### Task 7: Update Tests

**Files:**
- Modify: All test files under `test/screens/` that reference old types
- Modify: Any package-level tests that reference old APIs

- [ ] **Step 1: Find all test files referencing old packages**

Run:
```bash
grep -rl "app_theme\|theme_bloc\|app_adaptive_widgets\|app_feedback\|settings_ui" test/
```

- [ ] **Step 2: Update imports and type references in each test file**

Apply the same import/type renames as the corresponding source files:
- `ThemeBloc` → `DmThemeBloc`
- `ThemeState` → `DmThemeState`
- `AppTheme` → `DmThemeEntry`
- `ChangeTheme` → `DmSetTheme`
- `ChangeThemeMode` → `DmSetThemeMode`
- `AppAdaptiveScaffold` → `DmScaffold`
- Feedback function renames per Task 5

- [ ] **Step 3: Run tests**

Run: `flutter test`
Expected: All tests pass.

- [ ] **Step 4: Commit**

```bash
git add test/
git commit -m "test: update tests for duskmoon_ui migration"
```

---

### Task 8: Remove Old Package Directories

**Files:**
- Delete: `app_lib/theme/` directory
- Delete: `app_bloc/theme/` directory
- Delete: `app_widget/adaptive/` directory
- Delete: `app_widget/feedback/` directory
- Delete: `third_party/settings_ui/` directory
- Delete: `third_party/flutter_adaptive_scaffold/` directory

- [ ] **Step 1: Verify no remaining references to old packages**

Run:
```bash
grep -r "app_theme\|theme_bloc\b" lib/ app_lib/ app_bloc/ app_widget/ --include="*.dart" | grep -v "duskmoon"
grep -r "app_adaptive_widgets\|app_feedback\|settings_ui" lib/ app_lib/ app_bloc/ app_widget/ --include="*.dart" | grep -v "duskmoon"
```

Expected: No output — all references have been migrated.

- [ ] **Step 2: Delete old directories**

```bash
rm -rf app_lib/theme/
rm -rf app_bloc/theme/
rm -rf app_widget/adaptive/
rm -rf app_widget/feedback/
rm -rf third_party/settings_ui/
rm -rf third_party/flutter_adaptive_scaffold/
```

- [ ] **Step 3: Run full project validation**

```bash
flutter pub get
melos run analyze
flutter test
```

Expected: Everything passes cleanly.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "chore: remove packages replaced by duskmoon_ui"
```

---

### Task 9: Update Provider Package Dependencies

**Files:**
- Modify: `app_lib/provider/pubspec.yaml`
- Modify: Any other workspace package that depended on removed packages

- [ ] **Step 1: Check which workspace packages depend on removed packages**

Run:
```bash
grep -rl "app_theme\|theme_bloc\|app_adaptive_widgets\|app_feedback\|settings_ui" app_lib/*/pubspec.yaml app_bloc/*/pubspec.yaml app_widget/*/pubspec.yaml app_form/*/pubspec.yaml 2>/dev/null
```

- [ ] **Step 2: Update each found pubspec.yaml**

Replace old workspace package references with `duskmoon_ui: any` or `duskmoon_theme_bloc: any` as appropriate.

- [ ] **Step 3: Run flutter pub get and analyze**

Run: `flutter pub get && melos run analyze`
Expected: Clean.

- [ ] **Step 4: Commit**

```bash
git add app_lib/ app_bloc/ app_widget/ app_form/
git commit -m "chore(deps): update workspace package deps for duskmoon_ui"
```

---

### Task 10: Update CLAUDE.md and Documentation

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Update architecture section**

Remove references to `app_lib/theme`, `app_bloc/theme`, `app_widget/adaptive`, `app_widget/feedback`, `third_party/settings_ui`, `third_party/flutter_adaptive_scaffold`.

Add note that UI system is provided by `duskmoon_ui` and `duskmoon_theme_bloc`.

- [ ] **Step 2: Update workspace packages list**

Remove the deleted packages from the workspace listing. Add `duskmoon_ui` and `duskmoon_theme_bloc` as external dependencies.

- [ ] **Step 3: Update architecture patterns section**

Update the ThemeBloc example to show `DmThemeBloc` usage.

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md for duskmoon_ui migration"
```

---

## Post-Migration Verification Checklist

- [ ] `flutter pub get` resolves cleanly
- [ ] `melos run analyze` passes with no errors
- [ ] `melos run format-check` passes
- [ ] `flutter test` — all tests pass
- [ ] `flutter run -d macos` (or available device) — app launches, theme switches work
- [ ] Settings screens render correctly (appearance picker, accent color picker)
- [ ] Feedback demo screen works (dialogs, toasts, snackbars, bottom sheets)
- [ ] Adaptive layout responds to window resizing
- [ ] Theme persists across app restarts
