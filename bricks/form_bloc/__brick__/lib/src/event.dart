part of 'bloc.dart';

/// {@template {{name.snakeCase()}}_form_event}
/// Base class for all {{name.pascalCase()}} form events.
/// {@endtemplate}
sealed class {{name.pascalCase()}}FormEvent {
  /// {@macro {{name.snakeCase()}}_form_event}
  const {{name.pascalCase()}}FormEvent();
}

{% if has_submission %}
/// {@template {{name.snakeCase()}}_form_event_submitted}
/// Event to submit the {{name.pascalCase()}} form.
/// {@endtemplate}
final class {{name.pascalCase()}}FormEventSubmitted extends {{name.pascalCase()}}FormEvent {
  /// {@macro {{name.snakeCase()}}_form_event_submitted}
  const {{name.pascalCase()}}FormEventSubmitted();
}
{% endif %}

/// {@template {{name.snakeCase()}}_form_event_reset}
/// Event to reset the {{name.pascalCase()}} form.
/// {@endtemplate}
final class {{name.pascalCase()}}FormEventReset extends {{name.pascalCase()}}FormEvent {
  /// {@macro {{name.snakeCase()}}_form_event_reset}
  const {{name.pascalCase()}}FormEventReset();
}

{% for field in field_names %}
/// {@template {{name.snakeCase()}}_form_event_{{field.snakeCase()}}_changed}
/// Event when {{field}} field value changes.
/// {@endtemplate}
final class {{name.pascalCase()}}FormEvent{{field.pascalCase()}}Changed extends {{name.pascalCase()}}FormEvent {
  /// {@macro {{name.snakeCase()}}_form_event_{{field.snakeCase()}}_changed}
  const {{name.pascalCase()}}FormEvent{{field.pascalCase()}}Changed(this.{{field}});

  /// The new {{field}} value
  final String {{field}};
}
{% endfor %}