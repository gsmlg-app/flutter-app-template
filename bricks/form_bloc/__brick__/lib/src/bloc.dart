import 'package:duskmoon_form/duskmoon_form.dart';

/// {@template {{name.snakeCase()}}_form_bloc}
/// {{name.pascalCase()}}FormBloc manages the state and validation for the {{name.sentenceCase()}} form.
/// {@endtemplate}
class {{name.pascalCase()}}FormBloc extends FormBloc<String, String> {
  /// {@macro {{name.snakeCase()}}_form_bloc}
  {{name.pascalCase()}}FormBloc() : super(autoValidate: true) {
    addFieldBlocs(
      fieldBlocs: [
        email,
        password,
      ],
    );
  }

  /// Email field
  final email = TextFieldBloc(
    validators: [
      FieldBlocValidators.required,
      FieldBlocValidators.email,
    ],
  );

  /// Password field
  final password = TextFieldBloc(
    validators: [
      FieldBlocValidators.required,
      FieldBlocValidators.passwordMin6Chars,
    ],
  );

  @override
  void onSubmitting() async {
    try {
      // Simulate form submission
      await Future<void>.delayed(const Duration(milliseconds: 500));
      emitSuccess(successResponse: 'Form submitted successfully!');
    } catch (e) {
      emitFailure(failureResponse: e.toString());
    }
  }

  /// Helper method to get form data as a map
  Map<String, dynamic> getFormData() {
    return {
      'email': email.value,
      'password': password.value,
    };
  }

  @override
  Future<void> close() {
    email.close();
    password.close();
    return super.close();
  }
}
