import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:duskmoon_form/duskmoon_form.dart';
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

    group('field validation', () {
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
    });

    test('getFormData returns correct map', () {
      formBloc.email.updateValue('test@example.com');
      formBloc.password.updateValue('password123');

      final formData = formBloc.getFormData();
      expect(formData['email'], 'test@example.com');
      expect(formData['password'], 'password123');
    });
  });
}
