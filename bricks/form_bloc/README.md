# {{name.pascalCase()}} Form BLoC

A Form BLoC for handling {{name.sentenceCase()}} form validation and submission using the `form_bloc` package.

## Features

- ✅ Field validation with built-in validators
- ✅ Form submission with loading states
- ✅ Error handling and success responses
- ✅ Form reset functionality
- ✅ Comprehensive test coverage

## Usage

### Basic Usage

```dart
BlocProvider(
  create: (context) => {{name.pascalCase()}}FormBloc(),
  child: {{name.pascalCase()}}FormScreen(),
)
```

### Form Fields

{% for field in field_names %}
- `{{field.pascalCase()}}`: {{field}} input field{% if has_validation %} with validation{% endif %}
{% endfor %}

### Form Submission

```dart
context.read<{{name.pascalCase()}}FormBloc>().add(
  const {{name.pascalCase()}}FormEventSubmitted(),
);
```

### Form Reset

```dart
context.read<{{name.pascalCase()}}FormBloc>().add(
  const {{name.pascalCase()}}FormEventReset(),
);
```

## Form Field Builders

Use the `TextFieldBlocBuilder` from `flutter_form_bloc` to build form fields:

```dart
TextFieldBlocBuilder(
  textFieldBloc: context.read<{{name.pascalCase()}}FormBloc>().{{field_names.first.camelCase()}}FieldBloc,
  decoration: const InputDecoration(
    labelText: '{{field_names.first.pascalCase()}}',
  ),
)
```

## Testing

Run the test suite:

```bash
flutter test
```

## Implementation Notes

1. **Customize Validation**: Modify field validators in the BLoC constructor
2. **Implement Submission**: Update the `_submitForm` method with your actual submission logic
3. **Add Fields**: Add new fields to the `field_names` variable and regenerate
4. **Custom Events**: Add custom events for specific form interactions

## Dependencies

- `form_bloc`: Core form functionality
- `flutter_form_bloc`: Flutter widgets for form fields
- `bloc`: State management
- `equatable`: Value equality