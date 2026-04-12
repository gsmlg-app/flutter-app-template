import 'dart:async';

import 'package:duskmoon_form/duskmoon_form.dart';
import 'package:flutter/material.dart';

/// Demo form bloc showcasing all available field types.
class DemoFormBloc extends FormBloc<String, String> {
  DemoFormBloc() : super(autoValidate: true) {
    addFieldBlocs(
      fieldBlocs: [
        // Text fields
        name,
        email,
        password,
        age,
        // Selection fields
        country,
        priority,
        experienceLevel,
        interests,
        skills,
        // Boolean fields
        acceptTerms,
        enableNotifications,
        // Range/Numeric
        satisfaction,
        // Date & Time
        birthDate,
        preferredTime,
        // Rich text
        bio,
        codeSnippet,
      ],
    );
  }

  // --- Text fields ---

  final name = TextFieldBloc(
    name: 'name',
    validators: [FieldBlocValidators.required, _minLength(2)],
  );

  final email = TextFieldBloc(
    name: 'email',
    validators: [FieldBlocValidators.required, FieldBlocValidators.email],
  );

  final password = TextFieldBloc(
    name: 'password',
    validators: [FieldBlocValidators.required, _passwordValidator],
  );

  final age = TextFieldBloc(name: 'age', validators: [_ageValidator]);

  // --- Selection fields ---

  final country = SelectFieldBloc<String, dynamic>(
    name: 'country',
    items: [
      'United States',
      'Canada',
      'United Kingdom',
      'Australia',
      'Germany',
      'Japan',
      'Other',
    ],
    validators: [FieldBlocValidators.required],
  );

  // Choice chips (single select)
  final priority = SelectFieldBloc<String, dynamic>(
    name: 'priority',
    items: ['Low', 'Medium', 'High', 'Critical'],
    initialValue: 'Medium',
  );

  // Radio buttons (single select)
  final experienceLevel = SelectFieldBloc<String, dynamic>(
    name: 'experienceLevel',
    items: ['Beginner', 'Intermediate', 'Advanced', 'Expert'],
  );

  // Checkbox group (multi-select)
  final interests = MultiSelectFieldBloc<String, dynamic>(
    name: 'interests',
    items: ['Technology', 'Sports', 'Music', 'Art', 'Travel', 'Gaming'],
  );

  // Filter chips (multi-select)
  final skills = MultiSelectFieldBloc<String, dynamic>(
    name: 'skills',
    items: ['Flutter', 'Dart', 'Swift', 'Kotlin', 'React', 'TypeScript'],
  );

  // --- Boolean fields ---

  final acceptTerms = BooleanFieldBloc(
    name: 'acceptTerms',
    initialValue: false,
    validators: [_requiredTrue],
  );

  final enableNotifications = BooleanFieldBloc(
    name: 'enableNotifications',
    initialValue: true,
  );

  // --- Range/Numeric ---

  final satisfaction = InputFieldBloc<double, dynamic>(
    name: 'satisfaction',
    initialValue: 0.5,
  );

  // --- Date & Time ---

  final birthDate = InputFieldBloc<DateTime?, dynamic>(
    name: 'birthDate',
    initialValue: null,
  );

  final preferredTime = InputFieldBloc<TimeOfDay?, dynamic>(
    name: 'preferredTime',
    initialValue: null,
  );

  // --- Rich text ---

  final bio = MarkdownFieldBloc(
    name: 'bio',
    initialValue: '# About Me\n\nWrite something about yourself...',
  );

  final codeSnippet = CodeEditorFieldBloc(
    name: 'codeSnippet',
    initialValue: 'void main() {\n  print("Hello, World!");\n}\n',
    initialLanguage: 'dart',
  );

  // --- Validators ---

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
    if (value == null || value.isEmpty) return null;
    final age = int.tryParse(value);
    if (age == null) return 'Please enter a valid number';
    if (age < 13 || age > 120) return 'Age must be between 13 and 120';
    return null;
  }

  static String? _requiredTrue(bool? value) {
    return value == true ? null : 'You must accept the terms';
  }

  @override
  FutureOr<void> onSubmitting() async {
    try {
      await Future.delayed(const Duration(seconds: 2));

      emitSuccess(
        successResponse:
            'Form submitted successfully!\n\n'
            'Name: ${name.value}\n'
            'Email: ${email.value}\n'
            'Country: ${country.value}\n'
            'Priority: ${priority.value}\n'
            'Experience: ${experienceLevel.value}\n'
            'Interests: ${interests.value.join(", ")}\n'
            'Skills: ${skills.value.join(", ")}\n'
            'Satisfaction: ${(satisfaction.value * 100).round()}%\n'
            'Notifications: ${enableNotifications.value}',
      );
    } catch (e) {
      emitFailure(failureResponse: 'Submission failed: ${e.toString()}');
    }
  }
}
