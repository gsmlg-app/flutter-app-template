import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_bloc/form_bloc.dart';
import 'package:{{name.snakeCase()}}_form_bloc/{{name.snakeCase()}}_form_bloc.dart';

void main() {
  group('{{name.pascalCase()}}FormBloc', () {
    late {{name.pascalCase()}}FormBloc formBloc;

    setUp(() {
      formBloc = {{name.pascalCase()}}FormBloc();
    });

    tearDown(() {
      formBloc.close();
    });

    test('initial state is correct', () {
      expect(formBloc.state.isValid, isFalse);
      expect(formBloc.state.isSubmitting, isFalse);
      expect(formBloc.state.hasErrors, isFalse);
    });

    group('email field validation', () {
      blocTest<{{name.pascalCase()}}FormBloc, FormBlocState<String, String>>(
        'emits invalid state when email is empty',
        build: () => formBloc,
        act: (bloc) => bloc.email.updateValue(''),
        expect: () => [
          predicate<FormBlocState<String, String>>((state) => 
            state.isValid == false && 
            bloc.email.state.isInvalid
          ),
        ],
      );

      blocTest<{{name.pascalCase()}}FormBloc, FormBlocState<String, String>>(
        'emits invalid state when email is invalid format',
        build: () => formBloc,
        act: (bloc) => bloc.email.updateValue('invalid-email'),
        expect: () => [
          predicate<FormBlocState<String, String>>((state) => 
            state.isValid == false && 
            bloc.email.state.isInvalid
          ),
        ],
      );

      blocTest<{{name.pascalCase()}}FormBloc, FormBlocState<String, String>>(
        'emits valid state when email is valid format',
        build: () => formBloc,
        act: (bloc) => bloc.email.updateValue('test@example.com'),
        expect: () => [
          predicate<FormBlocState<String, String>>((state) => 
            bloc.email.state.isValid
          ),
        ],
      );
    });

    group('password field validation', () {
      blocTest<{{name.pascalCase()}}FormBloc, FormBlocState<String, String>>(
        'emits invalid state when password is empty',
        build: () => formBloc,
        act: (bloc) => bloc.password.updateValue(''),
        expect: () => [
          predicate<FormBlocState<String, String>>((state) => 
            state.isValid == false && 
            bloc.password.state.isInvalid
          ),
        ],
      );

      blocTest<{{name.pascalCase()}}FormBloc, FormBlocState<String, String>>(
        'emits invalid state when password is too short',
        build: () => formBloc,
        act: (bloc) => bloc.password.updateValue('123'),
        expect: () => [
          predicate<FormBlocState<String, String>>((state) => 
            state.isValid == false && 
            bloc.password.state.isInvalid
          ),
        ],
      );

      blocTest<{{name.pascalCase()}}FormBloc, FormBlocState<String, String>>(
        'emits valid state when password meets requirements',
        build: () => formBloc,
        act: (bloc) => bloc.password.updateValue('password123'),
        expect: () => [
          predicate<FormBlocState<String, String>>((state) => 
            bloc.password.state.isValid
          ),
        ],
      );
    });

    group('form submission', () {
      blocTest<{{name.pascalCase()}}FormBloc, FormBlocState<String, String>>(
        'emits submitting and success when form is submitted successfully',
        build: () => formBloc,
        setUp: () {
          formBloc.email.updateValue('test@example.com');
          formBloc.password.updateValue('password123');
        },
        act: (bloc) => bloc.submit(),
        expect: () => [
          predicate<FormBlocState<String, String>>((state) => 
            state.isSubmitting
          ),
          predicate<FormBlocState<String, String>>((state) => 
            state.isSuccess && 
            state.successResponse == 'Form submitted successfully!'
          ),
        ],
      );
    });

    group('form reset', () {
      blocTest<{{name.pascalCase()}}FormBloc, FormBlocState<String, String>>(
        'resets form to initial state',
        build: () => formBloc,
        setUp: () {
          formBloc.email.updateValue('test@example.com');
          formBloc.password.updateValue('password123');
        },
        act: (bloc) {
          bloc.email.updateValue('');
          bloc.password.updateValue('');
        },
        expect: () => [
          predicate<FormBlocState<String, String>>((state) => 
            state.isValid == false
          ),
        ],
      );
    });

    test('getFormData returns correct map', () {
      formBloc.email.updateValue('test@example.com');
      formBloc.password.updateValue('password123');
      
      final formData = formBloc.getFormData();
      
      expect(formData['email'], equals('test@example.com'));
      expect(formData['password'], equals('password123'));
    });

    test('form state extensions work correctly', () {
      // Test initial state
      expect({{name.pascalCase()}}FormStateExtensions.isFormValid(formBloc.state), isFalse);
      expect({{name.pascalCase()}}FormStateExtensions.isSubmitting(formBloc.state), isFalse);
      expect({{name.pascalCase()}}FormStateExtensions.hasErrors(formBloc.state), isFalse);
      
      // Test with invalid data
      formBloc.email.updateValue('invalid-email');
      expect({{name.pascalCase()}}FormStateExtensions.hasErrors(formBloc.state), isTrue);
      
      // Test with valid data
      formBloc.email.updateValue('test@example.com');
      formBloc.password.updateValue('password123');
      expect({{name.pascalCase()}}FormStateExtensions.isFormValid(formBloc.state), isTrue);
    });
  });
}