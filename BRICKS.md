# Mason Bricks Guide

This project uses [Mason](https://pub.dev/packages/mason_cli) for code generation to maintain consistency and speed up development. This guide explains how to use the available bricks.

## Available Bricks

### 1. Screen Brick (`screen`)
Creates a new screen file in the `lib/screens/` directory with proper navigation and theming integration.

**Usage:**
```bash
mason make screen --name ScreenName [options]
```

**Variables:**
- `name` (required): Screen name (e.g., "Profile", "UserSettings")
- `folder` (optional): Subfolder name (e.g., "user" creates `lib/screens/user/profile_screen.dart`)
- `has_adaptive_scaffold` (default: true): Use AppAdaptiveScaffold for responsive layout
- `has_app_bar` (default: true): Include SliverAppBar in the screen

**Examples:**
```bash
# Basic screen in root screens folder
mason make screen --name Home

# Screen in subfolder with custom options
mason make screen --name Profile --folder user --has_adaptive_scaffold true --has_app_bar true

# Simple screen without adaptive scaffold
mason make screen --name Login --has_adaptive_scaffold false
```

**Generated File:**
- `lib/screens/{folder}/{name}_screen.dart`

**Features:**
- Static `name` and `path` constants for GoRouter integration
- AppAdaptiveScaffold integration with navigation
- SafeArea and CustomScrollView with SliverAppBar
- Proper imports and theming support
- Localization ready with `context.l10n`

---

### 2. Widget Brick (`widget`)
Creates a complete reusable widget package in the `app_widget/` directory with platform-specific implementations.

**Usage:**
```bash
mason make widget --name WidgetName [options]
```

**Variables:**
- `name` (required): Widget name (e.g., "CustomButton", "LoadingSpinner")
- `type` (default: stateless): Widget type (`stateless` or `stateful`)
- `folder` (optional): Subfolder name (e.g., "buttons" creates `app_widget/buttons/custom_button_widget/`)
- `has_platform_adaptive` (default: true): Include platform-specific implementation

**Examples:**
```bash
# Basic stateless widget
mason make widget --name CustomButton

# Stateful widget with platform adaptation
mason make widget --name LoadingSpinner --type stateful --has_platform_adaptive true

# Widget in specific folder
mason make widget --name Card --folder cards --type stateless
```

**Generated Structure:**
```
app_widget/{folder}/{name}_widget/
├── lib/
│   ├── src/
│   │   └── {name}_widget.dart
│   └── {name}_widget.dart (export file)
├── test/
│   └── {name}_widget_test.dart
├── .gitignore
├── .metadata
├── README.md
├── CHANGELOG.md
├── LICENSE
├── analysis_options.yaml
└── pubspec.yaml
```

**Features:**
- Platform-specific implementations (Material vs Cupertino)
- Comprehensive test scaffolding
- Proper documentation and changelog
- Export pattern following project conventions
- MIT license included

---

### 3. Simple BLoC Brick (`simple_bloc`)
Creates a simple BLoC package with state management components.

**Usage:**
```bash
mason make simple_bloc --name BlocName
```

**Variables:**
- `name` (required): BLoC name (e.g., "User", "Settings")

**Generated Structure:**
```
{name}_bloc/
├── lib/
│   ├── src/
│   │   ├── bloc.dart
│   │   ├── event.dart
│   │   └── state.dart
│   └── {name}_bloc.dart
├── test/
│   └── {name}_bloc_test.dart
└── pubspec.yaml
```

---

### 4. Repository Brick (`repository`)
Creates a complete repository pattern implementation with data sources and models.

**Usage:**
```bash
mason make repository --name RepositoryName [options]
```

**Variables:**
- `name` (required): Repository name (e.g., "User", "Product")
- `has_remote_data_source` (default: true): Include remote data source
- `has_local_data_source` (default: true): Include local data source
- `model_name` (optional): Model name (defaults to repository name)

---

### 5. API Client Brick (`api_client`)
Generates a complete API client package from OpenAPI/Swagger specifications.

**Usage:**
```bash
mason make api_client --package_name api_package_name
```

**Variables:**
- `package_name` (required): Package name for the API client

---

## Getting Started

### Prerequisites
Ensure you have Mason CLI installed:
```bash
dart pub global activate mason_cli
```

### Initialize Mason
If you haven't already initialized Mason in your project:
```bash
mason init
```

### Install Bricks
The bricks are already configured in `mason.yaml`. To ensure they're available:
```bash
mason get
```

### Using Bricks
1. Choose the appropriate brick for your needs
2. Run the mason make command with required variables
3. Follow the prompts for optional variables
4. The generated code will be created in the appropriate location

## Best Practices

### Screen Creation
- Use descriptive names that clearly indicate the screen's purpose
- Place related screens in subfolders (e.g., all user-related screens in `user/`)
- Keep screens focused on a single responsibility
- Use the adaptive scaffold for consistent navigation

### Widget Creation
- Create reusable widgets for common UI patterns
- Use platform adaptation for better user experience
- Include comprehensive tests for widget behavior
- Document public APIs thoroughly
- Follow the existing widget patterns in `app_widget/`

### General Guidelines
- Always review generated code before committing
- Customize the generated code to fit your specific needs
- Add proper error handling and edge case management
- Include accessibility features in your widgets
- Follow the project's coding standards and conventions

## Troubleshooting

### Common Issues
1. **Brick not found**: Run `mason get` to ensure bricks are installed
2. **Template variables not resolving**: Check variable names and syntax
3. **Generated code has errors**: Review the template and your variable inputs

### Getting Help
- Check the [Mason documentation](https://pub.dev/packages/mason_cli)
- Review existing code patterns in the project
- Ensure your mason.yaml is properly configured

## Contributing

When adding new bricks or modifying existing ones:
1. Follow the existing brick structure and conventions
2. Test the brick thoroughly before committing
3. Update this documentation with new brick information
4. Consider adding examples and best practices
5. Ensure backward compatibility when possible

## Brick Development

To create a new brick:
1. Create a new directory in `bricks/`
2. Add `brick.yaml` with appropriate variables
3. Create template files in `__brick__/` directory
4. Update `mason.yaml` to include the new brick
5. Test the brick thoroughly
6. Document the brick in this guide

For more information on creating bricks, refer to the [Mason documentation](https://github.com/felangel/mason).