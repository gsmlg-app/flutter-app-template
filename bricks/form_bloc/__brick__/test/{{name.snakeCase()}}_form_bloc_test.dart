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
      {{#each field_names}}
      test('{{this}} field has initial validation', () {
        expect(formBloc.{{camelCase this}}FieldBloc.state.validators, isNotEmpty);
      });
      {{/each}}
    });

    {{#each field_names}}
    group('{{this}} field', () {
      blocTest<{{../name.pascalCase}}FormBloc, FormBlocState<String, String>>(
        'emits validating state when {{this}} is updated',
        build: () => formBloc,
        act: (bloc) {
          bloc.{{camelCase this}}FieldBloc.onChange('test value');
        },
        expect: () => [
          isA<FormBlocState<String, String>>()
              .having((state) => state.status, 'status', FormBlocStatus.validating),
        ],
      );
    });
    {{/each}}

    {{#if has_submission}}
    group('form submission', () {
      blocTest<{{name.pascalCase()}}FormBloc, FormBlocState<String, String>>(
        'emits inProgress and success when form is submitted successfully',
        build: () => formBloc,
        setUp: () {
          {{#each field_names}}
          formBloc.{{camelCase this}}FieldBloc.onChange('test value');
          {{/each}}
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
    });
    {{/if}}

    group('form reset', () {
      blocTest<{{name.pascalCase()}}FormBloc, FormBlocState<String, String>>(
        'clears all fields when reset is called',
        build: () => formBloc,
        setUp: () {
          {{#each field_names}}
          formBloc.{{camelCase this}}FieldBloc.onChange('test value');
          {{/each}}
        },
        act: (bloc) => bloc.add(const {{name.pascalCase()}}FormEventReset()),
        verify: (bloc) {
          {{#each field_names}}
          expect(bloc.{{camelCase this}}FieldBloc.value, isEmpty);
          {{/each}}
        },
      );
    });
  });
}