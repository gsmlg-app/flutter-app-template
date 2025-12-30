# Mason Bricks Guide

This project uses [Mason](https://pub.dev/packages/mason_cli) for code generation to maintain consistency and speed up development. This guide explains how to use the available bricks.

## Available Bricks

### 1. Screen Brick (`screen`)
Creates a new screen file in the `lib/screens/` directory with proper navigation and theming integration.

**Usage:**
```bash
mason make screen -c config.json
```

**Variables:**
- `name` (required): Screen name (e.g., "Profile", "UserSettings")
- `folder` (optional): Subfolder name (e.g., "user" creates `lib/screens/user/profile_screen.dart`)
- `has_adaptive_scaffold` (default: true): Use AppAdaptiveScaffold for responsive layout
- `has_app_bar` (default: true): Include SliverAppBar in the screen

**Examples:**
```bash
# Create config file for basic screen 
echo '{"name": "Home", "folder": "", "has_adaptive_scaffold": true, "has_app_bar": true}' > config.json
mason make screen -c config.json

# Screen in subfolder with custom options
echo '{"name": "Profile", "folder": "user", "ham nnks_adaptive_scaffold": true, "has_app_bar": true}' > config.json
mason make screen -c config.json

# Simple screen without adaptive scaffold
echo '{"name": "Login", "folder": "auth", "has_adaptive_scaffold": false, "has_app_bar": false}' > config.json
mason make screen -c config.json
```

**⚠️ Known Issues:**
- When `has_adaptive_scaffold` is false, extra import may be generated (needs manual cleanup)
- When `has_app_bar` is false, dangling comma may need manual removal

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
Creates a reusable widget package in the `app_widget/` folder with platform adaptive support and proper testing.

**Usage:**
```bash
mason make widget -c config.json
```

**Variables:**
- `name` (required): Widget name (e.g., "CustomButton", "LoadingSpinner")
- `type` (default: stateless): Widget type (`stateless` or `stateful`)
- `folder` (optional): Optional subfolder in app_widget (e.g., "buttons" for app_widget/buttons/)
- `has_platform_adaptive` (default: true): Include platform-specific implementation (Material vs Cupertino)

**Examples:**
```bash
# Basic stateless widget
echo '{"name": "CustomButton", "type": "stateless", "folder": "buttons", "has_platform_adaptive": true}' > config.json
mason make widget -c config.json

# Stateful widget with platform adaptation
echo '{"name": "LoadingSpinner", "type": "stateful", "folder": "", "has_platform_adaptive": true}' > config.json
mason make widget -c config.json

# Widget in specific folder without platform adaptation
echo '{"name": "Card", "type": "stateless", "folder": "cards", "has_platform_adaptive": false}' > config.json
mason make widget -c config.json
```

**⚠️ Known Issues:**
- **CRITICAL**: Generated widgets missing class inheritance and build method signatures
- Widget output directory may not respect folder structure
- Manual fixes required for generated widget files to be functional

**Manual Fixes Required:**
1. Add `StatelessWidget` or `StatefulWidget` to class declaration
2. Fix build method signature: `Widget build(BuildContext context)`
3. Move files to correct `app_widget/{folder}/{name}_widget/` structure if needed

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
- Analysis options for consistent linting

---

### 3. Simple BLoC Brick (`simple_bloc`)
Creates a simple bloc package in this app with state management components.

**Usage:**
```bash
mason make simple_bloc -c config.json
```

**Variables:**
- `name` (required): BLoC name (e.g., "User", "Settings", default: "todo")

**Examples:**
```bash
echo '{"name": "User"}' > config.json
mason make simple_bloc -c config.json

# Using default name
echo '{"name": "todo"}' > config.json
mason make simple_bloc -c config.json
```

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
├── .gitignore
├── .metadata
├── README.md
├── CHANGELOG.md
├── LICENSE
├── pubspec.yaml
└── hooks/ (pre/post generation scripts)
```

**Features:**
- Clean BLoC pattern implementation
- Event-driven state management
- Comprehensive testing scaffold
- Proper documentation and changelog
- MIT license included
- Pre/post generation hooks for customization

---

### 4. List BLoC Brick (`list_bloc`)
Creates a comprehensive list BLoC package with advanced features including schema management, pagination, search, filtering, reordering, and individual item state tracking.

**Usage:**
```bash
mason make list_bloc -c config.json
```

**Variables:**
- `name` (required): List name (e.g., "Users", "Products", "Tasks")
- `item_type` (default: "User"): Type of items in the list (singular form)
- `has_pagination` (default: true): Include pagination support
- `has_search` (default: true): Include search functionality
- `has_filters` (default: true): Include advanced filtering
- `has_reorder` (default: false): Include drag & drop reordering
- `has_crud` (default: true): Include CRUD operations
- `filter_types` (default: ["category", "status"]): Types of filters to include
- `sort_options` (default: ["name", "date"]): Available sort options
- `output_directory` (default: "app_bloc"): Where to create the bloc package

**Examples:**
```bash
# Complete feature list for users
echo '{"name": "Users", "item_type": "User", "has_pagination": true, "has_search": true, "has_filters": true, "has_reorder": true, "has_crud": true, "filter_types": ["category", "status"], "sort_options": ["name", "date"], "output_directory": "app_bloc"}' > config.json
mason make list_bloc -c config.json

# Simple product list without pagination
echo '{"name": "Products", "item_type": "Product", "has_pagination": false, "has_search": false, "has_filters": false, "has_reorder": false, "has_crud": false, "filter_types": [], "sort_options": [], "output_directory": "app_bloc"}' > config.json
mason make list_bloc -c config.json

# Task list with basic features
echo '{"name": "Tasks", "item_type": "Task", "has_crud": true, "filter_types": ["status", "priority"], "sort_options": ["name", "date"], "output_directory": "app_bloc"}' > config.json
mason make list_bloc -c config.json
```

**Generated Structure:**
```
{output_directory}/{name}_list_bloc/
├── lib/
│   ├── src/
│   │   ├── bloc.dart (main BLoC implementation)
│   │   ├── event.dart (comprehensive event definitions)
│   │   ├── state.dart (enhanced state with schema and item tracking)
│   │   ├── schema.dart (field and list schema models)
│   │   └── item_state.dart (individual item state tracking)
│   └── {name}_list_bloc.dart (export file)
├── test/
│   └── {name}_list_bloc_test.dart (comprehensive test suite)
├── hooks/
│   └── post_gen.dart (post-generation hook)
├── README.md (detailed usage documentation)
├── pubspec.yaml (dependencies include bloc, flutter_bloc, equatable)
└── brick.yaml
```

**Features:**
- **Schema Management**: Dynamic field configuration with visibility, sorting, and filtering
- **Individual Item States**: Track updating, removing, selecting, expanding, editing per item
- **Optimistic Updates**: Immediate UI feedback during CRUD operations
- **Pagination Support**: Efficient loading of large datasets
- **Real-time Search**: Debounced search with loading states
- **Advanced Filtering**: Multiple filter types with AND/OR logic
- **Drag & Drop Reordering**: Manual item reordering with position persistence
- **Batch Operations**: Multi-select with batch delete/update capabilities
- **Multiple Display Modes**: List, grid, table, and card layouts
- **Comprehensive Error Handling**: Per-item error states with recovery
- **Full Test Coverage**: Complete test suite for all functionality

**Usage in UI:**
```dart
// Create and provide the BLoC
BlocProvider(
  create: (context) => UserListBloc(),
  child: UserListView(),
)

// Initialize the list
context.read<UserListBloc>().add(UserListEventInitialize());

// Search functionality
context.read<UserListBloc>().add(UserListEventSearch('john'));

// Filter items
context.read<UserListBloc>().add(UserListEventSetFilter('status', 'active'));

// Select items
context.read<UserListBloc>().add(UserListEventSelectItem('user-123', true));

// Batch operations
context.read<UserListBloc>().add(UserListEventBatchDelete(['user-1', 'user-2']));
```

---

### 5. Form BLoC Brick (`form_bloc`)
Creates a form bloc package with dynamic field generation, validation, and submission logic.

**Usage:**
```bash
mason make form_bloc -c config.json
```

**Variables:**
- `name` (required): Form bloc name (e.g., "Login", "Registration", default: "login")
- `output_directory` (default: "app_bloc"): Output directory for the form bloc
- `fields` (default: ["email:email", "password:password"]): List of fields in format "name:field_type" (e.g., "name:text", "age:number", "isActive:boolean")

**Field Types:**
| Field Type | Description | Example | Generated FieldBloc |
|------------|-------------|---------|-------------------|
| `text` | Basic text input | `name:text` | TextFieldBloc |
| `email` | Email with validation | `email:email` | TextFieldBloc with email validator |
| `password` | Password with length validation | `password:password` | TextFieldBloc with password validator |
| `number` | Numeric text input | `age:number` | TextFieldBloc with number validator |
| `boolean` | True/false toggle | `isActive:boolean` | BooleanFieldBloc |
| `select` | Single selection dropdown | `country:select:USA,Canada,Mexico` | SelectFieldBloc with items |
| `multiselect` | Multiple selection | `interests:multiselect:sports,music,movies` | MultiSelectFieldBloc |
| `date` | Date picker | `birthDate:date` | InputFieldBloc<DateTime> |
| `file` | File upload | `avatar:file` | InputFieldBloc<dynamic> |

**Examples:**

**Basic Login Form (default):**
```bash
echo '{"name": "Login", "output_directory": "app_bloc", "fields": ["email:email", "password:password"]}' > config.json
mason make form_bloc -c config.json

# Using default values
echo '{"name": "login"}' > config.json
mason make form_bloc -c config.json
```

**User Registration Form:**
```bash
echo '{"name": "Registration", "output_directory": "app_bloc", "fields": ["name:text", "email:email", "password:password", "confirmPassword:password", "agreeTerms:boolean"]}' > config.json
mason make form_bloc -c config.json
```

**Profile Form with Select Options:**
```bash
echo '{"name": "Profile", "output_directory": "app_bloc", "fields": ["firstName:text", "lastName:text", "email:email", "phone:text", "country:select:USA,Canada,Mexico", "newsletter:boolean"]}' > config.json
mason make form_bloc -c config.json
```

**Survey Form with Multiple Selection:**
```bash
echo '{"name": "Survey", "output_directory": "app_bloc", "fields": ["rating:select:1,2,3,4,5", "comments:text", "interests:multiselect:sports,music,movies", "newsletter:boolean"]}' > config.json
mason make form_bloc -c config.json
```

**Complex Form with Mixed Types:**
```bash
echo '{"name": "Application", "output_directory": "app_bloc", "fields": ["fullName:text", "email:email", "age:number", "birthDate:date", "experience:select:Junior,Senior,Expert", "skills:multiselect:Flutter,Dart,React", "available:boolean", "resume:file"]}' > config.json
mason make form_bloc -c config.json
```

**Generated Structure:**
```
{output_directory}/{name}_form_bloc/
├── lib/
│   ├── src/
│   │   ├── bloc.dart (dynamic FormBloc implementation)
│   │   ├── event.dart (dynamic form events)
│   │   └── state.dart (FormBlocState extensions)
│   └── {name}_form_bloc.dart (export file)
├── test/
│   └── {name}_form_bloc_test.dart (dynamic test suite)
├── pubspec.yaml (dependencies include form_bloc, bloc_test)
└── brick.yaml
```

**Features:**
- **Dynamic Field Generation**: Automatically generates fields based on configuration
- **Type-Safe Fields**: Each field type gets appropriate FieldBloc with correct validators
- **Built-in Validation**: Email, password, number, required field validation
- **Select Field Options**: Support for dropdown items and multi-select options
- **Auto-validation**: Real-time validation as users type
- **Submission Handling**: Async form submission with loading states
- **Error Handling**: Comprehensive error management with user-friendly messages
- **State Extensions**: Helper methods for easier state checking
- **Dynamic Testing**: Automatically generates tests for all field types
- **Form Data Access**: Type-safe form data extraction

**Field Validation:**
- **Text Fields**: Required validation
- **Email Fields**: Required + email format validation
- **Password Fields**: Required + minimum 6 characters validation
- **Number Fields**: Required + numeric format validation
- **Boolean Fields**: Required validation (must be true)
- **Select Fields**: Required validation (must select an option)
- **MultiSelect Fields**: Required validation (must select at least one)
- **Date Fields**: Required validation
- **File Fields**: Required validation (must upload file)

**Generated Code Examples:**

**Field Declarations (from Profile Form):**
```dart
late final TextFieldBloc firstName;
late final TextFieldBloc lastName;
late final TextFieldBloc email;
late final TextFieldBloc phone;
late final SelectFieldBloc<String, dynamic> country;
late final BooleanFieldBloc newsletter;
```

**Field Initialization (with Select Options):**
```dart
void addCountryField() {
  final selectItems = ['USA', 'Canada', 'Mexico'];
  country = SelectFieldBloc<String, dynamic>(
    items: selectItems,
    validators: [
      FieldBlocValidators.required,
    ],
  );
  addFieldBlocs(fieldBlocs: [country]);
}
```

**Dynamic PopulateFormEvent:**
```dart
class PopulateFormEvent extends ProfileFormEvent {
  const PopulateFormEvent({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.country,
    required this.newsletter,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String? country;
  final bool newsletter;
}
```

**Form Data Access:**
```dart
// Get form data as map
final formData = formBloc.getFormData();
print('Name: ${formData['firstName']} ${formData['lastName']}');
print('Email: ${formData['email']}');
print('Country: ${formData['country']}');
print('Newsletter: ${formData['newsletter']}');

// Check form state
if (ProfileFormStateExtensions.isFormValid(formBloc.state)) {
  // Form is valid, can submit
}
```

**Usage in UI:**
```dart
BlocProvider(
  create: (context) => ProfileFormBloc(),
  child: Builder(
    builder: (context) {
      final formBloc = context.read<ProfileFormBloc>();

      return FormBlocListener(
        formBloc: formBloc,
        onSubmitting: () => showLoadingDialog(),
        onSuccess: () => showSuccessMessage(),
        onFailure: (error) => showErrorMessage(error),
        child: Column(
          children: [
            TextFieldBlocBuilder(
              textFieldBloc: formBloc.firstName,
              decoration: InputDecoration(labelText: 'First Name'),
            ),
            TextFieldBlocBuilder(
              textFieldBloc: formBloc.email,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            DropdownFieldBlocBuilder(
              selectFieldBloc: formBloc.country,
              decoration: InputDecoration(labelText: 'Country'),
            ),
            SwitchFieldBlocBuilder(
              booleanFieldBloc: formBloc.newsletter,
              title: Text('Subscribe to newsletter'),
            ),
            ElevatedButton(
              onPressed: () => formBloc.submit(),
              child: Text('Submit'),
            ),
          ],
        ),
      );
    },
  ),
)
```

**Populating Form Data:**
```dart
// Populate form with existing data
formBloc.add(ProfileFormEvent(
  firstName: 'John',
  lastName: 'Doe',
  email: 'john@example.com',
  phone: '+1234567890',
  country: 'USA',
  newsletter: true,
));
```

**Testing:**
The brick automatically generates comprehensive tests for each field type:

```dart
// Example generated tests
test('email field validation', () {
  blocTest<ProfileFormBloc, FormBlocState<String, String>>(
    'emits invalid state when email is invalid format',
    build: () => formBloc,
    act: (bloc) => bloc.email.updateValue('invalid-email'),
    expect: () => [
      predicate<FormBlocState<String, String>>((state) => 
        state.isValid == false && 
        bloc.email.state.isInvalid
      ),
    ],
  );
});

test('select field validation', () {
  blocTest<ProfileFormBloc, FormBlocState<String, String>>(
    'emits valid state when country has a selected value',
    build: () => formBloc,
    act: (bloc) => bloc.country.updateValue('USA'),
    expect: () => [
      predicate<FormBlocState<String, String>>((state) => 
        bloc.country.state.isValid
      ),
    ],
  );
});
```

**Dependencies:**
- `form_bloc`: Path reference to `../../third_party/form_bloc`
- `bloc_test`: For comprehensive testing
- `flutter_test`: For widget testing

**Migration from Previous Version:**
The brick maintains backward compatibility. Existing forms will continue to work:

```bash
# Old way (still works)
mason make form_bloc --name Login

# New equivalent
mason make form_bloc --name Login --fields "email:email,password:password"
```

**Advanced Usage:**
For complex forms, you can combine multiple field types:

```bash
mason make form_bloc --name JobApplication \
  --fields "fullName:text,email:email,phone:text,position:select:Developer,Designer,Manager,experience:number,portfolio:file,available:boolean"
```

This generates a complete form with text inputs, email validation, phone number, position dropdown, years of experience, file upload for portfolio, and availability toggle.

**Best Practices:**
1. Use descriptive field names that clearly indicate their purpose
2. Choose appropriate field types for better UX and validation
3. Provide meaningful select options for dropdown fields
4. Test generated forms thoroughly before integration
5. Customize validation logic in the generated BLoC if needed
6. Use the generated state extensions for cleaner UI code


### 7. Repository Brick (`repository`)
Creates a complete repository pattern implementation with data sources, models, and comprehensive testing.

**Usage:**
```bash
mason make repository -c config.json
```

**Variables:**
- `name` (required): Repository name (e.g., "User", "Product")
- `has_remote_data_source` (default: true): Include remote data source (API calls)
- `has_local_data_source` (default: true): Include local data source (local storage)
- `model_name` (optional): Model name for the repository (defaults to repository name)

**Examples:**
```bash
# Repository with both data sources
echo '{"name": "User", "has_remote_data_source": true, "has_local_data_source": true, "model_name": "User"}' > config.json
mason make repository -c config.json

# Repository with only local data source
echo '{"name": "Product", "has_remote_data_source": false, "has_local_data_source": true, "model_name": "Product"}' > config.json
mason make repository -c config.json

# Repository with custom model name
echo '{"name": "UserAuth", "has_remote_data_source": true, "has_local_data_source": false, "model_name": "Authentication"}' > config.json
mason make repository -c config.json
```

**Generated Structure:**
```
{name}_repository/
├── lib/
│   ├── src/
│   │   ├── data_sources/
│   │   │   ├── local_data_source.dart
│   │   │   └── remote_data_source.dart
│   │   ├── exceptions/
│   │   │   └── exceptions.dart
│   │   ├── models/
│   │   │   └── {name}_model.dart
│   │   └── repository.dart
│   └── {name}_repository.dart
└── pubspec.yaml
```

**Features:**
- Clean architecture repository pattern
- Remote and local data source separation
- Custom exception handling
- Data model generation
- Comprehensive testing support
- Flexible data source configuration

**⚠️ Known Issues:**
- Method parameter names may be missing in generated repository (needs manual fix)
- Data sources may be generated even when set to false

---

### 8. Native Federation Plugin Brick (`native_federation_plugin`)
Creates a complete federated Flutter plugin with native platform implementations for Android, iOS, Linux, macOS, and Windows.

**Usage:**
```bash
mason make native_federation_plugin -c config.json
```

**Variables:**
- `name` (required): Plugin name (e.g., "client_info", "battery_monitor")
- `description` (required): Plugin description
- `package_prefix` (default: "app"): Package name prefix
- `author` (default: "GSMLG Team"): Author name
- `support_android` (default: true): Include Android platform support
- `support_ios` (default: true): Include iOS platform support
- `support_linux` (default: true): Include Linux platform support
- `support_macos` (default: true): Include macOS platform support
- `support_windows` (default: true): Include Windows platform support
- `support_web` (default: false): Include Web platform support

**Examples:**
```bash
# Full cross-platform plugin
mason make native_federation_plugin \
  --name client_info \
  --description "Gather client information across all platforms" \
  --package_prefix app \
  --author "GSMLG Team" \
  --support_android true \
  --support_ios true \
  --support_linux true \
  --support_macos true \
  --support_windows true \
  -o app_plugin

# Mobile-only plugin
echo '{"name": "mobile_info", "description": "Mobile device information", "package_prefix": "app", "support_android": true, "support_ios": true, "support_linux": false, "support_macos": false, "support_windows": false}' > config.json
mason make native_federation_plugin -c config.json -o app_plugin

# Desktop-only plugin
echo '{"name": "desktop_utils", "description": "Desktop utilities", "package_prefix": "app", "support_android": false, "support_ios": false, "support_linux": true, "support_macos": true, "support_windows": true}' > config.json
mason make native_federation_plugin -c config.json -o app_plugin
```

**Generated Structure:**
```
{name}/                                    # Main plugin package
├── lib/
│   ├── src/
│   │   ├── {name}.dart                   # Plugin main class
│   │   └── models/
│   │       ├── models.dart               # Model exports
│   │       └── {name}_data.dart          # Data model
│   └── {package_prefix}_{name}.dart      # Public API export
└── pubspec.yaml

{name}_platform_interface/                # Platform interface
├── lib/
│   ├── src/
│   │   ├── {name}_platform.dart          # Abstract platform interface
│   │   └── method_channel_{name}.dart    # Method channel implementation
│   └── {package_prefix}_{name}_platform_interface.dart
└── pubspec.yaml

{name}_android/                            # Android implementation
├── android/
│   ├── build.gradle
│   ├── src/main/
│   │   ├── AndroidManifest.xml
│   │   └── kotlin/com/{package_prefix}/{name}/
│   │       └── {Name}Plugin.kt           # Kotlin native code
├── lib/
│   └── {package_prefix}_{name}_android.dart
└── pubspec.yaml

{name}_ios/                                # iOS implementation
├── ios/
│   ├── {name}_ios.podspec
│   └── Classes/
│       └── {Name}Plugin.swift            # Swift native code
├── lib/
│   └── {package_prefix}_{name}_ios.dart
└── pubspec.yaml

{name}_linux/                              # Linux implementation
├── linux/
│   ├── CMakeLists.txt
│   ├── {name}_plugin.cc                  # C++ implementation
│   └── include/{name}_linux/
│       └── {name}_plugin.h               # C++ header
├── lib/
│   └── {package_prefix}_{name}_linux.dart
└── pubspec.yaml

{name}_macos/                              # macOS implementation
├── macos/
│   ├── {name}_macos.podspec
│   └── Classes/
│       └── {Name}Plugin.swift            # Swift native code
├── lib/
│   └── {package_prefix}_{name}_macos.dart
└── pubspec.yaml

{name}_windows/                            # Windows implementation
├── windows/
│   ├── CMakeLists.txt
│   ├── {name}_plugin.cpp                 # C++ implementation
│   └── {name}_plugin.h                   # C++ header
├── lib/
│   └── {package_prefix}_{name}_windows.dart
└── pubspec.yaml

README.md                                  # Plugin documentation
```

**Post-Generation Steps:**

1. **Add to Melos Workspace:**
```yaml
# In root pubspec.yaml
workspace:
  - app_plugin/{name}
  - app_plugin/{name}_platform_interface
  - app_plugin/{name}_android
  - app_plugin/{name}_ios
  - app_plugin/{name}_linux
  - app_plugin/{name}_macos
  - app_plugin/{name}_windows
```

2. **Add resolution: workspace to all pubspec.yaml files:**
```yaml
# In each generated pubspec.yaml
resolution: workspace
```

3. **Run Melos Bootstrap:**
```bash
melos bootstrap
```

4. **Add to Main App:**
```yaml
# In main app pubspec.yaml dependencies
dependencies:
  {package_prefix}_{name}: any
```

**Features:**
- **Federated Architecture**: Clean separation between interface and implementations
- **Native Code**: Platform-specific implementations in Kotlin, Swift, and C++
- **Method Channels**: Type-safe communication between Dart and native code
- **Built-in Caching**: Platform implementations include data caching
- **Comprehensive Structure**: Includes pubspec, native build files, and platform registration
- **Cross-Platform**: Support for all major platforms (Android, iOS, Linux, macOS, Windows)
- **Ready to Extend**: Easy to add new methods and features

**Native Implementation Details:**

**Android (Kotlin):**
- Uses `FlutterPlugin` and `MethodCallHandler`
- Access to Android `Build` class for device info
- Method channel: `{package_prefix}_{name}`
- Supports `getData()` and `refresh()` methods

**iOS (Swift):**
- Uses `FlutterPlugin` protocol
- Access to `UIDevice` for device information
- Podspec configured for iOS 12.0+
- Automatic platform registration

**Linux (C++):**
- GTK-based Flutter Linux plugin
- Uses `uname` for system information
- CMake build configuration
- FlValue serialization for data exchange

**macOS (Swift):**
- Uses `ProcessInfo` for system data
- Podspec configured for macOS 10.14+
- Native Swift implementation
- Access to macOS-specific APIs

**Windows (C++):**
- Windows API integration
- CMake build system
- Access to `OSVERSIONINFOW` and `SYSTEM_INFO`
- Memory and CPU information available

**Example Usage:**

After generating the plugin, use it in your app:

```dart
import 'package:app_client_info/app_client_info.dart';

// Get plugin instance
final clientInfo = ClientInfo.instance;

// Fetch data from native platform
final data = await clientInfo.getData();
print('Platform: ${data.platform}');
print('Timestamp: ${data.timestamp}');
print('Additional Data: ${data.additionalData}');

// Refresh cached data
await clientInfo.refresh();
final newData = await clientInfo.getData();
```

**Customizing Native Implementations:**

Each platform package can be customized independently:

**Android (`{name}_android/android/src/main/kotlin/.../Plugin.kt`):**
```kotlin
private fun getData(): Map<String, Any> {
    return mutableMapOf(
        "platform" to "android",
        "additionalData" to mapOf(
            "manufacturer" to Build.MANUFACTURER,
            "model" to Build.MODEL,
            // Add more Android-specific data here
        )
    )
}
```

**iOS (`{name}_ios/ios/Classes/Plugin.swift`):**
```swift
private func getData() throws -> [String: Any] {
    let device = UIDevice.current
    return [
        "platform": "ios",
        "additionalData": [
            "name": device.name,
            "model": device.model,
            // Add more iOS-specific data here
        ]
    ]
}
```

**Testing:**

The brick generates test-ready structure. Add tests in each package:

```dart
// In {name}/test/{name}_test.dart
void main() {
  test('getData returns platform data', () async {
    final clientInfo = ClientInfo.instance;
    final data = await clientInfo.getData();
    expect(data.platform, isNotEmpty);
    expect(data.timestamp, isNotNull);
  });
}
```

**Best Practices:**
1. Design the platform interface before generating
2. Use descriptive names that clearly indicate plugin purpose
3. Implement error handling in native code
4. Add comprehensive tests for each platform
5. Document public APIs thoroughly
6. Use caching to avoid expensive native calls
7. Handle platform-specific edge cases gracefully
8. Version all packages together (keep versions in sync)

**⚠️ Known Limitations:**
- Web platform support is basic (no native code, Dart only)
- Native code requires platform-specific development knowledge
- Each platform must be tested on actual devices

**Important CMake Naming Convention:**
The CMake `PROJECT_NAME` in Linux/Windows plugins **must match** the package name from pubspec.yaml. This is because Flutter's `generated_plugins.cmake` expects the target name to be `${package_name}_plugin`.

For example, if your pubspec.yaml has:
```yaml
name: app_client_info_linux
```

Then CMakeLists.txt must have:
```cmake
set(PROJECT_NAME "app_client_info_linux")  # NOT "client_info_linux"
```

The brick template handles this automatically by using `{{package_prefix}}_{{name}}_linux` for the PROJECT_NAME.

**Dependencies:**
- `plugin_platform_interface`: For federated plugin architecture
- `flutter_lints`: For code quality
- `mockito`: For testing (optional)

**Publishing:**
If you want to publish to pub.dev:
1. Remove `publish_to: none` from all pubspec.yaml files
2. Add proper `homepage` and `repository` URLs
3. Ensure all packages have matching versions
4. Test on all supported platforms
5. Follow pub.dev publishing guidelines

---

### 9. API Client Brick (`api_client`)
Generates a complete API client package from OpenAPI/Swagger specifications with Dio, Retrofit, and JSON serialization support.

**Usage:**
```bash
mason make api_client -c config.json
```

**Variables:**
- `package_name` (required): Package name for the API client (default: "app_api")

**Examples:**
```bash
echo '{"package_name": "user_api_client"}' > config.json
mason make api_client -c config.json

# Using default name
echo '{"package_name": "app_api"}' > config.json
mason make api_client -c config.json
```

**Generated Structure:**
```
{package_name}/
├── lib/
│   └── {package_name}.dart
├── test/
│   └── {package_name}_test.dart
├── openapi.yaml (place your OpenAPI spec here)
├── swagger_parser.yaml
├── pubspec.yaml
└── hooks/ (pre/post generation scripts)
```

**Features:**
- OpenAPI/Swagger specification support
- Dio HTTP client integration
- Retrofit annotation support
- JSON serialization setup
- Comprehensive testing scaffold
- Pre/post generation hooks for customization

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