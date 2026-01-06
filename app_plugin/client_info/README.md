# Client Info

Gather client information across all platforms

## Features

- ✅ Cross-platform support (Android, iOS, Linux, macOS, Windows)
- ✅ Native platform integration
- ✅ Method channel communication
- ✅ Built-in caching
- ✅ Type-safe API

## Supported Platforms

- ✅ Android
- ✅ iOS
- ✅ Linux
- ✅ macOS
- ✅ Windows


## Installation

Add this plugin to your project's `pubspec.yaml`:

```yaml
dependencies:
  app_client_info: any
```

Then run:

```bash
melos bootstrap
```

## Usage

```dart
import 'package:app_client_info/app_client_info.dart';

// Get client_info instance
final clientInfo = ClientInfo.instance;

// Get data
final data = await clientInfo. getData();
print('Platform: ${data.platform}');
print('Timestamp: ${data.timestamp}');
print('Additional Data: ${data.additionalData}');

// Refresh cached data
await clientInfo.refresh();
```

## Architecture

This plugin uses a federated plugin architecture:

- **app_client_info**: Main package (app-facing API)
- **app_client_info_platform_interface**: Platform interface definition
- **app_client_info_android**: Android implementation
- **app_client_info_ios**: iOS implementation
- **app_client_info_linux**: Linux implementation
- **app_client_info_macos**: macOS implementation
- **app_client_info_windows**: Windows implementation


## Development

### Running Tests

```bash
# Test all packages
melos run test

# Test specific package
cd client_info && flutter test
```

### Adding New Features

1. Update the platform interface in `client_info_platform_interface`
2. Implement the feature in each platform-specific package
3. Update the main API in `client_info`
4. Add tests

## License

MIT License - see LICENSE file for details.

## Author

GSMLG Team
