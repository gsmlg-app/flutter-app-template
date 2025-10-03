import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

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

    test('initial state is FormBlocStatus.initial', () {
      expect(formBloc.state.status, FormBlocStatus.initial);
    });

    group('field validation', () {
      {% for field in field_names %}
      test('{{field}} field has initial validation', () {
        expect(formBloc.{{field.camelCase()}}FieldBloc.state.validators, isNotEmpty);
      });
      {% endfor %}
    });

    {% for field in field_names %}
    group('{{field}} field', () {
      blocTest<{{name.pascalCase()}}FormBloc, FormBlocState<String, String>>(
        'emits validating state when {{field}} is updated',
        build: () => formBloc,
        act: (bloc) {
          bloc.{{field.camelCase()}}FieldBloc.onChange('test value');
        },
        expect: () => [
          isA<FormBlocState<String, String>>()
              .having((state) => state.status, 'status', FormBlocStatus.validating),
        ],
      );
    });
    {% endfor %}

    {% if has_submission %}
    group('form submission', () {
      blocTest<{{name.pascalCase()}}FormBloc, FormBlocState<String, String>>(
        'emits inProgress and success when form is submitted successfully',
        build: () => formBloc,
        setUp: () {
          {% for field in field_names %}
          formBloc.{{field.camelCase()}}FieldBloc.onChange(
            {% if field == 'email' %}'test@example.com'{% elif field == 'password' %}'password123'{% else %}'test value'{% endif %}
          );
          {% endfor %}
        },
        act: (bloc) => bloc.add(const {{name.pascalCase()}}FormEventSubmitted()),
        expect: () => [
          isA<FormBlocState<String, String>>()
              .having((state) => state.status, 'status', FormBlocStatus.validating),
          isA<FormBlocState<String, String>>()
              .having((state) => state.status, 'status', FormBlocStatus.inProgress),
          isA<FormBlocState<String, String>>()
              .having((state) => state.status, 'status', FormBlocStatus.success)
              .having((state) => state.successResponse, 'successResponse', isA<String>()),
        ],
      );

      blocTest<{{name.pascalCase()}}FormBloc, FormBlocState<String, String>>(
        'emits failure when form submission fails',
        build: () => formBloc,
        setUp: () {
          {% for field in field_names %}
          formBloc.{{field.camelCase()}}FieldBloc.onChange(
            {% if field == 'email' %}'test@example.com'{% elif field == 'password' %}'password123'{% else %}'test value'{% endif %}
          );
          {% endfor %}
        },
        act: (bloc) => bloc.add(const {{name.pascalCase()}}FormEventSubmitted()),
        // Note: This test assumes the _submitForm method throws an exception
        // You'll need to modify the _submitForm method in your actual implementation
        // to test error scenarios properly
        skip: true,
        expect: () => [
          isA<FormBlocState<String, String>>()
              .having((state) => state.status, 'status', FormBlocStatus.validating),
          isA<FormBlocState<String, String>>()
              .having((state) => state.status, 'status', FormBlocStatus.inProgress),
          isA<FormBlocState<String, String>>()
              .having((state) => state.status, 'status', FormBlocStatus.failure)
              .having((state) => state.failureResponse, 'failureResponse', isA<String>()),
        ],
      );
    });
    {% endif %}

    group('form reset', () {
      blocTest<{{name.pascalCase()}}FormBloc, FormBlocState<String, String>>(
        'clears all fields when reset is called',
        build: () => formBloc,
        setUp: () {
          {% for field in field_names %}
          formBloc.{{field.camelCase()}}FieldBloc.onChange('test value');
          {% endfor %}
        },
        act: (bloc) => bloc.add(const {{name.pascalCase()}}FormEventReset()),
        verify: (bloc) {
          {% for field in field_names %}
          expect(bloc.{{field.camelCase()}}FieldBloc.value, isEmpty);
          {% endfor %}
        },
      );
    });

    group('form validation', () {
      {% if has_validation %}
      {% for field in field_names %}
      blocTest<{{name.pascalCase()}}FormBloc, FormBlocState<String, String>>(
        'validates {{field}} field correctly',
        build: () => formBloc,
        act: (bloc) {
          bloc.{{field.camelCase()}}FieldBloc.onChange('');
        },
        expect: () => [
          isA<FormBlocState<String, String>>()
              .having((state) => state.status, 'status', FormBlocStatus.validating),
        ],
        verify: (bloc) {
          expect(bloc.{{field.camelCase()}}FieldBloc.state.isInvalid, isTrue);
        },
      );
      {% endfor %}
      {% endif %}
    });
  });
}