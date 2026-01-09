import 'dart:async';

import 'package:flutter_form_bloc/flutter_form_bloc.dart';

/// Demo form bloc showcasing various field types and validation patterns.
class DemoFormBloc extends FormBloc<String, String> {
  DemoFormBloc() : super(autoValidate: true) {
    addFieldBlocs(fieldBlocs: [
      name,
      email,
      password,
      age,
      country,
      interests,
      acceptTerms,
    ]);
  }

  // Text field with required validation
  final name = TextFieldBloc(
    name: 'name',
    validators: [
      FieldBlocValidators.required,
      _minLength(2),
    ],
  );

  // Text field with email validation
  final email = TextFieldBloc(
    name: 'email',
    validators: [
      FieldBlocValidators.required,
      FieldBlocValidators.email,
    ],
  );

  // Password field with custom validation
  final password = TextFieldBloc(
    name: 'password',
    validators: [
      FieldBlocValidators.required,
      _passwordValidator,
    ],
  );

  // Numeric input field
  final age = TextFieldBloc(
    name: 'age',
    validators: [
      _ageValidator,
    ],
  );

  // Single select dropdown
  final country = SelectFieldBloc<String, dynamic>(
    name: 'country',
    items: [
      'United States',
      'Canada',
      'United Kingdom',
      'Australia',
      'Germany',
      'Japan',
      'Other'
    ],
    validators: [FieldBlocValidators.required],
  );

  // Multi-select checkboxes
  final interests = MultiSelectFieldBloc<String, dynamic>(
    name: 'interests',
    items: ['Technology', 'Sports', 'Music', 'Art', 'Travel', 'Gaming'],
  );

  // Boolean checkbox
  final acceptTerms = BooleanFieldBloc(
    name: 'acceptTerms',
    initialValue: false,
    validators: [
      _requiredTrue,
    ],
  );

  // Custom validators
  static Validator<String> _minLength(int min) {
    return (String? value) {
      if (value == null || value.length < min) {
        return 'Must be at least $min characters';
      }
      return null;
    };
  }

  static String? _passwordValidator(String? value) {
    if (value == null || value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Must contain at least one number';
    }
    return null;
  }

  static String? _ageValidator(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }
    final age = int.tryParse(value);
    if (age == null) {
      return 'Please enter a valid number';
    }
    if (age < 13 || age > 120) {
      return 'Age must be between 13 and 120';
    }
    return null;
  }

  static String? _requiredTrue(bool? value) {
    return value == true ? null : 'You must accept the terms';
  }

  @override
  FutureOr<void> onSubmitting() async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // In a real app, you would access field values:
      // final nameValue = name.value;
      // final emailValue = email.value;
      // await api.submitForm(...);

      emitSuccess(
        successResponse: 'Form submitted successfully!\n\n'
            'Name: ${name.value}\n'
            'Email: ${email.value}\n'
            'Country: ${country.value}\n'
            'Interests: ${interests.value.join(", ")}',
      );
    } catch (e) {
      emitFailure(failureResponse: 'Submission failed: ${e.toString()}');
    }
  }
}
