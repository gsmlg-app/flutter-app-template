import 'package:form_bloc/form_bloc.dart';
import 'package:equatable/equatable.dart';

import 'event.dart';
import 'state.dart';

/// {@template {{name.snakeCase()}}_form_bloc}
/// {{name.pascalCase()}}FormBloc handles {{name.sentenceCase()}} form validation and submission.
/// {@endtemplate}
class {{name.pascalCase()}}FormBloc extends FormBloc<String, String> {
  /// {@macro {{name.snakeCase()}}_form_bloc}
  {{name.pascalCase()}}FormBloc() : super() {
    {% for field in field_names %}
    addFieldBloc(
      {{field.camelCase()}}FieldBloc,
    );
    {% endfor %}

    {% if has_submission %}
    on<{{name.pascalCase()}}FormEventSubmitted>(_onSubmitted);
    {% endif %}
    on<{{name.pascalCase()}}FormEventReset>(_onReset);
  }

  {% for field in field_names %}
  /// {{field.pascalCase()}} field bloc
  late final {{field.camelCase()}}FieldBloc = TextFieldBloc(
    name: '{{field}}',
    {% if has_validation %}
    validators: [
      {% if field == 'email' %}
      FieldBlocValidators.required,
      FieldBlocValidators.email,
      {% elif field == 'password' %}
      FieldBlocValidators.required,
      FieldBlocValidators.passwordMinLength6,
      {% else %}
      FieldBlocValidators.required,
      {% endif %}
    ],
    {% endif %}
  );
  {% endfor %}

  {% if has_submission %}
  /// Handles form submission
  Future<void> _onSubmitted(
    {{name.pascalCase()}}FormEventSubmitted event,
    Emitter<FormBlocState<String, String>> emitter,
  ) async {
    try {
      emitter(state.copyWith(status: FormBlocStatus.inProgress));

      // TODO: Implement your form submission logic here
      // Example: API call, database operation, etc.
      await _submitForm();

      emitter(state.copyWith(
        status: FormBlocStatus.success,
        successResponse: '{{name.pascalCase()}} form submitted successfully',
      ));
    } catch (error, stackTrace) {
      emitter(state.copyWith(
        status: FormBlocStatus.failure,
        failureResponse: error.toString(),
      ));
      addError(error, stackTrace);
    }
  }

  /// Implement your form submission logic here
  Future<void> _submitForm() async {
    // TODO: Replace with actual submission logic
    // Example:
    // final result = await apiService.submit{{name.pascalCase()}}Form(
    //   {% for field in field_names %}
    //   {{field}}: {{field.camelCase()}}FieldBloc.value,
    //   {% endfor %}
    // );

    // Simulate async operation
    await Future.delayed(const Duration(seconds: 1));

    // Throw exception if there's an error
    // throw Exception('Submission failed');
  }
  {% endif %}

  /// Handles form reset
  Future<void> _onReset(
    {{name.pascalCase()}}FormEventReset event,
    Emitter<FormBlocState<String, String>> emitter,
  ) async {
    {% for field in field_names %}
    {{field.camelCase()}}FieldBloc.clear();
    {% endfor %}
  }
}