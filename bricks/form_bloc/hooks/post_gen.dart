import 'dart:io';

void run(List<String> arguments) {
  print('🎉 Form BLoC brick generated successfully!');
  print('');
  print('📝 Next steps:');
  print('1. Navigate to the generated package directory');
  print('2. Run `flutter pub get` to install dependencies');
  print('3. Implement the _submitForm method in the BLoC');
  print('4. Add custom field validators as needed');
  print('5. Run tests with `flutter test`');
  print('');
  print('💡 Usage example:');
  print('```dart');
  print('BlocProvider(');
  print('  create: (context) => {{name.pascalCase()}}FormBloc(),');
  print('  child: {{name.pascalCase()}}FormScreen(),');
  print(')');
  print('```');
}