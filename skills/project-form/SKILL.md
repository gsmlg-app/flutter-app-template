---
name: project-form
description: Guide for creating form modules with FormBloc state management and Flutter widgets in app_form packages (project)
---

# Flutter Form Development Skill

This skill guides the creation of form modules using `duskmoon_form` package following this project's conventions.

## When to Use

Trigger this skill when:
- Creating a new form with validation
- Building login, registration, or data entry forms
- User asks to "create a form", "add a form", "implement form validation"
- Need reactive form state management with BLoC pattern

## Package Dependencies

Forms use the `duskmoon_form` package in this project:
- `duskmoon_form` - Core form state management (FormBloc, FieldBlocs, validators) and Flutter widgets (DmTextFieldBlocBuilder, DmFormBlocListener, etc.)

## Project Structure

Form modules MUST be created in `app_form/`:

```
app_form/
└── {form_name}/
    ├── lib/
    │   ├── {form_name}_form.dart           # Barrel export file
    │   └── src/
    │       ├── bloc/
    │       │   └── {form_name}_form_bloc.dart  # FormBloc with fields
    │       └── widget/
    │           └── {form_name}_form_widget.dart # Form UI widget
    ├── test/
    │   └── {form_name}_form_test.dart
    └── pubspec.yaml
```

## Creating a New Form Module

### Step 1: Create Package Structure

```bash
mkdir -p app_form/{form_name}/lib/src/bloc
mkdir -p app_form/{form_name}/lib/src/widget
mkdir -p app_form/{form_name}/test
```

### Step 2: Create pubspec.yaml

```yaml
name: {form_name}_form
description: {FormName} form module with FormBloc state management
version: 1.0.0

environment:
  sdk: ">=3.6.0 <4.0.0"

resolution: workspace

dependencies:
  flutter:
    sdk: flutter
  duskmoon_form: any

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

### Step 3: Add to Root Workspace

Add to root `pubspec.yaml` workspace:

```yaml
workspace:
  - app_form/{form_name}
```

## FormBloc Implementation

### Basic FormBloc Template

```dart
// lib/src/bloc/{form_name}_form_bloc.dart
import 'package:duskmoon_form/duskmoon_form.dart';

class {FormName}FormBloc extends FormBloc<String, String> {
  {FormName}FormBloc() : super(autoValidate: true) {
    addFieldBlocs(fieldBlocs: [
      email,
      password,
    ]);
  }

  // Field Blocs
  final email = TextFieldBloc(
    name: 'email',
    validators: [
      FieldBlocValidators.required,
      FieldBlocValidators.email,
    ],
  );

  final password = TextFieldBloc(
    name: 'password',
    validators: [
      FieldBlocValidators.required,
      _passwordValidator,
    ],
  );

  // Custom validator
  static String? _passwordValidator(String? value) {
    if (value == null || value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  @override
  FutureOr<void> onSubmitting() async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Access field values
      final emailValue = email.value;
      final passwordValue = password.value;

      // Success
      emitSuccess(successResponse: 'Form submitted successfully');
    } catch (e) {
      emitFailure(failureResponse: e.toString());
    }
  }
}
```

## Available Field Blocs

### TextFieldBloc - Text input

```dart
final name = TextFieldBloc(
  name: 'name',
  initialValue: '',
  validators: [FieldBlocValidators.required],
);
```

### BooleanFieldBloc - Checkboxes/Switches

```dart
final acceptTerms = BooleanFieldBloc(
  name: 'acceptTerms',
  initialValue: false,
  validators: [
    (value) => value == true ? null : 'You must accept terms',
  ],
);
```

### SelectFieldBloc - Single selection dropdown

```dart
final country = SelectFieldBloc<String, dynamic>(
  name: 'country',
  items: ['USA', 'Canada', 'UK', 'Australia'],
  validators: [FieldBlocValidators.required],
);
```

### MultiSelectFieldBloc - Multiple selection

```dart
final interests = MultiSelectFieldBloc<String, dynamic>(
  name: 'interests',
  items: ['Sports', 'Music', 'Technology', 'Art'],
);
```

### InputFieldBloc - Generic typed input

```dart
final quantity = InputFieldBloc<int, dynamic>(
  name: 'quantity',
  initialValue: 1,
  validators: [
    (value) => value > 0 ? null : 'Must be positive',
  ],
);
```

## Built-in Validators

```dart
// From FieldBlocValidators
FieldBlocValidators.required      // Non-empty
FieldBlocValidators.email         // Email format
FieldBlocValidators.min(5)        // Minimum length
FieldBlocValidators.max(100)      // Maximum length
FieldBlocValidators.passwordMin6Chars  // Password >= 6 chars

// Async validators
final username = TextFieldBloc(
  name: 'username',
  asyncValidatorDebounceTime: const Duration(milliseconds: 500),
  asyncValidators: [_checkUsernameAvailable],
);

