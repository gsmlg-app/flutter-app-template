import 'package:demo_form/demo_form.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DemoFormBloc', () {
    late DemoFormBloc formBloc;

    setUp(() {
      formBloc = DemoFormBloc();
    });

    tearDown(() {
      formBloc.close();
    });

    test('initial state has all fields empty', () {
      expect(formBloc.name.value, isEmpty);
      expect(formBloc.email.value, isEmpty);
      expect(formBloc.password.value, isEmpty);
      expect(formBloc.age.value, isEmpty);
      expect(formBloc.country.value, isNull);
      expect(formBloc.interests.value, isEmpty);
      expect(formBloc.acceptTerms.value, isFalse);
    });

    group('name field', () {
      test('validates required', () {
        formBloc.name.updateValue('');
        expect(formBloc.name.state.error, isNotNull);
      });

      test('validates minimum length', () {
        formBloc.name.updateValue('A');
        expect(formBloc.name.state.error, isNotNull);
      });

      test('accepts valid name', () {
        formBloc.name.updateValue('John Doe');
        expect(formBloc.name.state.error, isNull);
      });
    });

    group('email field', () {
      test('validates email format', () {
        formBloc.email.updateValue('invalid');
        expect(formBloc.email.state.error, isNotNull);
      });

      test('accepts valid email', () {
        formBloc.email.updateValue('test@example.com');
        expect(formBloc.email.state.error, isNull);
      });
    });

    group('password field', () {
      test('validates minimum length', () {
        formBloc.password.updateValue('Short1');
        expect(formBloc.password.state.error, isNotNull);
      });

      test('validates uppercase requirement', () {
        formBloc.password.updateValue('lowercase1');
        expect(formBloc.password.state.error, contains('uppercase'));
      });

      test('validates number requirement', () {
        formBloc.password.updateValue('NoNumbers');
        expect(formBloc.password.state.error, contains('number'));
      });

      test('accepts valid password', () {
        formBloc.password.updateValue('ValidPass1');
        expect(formBloc.password.state.error, isNull);
      });
    });

    group('age field', () {
      test('allows empty value (optional)', () {
        formBloc.age.updateValue('');
        expect(formBloc.age.state.error, isNull);
      });

      test('validates numeric input', () {
        formBloc.age.updateValue('abc');
        expect(formBloc.age.state.error, isNotNull);
      });

      test('validates age range', () {
        formBloc.age.updateValue('10');
        expect(formBloc.age.state.error, isNotNull);
      });

      test('accepts valid age', () {
        formBloc.age.updateValue('25');
        expect(formBloc.age.state.error, isNull);
      });
    });

    group('acceptTerms field', () {
      test('validates required true', () {
        formBloc.acceptTerms.updateValue(false);
        expect(formBloc.acceptTerms.state.error, isNotNull);
      });

      test('accepts true value', () {
        formBloc.acceptTerms.updateValue(true);
        expect(formBloc.acceptTerms.state.error, isNull);
      });
    });

    test('form submission with valid data succeeds', () async {
      // Fill all required fields with valid data
      formBloc.name.updateValue('John Doe');
      formBloc.email.updateValue('john@example.com');
      formBloc.password.updateValue('ValidPass1');
      formBloc.country.updateValue('United States');
      formBloc.acceptTerms.updateValue(true);

      formBloc.submit();

      await expectLater(formBloc.stream, emitsThrough(isA<FormBlocSuccess>()));
    });

    test('form submission with invalid data fails', () async {
      // Leave required fields empty
      formBloc.submit();

      await expectLater(
        formBloc.stream,
        emitsThrough(isA<FormBlocSubmissionFailed>()),
      );
    });
  });
}
