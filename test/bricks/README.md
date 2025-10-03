# Mason Brick Tests

This directory contains comprehensive tests for all mason bricks in the Flutter App Template project.

## Test Structure

```
test/bricks/
├── README.md                    # This file
├── test_utils.dart              # Utility functions for testing
├── test_config.dart             # Test configurations and expected values
├── all_bricks_test.dart         # Main test runner
├── api_client_test.dart         # API Client brick tests
├── repository_test.dart         # Repository brick tests
├── simple_bloc_test.dart        # Simple BLoC brick tests
├── performance_test.dart        # Performance and memory tests
└── integration_test.dart        # Cross-brick integration tests
```

## Running Tests

### Run All Tests
```bash
dart test test/bricks/all_bricks_test.dart
```

### Run Individual Test Suites
```bash
# API Client brick tests
dart test test/bricks/api_client_test.dart

# Repository brick tests
dart test test/bricks/repository_test.dart

# Simple BLoC brick tests
dart test test/bricks/simple_bloc_test.dart

# Performance tests
dart test test/bricks/performance_test.dart

# Integration tests
dart test test/bricks/integration_test.dart
```

### Run with Coverage
```bash
dart test --coverage=coverage test/bricks/
genhtml coverage/lcov.info -o coverage/html
```

## Test Categories

### 1. Unit Tests
Each brick has comprehensive unit tests that verify:
- ✅ Correct file structure generation
- ✅ Valid pubspec.yaml with proper dependencies
- ✅ Correct Dart code syntax and structure
- ✅ Template variable substitution
- ✅ Parameter validation
- ✅ Error handling for invalid inputs

### 2. Performance Tests
Performance tests ensure bricks generate efficiently:
- ⚡ Generation speed benchmarks
- 💾 Memory usage monitoring
- 🔄 Concurrent generation capability
- 📏 Large template rendering performance

### 3. Integration Tests
Integration tests verify bricks work together:
- 🔗 Cross-brick type compatibility
- 📦 Workspace integration simulation
- 🏗️ Complete feature generation workflow
- ⚠️ Error handling consistency

## Test Utilities

### BrickTestUtils
The `test_utils.dart` file provides utility functions for:
- Creating and cleaning up temporary directories
- Loading bricks from YAML files
- Generating files from bricks
- Validating generated content
- File existence and content checks

### Test Configuration
The `test_config.dart` file contains:
- Expected file lists for each brick
- Dependency configurations
- Test scenarios and variations
- Validation patterns
- Edge case test data

## Expected Test Results

### API Client Brick
- Generates 5 core files
- Includes Dio, Retrofit, and JSON serialization dependencies
- Creates OpenAPI template and swagger_parser configuration
- Validates package naming conventions

### Repository Brick
- Generates 7 core files with data sources and models
- Supports remote/local data source combinations
- Includes comprehensive error handling
- Implements cache policies and factory patterns

### Simple BLoC Brick
- Generates 9 files including tests and documentation
- Creates sealed event classes and state management
- Includes comprehensive BLoC tests
- Supports proper BLoC patterns

## Performance Benchmarks

Expected performance targets:
- API Client: < 5 seconds
- Simple BLoC: < 3 seconds  
- Repository: < 4 seconds
- Concurrent generation: < 6 seconds
- Memory increase: < 50MB for 5 generations

## Troubleshooting

### Common Issues

1. **Mason not found**
   ```bash
   dart pub global activate mason_cli
   mason get
   ```

2. **Permission errors on temp directories**
   - Ensure proper file permissions
   - Check available disk space

3. **Template syntax errors**
   - Verify brick YAML syntax
   - Check template variable usage

4. **Dependency conflicts**
   - Run `dart pub get` in generated packages
   - Check for version conflicts

### Debug Mode

Enable verbose output for debugging:
```bash
dart test --verbose test/bricks/
```

## Contributing

When adding new bricks or modifying existing ones:

1. **Add corresponding tests** in the appropriate test file
2. **Update test configuration** in `test_config.dart`
3. **Verify performance** meets benchmarks
4. **Run integration tests** to ensure compatibility
5. **Update this README** with new test information

### Test Naming Conventions

- Use descriptive test names that explain what is being tested
- Group related tests in nested `group()` blocks
- Include setup and teardown for proper cleanup
- Use `BrickTestUtils.runTest()` for consistent error handling

### Adding New Test Scenarios

1. Add test data to `test_config.dart`
2. Create test functions following existing patterns
3. Update `all_bricks_test.dart` if needed
4. Verify all tests pass locally

## Continuous Integration

These tests are designed to run in CI/CD pipelines:
- ✅ Fast execution (< 2 minutes total)
- ✅ No external dependencies required
- ✅ Proper cleanup of temporary files
- ✅ Clear error reporting

## Test Coverage

The test suite aims for comprehensive coverage:
- 📁 File structure generation
- 📋 Content validation
- 🔧 Parameter handling
- ⚡ Performance characteristics
- 🔗 Integration scenarios
- ❌ Error conditions

This ensures that mason bricks work reliably in all scenarios and maintain high code quality standards.