Future<String?> _checkUsernameAvailable(String username) async {
  final available = await api.checkUsername(username);
  return available ? null : 'Username already taken';
}
```

## Form Widget Implementation

### Basic Form Widget Template

```dart
// lib/src/widget/{form_name}_form_widget.dart
import 'package:flutter/material.dart';
import 'package:duskmoon_form/duskmoon_form.dart';
import 'package:duskmoon_ui/duskmoon_ui.dart';
import '../bloc/{form_name}_form_bloc.dart';

class {FormName}FormWidget extends StatelessWidget {
  const {FormName}FormWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => {FormName}FormBloc(),
      child: Builder(
        builder: (context) {
          final formBloc = context.read<{FormName}FormBloc>();

          return DmFormBlocListener<{FormName}FormBloc, String, String>(
            onSubmitting: (context, state) {
              // Show loading indicator
            },
            onSubmissionFailed: (context, state) {
              // Handle validation errors
            },
            onSuccess: (context, state) {
              // Handle success - navigate, show snackbar, etc.
              showDmSuccessToast(
                context: context,
                message: state.successResponse ?? 'Success',
              );
            },
            onFailure: (context, state) {
              // Handle failure
              showDmErrorToast(
                context: context,
                message: state.failureResponse ?? 'Error',
              );
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DmTextFieldBlocBuilder(
                    textFieldBloc: formBloc.email,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  DmTextFieldBlocBuilder(
                    textFieldBloc: formBloc.password,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    suffixButton: SuffixButton.obscureText,
                  ),
                  const SizedBox(height: 24),
                  DmButton(
                    onPressed: formBloc.submit,
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
```

## Duskmoon Form Widgets

### DmTextFieldBlocBuilder

```dart
DmTextFieldBlocBuilder(
  textFieldBloc: formBloc.email,
  decoration: const InputDecoration(labelText: 'Email'),
  keyboardType: TextInputType.emailAddress,
  suffixButton: SuffixButton.clearText,  // or SuffixButton.obscureText
)
```

### DmCheckboxFieldBlocBuilder

```dart
DmCheckboxFieldBlocBuilder(
  booleanFieldBloc: formBloc.acceptTerms,
  body: Container(
    child: const Text('I accept the terms and conditions'),
  ),
)
```

### DmSwitchFieldBlocBuilder

```dart
DmSwitchFieldBlocBuilder(
  booleanFieldBloc: formBloc.notifications,
  body: Container(
    child: const Text('Enable notifications'),
  ),
)
```

### DmDropdownFieldBlocBuilder

```dart
DmDropdownFieldBlocBuilder<String>(
  selectFieldBloc: formBloc.country,
  decoration: const InputDecoration(labelText: 'Country'),
  itemBuilder: (context, value) => FieldItem(child: Text(value)),
)
```

### DmRadioButtonGroupFieldBlocBuilder

```dart
DmRadioButtonGroupFieldBlocBuilder<String>(
  selectFieldBloc: formBloc.gender,
  decoration: const InputDecoration(labelText: 'Gender'),
  itemBuilder: (context, value) => FieldItem(child: Text(value)),
)
```

### DmCheckboxGroupFieldBlocBuilder

```dart
DmCheckboxGroupFieldBlocBuilder<String>(
  multiSelectFieldBloc: formBloc.interests,
  decoration: const InputDecoration(labelText: 'Interests'),
  itemBuilder: (context, value) => FieldItem(child: Text(value)),
)
```

### DmDateTimeFieldBlocBuilder

```dart
DmDateTimeFieldBlocBuilder(
  dateTimeFieldBloc: formBloc.birthDate,
  format: DateFormat('yyyy-MM-dd'),
  decoration: const InputDecoration(labelText: 'Birth Date'),
)
```

## Form States

Handle different form states with `DmFormBlocListener`:

```dart
DmFormBlocListener<MyFormBloc, String, String>(
  onLoading: (context, state) {
    // FormBlocLoading - Initial loading
  },
  onLoadFailed: (context, state) {
    // FormBlocLoadFailed - Load failed
  },
  onSubmitting: (context, state) {
    // FormBlocSubmitting - Form is submitting
    // state.progress - submission progress (0.0 to 1.0)
  },
  onSuccess: (context, state) {
    // FormBlocSuccess - Submission succeeded
    // state.successResponse - success data
  },
  onFailure: (context, state) {
    // FormBlocFailure - Submission failed
    // state.failureResponse - error data
  },
  onDeleting: (context, state) {
    // FormBlocDeleting - Delete in progress
  },
  onDeleteSuccessful: (context, state) {
    // FormBlocDeleteSuccessful
  },
  onDeleteFailed: (context, state) {
    // FormBlocDeleteFailed
  },
  child: // Form widget
)
```

## Multi-Step Forms

```dart
class StepperFormBloc extends FormBloc<String, String> {
  StepperFormBloc() {
    // Step 0: Personal Info
    addFieldBlocs(step: 0, fieldBlocs: [firstName, lastName]);

    // Step 1: Contact Info
    addFieldBlocs(step: 1, fieldBlocs: [email, phone]);

    // Step 2: Preferences
    addFieldBlocs(step: 2, fieldBlocs: [notifications]);
  }

  // Fields...

  @override
  FutureOr<void> onSubmitting() async {
    if (state.currentStep < state.lastStep) {
      emitSuccess(canSubmitAgain: true);  // Move to next step
    } else {
      // Final submission
      emitSuccess(successResponse: 'Complete');
    }
  }
}
```

## Barrel Export File

```dart
// lib/{form_name}_form.dart
export 'src/bloc/{form_name}_form_bloc.dart';
export 'src/widget/{form_name}_form_widget.dart';
```

## Testing

```dart
// test/{form_name}_form_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:{form_name}_form/{form_name}_form.dart';

void main() {
  group('{FormName}FormBloc', () {
    late {FormName}FormBloc formBloc;

    setUp(() {
      formBloc = {FormName}FormBloc();
    });

    tearDown(() {
      formBloc.close();
    });

    test('email field validates email format', () {
      formBloc.email.updateValue('invalid');
      expect(formBloc.email.state.error, isNotNull);

      formBloc.email.updateValue('test@example.com');
      expect(formBloc.email.state.error, isNull);
    });

    test('form submission with valid data succeeds', () async {
      formBloc.email.updateValue('test@example.com');
      formBloc.password.updateValue('password123');

      formBloc.submit();

      await expectLater(
        formBloc.stream,
        emitsThrough(isA<FormBlocSuccess>()),
      );
    });
  });
}
```

## Complete Example: Login Form

### Bloc

```dart
// app_form/login/lib/src/bloc/login_form_bloc.dart
import 'package:duskmoon_form/duskmoon_form.dart';

class LoginFormBloc extends FormBloc<String, String> {
  LoginFormBloc() : super(autoValidate: true) {
    addFieldBlocs(fieldBlocs: [email, password, rememberMe]);
  }

  final email = TextFieldBloc(
    name: 'email',
    validators: [
      FieldBlocValidators.required,
      FieldBlocValidators.email,
    ],
  );

  final password = TextFieldBloc(
    name: 'password',
    validators: [
      FieldBlocValidators.required,
      FieldBlocValidators.passwordMin6Chars,
    ],
  );

  final rememberMe = BooleanFieldBloc(
    name: 'rememberMe',
    initialValue: false,
  );

  @override
  FutureOr<void> onSubmitting() async {
    try {
      // Call your auth service
      await Future.delayed(const Duration(seconds: 2));
      emitSuccess(successResponse: 'Login successful');
    } catch (e) {
      emitFailure(failureResponse: 'Invalid credentials');
    }
  }
}
```

### Widget

```dart
// app_form/login/lib/src/widget/login_form_widget.dart
import 'package:flutter/material.dart';
import 'package:duskmoon_form/duskmoon_form.dart';
import 'package:duskmoon_ui/duskmoon_ui.dart';
import '../bloc/login_form_bloc.dart';

class LoginFormWidget extends StatelessWidget {
  final VoidCallback? onSuccess;

  const LoginFormWidget({super.key, this.onSuccess});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginFormBloc(),
      child: Builder(
        builder: (context) {
          final formBloc = context.read<LoginFormBloc>();

          return DmFormBlocListener<LoginFormBloc, String, String>(
            onSuccess: (context, state) => onSuccess?.call(),
            onFailure: (context, state) {
              showDmErrorToast(
                context: context,
                message: state.failureResponse ?? 'Error',
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DmTextFieldBlocBuilder(
                    textFieldBloc: formBloc.email,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  DmTextFieldBlocBuilder(
                    textFieldBloc: formBloc.password,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outlined),
                    ),
                    suffixButton: SuffixButton.obscureText,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => formBloc.submit(),
                  ),
                  const SizedBox(height: 8),
                  DmCheckboxFieldBlocBuilder(
                    booleanFieldBloc: formBloc.rememberMe,
                    body: Container(
                      alignment: Alignment.centerLeft,
                      child: const Text('Remember me'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  BlocBuilder<LoginFormBloc, FormBlocState>(
                    builder: (context, state) {
                      return DmButton(
                        onPressed: state is FormBlocSubmitting
                            ? null
                            : formBloc.submit,
                        child: state is FormBlocSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Login'),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
```

## Integration Tips

1. **Access form in parent**: Use `BlocProvider.value` to provide existing FormBloc
2. **Pre-fill form**: Set `initialValue` on field blocs or use `updateInitialValue()`
3. **Clear form**: Call `formBloc.clear()` to reset all fields
4. **Delete operation**: Call `formBloc.delete()` and implement `onDeleting()`
5. **Cancel submission**: Call `formBloc.cancelSubmission()` for long operations
