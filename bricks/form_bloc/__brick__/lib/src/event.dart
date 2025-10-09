/// {@template {{name.snakeCase()}}_form_events}
/// Custom events for {{name.pascalCase()}}FormBloc beyond the standard FormBloc events.
/// {@endtemplate}
abstract class {{name.pascalCase()}}FormEvent {
  /// {@macro {{name.snakeCase()}}_form_events}
  const {{name.pascalCase()}}FormEvent();
}

/// Event to clear all form fields
class ClearFormEvent extends {{name.pascalCase()}}FormEvent {
  /// {@macro {{name.snakeCase()}}_form_clear_event}
  const ClearFormEvent();
}

/// Event to populate form with initial data
class PopulateFormEvent extends {{name.pascalCase()}}FormEvent {
  /// {@macro {{name.snakeCase()}}_form_populate_event}
  const PopulateFormEvent({
    required this.email,
    required this.password,
  });

  /// Initial email value
  final String email;
  
  /// Initial password value
  final String password;
}

/// Event to validate specific field
class ValidateFieldEvent extends {{name.pascalCase()}}FormEvent {
  /// {@macro {{name.snakeCase()}}_form_validate_field_event}
  const ValidateFieldEvent(this.fieldName);

  /// Name of the field to validate
  final String fieldName;
}