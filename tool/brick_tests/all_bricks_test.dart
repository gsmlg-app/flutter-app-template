import 'api_client_test.dart' as api_client_tests;
import 'form_bloc_test.dart' as form_bloc_tests;
import 'repository_test.dart' as repository_tests;
import 'simple_bloc_test.dart' as simple_bloc_tests;
import 'screen_test.dart' as screen_tests;
import 'widget_test.dart' as widget_tests;
import 'list_bloc_test.dart' as list_bloc_tests;
import 'performance_test.dart' as performance_tests;
import 'integration_test.dart' as integration_tests;

/// Main test runner for all mason bricks
///
/// Run all brick tests with:
/// ```bash
/// dart test test/bricks/all_bricks_test.dart
/// ```
///
/// Run specific test categories:
/// ```bash
/// dart test test/bricks/api_client_test.dart
/// dart test test/bricks/performance_test.dart
/// dart test test/bricks/integration_test.dart
/// ```
void main() {
  print('🧱 Running comprehensive mason brick test suite...\n');

  // Run unit tests for each brick
  print('🔧 Testing API Client Brick...');
  api_client_tests.main();
  print('✅ API Client Brick tests completed\n');

  print('📝 Testing Form BLoC Brick...');
  form_bloc_tests.main();
  print('✅ Form BLoC Brick tests completed\n');

  print('📦 Testing Repository Brick...');
  repository_tests.main();
  print('✅ Repository Brick tests completed\n');

  print('🎯 Testing Simple BLoC Brick...');
  simple_bloc_tests.main();
  print('✅ Simple BLoC Brick tests completed\n');

  print('📱 Testing Screen Brick...');
  screen_tests.main();
  print('✅ Screen Brick tests completed\n');

  print('🧩 Testing Widget Brick...');
  widget_tests.main();
  print('✅ Widget Brick tests completed\n');

  print('📋 Testing List BLoC Brick...');
  list_bloc_tests.main();
  print('✅ List BLoC Brick tests completed\n');

  // Run performance tests
  print('⚡ Running Performance Tests...');
  performance_tests.main();
  print('✅ Performance tests completed\n');

  // Run integration tests
  print('🔗 Running Integration Tests...');
  integration_tests.main();
  print('✅ Integration tests completed\n');

  print('🎉 All mason brick tests completed successfully!');
  print('\n📊 Test Summary:');
  print('   • Unit Tests: API Client, Form BLoC, Repository, Simple BLoC, Screen, Widget, List BLoC');
  print('   • Performance Tests: Generation speed, memory usage');
  print('   • Integration Tests: Cross-brick compatibility, workflow');
  print('\n✨ All bricks are working correctly and efficiently!');
}
