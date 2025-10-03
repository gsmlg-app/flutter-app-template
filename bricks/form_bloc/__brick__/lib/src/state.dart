part of 'bloc.dart';

/// {@template {{name.snakeCase()}}_form_state}
/// {{name.pascalCase()}}FormState represents the state of the {{name.sentenceCase()}} form.
/// {@endtemplate}
class {{name.pascalCase()}}FormState extends Equatable {
  /// {@macro {{name.snakeCase()}}_form_state}
  const {{name.pascalCase()}}FormState({
    this.status = FormBlocStatus.initial,
    this.error,
  });

  /// The current status of the form
  final FormBlocStatus status;

  /// Any error message from form submission
  final String? error;

  {{name.pascalCase()}}FormState copyWith({
    FormBlocStatus? status,
    String? error,
  }) {
    return {{name.pascalCase()}}FormState(
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, error];

  @override
  String toString() => '{{name.pascalCase()}}FormState(status: $status, error: $error)';
}

/// Form submission status enum
enum FormBlocStatus {
  /// Form is in its initial state
  initial,

  /// Form is being validated
  validating,

  /// Form submission is in progress
  inProgress,

  /// Form was submitted successfully
  success,

  /// Form submission failed
  failure,
}