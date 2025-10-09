import 'package:form_bloc/form_bloc.dart';

/// {@template {{name.snakeCase()}}_form_bloc}
/// {{name.pascalCase()}}FormBloc manages the state and events for the {{name.sentenceCase()}} form.
/// {@endtemplate}
class {{name.pascalCase()}}FormBloc extends FormBloc<String, String> {
  /// {@macro {{name.snakeCase()}}_form_bloc}
  {{name.pascalCase()}}FormBloc() : super(autoValidate: true) {
    // Add form fields
    addEmailField();
    addPasswordField();
  }

  late final TextFieldBloc email;
  late final TextFieldBloc password;

  void addEmailField() {
    email = TextFieldBloc(
      validators: [
        FieldBlocValidators.required,
        FieldBlocValidators.email,
      ],
    );
    addFieldBlocs(fieldBlocs: [email]);
  }

  void addPasswordField() {
    password = TextFieldBloc(
      validators: [
        FieldBlocValidators.required,
        (value) {
          if (value.length < 6) {
            return 'Password must be at least 6 characters';
          }
          return null;
        },
      ],
    );
    addFieldBlocs(fieldBlocs: [password]);
  }

  @override
  void onSubmitting() async {
    try {
      // TODO: Implement your form submission logic here
      // Example: await _repository.submitForm(email.value, password.value);
      
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      emitSuccess(successResponse: 'Form submitted successfully!');
    } catch (e) {
      emitFailure(failureResponse: e.toString());
    }
  }

  /// Helper method to get form data as a map
  Map<String, String> getFormData() {
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